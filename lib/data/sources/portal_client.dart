// ===========================================================================
//  portal_client.dart  =  CLIENT HTTP CARE FOLOSESTE SESIUNEA DE LOGIN
// ---------------------------------------------------------------------------
//  Cere date din portalul EMSYS (acilfov.emsys.ro) trimitand cookie-ul de
//  sesiune obtinut dupa ce te-ai logat in WebView.
//  Practic, "vorbeste" cu portalul ca si cum ai fi tu logat in browser.
//
//  Modeleaza exact stilul cererilor pe care le foloseste si integrarea
//  Home Assistant (proiectul ACIlfovHA):
//   - GET simplu (cookie) pentru contract / sold / perioada index;
//   - POST cu antete speciale (codclient/nrcontract/startdate/enddate) si
//     un corp "form-urlencoded" cu $action=LOAD_RECORDS pentru consum / plati.
//
//  Folosit de CookieACIRepository ca sursa de date reala PANA cand exista API.
// ===========================================================================

import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../cookie_store.dart';

class PortalIdentity {
  final String codClient;
  final String? nrContract;
  final Map<String, dynamic>? contractRow;

  const PortalIdentity({
    required this.codClient,
    required this.nrContract,
    required this.contractRow,
  });
}

class PortalClient {
  final http.Client _http;
  PortalIdentity? _identity;

  PortalClient({http.Client? client}) : _http = client ?? http.Client();

  // ------------------------------------------------------------- identitate
  // Codul de client si numarul de contract sunt citite din sesiunea portalului,
  // dupa login, prin endpoint-ul de contract. Multe endpoint-uri au nevoie de
  // ele pe langa cookie.
  Future<PortalIdentity> identity() async {
    final cached = _identity;
    if (cached != null) return cached;

    final data = await getJson(AppConfig.emsysContract);
    final row = _firstRow(data);
    final cod = row == null
        ? null
        : _str(row, [
            'codClient',
            'codclient',
            'cod_client',
            'clientCode',
            'codCli',
            'cod',
            'idClient',
          ]);
    final nr = row == null
        ? null
        : _str(row, [
            'nrContract',
            'nrcontract',
            'nr_contract',
            'numarContract',
            'numar_contract',
            'contract',
            'codContract',
          ]);

    if (cod == null) {
      throw StateError(
        'Nu pot identifica codul de client din sesiunea portalului. '
        'Logheaza-te din nou in portal; daca eroarea ramane, trebuie verificat '
        'raspunsul endpoint-ului de contract.',
      );
    }

    return _identity = PortalIdentity(
      codClient: cod,
      nrContract: nr,
      contractRow: row,
    );
  }

  Future<String> requireCodClient() async => (await identity()).codClient;

  // ---------------------------------------------------------------- sesiune
  // Cookie-ul de sesiune este citit din magazinul nativ WebView.
  Future<String> _cookie() async {
    final cookie = await CookieStore.currentHeader(AppConfig.portalUrl);
    if (cookie == null || cookie.isEmpty) {
      throw StateError(
        'Nu exista sesiune activa. Logheaza-te in portal din ecranul de autentificare.',
      );
    }
    return cookie;
  }

  // Antetele comune tuturor cererilor (imita un browser real).
  Future<Map<String, String>> _headers([Map<String, String>? extra]) async {
    final headers = <String, String>{
      'Cookie': await _cookie(),
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'application/json, text/plain, */*',
    };
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  // ------------------------------------------------------------------- GET
  // GET care intoarce textul brut (ex: getSoldClient intoarce un numar simplu).
  Future<String> getText(String url) async {
    final res = await _http.get(Uri.parse(url), headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Portalul a raspuns cu ${res.statusCode} la $url');
    }
    return res.body;
  }

  // GET care intoarce JSON deja decodat (poate fi Map sau List, dupa endpoint).
  Future<dynamic> getJson(String url) async {
    final body = await getText(url);
    return body.isEmpty ? null : jsonDecode(body);
  }

  // Compatibilitate cu codul mai vechi (echivalent cu getText).
  Future<String> fetch(String url) => getText(url);

  // ------------------------------------------------------------------ POST
  // POST in stilul EMSYS "LOAD_RECORDS": trimite codclient / nrcontract si
  // fereastra de timp (startdate/enddate) prin ANTETE, iar filtrele prin corp.
  // Intoarce JSON-ul decodat (de obicei { "records": [ { "row": {...} } ] }).
  Future<Map<String, dynamic>> postRecords(
    String url, {
    required DateTime startDate,
    required DateTime endDate,
    Map<String, String>? payloadExtra,
  }) async {
    final id = await identity();
    final headers = await _headers({
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
      'codclient': id.codClient,
      if (id.nrContract != null) 'nrcontract': id.nrContract!,
      'startdate': HttpDate.format(startDate.toUtc()),
      'enddate': HttpDate.format(endDate.toUtc()),
    });

    final payload = <String, String>{
      r'$qd': 'false',
      r'$action': 'LOAD_RECORDS',
      r'$locale': 'en',
      r'$ls': 'false',
      r'$to': '500',
      ...?payloadExtra,
    };

    final res = await _http.post(
      Uri.parse(url),
      headers: headers,
      body: payload, // http encodeaza automat ca form-urlencoded
    );
    if (res.statusCode != 200) {
      throw Exception('Portalul a raspuns cu ${res.statusCode} la $url');
    }
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  // POST specific pentru istoricul de consum (endpoint /consum/Consums).
  // IMPORTANT: foloseste EXACT antetele pe care le trimite aplicatia web
  // (camelCase + "locatie" + "contor" + "OUI_REQ"), altfel serverul intoarce
  // 0 randuri (confirmat prin inspectarea cererii reale din portal).
  Future<Map<String, dynamic>> consumRecords({
    required String idLocatie,
    required String contor,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final id = await identity();
    final headers = await _headers({
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
      'startDate': HttpDate.format(startDate.toUtc()),
      'endDate': HttpDate.format(endDate.toUtc()),
      'locatie': idLocatie,
      'contor': contor,
      'codClient': id.codClient,
      if (id.nrContract != null) 'nrContract': id.nrContract!,
      'OUI_REQ': 'true',
    });
    final payload = <String, String>{
      r'$qd': 'false',
      r'$action': 'LOAD_RECORDS',
      r'$locale': 'en',
      r'$ls': 'false',
      r'$to': '500',
      r'$order': 'DATA_NOU desc',
    };
    final res = await _http.post(
      Uri.parse(AppConfig.emsysConsum),
      headers: headers,
      body: payload,
    );
    if (res.statusCode != 200) {
      throw Exception('Portalul a raspuns cu ${res.statusCode} la consum');
    }
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  // POST specific pentru pagina "Informatii cont".
  // Confirmat din bundle-ul portalului:
  // controller InformatiiCont -> /rest/self/informatiiCont/InformatiiConts,
  // headere camelCase startDate/endDate si sortare DATA_OPERATIE desc.
  Future<Map<String, dynamic>> informatiiContRecords({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final headers = await _headers({
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
      'startDate': HttpDate.format(startDate.toUtc()),
      'endDate': HttpDate.format(endDate.toUtc()),
      'OUI_REQ': 'true',
    });
    final payload = <String, String>{
      r'$qd': 'false',
      r'$action': 'LOAD_RECORDS',
      r'$locale': 'en',
      r'$ls': 'false',
      r'$to': '500',
      r'$order': 'DATA_OPERATIE desc',
    };
    final res = await _http.post(
      Uri.parse(AppConfig.emsysInformatiiCont),
      headers: headers,
      body: payload,
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Portalul a raspuns cu ${res.statusCode} la informatii cont',
      );
    }
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Map<String, dynamic>? _firstRow(dynamic data) {
    if (data is List && data.isNotEmpty && data.first is Map) {
      return (data.first as Map).cast<String, dynamic>();
    }
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return null;
  }

  String? _str(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
    }
    return null;
  }
}

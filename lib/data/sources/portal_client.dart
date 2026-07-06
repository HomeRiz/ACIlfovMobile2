// ===========================================================================
//  portal_client.dart  =  CLIENT HTTP CARE FOLOSESTE SESIUNEA DE LOGIN
// ---------------------------------------------------------------------------
//  Cere date din portalul EMSYS (acilfov.emsys.ro) trimitand cookie-ul de
//  sesiune (obtinut dupa ce te-ai logat in WebView, sau pus manual in .env).
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

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../cookie_store.dart';

class PortalClient {
  final http.Client _http;
  PortalClient({http.Client? client}) : _http = client ?? http.Client();

  // ------------------------------------------------------------- identitate
  // Codul de client si numarul de contract, citite din .env (ca in addonul HA).
  // Multe endpoint-uri au nevoie de ele pe langa cookie.
  String? get codClient {
    final v = dotenv.maybeGet('ACI_COD_CLIENT');
    return (v != null && v.trim().isNotEmpty) ? v.trim() : null;
  }

  String? get nrContract {
    final v = dotenv.maybeGet('ACI_NR_CONTRACT');
    return (v != null && v.trim().isNotEmpty) ? v.trim() : null;
  }

  // Verifica faptul ca avem cod client (mesaj clar daca lipseste din .env).
  String requireCodClient() {
    final c = codClient;
    if (c == null) {
      throw StateError(
          'Lipseste ACI_COD_CLIENT din .env. Completeaza-l (vezi .env / handoff.md).');
    }
    return c;
  }

  // ---------------------------------------------------------------- sesiune
  // Cookie-ul de sesiune: intai din .env (testare), altfel din login (WebView).
  Future<String> _cookie() async {
    final envCookie = dotenv.maybeGet('ACI_SESSION_COOKIE');
    final cookie = (envCookie != null && envCookie.isNotEmpty)
        ? envCookie
        : await CookieStore.currentHeader(AppConfig.portalUrl);
    if (cookie == null || cookie.isEmpty) {
      throw StateError('Nu exista sesiune (nici in .env, nici din login).');
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
    final headers = await _headers({
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
      'codclient': requireCodClient(),
      if (nrContract != null) 'nrcontract': nrContract!,
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
    final headers = await _headers({
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
      'startDate': HttpDate.format(startDate.toUtc()),
      'endDate': HttpDate.format(endDate.toUtc()),
      'locatie': idLocatie,
      'contor': contor,
      'codClient': requireCodClient(),
      if (nrContract != null) 'nrContract': nrContract!,
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
}

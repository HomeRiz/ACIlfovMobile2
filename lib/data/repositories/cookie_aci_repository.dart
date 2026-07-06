// ===========================================================================
//  cookie_aci_repository.dart  =  SURSA "DATE REALE PRIN SESIUNE" (ACUM)
// ---------------------------------------------------------------------------
//  Aduce date REALE din portalul EMSYS (acilfov.emsys.ro) folosind sesiunea
//  de dupa login (cookie-ul) + identitatea contractului citita din portal.
//  Este solutia de tranzitie pana cand ACIlfov publica un API oficial.
//
//  Endpoint-urile si forma raspunsurilor sunt aceleasi pe care le foloseste si
//  integrarea Home Assistant (proiectul ACIlfovHA). Le centralizam in
//  AppConfig si le apelam prin PortalClient.
//
//  STARE (ce e sigur vs. ce e de verificat):
//   - getAccount()      -> SIGUR  (contract + getSoldClient, ca in HA)
//   - getMeterIndex()   -> SIGUR  (verificaPerioada + Consums, ca in HA)
//   - getInvoices()     -> BEST-EFFORT: HA nu are endpoint de facturi; folosim
//                          pattern-ul EMSYS (/facturi/Facturis). Daca portalul
//                          raspunde altfel, mapam campurile dupa Network tab.
//   - submitMeterIndex()-> BEST-EFFORT: HA e read-only, deci forma exacta a
//                          cererii de scriere nu e documentata (vezi mai jos).
//
//  ATENTIE: metoda "cookie" depinde de structura portalului si se poate
//  "sparge" daca ACIlfov schimba site-ul. API-ul oficial ramane tinta finala.
//  (vezi propunerea: docs/PROPUNERE-TEHNICA-ACILFOV.md)
// ===========================================================================

import 'dart:io' show HttpDate;

import '../../core/config/app_config.dart';
import '../models/account.dart';
import '../models/account_activity.dart';
import '../models/consumption_point.dart';
import '../models/consumption_record.dart';
import '../models/invoice.dart';
import '../models/meter_index.dart';
import '../models/payment_record.dart';
import '../sources/portal_client.dart';
import 'aci_repository.dart';

class CookieACIRepository implements ACIRepository {
  final PortalClient _portal;
  CookieACIRepository({PortalClient? portal})
      : _portal = portal ?? PortalClient();

  // ------------------------------------------------------------------ CONT
  @override
  Future<Account> getAccount() async {
    final identity = await _portal.identity();
    final cod = identity.codClient;

    // 1) Detalii contract (titular + adresa). GET, doar cookie.
    //    Raspunsul e o LISTA de contracte: [ { denClient, stareContract, ... } ]
    String holder = '';
    String address = '';
    final row = identity.contractRow;
    if (row != null) {
      holder = _str(row, ['denClient', 'numeClient', 'titular', 'nume']) ?? '';
      address = _str(row, [
            'adrClient', // numele real din portal (confirmat)
            'adresa',
            'adresaConsum',
            'adresaPunctConsum',
            'adresaClient',
          ]) ??
          '';
    }

    // 2) Sold curent. GET -> intoarce un numar simplu ca text (ex: "87.5").
    //    La EMSYS soldul e POZITIV cand ai de plata; modelul Account foloseste
    //    conventia inversa (negativ = de plata), deci il inversam.
    //    >>> De verificat semnul pe un cont real (o singura data). <<<
    double balance = 0;
    try {
      final nr = identity.nrContract;
      final url = '${AppConfig.emsysSold}?codClient=$cod'
          '${nr != null ? '&nrContract=$nr' : ''}';
      final text = (await _portal.getText(url)).trim();
      final sold = double.tryParse(text.replaceAll(',', '.')) ?? 0;
      balance = -sold;
    } catch (_) {
      // Fara sold -> ramane 0 ("La zi").
    }

    return Account(
      holderName: holder,
      clientCode: cod,
      contractNumber: identity.nrContract,
      address: address,
      balance: balance,
    );
  }

  // ---------------------------------------------------------- INFORMATII CONT
  @override
  Future<List<AccountActivity>> getAccountActivities({
    required DateTime start,
    required DateTime end,
  }) async {
    final data = await _portal.informatiiContRecords(
      startDate: start,
      endDate: end,
    );
    final records = data['records'];
    if (records is! List) return const [];

    final activities = <AccountActivity>[];
    for (var i = 0; i < records.length; i++) {
      final rec = records[i];
      final row = (rec is Map && rec['row'] is Map)
          ? (rec['row'] as Map).cast<String, dynamic>()
          : (rec is Map ? rec.cast<String, dynamic>() : null);
      if (row == null) continue;

      final operationCode = _str(row, ['operatie']) ?? '';
      activities.add(AccountActivity(
        id: _str(row, ['idOperatie', 'nrOperatie', 'id']) ?? '$i',
        clientCode: _str(row, ['codClient', 'codclient']) ?? '',
        contractNumber: _str(row, ['nrContract', 'nrcontract']) ?? '',
        operation: _correspondentValue(data, 'operatie', operationCode),
        alert: _str(row, ['alerta']) ?? '',
        email: _str(row, ['email']) ?? '',
        operationDate: _emsysDate(row['dataOperatie']),
      ));
    }
    return activities;
  }

  // -------------------------------------------------------------- FACTURI
  @override
  Future<List<Invoice>> getInvoices() async {
    final now = DateTime.now();

    // BEST-EFFORT: HA nu expune o lista de facturi. Incercam endpoint-ul
    // /facturi/Facturis dupa pattern-ul EMSYS (ca la consum / plati). Daca
    // portalul raspunde altfel, capteaza cererea reala din Network tab si
    // ajusteaza numele campurilor de mai jos.
    try {
      final data = await _portal.postRecords(
        AppConfig.emsysFacturi,
        startDate: DateTime(now.year - 2, now.month, now.day),
        endDate: now,
        payloadExtra: {r'$order': 'DATA_EMITERE desc'},
      );
      final records = data['records'];
      if (records is! List) return const [];

      final invoices = <Invoice>[];
      for (var i = 0; i < records.length; i++) {
        final rec = records[i];
        final row = (rec is Map && rec['row'] is Map)
            ? (rec['row'] as Map).cast<String, dynamic>()
            : (rec is Map ? rec.cast<String, dynamic>() : null);
        if (row == null) continue;

        final issue =
            _emsysDate(row['dataEmitere']) ?? _emsysDate(row['dataFactura']);
        final due =
            _emsysDate(row['dataScadenta']) ?? _emsysDate(row['termenPlata']);
        final amount = _double(row, [
              'valoare',
              'valoareFactura',
              'total',
              'suma',
              'valoareTotala',
            ]) ??
            0.0;
        final number = _str(row, [
              'numarFactura',
              'serieNumar',
              'numar',
              'nrFactura',
              'factura',
            ]) ??
            '';
        // "Platit" dedus din restul de plata daca exista (rest <= 0 -> platit).
        final rest = _double(row, ['rest', 'restPlata', 'restRamas', 'sold']);
        final paid = rest != null ? rest <= 0.005 : false;

        invoices.add(Invoice(
          id: '$i',
          number: number,
          issueDate: issue ?? now,
          dueDate: due ?? (issue ?? now).add(const Duration(days: 15)),
          amount: amount,
          paid: paid,
        ));
      }
      return invoices;
    } catch (_) {
      // Endpoint-ul de facturi nu e (inca) confirmat -> lista goala, nu eroare.
      return const [];
    }
  }

  // ------------------------------------------------------------------ PLATI
  @override
  Future<List<PaymentRecord>> getPayments({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final data = await _portal.postRecords(
        AppConfig.emsysPlati,
        startDate: start,
        endDate: end,
        payloadExtra: {r'$order': 'DATA_PLATA desc'},
      );
      final records = data['records'];
      if (records is! List) return const [];

      final payments = <PaymentRecord>[];
      for (var i = 0; i < records.length; i++) {
        final rec = records[i];
        final row = (rec is Map && rec['row'] is Map)
            ? (rec['row'] as Map).cast<String, dynamic>()
            : (rec is Map ? rec.cast<String, dynamic>() : null);
        if (row == null) continue;
        payments.add(PaymentRecord(
          id: '$i',
          paymentDate:
              _emsysDate(row['dataPlata']) ?? _emsysDate(row['dataOperatie']),
          amount: _double(row, [
                'valoarePlata',
                'sumaPlata',
                'valoare',
                'suma',
                'total',
              ]) ??
              0,
          document: _str(row, [
                'nrDocument',
                'numarDocument',
                'document',
                'chitanta',
                'nrChitanta',
                'ordinPlata',
              ]) ??
              '',
          method: _str(row, [
                'modalitatePlata',
                'tipPlata',
                'metodaPlata',
                'canalPlata',
              ]) ??
              '',
        ));
      }
      return payments;
    } catch (_) {
      return const [];
    }
  }

  // ----------------------------------------------------------------- INDEX
  @override
  Future<MeterIndex> getMeterIndex() async {
    final cod = await _portal.requireCodClient();
    final now = DateTime.now();

    // 1) Ziua de start a perioadei de transmitere (verificaPerioada). La ACIlfov
    //    perioada e de pe 25 pana la finalul lunii; luam ziua din API daca exista.
    int startDay = 25;
    try {
      final data =
          await _portal.getJson('${AppConfig.emsysIndexPeriod}?codClient=$cod');
      if (data is Map) {
        final parsed = int.tryParse('${data['start']}');
        if (parsed != null && parsed >= 1 && parsed <= 28) startDay = parsed;
      }
    } catch (_) {
      // Fara raspuns -> folosim regula standard (25).
    }
    final windowStart = DateTime(now.year, now.month, startDay);
    final windowEnd = DateTime(now.year, now.month + 1, 0); // ultima zi a lunii

    // 2) Ultimul index din istoricul de consum (cel mai recent rand).
    //    Folosim acelasi flux ca ecranul "Istoric consum": prima locatie +
    //    primul contor, pe un interval larg (~3 ani), luam cea mai recenta citire.
    int? lastValue;
    DateTime? lastReadDate;
    try {
      final points = await getConsumptionPoints();
      if (points.isNotEmpty && points.first.meters.isNotEmpty) {
        final p = points.first;
        final records = await getConsumption(
          idLocatie: p.idLocatie,
          contor: p.meters.first,
          start: now.subtract(const Duration(days: 1095)),
          end: now,
        );
        if (records.isNotEmpty) {
          final r = records.first; // ordonate descrescator dupa data
          lastValue = r.indexNou;
          lastReadDate = r.dataConsum;
        }
      }
    } catch (_) {
      // Fara istoric -> lastValue ramane null (ecranul afiseaza corect).
    }

    return MeterIndex(
      lastValue: lastValue,
      lastReadDate: lastReadDate,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
  }

  // -------------------------------------------------- TRANSMITERE (SCRIERE)
  @override
  Future<void> submitMeterIndex(int value) async {
    final identity = await _portal.identity();
    final cod = identity.codClient;
    final now = DateTime.now();

    // BEST-EFFORT / DE VERIFICAT:
    // Integrarea HA e strict read-only, deci forma exacta a cererii de SCRIERE
    // (transmitere index) nu e documentata nicaieri. Mai jos e o incercare
    // dupa pattern-ul EMSYS. Daca portalul raspunde cu eroare:
    //   1. Logheaza-te in portal, deschide F12 -> Network.
    //   2. Transmite un index real din pagina web.
    //   3. Copiaza cererea (URL, antete, corp) si adapteaza apelul de mai jos.
    // O singura rubrica in aplicatie -> aceeasi valoare la "index nou" si
    // "verificare index".
    await _portal.postRecords(
      AppConfig.emsysTransmitere,
      startDate: now,
      endDate: now,
      payloadExtra: {
        r'$action': 'SAVE_RECORDS',
        'codClient': cod,
        if (identity.nrContract != null) 'nrContract': identity.nrContract!,
        'indexNou': '$value',
        'verificareIndex': '$value',
      },
    );
  }

  // -------------------------------------------------------- PUNCTE CONSUM
  @override
  Future<List<ConsumptionPoint>> getConsumptionPoints() async {
    final identity = await _portal.identity();
    final cod = identity.codClient;
    final nr = identity.nrContract;
    final url = '${AppConfig.emsysPuncteConsum}?codClient=$cod'
        '${nr != null ? '&nrContract=$nr' : ''}';

    final data = await _portal.getJson(url);
    if (data is! List) return const [];

    final points = <ConsumptionPoint>[];
    for (final item in data) {
      if (item is! Map) continue;
      final row = item.cast<String, dynamic>();
      final idLocatie = _str(row, ['idLocatie', 'idlocatie', 'id']);
      if (idLocatie == null) continue;
      final meters = await _metersFor(idLocatie);
      points.add(ConsumptionPoint(
        idLocatie: idLocatie,
        clientName: _str(row, ['denClient', 'numeClient', 'titular']) ?? '',
        address: _composeAddress(row),
        meters: meters,
      ));
    }
    return points;
  }

  // Contoarele unei locatii. Endpoint-ul intoarce o lista de siruri (serii).
  Future<List<String>> _metersFor(String idLocatie) async {
    try {
      final startParam =
          Uri.encodeComponent(HttpDate.format(DateTime.now().toUtc()));
      final data = await _portal.getJson(
          '${AppConfig.emsysContoare}?idLocatie=$idLocatie&startDate=$startParam');
      if (data is List) {
        return data.map((e) => '$e'.trim()).where((s) => s.isNotEmpty).toList();
      }
    } catch (_) {
      // fara contoare -> lista goala
    }
    return const [];
  }

  // Compune adresa punctului din campurile portalului (adresa + localitate + judet).
  String _composeAddress(Map<String, dynamic> row) {
    final parts = <String>[];
    for (final k in ['adresa', 'denLocalitate', 'denJudet']) {
      final v = _str(row, [k]);
      if (v != null) parts.add(v);
    }
    return parts.join(', ');
  }

  // -------------------------------------------------------- ISTORIC CONSUM
  @override
  Future<List<ConsumptionRecord>> getConsumption({
    required String idLocatie,
    required String contor,
    required DateTime start,
    required DateTime end,
  }) async {
    final data = await _portal.consumRecords(
      idLocatie: idLocatie,
      contor: contor,
      startDate: start,
      endDate: end,
    );
    final records = data['records'];
    if (records is! List) return const [];

    final out = <ConsumptionRecord>[];
    for (final rec in records) {
      if (rec is! Map) continue;
      final row = (rec['row'] is Map)
          ? (rec['row'] as Map).cast<String, dynamic>()
          : rec.cast<String, dynamic>();
      out.add(ConsumptionRecord(
        contor: _str(row, ['contor']) ?? contor,
        dataConsum: _emsysDate(row['dataConsum']),
        indexVechi: _int(row, ['indexVechi']) ?? 0,
        indexNou: _int(row, ['indexNou']) ?? 0,
        diferenta: _int(row, ['diferenta']) ?? 0,
        tipConsum: _str(row, ['tipConsum']) ?? '',
        factura: _str(row, ['factura']) ?? '',
        dataEmitere: _emsysDate(row['dataEmitere']),
      ));
    }
    return out;
  }

  // ======================================================================
  //  Ajutoare de mapare (defensive: tolereaza campuri lipsa / tipuri diferite)
  // ======================================================================

  // Primul camp ne-gol dintr-o lista de nume posibile.
  String? _str(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
    }
    return null;
  }

  int? _int(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v is int) return v;
      if (v is num) return v.round();
      if (v is String && v.trim().isNotEmpty) {
        final n = int.tryParse(v.trim()) ??
            double.tryParse(v.trim().replaceAll(',', '.'))?.round();
        if (n != null) return n;
      }
    }
    return null;
  }

  double? _double(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v is num) return v.toDouble();
      if (v is String && v.trim().isNotEmpty) {
        final n = double.tryParse(v.trim().replaceAll(',', '.'));
        if (n != null) return n;
      }
    }
    return null;
  }

  // EMSYS trimite uneori coduri in row si dictionare de afisare in items.
  String _correspondentValue(
    Map<String, dynamic> data,
    String itemName,
    String value,
  ) {
    if (value.isEmpty) return '';
    final items = data['items'];
    final source = items is Map ? items[itemName] : null;
    if (source is List) {
      for (final item in source) {
        if (item is! Map) continue;
        final row = item.cast<String, dynamic>();
        final key = _str(row, [
          'key',
          'value',
          'cod',
          'code',
          'id',
          'name',
        ]);
        if (key != value) continue;
        return _str(row, [
              'text',
              'label',
              'descriere',
              'description',
              'name',
              'value',
            ]) ??
            value;
      }
    }
    if (source is Map) {
      final mapped = source[value];
      if (mapped != null && '$mapped'.trim().isNotEmpty) {
        return '$mapped'.trim();
      }
    }
    return value;
  }

  // Parseaza formatul EMSYS "/Date(1712345678000)/" (sau ISO) -> DateTime.
  DateTime? _emsysDate(dynamic value) {
    if (value == null) return null;
    final s = '$value';
    final m = RegExp(r'/Date\((-?\d+)').firstMatch(s);
    if (m != null) {
      final ms = int.tryParse(m.group(1)!);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return DateTime.tryParse(s);
  }
}

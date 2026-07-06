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
//   - getInvoices()     -> SIGUR  (/facturi/Facturis, confirmat din portal)
//   - submitMeterIndex()-> SIGUR  (/transmitere/add, confirmat din portal)
//
//  ATENTIE: metoda "cookie" depinde de structura portalului si se poate
//  "sparge" daca ACIlfov schimba site-ul. API-ul oficial ramane tinta finala.
//  (vezi propunerea: docs/PROPUNERE-TEHNICA-ACILFOV.md)
// ===========================================================================

import 'dart:io' show HttpDate;

import '../../core/config/app_config.dart';
import '../models/account.dart';
import '../models/account_activity.dart';
import '../models/contact_option.dart';
import '../models/consumption_point.dart';
import '../models/consumption_record.dart';
import '../models/invoice.dart';
import '../models/linked_account.dart';
import '../models/meter_index.dart';
import '../models/payment_record.dart';
import '../models/portal_config.dart';
import '../sources/portal_client.dart';
import 'aci_repository.dart';

class CookieACIRepository implements ACIRepository {
  final PortalClient _portal;
  CookieACIRepository({PortalClient? portal})
      : _portal = portal ?? PortalClient();

  // ------------------------------------------------------- ACTIUNI PORTAL
  @override
  Future<ContactOptions> getContactOptions() async {
    final clients = await _portal.getJson(AppConfig.emsysContactCodClients);
    final motives = await _portal.getJson(AppConfig.emsysContactMotives);
    final subjects = await _portal.getJson(AppConfig.emsysContactSubjects);
    final length = await _portal.getJson(AppConfig.emsysContactMessageLength);

    String? defaultContactValue;
    try {
      final session = await _portal.postJson(AppConfig.emsysInfoSession, {});
      if (session is Map) {
        defaultContactValue = _str(session.cast<String, dynamic>(), [
          'userName',
          'username',
          'email',
        ]);
      }
    } catch (_) {
      defaultContactValue = null;
    }

    return ContactOptions(
      clientCodes: clients is List
          ? clients
              .map((e) => '$e'.trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
      motives: _contactOptions(
        motives,
        idKeys: const ['idMotiv', 'id', 'key'],
        labelKeys: const ['motiv', 'label', 'value'],
      ),
      subjects: _contactOptions(
        subjects,
        idKeys: const ['idSubiect', 'id', 'key'],
        labelKeys: const ['subiect', 'label', 'value'],
      ),
      minimumMessageLength: _int({'length': length}, ['length']) ?? 20,
      defaultContactValue: defaultContactValue,
    );
  }

  @override
  Future<void> sendContactMessage({
    required String clientCode,
    required ContactOption motive,
    required ContactOption subject,
    required String contactMethod,
    required String contactValue,
    required String message,
  }) async {
    final response = await _portal.postJson(AppConfig.emsysContactSend, {
      'codClient': clientCode,
      'idMotiv': motive.id,
      'idSubiect': subject.id,
      'numeFisier': null,
      'metodaContactare': contactMethod,
      'valMetodaContactare': contactValue,
      'mesaj': message,
      'motiv': motive.label,
      'subiect': subject.label,
    });
    _throwIfPortalError(response);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _portal.postJson(AppConfig.emsysChangePassword, {
      'password': currentPassword,
      'newPassword': newPassword,
    });
    _throwIfPortalError(response);
  }

  @override
  Future<void> deletePortalAccount() async {
    final response = await _portal.postJson(AppConfig.emsysDeleteAccount, {});
    _throwIfPortalError(response);
  }

  @override
  Future<List<LinkedAccount>> getLinkedAccounts() async {
    final data = await _portal.getJson(AppConfig.emsysContract);
    if (data is! List) return const [];
    return data.whereType<Map>().map((item) {
      final row = item.cast<String, dynamic>();
      return LinkedAccount(
        clientCode: _str(row, ['codClient', 'codclient']) ?? '',
        contractNumber: _str(row, ['nrContract', 'nrcontract']) ?? '',
        holderName: _str(row, ['denClient', 'numeClient', 'titular']) ?? '',
        address: _str(row, ['adrClient', 'adresaClient', 'adresa']) ?? '',
        raw: row,
      );
    }).where((e) => e.clientCode.isNotEmpty).toList();
  }

  @override
  Future<void> addClientContract({
    required String clientCode,
    required String contractNumber,
  }) async {
    final response = await _portal.postJson(AppConfig.emsysAddClientContract, {
      'codClient': clientCode,
      'nrContract': contractNumber,
    });
    _throwIfPortalError(response);
  }

  @override
  Future<List<String>> getClientCodesWithoutContracts() async {
    final data = await _portal.getJson(AppConfig.emsysClientCodesWithoutContracts);
    return data is List
        ? data.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList()
        : const [];
  }

  @override
  Future<List<String>> getContractsWithoutClient(String clientCode) async {
    final uri = Uri.parse(AppConfig.emsysContractsWithoutClient)
        .replace(queryParameters: {'codClient': clientCode});
    final data = await _portal.getJson(uri.toString());
    return data is List
        ? data.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList()
        : const [];
  }

  @override
  Future<void> addContract({
    required String clientCode,
    required String contractNumber,
  }) async {
    final response = await _portal.postJson(AppConfig.emsysAddContract, {
      'codClient': clientCode,
      'nrContract': contractNumber,
    });
    _throwIfPortalError(response);
  }

  @override
  Future<void> deleteClientCodes(List<String> clientCodes) async {
    if (clientCodes.isEmpty) return;
    final uri = Uri.parse(AppConfig.emsysDeleteClientCode).replace(
      queryParameters: {'codClients': clientCodes.join(',')},
    );
    final response = await _portal.deleteJson(uri.toString());
    _throwIfPortalError(response);
  }

  @override
  Future<List<InvoiceDeliveryConfig>> getInvoiceDeliveryConfigs(
    String mode,
  ) async {
    final id = await _portal.identity();
    final data = await _portal.loadRecords(
      AppConfig.emsysInvoiceDeliveryConfigs,
      headersExtra: {
        'codClient': id.codClient,
        'modTrimitere': mode,
      },
      payloadExtra: {r'$order': 'DATA_OPERATIE desc'},
    );
    final records = data['records'];
    if (records is! List) return const [];
    return records.map(_recordRow).whereType<Map<String, dynamic>>().map((row) {
      return InvoiceDeliveryConfig(
        mode: mode,
        destination: _str(row, ['email', 'telefon', 'trimitereValue']) ?? '',
        operationDate: _emsysDate(row['dataOperatie']),
        raw: row,
      );
    }).where((e) => e.destination.isNotEmpty).toList();
  }

  @override
  Future<void> activateInvoiceDelivery({
    required String mode,
    required String destination,
  }) async {
    final id = await _portal.identity();
    final response = await _portal.postJson(
      AppConfig.emsysActivateInvoiceDelivery,
      {
        'modeTrimitere': mode,
        'trimitereValue': destination,
        'isAccept': true,
      },
      headersExtra: {'codClient': id.codClient},
    );
    _throwIfPortalError(response);
  }

  @override
  Future<void> deactivateInvoiceDelivery({
    required String mode,
    required InvoiceDeliveryConfig config,
  }) async {
    final id = await _portal.identity();
    final response = await _portal.postJson(
      AppConfig.emsysDeactivateInvoiceDelivery,
      config.raw,
      headersExtra: {
        'codClient': id.codClient,
        'modTrimitereFact': mode,
      },
    );
    _throwIfPortalError(response);
  }

  @override
  Future<List<AlertConfig>> getAlertConfigs() async {
    final id = await _portal.identity();
    final data = await _portal.loadRecords(
      AppConfig.emsysAlertConfigs,
      headersExtra: {'codClient': id.codClient},
    );
    final records = data['records'];
    if (records is! List) return const [];
    return records.map(_recordRow).whereType<Map<String, dynamic>>().map((row) {
      final code = _str(row, ['alerta']) ?? '';
      return AlertConfig(
        code: code,
        label: _correspondentValue(data, 'alerta', code),
        active: (_str(row, ['activataClient']) ?? '').toUpperCase() == 'DA',
        email: _str(row, ['emailClient']),
        phone: _str(row, ['telefonClient']),
        emailAllowed: (_str(row, ['prinEmail']) ?? 'DA').toUpperCase() == 'DA',
        smsAllowed: (_str(row, ['prinSms']) ?? 'DA').toUpperCase() == 'DA',
        raw: row,
      );
    }).where((e) => e.code.isNotEmpty).toList();
  }

  @override
  Future<void> saveAlertConfig(AlertConfig config) async {
    final id = await _portal.identity();
    final row = Map<String, dynamic>.from(config.raw);
    row['activataClient'] = config.active ? 'DA' : 'NU';
    if (config.active) {
      if (config.emailAllowed) {
        row['prinEmailClient'] =
            (config.email ?? '').trim().isEmpty ? 'NU' : 'DA';
        row['bifatPrinEmail'] = row['prinEmailClient'] == 'DA';
        row['emailClient'] = (config.email ?? '').trim();
      }
      if (config.smsAllowed) {
        row['prinSmsClient'] =
            (config.phone ?? '').trim().isEmpty ? 'NU' : 'DA';
        row['bifatPrinSms'] = row['prinSmsClient'] == 'DA';
        row['telefonClient'] = (config.phone ?? '').trim();
      }
    } else {
      row['prinEmailClient'] = 'NU';
      row['prinSmsClient'] = 'NU';
      row['bifatPrinEmail'] = false;
      row['bifatPrinSms'] = false;
      row['emailClient'] = null;
      row['telefonClient'] = null;
    }
    final response = await _portal.postJson(
      AppConfig.emsysAlertConfig,
      row,
      headersExtra: {'codClient': id.codClient},
    );
    _throwIfPortalError(response);
  }

  @override
  Future<CompanyNotificationConfig> getCompanyNotificationConfig() async {
    final id = await _portal.identity();
    final uri = Uri.parse(AppConfig.emsysCompanyNotifications)
        .replace(queryParameters: {'codClient': id.codClient});
    final data = await _portal.getJson(uri.toString());
    final row = data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
    return CompanyNotificationConfig(
      emailAccepted: row['primireNotificariCompanie'] == true,
      smsAccepted: row['primireNotificariCompanieSms'] == true,
      phone: _str(row, ['telefonNotificari']),
      raw: row,
    );
  }

  @override
  Future<void> saveCompanyNotificationConfig(
    CompanyNotificationConfig config,
  ) async {
    final id = await _portal.identity();
    final row = Map<String, dynamic>.from(config.raw);
    row['primireNotificariCompanie'] = config.emailAccepted;
    row['primireNotificariCompanieSms'] = config.smsAccepted;
    row['telefonNotificari'] = config.smsAccepted ? config.phone : null;
    final response = await _portal.postJson(
      AppConfig.emsysModifyCompanyNotifications,
      row,
      headersExtra: {'codClient': id.codClient},
    );
    _throwIfPortalError(response);
  }

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

    try {
      final data = await _portal.facturiRecords(
        startDate: DateTime(now.year - 2, now.month, now.day),
        endDate: now,
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

        final issue = _emsysDate(row['dataEmitere']) ??
            _emsysDate(row['dataFactura']) ??
            _emsysDate(row['dataDoc']);
        final due =
            _emsysDate(row['dataScadenta']) ?? _emsysDate(row['termenPlata']);
        final amount = _double(row, [
              'valoareFactura',
              'valoare',
              'total',
              'suma',
              'valoareTotala',
            ]) ??
            0.0;
        final number = _str(row, [
              'factura',
              'numarFactura',
              'serieNumar',
              'numar',
              'nrFactura',
            ]) ??
            '';
        // "Platit" dedus din restul de plata daca exista (rest <= 0 -> platit).
        final rest =
            _double(row, ['restDePlata', 'rest', 'restPlata', 'restRamas']);
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
    final nr = identity.nrContract;
    final puncte = await _portal.getJson(
      '${AppConfig.emsysTransmiterePuncte}?codClient=$cod'
      '${nr != null ? '&nrContract=$nr' : ''}',
    );
    if (puncte is! List || puncte.isEmpty || puncte.first is! Map) {
      throw StateError('Nu exista punct de consum pentru transmiterea indexului.');
    }
    final punct = (puncte.first as Map).cast<String, dynamic>();
    final idLocatie = _str(punct, ['idLocatie', 'idlocatie', 'id']);
    if (idLocatie == null) {
      throw StateError('Punctul de consum nu are idLocatie.');
    }

    final data = await _portal.loadRecords(
      AppConfig.emsysTransmitere,
      headersExtra: {'puncteConsum': idLocatie},
    );
    final records = data['records'];
    if (records is! List || records.isEmpty) {
      throw StateError('Portalul nu a intors niciun contor pentru transmitere.');
    }
    final row = _recordRow(records.first);
    if (row == null) {
      throw StateError('Raspunsul portalului pentru contor nu poate fi citit.');
    }
    row['indexNou'] = value;
    row['indexNouConf'] = value;
    final response = await _portal.postJson(AppConfig.emsysTransmitereAdd, row);
    _throwIfPortalError(response);
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

  List<ContactOption> _contactOptions(
    dynamic data, {
    required List<String> idKeys,
    required List<String> labelKeys,
  }) {
    if (data is! List) return const [];
    return data.whereType<Map>().map((item) {
      final row = item.cast<String, dynamic>();
      return ContactOption(
        id: _str(row, idKeys) ?? '',
        label: _str(row, labelKeys) ?? '',
      );
    }).where((e) => e.id.isNotEmpty && e.label.isNotEmpty).toList();
  }

  Map<String, dynamic>? _recordRow(dynamic rec) {
    if (rec is! Map) return null;
    if (rec['row'] is Map) {
      return (rec['row'] as Map).cast<String, dynamic>();
    }
    return rec.cast<String, dynamic>();
  }

  void _throwIfPortalError(dynamic response) {
    final message = _portalErrorMessage(response);
    if (message != null && message.isNotEmpty) {
      throw Exception(message);
    }
  }

  String? _portalErrorMessage(dynamic response) {
    if (response is String) {
      return null;
    }
    if (response is! Map) return null;
    final data = response.cast<String, dynamic>();
    if (data['messageType'] == 'ERROR') {
      return _str(data, ['message']) ?? 'Portalul a intors o eroare.';
    }
    final direct = _messageListError(data['messageList']);
    if (direct != null) return direct;
    final row = data['row'];
    if (data['error'] == true && row is Map) {
      return _messageListError(row['messageList']) ??
          _str(row.cast<String, dynamic>(), ['message', 'detailedMessage']);
    }
    return null;
  }

  String? _messageListError(dynamic value) {
    if (value is! List || value.isEmpty || value.first is! Map) return null;
    final row = (value.first as Map).cast<String, dynamic>();
    return _str(row, ['detailedMessage', 'message']) ??
        'Portalul a intors o eroare.';
  }

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

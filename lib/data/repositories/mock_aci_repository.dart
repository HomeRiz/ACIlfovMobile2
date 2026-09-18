// ===========================================================================
//  mock_aci_repository.dart  =  SURSA "DATE DE TEST"
// ---------------------------------------------------------------------------
//  Intoarce date fixe, ca sa poti construi si vedea ecranele native inainte
//  sa existe API-ul (sau fara sa te loghezi). Simuleaza si o mica intarziere,
//  ca sa vezi cum arata aplicatia in timp ce "incarca".
// ===========================================================================

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
import 'aci_repository.dart';

class MockACIRepository implements ACIRepository {
  // Stare in memorie pentru Configurari, ca sa para ca setarile chiar se
  // salveaza in timpul unei sesiuni demo (nu se pastreaza intre porniri ale
  // aplicatiei - doar cat tine sesiunea curenta).
  final Map<String, InvoiceDeliveryConfig?> _invoiceDelivery = {
    'EMAIL': InvoiceDeliveryConfig(
      mode: 'EMAIL',
      destination: 'EMAIL_TEST',
      operationDate: DateTime.now().subtract(const Duration(days: 10)),
    ),
  };

  List<AlertConfig> _alertConfigs = const [
    AlertConfig(
      code: 'ALERTA_EMITERE_FACTURA',
      label: 'Emitere factura',
      active: true,
      email: '',
    ),
    AlertConfig(
      code: 'ALERTA_SCADENTA_AUTOCIT',
      label: 'Scadenta autocitire',
      active: false,
    ),
  ];

  CompanyNotificationConfig _companyConfig = const CompanyNotificationConfig(
    emailAccepted: true,
    smsAccepted: false,
  );

  @override
  Future<Account> getAccount() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const Account(
      holderName: 'Client demonstrativ',
      clientCode: 'CLIENT_TEST',
      address: 'Adresa demonstrativa',
      balance: -87.50,
    );
  }

  @override
  Future<List<AccountActivity>> getAccountActivities({
    required DateTime start,
    required DateTime end,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return [
      AccountActivity(
        id: '101',
        clientCode: 'CLIENT_TEST',
        contractNumber: 'CONTRACT_TEST',
        operation: 'Inregistrare index',
        alert: '',
        email: '',
        operationDate: now.subtract(const Duration(days: 8)),
      ),
      AccountActivity(
        id: '100',
        clientCode: 'CLIENT_TEST',
        contractNumber: 'CONTRACT_TEST',
        operation: 'Trimitere mesaj companie',
        alert: '',
        email: '',
        operationDate: now.subtract(const Duration(days: 18)),
      ),
      AccountActivity(
        id: '99',
        clientCode: 'CLIENT_TEST',
        contractNumber: 'CONTRACT_TEST',
        operation: 'Activare factura pe email',
        alert: '',
        email: '',
        operationDate: now.subtract(const Duration(days: 40)),
      ),
    ];
  }

  @override
  Future<List<Invoice>> getInvoices() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return [
      Invoice(
        id: '1',
        number: 'FACTURA-TEST-001',
        issueDate: now.subtract(const Duration(days: 5)),
        dueDate: now.add(const Duration(days: 10)),
        amount: 87.50,
        paid: false,
      ),
      Invoice(
        id: '2',
        number: 'FACTURA-TEST-002',
        issueDate: now.subtract(const Duration(days: 35)),
        dueDate: now.subtract(const Duration(days: 20)),
        amount: 92.30,
        paid: true,
      ),
      Invoice(
        id: '3',
        number: 'FACTURA-TEST-003',
        issueDate: now.subtract(const Duration(days: 65)),
        dueDate: now.subtract(const Duration(days: 50)),
        amount: 79.10,
        paid: true,
      ),
    ];
  }

  @override
  Future<List<PaymentRecord>> getPayments({
    required DateTime start,
    required DateTime end,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      PaymentRecord(
        id: '1',
        paymentDate: DateTime.now().subtract(const Duration(days: 20)),
        amount: 92.30,
        document: 'PLATA-TEST-001',
        method: 'Online',
      ),
    ];
  }

  int _lastMeterValue = 1420;
  DateTime _lastMeterReadDate = DateTime(
    DateTime.now().year,
    DateTime.now().month - 1,
    26,
  );

  @override
  Future<MeterIndex> getMeterIndex() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return MeterIndex(
      lastValue: _lastMeterValue,
      lastReadDate: _lastMeterReadDate,
      // Regula ACIlfov: perioada de transmitere e de pe 25 pana la finalul lunii.
      windowStart: DateTime(now.year, now.month, 25),
      windowEnd: DateTime(now.year, now.month + 1, 0), // ultima zi a lunii
    );
  }

  @override
  Future<void> submitMeterIndex(int value) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _lastMeterValue = value;
    _lastMeterReadDate = DateTime.now();
  }

  @override
  Future<ContactOptions> getContactOptions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const ContactOptions(
      clientCodes: ['CLIENT_TEST'],
      motives: [
        ContactOption(id: '1', label: 'Sesizare'),
        ContactOption(id: '2', label: 'Solicitare'),
      ],
      subjects: [
        ContactOption(id: '1', label: 'Informatii contract'),
        ContactOption(id: '2', label: 'Facturi si plati'),
      ],
      minimumMessageLength: 20,
      defaultContactValue: '',
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
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> deletePortalAccount() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<List<LinkedAccount>> getLinkedAccounts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      LinkedAccount(
        clientCode: 'CLIENT_TEST',
        contractNumber: 'CONTRACT_TEST',
        holderName: 'Client demonstrativ',
        address: 'Adresa demonstrativa',
      ),
    ];
  }

  @override
  Future<void> addClientContract({
    required String clientCode,
    required String contractNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<List<String>> getClientCodesWithoutContracts() async => const [
        'CLIENT_TEST',
      ];

  @override
  Future<List<String>> getContractsWithoutClient(String clientCode) async =>
      const ['CONTRACT_TEST_2'];

  @override
  Future<void> addContract({
    required String clientCode,
    required String contractNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> deleteClientCodes(List<String> clientCodes) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<String?> getSessionEmail() async => 'client.demo@exemplu.ro';

  @override
  Future<List<InvoiceDeliveryConfig>> getInvoiceDeliveryConfigs(
    String mode,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final config = _invoiceDelivery[mode];
    return config == null ? [] : [config];
  }

  @override
  Future<void> activateInvoiceDelivery({
    required String mode,
    required String destination,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _invoiceDelivery[mode] = InvoiceDeliveryConfig(
      mode: mode,
      destination: destination,
      operationDate: DateTime.now(),
    );
  }

  @override
  Future<void> deactivateInvoiceDelivery({
    required String mode,
    required InvoiceDeliveryConfig config,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _invoiceDelivery[mode] = null;
  }

  @override
  Future<List<AlertConfig>> getAlertConfigs() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _alertConfigs;
  }

  @override
  Future<void> saveAlertConfig(AlertConfig config) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _alertConfigs = [
      for (final existing in _alertConfigs)
        if (existing.code == config.code) config else existing,
    ];
  }

  @override
  Future<CompanyNotificationConfig> getCompanyNotificationConfig() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _companyConfig;
  }

  @override
  Future<void> saveCompanyNotificationConfig(
    CompanyNotificationConfig config,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _companyConfig = config;
  }

  @override
  Future<List<ConsumptionPoint>> getConsumptionPoints() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      ConsumptionPoint(
        idLocatie: '1',
        clientName: 'Client demonstrativ',
        address: 'Adresa demonstrativa',
        meters: ['CONTOR_TEST'],
      ),
    ];
  }

  @override
  Future<List<ConsumptionRecord>> getConsumption({
    required String idLocatie,
    required String contor,
    required DateTime start,
    required DateTime end,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final list = <ConsumptionRecord>[];
    var d = DateTime(start.year, start.month, 1);
    var index = 500;
    while (!d.isAfter(end)) {
      final consum = 8 + (d.month % 6);
      list.add(ConsumptionRecord(
        contor: contor,
        dataConsum: DateTime(d.year, d.month, 1),
        indexVechi: index,
        indexNou: index + consum,
        diferenta: consum,
        tipConsum: 'CITIRE',
        factura: '',
        dataEmitere: null,
      ));
      index += consum;
      d = DateTime(d.year, d.month + 1, 1);
    }
    return list.reversed.toList(); // cele mai noi sus
  }
}

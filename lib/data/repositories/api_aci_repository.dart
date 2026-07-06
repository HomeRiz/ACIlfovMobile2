// ===========================================================================
//  api_aci_repository.dart  =  SURSA "API OFICIAL" (VIITOR)
// ---------------------------------------------------------------------------
//  Implementarea reala, cand ACIlfov va publica API-ul. Structura e completa;
//  cand primesti documentatia API, trebuie doar:
//    1. sa pui caile corecte (endpoint-urile) unde scrie "TODO";
//    2. sa setezi AppConfig.dataSource = DataSource.api.
//  Ecranele si restul aplicatiei raman NEATINSE.
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
import '../sources/api_client.dart';
import 'aci_repository.dart';

class ApiACIRepository implements ACIRepository {
  final ApiClient _api;
  ApiACIRepository({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  Future<Account> getAccount() async {
    final json = await _api.getJson('/account'); // TODO: calea reala
    return Account.fromJson(json);
  }

  @override
  Future<List<AccountActivity>> getAccountActivities({
    required DateTime start,
    required DateTime end,
  }) async {
    // TODO: cand exista API oficial, mapeaza raspunsul la AccountActivity.
    return const [];
  }

  @override
  Future<List<Invoice>> getInvoices() async {
    final json = await _api.getJson('/invoices'); // TODO: calea reala
    final list = (json['items'] as List).cast<Map<String, dynamic>>();
    return list.map(Invoice.fromJson).toList();
  }

  @override
  Future<List<PaymentRecord>> getPayments({
    required DateTime start,
    required DateTime end,
  }) async {
    // TODO: cand exista API oficial, mapeaza raspunsul la PaymentRecord.
    return const [];
  }

  @override
  Future<MeterIndex> getMeterIndex() async {
    final json = await _api.getJson('/meter-index'); // TODO: calea reala
    return MeterIndex.fromJson(json);
  }

  @override
  Future<void> submitMeterIndex(int value) async {
    // O singura rubrica in aplicatie -> trimitem aceeasi valoare la ambele
    // campuri pe care le cere portalul: "index nou" si "verificare index".
    await _api.postJson('/meter-index', {
      'index_nou': value,
      'verificare_index': value,
    }); // TODO: numele reale ale campurilor/caii
  }

  @override
  Future<ContactOptions> getContactOptions() {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<void> sendContactMessage({
    required String clientCode,
    required ContactOption motive,
    required ContactOption subject,
    required String contactMethod,
    required String contactValue,
    required String message,
  }) {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<void> deletePortalAccount() {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<List<LinkedAccount>> getLinkedAccounts() {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<void> addClientContract({
    required String clientCode,
    required String contractNumber,
  }) {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<List<String>> getClientCodesWithoutContracts() {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<List<String>> getContractsWithoutClient(String clientCode) {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<void> addContract({
    required String clientCode,
    required String contractNumber,
  }) {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<void> deleteClientCodes(List<String> clientCodes) {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<List<InvoiceDeliveryConfig>> getInvoiceDeliveryConfigs(String mode) {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<void> activateInvoiceDelivery({
    required String mode,
    required String destination,
  }) {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<void> deactivateInvoiceDelivery({
    required String mode,
    required InvoiceDeliveryConfig config,
  }) {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<List<AlertConfig>> getAlertConfigs() {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<void> saveAlertConfig(AlertConfig config) {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<CompanyNotificationConfig> getCompanyNotificationConfig() {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<void> saveCompanyNotificationConfig(
    CompanyNotificationConfig config,
  ) {
    throw UnimplementedError('API-ul oficial ACIlfov nu este configurat.');
  }

  @override
  Future<List<ConsumptionPoint>> getConsumptionPoints() async {
    // TODO: cand exista API oficial, mapeaza raspunsul la ConsumptionPoint.
    return const [];
  }

  @override
  Future<List<ConsumptionRecord>> getConsumption({
    required String idLocatie,
    required String contor,
    required DateTime start,
    required DateTime end,
  }) async {
    // TODO: cand exista API oficial, mapeaza raspunsul la ConsumptionRecord.
    return const [];
  }
}

// ===========================================================================
//  switchable_aci_repository.dart  =  COMUTATOR DE REPOSITORY LA RUNTIME
// ---------------------------------------------------------------------------
//  Foloseste ACELASI repository peste tot in aplicatie (injectat o singura
//  data in main.dart), dar poate trece intre sursa reala (portal) si sursa
//  demo (date generate) in timpul rularii, fara sa repornesti aplicatia.
//
//  DE CE: butonul "Verificare / Demo" de pe ecranul de login (pentru ACIlfov, ca
//  sa poata vedea aplicatia fara un cont real de la ei) trebuie sa activeze
//  datele demo doar pentru sesiunea curenta, fara sa atinga vreun ecran -
//  ecranele continua sa citeasca ACIRepository exact ca inainte.
// ===========================================================================

import '../models/account.dart';
import '../models/account_activity.dart';
import '../models/consumption_point.dart';
import '../models/consumption_record.dart';
import '../models/contact_option.dart';
import '../models/invoice.dart';
import '../models/linked_account.dart';
import '../models/meter_index.dart';
import '../models/payment_record.dart';
import '../models/portal_config.dart';
import 'aci_repository.dart';

class SwitchableACIRepository implements ACIRepository {
  SwitchableACIRepository({required this.real, required this.demo});

  final ACIRepository real;
  final ACIRepository demo;

  bool useDemo = false;

  ACIRepository get _active => useDemo ? demo : real;

  @override
  Future<Account> getAccount() => _active.getAccount();

  @override
  Future<List<Invoice>> getInvoices() => _active.getInvoices();

  @override
  Future<List<AccountActivity>> getAccountActivities({
    required DateTime start,
    required DateTime end,
  }) =>
      _active.getAccountActivities(start: start, end: end);

  @override
  Future<List<PaymentRecord>> getPayments({
    required DateTime start,
    required DateTime end,
  }) =>
      _active.getPayments(start: start, end: end);

  @override
  Future<MeterIndex> getMeterIndex() => _active.getMeterIndex();

  @override
  Future<void> submitMeterIndex(int value) => _active.submitMeterIndex(value);

  @override
  Future<ContactOptions> getContactOptions() => _active.getContactOptions();

  @override
  Future<void> sendContactMessage({
    required String clientCode,
    required ContactOption motive,
    required ContactOption subject,
    required String contactMethod,
    required String contactValue,
    required String message,
  }) =>
      _active.sendContactMessage(
        clientCode: clientCode,
        motive: motive,
        subject: subject,
        contactMethod: contactMethod,
        contactValue: contactValue,
        message: message,
      );

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _active.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  @override
  Future<void> deletePortalAccount() => _active.deletePortalAccount();

  @override
  Future<List<LinkedAccount>> getLinkedAccounts() =>
      _active.getLinkedAccounts();

  @override
  Future<void> addClientContract({
    required String clientCode,
    required String contractNumber,
  }) =>
      _active.addClientContract(
        clientCode: clientCode,
        contractNumber: contractNumber,
      );

  @override
  Future<List<String>> getClientCodesWithoutContracts() =>
      _active.getClientCodesWithoutContracts();

  @override
  Future<List<String>> getContractsWithoutClient(String clientCode) =>
      _active.getContractsWithoutClient(clientCode);

  @override
  Future<void> addContract({
    required String clientCode,
    required String contractNumber,
  }) =>
      _active.addContract(
        clientCode: clientCode,
        contractNumber: contractNumber,
      );

  @override
  Future<void> deleteClientCodes(List<String> clientCodes) =>
      _active.deleteClientCodes(clientCodes);

  @override
  Future<String?> getSessionEmail() => _active.getSessionEmail();

  @override
  Future<List<InvoiceDeliveryConfig>> getInvoiceDeliveryConfigs(
    String mode,
  ) =>
      _active.getInvoiceDeliveryConfigs(mode);

  @override
  Future<void> activateInvoiceDelivery({
    required String mode,
    required String destination,
  }) =>
      _active.activateInvoiceDelivery(mode: mode, destination: destination);

  @override
  Future<void> deactivateInvoiceDelivery({
    required String mode,
    required InvoiceDeliveryConfig config,
  }) =>
      _active.deactivateInvoiceDelivery(mode: mode, config: config);

  @override
  Future<List<AlertConfig>> getAlertConfigs() => _active.getAlertConfigs();

  @override
  Future<void> saveAlertConfig(AlertConfig config) =>
      _active.saveAlertConfig(config);

  @override
  Future<CompanyNotificationConfig> getCompanyNotificationConfig() =>
      _active.getCompanyNotificationConfig();

  @override
  Future<void> saveCompanyNotificationConfig(
    CompanyNotificationConfig config,
  ) =>
      _active.saveCompanyNotificationConfig(config);

  @override
  Future<List<ConsumptionPoint>> getConsumptionPoints() =>
      _active.getConsumptionPoints();

  @override
  Future<List<ConsumptionRecord>> getConsumption({
    required String idLocatie,
    required String contor,
    required DateTime start,
    required DateTime end,
  }) =>
      _active.getConsumption(
        idLocatie: idLocatie,
        contor: contor,
        start: start,
        end: end,
      );
}

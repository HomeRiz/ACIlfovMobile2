// ===========================================================================
//  aci_repository.dart  =  "CONTRACTUL" DE DATE (interfata)
// ---------------------------------------------------------------------------
//  Acesta este PUNCTUL-CHEIE al arhitecturii. Ecranele nu stiu si nu le pasa
//  DE UNDE vin datele - ele cunosc doar acest "contract" (ce metode exista).
//
//  Contractul este implementat de trei clase interschimbabile:
//    - MockACIRepository   -> date de test
//    - CookieACIRepository -> date reale din portal, prin sesiunea de login
//    - ApiACIRepository    -> API-ul oficial ACIlfov (viitor)
//
//  Cand apare API-ul, schimbi sursa in AppConfig.dataSource si GATA: ecranele
//  raman neatinse. Asta face tranzitia foarte usoara.
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

abstract class ACIRepository {
  Future<Account> getAccount(); // datele contului
  Future<List<Invoice>> getInvoices(); // lista de facturi
  Future<List<AccountActivity>> getAccountActivities({
    required DateTime start,
    required DateTime end,
  }); // informatii cont / istoric operatii
  Future<List<PaymentRecord>> getPayments({
    required DateTime start,
    required DateTime end,
  }); // istoricul platilor
  Future<MeterIndex> getMeterIndex(); // indexul + perioada de transmitere
  Future<void> submitMeterIndex(int value); // trimite un index nou

  Future<ContactOptions> getContactOptions();
  Future<void> sendContactMessage({
    required String clientCode,
    required ContactOption motive,
    required ContactOption subject,
    required String contactMethod,
    required String contactValue,
    required String message,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> deletePortalAccount();

  Future<List<LinkedAccount>> getLinkedAccounts();
  Future<void> addClientContract({
    required String clientCode,
    required String contractNumber,
  });
  Future<List<String>> getClientCodesWithoutContracts();
  Future<List<String>> getContractsWithoutClient(String clientCode);
  Future<void> addContract({
    required String clientCode,
    required String contractNumber,
  });
  Future<void> deleteClientCodes(List<String> clientCodes);

  /// Emailul cu care s-a autentificat userul, luat din sesiunea portalului.
  /// `null` daca sesiunea nu il ofera. Il folosim ca sa nu mai ceara nimeni
  /// userului sa scrie aceeasi adresa la fiecare optiune de notificare.
  Future<String?> getSessionEmail();

  Future<List<InvoiceDeliveryConfig>> getInvoiceDeliveryConfigs(String mode);
  Future<void> activateInvoiceDelivery({
    required String mode,
    required String destination,
  });
  Future<void> deactivateInvoiceDelivery({
    required String mode,
    required InvoiceDeliveryConfig config,
  });
  Future<List<AlertConfig>> getAlertConfigs();
  Future<void> saveAlertConfig(AlertConfig config);
  Future<CompanyNotificationConfig> getCompanyNotificationConfig();
  Future<void> saveCompanyNotificationConfig(CompanyNotificationConfig config);

  // Punctele de consum (locatii + contoare) ale clientului.
  Future<List<ConsumptionPoint>> getConsumptionPoints();

  // Istoricul de consum pentru o locatie + contor, intr-un interval de timp.
  Future<List<ConsumptionRecord>> getConsumption({
    required String idLocatie,
    required String contor,
    required DateTime start,
    required DateTime end,
  });
}

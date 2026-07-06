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
import '../models/consumption_point.dart';
import '../models/consumption_record.dart';
import '../models/invoice.dart';
import '../models/meter_index.dart';
import '../models/payment_record.dart';

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

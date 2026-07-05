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
import '../models/invoice.dart';
import '../models/meter_index.dart';

abstract class ACIRepository {
  Future<Account> getAccount();          // datele contului
  Future<List<Invoice>> getInvoices();   // lista de facturi
  Future<MeterIndex> getMeterIndex();    // indexul + perioada de transmitere
  Future<void> submitMeterIndex(int value); // trimite un index nou
}

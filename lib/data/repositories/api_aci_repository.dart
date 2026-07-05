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
import '../models/invoice.dart';
import '../models/meter_index.dart';
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
  Future<List<Invoice>> getInvoices() async {
    final json = await _api.getJson('/invoices'); // TODO: calea reala
    final list = (json['items'] as List).cast<Map<String, dynamic>>();
    return list.map(Invoice.fromJson).toList();
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
}

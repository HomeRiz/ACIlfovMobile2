// ===========================================================================
//  account_provider.dart  =  DATELE CONTULUI (cont, facturi, index)
// ---------------------------------------------------------------------------
//  Cere datele prin repository (indiferent de sursa) si le tine la dispozitia
//  ecranelor. Dupa ce le are, programeaza notificarile locale relevante.
// ===========================================================================

import 'package:flutter/foundation.dart';

import '../data/models/account.dart';
import '../data/models/invoice.dart';
import '../data/models/meter_index.dart';
import '../data/repositories/aci_repository.dart';
import '../services/notification_service.dart';

class AccountProvider extends ChangeNotifier {
  AccountProvider(this._repo);

  final ACIRepository _repo;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Account? account;
  List<Invoice> invoices = [];
  MeterIndex? meterIndex;

  // Incarca toate datele contului. Apelat la intrarea in aplicatie si la
  // "trage pentru reimprospatare".
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      account = await _repo.getAccount();
      invoices = await _repo.getInvoices();
      meterIndex = await _repo.getMeterIndex();
      await _scheduleNotifications();
    } catch (e) {
      _error = 'Nu am putut incarca datele: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Trimite un index nou, apoi reincarca indexul actualizat.
  Future<void> submitIndex(int value) async {
    await _repo.submitMeterIndex(value);
    meterIndex = await _repo.getMeterIndex();
    notifyListeners();
  }

  // Programeaza notificarile locale in functie de date.
  Future<void> _scheduleNotifications() async {
    final mi = meterIndex;
    if (mi != null) {
      await NotificationService.instance
          .scheduleIndexReminder(mi.windowStart, mi.windowEnd);
    }
    // Pentru fiecare factura neplatita: reamintire inainte de scadenta.
    for (final inv in invoices.where((i) => !i.paid)) {
      await NotificationService.instance
          .scheduleInvoiceDueReminder(inv.number, inv.dueDate);
    }
  }
}

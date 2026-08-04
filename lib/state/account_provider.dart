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
import '../data/notification_prefs.dart';
import '../data/repositories/aci_repository.dart';
import '../services/invoice_alerts.dart';
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

  // Reface DOAR planul de notificari, fara sa mai ceara datele de la server.
  // Folosit cand userul schimba preferintele in ecranul Configurari: reactia
  // trebuie sa fie instantanee, nu sa astepte trei cereri HTTP.
  Future<void> refreshNotificationPlan() => _scheduleNotifications();

  // Trimite un index nou, apoi reincarca indexul actualizat.
  Future<void> submitIndex(int value) async {
    await _repo.submitMeterIndex(value);
    meterIndex = await _repo.getMeterIndex();
    notifyListeners();
  }

  // Construieste planul de reamintiri locale in functie de date si il trimite
  // serviciului de notificari. Ce nu mai apare in lista (ex: o factura platita
  // intre timp) se anuleaza automat.
  //
  // Tot aici verificam daca a aparut o factura noua fata de ultima data.
  Future<void> _scheduleNotifications() async {
    final prefs = await NotificationPrefsStore.read();

    // "S-a emis o factura noua": comparam cu ce stia aplicatia.
    try {
      await InvoiceAlerts.notifyNewInvoices(invoices);
    } catch (e) {
      debugPrint('Nu am putut verifica facturile noi: $e');
    }

    final requests = <ReminderRequest>[];

    // Reamintire in prima zi a perioadei de transmitere a indexului, la 9:00.
    final mi = meterIndex;
    if (mi != null && prefs.indexWindow) {
      requests.add(
        ReminderRequest(
          key: 'index',
          title: 'A inceput perioada de index',
          body: 'Poti transmite indexul pana pe '
              '${mi.windowEnd.day}.${mi.windowEnd.month}.',
          when: DateTime(
            mi.windowStart.year,
            mi.windowStart.month,
            mi.windowStart.day,
            9,
          ),
        ),
      );
    }

    // Pentru fiecare factura neplatita: reamintire cu 3 zile inainte de
    // scadenta, la ora 9:00.
    for (final inv in prefs.invoiceDue
        ? invoices.where((i) => !i.paid)
        : const <Invoice>[]) {
      requests.add(
        ReminderRequest(
          key: 'invoice:${inv.number}',
          title: 'Factura se apropie de scadenta',
          body: 'Factura ${inv.number} ajunge la scadenta pe '
              '${inv.dueDate.day}.${inv.dueDate.month}.',
          when: DateTime(inv.dueDate.year, inv.dueDate.month, inv.dueDate.day, 9)
              .subtract(const Duration(days: 3)),
        ),
      );
    }

    try {
      await NotificationService.instance.syncReminders(requests);
    } catch (e) {
      // Notificarile sunt un plus, nu o conditie: daca ceva nu merge acolo,
      // datele contului trebuie sa se afiseze oricum.
      debugPrint('Reamintirile nu au putut fi programate: $e');
    }
  }
}

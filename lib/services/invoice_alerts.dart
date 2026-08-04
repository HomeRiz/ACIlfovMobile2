// ===========================================================================
//  invoice_alerts.dart  =  "S-A EMIS O FACTURA NOUA"
// ---------------------------------------------------------------------------
//  Portalul Apa Ilfov nu trimite nimic catre telefon din proprie initiativa
//  (nu exista push oficial). Asa ca aplicatia INTREABA ea portalul si compara
//  lista de facturi cu ce stia inainte. Ce e in plus = factura noua = notificare.
//
//  Aceeasi functie e folosita in doua locuri:
//   - din aplicatie, la fiecare reimprospatare a datelor;
//   - din task-ul de fundal (background_sync.dart), cu aplicatia inchisa.
//
//  La PRIMA rulare nu se trimite nimic: doar se retine lista curenta. Altfel
//  userul ar primi zeci de notificari pentru facturi vechi.
// ===========================================================================

import 'package:flutter/foundation.dart';

import '../data/models/invoice.dart';
import '../data/notification_prefs.dart';
import 'notification_service.dart';

class InvoiceAlerts {
  InvoiceAlerts._();

  /// Compara [invoices] cu ce stia aplicatia si anunta facturile aparute intre
  /// timp. Returneaza cate notificari a trimis.
  static Future<int> notifyNewInvoices(List<Invoice> invoices) async {
    if (invoices.isEmpty) return 0;

    final prefs = await NotificationPrefsStore.read();
    final numbers = invoices
        .map((i) => i.number.trim())
        .where((n) => n.isNotEmpty)
        .toSet();
    if (numbers.isEmpty) return 0;

    final firstRun = !await NotificationPrefsStore.hasSeenInvoicesBefore();
    final seen = await NotificationPrefsStore.readSeenInvoices();

    // Prima rulare: memoram tacut situatia de acum.
    if (firstRun) {
      await NotificationPrefsStore.writeSeenInvoices(numbers);
      return 0;
    }

    final fresh = numbers.difference(seen);
    // Actualizam memoria chiar daca userul a oprit notificarea, ca sa nu
    // primeasca mai tarziu un val de anunturi pentru facturi deja vechi.
    await NotificationPrefsStore.writeSeenInvoices(seen.union(numbers));
    if (fresh.isEmpty || !prefs.newInvoice) return 0;

    var sent = 0;
    for (final number in fresh) {
      final invoice = invoices.firstWhere(
        (i) => i.number.trim() == number,
        orElse: () => invoices.first,
      );
      try {
        await NotificationService.instance.showNewInvoice(
          number: number,
          amount: invoice.amount,
          dueDate: invoice.dueDate,
        );
        sent++;
      } catch (e) {
        debugPrint('InvoiceAlerts: nu am putut anunta factura $number: $e');
      }
    }
    return sent;
  }
}

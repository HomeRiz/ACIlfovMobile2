// ===========================================================================
//  background_sync.dart  =  VERIFICAREA FACTURILOR CU APLICATIA INCHISA
// ---------------------------------------------------------------------------
//  CE FACE
//   La fiecare cateva ore, sistemul porneste pentru cateva secunde o bucata din
//   aplicatie, FARA ecran, si aceasta:
//     1. citeste sesiunea salvata (cookie-ul din seiful criptat);
//     2. intreaba portalul ce facturi exista;
//     3. daca a aparut una noua, trimite notificarea pe telefon;
//     4. reprogrameaza reamintirile pierdute (acelasi caine de paza).
//
//  DE CE ASA
//   Apa Ilfov nu ofera "push" (nu are cum sa trimita ea ceva catre telefon).
//   Singura solutie fara server propriu e ca aplicatia sa intrebe periodic.
//
//  LIMITE, CINSTIT SPUS
//   - Android nu garanteaza ora exacta: WorkManager ruleaza task-ul "cam la"
//     intervalul cerut (minimul permis de sistem este 15 minute).
//   - Daca sesiunea din portal expira, verificarea esueaza tacut pana cand
//     redeschizi aplicatia si te autentifici din nou.
//   - Cu economisirea agresiva a bateriei (Samsung: "Aplicatii care adorm"),
//     sistemul poate sari peste rulari.
// ===========================================================================

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../core/config/app_config.dart';
import '../data/notification_prefs.dart';
import '../data/repositories/cookie_aci_repository.dart';
import 'invoice_alerts.dart';
import 'notification_service.dart';

// Numele task-ului periodic, folosit si la inregistrare si la anulare.
const String _invoiceTaskName = 'acilfov-verifica-facturi';
const String _invoiceTaskId = 'acilfov-verifica-facturi-periodic';

/// Punctul de intrare al task-ului de fundal.
///
/// `@pragma('vm:entry-point')` e OBLIGATORIU: fara el, compilarea pentru
/// release sterge functia (nu e apelata din cod Dart) si task-ul nu porneste.
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await runBackgroundCheck();
      return true;
    } catch (e) {
      debugPrint('Verificarea din fundal a esuat: $e');
      // `false` cere sistemului sa reincerce mai tarziu.
      return false;
    }
  });
}

/// Verificarea propriu-zisa. Separata de dispatcher ca sa poata fi apelata si
/// direct (din aplicatie) pentru depanare.
Future<void> runBackgroundCheck() async {
  final prefs = await NotificationPrefsStore.read();

  // Cainele de paza merge intotdeauna: reprogrameaza reamintirile pe care
  // telefonul le-a pierdut si le trimite pe cele intarziate.
  await NotificationService.instance.runWatchdog();

  if (!prefs.newInvoice) return;
  // Doar sursa "cookie" poate interoga portalul in fundal.
  if (AppConfig.dataSource != DataSource.cookie) return;

  final repo = CookieACIRepository();
  final invoices = await repo.getInvoices();
  await InvoiceAlerts.notifyNewInvoices(invoices);
}

class BackgroundSync {
  BackgroundSync._();

  // Cat de des intrebam portalul. Android nu accepta sub 15 minute; la 3 ore
  // consumul de baterie e neglijabil, iar o factura tot nu apare mai des.
  static const Duration _frequency = Duration(hours: 3);

  static bool _started = false;

  /// Porneste verificarea periodica. Apelat o data, la pornirea aplicatiei.
  static Future<void> start() async {
    if (_started) return;
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }
    try {
      await Workmanager().initialize(backgroundCallbackDispatcher);
      await _register();
      _started = true;
    } catch (e) {
      debugPrint('Nu am putut porni verificarea din fundal: $e');
    }
  }

  static Future<void> _register() async {
    await Workmanager().registerPeriodicTask(
      _invoiceTaskId,
      _invoiceTaskName,
      frequency: _frequency,
      // Fara internet nu are ce sa verifice - lasam sistemul sa astepte.
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      initialDelay: const Duration(minutes: 15),
    );
  }

  /// Opreste verificarea (la deconectare: fara sesiune nu are ce interoga).
  static Future<void> stop() async {
    try {
      await Workmanager().cancelByUniqueName(_invoiceTaskId);
    } catch (e) {
      debugPrint('Nu am putut opri verificarea din fundal: $e');
    }
    _started = false;
  }

  /// Reaplica inregistrarea dupa ce userul schimba preferintele.
  static Future<void> syncWithPrefs(NotificationPrefs prefs) async {
    if (prefs.newInvoice) {
      await start();
    } else {
      await stop();
    }
  }
}

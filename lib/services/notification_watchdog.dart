// ===========================================================================
//  notification_watchdog.dart  =  "CAINELE DE PAZA" AL NOTIFICARILOR
// ---------------------------------------------------------------------------
//  PROBLEMA
//   Sistemul de operare poate amana sau sterge alarmele aplicatiei:
//     - la repornirea telefonului;
//     - in modul de economisire a bateriei (Doze / App Standby);
//     - cand alte aplicatii tin telefonul ocupat si sistemul "strange cureaua";
//     - dupa "Force stop" din setari.
//   Efectul: reamintirea pentru index sau pentru factura nu mai ajunge la timp.
//
//  SOLUTIA
//   Aplicatia isi tine un PLAN propriu (notification_service.dart) si il
//   verifica des:
//     - la pornire;
//     - de fiecare data cand revine in prim-plan;
//     - periodic, cat timp e deschisa;
//     - dupa fiecare reincarcare a datelor contului.
//   La fiecare verificare, reamintirile disparute se reprogrameaza, iar cele
//   pe care sistemul le-a intarziat peste limita se trimit imediat.
//
//  Se porneste o singura data, din main(), cu NotificationWatchdog.instance.start().
// ===========================================================================

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'notification_service.dart';

class NotificationWatchdog with WidgetsBindingObserver {
  NotificationWatchdog._();
  static final NotificationWatchdog instance = NotificationWatchdog._();

  // Cat de des verificam cat timp aplicatia e deschisa.
  static const Duration _interval = Duration(minutes: 15);

  // Dupa o revenire in prim-plan, nu are rost sa verificam de doua ori la rand.
  static const Duration _minGapBetweenChecks = Duration(minutes: 1);

  Timer? _timer;
  bool _started = false;
  bool _running = false;
  DateTime? _lastRun;

  /// Porneste supravegherea. Apelat o singura data, la pornirea aplicatiei.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_interval, (_) => unawaited(check()));
    await check(force: true);
  }

  /// Opreste supravegherea (folosit doar in teste).
  void stop() {
    if (!_started) return;
    _started = false;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // La revenirea in prim-plan verificam imediat: e momentul in care aflam
    // daca sistemul a "pierdut" ceva cat timp aplicatia a stat inchisa.
    if (state == AppLifecycleState.resumed) unawaited(check());
  }

  /// Ruleaza o verificare. Returneaza cate reamintiri au fost reparate.
  ///
  /// Verificarile prea dese sunt ignorate, in afara de cazul [force] (folosit
  /// de butonul "Verifica acum" din Configurari).
  Future<int> check({bool force = false}) async {
    if (_running) return 0;
    final last = _lastRun;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _minGapBetweenChecks) {
      return 0;
    }
    _running = true;
    try {
      return await NotificationService.instance.runWatchdog();
    } finally {
      _lastRun = DateTime.now();
      _running = false;
    }
  }
}

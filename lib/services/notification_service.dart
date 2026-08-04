// ===========================================================================
//  notification_service.dart  =  NOTIFICARI LOCALE (fara server)
// ---------------------------------------------------------------------------
//  Trimite reamintiri pe telefon, programate local:
//    - cand incepe perioada de transmitere a indexului;
//    - cu 3 zile inainte de scadenta unei facturi.
//
//  DE CE E NEVOIE DE UN "PLAN" SALVAT PE TELEFON
//   Sistemul de operare (mai ales Android) poate SA AMANE sau SA STEARGA
//   alarmele programate: la repornirea telefonului, la "force stop", in modul
//   de economisire a bateriei, sau cand alte aplicatii tin telefonul ocupat.
//   De aceea aplicatia isi tine un PLAN propriu (ce reamintiri ar trebui sa
//   existe si cand). Cainele de paza (notification_watchdog.dart) compara
//   periodic planul cu ce e programat REAL in sistem si repara diferentele:
//     - reprogrameaza reamintirile disparute;
//     - trimite imediat reamintirile pe care sistemul le-a "intarziat";
//     - sterge alarmele ramase de la date vechi.
//
//  IMPORTANT (limitari):
//   Notificarile LOCALE se programeaza pentru date pe care aplicatia deja le
//   stie. Pentru instiintari INSTANT despre facturi noi (chiar cu aplicatia
//   inchisa), e nevoie de API + webhook din partea ACIlfov, sau de Home
//   Assistant. Vezi docs/ARHITECTURA.md si docs/PROPUNERE-TEHNICA-ACILFOV.md.
// ===========================================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/system_settings.dart';
import '../data/secure_store.dart';

/// O reamintire ceruta de aplicatie (inainte de a fi programata in sistem).
///
/// [key] este un identificator STABIL (ex: `invoice:F12345`). Pe baza lui se
/// calculeaza mereu acelasi id de notificare, ca reprogramarea sa nu duca la
/// notificari duplicate.
class ReminderRequest {
  final String key;
  final String title;
  final String body;
  final DateTime when;

  const ReminderRequest({
    required this.key,
    required this.title,
    required this.body,
    required this.when,
  });
}

/// O reamintire din planul salvat pe telefon.
class PlannedReminder {
  final String key;
  final int id;
  final String title;
  final String body;
  final DateTime when;

  /// Adevarat dupa ce sistemul a acceptat programarea alarmei.
  final bool scheduled;

  /// Momentul in care reamintirea a ajuns (sau a fost recuperata) la user.
  final DateTime? deliveredAt;

  const PlannedReminder({
    required this.key,
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    this.scheduled = false,
    this.deliveredAt,
  });

  bool get done => deliveredAt != null;

  PlannedReminder copyWith({
    bool? scheduled,
    DateTime? deliveredAt,
    String? title,
    String? body,
    DateTime? when,
  }) {
    return PlannedReminder(
      key: key,
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      when: when ?? this.when,
      scheduled: scheduled ?? this.scheduled,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'id': id,
        'title': title,
        'body': body,
        'when': when.toIso8601String(),
        'scheduled': scheduled,
        'deliveredAt': deliveredAt?.toIso8601String(),
      };

  static PlannedReminder? fromJson(Object? value) {
    if (value is! Map) return null;
    final key = value['key'];
    final id = value['id'];
    final when = DateTime.tryParse('${value['when']}');
    if (key is! String || id is! int || when == null) return null;
    final delivered = value['deliveredAt'];
    return PlannedReminder(
      key: key,
      id: id,
      title: '${value['title'] ?? ''}',
      body: '${value['body'] ?? ''}',
      when: when,
      scheduled: value['scheduled'] == true,
      deliveredAt: delivered is String ? DateTime.tryParse(delivered) : null,
    );
  }
}

/// Starea sistemului de notificari - afisata in ecranul "Configurari".
class NotificationDiagnostics {
  /// Serviciul a pornit corect (pluginul e initializat).
  final bool ready;

  /// Userul a acceptat notificarile.
  final bool permissionGranted;

  /// Android: aplicatia poate folosi alarme EXACTE (livrare la fix).
  /// `null` = intrebarea nu se aplica (iOS) sau nu s-a putut afla.
  final bool? exactAlarmsAllowed;

  /// Cate reamintiri sunt in plan si inca nu au fost trimise.
  final int plannedCount;

  /// Cate sunt programate REAL in sistemul de operare.
  final int scheduledInSystemCount;

  /// Prima reamintire care urmeaza.
  final DateTime? nextReminder;

  /// Cand a rulat ultima oara cainele de paza.
  final DateTime? lastCheck;

  /// Cate reamintiri a reparat cainele de paza la ultima rulare.
  final int lastRepairCount;

  const NotificationDiagnostics({
    this.ready = false,
    this.permissionGranted = false,
    this.exactAlarmsAllowed,
    this.plannedCount = 0,
    this.scheduledInSystemCount = 0,
    this.nextReminder,
    this.lastCheck,
    this.lastRepairCount = 0,
  });

  /// Totul e in regula: serviciul merge si planul e acoperit de sistem.
  bool get healthy =>
      ready && permissionGranted && scheduledInSystemCount >= plannedCount;
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // Intervalul de id-uri rezervat reamintirilor. Orice alarma din acest
  // interval care NU mai e in plan e considerata veche si se sterge.
  static const int _idBase = 10000;
  static const int _idRange = 80000;
  static const int _testId = 999;

  // Notificarile "factura noua" au id-uri in afara intervalului rezervat
  // reamintirilor programate, ca sa nu fie sterse de curatenia cainelui de paza.
  static const int _invoiceIdBase = 100000;

  // Cat de tarziu poate fi livrata o alarma inainte sa o consideram "pierduta"
  // si sa o trimitem noi (cazul telefonului tinut ocupat de alte aplicatii).
  static const Duration _lateTolerance = Duration(minutes: 10);

  // Peste acest interval reamintirea nu mai are rost: o marcam ca trecuta.
  static const Duration _catchUpWindow = Duration(days: 3);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  Future<void>? _initializing;

  // Pornim de la "sunt permise". Nu avem voie sa speriem userul cu un
  // avertisment doar pentru ca inca nu am apucat sa intrebam sistemul.
  bool _permissionGranted = true;
  bool? _exactAlarmsAllowed;
  DateTime? _lastCheck;
  int _lastRepairCount = 0;

  bool get isReady => _ready;

  /// Doar pentru teste: aduce serviciul la starea de dinainte de pornire.
  @visibleForTesting
  void resetForTests() {
    _ready = false;
    _initializing = null;
    _permissionGranted = true;
    _exactAlarmsAllowed = null;
    _lastCheck = null;
    _lastRepairCount = 0;
  }

  // ------------------------------------------------------------------ START
  // Porneste serviciul si cere permisiunile. Se apeleaza o data, in main().
  //
  // Poate fi apelat din mai multe locuri deodata (pornire + ecranul Configurari):
  // pornirea reala se face O SINGURA data, restul asteapta acelasi Future - ca
  // sa nu ceara permisiunea de doua ori.
  Future<void> init() {
    if (_ready) return Future.value();
    return _initializing ??= _init().whenComplete(() => _initializing = null);
  }

  Future<void> _init() async {
    if (_ready) return;

    // Fus orar pentru programari la ora corecta. Romania = Europe/Bucharest.
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Bucharest'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    // Canalul de notificari (Android 8+). Il cream explicit, ca sa existe
    // chiar daca prima notificare vine mai tarziu.
    await android?.createNotificationChannel(_channel);

    // Cererea de permisiune are voie sa esueze (ex: in izolatul de fundal nu
    // exista ecran, deci nu se poate cere nimic). Nu are voie insa sa opreasca
    // initializarea - altfel serviciul ar ramane "nepornit" degeaba.
    try {
      await android?.requestNotificationsPermission();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'requesting notification permissions at start');
    }

    // Starea reala a permisiunii se ia DOAR de la sistem, nu din rezultatul
    // cererii de mai sus: pe Android sub 13 acea cerere nu inseamna nimic.
    _permissionGranted = await _readNotificationsEnabled() ?? true;

    // Android 12+: alarmele exacte au nevoie de o permisiune separata.
    _exactAlarmsAllowed = await _readExactAlarmsAllowed();

    _ready = true;
  }

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'acilfov_general',
    'Notificari Apa Ilfov',
    description: 'Reamintiri pentru index si facturi',
    importance: Importance.high,
  );

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'acilfov_general',
          'Notificari Apa Ilfov',
          channelDescription: 'Reamintiri pentru index si facturi',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.active,
        ),
      );

  // ------------------------------------------------------------- PLANIFICARE
  /// Inlocuieste planul de reamintiri cu cel cerut de datele contului si il
  /// aplica imediat in sistem.
  ///
  /// Ce dispare din [requests] (ex: o factura platita intre timp) se anuleaza
  /// automat la urmatoarea verificare.
  Future<void> syncReminders(List<ReminderRequest> requests) async {
    await init();
    final previous = await _loadPlan();
    final byKey = {for (final entry in previous) entry.key: entry};
    final taken = <int>{};
    final next = <PlannedReminder>[];
    final now = DateTime.now();

    for (final request in requests) {
      final old = byKey[request.key];
      final id = old?.id ?? _idFor(request.key, taken);
      taken.add(id);
      // Daca ora s-a schimbat fata de plan, reamintirea trebuie reprogramata.
      final movedInTime =
          old != null && !old.when.isAtSameMomentAs(request.when);
      final known = old != null && !movedInTime;

      // O reamintire NOUA a carei ora a trecut deja (ex: prima pornire a
      // aplicatiei, cu facturi mai vechi) nu se mai trimite: nu am promis-o
      // niciodata, deci ar fi doar zgomot. O marcam direct ca incheiata.
      final missedBeforeWeKnew = !known && request.when.isBefore(now);

      next.add(
        PlannedReminder(
          key: request.key,
          id: id,
          title: request.title,
          body: request.body,
          when: request.when,
          scheduled: known && (old.scheduled),
          deliveredAt: missedBeforeWeKnew
              ? now
              : (known ? old.deliveredAt : null),
        ),
      );
    }

    await _savePlan(next);
    await runWatchdog();
  }

  // ------------------------------------------------------------ CAINE DE PAZA
  /// Compara planul cu ce e programat REAL in sistem si repara diferentele.
  ///
  /// Se apeleaza la pornirea aplicatiei, la fiecare revenire in prim-plan si
  /// periodic cat timp aplicatia e deschisa. Returneaza cate reamintiri a
  /// reparat (reprogramate + recuperate).
  Future<int> runWatchdog() async {
    var repaired = 0;
    try {
      await init();
      final plan = await _loadPlan();

      // Permisiunile se pot schimba oricand din setarile telefonului, deci le
      // recitim la fiecare verificare (nu doar la pornire).
      _exactAlarmsAllowed = await _readExactAlarmsAllowed();
      _permissionGranted = await _readNotificationsEnabled() ?? _permissionGranted;

      final pending = await _plugin.pendingNotificationRequests();
      final pendingIds = {for (final p in pending) p.id};
      final planIds = {for (final entry in plan) entry.id};
      final now = DateTime.now();
      final updated = <PlannedReminder>[];

      for (final entry in plan) {
        // 1) Deja livrata: o pastram putin, apoi o uitam.
        if (entry.done) {
          if (now.difference(entry.deliveredAt!) < const Duration(days: 30)) {
            updated.add(entry);
          }
          continue;
        }

        final late = now.difference(entry.when);

        // 2) Momentul a trecut.
        if (!late.isNegative) {
          final stillQueued = pendingIds.contains(entry.id);
          final tooLate = late > _catchUpWindow;

          if (tooLate) {
            // Nu mai are rost sa deranjam userul cu o reamintire veche.
            if (stillQueued) await _cancel(entry.id);
            updated.add(entry.copyWith(deliveredAt: now));
            continue;
          }

          // Alarma e inca in coada desi ora a trecut => sistemul a amanat-o
          // (telefon ocupat / economisire baterie). O trimitem noi, acum.
          if (stillQueued && late > _lateTolerance) {
            await _cancel(entry.id);
            await _showNow(entry);
            updated.add(entry.copyWith(deliveredAt: now));
            repaired++;
            continue;
          }

          // Nu a apucat sa fie programata niciodata (ex: aplicatia a fost
          // inchisa de sistem inainte sa o programeze) => o recuperam acum.
          if (!entry.scheduled && !stillQueued) {
            await _showNow(entry);
            updated.add(entry.copyWith(deliveredAt: now));
            repaired++;
            continue;
          }

          if (stillQueued) {
            // Intarziere mica, sub toleranta: lasam sistemul sa o livreze.
            updated.add(entry);
          } else {
            // A fost programata si nu mai e in coada => sistemul a livrat-o.
            updated.add(entry.copyWith(deliveredAt: now));
          }
          continue;
        }

        // 3) Reamintire viitoare care lipseste din sistem (repornire telefon,
        //    "force stop", stergerea alarmelor) => o reprogramam.
        if (!pendingIds.contains(entry.id)) {
          final ok = await _schedule(entry);
          // Prima programare e normala; "reparatie" e doar cand o alarma deja
          // programata a disparut din sistem.
          if (ok && entry.scheduled) repaired++;
          updated.add(entry.copyWith(scheduled: ok));
        } else {
          updated.add(entry.copyWith(scheduled: true));
        }
      }

      // 4) Alarme ramase din planuri vechi: le stergem, ca sa nu apara
      //    notificari pentru facturi deja platite.
      for (final id in pendingIds) {
        if (id < _idBase || id >= _idBase + _idRange) continue;
        if (planIds.contains(id)) continue;
        await _cancel(id);
      }

      await _savePlan(updated);
      _lastRepairCount = repaired;
    } catch (error, stackTrace) {
      // Cainele de paza nu are voie sa darame aplicatia.
      _report(error, stackTrace, 'running the notification watchdog');
    } finally {
      _lastCheck = DateTime.now();
    }
    return repaired;
  }

  /// Starea curenta a notificarilor, pentru ecranul "Configurari".
  Future<NotificationDiagnostics> diagnostics() async {
    try {
      await init();
      _permissionGranted =
          await _readNotificationsEnabled() ?? _permissionGranted;
      final plan = await _loadPlan();
      final upcoming = plan.where((e) => !e.done).toList()
        ..sort((a, b) => a.when.compareTo(b.when));
      final pending = await _plugin.pendingNotificationRequests();
      final pendingIds = {for (final p in pending) p.id};
      return NotificationDiagnostics(
        ready: _ready,
        permissionGranted: _permissionGranted,
        exactAlarmsAllowed: _exactAlarmsAllowed,
        plannedCount: upcoming.length,
        scheduledInSystemCount:
            upcoming.where((e) => pendingIds.contains(e.id)).length,
        nextReminder: upcoming.isEmpty ? null : upcoming.first.when,
        lastCheck: _lastCheck,
        lastRepairCount: _lastRepairCount,
      );
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'reading notification diagnostics');
      return NotificationDiagnostics(
        ready: _ready,
        permissionGranted: _permissionGranted,
        exactAlarmsAllowed: _exactAlarmsAllowed,
        lastCheck: _lastCheck,
      );
    }
  }

  /// Cere din nou permisiunile (notificari + alarme exacte pe Android).
  /// Deschide ecranul de sistem cand permisiunea lipseste.
  Future<NotificationDiagnostics> requestPermissions() async {
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
      if (await _readExactAlarmsAllowed() == false) {
        await android?.requestExactAlarmsPermission();
      }
      _permissionGranted = await _readNotificationsEnabled() ?? _permissionGranted;

      // Daca tot sunt oprite, inseamna ca sistemul nu ofera niciun dialog
      // (Android sub 13): singura cale e sa deschidem noi ecranul de setari.
      if (!_permissionGranted) {
        await SystemSettings.openNotificationSettings();
      }
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'requesting notification permissions');
    }
    await runWatchdog();
    return diagnostics();
  }

  /// Anunta imediat ca s-a emis o factura noua.
  ///
  /// Se apeleaza si din aplicatie (la reimprospatarea datelor), si din task-ul
  /// de fundal, ca sa ajunga chiar si cu aplicatia inchisa.
  Future<void> showNewInvoice({
    required String number,
    double? amount,
    DateTime? dueDate,
  }) async {
    try {
      await init();
      final details = <String>[
        if (amount != null) '${amount.toStringAsFixed(2)} lei',
        if (dueDate != null)
          'scadenta ${dueDate.day}.${dueDate.month}.${dueDate.year}',
      ];
      await _plugin.show(
        _invoiceIdBase + (number.hashCode.abs() % 1000),
        'Factura noua de la Apa Ilfov',
        details.isEmpty
            ? 'Factura $number a fost emisa.'
            : 'Factura $number: ${details.join(', ')}.',
        _details,
        payload: 'invoice:$number',
      );
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'showing new invoice notification');
    }
  }

  // Notificare imediata - utila pentru a testa ca notificarile functioneaza.
  Future<void> showTest() async {
    try {
      await init();
      await _plugin.show(
        _testId,
        'Test Apa Ilfov',
        'Notificarile functioneaza!',
        _details,
      );
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'showing the test notification');
    }
  }

  // ---------------------------------------------------------------- INTERNE
  Future<bool> _schedule(PlannedReminder entry) async {
    try {
      final when = tz.TZDateTime.from(entry.when, tz.local);
      await _plugin.zonedSchedule(
        entry.id,
        entry.title,
        entry.body,
        when,
        _details,
        androidScheduleMode: _exactAlarmsAllowed == false
            ? AndroidScheduleMode.inexactAllowWhileIdle
            : AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: entry.key,
      );
      return true;
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'scheduling reminder ${entry.key}');
      // Ultima incercare: modul inexact e acceptat fara permisiuni speciale.
      try {
        await _plugin.zonedSchedule(
          entry.id,
          entry.title,
          entry.body,
          tz.TZDateTime.from(entry.when, tz.local),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: entry.key,
        );
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> _showNow(PlannedReminder entry) async {
    try {
      await _plugin.show(entry.id, entry.title, entry.body, _details,
          payload: entry.key);
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'showing recovered reminder ${entry.key}');
    }
  }

  Future<void> _cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'cancelling notification $id');
    }
  }

  // Adevarul despre notificari: userul le poate opri din setarile telefonului
  // oricand, iar pe Android sub 13 nu exista dialog de permisiune - doar asta
  // ne spune daca chiar sunt permise.
  Future<bool?> _readNotificationsEnabled() async {
    try {
      return await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _readExactAlarmsAllowed() async {
    try {
      return await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();
    } catch (_) {
      return null;
    }
  }

  // Acelasi id pentru aceeasi reamintire, la fiecare pornire a aplicatiei.
  int _idFor(String key, Set<int> taken) {
    var id = _idBase + (key.hashCode.abs() % _idRange);
    while (taken.contains(id)) {
      id = _idBase + ((id - _idBase + 1) % _idRange);
    }
    return id;
  }

  Future<List<PlannedReminder>> _loadPlan() async {
    try {
      final raw = await SecureStore.readNotificationPlan();
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map(PlannedReminder.fromJson)
          .whereType<PlannedReminder>()
          .toList();
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'reading the notification plan');
      return [];
    }
  }

  Future<void> _savePlan(List<PlannedReminder> plan) async {
    try {
      await SecureStore.writeNotificationPlan(
        jsonEncode([for (final entry in plan) entry.toJson()]),
      );
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'saving the notification plan');
    }
  }

  void _report(Object error, StackTrace stackTrace, String what) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'notification_service',
        context: ErrorDescription(what),
        silent: true,
      ),
    );
  }
}

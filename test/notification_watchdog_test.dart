// ===========================================================================
//  Teste pentru "cainele de paza" al notificarilor.
// ---------------------------------------------------------------------------
//  Simulam sistemul de operare (pluginul de notificari + seiful local) prin
//  canale false, ca sa putem verifica exact ce face serviciul cand:
//    - reamintirile lipsesc din sistem (repornire telefon / force stop);
//    - o alarma a ramas in coada desi ora ei a trecut (telefon throttled);
//    - o factura a fost platita si reamintirea ei trebuie stearsa.
// ===========================================================================

import 'dart:convert';

import 'package:acilfov_mobile/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Sistemul de operare, simulat.
class _FakeOs {
  // Alarmele "programate in sistem": id -> ora.
  final Map<int, String> scheduled = {};

  // Notificarile afisate imediat (recuperari).
  final List<int> shown = [];
  final List<int> cancelled = [];

  bool exactAlarmsAllowed = true;

  // Continutul seifului local (planul de reamintiri).
  String? storedPlan;

  Future<Object?> handleNotifications(MethodCall call) async {
    switch (call.method) {
      case 'initialize':
      case 'createNotificationChannel':
        return true;
      case 'requestNotificationsPermission':
        return true;
      case 'canScheduleExactNotifications':
        return exactAlarmsAllowed;
      case 'requestExactAlarmsPermission':
        return true;
      case 'pendingNotificationRequests':
        return [
          for (final id in scheduled.keys)
            {'id': id, 'title': '', 'body': '', 'payload': ''},
        ];
      case 'zonedSchedule':
        final args = (call.arguments as Map).cast<String, dynamic>();
        scheduled[args['id'] as int] = '${args['scheduledDateTime']}';
        return null;
      case 'show':
        shown.add((call.arguments as Map)['id'] as int);
        return null;
      case 'cancel':
        final args = call.arguments;
        final id = args is Map ? args['id'] as int : args as int;
        cancelled.add(id);
        scheduled.remove(id);
        return null;
    }
    return null;
  }

  Future<Object?> handleStorage(MethodCall call) async {
    switch (call.method) {
      case 'write':
        storedPlan = (call.arguments as Map)['value'] as String?;
        return null;
      case 'read':
        return storedPlan;
      case 'delete':
        storedPlan = null;
        return null;
    }
    return null;
  }

  // Planul salvat, ca lista de map-uri - pentru verificari.
  List<Map<String, dynamic>> get plan {
    final raw = storedPlan;
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  const storageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  late _FakeOs os;
  late NotificationService service;

  setUp(() {
    os = _FakeOs();
    service = NotificationService.instance..resetForTests();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        notificationsChannel, os.handleNotifications);
    messenger.setMockMethodCallHandler(storageChannel, os.handleStorage);
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(notificationsChannel, null);
    messenger.setMockMethodCallHandler(storageChannel, null);
  });

  ReminderRequest futureReminder(String key, Duration inHowLong) {
    return ReminderRequest(
      key: key,
      title: 'Titlu $key',
      body: 'Text $key',
      when: DateTime.now().add(inHowLong),
    );
  }

  test('programeaza reamintirile viitoare si le tine in plan', () async {
    await service.syncReminders([
      futureReminder('index', const Duration(days: 2)),
      futureReminder('invoice:F1', const Duration(days: 5)),
    ]);

    expect(os.scheduled.length, 2);
    expect(os.plan.length, 2);
    expect(os.plan.every((e) => e['scheduled'] == true), isTrue);
  });

  test('reprogrameaza reamintirile disparute din sistem', () async {
    await service.syncReminders([
      futureReminder('index', const Duration(days: 2)),
      futureReminder('invoice:F1', const Duration(days: 5)),
    ]);

    // Sistemul le pierde (repornire telefon / "force stop").
    os.scheduled.clear();

    final repaired = await service.runWatchdog();

    expect(repaired, 2);
    expect(os.scheduled.length, 2);
  });

  test('trimite imediat reamintirea pe care sistemul a intarziat-o', () async {
    // Reamintire programata acum 40 de minute, dar inca in coada: telefonul a
    // fost tinut ocupat si alarma nu a mai plecat la timp.
    const id = 12345;
    os.storedPlan = jsonEncode([
      {
        'key': 'invoice:F9',
        'id': id,
        'title': 'Factura se apropie de scadenta',
        'body': 'Factura F9',
        'when': DateTime.now()
            .subtract(const Duration(minutes: 40))
            .toIso8601String(),
        'scheduled': true,
        'deliveredAt': null,
      }
    ]);
    os.scheduled[id] = 'oricand';

    final repaired = await service.runWatchdog();

    expect(repaired, 1);
    expect(os.shown, contains(id), reason: 'reamintirea trebuie recuperata');
    expect(os.cancelled, contains(id), reason: 'alarma veche se anuleaza');
    expect(os.plan.single['deliveredAt'], isNotNull);
  });

  test('nu deranjeaza cu reamintiri mai vechi de trei zile', () async {
    const id = 22222;
    os.storedPlan = jsonEncode([
      {
        'key': 'invoice:F8',
        'id': id,
        'title': 'Factura',
        'body': 'Text',
        'when':
            DateTime.now().subtract(const Duration(days: 9)).toIso8601String(),
        'scheduled': true,
        'deliveredAt': null,
      }
    ]);
    os.scheduled[id] = 'oricand';

    await service.runWatchdog();

    expect(os.shown, isEmpty);
    expect(os.plan.single['deliveredAt'], isNotNull);
  });

  test('sterge alarma unei facturi care nu mai e in plan', () async {
    await service.syncReminders([
      futureReminder('invoice:F1', const Duration(days: 4)),
      futureReminder('invoice:F2', const Duration(days: 6)),
    ]);
    expect(os.scheduled.length, 2);

    // F1 a fost platita: ramane doar F2.
    await service.syncReminders([
      futureReminder('invoice:F2', const Duration(days: 6)),
    ]);

    expect(os.scheduled.length, 1);
    expect(os.plan.single['key'], 'invoice:F2');
  });

  test('o reamintire deja trecuta la prima sincronizare nu se mai trimite',
      () async {
    await service.syncReminders([
      ReminderRequest(
        key: 'invoice:vechi',
        title: 'Factura',
        body: 'Text',
        when: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ]);

    expect(os.shown, isEmpty);
    expect(os.scheduled, isEmpty);
    expect(os.plan.single['deliveredAt'], isNotNull);
  });

  test('foloseste alarme inexacte cand cele exacte sunt interzise', () async {
    os.exactAlarmsAllowed = false;
    await service.syncReminders([
      futureReminder('index', const Duration(days: 1)),
    ]);

    // Programarea trebuie sa reuseasca oricum.
    expect(os.scheduled.length, 1);
    final status = await service.diagnostics();
    expect(status.exactAlarmsAllowed, isFalse);
  });
}

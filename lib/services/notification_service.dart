// ===========================================================================
//  notification_service.dart  =  NOTIFICARI LOCALE (fara server)
// ---------------------------------------------------------------------------
//  Trimite reamintiri pe telefon, programate local:
//    - cand incepe perioada de transmitere a indexului;
//    - cu 3 zile inainte de scadenta unei facturi.
//
//  IMPORTANT (limitari):
//   Notificarile LOCALE se programeaza pentru date pe care aplicatia deja le
//   stie. Pentru instiintari INSTANT despre facturi noi (chiar cu aplicatia
//   inchisa), e nevoie de API + webhook din partea ACIlfov, sau de Home
//   Assistant. Vezi docs/ARHITECTURA.md si docs/PROPUNERE-TEHNICA-ACILFOV.md.
// ===========================================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // Porneste serviciul si cere permisiunile. Se apeleaza o data, in main().
  Future<void> init() async {
    if (_ready) return;

    // Fus orar pentru programari la ora corecta. Romania = Europe/Bucharest.
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Bucharest'));

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);

    // Cerem permisiunea de notificari (Android 13+ si iOS).
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _ready = true;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'acilfov_general',
          'Notificari Apa Ilfov',
          channelDescription: 'Reamintiri pentru index si facturi',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  // Reamintire in prima zi a perioadei de transmitere a indexului, la ora 9:00.
  Future<void> scheduleIndexReminder(
      DateTime windowStart, DateTime windowEnd) async {
    final when = tz.TZDateTime(
        tz.local, windowStart.year, windowStart.month, windowStart.day, 9);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return; // data a trecut
    await _plugin.zonedSchedule(
      1001,
      'A inceput perioada de index',
      'Poti transmite indexul pana pe ${windowEnd.day}.${windowEnd.month}.',
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Reamintire cu 3 zile inainte de scadenta unei facturi, la ora 9:00.
  Future<void> scheduleInvoiceDueReminder(
      String invoiceNumber, DateTime dueDate) async {
    final when =
        tz.TZDateTime(tz.local, dueDate.year, dueDate.month, dueDate.day, 9)
            .subtract(const Duration(days: 3));
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      2000 + (invoiceNumber.hashCode.abs() % 1000), // id unic per factura
      'Factura se apropie de scadenta',
      'Factura $invoiceNumber ajunge la scadenta pe '
          '${dueDate.day}.${dueDate.month}.',
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Notificare imediata - utila pentru a testa ca notificarile functioneaza.
  Future<void> showTest() async {
    await _plugin.show(
        9999, 'Test Apa Ilfov', 'Notificarile functioneaza!', _details);
  }
}

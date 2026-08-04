// ===========================================================================
//  notification_prefs.dart  =  CE NOTIFICARI VREA USERUL PE TELEFON
// ---------------------------------------------------------------------------
//  Astea NU sunt setari de pe serverul Apa Ilfov, ci alegerile userului despre
//  ce sa-i arate aplicatia pe telefon. Se tin local, in seiful criptat, ca sa
//  fie citite si din task-ul de fundal (care ruleaza fara ecran).
//
//  Tot aici tinem si lista facturilor deja vazute: pe baza ei stim cand a
//  aparut una NOUA si dam notificarea "s-a emis o factura".
// ===========================================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationPrefs {
  final bool newInvoice; // "s-a emis o factura noua"
  final bool invoiceDue; // "factura se apropie de scadenta"
  final bool indexWindow; // "a inceput perioada de index"

  const NotificationPrefs({
    this.newInvoice = true,
    this.invoiceDue = true,
    this.indexWindow = true,
  });

  NotificationPrefs copyWith({
    bool? newInvoice,
    bool? invoiceDue,
    bool? indexWindow,
  }) {
    return NotificationPrefs(
      newInvoice: newInvoice ?? this.newInvoice,
      invoiceDue: invoiceDue ?? this.invoiceDue,
      indexWindow: indexWindow ?? this.indexWindow,
    );
  }

  /// Adevarat daca userul vrea macar o notificare pe telefon.
  bool get anyEnabled => newInvoice || invoiceDue || indexWindow;

  Map<String, dynamic> toJson() => {
        'newInvoice': newInvoice,
        'invoiceDue': invoiceDue,
        'indexWindow': indexWindow,
      };

  static NotificationPrefs fromJson(Object? value) {
    if (value is! Map) return const NotificationPrefs();
    return NotificationPrefs(
      newInvoice: value['newInvoice'] != false,
      invoiceDue: value['invoiceDue'] != false,
      indexWindow: value['indexWindow'] != false,
    );
  }
}

class NotificationPrefsStore {
  NotificationPrefsStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _prefsKey = 'notification_prefs';
  static const String _seenInvoicesKey = 'seen_invoice_numbers';

  // Pastram in memorie ce am citit, ca ecranul de Configurari sa nu astepte
  // seiful la fiecare redesenare.
  static NotificationPrefs? _cached;

  static NotificationPrefs? get cached => _cached;

  static Future<NotificationPrefs> read() async {
    try {
      final raw = await _storage.read(key: _prefsKey);
      if (raw == null || raw.isEmpty) return _cached = const NotificationPrefs();
      return _cached = NotificationPrefs.fromJson(jsonDecode(raw));
    } catch (e) {
      debugPrint('NotificationPrefs.read: $e');
      return _cached ?? const NotificationPrefs();
    }
  }

  static Future<void> write(NotificationPrefs prefs) async {
    _cached = prefs;
    try {
      await _storage.write(key: _prefsKey, value: jsonEncode(prefs.toJson()));
    } catch (e) {
      debugPrint('NotificationPrefs.write: $e');
    }
  }

  // ------------------------------------------------------ facturi deja vazute
  static Future<Set<String>> readSeenInvoices() async {
    try {
      final raw = await _storage.read(key: _seenInvoicesKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return decoded.map((e) => '$e').toSet();
    } catch (e) {
      debugPrint('NotificationPrefs.readSeenInvoices: $e');
      return {};
    }
  }

  static Future<void> writeSeenInvoices(Set<String> numbers) async {
    try {
      // Pastram doar ultimele 200, ca sa nu creasca la nesfarsit.
      final trimmed =
          numbers.length <= 200 ? numbers : numbers.toList().sublist(numbers.length - 200).toSet();
      await _storage.write(
        key: _seenInvoicesKey,
        value: jsonEncode(trimmed.toList()),
      );
    } catch (e) {
      debugPrint('NotificationPrefs.writeSeenInvoices: $e');
    }
  }

  /// Adevarat daca aplicatia a mai vazut vreodata lista de facturi. La prima
  /// rulare NU dam notificari pentru facturile vechi - ar fi doar zgomot.
  static Future<bool> hasSeenInvoicesBefore() async {
    try {
      final raw = await _storage.read(key: _seenInvoicesKey);
      return raw != null && raw.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

// ===========================================================================
//  system_settings.dart  =  DESCHIDEREA SETARILOR TELEFONULUI
// ---------------------------------------------------------------------------
//  Pe Android sub versiunea 13 NU exista niciun dialog prin care aplicatia sa
//  ceara permisiunea de notificari: ori sunt pornite din setari, ori nu.
//  Singurul lucru corect pe care il poate face aplicatia e sa duca userul
//  direct la ecranul de unde le reporneste.
//
//  Canalul nativ e definit in:
//    - android/app/src/main/kotlin/ro/acilfov/mobile/MainActivity.kt
//    - ios/Runner/AppDelegate.swift
// ===========================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SystemSettings {
  SystemSettings._();

  static const MethodChannel _channel = MethodChannel('acilfov/system');

  /// Deschide ecranul de notificari al aplicatiei. Returneaza `false` daca
  /// telefonul nu a putut deschide acel ecran.
  static Future<bool> openNotificationSettings() =>
      _invoke('openNotificationSettings');

  /// Deschide ecranul de optimizare a bateriei (util pe telefoanele care
  /// adorm aplicatiile si intarzie reamintirile).
  static Future<bool> openBatterySettings() => _invoke('openBatterySettings');

  static Future<bool> _invoke(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (e) {
      debugPrint('SystemSettings.$method: $e');
      return false;
    }
  }
}

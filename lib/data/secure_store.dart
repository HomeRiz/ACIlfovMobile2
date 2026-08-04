// ===========================================================================
//  secure_store.dart  =  SEIFUL CRIPTAT PENTRU TOKEN (viitor)
// ---------------------------------------------------------------------------
//  Aici vom pastra tokenul de API primit dupa login (fluxul OAuth), cand
//  ACIlfov va publica API-ul. Foloseste EncryptedSharedPreferences pe Android
//  si Keychain pe iOS - nu text clar.
// ===========================================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  SecureStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _tokenKey = 'api_token';

  // Planul de reamintiri locale (ce notificari ar trebui sa existe si cand).
  // Il tinem tot aici, ca sa fie un singur loc care stie de stocarea locala.
  static const String _notificationPlanKey = 'notification_plan';

  static Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> readToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<void> writeNotificationPlan(String json) =>
      _storage.write(key: _notificationPlanKey, value: json);

  static Future<String?> readNotificationPlan() =>
      _storage.read(key: _notificationPlanKey);
}

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
  );

  static const String _tokenKey = 'api_token';

  static Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> readToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);
}

// ===========================================================================
//  cookie_store.dart  =  PASTRAREA SESIUNII + ACCES LA COOKIE
// ---------------------------------------------------------------------------
//  Rol dublu:
//   1. Salveaza/restaureaza cookie-ul de sesiune (ca sa ramai logat) - la fel
//      ca in v1.
//   2. Ofera cookie-ul curent (currentHeader) sursei "cookie", ca sa poata
//      cere date reale din portal in numele tau, imediat dupa login.
//
//  De ce cod nativ: cookie-ul de sesiune este "HttpOnly" - JavaScript din
//  pagina NU il poate citi. Doar magazinul nativ de cookie-uri il vede. De
//  aceea folosim un mic "canal" (MethodChannel "acilfov/cookies") catre codul
//  Kotlin/Swift din partea nativa (acelasi din v1 - se copiaza MainActivity.kt
//  si AppDelegate.swift).
// ===========================================================================

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CookieStore {
  static const MethodChannel _channel = MethodChannel('acilfov/cookies');

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _key = 'session_cookies';

  static bool get _supported => Platform.isAndroid || Platform.isIOS;

  // Citeste cookie-urile native pentru un URL (inclusiv HttpOnly). Le foloseste
  // atat save() (pentru pastrarea sesiunii), cat si sursa "cookie" (currentHeader).
  static Future<String?> _readNative(String url) async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod('getCookies', {'url': url});
    } catch (e) {
      if (kDebugMode) debugPrint('CookieStore._readNative eroare: $e');
      return null;
    }
  }

  // Intoarce sirul de cookie-uri gata de pus in antetul "Cookie:" al unei
  // cereri HTTP catre portal. Folosit de sursa "cookie".
  static Future<String?> currentHeader(String url) => _readNative(url);

  // Salveaza cookie-ul de sesiune in seif (doar daca esti logat).
  static Future<void> save(String url) async {
    final cookies = await _readNative(url);
    if (cookies == null || cookies.isEmpty) return;
    final loggedIn = cookies.contains('sl-session') || cookies.contains('SELF_UTI');
    if (!loggedIn) return;
    await _storage.write(key: _key, value: cookies);
    if (kDebugMode) debugPrint('CookieStore: am salvat sesiunea.');
  }

  // Pune inapoi sesiunea salvata in magazinul nativ. Intoarce true daca a restaurat.
  static Future<bool> restore(String url) async {
    if (!_supported) return false;
    try {
      final cookies = await _storage.read(key: _key);
      if (cookies == null || cookies.isEmpty) return false;
      await _channel.invokeMethod('setCookies', {'url': url, 'cookies': cookies});
      if (kDebugMode) debugPrint('CookieStore: am restaurat sesiunea.');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('CookieStore.restore eroare: $e');
      return false;
    }
  }

  // Sterge sesiunea (folosit la logout).
  static Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
      if (_supported) await _channel.invokeMethod('clearCookies');
    } catch (e) {
      if (kDebugMode) debugPrint('CookieStore.clear eroare: $e');
    }
  }
}

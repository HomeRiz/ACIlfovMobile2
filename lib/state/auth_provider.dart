// ===========================================================================
//  auth_provider.dart  =  STAREA DE AUTENTIFICARE
// ---------------------------------------------------------------------------
//  Tine minte daca userul e logat. Ecranul principal (app.dart) asculta acest
//  provider: cand devii logat, aplicatia trece automat de la login la ecranele
//  native.
//
//  In v2, login-ul se face prin WebView (ecranul de login). Cand portalul
//  confirma autentificarea, ecranul apeleaza markLoggedIn().
//  VIITOR: cand exista API + token, aici verificam existenta tokenului salvat.
// ===========================================================================

import 'package:flutter/foundation.dart';

import '../data/cookie_store.dart';
import '../data/repositories/aci_repository.dart';
import '../data/secure_store.dart';
import '../services/background_sync.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo) {
    _restore();
  }

  // Pastrat pentru viitor (ex: verificari care au nevoie de repository).
  // ignore: unused_field
  final ACIRepository _repo;

  bool _loggedIn = false;
  bool get isLoggedIn => _loggedIn;

  // La pornire: daca avem token de API salvat, suntem deja logati (viitor).
  Future<void> _restore() async {
    final token = await SecureStore.readToken();
    if (token != null && token.isNotEmpty) {
      _loggedIn = true;
      notifyListeners();
    }
  }

  // Apelat de ecranul de login cand portalul confirma autentificarea.
  void markLoggedIn() {
    if (_loggedIn) return;
    _loggedIn = true;
    notifyListeners();
  }

  // Deconectare: sterge tokenul si sesiunea, revine la ecranul de login.
  Future<void> logout() async {
    await SecureStore.clearToken();
    await CookieStore.clear();
    // Fara sesiune, verificarea din fundal nu are ce sa intrebe portalul.
    await BackgroundSync.stop();
    _loggedIn = false;
    notifyListeners();
  }
}

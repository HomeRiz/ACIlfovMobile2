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
import '../data/repositories/switchable_aci_repository.dart';
import '../data/secure_store.dart';
import '../services/background_sync.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo) {
    _restore();
  }

  // Comutabil intre sursa reala si modul demo - vezi enterDemoMode().
  final SwitchableACIRepository _repo;

  bool _loggedIn = false;
  bool get isLoggedIn => _loggedIn;

  bool _isDemo = false;
  bool get isDemo => _isDemo;

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

  // Intra in modul Verificare/Demo: date generate, fara nicio legatura cu
  // portalul real - folosit de butonul de pe ecranul de login, pentru
  // ACIlfov, ca sa poata vedea aplicatia fara sa aiba un cont real acolo.
  void enterDemoMode() {
    if (_loggedIn) return;
    _repo.useDemo = true;
    _isDemo = true;
    _loggedIn = true;
    notifyListeners();
  }

  // Deconectare: sterge tokenul si sesiunea, revine la ecranul de login.
  Future<void> logout() async {
    if (_isDemo) {
      // Nicio sesiune reala de sters - doar iesim din modul demo.
      _repo.useDemo = false;
      _isDemo = false;
      _loggedIn = false;
      notifyListeners();
      return;
    }
    await SecureStore.clearToken();
    await CookieStore.clear();
    // Fara sesiune, verificarea din fundal nu are ce sa intrebe portalul.
    await BackgroundSync.stop();
    _loggedIn = false;
    notifyListeners();
  }
}

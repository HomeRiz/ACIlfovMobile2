// ===========================================================================
//  portal_client.dart  =  CLIENT HTTP CARE FOLOSESTE SESIUNEA DE LOGIN
// ---------------------------------------------------------------------------
//  Cere pagini/date din portalul ACIlfov trimitand cookie-ul de sesiune
//  (obtinut dupa ce te-ai logat in WebView). Practic, "vorbeste" cu portalul
//  ca si cum ai fi tu logat in browser.
//
//  Folosit de CookieACIRepository ca sursa de date reala PANA cand exista API.
// ===========================================================================

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../cookie_store.dart';

class PortalClient {
  final http.Client _http;
  PortalClient({http.Client? client}) : _http = client ?? http.Client();

  // Descarca continutul unei pagini/endpoint din portal, autentificat cu
  // cookie-ul de sesiune. Intoarce textul brut (HTML sau JSON, dupa caz).
  Future<String> fetch(String url) async {
    // Pentru testare cu cont real: daca ai pus un cookie in .env
    // (ACI_SESSION_COOKIE), il folosim. Altfel folosim cookie-ul din login.
    final envCookie = dotenv.maybeGet('ACI_SESSION_COOKIE');
    final cookie = (envCookie != null && envCookie.isNotEmpty)
        ? envCookie
        : await CookieStore.currentHeader(AppConfig.portalUrl);
    if (cookie == null || cookie.isEmpty) {
      throw StateError('Nu exista sesiune (nici in .env, nici din login).');
    }
    final res = await _http.get(
      Uri.parse(url),
      headers: {
        'Cookie': cookie,
        // Ne dam drept browser, ca portalul sa raspunda normal.
        'User-Agent': 'ACIlfovMobile/2.0',
        'Accept': 'text/html,application/json',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Portalul a raspuns cu ${res.statusCode}');
    }
    return res.body;
  }
}

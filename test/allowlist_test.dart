// Test pentru regula de securitate a WebView-ului de login: ce URL-uri au voie
// sa fie pagina principala. Ruleaza cu:  flutter test
import 'package:flutter_test/flutter_test.dart';
import 'package:acilfov_mobile/features/auth/login_screen.dart';

void main() {
  test('permite doar portalul ACIlfov si Cloudflare, doar pe https', () {
    // Permise:
    expect(
        isAllowedMainFrameUrl('https://acilfov.emsys.ro/self_utilities/'), true);
    expect(
        isAllowedMainFrameUrl('https://challenges.cloudflare.com/turnstile'),
        true);

    // Blocate:
    expect(isAllowedMainFrameUrl('http://acilfov.emsys.ro/'), false); // nu https
    expect(isAllowedMainFrameUrl('https://evil.example.com/'), false);
    expect(isAllowedMainFrameUrl('https://emsys.ro/'), false); // subdomeniu vecin
    expect(isAllowedMainFrameUrl('not a url'), false);
  });
}

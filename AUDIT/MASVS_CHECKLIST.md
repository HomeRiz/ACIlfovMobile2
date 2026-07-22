# MASVS checklist - ACIlfovMobile2

Data: 2026-07-07
Standard de referinta: OWASP MASVS v2, mapare practica pentru audit local.

Legenda: PASS = acoperit in codul curent; PARTIAL = acoperit partial sau acceptat cu risc; FAIL = lipseste si trebuie remediat; N/A = nu se aplica fluxului curent.

## MASVS-STORAGE

- PASS: Cookie-ul de sesiune este salvat cu `flutter_secure_storage`, folosind EncryptedSharedPreferences pe Android si Keychain pe iOS.
- PASS: Aplicatia nu salveaza parola utilizatorului.
- PASS: Android backup si device transfer sunt dezactivate/excluse prin manifest si `data_extraction_rules.xml`.
- PASS: Nu am gasit `SharedPreferences`, fisiere locale plaintext sau baze locale pentru date personale.
- PARTIAL: iOS foloseste `KeychainAccessibility.first_unlock_this_device`; pentru sesiuni sensibile se poate evalua `unlocked_this_device`.
- PARTIAL: Android are `FLAG_SECURE`; iOS nu are inca privacy overlay pentru app switcher/snapshot.

## MASVS-CRYPTO

- PASS: Nu exista criptografie custom.
- PASS: Nu am gasit chei criptografice hardcodate, private keys sau certificate private in tree-ul activ.
- PASS: Se folosesc primitivele platformei prin Keychain/EncryptedSharedPreferences.
- PARTIAL: Nu exista certificate/public-key pinning pentru hostul principal.

## MASVS-AUTH

- PASS: Autentificarea este delegata portalului oficial ACIlfov/EMSYS; aplicatia nu implementeaza propriul formular de parola pentru login.
- PASS: Cookie-ul `HttpOnly` este citit din store-ul nativ, nu prin JavaScript.
- PASS: Logout-ul sterge secure storage si cookie store-ul nativ.
- PARTIAL: Operatiunile sensibile folosesc sesiunea portalului, dar nu exista step-up local suplimentar.
- PARTIAL: Nu exista forced update sau invalidare server-side controlata din aplicatie pentru versiuni vechi.

## MASVS-NETWORK

- PASS: Toate URL-urile runtime din configuratie sunt HTTPS.
- PASS: Android are `usesCleartextTraffic=false`.
- PASS: Android `network_security_config.xml` foloseste CA-uri de sistem si blocheaza cleartext.
- PASS: iOS nu contine exceptii ATS in `Info.plist`.
- PARTIAL: Nu exista TLS pinning.
- PARTIAL: Aplicatia foloseste endpoint-uri REST interne EMSYS cu cookie de sesiune; este functional, dar nu este un API public/oficial stabil.

## MASVS-PLATFORM

- PASS: Nu exista deep link-uri sau scheme URL proprii expuse.
- PASS: `android:exported="true"` apare doar pe launcher activity.
- PASS: Permisiunea principala este doar `INTERNET`; nu exista camera, locatie, contacte, microfon, fisiere sau tracking.
- PASS: Nu exista JavaScript bridge catre cod nativ (`addJavaScriptChannel` absent).
- PARTIAL: MethodChannel-ul pentru cookie ar trebui sa valideze defensiv hostul exact si in cod nativ.
- PARTIAL: iOS `clearCookies` sterge toate cookie-urile WKWebsiteDataStore, nu doar domeniul ACIlfov.
- PARTIAL: WebView-ul are allowlist pentru main-frame, dar hardening-ul explicit pentru mixed content/file access nu este documentat/configurat in cod.

## MASVS-CODE

- PASS: `flutter analyze` trece fara probleme.
- PASS: `flutter test` trece, inclusiv testul allowlist WebView.
- PASS: Nu am gasit secrete reale in tree-ul activ.
- PARTIAL: `pubspec.lock` exista local, dar este ignorat si nu este urmarit in git; pentru aplicatie trebuie comis.
- PARTIAL: `flutter pub outdated` arata dependinte majore mai noi si `js` transitive discontinued, desi nu au aparut advisories active in output-ul curent.
- PARTIAL: Release signing cade pe debug key daca lipseste `android/key.properties`; build-ul release de productie trebuie sa esueze in lipsa keystore-ului.

## MASVS-PRIVACY

- PASS: Nu am gasit SDK-uri de analytics, ads sau tracking.
- PASS: Nu exista `NSUserTrackingUsageDescription` si nu se cere tracking.
- PASS: Nu se cer permisiuni sensibile care nu sunt necesare.
- PARTIAL: Notificarile locale pot afisa numarul facturii si data scadenta; continutul este util, dar ar trebui pastrat minim si validat cu cerintele de confidentialitate.
- PARTIAL: Erorile brute pot afisa URL-uri interne in unele SnackBar-uri; mesajele UI ar trebui sanitizate centralizat.

## MASVS-RESILIENCE

- PARTIAL: Nu exista root/jailbreak detection, anti-tamper, anti-debug sau integritate runtime. Acceptabil pentru etapa curenta, dar nu pentru un model de risc ridicat.
- PARTIAL: Nu am gasit obfuscation/split-debug-info configurat explicit pentru release.
- N/A: Nu s-au evaluat controale server-side EMSYS/ACIlfov.

## Rezumat actiuni

- Remediere imediata: release signing fara fallback debug, `pubspec.lock` versionat.
- Remediere scurta: iOS snapshot overlay, validare nativa host cookie, mesaje de eroare sanitizate.
- Remediere planificata: TLS pinning cu proces de rotatie, forced update, API oficial OAuth/OIDC.

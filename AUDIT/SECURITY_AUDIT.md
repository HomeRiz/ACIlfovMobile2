# Audit de securitate - ACIlfovMobile2

Data audit: 2026-07-07
Aplicatie: Flutter, Android si iOS
Repo auditat: `C:\Users\Florin\Documents\GitHub\ACIlfovMobile2`
Baseline luat in calcul: `C:\Users\Florin\Documents\GitHub\ACIlfovMobile\SECURITY_AUDIT.md`

## Verdict

Nu am gasit vulnerabilitati critice sau high in codul curent. Cele mai importante probleme din varianta veche sunt inchise in V2: cookie-ul nu mai este tinut in `.env` sau `shared_preferences`, WebView-ul de login are allowlist pe host exact, backup-ul Android este oprit, cleartext HTTP este blocat, iar aplicatia nu expune deep link-uri proprii sau componente Android in afara launcherului.

Riscul ramas este mediu spre scazut si tine mai ales de hardening pentru productie: release signing nu trebuie sa cada niciodata pe cheia debug, `pubspec.lock` trebuie urmarit in git, iOS are nevoie de protectie pentru snapshot/app switcher, iar pinning-ul TLS si update-ul fortat trebuie planificate impreuna cu operarea serverului.

Auditul este un audit static/local plus verificari de build/test. Nu este un pentest complet impotriva serverului EMSYS/ACIlfov si nu valideaza configuratia server-side.

## Ce am verificat

- Skilluri folosite: code-quality-scan, auth-assessment, network-security-check, secure-storage-audit, privacy-audit, crypto-review, platform-interaction-review, resilience-assessment, masvs-checklist si secure-mobile-dev-guide.
- Cod Dart, Android Kotlin/manifest/XML, iOS Swift/Info.plist, dependinte Flutter, documentatia existenta si istoricul git curent.
- Auditul vechi din `ACIlfovMobile`, in special lista de probleme cautate acolo: stocare sesiune, WebView, backup Android, cleartext, loguri, TLS pinning, fisiere personale, iOS cookie persistence, `Secure` pe cookie si signing release.
- Comenzi rulate: `flutter analyze`, `flutter test`, `flutter pub outdated`, scanari `rg` pentru secrete, cleartext, permisiuni, clipboard, WebView bridge, MethodChannel, backup si configuratii native.

## Rezultate bune confirmate

- Stocare sesiune: `lib/data/cookie_store.dart` foloseste `flutter_secure_storage` cu `AndroidOptions(encryptedSharedPreferences: true)` si Keychain pe iOS. Cookie-ul de sesiune se salveaza doar daca exista indicatori de sesiune (`sl-session` sau `SELF_UTI`).
- Stocare token viitor: `lib/data/secure_store.dart` foloseste aceeasi stocare securizata. Nu am gasit parole, tokenuri reale sau chei API hardcodate in tree-ul activ.
- WebView login: `lib/features/auth/login_screen.dart` permite main-frame doar pentru `https://acilfov.emsys.ro` si `https://challenges.cloudflare.com`; exista test dedicat in `test/allowlist_test.dart`.
- Nu exista JavaScript bridge catre nativ: nu am gasit `addJavaScriptChannel`; canalul nativ `acilfov/cookies` este folosit din Dart, nu din continutul web.
- Android backup: `android:allowBackup="false"`, `android:fullBackupContent="false"` si `data_extraction_rules.xml` exclud sharedpref/database/file/external din backup si device transfer.
- Network Android: `android:usesCleartextTraffic="false"` si `network_security_config.xml` blocheaza cleartext si foloseste doar CA-uri de sistem.
- iOS ATS: `Info.plist` nu contine exceptii `NSAppTransportSecurity`/`NSAllowsArbitraryLoads`.
- Permisiuni: manifestul principal cere doar `INTERNET`; nu sunt permisiuni pentru locatie, camera, contacte, poze, microfon sau tracking.
- Privacy: nu am gasit analytics, reclame, SDK-uri de tracking sau identificatori persistenti terti.
- Crypto: nu am gasit algoritmi custom, chei hardcodate sau criptografie proprie. Aplicatia se bazeaza pe Keychain/EncryptedSharedPreferences si TLS.
- Build/test: `flutter analyze` a trecut fara probleme; `flutter test` a trecut cu 2 teste.

## Status fata de auditul vechi

| Problema din ACIlfovMobile | Status in ACIlfovMobile2 |
| --- | --- |
| Cookie/sesiune in plaintext sau `.env` runtime | Remediat in codul activ; cookie-ul este in secure storage. Istoricul git curent mai contine referinte vechi la `.env`/`.env.example`, dar nu am gasit secrete reale. |
| WebView cu navigare nerestrictionata | Remediat; main-frame allowlist exact, testat. |
| Android backup implicit permis | Remediat; backup si transfer sunt oprite/excluse. |
| Cleartext HTTP permis | Remediat; Android cleartext off, iOS fara ATS exception. |
| Loguri cu informatii sensibile | In mare remediat; logurile ramase sunt sub `kDebugMode`. Mai ramane riscul separat de mesaje brute in UI, vezi F-07. |
| Lipsa TLS pinning | Nerezolvat; ramane risc acceptat/planificat, vezi F-02. |
| Fisiere personale/artefacte generate in git | Nu am gasit secrete reale in tree-ul activ. Istoricul curent are doar false positive-uri/documentatie si referinte vechi, nu valori reale de cookie/token/chei. |
| iOS cookie fara expirare / salvare incompleta | Remediat; iOS seteaza expirare la restaurare, iar salvarea se face din lifecycle/login. |
| Cookie Android restaurat fara `Secure` | Remediat; Android adauga `Secure; HttpOnly; SameSite=Lax`. |
| Release signing cu debug fallback | Ramane risc de productie, vezi F-01. |

## Constatari curente

### F-01 - Release signing cade pe cheia debug daca lipseste keystore-ul

Severitate: Medie

In `android/app/build.gradle.kts`, build type-ul `release` foloseste `signingConfigs.getByName("debug")` daca lipseste `android/key.properties`. Asta e convenabil la dezvoltare, dar periculos pentru distributie: un APK/AAB de productie semnat cu debug key poate fi impersonat mai usor si nu respecta controlul de release.

Remediere recomandata: pentru `release`, esueaza build-ul daca `key.properties` lipseste. Pentru dezvoltare foloseste explicit `debug` sau un flavor intern, nu fallback tacit in `release`.

### F-02 - TLS certificate/public-key pinning lipseste

Severitate: Medie

Traficul este HTTPS-only, iar Android accepta doar CA-uri de sistem, dar nu exista pinning pentru `acilfov.emsys.ro`. Un atacator cu control asupra lantului de incredere al dispozitivului sau al retelei enterprise poate ramane o problema.

Remediere recomandata: implementeaza pinning SPKI/public key doar dupa ce exista proces operational de rotatie a certificatului. Pinning gresit poate bloca toti utilizatorii la schimbarea certificatului, deci trebuie coordonat cu administratorul serverului.

### F-03 - `pubspec.lock` este ignorat si nu este urmarit in git

Severitate: Medie

`.gitignore` contine `pubspec.lock`, iar `git ls-files --stage pubspec.lock` nu returneaza fisierul. Pentru o aplicatie mobila, lockfile-ul trebuie versionat ca build-urile, auditul dependintelor si reproducibilitatea sa fie stabile.

Remediere recomandata: elimina `pubspec.lock` din `.gitignore`, ruleaza `flutter pub get`, apoi comite `pubspec.lock`.

### F-04 - Sursa activa foloseste endpoint-uri REST interne EMSYS cu sesiune cookie

Severitate: Medie

`AppConfig.dataSource = DataSource.cookie`, iar aplicatia reutilizeaza endpoint-urile interne ale portalului EMSYS (`/self_utilities/rest/self/...`) cu cookie-ul de sesiune. Este mai sigur decat varianta veche cu `.env`, dar ramane dependent de API-uri neoficiale si de comportamentul portalului web.

Remediere recomandata: pastreaza aceasta solutie ca tranzitie, dar tinta de productie ar trebui sa fie API oficial cu OAuth/OIDC, scope-uri, token refresh, rate limiting si contract stabil.

### F-05 - iOS nu are protectie pentru screenshot/app switcher

Severitate: Medie

Android activeaza `FLAG_SECURE` in `MainActivity`, dar `ios/Runner/SceneDelegate.swift` nu adauga un overlay cand aplicatia intra in background/inactive. Datele din facturi, cont, sold sau index pot aparea in snapshot-ul sistemului.

Remediere recomandata: adauga un privacy overlay in scene lifecycle (`sceneWillResignActive`/`sceneDidEnterBackground`) si elimina overlay-ul la revenire. Daca UX-ul permite, evalueaza si masuri de tip blur pentru ecrane sensibile.

### F-06 - Canalul nativ de cookie are validare slaba de domeniu

Severitate: Scazuta

Pe Android, `MainActivity.kt` accepta URL-ul primit din Dart pentru `getCookies`/`setCookies`. Pe iOS, `AppDelegate.swift` citeste cookie-urile cu `domain.contains("emsys.ro")`, ceea ce poate include subdomenii vecine sau domenii care contin acel text. Codul Dart trimite acum URL-ul corect, iar continutul web nu poate apela canalul direct, deci riscul practic este limitat.

Remediere recomandata: valideaza defensiv si nativ hostul exact `acilfov.emsys.ro`; pe iOS filtreaza `domain == "acilfov.emsys.ro"` sau `.acilfov.emsys.ro`, nu `contains`.

### F-07 - Erorile brute pot afisa URL-uri interne in SnackBar

Severitate: Scazuta

`PortalClient` arunca exceptii care includ URL-ul complet al endpoint-ului, iar mai multe ecrane afiseaza `_cleanError(e)` direct in `SnackBar`. `FailsafeErrorState` sanitizeaza mai bine erorile generale, dar actiunile de scriere pot expune endpoint-uri interne catre utilizator.

Remediere recomandata: introdu o clasa de exceptie controlata (`PortalException(statusCode, operation)`) si mapeaza toate mesajele UI la texte prietenoase fara URL complet, parametri sau detalii de endpoint.

### F-08 - WebView-ul are JavaScript nelimitat si hardening explicit incomplet

Severitate: Scazuta

Login-ul are nevoie de JavaScript pentru portal/Cloudflare si main-frame allowlist-ul reduce riscul. Totusi nu am gasit hardening explicit pentru mixed content, file access, universal access from file URLs sau media/file permissions pe Android WebView.

Remediere recomandata: pastreaza JS doar pentru login, configureaza explicit setarile Android WebView unde pluginul permite, blocheaza mixed content si file access, si documenteaza de ce iframe-urile Cloudflare raman permise.

### F-09 - Campurile de parola nu dezactiveaza explicit sugestii/autocorrect

Severitate: Scazuta

`ChangePasswordView` foloseste `obscureText`, dar `enableSuggestions: false` si `autocorrect: false` nu sunt setate explicit pentru campurile de parola. Flutter trateaza multe cazuri corect, dar pentru MASVS este mai bine sa fie explicit.

Remediere recomandata: seteaza `enableSuggestions: false`, `autocorrect: false`, `keyboardType: TextInputType.visiblePassword` si, unde e potrivit, `textInputAction`.

### F-10 - Keychain accessibility poate fi intarit

Severitate: Scazuta

`CookieStore` si `SecureStore` folosesc `KeychainAccessibility.first_unlock_this_device`. Aceasta setare impiedica migrarea pe alt dispozitiv, dar permite acces dupa primul unlock si cand telefonul este ulterior blocat. Pentru cookie/token de sesiune, o setare mai stricta poate fi preferabila daca aplicatia nu are nevoie de acces in background.

Remediere recomandata: evalueaza `unlocked_this_device` pentru cookie/token, cu testare pe iOS ca restaurarea sesiunii dupa restart sa ramana acceptabila.

### F-11 - Dependinte invechite si un pachet transitive discontinued

Severitate: Scazuta

`flutter pub outdated` nu a raportat advisories active in output-ul curent, dar arata dependinte directe depasite: `connectivity_plus`, `flutter_local_notifications`, `flutter_secure_storage`, `timezone`, `flutter_lints`. Pachetul transitive `js` este marcat discontinued.

Remediere recomandata: planifica upgrade controlat, ruleaza testele si build-urile Android/iOS dupa fiecare salt major. Dupa ce `pubspec.lock` este versionat, adauga verificare periodica `flutter pub outdated`/SCA in CI.

### F-12 - Nu exista mecanism de forced update pentru remedieri critice

Severitate: Scazuta spre Medie

Aplicatia nu are mecanism de versiune minima suportata. Daca apare o problema de securitate in client, utilizatorii pot ramane pe versiuni vulnerabile.

Remediere recomandata: cand exista backend/API oficial, expune `minimum_supported_version` si blocheaza sau limiteaza versiunile vechi cu mesaj clar de update.

### F-13 - Protectiile de rezilienta sunt minimale

Severitate: Informativ

Nu am gasit root/jailbreak detection, Play Integrity/App Attest, anti-debug, anti-tamper sau obfuscation/split-debug-info configurat explicit. Pentru o aplicatie utilitara cu server-side auth, lipsa lor nu este critica, dar creste usurinta de reverse engineering.

Remediere recomandata: pentru distributie publica, activeaza build-uri release cu obfuscation/split-debug-info si evalueaza Play Integrity/App Attest pentru fluxuri sensibile. Nu baza securitatea principala pe aceste controale; serverul ramane sursa de incredere.

### F-14 - Logout-ul iOS sterge toate cookie-urile WKWebsiteDataStore

Severitate: Scazuta

`AppDelegate.swift` sterge toate cookie-urile din `WKWebsiteDataStore.default()` la `clearCookies`, nu doar cookie-urile pentru `acilfov.emsys.ro`. Intr-o aplicatie care foloseste WebView doar pentru login este probabil acceptabil, dar este mai larg decat necesar.

Remediere recomandata: sterge doar cookie-urile cu domeniul exact al portalului ACIlfov.

## Prioritate recomandata

1. Fix de release pipeline: scoate fallback-ul la debug signing si urmareste `pubspec.lock` in git.
2. Hardening confidentialitate: iOS app switcher overlay, cookie channel host validation, cookie clear scoped.
3. Hardening UI: exceptii controlate si mesaje fara URL-uri interne; password fields explicit no-suggestions.
4. Hardening WebView: mixed content/file access explicit off si documentare pentru Cloudflare iframe.
5. Plan operational: TLS pinning SPKI, forced update si tranzitie spre API oficial OAuth/OIDC.

## Verificari executate

```text
flutter analyze
No issues found!

flutter test
All tests passed! (2 tests)

flutter pub outdated
Dependinte directe depasite, fara advisories active raportate in output-ul curent; `js` transitive discontinued.
```

Scanarile pentru secrete au returnat doar false positive-uri: campul legitim `password` trimis la schimbare parola, nume de variabile pentru tokenul viitor, documentatie despre OAuth/API si referinte istorice la `.env`/`.env.example`. Nu am gasit cookie-uri reale, tokenuri reale, chei API, private keys sau keystore-uri in tree-ul activ.

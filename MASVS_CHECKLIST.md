# MASVS checklist - ACIlfovMobile2

Data: 2026-07-07

## MASVS-STORAGE

- PASS: Cookie-ul de sesiune este salvat prin `flutter_secure_storage`.
- PASS: Android foloseste `encryptedSharedPreferences`.
- PASS: Backup Android si device transfer sunt dezactivate pentru datele
  aplicatiei.
- PASS: `.env` nu este folosit in runtime.
- PARTIAL: Nu exista mecanism de expirare locala custom; expirarea reala este
  controlata de cookie-ul portalului.

## MASVS-CRYPTO

- PASS: Aplicatia nu implementeaza criptografie proprie.
- PASS: Stocarea criptata este delegata platformei.
- PARTIAL: Nu exista pinning TLS.

## MASVS-AUTH

- PASS: Autentificarea ramane in portalul oficial ACIlfov.
- PASS: Logout sterge tokenul viitor si cookie-urile native.
- PASS: Schimbarea parolei foloseste endpoint-ul real al portalului.
- PARTIAL: Sesiunea depinde de cookie-ul portalului si de politicile serverului.

## MASVS-NETWORK

- PASS: Traficul HTTP cleartext este dezactivat pe Android.
- PASS: WebView-ul de login are allowlist HTTPS pentru main-frame.
- PASS: iOS nu are `NSAllowsArbitraryLoads`.
- PARTIAL: Nu exista pinning TLS.

## MASVS-PLATFORM

- PASS: Nu exista JavaScript channel expus din WebView.
- PASS: Android `FLAG_SECURE` este activ.
- PASS: Nu exista deep links exportate in manifest.
- PARTIAL: iOS nu are inca protectie similara pentru screenshot/app switcher.

## MASVS-CODE

- PASS: `flutter analyze` trece.
- PASS: `flutter test` trece.
- PASS: Endpoint-urile folosite de paginile active au fost centralizate in
  `AppConfig`.
- PARTIAL: `ApiACIRepository` ramane schelet pentru viitorul API oficial.

## MASVS-PRIVACY

- PASS: Permisiune Android minima: `INTERNET`.
- PASS: Nu exista SDK-uri de analytics/tracking.
- PASS: Link-urile GDPR/licente duc la sursele oficiale ACIlfov.
- PARTIAL: Politica de retentie a cookie-ului este mostenita din portal.

## MASVS-RESILIENCE

- PARTIAL: Nu exista root/jailbreak detection sau anti-tamper; nu este critic
  pentru faza curenta de aplicatie utilitara, dar poate fi decis pentru release.
- PARTIAL: Build-ul release trebuie semnat cu keystore de productie.

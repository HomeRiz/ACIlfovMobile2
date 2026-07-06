# ACIlfovMobile2 - audit securitate mobil

Data audit: 2026-07-07

Auditul a folosit skill-urile instalate din
`dweinstein/mobile-security-skills`: `secure-storage-audit`,
`network-security-check`, `auth-assessment`, `privacy-audit`,
`platform-interaction-review`, `code-quality-scan`, `masvs-checklist` si
`mobile-threat-model`.

## Rezumat

Status general: potrivit pentru testare pe dispozitiv real dupa validarea
fluxurilor EMSYS cu un cont autentic. Problemele critice din auditul V1 sunt
inchise in V2: nu mai exista `.env` in runtime, cookie-ul este salvat in storage
criptat, backup-ul Android este dezactivat, traficul cleartext este blocat, iar
WebView-ul este limitat la domeniile necesare autentificarii.

## Remedieri aplicate

- Stocare sesiune: `CookieStore` foloseste `flutter_secure_storage` cu
  `encryptedSharedPreferences` pe Android si Keychain pe iOS.
- Backup Android: `allowBackup=false`, `fullBackupContent=false` si
  `dataExtractionRules` exclud shared preferences, database, file si external.
- Retea: `usesCleartextTraffic=false` si `network_security_config.xml` permit
  doar CA-uri de sistem si interzic HTTP necriptat.
- Autentificare: WebView-ul de login permite navigare main-frame doar pe
  `https://acilfov.emsys.ro` si `https://challenges.cloudflare.com`.
- Platform interaction: nu exista `addJavaScriptChannel`; link-urile Info ies
  prin browser extern unde este cazul.
- Privacy: permisiunea Android activa este doar `INTERNET`; nu exista analytics,
  tracker SDK sau identificatori publicitari.
- Protectie ecran Android: `FLAG_SECURE` este activ in `MainActivity`, deci
  capturile de ecran si preview-ul din recents sunt blocate pe Android.
- Secrete: `.env` si `flutter_dotenv` au fost eliminate din runtime; `.gitignore`
  exclude fisiere env, chei si certificate private.

## Riscuri ramase

| Risc | Severitate | Status |
| --- | --- | --- |
| TLS pinning nu este implementat | Medie | Risc acceptabil temporar; aplicatia se bazeaza pe trust store-ul sistemului si HTTPS strict. |
| API-ul folosit este REST intern EMSYS, nu API public oficial | Medie | Functional acum, dar poate necesita mentenanta daca portalul isi schimba bundle-ul. |
| Protectia de screenshot pe iOS nu este implementata | Medie | Recomandat inainte de release iOS. |
| Release signing cade pe debug daca lipseste `android/key.properties` | Medie | Pentru productie trebuie configurat keystore release. |
| Upload atasament Contact nu este implementat | Scazuta | Mesajele fara atasament functioneaza; atasamentul ramane de adaugat. |

## Verificari rulate

- `flutter analyze` - fara erori.
- `flutter test` - toate testele trec.
- Scan cod: fara `flutter_dotenv`, fara `shared_preferences`, fara
  `addJavaScriptChannel`, fara `print(` in codul Dart.
- Android manifest/config: backup dezactivat, cleartext dezactivat, network
  security config prezent.

## Recomandari inainte de productie

- Configurare keystore release si verificare ca `flutter build apk --release`
  nu foloseste cheia debug.
- Test manual pe cont real pentru toate actiunile de scriere: contact,
  configurari, schimbare parola, adaugare/stergere cod client, transmitere
  index.
- Implementare protectie screenshot iOS cand aplicatia iOS intra in etapa de
  release.
- Decizie explicita pentru TLS pinning sau monitorizare certificate, tinand cont
  de Cloudflare si rotatia certificatelor portalului.

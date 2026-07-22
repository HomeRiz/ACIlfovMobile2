# Apa Ilfov Mobile

Aplicatie mobila Flutter pentru clientii Apa-Canal Ilfov. Proiectul genereaza doua aplicatii native din acelasi cod sursa: Android si iOS.

Aplicatia foloseste WebView doar pentru autentificarea in portalul oficial `acilfov.emsys.ro`. Dupa autentificare, ecranele principale sunt native Flutter si citesc datele prin sesiunea reala a portalului, pana cand exista un API oficial ACIlfov.

## Cuprins

- Prezentare proiect
- Structura proiectului
- Documente mutate pentru verificare
- Cerinte locale
- Instalare dupa clone
- Build si test Android
- Build si test iOS
- Publicare Google Play
- Publicare App Store
- Securitate si audit

## Prezentare proiect

Aplicatia include:

- autentificare prin portalul oficial ACIlfov/EMSYS;
- interfata nativa pentru acasa, facturi, plati, consum, index, configurari, contact si informatii cont;
- notificari locale pentru index si facturi scadente;
- stocare securizata pentru cookie-ul de sesiune;
- structura pregatita pentru trecerea la un API oficial cu token cand acesta va fi disponibil.

Sursa activa de date este configurata in `lib/core/config/app_config.dart`:

```dart
static const DataSource dataSource = DataSource.cookie;
```

Valorile disponibile sunt:

| Valoare | Rol |
| --- | --- |
| `DataSource.mock` | Date locale de test pentru dezvoltare si verificare UI. |
| `DataSource.cookie` | Date reale prin sesiunea portalului, fluxul activ in prezent. |
| `DataSource.api` | Pregatit pentru viitorul API oficial ACIlfov. |

## Structura proiectului

Fisiere si foldere pastrate in root pentru aplicatie si build:

```text
android/                 proiectul nativ Android si configuratia Gradle
ios/                     proiectul nativ iOS, Xcode si CocoaPods
lib/                     codul Flutter al aplicatiei
assets/                  resurse incluse in aplicatie
test/                    teste automate Flutter
pubspec.yaml             dependinte, versiune si asset-uri Flutter
pubspec.lock             versiuni exacte ale dependintelor pentru build reproductibil
analysis_options.yaml    reguli de analiza statica
.metadata                metadata Flutter pentru proiect
.gitignore               reguli pentru fisiere locale si artefacte de build
README.md                documentul principal al proiectului
USERCHECK/               documente mutate pentru revizuire inainte de stergere
AUDIT/                   rapoarte de securitate pastrate separat de USERCHECK
```

Structura principala din `lib/`:

```text
lib/
  main.dart                         punctul de pornire
  app.dart                          tema si rutarea login/aplicatie
  core/config/app_config.dart       URL-uri, culori si sursa de date
  data/models/                      modelele de date
  data/repositories/                surse mock/cookie/api
  data/sources/                     clienti HTTP pentru portal/API
  data/cookie_store.dart            acces si persistenta cookie sesiune
  data/secure_store.dart            stocare securizata pentru token viitor
  features/                         ecranele aplicatiei
  services/notification_service.dart notificari locale
  state/                            Provider pentru auth si date cont
```

## Documente mutate pentru verificare

Tot ce nu este necesar direct pentru construirea aplicatiilor Android/iOS a fost mutat in `USERCHECK/`, ca sa poata fi revizuit inainte de stergere.

Documentele de audit securitate nu sunt in `USERCHECK`, deoarece acel folder poate fi sters dupa revizuire. Ele sunt pastrate separat in `AUDIT/`:

- `AUDIT/SECURITY_AUDIT.md`
- `AUDIT/MASVS_CHECKLIST.md`
- `AUDIT/THREAT_MODEL.md`
- `AUDIT/PAGES_REAL_API_STATUS.md`

Alte documente mutate:

- `USERCHECK/docs/ARHITECTURA.md`
- `USERCHECK/docs/PROPUNERE-TEHNICA-ACILFOV.md`
- `USERCHECK/IOS_BUILD_MACBOOK.md`
- `USERCHECK/handoff.md`
- `USERCHECK/AGENTS.md`
- `USERCHECK/generated-ios/README_LAUNCH_IMAGE_ASSETS.md`

## Cerinte locale

Pentru Android:

- Git;
- Flutter SDK instalat si disponibil in `PATH`;
- Android Studio;
- Android SDK, Android Platform Tools si un emulator configurat;
- Java/JDK furnizat de Android Studio sau configurat separat.

Pentru iOS:

- macOS;
- Flutter SDK;
- Xcode;
- CocoaPods;
- cont Apple Developer pentru instalare pe iPhone real si publicare.

Verificare mediu:

```bash
flutter doctor -v
```

## Instalare dupa clone

Cloneaza repository-ul:

```bash
git clone <URL_REPOSITORY>
cd ACIlfovMobile2
```

Descarca dependintele:

```bash
flutter pub get
```

Ruleaza verificarile de baza:

```bash
flutter analyze
flutter test
```

Regula de testare pe dispozitive: inainte de instalarea unui build nou, dezinstaleaza variantele vechi ale aplicatiei. Pe Android verifica pachetele `ro.acilfov.mobile` si orice identificator vechi folosit in testare.

## Build si test Android

### Debug pe emulator Android

Porneste un emulator din Android Studio sau din terminal:

```bash
flutter emulators
flutter emulators --launch <ID_EMULATOR>
```

Verifica dispozitivele:

```bash
flutter devices
adb devices
```

Dezinstaleaza aplicatia veche din emulator:

```bash
adb -s <DEVICE_ID> shell pm list packages | findstr acilfov
adb -s <DEVICE_ID> uninstall ro.acilfov.mobile
```

Ruleaza aplicatia direct:

```bash
flutter run -d <DEVICE_ID>
```

Sau construieste APK debug pentru emulator:

```bash
flutter build apk --debug --target-platform android-x64
adb -s <DEVICE_ID> install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Debug pe telefon Android real

Activeaza pe telefon `Developer options` si `USB debugging`, apoi conecteaza telefonul prin USB.

```bash
adb devices
adb -s <DEVICE_ID> uninstall ro.acilfov.mobile
flutter build apk --debug --target-platform android-arm,android-arm64
adb -s <DEVICE_ID> install -r build/app/outputs/flutter-apk/app-debug.apk
```

Pentru lansare si loguri:

```bash
adb -s <DEVICE_ID> shell monkey -p ro.acilfov.mobile 1
adb -s <DEVICE_ID> logcat
```

### Release Android pentru test pe telefon

Pentru un build release local:

```bash
flutter clean
flutter pub get
flutter build apk --release --target-platform android-arm,android-arm64
```

APK-ul rezultat:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Instalare pe telefon:

```bash
adb -s <DEVICE_ID> uninstall ro.acilfov.mobile
adb -s <DEVICE_ID> install -r build/app/outputs/flutter-apk/app-release.apk
```

Pentru productie, release-ul trebuie semnat cu keystore de productie/upload key, nu cu debug key.

Configurare semnare Android:

1. Genereaza sau obtine upload keystore-ul.
2. Pune keystore-ul local in `android/app/`, de exemplu `android/app/upload-keystore.jks`.
3. Creeaza `android/key.properties` local, fara sa il comiti:

```properties
storePassword=<PAROLA_STORE>
keyPassword=<PAROLA_KEY>
keyAlias=upload
storeFile=upload-keystore.jks
```

4. Construieste AAB pentru Google Play:

```bash
flutter build appbundle --release --target-platform android-arm,android-arm64
```

Fisierul rezultat:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Build si test iOS

Build-ul iOS se face pe macOS.

### Debug pe simulator iOS

```bash
flutter pub get
flutter devices
flutter run -d <ID_SIMULATOR>
```

Sau build fara rulare:

```bash
flutter build ios --debug --simulator
```

### Test pe iPhone real

1. Conecteaza iPhone-ul la Mac.
2. Deschide workspace-ul iOS:

```bash
open ios/Runner.xcworkspace
```

3. In Xcode intra la `Runner` -> `Signing & Capabilities`.
4. Alege `Team` din contul Apple Developer.
5. Verifica `Bundle Identifier`. Pentru update peste aceeasi aplicatie, pastreaza identificatorul stabilit pentru proiect.
6. Selecteaza iPhone-ul conectat si apasa `Run`.

Daca iPhone-ul cere incredere pentru profilul de developer, intra pe telefon la:

```text
Settings -> General -> VPN & Device Management
```

si apasa `Trust` pentru profilul folosit la semnare.

Build release iOS:

```bash
flutter clean
flutter pub get
flutter build ios --release
```

Pentru IPA:

```bash
flutter build ipa --release
```

IPA-ul este generat in:

```text
build/ios/ipa/
```

## Publicare Google Play

Publicarea se face din Google Play Console.

1. Incrementeaza versiunea in `pubspec.yaml`, de exemplu:

```yaml
version: 2.0.1+2
```

2. Ruleaza verificarile:

```bash
flutter analyze
flutter test
```

3. Configureaza semnarea release in `android/key.properties`.
4. Genereaza AAB:

```bash
flutter build appbundle --release --target-platform android-arm,android-arm64
```

5. Intra in [Google Play Console](https://play.google.com/console).
6. Creeaza aplicatia sau selecteaza aplicatia existenta.
7. Completeaza `Store listing`, screenshots, icon, descriere, categorie si date de contact.
8. Completeaza `App content`: Data safety, privacy policy, target audience, ads, content rating.
9. Intra la `Release` -> `Testing` pentru test intern sau inchis.
10. Incarca fisierul `app-release.aab`.
11. Verifica raportul Play Console si publica intai pe test intern.
12. Dupa validare, promoveaza release-ul catre productie.

## Publicare App Store

Publicarea se face din Apple Developer si App Store Connect.

1. Incrementeaza versiunea in `pubspec.yaml`.
2. In Apple Developer creeaza/verifica `Identifier` pentru bundle id-ul aplicatiei.
3. In Xcode, la `Runner` -> `Signing & Capabilities`, seteaza `Team` si signing automat sau manual.
4. Genereaza build release:

```bash
flutter build ipa --release
```

Sau foloseste Xcode:

```text
Xcode -> Product -> Archive
```

5. In Xcode Organizer apasa `Distribute App` si trimite build-ul catre App Store Connect.
6. Intra in [App Store Connect](https://appstoreconnect.apple.com/).
7. Creeaza aplicatia sau selecteaza aplicatia existenta.
8. Completeaza metadata: nume, subtitlu, descriere, keywords, screenshots, categorie, suport si privacy policy.
9. Completeaza `App Privacy`.
10. Publica intai in TestFlight.
11. Dupa testare, trimite build-ul la App Review pentru publicare.

## Securitate si audit

Aplicatia a fost auditata local pe cod, configuratii Android/iOS si dependinte. Rapoartele sunt in `AUDIT/`:

- `SECURITY_AUDIT.md` - raportul complet de audit;
- `MASVS_CHECKLIST.md` - checklist OWASP MASVS;
- `THREAT_MODEL.md` - modelul de amenintari;
- `PAGES_REAL_API_STATUS.md` - statusul paginilor conectate la date reale.

Rezumat audit:

- nu au fost gasite vulnerabilitati critice sau high in codul curent;
- sesiunea este stocata in secure storage;
- Android are backup dezactivat si cleartext blocat;
- WebView-ul de login are allowlist pe domenii;
- raman recomandari de productie pentru signing release, pinning TLS, forced update, protectie iOS pentru app switcher si versionarea `pubspec.lock`.

## Note operationale

- Inainte de test pe emulator sau telefon real, dezinstaleaza aplicatiile vechi cu acelasi pachet sau cu pachete folosite anterior.
- Pentru emulator Android se folosesc ABI-uri x86/x64.
- Pentru telefoane Android reale se folosesc ABI-uri ARM: `android-arm` si `android-arm64`.
- `android/key.properties`, keystore-urile, certificatele si fisierele `.env` nu se comit in git.
- `pubspec.lock` trebuie pastrat si comis pentru build-uri reproductibile.

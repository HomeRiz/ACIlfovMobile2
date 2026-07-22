# Predare context - Apa Ilfov Mobile

Ultima actualizare: 2026-07-07 04:01 EEST

## Stare curenta

- Aplicatia a fost redenumita vizibil din `ACIlfov` in `Apa Ilfov` pe iOS si Android.
- Bundle/application id ramane `ro.acilfov.mobile`, intentionat, ca sa nu apara o a doua aplicatie la update.
- Logo-ul AIF este folosit in drawer si pentru launcher icons iOS/Android.
- Ecranul Info este nativ: Licenta de utilizare, Conformitate GDPR si Politica de cookie nu mai redirectioneaza catre site.
- Din Info a fost eliminat `Formular standard GDPR`.
- Din Info a fost eliminat mesajul `Continut incarcat din surse oficiale ACIlfov.ro`.
- Din Configurari a fost eliminat mesajul `Sursa de date curenta: cookie`.
- Din Transmitere index a fost eliminat helper-ul `Aceeasi valoare se trimite si la verificarea indexului`.
- In Contact au fost eliminate iconitele de redirect de la telefon, email si website; randurile raman apasabile.
- A fost adaugat banner global offline: `Verificati conexiunea la internet. Se asteapta conexiunea la internet.`
- Cand conexiunea revine, aplicatia reincarca datele contului daca utilizatorul este autentificat.

## Failsafe sesiune / erori

- Fisier nou: `lib/core/widgets/failsafe_error_state.dart`.
- Erorile HTTP sunt afisate scurt, fara URL intern, de forma:
  - `Eroare 403: autentificare esuata sau sesiune expirata.`
  - `Eroare 500: eroare interna pe server.`
- Dupa 3 apasari pe `Reincarca` pentru aceeasi eroare, utilizatorul este delogat.
- Logout-ul sterge tokenul si cookie-urile vechi prin fluxul existent `AuthProvider.logout()` -> `CookieStore.clear()`.
- Failsafe-ul este conectat pe ecranele principale care pot primi erori de sesiune: Acasa, Facturi, Index, Configurari, Contact, Actualizare date, Informatii cont, Plati si Grafic consum.

## Securitate / cookie

- Cookie-urile de sesiune sunt salvate cu `flutter_secure_storage`.
- Android foloseste `EncryptedSharedPreferences`.
- iOS foloseste Keychain cu `KeychainAccessibility.first_unlock_this_device`.
- Android restore seteaza cookie-urile cu `Secure; HttpOnly; SameSite=Lax`.
- iOS restore seteaza cookie-urile cu `Secure` si `HttpOnly`.
- Android are `allowBackup=false`, `usesCleartextTraffic=false` si `networkSecurityConfig` cu cleartext interzis.
- Auditul facut este tehnic, pe cod/configuratii. Nu reprezinta certificare juridica GDPR.

## iOS

- Build simulator reusit:
  - `flutter build ios --debug --simulator`
  - output: `build/ios/iphonesimulator/Runner.app`
- Build release reusit:
  - `flutter build ios --release`
  - output: `build/ios/iphoneos/Runner.app`
- Aplicatia a fost instalata si pornita in simulatorul `iPhone 17`.
- Simulatorul arata aplicatia pornita pe Acasa.
- Daca simulatorul are sesiune expirata, noul failsafe trebuie sa afiseze mesaj scurt si sa delogheze dupa 3 reincarcari.

## Android

- Build debug reusit:
  - `flutter build apk --debug`
  - output: `build/app/outputs/flutter-apk/app-debug.apk`
- Build release reusit:
  - `flutter build apk --release`
  - output: `build/app/outputs/flutter-apk/app-release.apk`
- Testarea pe Android emulator a fost oprita la cererea utilizatorului.
- Utilizatorul va testa APK-ul pe Windows.

## Verificari rulate

- `flutter analyze` - OK
- `flutter test` - OK
- `flutter build ios --debug --simulator` - OK
- `flutter build ios --release` - OK
- `flutter build apk --debug` - OK
- `flutter build apk --release` - OK

## Note importante

- Pentru cautarea dupa termeni precum `acilfov`, `apa`, `aif`, `apa ilfov`, `ilfov`, `apa canal ilfov`, `canal ilfov`, `canal`, partea garantata in cod este numele vizibil `Apa Ilfov`. Cuvintele cheie reale de cautare in App Store / Google Play trebuie setate in metadata store-ului.
- Identificatorii tehnici vechi `ro.acilfov.mobile` si channel-ul `acilfov/cookies` au fost pastrati pentru compatibilitate si update fara duplicarea aplicatiei.
- Continutul nativ Info este sumarizat/parafrazat din paginile oficiale ACIlfov/Apa-Canal Ilfov.

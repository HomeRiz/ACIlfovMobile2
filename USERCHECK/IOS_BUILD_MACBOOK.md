# Build iOS pe MacBook

Build-ul iOS nu poate fi generat pe Windows. Pentru iPhone ai nevoie de macOS,
Xcode si un cont Apple Developer configurat in Xcode.

## Mesaj pentru Codex pe MacBook

Cand deschizi repo-ul pe MacBook, poti trimite acest mesaj:

> Sunt pe MacBook în repo-ul ACIlfovMobile2. Te rog să verifici mediul iOS, să rulezi flutter doctor, flutter pub get, să repari ce lipsește pentru iOS, să faci build iOS pentru test pe iPhone și să deschizi/explici ce trebuie setat în Xcode pentru signing. iPhone-ul este conectat pentru testare.

## Pasi pe MacBook

1. Dezarhiveaza proiectul si intra in folder:

   ```bash
   cd ACIlfovMobile2
   ```

2. Verifica mediul:

   ```bash
   flutter doctor -v
   ```

3. Descarca dependintele:

   ```bash
   flutter pub get
   ```

4. Valideaza build-ul iOS fara semnare:

   ```bash
   flutter build ios --debug --no-codesign
   ```

5. Pentru test pe iPhone, deschide proiectul in Xcode:

   ```bash
   open ios/Runner.xcworkspace
   ```

   In Xcode:
   - selecteaza targetul `Runner`;
   - seteaza `Team` la contul tau Apple;
   - pastreaza bundle id `ro.acilfov.mobile` sau schimba-l daca Apple cere un
     identificator unic;
   - conecteaza iPhone-ul si apasa `Run`.
   - daca iPhone-ul refuza lansarea cu mesaj de profil/developer nevalidat,
     deschide pe iPhone `Settings` -> `General` -> `VPN & Device Management`
     si apasa `Trust` pentru profilul Apple Developer folosit la semnare.

   Pentru instalare release direct din terminal:

   ```bash
   flutter build ios --release
   flutter install -d <DEVICE_ID> --release
   ```

6. Pentru IPA semnat:

   ```bash
   flutter build ipa --release
   ```

   IPA-ul va fi generat in `build/ios/ipa/`, daca semnarea Apple este configurata.

## Observatii

- Proiectul iOS este configurat cu CocoaPods, deoarece unele pluginuri folosite
  de aplicatie nu au inca suport complet Swift Package Manager.
- Pe acest Mac, suportul Flutter pentru Swift Package Manager a fost dezactivat
  cu:

  ```bash
  flutter config --no-enable-swift-package-manager
  ```

  Daca folosesti alt Mac si vezi build-uri blocate in `Resolve Package Graph`
  sau `ibtool`, ruleaza aceeasi comanda, apoi:

  ```bash
  flutter clean
  flutter pub get
  flutter build ios --debug --no-codesign
  ```

- `ios/Podfile` si `ios/Podfile.lock` trebuie pastrate in proiect.
- Lansarea iOS este programatica prin `ios/Runner/SceneDelegate.swift`, fara
  `Main.storyboard` in build. Launch screen-ul foloseste cheia `UILaunchScreen`
  din `ios/Runner/Info.plist`.
- Daca Xcode cere actualizari de signing/provisioning, lasa Xcode sa le faca
  automat dupa ce alegi `Team`.

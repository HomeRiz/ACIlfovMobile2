# Apa Ilfov Mobile

*(Non-authoritative English translation, for reference only. The Romanian document at `../README.md` in the project root is the primary version.)*

Flutter mobile application for Apa-Canal Ilfov customers. The project generates two native applications from the same source code: Android and iOS.

The application uses a WebView only for authentication with the official `acilfov.emsys.ro` portal. After authentication, the main screens are native Flutter and read data through the real portal session, until an official ACIlfov API exists.

> **Important - read before anything else:** this project is not affiliated with Apa-Canal Ilfov / ACIlfov. It was built independently, out of personal need, and is offered to ACIlfov with no conditions attached. The full terms - legal status, what is offered, future responsibility, and the policy for deleting the code on request - are in **[TRANSPARENCY.md](TRANSPARENCY.md)**. The software license is in **[LICENSE](LICENSE)**.

## Contents

- Project overview
- Screenshots
- Project structure
- Documentation
- Local requirements
- Installation after cloning
- Build and test Android
- Build and test iOS
- How the application was tested (installation on a real device)
- Publishing to Google Play
- Publishing to the App Store
- Security and audit

## Project overview

The application includes:

- authentication through the official ACIlfov/EMSYS portal;
- a native interface for home, invoices, payments, consumption, meter readings, settings, contact, and account information;
- local notifications for meter readings and due invoices, with an automatic check
  (a "watchdog") that reschedules reminders missed by the phone and
  sends ones delayed by battery saving;
- soft decorative backgrounds, one for each page in the menu;
- secure storage for the session cookie;
- structure prepared for the switch to an official token-based API once it becomes available.

The active data source is configured in `lib/core/config/app_config.dart`:

```dart
static const DataSource dataSource = DataSource.cookie;
```

The available values are:

| Value | Role |
| --- | --- |
| `DataSource.mock` | Local test data for development and UI verification. |
| `DataSource.cookie` | Real data through the portal session, the currently active flow. |
| `DataSource.api` | Prepared for the future official ACIlfov API. |

## Screenshots

Screenshots taken on the iOS simulator, in **Review/Demo mode** (generated data - see `AppConfig.reviewDemoEnabled` and press-and-hold on the logo in the login screen), so that the full functionality can be seen without a real ACIlfov account.

| | | |
|---|---|---|
| ![Login](../docs/screenshots/01_login.png) Login (real portal, WebView) | ![Home](../docs/screenshots/02_home_demo.png) Home | ![Menu 1](../docs/screenshots/03_menu_1.png) Menu (1/2) |
| ![Menu 2](../docs/screenshots/03_menu_2.png) Menu (2/2) | ![Invoice history](../docs/screenshots/04_facturi.png) Invoice history | ![Meter reading submission](../docs/screenshots/05_index.png) Meter reading submission |
| ![Consumption history](../docs/screenshots/06_consum.png) Consumption history | ![Chart](../docs/screenshots/07_grafic.png) Chart | ![Account data update](../docs/screenshots/08_actualizare_date.png) Account data update |
| ![Settings 1](../docs/screenshots/09_configurari_1.png) Settings (1/3) | ![Settings 2](../docs/screenshots/09_configurari_2.png) Settings (2/3) | ![Settings 3](../docs/screenshots/09_configurari_3.png) Settings (3/3) |
| ![Password change](../docs/screenshots/10_schimbare_parola.png) Password change | ![Contact](../docs/screenshots/11_contact.png) Contact | ![Account information](../docs/screenshots/12_informatii_cont.png) Account information |
| ![Account deletion](../docs/screenshots/13_stergere_cont.png) Account deletion | ![Info](../docs/screenshots/14_info.png) Info | ![Info - GDPR](../docs/screenshots/15_info_gdpr.png) Info - GDPR compliance (official text + external link) |

## Project structure

Files and folders kept in the root for the application and the build:

```text
android/                 native Android project and Gradle configuration
ios/                     native iOS project, Xcode and CocoaPods
lib/                     the application's Flutter code
assets/                  resources included in the application
test/                    automated Flutter tests
pubspec.yaml             dependencies, version and Flutter assets
pubspec.lock             exact dependency versions for reproducible builds
analysis_options.yaml    static analysis rules
.metadata                Flutter metadata for the project
.gitignore               rules for local files and build artifacts
README.md                the project's main document
docs/                    documentation (architecture, API proposal, screenshots)
AUDIT/                   security reports
```

Main structure inside `lib/`:

```text
lib/
  main.dart                         entry point
  app.dart                          theme and login/app routing
  core/config/app_config.dart       URLs, colors and data source
  core/widgets/page_backdrop.dart   the decorative drawings in the page backgrounds
  data/models/                      data models
  data/repositories/                mock/cookie/api sources
  data/sources/                     HTTP clients for the portal/API
  data/cookie_store.dart            session cookie access and persistence
  data/secure_store.dart            secure storage for a future token
  features/                         application screens
  services/notification_service.dart local notifications + reminder scheduling
  services/notification_watchdog.dart checks and repairs scheduled reminders
  state/                            Provider for auth and account data
```

## Documentation

Security audit reports are in `AUDIT/`:

- `AUDIT/SECURITY_AUDIT.md`
- `AUDIT/MASVS_CHECKLIST.md`
- `AUDIT/THREAT_MODEL.md`
- `AUDIT/PAGES_REAL_API_STATUS.md`

Other project documentation, in `docs/`:

- `docs/ARHITECTURA.md` - how the application is structured and why the transition to the official API is easy.
- `docs/PROPUNERE-TEHNICA-ACILFOV.md` - a technical proposal to ACIlfov for an account API, OAuth 2.0 authentication, and read-only tokens for personal integrations.
- `docs/screenshots/` - the screenshots from the "Screenshots" section above.

**Note:** the repo previously contained a `USERCHECK/` folder with documents set aside for review (including internal working notes, unrelated to how the application functions). It has been reviewed and cleaned up: `ARHITECTURA.md` and `PROPUNERE-TEHNICA-ACILFOV.md` have real value and were moved to `docs/`; the rest (notes on workflow between development tools, a README auto-generated by Xcode with no useful content) was deleted. See `TRANSPARENCY.md` for full context on this project.

## Local requirements

For Android:

- Git;
- Flutter SDK installed and available in `PATH`;
- Android Studio;
- Android SDK, Android Platform Tools, and a configured emulator;
- Java/JDK provided by Android Studio or configured separately.

For iOS:

- macOS;
- Flutter SDK;
- Xcode;
- CocoaPods;
- an Apple Developer account for installation on a real iPhone and publishing.

Environment check:

```bash
flutter doctor -v
```

## Installation after cloning

Clone the repository:

```bash
git clone <URL_REPOSITORY>
cd ACIlfovMobile2
```

Download the dependencies:

```bash
flutter pub get
```

Run the basic checks:

```bash
flutter analyze
flutter test
```

Device testing rule: before installing a new build, uninstall old versions of the application. On Android check for the `ro.acilfov.mobile` package and any old identifier used during testing.

## Build and test Android

### Debug on an Android emulator

Start an emulator from Android Studio or from the terminal:

```bash
flutter emulators
flutter emulators --launch <ID_EMULATOR>
```

Check the devices:

```bash
flutter devices
adb devices
```

Uninstall the old application from the emulator:

```bash
adb -s <DEVICE_ID> shell pm list packages | findstr acilfov
adb -s <DEVICE_ID> uninstall ro.acilfov.mobile
```

Run the application directly:

```bash
flutter run -d <DEVICE_ID>
```

Or build a debug APK for the emulator:

```bash
flutter build apk --debug --target-platform android-x64
adb -s <DEVICE_ID> install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Debug on a real Android phone

Enable `Developer options` and `USB debugging` on the phone, then connect the phone via USB.

```bash
adb devices
adb -s <DEVICE_ID> uninstall ro.acilfov.mobile
flutter build apk --debug --target-platform android-arm,android-arm64
adb -s <DEVICE_ID> install -r build/app/outputs/flutter-apk/app-debug.apk
```

For launching and logs:

```bash
adb -s <DEVICE_ID> shell monkey -p ro.acilfov.mobile 1
adb -s <DEVICE_ID> logcat
```

### Android release for testing on a phone

For a local release build:

```bash
flutter clean
flutter pub get
flutter build apk --release --target-platform android-arm,android-arm64
```

The resulting APK:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Installation on the phone:

```bash
adb -s <DEVICE_ID> uninstall ro.acilfov.mobile
adb -s <DEVICE_ID> install -r build/app/outputs/flutter-apk/app-release.apk
```

For production, the release must be signed with a production keystore/upload key, not with the debug key.

Android signing configuration:

1. Generate or obtain the upload keystore.
2. Put the keystore locally in `android/app/`, for example `android/app/upload-keystore.jks`.
3. Create `android/key.properties` locally, without committing it:

```properties
storePassword=<PAROLA_STORE>
keyPassword=<PAROLA_KEY>
keyAlias=upload
storeFile=upload-keystore.jks
```

4. Build the AAB for Google Play:

```bash
flutter build appbundle --release --target-platform android-arm,android-arm64
```

The resulting file:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Build and test iOS

The iOS build is done on macOS.

### Debug on the iOS simulator

```bash
flutter pub get
flutter devices
flutter run -d <ID_SIMULATOR>
```

Or build without running:

```bash
flutter build ios --debug --simulator
```

### Testing on a real iPhone

1. Connect the iPhone to the Mac.
2. Open the iOS workspace:

```bash
open ios/Runner.xcworkspace
```

3. In Xcode go to `Runner` -> `Signing & Capabilities`.
4. Choose the `Team` from the Apple Developer account.
5. Check the `Bundle Identifier`. For updating the same application, keep the identifier established for the project.
6. Select the connected iPhone and press `Run`.

If the iPhone asks to trust the developer profile, go on the phone to:

```text
Settings -> General -> VPN & Device Management
```

and press `Trust` for the profile used for signing.

iOS release build:

```bash
flutter clean
flutter pub get
flutter build ios --release
```

For an IPA:

```bash
flutter build ipa --release
```

The IPA is generated in:

```text
build/ios/ipa/
```

## How the application was tested (installation on a real device)

This section documents EXACTLY what was used to install and test the application on a real iPhone and Android device, wirelessly, including the problems encountered - so that anyone taking over the project can repeat the same test without reinventing the steps.

### Android, real phone (USB or wireless ADB)

```bash
flutter devices                       # confirms the phone appears
flutter run -d <ID_DEVICE> --debug    # install + run debug
# or, for a release build:
flutter build apk --release           # fails intentionally without android/key.properties (see below)
flutter run -d <ID_DEVICE> --release
```

**Note:** since release signing was hardened (see `android/app/build.gradle.kts`), `assembleRelease`/`bundleRelease` fails intentionally if `android/key.properties` is missing - this is a safeguard, not a bug; without it, a production build could accidentally get signed with the debug key.

### iOS, real iPhone, over the network (wireless, no cable)

```bash
flutter devices                                  # the "wireless devices" section shows the iPhone, if it has previously been connected at least once via cable and "Connect via network" was enabled in Xcode
flutter run -d "<ID_IPHONE_WIRELESS>" --release   # or --debug
```

Real problems encountered and how they were solved, in order:

1. **`pod install` failed** with "requires a higher minimum iOS deployment version" - a plugin (`workmanager_apple`) requires iOS 14+, but the project targets iOS 13.0. Resolved by raising `IPHONEOS_DEPLOYMENT_TARGET` to 14.0 in `ios/Podfile` and `ios/Runner.xcodeproj/project.pbxproj` (real phones run much newer versions anyway, so there is no practical impact).
2. **Installation failed** with "may need to be unlocked to recover from previously reported preparation errors" - the iPhone was locked. Solution: the phone needs to be unlocked (and ideally stay unlocked) while Xcode installs over the network.
3. **The application closed instantly on opening** (release build) - the real cause, found from the phone's crash logs (see below), was that the `BGTaskScheduler` handler for the periodic invoice check was not registered before `didFinishLaunching`, which threw an uncatchable Objective-C exception from Dart. Fixed in `ios/Runner/AppDelegate.swift` via the `WorkmanagerPlugin.registerPeriodicTask(withIdentifier:)` call.

### Checking an application installed on an iPhone, from the terminal (without Xcode open)

Useful for diagnostics, especially when the application seems to close on its own:

```bash
xcrun devicectl list devices                                                         # the device ID (UDID)
xcrun devicectl device info processes --device <UDID> | grep -i runner               # is the Runner process alive?
xcrun devicectl device info files --device <UDID> --domain-type systemCrashLogs      # lists the crash logs on the phone
xcrun devicectl device copy from --device <UDID> --domain-type systemCrashLogs \
  --source "Runner-<data>.ips" --destination /tmp/crash.ips                          # downloads a specific crash log
xcrun devicectl device process launch --device <UDID> ro.acilfov.mobile              # launches the application manually, without opening the phone
```

A crash `.ips` downloaded this way is JSON after the first header line - `asi` (application specific information) and `lastExceptionBacktrace` are usually enough to identify the cause without reproducing the crash in a debugger.

## Publishing to Google Play

Publishing is done from Google Play Console.

1. Increment the version in `pubspec.yaml`, for example:

```yaml
version: 2.0.1+2
```

2. Run the checks:

```bash
flutter analyze
flutter test
```

3. Configure release signing in `android/key.properties`.
4. Generate the AAB:

```bash
flutter build appbundle --release --target-platform android-arm,android-arm64
```

5. Go to [Google Play Console](https://play.google.com/console).
6. Create the application or select the existing application.
7. Fill in the `Store listing`, screenshots, icon, description, category, and contact details.
8. Fill in `App content`: Data safety, privacy policy, target audience, ads, content rating.
9. Go to `Release` -> `Testing` for internal or closed testing.
10. Upload the `app-release.aab` file.
11. Check the Play Console report and publish first to internal testing.
12. After validation, promote the release to production.

## Publishing to the App Store

Publishing is done from Apple Developer and App Store Connect.

1. Increment the version in `pubspec.yaml`.
2. In Apple Developer create/verify the `Identifier` for the application's bundle id.
3. In Xcode, under `Runner` -> `Signing & Capabilities`, set the `Team` and automatic or manual signing.
4. Generate the release build:

```bash
flutter build ipa --release
```

Or use Xcode:

```text
Xcode -> Product -> Archive
```

5. In Xcode Organizer press `Distribute App` and send the build to App Store Connect.
6. Go to [App Store Connect](https://appstoreconnect.apple.com/).
7. Create the application or select the existing application.
8. Fill in the metadata: name, subtitle, description, keywords, screenshots, category, support, and privacy policy.
9. Fill in `App Privacy`.
10. Publish first to TestFlight.
11. After testing, submit the build to App Review for publishing.

## Security and audit

The application has been audited locally on code, Android/iOS configurations, and dependencies. The reports are in `AUDIT/`:

- `SECURITY_AUDIT.md` - the complete audit report;
- `MASVS_CHECKLIST.md` - OWASP MASVS checklist;
- `THREAT_MODEL.md` - the threat model;
- `PAGES_REAL_API_STATUS.md` - the status of pages connected to real data.

Audit summary:

- no critical or high vulnerabilities were found in the current code;
- the session is stored in secure storage;
- Android has backup disabled and cleartext blocked;
- the login WebView has a domain allowlist;
- production recommendations remain for release signing, TLS pinning, forced update, iOS app switcher protection, and versioning `pubspec.lock`.

## Operational notes

- Before testing on an emulator or a real phone, uninstall old applications with the same package or with packages used previously.
- For the Android emulator, x86/x64 ABIs are used.
- For real Android phones, ARM ABIs are used: `android-arm` and `android-arm64`.
- `android/key.properties`, keystores, certificates, and `.env` files are not committed to git.
- `pubspec.lock` must be kept and committed for reproducible builds.

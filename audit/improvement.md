# Improvements (from MASVS_CHECKLIST.md)

- **MASVS-STORAGE**
  - PARTIAL: iOS uses `KeychainAccessibility.first_unlock_this_device`; for sensitive sessions, evaluate using `unlocked_this_device`.
  - PARTIAL: Android has `FLAG_SECURE`; iOS does not yet have a privacy overlay for the app switcher/snapshot.

- **MASVS-CRYPTO**
  - PARTIAL: There is no certificate/public-key pinning for the main host.

- **MASVS-AUTH**
  - PARTIAL: Sensitive operations use the portal session, but there is no additional local step-up authentication.
  - PARTIAL: There is no forced update or controlled server-side invalidation from the app for older versions.

- **MASVS-NETWORK**
  - PARTIAL: No TLS pinning exists.
  - PARTIAL: The application uses internal EMSYS REST endpoints with a session cookie; it is functional but not a stable public/official API.

- **MASVS-PLATFORM**
  - PARTIAL: The MethodChannel for the cookie should defensively validate the exact host in native code as well.
  - PARTIAL: iOS `clearCookies` deletes all cookies in `WKWebsiteDataStore`, not just the ACIlfov domain.
  - PARTIAL: The WebView has an allowlist for the main-frame, but explicit hardening for mixed content/file access is not documented/configured in the code.

- **MASVS-CODE**
  - PARTIAL: `pubspec.lock` exists locally but is ignored and not tracked in git; it must be committed for the application.
  - PARTIAL: `flutter pub outdated` shows newer major dependencies and the transitive `js` package is discontinued, although no active advisories appear in the current output.
  - PARTIAL: Release signing falls back to the debug key if `android/key.properties` is missing; production release builds must fail if the keystore is missing.

- **MASVS-PRIVACY**
  - PARTIAL: Local notifications can display the invoice number and due date; the content is useful but should be kept minimal and validated against privacy requirements.
  - PARTIAL: Raw errors can display internal URLs in some SnackBars; UI messages should be centralized and sanitized.

- **MASVS-RESILIENCE**
  - PARTIAL: There is no root/jailbreak detection, anti-tamper, anti-debug, or runtime integrity checking. Acceptable for the current stage, but not for a high-risk model.
  - PARTIAL: I did not find explicit obfuscation/split-debug-info configured for release.

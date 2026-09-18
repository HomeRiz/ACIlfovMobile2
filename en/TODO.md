# Store Readiness — App Store & Google Play

*(Non-authoritative English original of this document, kept for reference. The
Romanian translation at `../TODO.md` in the project root is the primary
version.)*

Researched 2026-09-18 against official Apple/Google documentation (sources cited per item).
Cross-checked with two independent research passes (a Claude subagent and Google's `agy`/Gemini
CLI) — both converged on nearly everything below; the one place they usefully disagreed
(`SCHEDULE_EXACT_ALARM`) is called out explicitly.
App: **Apa Ilfov** (`ro.acilfov.mobile`) — login-gated Flutter client for the ACIlfov/EMSYS water
portal. Login is first-party only (username/password on the real portal page inside a WebView) —
**no Sign in with Google/Apple, no self-registration in-app**. No ads, no analytics/tracking SDKs.

Status legend: ✅ OK (already satisfied) · ⚠️ MISSING (blocks submission) · ℹ️ JUDGMENT CALL (needs a decision, not just code)

---

## 1. Apple App Store

| # | Requirement | Status | Notes |
|---|---|---|---|
| 1 | **Account deletion** (Guideline 5.1.1(v)) — in-app deletion of the real account, not just deactivation | ✅ OK | `lib/features/account_info/delete_account_view.dart` already sends a real delete request to the portal account. Matches Apple's requirement as written. Just confirm the entry point is easy to find in the menu (Apple checks this manually). |
| 2 | **Sign in with Apple** (Guideline 4.8) | ✅ OK — exempt | Only triggers if the app offers third-party/social login (Google, Facebook, etc.) as an option. Apa Ilfov exclusively uses the utility's own account system → falls under Apple's explicit exemption. Nothing to build. |
| 3 | **Demo/reviewer account** for App Review | ⚠️ MISSING — action owned by ACIlfov | App requires login and has no self-registration, so a **real, non-expiring demo account username/password** must be entered in App Store Connect → App Review Information → Sign-In Information. **Decision (2026-09-18): ACIlfov/EMSYS is responsible for provisioning this** — a single dummy customer record in their existing production system (not a separate sandbox), reused for every future re-review. We deliberately chose **not** to build an in-app fallback "demo mode" (fake native login bypassing the real portal) to avoid the ongoing cost of keeping it feature-identical to the real app. If ACIlfov ultimately refuses, revisit: Apple allows an in-app demo mode as a fallback with prior approval — the codebase already has the pieces for it (`AppConfig.dataSource` switch + the existing unused `MockACIRepository`), so it's a contained addition if it ever becomes necessary. |
| 4 | **App Privacy "nutrition label"** in App Store Connect | ⚠️ MISSING (needs to be filled in, not code) | Declare: Contact Info (name/address), Identifiers (account ID), Financial Info (balance, invoices/payments). Everything is tied to the authenticated user → declare as **"linked to you"**, not "not linked" (no anonymization step exists in the app). |
| 5 | **Hosted privacy policy URL** | ⚠️ MISSING | Must be a real, publicly reachable web page (no login required), separate from the in-app "Politica de cookie" screen (`lib/features/info/info_view.dart`), which does **not** satisfy this on its own. Needs to be published somewhere under ACIlfov's or HomeRiz's own domain before submission. |
| 6 | **Apple Developer Program enrollment** | ⚠️ MISSING | $99/year. Currently only a free personal-team signing identity exists. Decide **Individual vs Organization**: Organization requires a D-U-N-S number for the legal entity (lead time — can take weeks if one doesn't already exist) and can't use a DBA/trade name. If publishing as HomeRiz/on behalf of ACIlfov, this decision should be made early because of the D-U-N-S lead time. |

**Source:** developer.apple.com/app-store/review/guidelines/ · developer.apple.com/support/offering-account-deletion-in-your-app/ · developer.apple.com/help/app-store-connect/reference/app-review-information/ · support.apple.com/en-us/102399 · developer.apple.com/help/app-store-connect/reference/app-privacy/ · developer.apple.com/programs/enroll/

---

## 2. Google Play

| # | Requirement | Status | Notes |
|---|---|---|---|
| 1 | **Play Console developer account** | ⚠️ MISSING | $25 one-time fee. Same Individual vs Organization decision as Apple — Organization needs a D-U-N-S number (up to ~30 days to obtain if you don't have one). |
| 2 | **New-account closed-testing gate** (12 testers / 14 days before production access) | ℹ️ JUDGMENT CALL | Current rule (reduced from 20→12 testers, Dec 2024): applies only to **personal** developer accounts created after 2023-11-13. **Organization accounts are exempt.** → registering as an Organization skips this gate entirely and goes straight to standard review. This is a strong argument for the Organization path on both stores. |
| 3 | **Data Safety section** | ⚠️ MISSING (form, not code) | Declare Personal info (name/address/account ID) and Financial info (balance, invoice/payment history). A hosted privacy policy URL is **required to even complete this form** — same gap as Apple, item 1.5. |
| 4 | **`SCHEDULE_EXACT_ALARM` permission declaration** | ⚠️ ACTION RECOMMENDED | Android 12+ restricted permission — already declared in the manifest (`android/app/src/main/AndroidManifest.xml`) for invoice/index reminders. **Cross-checked by both research passes**: Google's Exact Alarms Declaration policy explicitly limits the accepted justification categories to *alarm-clock/timer apps* and *calendar apps with event reminders* — a bill/meter-reading reminder does **not** fit either category. Recommendation (converged from both passes): **drop `SCHEDULE_EXACT_ALARM`** and reschedule invoice/index reminders through the existing WorkManager-based periodic check (already used for the background invoice poll) or `AlarmManager`'s inexact scheduling instead, to avoid a likely Play Console rejection on the declaration form. |
| 5 | **Demo/reviewer sign-in details** | ⚠️ MISSING — action owned by ACIlfov | Same as Apple: Play Console → App content → "Sign-in details" needs a persistent, always-valid test account (must work regardless of location, must bypass any 2FA/OTP, instructions in English even though the app is Romanian). Google's docs don't describe a demo-mode fallback the way Apple does — a real account is required either way. Same account provisioned by ACIlfov/EMSYS for Apple (item 3 above) covers this too. |
| 6 | **Target API level** | ✅ OK | Android apps must target API 36 (Android 16) as of **2026-08-31** — that deadline has already passed (today is 2026-09-18). App already resolves `targetSdk`/`compileSdk` to 36 → compliant now, no action needed. |

**Source:** support.google.com/googleplay/android-developer/answer/13634885 · .../answer/13628312 · .../answer/14151465 · .../answer/10787469 · .../answer/10144311 · .../answer/9888170 · .../answer/15748846 · .../answer/9859455 · .../answer/11926878 · developer.android.com/google/play/requirements/target-sdk

---

## 3. GDPR / EU data protection

| Question | Answer |
|---|---|
| Does either store mandate a separate "GDPR consent flow"? | **No.** Both stores require a hosted privacy policy + their own disclosure mechanism (App Privacy details / Data Safety section) — that's a transparency layer, not a GDPR compliance certification. Actual GDPR compliance (lawful basis, data subject rights, DPA with the portal operator, etc.) is **the developer's own legal responsibility**, not something either store's review process enforces beyond requiring the policy to exist. |
| Does either store require a cookie-consent banner for the functional session cookie? | **No store policy found requiring this.** Google's "EU User Consent Policy" only applies to Google's own ad/measurement products (Ads, AdSense, Analytics) — not applicable, since this app has none. No equivalent Apple rule found. (Whether Romanian/EU ePrivacy law itself requires anything for a strictly-necessary session cookie is a separate legal question outside app-store policy — likely exempt as "strictly necessary," but that's not something either store's review checks.) |

**Source:** developer.apple.com/help/app-store-connect/reference/compliance-review/ · google.com/about/company/user-consent-policy/

---

## 4. Blocking gaps — summary (do these before submitting anywhere)

1. **Hosted privacy policy page** — publish a real URL; the in-app cookie-policy screen isn't enough for either store.
2. **Apple Developer Program enrollment** ($99/yr) — decide Individual vs Organization now (D-U-N-S lead time if Organization).
3. **Play Console developer account** ($25) — same Individual vs Organization decision; Organization also skips the 12-tester/14-day gate.
4. **Production release signing keystore** — `android/key.properties` doesn't exist yet; release Gradle builds now hard-fail without it (see `android/app/build.gradle.kts`). iOS needs a paid-account Distribution certificate once enrolled.
5. **One persistent reviewer test account** — **owned by ACIlfov/EMSYS, not us.** Decision made 2026-09-18: we're not building an in-app demo-mode fallback; ACIlfov provisions one dummy customer record in their existing production system, supplied to both App Store Connect and Play Console. **Follow up with them and don't let this slip** — it's the single biggest schedule risk in this whole list since it's the one item outside our control. **Once they provide it, do not let it be deactivated after initial approval**: Apple's own docs state the demo account "must not expire," and every subsequent app update triggers a fresh review that can re-test the same login — an expired/removed reviewer account is one of the most common real-world rejection reasons on updates. It must stay active for the life of the app on both stores.
6. **App Privacy details (Apple) + Data Safety section (Google)** — fill in as "linked to you" for Personal + Financial info categories.
7. **`SCHEDULE_EXACT_ALARM` (Play)** — both research passes converged: drop it and use inexact/WorkManager-based scheduling for reminders instead, before submitting the declaration form (see §2 item 4).

## 5. Already fine, no action needed

- Account deletion flow (Apple 5.1.1(v)).
- Sign in with Apple exemption (Apple 4.8) — no social login exists.
- Android target/compile SDK 36 — already meets the 2026-08-31 deadline.
- No ads/tracking SDKs — simplifies both privacy declarations and avoids Google's ad-consent policy entirely.

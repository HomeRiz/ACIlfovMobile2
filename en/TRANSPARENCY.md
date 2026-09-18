# Transparency statement

(Non-authoritative English translation, for reference only. The Romanian
text at `../TRANSPARENCY.md` in the project root is the sole authoritative
version of this document.)

This document exists so that anyone reading this repository — Apa-Canal Ilfov
(ACIlfov), its staff, its legal counsel, or anyone else — understands exactly
what this project is, who made it, and under what terms it's being made
available. It is written in plain language on purpose. It is not a substitute
for legal advice; see the note at the bottom.

## What this project is

This app ("Apa Ilfov" / `ro.acilfov.mobile`) is an unofficial, independently
built mobile client for the ACIlfov customer web portal
(`acilfov.emsys.ro`). It was built by a single developer, under the name
**HomeRiz**, out of personal need — to have a usable mobile app for a service
that only offered a desktop-oriented web portal.

## No affiliation

**HomeRiz is not affiliated, associated, authorized, endorsed by, or in any
way officially connected with Apa-Canal Ilfov, ACIlfov, or any entity
representing them**, or with any of their subsidiaries or affiliates. The
official ACIlfov website is at [acilfov.ro](https://acilfov.ro/), and the
official customer portal is at
[acilfov.emsys.ro](https://acilfov.emsys.ro/self_utilities/). This app
reaches that same portal exactly the way a browser would (see the in-app
"Info" section for the mechanism, and `AUDIT/` in this repository for the
security review of that mechanism).

This project was built and published entirely on HomeRiz's own initiative,
without being asked to by ACIlfov, and without any prior arrangement.

## What is being offered, and on what terms

HomeRiz is offering this entire codebase and its documentation to ACIlfov,
**exclusively and with no other condition**. The exact legal terms are in
`LICENSE` (the authoritative version) — in short:

- Only ACIlfov has the right to use, copy, modify, distribute, or
  relicense this code.
- **No other party — including HomeRiz itself** — may use, copy, or
  redistribute this code, in whole or in part, without ACIlfov's express
  written permission, granted after the transfer.
- Once in ACIlfov's possession, ACIlfov may apply any license of its own
  choosing to its copy, including a closed/proprietary one, and may modify
  the code in any way it wants.
- No attribution, credit, or mention of HomeRiz is requested or required,
  anywhere — not in the app, not in the code, not in any documentation
  ACIlfov produces going forward. None has been added to this repository,
  by design.

## Ongoing assistance — not an obligation

HomeRiz may, at its own discretion, help ACIlfov implement further features
or fix bugs in this codebase at no cost. **This is not a commitment or a
service agreement.** Any such assistance may be declined, limited, or ended
by HomeRiz at any time, for any reason, with no notice period required.

If and when HomeRiz stops assisting with this project, full responsibility
for its future development, updates, and maintenance — on both the Android
and iOS builds — passes entirely to ACIlfov. HomeRiz bears no responsibility
for the project's development, correctness, security, or legal compliance
from that point forward, or at any point after the code has left HomeRiz's
possession.

**Practical note for whoever maintains this next:** this is one Flutter/Dart
codebase (everything under `lib/`), but it is not purely cross-platform —
there is real platform-specific native code that has to be maintained on
both sides independently:

- `ios/Runner/AppDelegate.swift`, `ios/Runner/SceneDelegate.swift` (Swift) —
  the native cookie bridge, the iOS app-switcher privacy overlay, and the
  background-task (`BGTaskScheduler`) registration required for the periodic
  invoice check to work at all on iOS.
- `android/app/src/main/kotlin/ro/acilfov/mobile/MainActivity.kt` (Kotlin) —
  the equivalent native cookie bridge and the `FLAG_SECURE` screenshot
  protection.

A change to how login sessions, notifications, or background checks work
generally needs a matching change on both sides, not just in `lib/`.

## Withdrawal and deletion

If ACIlfov decides not to proceed with this project, **HomeRiz commits to
permanently deleting this entire codebase and its associated documentation
within 24 hours of receiving a written request by email asking for exactly
that.**

This is a stated policy that a person carries out manually upon request — it
is not, and will not be, an automated system watching an inbox. If you send
that request, expect a human response confirming the deletion, not an
automatic action.

## Liability

This software is provided under an exclusive-use license (`LICENSE` in this
repository), which includes a standard "AS IS" warranty disclaimer and
limitation of liability. HomeRiz assumes no responsibility for how this code
is used, modified, deployed, or relied upon by anyone, including ACIlfov,
before or after this handover.

## A note on this document itself

This document was written to be clear and honest, not to be a tested legal
instrument. HomeRiz is not a lawyer. If this statement's legal effect ever
matters — a dispute, a formal handover, anything with real stakes — it
should be reviewed by an actual lawyer before either side relies on it.

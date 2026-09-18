# Pregatire pentru publicare — App Store si Google Play

*(O traducere in engleza a acestui document, doar pentru referinta, este
disponibila la `en/TODO.md` — textul romanesc de mai jos este versiunea
principala.)*

Cercetat pe 2026-09-18, pe baza documentatiei oficiale Apple/Google (surse citate la fiecare punct).
Verificat incrucisat prin doua cercetari independente (un subagent Claude si `agy`/Gemini CLI de la
Google) — ambele au ajuns la aceleasi concluzii pentru aproape tot ce urmeaza; singurul loc unde au
divergat util (`SCHEDULE_EXACT_ALARM`) este mentionat explicit.

Aplicatie: **Apa Ilfov** (`ro.acilfov.mobile`) — client Flutter cu login obligatoriu pentru portalul
ACIlfov/EMSYS. Login-ul este exclusiv de tip "prima parte" (username/parola pe pagina reala a
portalului, in interiorul unui WebView) — **fara Sign in with Google/Apple, fara auto-inregistrare
in aplicatie**. Fara reclame, fara SDK-uri de analytics/tracking.

Legenda status: ✅ OK (deja indeplinit) · ⚠️ LIPSEȘTE (blocheaza trimiterea) · ℹ️ DECIZIE NECESARA (are nevoie de o decizie, nu doar de cod)

---

## 1. Apple App Store

| # | Cerinta | Status | Note |
|---|---|---|---|
| 1 | **Stergerea contului** (Guideline 5.1.1(v)) — stergere reala a contului din aplicatie, nu doar dezactivare | ✅ OK | `lib/features/account_info/delete_account_view.dart` trimite deja o cerere reala de stergere catre contul din portal. Se potriveste exact cu cerinta Apple. Ramane doar de confirmat ca punctul de acces e usor de gasit in meniu (Apple verifica manual acest lucru). |
| 2 | **Sign in with Apple** (Guideline 4.8) | ✅ OK — scutit | Se aplica doar daca aplicatia ofera login social/tert (Google, Facebook etc.) ca optiune. Apa Ilfov foloseste exclusiv sistemul de cont al furnizorului de utilitati → se incadreaza in scutirea explicita a Apple. Nimic de construit. |
| 3 | **Cont demo/reviewer** pentru App Review | ⚠️ LIPSEȘTE — actiune in sarcina ACIlfov | Aplicatia cere login si nu are auto-inregistrare, deci un **cont demo real, cu username/parola care nu expira**, trebuie introdus in App Store Connect → App Review Information → Sign-In Information. **Decizie (2026-09-18): ACIlfov/EMSYS este responsabil sa furnizeze acest cont** — o singura inregistrare de client fictiv in sistemul lor de productie existent (nu un mediu de test separat), refolosita la fiecare re-verificare viitoare. Am ales in mod deliberat **sa nu** construim un "mod demo" de rezerva in aplicatie (login nativ fals care ocoleste portalul real), ca sa evitam costul continuu de a-l tine identic ca functionalitate cu aplicatia reala. Daca ACIlfov refuza in cele din urma, revizuim: Apple permite un mod demo in aplicatie ca solutie de rezerva, cu aprobare prealabila — codul are deja piesele necesare pentru asta (comutatorul `AppConfig.dataSource` + `MockACIRepository`, deja existent dar nefolosit), deci ar fi o adaugare limitata daca devine vreodata necesara. |
| 4 | **"Eticheta de confidentialitate" (App Privacy)** in App Store Connect | ⚠️ LIPSEȘTE (trebuie completata, nu e cod) | De declarat: Date de contact (nume/adresa), Identificatori (ID cont), Informatii financiare (sold, facturi/plati). Totul este legat de utilizatorul autentificat → se declara ca **"legate de tine"**, nu "nelegate" (nu exista niciun pas de anonimizare in aplicatie). |
| 5 | **URL de politica de confidentialitate gazduit public** | ⚠️ LIPSEȘTE | Trebuie sa fie o pagina web reala, accesibila public (fara login), separata de ecranul din aplicatie "Politica de cookie" (`lib/features/info/info_view.dart`), care **nu** satisface singura aceasta cerinta. Trebuie publicata undeva pe domeniul ACIlfov sau HomeRiz inainte de trimitere. |
| 6 | **Inscriere in Apple Developer Program** | ⚠️ LIPSEȘTE | 99$/an. In prezent exista doar o identitate de semnare personala, gratuita. De decis **Individual vs Organizatie**: Organizatie cere un numar D-U-N-S pentru entitatea juridica (poate dura saptamani daca nu exista deja unul) si nu poate folosi un nume comercial (DBA). Daca publicarea se face sub HomeRiz/in numele ACIlfov, aceasta decizie ar trebui luata devreme, din cauza timpului necesar pentru D-U-N-S. |

**Surse:** developer.apple.com/app-store/review/guidelines/ · developer.apple.com/support/offering-account-deletion-in-your-app/ · developer.apple.com/help/app-store-connect/reference/app-review-information/ · support.apple.com/en-us/102399 · developer.apple.com/help/app-store-connect/reference/app-privacy/ · developer.apple.com/programs/enroll/

---

## 2. Google Play

| # | Cerinta | Status | Note |
|---|---|---|---|
| 1 | **Cont de dezvoltator Play Console** | ⚠️ LIPSEȘTE | Taxa unica de 25$. Aceeasi decizie Individual vs Organizatie ca la Apple — Organizatie are nevoie de un numar D-U-N-S (pana la ~30 de zile daca nu exista deja unul). |
| 2 | **Pragul de testare inchisa pentru conturi noi** (12 testeri / 14 zile inainte de acces la productie) | ℹ️ DECIZIE NECESARA | Regula actuala (redusa de la 20 la 12 testeri, dec. 2024): se aplica doar conturilor de dezvoltator **personale**, create dupa 2023-11-13. **Conturile de Organizatie sunt scutite.** → inregistrarea ca Organizatie sare complet peste acest prag si merge direct la verificarea standard. Acesta e un argument puternic pentru varianta Organizatie, pe ambele platforme. |
| 3 | **Sectiunea Data Safety** | ⚠️ LIPSEȘTE (formular, nu cod) | De declarat: Informatii personale (nume/adresa/ID cont) si Informatii financiare (sold, istoric facturi/plati). Un URL de politica de confidentialitate gazduit public este **obligatoriu chiar si pentru a completa acest formular** — acelasi gol ca la Apple, punctul 1.5. |
| 4 | **Declaratia pentru permisiunea `SCHEDULE_EXACT_ALARM`** | ⚠️ ACTIUNE RECOMANDATA | Permisiune restrictionata pe Android 12+ — deja declarata in manifest (`android/app/src/main/AndroidManifest.xml`) pentru remindere de facturi/index. **Verificat incrucisat de ambele cercetari**: politica Google pentru declararea alarmelor exacte limiteaza explicit categoriile de justificare acceptate la *aplicatii de tip ceas cu alarma/cronometru* si *aplicatii de calendar cu remindere de evenimente* — un reminder de factura/index **nu** se incadreaza in niciuna dintre ele. Recomandare (convergenta din ambele cercetari): **eliminati `SCHEDULE_EXACT_ALARM`** si reprogramati reminderele de facturi/index prin verificarea periodica bazata pe WorkManager (deja folosita pentru verificarea facturilor din fundal) sau prin programarea inexacta a `AlarmManager`, ca sa evitati o respingere probabila in Play Console la formularul de declaratie. |
| 5 | **Detalii de autentificare demo/reviewer** | ⚠️ LIPSEȘTE — actiune in sarcina ACIlfov | La fel ca la Apple: Play Console → App content → "Sign-in details" are nevoie de un cont de test permanent, mereu valid (trebuie sa functioneze indiferent de locatie, trebuie sa ocoleasca orice 2FA/OTP, instructiuni in engleza chiar daca aplicatia e in romana). Documentatia Google nu descrie o solutie de tip "mod demo" asa cum face Apple — e nevoie de un cont real oricum. Acelasi cont furnizat de ACIlfov/EMSYS pentru Apple (punctul 3 de mai sus) acopera si acest caz. |
| 6 | **Nivelul de API tinta** | ✅ OK | Aplicatiile Android trebuie sa tinteasca API 36 (Android 16) incepand cu **31.08.2026** — termenul a trecut deja (azi e 18.09.2026). Aplicatia tinteste deja `targetSdk`/`compileSdk` 36 → conforma acum, nicio actiune necesara. |

**Surse:** support.google.com/googleplay/android-developer/answer/13634885 · .../answer/13628312 · .../answer/14151465 · .../answer/10787469 · .../answer/10144311 · .../answer/9888170 · .../answer/15748846 · .../answer/9859455 · .../answer/11926878 · developer.android.com/google/play/requirements/target-sdk

---

## 3. GDPR / protectia datelor in UE

| Intrebare | Raspuns |
|---|---|
| Vreuna dintre platforme cere un flux separat de "consimtamant GDPR"? | **Nu.** Ambele platforme cer o politica de confidentialitate gazduita public + propriul lor mecanism de declarare (App Privacy details / Data Safety section) — acesta e un nivel de transparenta, nu o certificare de conformitate GDPR. Conformitatea GDPR reala (temei legal, drepturile persoanelor vizate, acord de procesare a datelor cu operatorul portalului etc.) este **raspunderea legala proprie a dezvoltatorului**, nu ceva ce procesul de verificare al platformelor impune dincolo de a cere ca politica sa existe. |
| Vreuna dintre platforme cere un banner de consimtamant pentru cookie-uri, pentru cookie-ul functional de sesiune? | **Nicio politica de platforma gasita care sa ceara asta.** "Politica de Consimtamant UE" a Google se aplica doar produselor proprii de reclame/masurare ale Google (Ads, AdSense, Analytics) — nu se aplica, pentru ca aplicatia nu are niciunul dintre ele. Nu am gasit nicio regula echivalenta la Apple. (Daca legea romana/UE de e-Privacy cere ceva pentru un cookie de sesiune strict necesar este o intrebare juridica separata, in afara politicii magazinelor de aplicatii — probabil scutit ca fiind "strict necesar", dar asta nu e ceva ce verifica recenzia vreunei platforme.) |

**Surse:** developer.apple.com/help/app-store-connect/reference/compliance-review/ · google.com/about/company/user-consent-policy/

---

## 4. Goluri blocante — rezumat (de facut inainte de trimitere, oriunde)

1. **Pagina de politica de confidentialitate gazduita public** — publicati un URL real; ecranul din aplicatie cu politica de cookie nu e suficient pentru nicio platforma.
2. **Inscrierea in Apple Developer Program** (99$/an) — decideti acum Individual vs Organizatie (timp de asteptare pentru D-U-N-S daca e Organizatie).
3. **Cont de dezvoltator Play Console** (25$) — aceeasi decizie Individual vs Organizatie; Organizatia sare si peste pragul de 12 testeri/14 zile.
4. **Keystore de semnare pentru release-ul de productie** — `android/key.properties` inca nu exista; build-urile Gradle de release esueaza acum intentionat fara el (vezi `android/app/build.gradle.kts`). iOS are nevoie de un certificat de Distribution de la un cont platit, odata inscris.
5. **Un cont de test persistent pentru reviewer** — **in sarcina ACIlfov/EMSYS, nu a noastra.** Decizie luata pe 2026-09-18: nu construim un mod demo de rezerva in aplicatie; ACIlfov furnizeaza o inregistrare de client fictiv in sistemul lor de productie existent, oferita atat la App Store Connect, cat si la Play Console. **Urmariti acest subiect cu ei si nu il lasati sa treaca neobservat** — este cel mai mare risc de intarziere din toata aceasta lista, fiind singurul punct in afara controlului nostru. **Odata furnizat, nu lasati contul sa fie dezactivat dupa aprobarea initiala**: documentatia Apple spune explicit ca acest cont demo "nu trebuie sa expire", iar fiecare actualizare ulterioara a aplicatiei declanseaza o noua verificare care poate re-testa acelasi login — un cont de reviewer expirat sau eliminat este unul dintre cele mai frecvente motive reale de respingere la actualizari. Trebuie sa ramana activ pe toata durata de viata a aplicatiei, pe ambele platforme.
6. **App Privacy details (Apple) + Data Safety section (Google)** — completati ca "legate de tine" pentru categoriile de informatii personale si financiare.
7. **`SCHEDULE_EXACT_ALARM` (Play)** — ambele cercetari converg: eliminati-l si folositi in schimb programare inexacta/bazata pe WorkManager pentru remindere, inainte de a trimite formularul de declaratie (vezi §2, punctul 4).

## 5. Deja in regula, nicio actiune necesara

- Fluxul de stergere a contului (Apple 5.1.1(v)).
- Scutirea de Sign in with Apple (Apple 4.8) — nu exista login social.
- Android target/compile SDK 36 — indeplineste deja termenul din 31.08.2026.
- Fara SDK-uri de reclame/tracking — simplifica ambele declaratii de confidentialitate si evita complet politica de consimtamant pentru reclame a Google.

# Arhitectura aplicatiei ACIlfov Mobile v2

Acest document explica **cum e gandita** aplicatia si, mai ales, **de ce
tranzitia la API-ul oficial va fi usoara**.

---

## Ideea centrala: straturi separate

Aplicatia e impartita pe straturi. Fiecare strat stie doar de vecinul lui, nu
de tot. Asta inseamna ca poti schimba un strat fara sa le strici pe celelalte.

```
   ECRANE (features/)                 ce vede si atinge userul
        |  cer date prin "starea" aplicatiei
   STARE (state/ - Provider)          tine datele si anunta ecranele
        |  cere date prin "contract"
   REPOSITORY (contract)              NU stie de unde vin datele
        |  implementat de una din:
   +----+-----------------+-----------------+
   | MOCK (test)   | COOKIE (portal)  | API (viitor)   |
   +---------------+------------------+----------------+
        |                 |                  |
     date fixe      sesiune login        token OAuth
```

**Punctul-cheie:** ecranele vorbesc doar cu "contractul" (`ACIRepository`).
Nu le pasa daca datele vin din date de test, din portal (cookie) sau din API.
De aceea, cand apare API-ul, **schimbi doar sursa** si ecranele raman neatinse.

---

## Comutatorul de sursa

In `lib/core/config/app_config.dart`:

```dart
enum DataSource { mock, cookie, api }

static const DataSource dataSource = DataSource.mock;  // <-- singura schimbare
```

`lib/data/repositories/repository_factory.dart` citeste aceasta valoare si
livreaza automat implementarea potrivita:

```dart
switch (AppConfig.dataSource) {
  case DataSource.mock:   return MockACIRepository();
  case DataSource.cookie: return CookieACIRepository();
  case DataSource.api:    return ApiACIRepository();
}
```

### Traseul catre API (pas cu pas, pentru viitor)

1. ACIlfov publica API-ul si documentatia (endpoint-uri).
2. In `api_aci_repository.dart` completezi caile reale (marcate `TODO`).
3. In `app_config.dart` pui `DataSource.api`.
4. Gata. Ecranele, meniul, notificarile - toate raman la fel.

---

## Cele trei surse, pe scurt

### 1. Mock (`mock_aci_repository.dart`)
Date fixe de test. Pentru dezvoltare si pentru a vedea interfata fara login.

### 2. Cookie (`cookie_aci_repository.dart`)
Solutia de **acum**, pana exista API. Dupa ce te loghezi in WebView, sesiunea
(cookie-ul) e salvata. `PortalClient` trimite acel cookie catre portal si aduce
paginile/datele ca si cum ai fi tu logat in browser.

Pentru a o activa, trebuie inspectat portalul o data (Developer Tools -> Network)
ca sa afli ce adrese intorc datele si sa completezi metodele. **Atentie:** e
fragila - se poate strica daca ACIlfov schimba site-ul. De aceea API-ul ramane
tinta finala.

### 3. API (`api_aci_repository.dart`)
Viitorul. Foloseste `ApiClient`, care ataseaza tokenul (din seiful criptat) la
fiecare cerere. Structura e gata; se completeaza caile cand exista documentatia.

---

## Autentificarea

- **Acum:** login prin WebView. Cand pagina ajunge in zona autentificata
  (`/oui/cl/`), `AuthProvider.markLoggedIn()` trece aplicatia la ecranele native.
  Sesiunea e pastrata criptat (`CookieStore`), la fel ca in v1.
- **Viitor (OAuth):** dupa login, portalul emite un **token** legat de contul
  userului. Tokenul se pastreaza in `SecureStore` (seif criptat) si se ataseaza
  automat la cererile API. Vizibil pentru user e doar login-ul, o data.

---

## Notificari

`NotificationService` (peste `flutter_local_notifications`) programeaza:
- o reamintire cand incepe perioada de transmitere a indexului;
- o reamintire cu 3 zile inainte de scadenta fiecarei facturi neplatite.

Acestea sunt **locale** (fara server). Pentru **push instant** (ex: factura noua
aparuta chiar cu aplicatia inchisa) exista doua drumuri:

1. **Webhook ACIlfov -> mini-server -> FCM -> telefon** (push adevarat, dar cere
   un server propriu).
2. **Home Assistant** cu token read-only: HA face polling la API-ul ACIlfov si
   trimite notificarea prin aplicatia lui. Cel mai simplu pentru useri tehnici,
   fara server propriu.

Ambele depind de API-ul ACIlfov. Vezi `PROPUNERE-TEHNICA-ACILFOV.md`.

---

## De ce e usoara tranzitia pentru ACIlfov (rezumat)

- Ecranele nu se rescriu - doar sursa de date se schimba.
- Un singur comutator (`AppConfig.dataSource`) trece toata aplicatia pe API.
- Modelele de date (`Account`, `Invoice`, `MeterIndex`) au deja `fromJson`, deci
  se "umplu" direct din raspunsul API.
- Autentificarea prin WebView se pastreaza ca pas OAuth - nimic exotic.

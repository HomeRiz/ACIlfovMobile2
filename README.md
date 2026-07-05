# ACIlfov Mobile v2

Aplicatie mobila nativa pentru portalul **Apa Canal Ilfov** (`acilfov.emsys.ro`).

Fata de v1 (care era doar un WebView peste portal), v2 foloseste WebView-ul
**doar pentru autentificare**, iar restul aplicatiei este construit nativ:
interfata proprie, meniu hamburger, notificari locale si o structura pregatita
sa treaca usor pe un API oficial ACIlfov cand acesta va exista.

---

## Ce contine (pe scurt)

- **Login prin WebView** (portalul gestioneaza parola + verificarea anti-robot).
- **Interfata nativa** cu meniu lateral (hamburger + swipe): Acasa, Istoric
  facturi, Transmitere index, Istoric consum, Istoric plati, Alerte si
  notificari, Actualizare date cont, Trimitere mesaj, Informatii cont si
  contact, Configurari.
- **Notificari locale** pentru perioada de index si facturi scadente.
- **Trei surse de date interschimbabile** dintr-o singura linie de cod.

---

## Cum pornesti proiectul (pe PC-ul tau)

Structura din acest folder contine codul aplicatiei (`lib/`), dar **nu** si
folderele native `android/` si `ios/` (se genereaza automat).

1. Deschide un terminal in acest folder si genereaza partea nativa:

   ```
   flutter create --project-name acilfov_mobile .
   ```

2. Descarca pachetele:

   ```
   flutter pub get
   ```

3. Copiaza codul nativ pentru cookie-uri din **v1** (ca sa functioneze
   pastrarea sesiunii). Din proiectul vechi ACIlfovMobile, copiaza:
   - `android/app/src/main/kotlin/.../MainActivity.kt`
   - `ios/Runner/AppDelegate.swift`

   (Sunt aceleasi - folosesc canalul `acilfov/cookies`.)

4. Ruleaza aplicatia:

   ```
   flutter run
   ```

> **Vrei doar sa vezi interfata?** In modul debug, pe ecranul de login apasa
> butonul de intrare (dreapta sus) - sare peste login si intra direct in
> aplicatie cu **date de test**.

---

## Comutatorul de date (cel mai important)

Aplicatia poate lua datele din trei surse. Schimbi **o singura valoare** in
`lib/core/config/app_config.dart`:

```dart
static const DataSource dataSource = DataSource.mock;
```

| Valoare              | Ce face                                                        | Cand o folosesti            |
|----------------------|----------------------------------------------------------------|-----------------------------|
| `DataSource.mock`    | Date de test (fixe)                                            | Dezvoltare / vezi interfata |
| `DataSource.cookie`  | Date **reale** din portal, prin sesiunea de dupa login         | Acum, pana exista API       |
| `DataSource.api`     | API-ul oficial ACIlfov                                         | Viitor (tranzitia ideala)   |

Cand ACIlfov publica API-ul: pui `DataSource.api`, completezi caile reale in
`lib/data/repositories/api_aci_repository.dart` (marcate cu `TODO`) si **gata** -
ecranele nu se modifica deloc.

---

## Structura folderelor

```
lib/
  main.dart                  punctul de pornire (alege sursa + porneste app-ul)
  app.dart                   invelisul (tema + login vs. aplicatie)
  core/
    config/app_config.dart   adrese, culori, COMUTATORUL de sursa de date
    theme/app_theme.dart     tema vizuala
    utils/format.dart        formatare sume/date
  data/
    models/                  forma datelor (cont, factura, index)
    repositories/            contractul + cele 3 surse (mock / cookie / api)
    sources/                 clientii HTTP (portal cu cookie / API cu token)
    cookie_store.dart        pastrarea sesiunii + acces la cookie
    secure_store.dart        seif criptat pentru token (viitor)
  state/                     "creierul" ecranelor (Provider): auth + cont
  services/
    notification_service.dart notificari locale
  features/                  ecranele (auth, shell/meniu, si fiecare pagina)
docs/
  ARHITECTURA.md             explicatia detaliata a arhitecturii
  PROPUNERE-TEHNICA-ACILFOV.md  propunerea pentru ACIlfov (API + token)
```

---

## Notificari - ce se poate si ce nu

- **Notificari locale** (index / facturi scadente): functioneaza acum, fara
  server. Sunt programate pe telefon pe baza datelor pe care aplicatia le stie.
- **Notificari instant** (ex: "s-a emis o factura noua", chiar cu aplicatia
  inchisa): necesita API + webhook din partea ACIlfov, sau folosirea Home
  Assistant. Detalii in `docs/ARHITECTURA.md` si in propunerea tehnica.

---

## Licentiere / confidentialitate

Proiect privat. A se vedea regulile de confidentialitate ale proiectului
(identitate HomeRiz, fara date personale in istoricul repo-ului).

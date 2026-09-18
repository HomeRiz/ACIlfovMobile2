# Propunere tehnică: API, autentificare OAuth și tokene de integrare pentru portalul ACIlfov

**Către:** Echipa tehnică Apa Canal Ilfov / furnizorul platformei `acilfov.emsys.ro`
**De la:** [Nume expeditor]
**Data:** [completează la trimitere]
**Subiect:** Propunere pentru expunerea unui API de cont, autentificare standard OAuth 2.0 și tokene read-only pentru integrări personale (ex. Home Assistant)

---

## 1. Rezumat executiv (pentru management)

Am dezvoltat o aplicație mobilă pentru clienții Apa Canal Ilfov, care în prezent
afișează portalul existent. Pentru a oferi clienților o experiență modernă
(notificări la emiterea facturii și la perioada de transmitere a indexului,
interfață rapidă și simplă), aplicația are nevoie să **acceseze datele contului
în mod structurat și sigur**.

Astăzi, singura cale este „citirea" paginilor web, o metodă fragilă și
nerecomandată. Propunem trei elemente standard în industrie, care aduc beneficii
și companiei, și clienților:

1. **Un API de cont** — o cale sigură prin care aplicații autorizate pot citi
   date (facturi, index, scadențe).
2. **Autentificare standard (OAuth 2.0)** — clientul se loghează o singură dată,
   fără ca aplicația să stocheze vreodată parola.
3. **Tokene personale read-only** — pe care clientul le poate genera singur, ca
   să-și conecteze contul la instrumente proprii (ex. Home Assistant).

**Beneficii pentru ACIlfov:** clienți mai mulțumiți, mai puține apeluri la
call-center (clientul e notificat proactiv), plăți mai punctuale (alerte de
scadență), imagine de operator modern — fără a expune parole sau a compromite
securitatea.

---

## 2. Situația actuală și problema

- Portalul `acilfov.emsys.ro` este proiectat pentru navigare umană în browser
  (inclusiv verificare anti-robot Cloudflare Turnstile).
- O aplicație terță nu poate obține datele decât imitând un browser și
  interpretând HTML-ul paginilor — soluție **fragilă** (se strică la orice
  modificare a site-ului) și **nedorită** din punct de vedere al securității.
- Nu există notificări proactive: clientul află de o factură nouă doar dacă
  intră singur pe portal.

---

## 3. Cele trei cereri

### Cererea 1 — Un API REST pentru datele contului

Un set minim de puncte de acces (endpoint-uri) care întorc date în format JSON:

- date cont (titular, cod client, adresă, **sold**);
- listă **facturi** (număr, data emiterii, **scadență**, sumă, stare plătit/neplătit);
- **index** contor (ultima valoare, data, perioada de transmitere);
- transmitere index (trimiterea unei citiri noi).

**De ce:** permite o aplicație stabilă și rapidă, fără scraping. Este fundația
pentru orice funcție ulterioară (notificări, istoric, integrări).

### Cererea 2 — Autentificare standard OAuth 2.0 (WebView-ul rămâne pasul de login)

Fluxul standard folosit de aproape orice aplicație mobilă serioasă:

1. Clientul se loghează **o singură dată** pe portal (unde rulează și Turnstile).
2. La login reușit, portalul emite un **token de acces** legat de contul acelui
   client (schimbul standard „authorization code → token").
3. Aplicația păstrează tokenul într-un seif criptat (Keychain / Keystore) și îl
   folosește pentru cererile către API — **invizibil** pentru client de aici
   încolo. Cu un „refresh token", reînnoirea rămâne și ea invizibilă.

**De ce:** aplicația **nu stochează niciodată parola**. Accesul este legat de
sesiunea autentificată a clientului, revocabil în orice moment. Turnstile nu e
ocolit „cu forța" — pur și simplu cererile API cu token nu trec prin formularul
web, deci nu-l ating.

### Cererea 3 — Tokene personale read-only (pentru integrări, ex. Home Assistant)

Un token separat, pe care **clientul îl generează singur** din setările contului:

- **read-only** (doar citire, nu poate modifica nimic);
- **revocabil** oricând de către client;
- **separat** de tokenul aplicației mobile (revocarea unuia nu îl afectează pe celălalt).

**De ce:** tot mai mulți clienți tehnici vor să-și vadă consumul/facturile în
sisteme proprii de tip „smart home" (Home Assistant). Un token read-only e ieftin
de implementat și fără riscuri (nu permite operațiuni, doar citire).

---

## 4. Securitate (principii)

- **Fără parole stocate** în aplicații terțe — doar tokene, emise după login.
- **Token legat de user + revocabil** — clientul (sau operatorul) poate revoca
  accesul în orice moment.
- **Scope minim** — tokenul de integrare este strict read-only.
- **Autenticitatea aplicației (opțional):** pentru a vă asigura că cererile vin
  chiar de la aplicația oficială și nu de la o copie, se pot folosi mecanismele
  standard **Play Integrity (Android)** și **App Attest (iOS)**.
- **HTTPS obligatoriu** pentru toate apelurile.

> Notă onestă: un „secret" înglobat într-o aplicație mobilă distribuită nu este
> cu adevărat secret (poate fi extras). De aceea securitatea reală provine din
> tokenul legat de sesiunea clientului autentificat, nu dintr-o cheie ascunsă în
> aplicație. App Attest / Play Integrity acoperă exact acest aspect.

---

## 5. Anexă tehnică (pentru ingineri)

### 5.1 Endpoint-uri propuse (exemplu)

```
GET  /api/v1/account            -> { holder_name, client_code, address, balance }
GET  /api/v1/invoices           -> { items: [ { id, number, issue_date, due_date, amount, paid } ] }
GET  /api/v1/meter-index        -> { last_value, last_read_date, window_start, window_end }
POST /api/v1/meter-index        -> body: { value }        (transmitere index)
```

Toate cererile autentificate trebuie sa foloseasca un antet de autentificare cu token.

### 5.2 Flux OAuth 2.0 (Authorization Code)

```
Aplicatie ──(deschide WebView login)──> Portal ACIlfov (+ Turnstile)
Portal    ──(authorization code)──────> Aplicatie
Aplicatie ──(code -> /oauth/token)────> Portal
Portal    ──(access_token + refresh)──> Aplicatie  (păstrat în seif criptat)
Aplicatie ──(Bearer token)────────────> API /api/v1/...
```

Endpoint-uri OAuth uzuale: `/oauth/authorize`, `/oauth/token`.
Scope-uri propuse: `account:read`, `invoices:read`, `index:read`, `index:write`.

### 5.3 Token read-only pentru integrări (Home Assistant)

- Generat de client în „Contul meu → Tokene API".
- Scope unic: `account:read invoices:read index:read` (fără `write`).
- Exemplu de folosire într-un senzor Home Assistant (RESTful sensor):

```yaml
sensor:
  - platform: rest
    name: ACIlfov Sold
    resource: https://acilfov.emsys.ro/api/v1/account
    headers:
      Authorization: "Bearer <TOKEN_READ_ONLY>"
    value_template: "{{ value_json.balance }}"
    scan_interval: 3600
```

### 5.4 Opțional — Webhook pentru notificări instant

Pentru instiințări în timp real (ex. „factură nouă emisă"), un webhook prin care
serverul ACIlfov anunță un serviciu al aplicației, care apoi trimite push (FCM)
către telefon:

```
Eveniment (factură nouă) --> POST webhook --> serviciu aplicatie --> FCM --> telefon
```

Alternativ, fără webhook, integrarea Home Assistant poate obține același rezultat
prin interogare periodică (polling) a API-ului.

---

## 6. Pași următori propuși

1. Confirmarea principiului de către ACIlfov (API + OAuth + token read-only).
2. Stabilirea împreună a listei exacte de endpoint-uri și scope-uri.
3. Un mediu de test (sandbox) pentru integrare.
4. Implementarea și testarea aplicației pe API-ul oficial.

Rămân la dispoziție pentru o discuție tehnică detaliată.

**Contact:** [nume, e-mail, telefon]

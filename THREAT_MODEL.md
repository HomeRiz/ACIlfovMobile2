# Threat model - ACIlfovMobile2

Data: 2026-07-07

## Context

Aplicatie Flutter pentru clienti ACIlfov. Autentificarea se face in portalul
oficial prin WebView, iar ecranele native folosesc cookie-ul portalului pentru
apeluri REST EMSYS.

## Active protejate

- Cookie sesiune portal.
- Date personale client: cod client, contract, adresa, istoric operatii.
- Date financiare: facturi, sold, plati.
- Operatii de cont: parola, configurari notificari, stergere cont.

## Suprafete de atac

- WebView login.
- Canal nativ `acilfov/cookies`.
- Stocare locala cookie/token.
- Cereri HTTPS catre `acilfov.emsys.ro`.
- Actiuni de scriere prin REST intern EMSYS.

## STRIDE

| Categorie | Risc | Masuri existente |
| --- | --- | --- |
| Spoofing | Navigare catre pagina falsa de login | Allowlist HTTPS pentru main-frame WebView. |
| Tampering | Modificare trafic local | HTTPS strict, cleartext blocat, trust store sistem. |
| Repudiation | Actiuni de cont contestate | Operatiile sunt trimise catre portalul autentic si jurnalizate server-side. |
| Information disclosure | Cookie sau date personale in backup/capturi | Storage criptat, backup dezactivat, Android `FLAG_SECURE`. |
| Denial of service | Portal indisponibil sau bundle schimbat | Erori afisate in UI, reload manual; necesita monitorizare. |
| Elevation of privilege | Abuz canal nativ/WebView | Fara JS channel; canalul de cookie este apelat doar din codul aplicatiei. |

## Decizii si ipoteze

- Se accepta temporar lipsa TLS pinning din cauza rotatiei certificatelor si
  folosirii Cloudflare.
- Se accepta folosirea endpoint-urilor REST interne EMSYS pana la publicarea
  unui API oficial ACIlfov.
- Actiunile destructive, precum stergerea contului, necesita confirmare UI si
  sesiune valida server-side.

## Teste recomandate pe dispozitiv real

- Login/logout si restaurarea sesiunii dupa inchiderea aplicatiei.
- Schimbare parola cu parola gresita si parola corecta.
- Trimitere mesaj companie.
- Activare/dezactivare factura prin email.
- Activare/dezactivare alerta cu email/telefon.
- Adaugare/stergere cod client si contract.
- Transmitere index doar in perioada permisa de portal.

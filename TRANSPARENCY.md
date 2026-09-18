# Declarație de transparență

Acest document există pentru ca oricine citește acest depozit de cod — Apa-Canal
Ilfov (ACIlfov), personalul lor, avocații lor, sau oricine altcineva — să
înțeleagă exact ce este acest proiect, cine l-a făcut și în ce condiții este
pus la dispoziție. Este scris intenționat în limbaj simplu, clar. Nu
înlocuiește o consultanță juridică; vezi nota de la final.

*(O traducere în engleză a acestui document, doar pentru referință, este
disponibilă la `en/TRANSPARENCY.md` — textul românesc de mai jos este singura
versiune autoritară.)*

## Ce este acest proiect

Această aplicație ("Apa Ilfov" / `ro.acilfov.mobile`) este un client mobil
neoficial, dezvoltat independent, pentru portalul web de clienți al ACIlfov
(`acilfov.emsys.ro`). A fost construită de un singur dezvoltator, sub numele
**HomeRiz**, din nevoie personală — pentru a avea o aplicație mobilă utilizabilă
pentru un serviciu care oferea doar un portal web gândit pentru desktop.

## Fără nicio afiliere

**HomeRiz nu este afiliat, asociat, autorizat, susținut de sau in vreun fel
legat oficial de Apa-Canal Ilfov, ACIlfov sau orice entitate care îi
reprezintă**, sau de oricare dintre filialele sau afiliații lor. Website-ul
oficial ACIlfov este [acilfov.ro](https://acilfov.ro/), iar portalul oficial de
clienți este [acilfov.emsys.ro](https://acilfov.emsys.ro/self_utilities/).
Această aplicație accesează exact acel portal, la fel cum ar face-o un browser
(vezi secțiunea "Info" din aplicație pentru mecanism, și `AUDIT/` din acest
depozit pentru auditul de securitate al acestui mecanism).

Acest proiect a fost construit și publicat integral din inițiativa proprie a
HomeRiz, fără să fi fost solicitat de ACIlfov, și fără nicio înțelegere
prealabilă.

## Ce se ofera si in ce conditii

HomeRiz oferă acest cod sursă integral și documentația aferentă către ACIlfov,
**în exclusivitate și fără nicio altă condiție**. Termenii juridici exacți sunt
în `LICENSE` (versiunea autoritară) — pe scurt:

- Doar ACIlfov are dreptul să folosească, copieze, modifice, distribuie sau
  relicențieze acest cod.
- **Nicio altă parte — inclusiv HomeRiz însuși** — nu are voie să
  folosească, copieze sau redistribuie acest cod, în tot sau în parte, fără
  permisiunea scrisă și explicită a ACIlfov, acordată după transfer.
- Odată intrat în posesia ACIlfov, ACIlfov poate aplica orice licență proprie
  consideră potrivită asupra copiei sale, inclusiv una închisă/proprietară, și
  poate modifica codul in orice fel doreste.
- Nu se solicită și nu se cere nicio mențiune, credit sau atribuire către
  HomeRiz, nicăieri — nici în aplicație, nici în cod, nici în vreo
  documentație pe care ACIlfov o va produce de acum înainte. Niciuna nu a fost
  adăugată în acest depozit, intenționat.

## Asistență ulterioară - nu este o obligație

HomeRiz poate, la propria discreție, să ajute ACIlfov să implementeze
funcționalități suplimentare sau să repare erori în acest cod, gratuit.
**Aceasta nu este un angajament sau un contract de servicii.** Orice astfel de
asistență poate fi refuzată, limitată sau încheiată de HomeRiz în orice moment,
din orice motiv, fără preaviz.

Dacă și când HomeRiz încetează să asiste acest proiect, întreaga
responsabilitate pentru dezvoltarea, actualizarea și întreținerea sa viitoare —
atât pe Android, cât și pe iOS — trece integral către ACIlfov. HomeRiz nu poarta
nicio răspundere pentru dezvoltarea, corectitudinea, securitatea sau
conformitatea legală a proiectului de acel moment înainte, sau in orice moment
ulterior transferului codului.

**Notă practică pentru cine întreține codul de acum înainte:** acesta este un
singur cod sursă Flutter/Dart (tot ce se afla in `lib/`), dar nu este pur
cross-platform — există cod nativ, specific fiecărei platforme, care trebuie
întreținut independent pe fiecare parte:

- `ios/Runner/AppDelegate.swift`, `ios/Runner/SceneDelegate.swift` (Swift) —
  puntea nativă pentru cookie, overlay-ul de confidențialitate din
  app-switcher-ul iOS, și înregistrarea sarcinii de fundal (`BGTaskScheduler`)
  necesară ca verificarea periodică a facturilor să funcționeze pe iOS.
- `android/app/src/main/kotlin/ro/acilfov/mobile/MainActivity.kt` (Kotlin) —
  puntea nativă echivalentă pentru cookie și protecția `FLAG_SECURE` împotriva
  capturilor de ecran.

O modificare a modului în care funcționează sesiunile de login, notificările
sau verificările din fundal are, de regulă, nevoie de o schimbare identică pe
ambele părți, nu doar în `lib/`.

## Retragere și ștergere

Dacă ACIlfov decide să nu continue cu acest proiect, **HomeRiz se angajează să
șteargă definitiv întregul cod sursă și documentația aferentă în termen de 24
de ore de la primirea unei cereri scrise, prin e-mail, care solicită exact
acest lucru.**

Aceasta este o politică declarată, dusă la îndeplinire manual de o persoană, la
cerere — nu este și nu va fi un sistem automatizat care monitorizează o căsuță
de mail. Dacă trimiteți acea cerere, așteptați-vă la un răspuns uman care
confirmă ștergerea, nu la o acțiune automată.

## Răspundere

Acest software este oferit sub o licență de utilizare exclusivă (`LICENSE` din
acest depozit), care include o clauză standard de tip "AS IS" (fără garanție)
și o limitare a răspunderii. HomeRiz nu își asumă nicio răspundere pentru modul
în care acest cod este folosit, modificat, implementat sau utilizat de
oricine, inclusiv ACIlfov, înainte sau după acest transfer.

## O notă despre acest document

Acest document a fost scris pentru a fi clar și onest, nu ca instrument
juridic testat. HomeRiz nu este avocat. Dacă efectul juridic al acestei
declarații devine vreodată relevant — un litigiu, o cesiune formală, orice
situație cu mize reale — ar trebui revizuit de un avocat adevărat înainte ca
oricare parte să se bazeze pe el.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';

class InfoView extends StatelessWidget {
  const InfoView({super.key});

  static const List<_NativeDocument> _documents = [
    _NativeDocument(
      title: 'Licenta de utilizare',
      subtitle: 'Certificari, licentiere si autorizatii Apa Ilfov',
      icon: Icons.verified_outlined,
      officialLinks: [
        _OfficialLink(
          label: 'Pagina oficiala: Certificari si licentiere',
          url: AppConfig.officialLicensingUrl,
        ),
      ],
      sections: [
        _DocumentSection(
          title: 'Certificare ISO 9001 - Managementul calitatii',
          body:
              'Certificatul ISO 9001 reprezinta o confirmare a respectarii de catre Apa-Canal Ilfov a cerintelor impuse de implementarea unui sistem de management al calitatii.\n\n'
              'Detinerea certificatului ISO 9001 constituie argumentul oferit clientilor Apa-Canal Ilfov ca societatea functioneaza in acord si pe baza unui sistem de calitate recunoscut international.\n\n'
              'Certificarea ISO 9001 reprezinta o confirmare a managementului eficace practicat in organizatie, da incredere tertilor in "calitatea" organizatiei, confirmata "zi de zi" prin respectarea angajamentelor luate, confirma calitatea si progresul permanent al organizatiei.',
        ),
        _DocumentSection(
          title: 'Certificare ISO 14001 - Management al mediului',
          body:
              'Certificatul ISO 14001 demonstreaza ca Sistemul de Management de Mediu al Apa-Canal Ilfov a fost testat si gasit corespunzator referitor la standardul de buna practica, asigurand clientii ca pot avea incredere in faptul ca organizatia minimizeaza activ impactul asupra mediului prin procesele, produsele si serviciile proprii.\n\n'
              'Preocuparea tot mai accentuata a Operatorului Regional Apa-Canal Ilfov pentru protectia mediului inconjurator este o consecinta a dezvoltarii economice sustinute din ultimii ani, a constientizarii importantei protejarii mediului in care traim, atat pentru noi cat si pentru generatiile viitoare.',
        ),
        _DocumentSection(
          title: 'Certificare ISO 45001 - Sanatate si Securitate Ocupationala',
          body:
              'Certificatul ISO 45001 demonstreaza ca sistemul de management al sanatatii si securitatii ocupationale are un ridicat nivel de control in ceea ce priveste conformitatea cu legislatia in vigoare.',
        ),
        _DocumentSection(
          title: 'Licentiere',
          body:
              'Conform ordinului ANRSC nr.348/10.10.2017, Apa Ilfov a obtinut Licenta CLASA 2 pentru serviciul public de alimentare cu apa si de canalizare.',
          bullets: [
            'Ordine ANRSC publicate: 416/21.06.2023, 703/24.10.2022, 112/11.03.2021, 171/07.05.2020, 518/24.10.2019, 97/23.02.2018 si 348/10.10.2017. Textul integral al fiecarui ordin este disponibil pe pagina oficiala de mai sus.',
          ],
        ),
        _DocumentSection(
          title: 'Analize apa potabila si ape uzate',
          body:
              'Laboratorul este dotat cu aparatura moderna, de ultima generatie, si dispune de personal calificat care garanteaza performanta metodelor de lucru, conform cerintelor impuse de RENAR si Ministerul Sanatatii prin Institutul National de Sanatate Publica si Directia de Sanatate Publica Ilfov.',
        ),
        _DocumentSection(
          title: 'Montare contoare de apa rece',
          body:
              'Avizele Biroului Roman de Metrologie Legala (BRML) pentru exercitarea activitatii de montare contoare de apa rece sunt publicate pe pagina oficiala de mai sus (documente 2019-2025).',
        ),
      ],
    ),
    _NativeDocument(
      title: 'Conformitate GDPR',
      subtitle: 'Date personale, scopuri, temeiuri si drepturi',
      icon: Icons.privacy_tip_outlined,
      officialLinks: [
        _OfficialLink(
          label: 'Pagina oficiala: Prelucrarea datelor cu caracter personal',
          url: AppConfig.officialTermsUrl,
        ),
        _OfficialLink(
          label: 'Formular exercitare drepturi GDPR (PDF)',
          url: AppConfig.officialGdprFormUrl,
        ),
      ],
      sections: [
        _DocumentSection(
          title: 'Prelucrarea datelor - cadru general',
          body:
              'Conform cerintelor Legii nr. 677/2001 pentru protectia persoanelor cu privire la prelucrarea datelor cu caracter personal si libera circulatie a acestor date, modificata si completata, si ale Legii nr. 506/2004 privind prelucrarea datelor cu caracter personal si protectia vietii private in sectorul comunicatiilor electronice, S.C. Apa-Canal Ilfov S.A. are obligatia de a administra in conditii de siguranta si numai pentru scopurile specificate datele personale pe care ni le furnizati despre dumneavoastra, un membru al familiei dumneavoastra ori o alta persoana.\n\n'
              'S.C. Apa-Canal Ilfov S.A. prelucreaza datele dumneavoastra cu caracter personal, prin mijloace automatizate si manuale, destinate emiterii facturilor de servicii, colectarea creantelor legate de acestea, precum si rezolvarii solicitarilor dumneavoastra in legatura cu activitatea desfasurata de Apa-Canal Ilfov S.A.\n\n'
              'Datele dumneavoastra sunt necesare emiterii facturilor de servicii, colectarii creantelor legate de acestea, precum si rezolvarii solicitarilor dumneavoastra in legatura cu activitatea desfasurata de Apa-Canal Ilfov S.A. Refuzul dumneavoastra determina imposibilitatea furnizarii serviciilor.\n\n'
              'Aceste date furnizate sunt strict confidentiale. Societatea S.C. Apa-Canal Ilfov S.A. se angajeaza in fata clientilor sai sa nu furnizeze aceste date unor terte persoane sau companii si sa le utilizeze strict in uzul relatiei comerciale dintre client si S.C. Apa-Canal Ilfov. Societatea are dreptul sa distribuie aceste informatii catre colaboratorii sai, care le pot folosi in aceleasi scopuri. Datele dumneavoastra nu pot fi transferate in strainatate.',
        ),
        _DocumentSection(
          title: 'Numar de inregistrare si actualizarea datelor',
          body:
              'Numarul de inregistrare al S.C. Apa-Canal Ilfov S.A. in Registrul de evidenta a operatorilor de date cu caracter personal este 31452.\n\n'
              'In cazul in care au intervenit modificari in datele contractuale (schimbarea titularului, a adresei de corespondenta, a numarului de persoane din imobil sau a suprafetei imobilului), aveti obligatia sa ni le aduceti la cunostinta, pentru a nu influenta prestarea serviciului de alimentare cu apa potabila si/sau canalizare. Actualizarea datelor contractuale va asigura furnizarea serviciilor in cele mai bune conditii.',
        ),
        _DocumentSection(
          title: 'GDPR - Regulamentul (UE) 2016/679',
          body:
              'Incepand cu data de 25 mai 2018, au devenit aplicabile prevederile Regulamentului (UE) 2016/679 al Parlamentului European si al Consiliului din 27 aprilie 2016 privind protectia persoanelor fizice in ceea ce priveste prelucrarea datelor cu caracter personal si privind libera circulatie a acestor date si de abrogare a Directivei 95/46/CE ("GDPR").\n\n'
              'GDPR impune un set unic de reguli, direct aplicabile in toate statele membre ale Uniunii Europene, si inlocuieste Directiva 95/46/CE si, implicit, prevederile Legii nr. 677/2001.\n\n'
              'Protectia persoanelor fizice in ceea ce priveste prelucrarea datelor cu caracter personal este un drept fundamental al omului, prevazut in art. 8 alin. (1) din Carta drepturilor fundamentale a Uniunii Europene si art. 16 alin. (1) din Tratatul privind functionarea Uniunii Europene.\n\n'
              'APA ILFOV cunoaste importanta datelor dumneavoastra si se angajeaza sa protejeze confidentialitatea si securitatea acestora, in calitate de operator de date cu caracter personal.',
          bullets: [
            'Dreptul de a fi uitat - va puteti opune prelucrarii datelor pentru motive intemeiate si legitime legate de situatia dvs. particulara (cu exceptia marketingului direct, unde va puteti opune oricand, gratuit); puteti solicita stergerea datelor, cu exceptiile prevazute de lege.',
            'Dreptul la portabilitatea datelor - puteti opta pentru transmiterea datelor catre un alt partener.',
            'Prevederi specifice pentru minori - APA ILFOV nu urmareste in activitatile sale prelucrarea datelor cu caracter personal ale minorilor.',
          ],
        ),
        _DocumentSection(
          title: 'Ce date personale detine ACIlfov',
          body:
              'Apa Ilfov detine urmatoarele date personale pe care le-ati furnizat cu ocazia incheierii contractului de furnizare/prestare a serviciului de apa si de canalizare: nume, prenume, domiciliu, adresa de corespondenta, CNP, serie si numar act de identitate, numar telefon, adresa de e-mail, semnatura.\n\n'
              'Datele cu caracter personal care beneficiaza de un regim special de protectie (CNP, serie si numar act de identitate) vor fi colectate si prelucrate in conditii limitative, conform legislatiei aplicabile in domeniul protectiei datelor.\n\n'
              'APA ILFOV poate detine filmari din incinta punctelor de lucru ale societatii, utilizarea sistemului video fiind necesara in special in vederea controlului de securitate si paza, atat a angajatilor cat si a clientilor.',
        ),
        _DocumentSection(
          title: 'Scopul prelucrarii',
          bullets: [
            'Derularea relatiilor contractuale in vederea prestarii serviciilor de apa si/sau de canalizare; transmiterea diferitelor informari legate de activitatea dvs. ca utilizator al serviciului.',
            'Intocmirea facturilor fiscale.',
            'Prelucrarea in conditiile solicitarilor autoritatilor statului, conform legislatiei in vigoare.',
          ],
          body: '',
        ),
        _DocumentSection(
          title: 'Temeiul legal al prelucrarii',
          body: 'Prelucrarea se realizeaza in baza:',
          bullets: [
            'Art. 6 alin. 1 lit. b) GDPR - executarea unui contract la care persoana vizata este parte, sau demersuri la cererea acesteia inainte de incheierea unui contract.',
            'Art. 6 alin. 1 lit. c) GDPR - indeplinirea unei obligatii legale (Legea nr. 241/2006, Legea nr. 51/2006, Ordinele ANRSC nr. 90/2007 si nr. 88/2007, printre altele).',
            'Art. 6 alin. 1 lit. f) GDPR - interesele legitime urmarite de operator.',
            'Art. 9 alin. (2) lit. j) GDPR - scopuri de cercetare stiintifica, in baza dreptului Uniunii sau a dreptului intern, unde este cazul.',
          ],
        ),
        _DocumentSection(
          title: 'Durata de stocare',
          body:
              'Datele personale sunt necesare pentru indeplinirea obligatiilor legale. Avand in vedere necesitatea constituirii evidentelor utilizatorilor serviciilor de apa si/sau canalizare, aceste date vor fi stocate pe perioada nedeterminata.',
        ),
        _DocumentSection(
          title: 'Cui ii dezvaluim datele',
          body:
              'In vederea realizarii scopurilor mentionate mai sus, Apa Ilfov poate dezvalui datele dumneavoastra cu caracter personal catre:',
          bullets: [
            'Furnizorii cu care a incheiat contracte de prestari servicii pentru buna functionare a sistemelor informatice.',
            'Furnizorii de servicii in interesul operatorului (societati de avocatura, societati de recuperare a creantelor, executori judecatoresti etc.).',
            'Anumite autoritati publice (politie, instante judecatoresti si alte organe abilitate ale statului), in baza si in limitele prevederilor legale, ca urmare a unor cereri expres formulate.',
          ],
        ),
        _DocumentSection(
          title: 'Drepturile dumneavoastra',
          body:
              'Incepand cu intrarea in vigoare a GDPR, va puteti exercita gratuit urmatoarele drepturi:',
          bullets: [
            'Dreptul la informare - identitatea operatorului, scopul prelucrarii, destinatarii datelor, drepturile GDPR si conditiile de exercitare.',
            'Dreptul de acces la date - confirmarea faptului ca datele sunt sau nu prelucrate.',
            'Dreptul de interventie - rectificarea, actualizarea, blocarea, stergerea sau anonimizarea datelor incomplete/inexacte, la cerere si gratuit.',
            'Dreptul de opozitie - va puteti opune oricand, din motive intemeiate si legitime legate de situatia particulara, cu exceptiile prevazute de lege.',
            'Dreptul de a nu fi supus unei decizii individuale bazate exclusiv pe prelucrare automata.',
            'Dreptul de a contacta responsabilul pentru protectia datelor, la dpo@acilfov.ro.',
            'Dreptul de a va adresa Autoritatii Nationale de Supraveghere a Prelucrarii Datelor cu Caracter Personal (www.dataprotection.ro), daca considerati ca drepturile v-au fost incalcate de APA ILFOV.',
          ],
        ),
        _DocumentSection(
          title: 'Exercitarea drepturilor si contact',
          body:
              'Pentru exercitarea drepturilor conform Legii nr. 677/2001, va puteti adresa cu o cerere scrisa, datata si semnata, la sediul din Bucuresti, Calea Bucurestilor nr. 222C, Otopeni, Ilfov, sau puteti folosi formularul oficial de mai sus. Aveti de asemenea dreptul de a va adresa justitiei.\n\n'
              'Niciun program de securizare a informatiilor nu este infailibil. APA ILFOV nu promoveaza SPAM-ul; orice utilizator care a furnizat explicit adresa sa de e-mail poate opta pentru stergerea acesteia din baza de date a institutiei.',
        ),
      ],
    ),
    _NativeDocument(
      title: 'Politica de cookie',
      subtitle: 'Ce sunt cookie-urile si cum sunt folosite',
      icon: Icons.cookie_outlined,
      officialLinks: [
        _OfficialLink(
          label: 'Pagina oficiala: Politica de cookie',
          url: AppConfig.officialCookiePolicyUrl,
        ),
      ],
      sections: [
        _DocumentSection(
          title: 'Folosirea reala in aceasta aplicatie (citeste asta primul)',
          body:
              'Sectiunile de mai jos sunt textul oficial, integral, al politicii de cookie publicate pe website-ul acilfov.ro - acesta descrie website-ul, nu aplicatia mobila. Aplicatia mobila Apa Ilfov NU foloseste cookie-uri de analytics, publicitate sau de la terti (Google, Facebook, LinkedIn etc.) mentionate mai jos.',
          bullets: [
            'Aplicatia foloseste EXCLUSIV cookie-ul de sesiune al portalului EMSYS, obtinut dupa login, doar pentru autentificare si pentru cererile facute in numele utilizatorului autentificat.',
            'Cookie-ul de sesiune este transmis doar catre domeniul portalului Apa Ilfov (acilfov.emsys.ro).',
            'Aplicatia nu include module proprii de publicitate, urmarire sau analytics.',
            'Utilizatorul poate sterge sesiunea oricand, prin Deconectare.',
          ],
        ),
        _DocumentSection(
          title: 'Politica de cookie a website-ului acilfov.ro (text oficial)',
          body:
              'Acest website foloseste cookie-uri proprii si de la terti pentru a furniza vizitatorilor o experienta mult mai buna de navigare si servicii adaptate nevoilor si interesului fiecaruia.\n\n'
              'Pe Internet, cookie-urile joaca un rol important in facilitarea accesului si livrarii multiplelor servicii de care utilizatorul se bucura pe Internet, cum ar fi: personalizarea anumitor setari (limba, moneda, preferinte, cosul de cumparaturi), feedback valoros pentru detinatorii de site-uri, includerea de aplicatii multimedia de pe alte site-uri si imbunatatirea eficientei publicitatii online.',
        ),
        _DocumentSection(
          title: 'Ce este un "cookie"?',
          body:
              'Un "Internet Cookie" (cunoscut si ca "browser cookie", "HTTP cookie" sau simplu "cookie") este un fisier de mici dimensiuni, format din litere si numere, stocat pe computerul, terminalul mobil sau alte echipamente ale unui utilizator de pe care se acceseaza Internetul.\n\n'
              'Cookie-ul este instalat prin solicitarea emisa de catre un web-server unui browser si este complet "pasiv" (nu contine programe software, virusi sau spyware si nu poate accesa informatiile de pe discul utilizatorului).\n\n'
              'Un cookie este format din 2 parti: numele si continutul sau valoarea cookie-ului. Durata de existenta a unui cookie este determinata; tehnic, doar webserverul care a trimis cookie-ul il poate accesa din nou cand utilizatorul se intoarce pe website-ul asociat.\n\n'
              'Cookie-urile in sine nu solicita informatii cu caracter personal pentru a putea fi utilizate si, in cele mai multe cazuri, nu identifica personal utilizatorii de Internet.',
          bullets: [
            'Cookie-uri de sesiune - stocate temporar, memorate pana cand utilizatorul iese de pe website sau inchide fereastra browserului.',
            'Cookie-uri persistente - stocate pe hard-drive-ul unui echipament; includ si cele plasate de alt website decat cel vizitat ("third party cookies"), care pot fi folosite anonim pentru a memora interesele unui utilizator.',
          ],
        ),
        _DocumentSection(
          title: 'Cum sunt folosite cookie-urile pe acest website',
          body:
              'O vizita pe acest site poate plasa cookie-uri in scopuri de: analiza a vizitatorilor, inregistrare si publicitate. Aceste cookie-uri pot proveni de la urmatorii terti: Google, Facebook, LinkedIn.',
          bullets: [
            'Cookie-uri pentru analiza vizitatorilor - genereaza un cookie care spune daca ati mai vizitat site-ul, permitand monitorizarea utilizatorilor unici si a frecventei vizitelor; folosite doar statistic cat timp nu sunteti inregistrat.',
            'Cookie-uri pentru inregistrare - anunta daca sunteti inregistrat, arata contul si permisiunile; se sterg automat la inchiderea browserului daca nu ati ales "pastreaza-ma inregistrat".',
            'Cookie-uri pentru publicitate - arata daca ati vazut o reclama online, tipul acesteia si cat timp a trecut; pot folosi si cookie-uri de la terti pentru targetare, stocand informatii despre continutul vizualizat, nu despre utilizatori.',
          ],
        ),
        _DocumentSection(
          title: 'Securitate si confidentialitate',
          body:
              'Cookie-urile NU sunt virusi - folosesc format plain text, nu sunt cod executabil si nu se pot duplica sau replica singure. Pot fi totusi folosite pentru scopuri negative, deoarece stocheaza informatii despre preferintele si istoricul de navigare, motiv pentru care produsele anti-spyware le marcheaza adesea pentru stergere.\n\n'
              'Daca un atacator intervine in transmiterea datelor (de exemplu printr-o retea WiFi nesecurizata sau printr-un website cu setari gresite ale cookie-urilor), informatiile continute de cookie pot fi interceptate. Browserele moderne au integrate setari de confidentialitate care controleaza acceptarea, valabilitatea si stergerea automata a cookie-urilor.',
        ),
        _DocumentSection(
          title: 'Cum pot opri cookie-urile?',
          body:
              'Dezactivarea si refuzul de a primi cookie-uri pot face anumite site-uri impracticabile sau dificil de vizitat si folosit; refuzul nu inseamna ca nu veti mai vedea publicitate online, doar ca aceasta nu va mai tine cont de preferintele dvs.\n\n'
              'Toate browserele moderne permit schimbarea setarilor cookie-urilor, de regula din meniul de "optiuni" sau "preferinte". Pentru cookie-urile generate de terti pentru publicitate, poate fi consultat si www.youronlinechoices.com/ro/.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const _SectionTitle('Informatii native'),
        for (final document in _documents)
          Card(
            child: ListTile(
              leading: Icon(document.icon, color: const Color(0xFF335C80)),
              title: Text(document.title),
              subtitle: Text(document.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _NativeDocumentPage(document: document),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NativeDocumentPage extends StatelessWidget {
  final _NativeDocument document;

  const _NativeDocumentPage({required this.document});

  Future<void> _openOfficialLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu am putut deschide pagina oficiala.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Textul de mai jos este un rezumat. Pentru informatia oficiala '
            'completa, vezi pagina ACIlfov:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 8),
          for (final link in document.officialLinks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: () => _openOfficialLink(context, link.url),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(link.label),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  foregroundColor: const Color(0xFF335C80),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          for (final section in document.sections) ...[
            Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF335C80),
                  ),
            ),
            const SizedBox(height: 6),
            Text(section.body),
            if (section.bullets.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final bullet in section.bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(bullet)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _NativeDocument {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_DocumentSection> sections;
  final List<_OfficialLink> officialLinks;

  const _NativeDocument({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sections,
    this.officialLinks = const [],
  });
}

// Link catre pagina oficiala ACIlfov care contine informatia completa (nu
// doar rezumatul nativ de mai sus). Deschis in browser-ul extern, nu in
// aplicatie, ca utilizatorul sa vada exact pagina publicata de ACIlfov.
class _OfficialLink {
  final String label;
  final String url;

  const _OfficialLink({required this.label, required this.url});
}

class _DocumentSection {
  final String title;
  final String body;
  final List<String> bullets;

  const _DocumentSection({
    required this.title,
    required this.body,
    this.bullets = const [],
  });
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF335C80),
          ),
        ),
      );
}

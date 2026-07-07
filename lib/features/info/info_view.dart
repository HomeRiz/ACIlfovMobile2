import 'package:flutter/material.dart';

class InfoView extends StatelessWidget {
  const InfoView({super.key});

  static const List<_NativeDocument> _documents = [
    _NativeDocument(
      title: 'Licenta de utilizare',
      subtitle: 'Certificari, licentiere si autorizatii Apa Ilfov',
      icon: Icons.verified_outlined,
      sections: [
        _DocumentSection(
          title: 'Certificari',
          body:
              'Apa-Canal Ilfov isi desfasoara activitatea in baza unor sisteme certificate pentru managementul calitatii, protectia mediului si sanatate si securitate ocupationala.',
          bullets: [
            'ISO 9001 confirma cerintele sistemului de management al calitatii si modul controlat de functionare al organizatiei.',
            'ISO 14001 confirma sistemul de management de mediu si preocuparea pentru reducerea impactului asupra mediului.',
            'ISO 45001 confirma sistemul de management al sanatatii si securitatii ocupationale.',
          ],
        ),
        _DocumentSection(
          title: 'Licentiere',
          body:
              'Conform ordinului ANRSC nr. 348/10.10.2017, Apa Ilfov a obtinut licenta clasa 2 pentru serviciul public de alimentare cu apa si de canalizare.',
          bullets: [
            'Ordine ANRSC mentionate public: 416/21.06.2023, 703/24.10.2022, 112/11.03.2021, 171/07.05.2020, 518/24.10.2019, 97/23.02.2018 si 348/10.10.2017.',
          ],
        ),
        _DocumentSection(
          title: 'Laborator si contoare',
          body:
              'Laboratorul pentru analiza apei potabile si apei uzate este prezentat ca fiind dotat cu aparatura moderna si personal calificat, conform cerintelor RENAR si Ministerului Sanatatii.',
          bullets: [
            'Sunt mentionate certificatul RENAR si certificatul Ministerului Sanatatii pentru laborator.',
            'Sunt mentionate avize BRML pentru exercitarea activitatii de montare contoare de apa rece.',
          ],
        ),
      ],
    ),
    _NativeDocument(
      title: 'Conformitate GDPR',
      subtitle: 'Date personale, scopuri, temeiuri si drepturi',
      icon: Icons.privacy_tip_outlined,
      sections: [
        _DocumentSection(
          title: 'Operator si scop',
          body:
              'Apa Ilfov prelucreaza date personale pentru derularea contractelor de furnizare/prestare a serviciilor de apa si canalizare, facturare, colectarea creantelor si solutionarea solicitarilor clientilor.',
          bullets: [
            'Datele pot include nume, prenume, domiciliu, adresa de corespondenta, CNP, act de identitate, telefon, e-mail si semnatura.',
            'Datele sunt necesare pentru executarea contractului si indeplinirea obligatiilor legale.',
            'Refuzul furnizarii datelor necesare poate face imposibila furnizarea serviciilor.',
          ],
        ),
        _DocumentSection(
          title: 'Temeiuri si perioada',
          body:
              'Prelucrarea este indicata in legatura cu executarea contractului, obligatiile legale, interesele legitime si, unde este cazul, temeiuri speciale prevazute de GDPR.',
          bullets: [
            'Datele necesare evidentei utilizatorilor serviciilor de apa si canalizare pot fi pastrate pe perioada necesara indeplinirii obligatiilor legale.',
            'Sunt mentionate si prelucrari prin sisteme video in punctele de lucru, in scop de securitate.',
          ],
        ),
        _DocumentSection(
          title: 'Drepturile persoanei vizate',
          body:
              'Persoanele vizate au drepturi privind accesul, rectificarea, opozitia, stergerea in cazurile prevazute de lege, portabilitatea datelor si adresarea catre autoritati sau justitie.',
          bullets: [
            'Dreptul de opozitie poate fi exercitat in special pentru motive legate de situatia particulara, iar pentru marketing direct opozitia se poate face oricand.',
            'Pentru exercitarea drepturilor, cererile se transmit catre Apa Ilfov prin canalele oficiale de contact.',
            'Datele furnizate sunt tratate confidential, cu respectarea legislatiei aplicabile.',
          ],
        ),
      ],
    ),
    _NativeDocument(
      title: 'Politica de cookie',
      subtitle: 'Ce sunt cookie-urile si cum sunt folosite',
      icon: Icons.cookie_outlined,
      sections: [
        _DocumentSection(
          title: 'Rolul cookie-urilor',
          body:
              'Cookie-urile sunt fisiere mici stocate de browser sau dispozitiv pentru a face navigarea mai eficienta si pentru a pastra anumite preferinte sau sesiuni.',
          bullets: [
            'Pot ajuta la personalizarea setarilor, pastrarea preferintelor si functionarea serviciilor online.',
            'Pot oferi statistici despre utilizarea site-ului si pot imbunatati experienta de navigare.',
            'Cookie-urile nu sunt programe software si nu pot accesa direct fisierele utilizatorului.',
          ],
        ),
        _DocumentSection(
          title: 'Tipuri de cookie-uri',
          body:
              'Politica distinge intre cookie-uri de sesiune, cookie-uri persistente si cookie-uri plasate de terti.',
          bullets: [
            'Cookie-urile de sesiune exista temporar, pana la inchiderea sesiunii sau browserului.',
            'Cookie-urile persistente raman pentru o durata stabilita si pot fi sterse din setarile browserului.',
            'Cookie-urile tertilor pot proveni de la servicii precum Google, Facebook sau LinkedIn, in functie de continutul integrat.',
          ],
        ),
        _DocumentSection(
          title: 'Folosire in aplicatie',
          body:
              'Aplicatia foloseste cookie-ul de sesiune al portalului doar pentru autentificare si pentru cereri directe catre portalul Apa Ilfov in numele utilizatorului autentificat.',
          bullets: [
            'Cookie-ul de sesiune este transmis doar catre domeniul portalului Apa Ilfov.',
            'Aplicatia nu include module proprii de publicitate sau urmarire.',
            'Utilizatorul poate sterge sesiunea prin Deconectare.',
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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

  const _NativeDocument({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sections,
  });
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

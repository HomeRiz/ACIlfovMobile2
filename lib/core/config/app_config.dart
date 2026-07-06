// ===========================================================================
//  app_config.dart  =  SETARILE CENTRALE ALE APLICATIEI
// ---------------------------------------------------------------------------
//  Un singur loc pentru adrese (URL-uri), culori si "steaguri" de functii.
//  Daca se schimba o adresa a portalului, o modifici DOAR aici.
// ===========================================================================

// De UNDE isi ia aplicatia datele. Aici e "comutatorul" cerut: schimbi o
// singura valoare (mai jos, AppConfig.dataSource) si toata aplicatia trece pe
// noua sursa, fara sa modifici ecranele.
//   mock   = date de test (pentru dezvoltare / vizualizare ecrane)
//   cookie = date REALE extrase din portal folosind sesiunea de dupa login
//            (solutia de acum, pana exista API oficial)
//   api    = API-ul oficial ACIlfov (VIITOR - tranzitia ideala)
enum DataSource { mock, cookie, api }

class AppConfig {
  AppConfig._(); // clasa nu se instantiaza (doar valori statice)

  // ======================================================================
  //  >>> SINGURA LINIE PE CARE O SCHIMBI CAND APARE API-UL <<<
  //  Azi:   DataSource.mock   (sau .cookie pentru date reale prin sesiune)
  //  Maine: DataSource.api    (dupa ce ACIlfov publica API-ul)
  // ======================================================================
  static const DataSource dataSource = DataSource.cookie;

  // Adevarat cand folosim API-ul oficial. Derivat automat din dataSource, ca
  // sa nu existe doua setari care se pot contrazice.
  static bool get hasApi => dataSource == DataSource.api;

  // Adresele portalului oficial ACIlfov (folosite de ecranul de login WebView
  // si de sursa "cookie").
  static const String portalUrl =
      'https://acilfov.emsys.ro/self_utilities/';
  static const String authUrl =
      'https://acilfov.emsys.ro/self_utilities/oui/cl/index.html';

  // ----------------------------------------------------------------------
  //  API-ul REST intern al portalului EMSYS (folosit de sursa "cookie").
  //  Aceleasi endpoint-uri pe care le foloseste si integrarea Home Assistant
  //  (proiectul ACIlfovHA). Nu e un API "oficial", ci cel apelat de aplicatia
  //  web a portalului; il reutilizam cu sesiunea de login (cookie).
  // ----------------------------------------------------------------------
  static const String emsysRestBase =
      'https://acilfov.emsys.ro/self_utilities/rest/self';

  // Detalii contract (titular, stare, adresa). GET, doar cookie.
  static const String emsysContract =
      '$emsysRestBase/contract/getListaCodClientContracte';
  // Sold curent. GET ?codClient=..&nrContract=.. -> intoarce un numar (text).
  static const String emsysSold = '$emsysRestBase/facturi/getSoldClient';
  // Perioada de transmitere index. GET ?codClient=..
  static const String emsysIndexPeriod =
      '$emsysRestBase/transmitere/verificaPerioada';
  // Istoric consum / ultimul index. POST (pattern EMSYS LOAD_RECORDS).
  static const String emsysConsum = '$emsysRestBase/consum/Consums';
  // Punctele de consum valide (locatii) ale clientului. GET ?codClient&nrContract
  static const String emsysPuncteConsum =
      '$emsysRestBase/consum/getPuncteConsumValide';
  // Contoarele unei locatii. GET ?idLocatie=..&startDate=..
  static const String emsysContoare = '$emsysRestBase/consum/getContoare';
  // Istoric plati. POST (pattern EMSYS LOAD_RECORDS).
  static const String emsysPlati = '$emsysRestBase/plati/Platis';
  // Transmitere index (scriere). POST — payload de verificat din Network tab.
  static const String emsysTransmitere =
      '$emsysRestBase/transmitere/Transmiteres';
  // Lista facturi (presupus dupa pattern-ul EMSYS; de verificat din Network).
  static const String emsysFacturi = '$emsysRestBase/facturi/Facturis';

  // VIITOR: adresa de baza a API-ului ACIlfov (exemplu ipotetic).
  // Se completeaza cu adresa reala cand ACIlfov publica API-ul.
  static const String apiBaseUrl = 'https://acilfov.emsys.ro/api/v1';

  // Culoarea principala din branding (albastrul ACIlfov).
  static const int brandColor = 0xFF335C80;
}

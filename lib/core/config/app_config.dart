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

  // ======================================================================
  //  INTRERUPATOR PENTRU MODUL REVIEW / DEMO
  //  Tine-apasat pe logo-ul din ecranul de login intra in aplicatie cu date
  //  generate (fara cont real), pentru cine vrea sa vada functionalitatea
  //  fara sa aiba un cont ACIlfov. Pune pe `false` ca sa scoti complet acest
  //  punct de intrare din build (nu doar sa-l ascunzi) - o singura linie.
  // ======================================================================
  static const bool reviewDemoEnabled = true;

  // Adresele portalului oficial ACIlfov (folosite de ecranul de login WebView
  // si de sursa "cookie").
  static const String portalUrl = 'https://acilfov.emsys.ro/self_utilities/';
  static const String authUrl =
      'https://acilfov.emsys.ro/self_utilities/oui/cl/index.html';

  // Pagini publice oficiale ACIlfov, folosite in ecranul Info. Continutul este
  // incarcat direct din sursa oficiala, ca sa ramana identic cu ACIlfov.ro.
  static const String officialSiteUrl = 'https://acilfov.ro/';
  static const String officialLicensingUrl =
      'https://acilfov.ro/despre-noi/certificari-si-licentiere/';
  static const String officialTermsUrl =
      'https://acilfov.ro/termeni-si-conditii/';
  static const String officialCookiePolicyUrl =
      'https://acilfov.ro/politica-de-cookie/';
  static const String officialGdprFormUrl =
      'https://acilfov.ro/wp-content/uploads/2026/06/Formular-GDPR-AIF_23062026.pdf';
  static const String officialCustomerPortalUrl =
      'https://acilfov.emsys.ro/CUSTOMER_PORTAL/login.jsp';

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
  // Transmitere index (lista contoare pentru pagina de transmitere).
  static const String emsysTransmitere =
      '$emsysRestBase/transmitere/Transmiteres';
  // Lista facturi, confirmata din controllerul portalului.
  static const String emsysFacturi = '$emsysRestBase/facturi/Facturis';
  // Informatii cont: istoricul operatiilor/cererilor pe cont.
  static const String emsysInformatiiCont =
      '$emsysRestBase/informatiiCont/InformatiiConts';
  // Contact / trimitere mesaj companie.
  static const String emsysContactCodClients =
      '$emsysRestBase/contact/codClients';
  static const String emsysContactMessageLength =
      '$emsysRestBase/contact/getLungimeMesaj';
  static const String emsysContactMotives = '$emsysRestBase/contact/motives';
  static const String emsysContactSubjects = '$emsysRestBase/contact/subiectes';
  static const String emsysContactSend = '$emsysRestBase/contact/sendMessage';
  static const String emsysInfoSession = '$emsysRestBase/infoSession';
  // Utilizator portal.
  static const String emsysChangePassword =
      '$emsysRestBase/portaluserobj/changePassword';
  static const String emsysDeleteAccount =
      '$emsysRestBase/portaluserobj/stergereCont';
  // Actualizare date cont / contracte.
  static const String emsysAddClientContract =
      '$emsysRestBase/contract/addClientContract';
  static const String emsysAddContract = '$emsysRestBase/contract/addContract';
  static const String emsysDeleteClientCode =
      '$emsysRestBase/contract/deleteCodClient';
  static const String emsysClientCodesWithoutContracts =
      '$emsysRestBase/contract/getListaCodClientCuContracteNeintroduse';
  static const String emsysContractsWithoutClient =
      '$emsysRestBase/contract/getListaContracteNeintroduse';
  // Configurari factura electronica si alerte.
  static const String emsysConfiguriBase = '$emsysRestBase/cofiguri';
  static const String emsysInvoiceDeliveryConfigs =
      '$emsysConfiguriBase/Configuris';
  static const String emsysActivateInvoiceDelivery =
      '$emsysConfiguriBase/activare';
  static const String emsysDeactivateInvoiceDelivery =
      '$emsysConfiguriBase/dialogDezactiveaza';
  static const String emsysSmsConfig = '$emsysConfiguriBase/smsConfig';
  static const String emsysAlertConfigs =
      '$emsysRestBase/configAlerte/ConfigAlertes';
  static const String emsysAlertConfig =
      '$emsysRestBase/configAlerte/ConfigAlerte';
  static const String emsysCompanyNotifications =
      '$emsysRestBase/configAlerte/primireNotif';
  static const String emsysModifyCompanyNotifications =
      '$emsysRestBase/configAlerte/modifyPrimireNotif';
  // Transmitere index (scriere confirmata din controllerul portalului).
  static const String emsysTransmiterePuncte =
      '$emsysRestBase/transmitere/puncteConsums';
  static const String emsysTransmitereAdd = '$emsysRestBase/transmitere/add';

  // VIITOR: adresa de baza a API-ului ACIlfov (exemplu ipotetic).
  // Se completeaza cu adresa reala cand ACIlfov publica API-ul.
  static const String apiBaseUrl = 'https://acilfov.emsys.ro/api/v1';

  // Culoarea principala din branding (albastrul ACIlfov).
  static const int brandColor = 0xFF335C80;
}

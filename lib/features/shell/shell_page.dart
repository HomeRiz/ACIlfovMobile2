// ===========================================================================
//  shell_page.dart  =  TOATE PAGINILE DIN MENIU
// ---------------------------------------------------------------------------
//  Fiecare valoare = o pagina accesibila din meniul hamburger. Ca sa adaugi
//  o pagina noua in viitor: adaugi o valoare aici, o intrare in lista de meniu
//  (home_shell.dart) si un caz in _bodyFor (home_shell.dart). Atat.
// ===========================================================================

enum ShellPage {
  home, // Acasa
  invoices, // Istoric facturi
  indexPage, // Transmitere index
  consumption, // Istoric consum
  payments, // Istoric plati
  alerts, // Alerte si notificari (+ factura electronica)
  updateData, // Actualizare date cont
  sendMessage, // Trimitere mesaj
  accountInfo, // Informatii cont si contact
  settings, // Configurari
}

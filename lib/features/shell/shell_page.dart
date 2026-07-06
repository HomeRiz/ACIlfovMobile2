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
  chart, // Grafic consum
  payments, // Istoric plati
  updateData, // Actualizare date cont
  settings, // Configurari
  changePassword, // Schimbare parola
  contact, // Contact / trimitere mesaj
  accountInfo, // Informatii cont
  deleteAccount, // Stergere cont
  info, // Info
}

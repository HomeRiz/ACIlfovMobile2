// ===========================================================================
//  consumption_point.dart  =  MODELUL "PUNCT DE CONSUM"
// ---------------------------------------------------------------------------
//  Un punct de consum (locatie) al clientului: adresa + contoarele lui.
//  Vine din endpoint-ul EMSYS /consum/getPuncteConsumValide (+ /getContoare).
//  Ecranul "Istoric consum" foloseste aceste puncte pentru filtre.
// ===========================================================================

class ConsumptionPoint {
  final String idLocatie;   // id-ul locatiei (necesar la interogarea consumului)
  final String clientName;  // titularul (denClient)
  final String address;     // adresa punctului de consum
  final List<String> meters; // seriile contoarelor de la aceasta locatie

  const ConsumptionPoint({
    required this.idLocatie,
    required this.clientName,
    required this.address,
    required this.meters,
  });
}

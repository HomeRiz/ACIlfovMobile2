// ===========================================================================
//  consumption_record.dart  =  MODELUL "CITIRE DE CONSUM" (un rand din istoric)
// ---------------------------------------------------------------------------
//  Un rand din istoricul de consum, exact ca pe portalul web:
//   Contor, Data consum, Index vechi, Index nou, Consum (diferenta),
//   Tip consum, Factura, Data emitere.
//  Vine din endpoint-ul EMSYS /consum/Consums.
// ===========================================================================

class ConsumptionRecord {
  final String contor;
  final DateTime? dataConsum;
  final int indexVechi;
  final int indexNou;
  final int diferenta;    // consumul (indexNou - indexVechi)
  final String tipConsum; // ex: "CITIRE", "MONTARE CT."
  final String factura;   // numarul facturii asociate (poate fi gol)
  final DateTime? dataEmitere;

  const ConsumptionRecord({
    required this.contor,
    required this.dataConsum,
    required this.indexVechi,
    required this.indexNou,
    required this.diferenta,
    required this.tipConsum,
    required this.factura,
    required this.dataEmitere,
  });
}

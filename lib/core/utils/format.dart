// ===========================================================================
//  format.dart  =  MICI AJUTOARE DE FORMATARE (fara librarii externe)
// ---------------------------------------------------------------------------
//  Transforma numere si date in text prietenos pentru afisare.
// ===========================================================================

// Suma in lei, cu doua zecimale. Ex: 87.5 -> "87.50 lei".
String ron(double value) => '${value.toStringAsFixed(2)} lei';

// Data in format zi.luna.an. Ex: "05.07.2026".
String dmy(DateTime d) =>
    '${_two(d.day)}.${_two(d.month)}.${d.year}';

// Data si ora. Ex: "05.07.2026, 09:00".
String dmyHm(DateTime d) => '${dmy(d)}, ${hm(d)}';

// Doar ora. Ex: "09:05".
String hm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

String _two(int n) => n.toString().padLeft(2, '0');

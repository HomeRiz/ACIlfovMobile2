// ===========================================================================
//  meter_index.dart  =  MODELUL "INDEX CONTOR + PERIOADA DE TRANSMITERE"
// ===========================================================================

class MeterIndex {
  final int? lastValue;         // ultimul index citit / transmis
  final DateTime? lastReadDate; // cand a fost transmis ultima data
  final DateTime windowStart;   // inceputul perioadei de transmitere
  final DateTime windowEnd;     // sfarsitul perioadei de transmitere

  const MeterIndex({
    required this.lastValue,
    required this.lastReadDate,
    required this.windowStart,
    required this.windowEnd,
  });

  // Suntem in perioada de transmitere a indexului?
  // Regula ACIlfov: de pe 25 pana la finalul lunii (ambele capete INCLUSIV).
  // Comparam pe zile (fara ora), ca ziua de 25 si ultima zi sa intre in perioada.
  bool get isWindowOpen {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(_dateOnly(windowStart)) &&
        !today.isAfter(_dateOnly(windowEnd));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  factory MeterIndex.fromJson(Map<String, dynamic> json) => MeterIndex(
        lastValue: json['last_value'] as int?,
        lastReadDate: json['last_read_date'] != null
            ? DateTime.parse(json['last_read_date'] as String)
            : null,
        windowStart: DateTime.parse(json['window_start'] as String),
        windowEnd: DateTime.parse(json['window_end'] as String),
      );
}

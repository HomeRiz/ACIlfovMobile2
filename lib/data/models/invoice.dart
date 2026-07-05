// ===========================================================================
//  invoice.dart  =  MODELUL "FACTURA"
// ===========================================================================

class Invoice {
  final String id;
  final String number;      // seria / numarul facturii
  final DateTime issueDate; // data emiterii
  final DateTime dueDate;   // data scadentei
  final double amount;      // suma totala
  final bool paid;          // platita sau nu

  const Invoice({
    required this.id,
    required this.number,
    required this.issueDate,
    required this.dueDate,
    required this.amount,
    required this.paid,
  });

  // Factura este scadenta? (neplatita + a trecut data scadentei)
  bool get isOverdue => !paid && DateTime.now().isAfter(dueDate);

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id']?.toString() ?? '',
        number: json['number'] as String? ?? '',
        issueDate: DateTime.parse(json['issue_date'] as String),
        dueDate: DateTime.parse(json['due_date'] as String),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        paid: json['paid'] as bool? ?? false,
      );
}

class PaymentRecord {
  final String id;
  final DateTime? paymentDate;
  final double amount;
  final String document;
  final String method;

  const PaymentRecord({
    required this.id,
    required this.paymentDate,
    required this.amount,
    required this.document,
    required this.method,
  });
}

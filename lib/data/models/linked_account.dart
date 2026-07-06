class LinkedAccount {
  final String clientCode;
  final String contractNumber;
  final String holderName;
  final String address;
  final Map<String, dynamic> raw;

  const LinkedAccount({
    required this.clientCode,
    required this.contractNumber,
    required this.holderName,
    required this.address,
    this.raw = const {},
  });
}

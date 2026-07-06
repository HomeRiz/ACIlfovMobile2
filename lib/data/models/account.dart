// ===========================================================================
//  account.dart  =  MODELUL "CONT CLIENT"
// ---------------------------------------------------------------------------
//  Un "model" este forma datelor: ce campuri are un cont de client.
//  Este independent de sursa - la fel arata fie ca vine din date de test,
//  din portal (cookie) sau din API.
// ===========================================================================

class Account {
  final String holderName; // numele titularului
  final String clientCode; // codul de client
  final String? contractNumber; // nr. contract, daca portalul/API-ul il ofera
  final String address; // adresa locului de consum
  final double balance; // soldul curent (negativ = de plata)

  const Account({
    required this.holderName,
    required this.clientCode,
    this.contractNumber,
    required this.address,
    required this.balance,
  });

  // Construieste un Account dintr-un JSON (folosit de sursa API).
  factory Account.fromJson(Map<String, dynamic> json) => Account(
        holderName: json['holder_name'] as String? ?? '',
        clientCode: json['client_code'] as String? ?? '',
        contractNumber: _optionalString(json, [
          'contract_number',
          'nr_contract',
          'nrContract',
          'numarContract',
          'contract',
        ]),
        address: json['address'] as String? ?? '',
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
      );

  static String? _optionalString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && '$value'.trim().isNotEmpty) {
        return '$value'.trim();
      }
    }
    return null;
  }
}

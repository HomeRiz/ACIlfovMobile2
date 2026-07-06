// ===========================================================================
//  account_activity.dart  =  MODELUL "OPERATIE CONT"
// ---------------------------------------------------------------------------
//  Un rand din pagina "Informatii cont" a portalului: operatii precum
//  inregistrare index, trimitere mesaj companie, adaugare cont client,
//  activare factura pe email etc.
// ===========================================================================

class AccountActivity {
  final String id;
  final String clientCode;
  final String contractNumber;
  final String operation;
  final String alert;
  final String email;
  final DateTime? operationDate;

  const AccountActivity({
    required this.id,
    required this.clientCode,
    required this.contractNumber,
    required this.operation,
    required this.alert,
    required this.email,
    required this.operationDate,
  });
}

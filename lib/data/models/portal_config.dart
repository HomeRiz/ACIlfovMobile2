class InvoiceDeliveryConfig {
  final String mode;
  final String destination;
  final DateTime? operationDate;
  final Map<String, dynamic> raw;

  const InvoiceDeliveryConfig({
    required this.mode,
    required this.destination,
    this.operationDate,
    this.raw = const {},
  });
}

class AlertConfig {
  final String code;
  final String label;
  final bool active;
  final String? email;
  final String? phone;
  final bool emailAllowed;
  final bool smsAllowed;
  final Map<String, dynamic> raw;

  const AlertConfig({
    required this.code,
    required this.label,
    required this.active,
    this.email,
    this.phone,
    this.emailAllowed = true,
    this.smsAllowed = true,
    this.raw = const {},
  });

  AlertConfig copyWith({
    bool? active,
    String? email,
    String? phone,
  }) {
    return AlertConfig(
      code: code,
      label: label,
      active: active ?? this.active,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emailAllowed: emailAllowed,
      smsAllowed: smsAllowed,
      raw: raw,
    );
  }

  // Copie in care emailul si telefonul iau EXACT valorile primite. Spre
  // deosebire de copyWith, aici `null` chiar sterge valoarea veche - de asta e
  // nevoie cand userul goleste campul din dialogul de alerte.
  AlertConfig withContacts({
    required bool active,
    required String? email,
    required String? phone,
  }) {
    return AlertConfig(
      code: code,
      label: label,
      active: active,
      email: email,
      phone: phone,
      emailAllowed: emailAllowed,
      smsAllowed: smsAllowed,
      raw: raw,
    );
  }
}

class CompanyNotificationConfig {
  final bool emailAccepted;
  final bool smsAccepted;
  final String? phone;
  final Map<String, dynamic> raw;

  const CompanyNotificationConfig({
    required this.emailAccepted,
    required this.smsAccepted,
    this.phone,
    this.raw = const {},
  });

  CompanyNotificationConfig copyWith({
    bool? emailAccepted,
    bool? smsAccepted,
    String? phone,
  }) {
    return CompanyNotificationConfig(
      emailAccepted: emailAccepted ?? this.emailAccepted,
      smsAccepted: smsAccepted ?? this.smsAccepted,
      phone: phone ?? this.phone,
      raw: raw,
    );
  }

  // Copie in care telefonul ia EXACT valoarea primita (`null` chiar sterge).
  CompanyNotificationConfig withPhone(String? phone) {
    return CompanyNotificationConfig(
      emailAccepted: emailAccepted,
      smsAccepted: smsAccepted,
      phone: phone,
      raw: raw,
    );
  }
}

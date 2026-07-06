class ContactOption {
  final String id;
  final String label;

  const ContactOption({
    required this.id,
    required this.label,
  });
}

class ContactOptions {
  final List<String> clientCodes;
  final List<ContactOption> motives;
  final List<ContactOption> subjects;
  final int minimumMessageLength;
  final String? defaultContactValue;

  const ContactOptions({
    required this.clientCodes,
    required this.motives,
    required this.subjects,
    required this.minimumMessageLength,
    this.defaultContactValue,
  });
}

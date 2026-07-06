import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/contact_option.dart';
import '../../data/repositories/aci_repository.dart';

class SendMessageView extends StatefulWidget {
  const SendMessageView({super.key});

  @override
  State<SendMessageView> createState() => _SendMessageViewState();
}

class _SendMessageViewState extends State<SendMessageView> {
  Future<ContactOptions>? _optionsFuture;
  String? _clientCode;
  ContactOption? _motive;
  ContactOption? _subject;
  String _contactMethod = 'EMAIL';
  bool _sending = false;

  final _body = TextEditingController();
  final _contactValue = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _optionsFuture ??= context.read<ACIRepository>().getContactOptions();
  }

  @override
  void dispose() {
    _body.dispose();
    _contactValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContactOptions>(
      future: _optionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _errorState(snapshot.error.toString());
        }
        final options = snapshot.data;
        if (options == null) {
          return _errorState('Nu am primit optiunile formularului.');
        }
        _applyDefaults(options);
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _clientCode,
                decoration: const InputDecoration(
                  labelText: 'Client',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final c in options.clientCodes)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged:
                    _sending ? null : (v) => setState(() => _clientCode = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ContactOption>(
                initialValue: _motive,
                decoration: const InputDecoration(
                  labelText: 'Motiv',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final o in options.motives)
                    DropdownMenuItem(value: o, child: Text(o.label)),
                ],
                onChanged: _sending ? null : (v) => setState(() => _motive = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ContactOption>(
                initialValue: _subject,
                decoration: const InputDecoration(
                  labelText: 'Subiect',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final o in options.subjects)
                    DropdownMenuItem(value: o, child: Text(o.label)),
                ],
                onChanged:
                    _sending ? null : (v) => setState(() => _subject = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                minLines: 7,
                maxLines: 10,
                enabled: !_sending,
                decoration: InputDecoration(
                  labelText: 'Continut',
                  helperText: 'Minim ${options.minimumMessageLength} caractere',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _contactMethod,
                decoration: const InputDecoration(
                  labelText: 'Va rog contactati-ma prin',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
                  DropdownMenuItem(value: 'TELEFON', child: Text('Telefon')),
                ],
                onChanged: _sending
                    ? null
                    : (v) => setState(() => _contactMethod = v ?? 'EMAIL'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contactValue,
                enabled: !_sending,
                keyboardType: _contactMethod == 'EMAIL'
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                decoration: InputDecoration(
                  labelText: _contactMethod == 'EMAIL' ? 'Email' : 'Telefon',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _sending ? null : () => _send(options),
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_sending ? 'Se trimite...' : 'Trimite'),
              ),
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFF335C80)),
                title: const Text('Telefon'),
                subtitle: const Text('0374 / 205 200'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () =>
                    _launchExternal(Uri(scheme: 'tel', path: '0374205200')),
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Color(0xFF335C80)),
                title: const Text('E-mail'),
                subtitle: const Text('contact@acilfov.ro'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _launchExternal(
                  Uri(scheme: 'mailto', path: 'contact@acilfov.ro'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.public, color: Color(0xFF335C80)),
                title: const Text('Website'),
                subtitle: const Text('www.acilfov.ro'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _launchExternal(
                  Uri.parse('https://www.acilfov.ro/'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'In intervalul orar 17:00-07:30, Call Center-ul va prelua exclusiv sesizari privind avarii la reteaua publica de apa si canalizare.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyDefaults(ContactOptions options) {
    _clientCode ??=
        options.clientCodes.isNotEmpty ? options.clientCodes.first : null;
    _motive ??= options.motives.isNotEmpty ? options.motives.first : null;
    _subject ??= options.subjects.isNotEmpty ? options.subjects.first : null;
    if (_contactValue.text.isEmpty && options.defaultContactValue != null) {
      _contactValue.text = options.defaultContactValue!;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _optionsFuture = context.read<ACIRepository>().getContactOptions();
      _clientCode = null;
      _motive = null;
      _subject = null;
    });
    await _optionsFuture;
  }

  Future<void> _send(ContactOptions options) async {
    final client = _clientCode;
    final motive = _motive;
    final subject = _subject;
    final body = _body.text.trim();
    final contactValue = _contactValue.text.trim();
    if (client == null ||
        motive == null ||
        subject == null ||
        body.length < options.minimumMessageLength ||
        contactValue.isEmpty) {
      _snack(
          'Completeaza clientul, motivul, subiectul, continutul si metoda de contactare.');
      return;
    }
    setState(() => _sending = true);
    try {
      await context.read<ACIRepository>().sendContactMessage(
            clientCode: client,
            motive: motive,
            subject: subject,
            contactMethod: _contactMethod,
            contactValue: contactValue,
            message: body,
          );
      _body.clear();
      if (mounted) _snack('Mesajul a fost trimis.');
    } catch (e) {
      if (mounted) _snack(_cleanError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _errorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 42),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Reincarca'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _launchExternal(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _snack('Nu am putut deschide aplicatia externa.');
    }
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
}

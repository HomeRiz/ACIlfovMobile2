// ===========================================================================
//  send_message_view.dart  =  PAGINA "TRIMITERE MESAJ"
// ---------------------------------------------------------------------------
//  Formular de contact aliniat cu portalul: Client, Motiv, Subiect, Continut,
//  metoda de contactare si atasament. Trimiterea ramane dezactivata pana cand
//  validam payload-ul real al portalului.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/account_provider.dart';

class SendMessageView extends StatefulWidget {
  const SendMessageView({super.key});

  @override
  State<SendMessageView> createState() => _SendMessageViewState();
}

class _SendMessageViewState extends State<SendMessageView> {
  String? _motive;
  String _contactMethod = 'Email';
  final _client = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  final _contactValue = TextEditingController();
  final _attachment = TextEditingController();

  @override
  void dispose() {
    _client.dispose();
    _subject.dispose();
    _body.dispose();
    _contactValue.dispose();
    _attachment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>().account;
    if (_client.text.isEmpty && account != null) {
      _client.text = account.clientCode;
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _client,
          decoration: const InputDecoration(
            labelText: 'Client',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _motive,
          decoration: const InputDecoration(
            labelText: 'Motiv',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Sesizare', child: Text('Sesizare')),
            DropdownMenuItem(value: 'Solicitare', child: Text('Solicitare')),
            DropdownMenuItem(value: 'Informatii', child: Text('Informatii')),
            DropdownMenuItem(value: 'Altele', child: Text('Altele')),
          ],
          onChanged: (v) => setState(() => _motive = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _subject,
          decoration: const InputDecoration(
            labelText: 'Subiect',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _body,
          minLines: 7,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: 'Continut',
            helperText: 'Minim 20 caractere',
            border: OutlineInputBorder(),
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
            DropdownMenuItem(value: 'Email', child: Text('Email')),
            DropdownMenuItem(value: 'Telefon', child: Text('Telefon')),
          ],
          onChanged: (v) => setState(() => _contactMethod = v ?? 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contactValue,
          keyboardType: _contactMethod == 'Email'
              ? TextInputType.emailAddress
              : TextInputType.phone,
          decoration: InputDecoration(
            labelText: _contactMethod == 'Email' ? 'Email' : 'Telefon',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _attachment,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Atasament',
            border: const OutlineInputBorder(),
            suffixIcon: TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Incarcarea atasamentelor se activeaza dupa validarea API-ului.'),
                ),
              ),
              child: const Text('Browse...'),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _send,
          icon: const Icon(Icons.send),
          label: const Text('Trimite'),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.phone, color: Color(0xFF335C80)),
          title: Text('Telefon'),
          subtitle: Text('0374 / 205 200'),
        ),
        const ListTile(
          leading: Icon(Icons.email, color: Color(0xFF335C80)),
          title: Text('E-mail'),
          subtitle: Text('contact@acilfov.ro'),
        ),
        const ListTile(
          leading: Icon(Icons.public, color: Color(0xFF335C80)),
          title: Text('Website'),
          subtitle: Text('www.acilfov.ro'),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'În intervalul orar 17:00–07:30, Call Center-ul va prelua exclusiv sesizări privind avarii la rețeaua publică de apă și canalizare (ex. lipsă apă, refulări ale canalizarii, neconformități ale aspectului apei).',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _send() {
    if (_client.text.trim().isEmpty ||
        _motive == null ||
        _subject.text.trim().isEmpty ||
        _body.text.trim().length < 20 ||
        _contactValue.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completeaza clientul, motivul, subiectul, continutul si metoda de contactare.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Trimiterea mesajului necesita validarea endpoint-ului real din portal.'),
      ),
    );
  }
}

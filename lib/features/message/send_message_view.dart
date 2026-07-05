// ===========================================================================
//  send_message_view.dart  =  PAGINA "TRIMITERE MESAJ"
// ---------------------------------------------------------------------------
//  Formular simplu (subiect + mesaj) pentru a contacta ACIlfov. ACUM trimiterea
//  este simulata; cand exista API, mesajul se va trimite catre ACIlfov.
// ===========================================================================

import 'package:flutter/material.dart';

class SendMessageView extends StatefulWidget {
  const SendMessageView({super.key});

  @override
  State<SendMessageView> createState() => _SendMessageViewState();
}

class _SendMessageViewState extends State<SendMessageView> {
  final _subject = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Mesaj',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _send,
          icon: const Icon(Icons.send),
          label: const Text('Trimite mesajul'),
        ),
      ],
    );
  }

  void _send() {
    if (_subject.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completeaza subiectul si mesajul.')),
      );
      return;
    }
    _subject.clear();
    _body.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Mesajul va fi trimis catre ACIlfov cand API-ul va fi disponibil.'),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _current,
          obscureText: _obscure,
          decoration: _decoration('Parola curenta'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _next,
          obscureText: _obscure,
          decoration: _decoration('Parola noua'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirm,
          obscureText: _obscure,
          decoration: _decoration('Confirma parola noua'),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _validateOnly,
          icon: const Icon(Icons.lock_reset),
          label: const Text('Schimbare Parola'),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show' : 'Hide',
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      );

  void _validateOnly() {
    final current = _current.text.trim();
    final next = _next.text.trim();
    final confirm = _confirm.text.trim();
    final message = current.isEmpty || next.isEmpty || confirm.isEmpty
        ? 'Completeaza toate campurile.'
        : next != confirm
            ? 'Parola noua si confirmarea nu coincid.'
            : 'Schimbarea parolei necesita validarea endpoint-ului real din portal.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

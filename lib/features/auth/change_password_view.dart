import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/aci_repository.dart';

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
  bool _saving = false;

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
          enabled: !_saving,
          decoration: _decoration('Parola curenta'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _next,
          obscureText: _obscure,
          enabled: !_saving,
          decoration: _decoration('Parola noua'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirm,
          obscureText: _obscure,
          enabled: !_saving,
          decoration: _decoration('Confirma parola noua'),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : _changePassword,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_reset),
          label: Text(_saving ? 'Se salveaza...' : 'Schimbare Parola'),
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
          onPressed: _saving ? null : () => setState(() => _obscure = !_obscure),
        ),
      );

  Future<void> _changePassword() async {
    final current = _current.text.trim();
    final next = _next.text.trim();
    final confirm = _confirm.text.trim();
    final validation = current.isEmpty || next.isEmpty || confirm.isEmpty
        ? 'Completeaza toate campurile.'
        : next != confirm
            ? 'Parola noua si confirmarea nu coincid.'
            : current == next
                ? 'Parola noua trebuie sa fie diferita de parola curenta.'
                : null;
    if (validation != null) {
      _snack(validation);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<ACIRepository>().changePassword(
            currentPassword: current,
            newPassword: next,
          );
      _current.clear();
      _next.clear();
      _confirm.clear();
      if (mounted) _snack('Parola a fost schimbata.');
    } catch (e) {
      if (mounted) _snack(_cleanError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/aci_repository.dart';
import '../../state/auth_provider.dart';

class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({super.key});

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirmare',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF335C80),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Sunteti sigur ca doriti sa stergeti contul? Aceasta operatie va sterge toate datele legate de acest cont din portal.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _deleting ? null : _confirmDelete,
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text(_deleting ? 'Se sterge...' : 'Da'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _deleting ? null : () => Navigator.maybePop(context),
                child: const Text('Nu'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final repo = context.read<ACIRepository>();
    final auth = context.read<AuthProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stergere cont'),
        content: const Text(
          'Confirmi stergerea contului din portalul ACIlfov?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nu'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Da'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      await repo.deletePortalAccount();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Informare'),
          content: const Text('Contul a fost sters.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) await auth.logout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_cleanError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
}

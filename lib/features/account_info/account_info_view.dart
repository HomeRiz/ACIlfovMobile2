// ===========================================================================
//  account_info_view.dart  =  PAGINA "INFORMATII CONT SI CONTACT"
// ---------------------------------------------------------------------------
//  Datele contului tau + datele de contact ale ACIlfov (telefon, e-mail, web).
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/account_provider.dart';

class AccountInfoView extends StatelessWidget {
  const AccountInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, p, _) {
        final acc = p.account;
        return ListView(
          children: [
            const _Header('Contul meu'),
            if (acc != null) ...[
              _Info(Icons.person, 'Titular', acc.holderName),
              _Info(Icons.badge, 'Cod client', acc.clientCode),
              _Info(Icons.location_on, 'Adresa', acc.address),
            ] else
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Se incarca...'),
              ),
            const Divider(),
            const _Header('Contact ACIlfov'),
            // Datele de contact reale se completeaza aici.
            const _Info(Icons.phone, 'Telefon', '021 / xxx xx xx'),
            const _Info(Icons.email, 'E-mail', 'contact@acilfov.ro'),
            const _Info(Icons.public, 'Website', 'www.acilfov.ro'),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Completeaza datele de contact reale ale ACIlfov in acest ecran.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF335C80))),
      );
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Info(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: const Color(0xFF335C80)),
        title: Text(label),
        subtitle: Text(value),
      );
}

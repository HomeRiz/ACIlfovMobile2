// ===========================================================================
//  home_view.dart  =  PAGINA "ACASA" (sold + dale de actiuni)
// ---------------------------------------------------------------------------
//  Afiseaza soldul curent si dalele rapide din portal. Fiecare dala comuta pe pagina
//  corespunzatoare din meniu (prin functia onNavigate).
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format.dart';
import '../../state/account_provider.dart';
import '../shell/shell_page.dart';

class HomeView extends StatelessWidget {
  // Functie primita de la ecranul principal, ca sa comute pe alta pagina.
  final void Function(ShellPage) onNavigate;

  const HomeView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, p, _) {
        return RefreshIndicator(
          onRefresh: p.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _soldCard(p),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  _tile(Icons.speed, 'Transmitere index',
                      () => onNavigate(ShellPage.indexPage)),
                  _tile(Icons.notifications_active, 'Alerte si notificari',
                      () => onNavigate(ShellPage.settings)),
                  _tile(Icons.edit_note, 'Actualizare date',
                      () => onNavigate(ShellPage.updateData)),
                  _tile(Icons.mail_outline, 'Trimite mesaj',
                      () => onNavigate(ShellPage.contact)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Cardul cu soldul curent.
  Widget _soldCard(AccountProvider p) {
    if (p.loading && p.account == null) {
      return const Card(
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final acc = p.account;
    final balance = acc?.balance ?? 0;
    final due = balance < 0;
    return Card(
      color: due ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sold curent',
                style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              ron(balance.abs()),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: due ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(due ? 'De plata' : 'La zi',
                style: TextStyle(color: due ? Colors.red : Colors.green)),
            if (acc != null) ...[
              const SizedBox(height: 12),
              Text(acc.holderName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(acc.clientCode,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  // O "dala" patrata cu iconita + text, care porneste o actiune.
  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: const Color(0xFF335C80)),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

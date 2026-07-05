// ===========================================================================
//  payments_view.dart  =  PAGINA "ISTORIC PLATI"
// ---------------------------------------------------------------------------
//  Afiseaza facturile deja platite ca istoric de plati. Foloseste aceleasi
//  date ca "Istoric facturi", filtrate dupa cele platite.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format.dart';
import '../../state/account_provider.dart';

class PaymentsView extends StatelessWidget {
  const PaymentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, p, _) {
        if (p.loading && p.invoices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final paid = p.invoices.where((i) => i.paid).toList();
        if (paid.isEmpty) {
          return const Center(child: Text('Nu exista plati inregistrate.'));
        }
        return RefreshIndicator(
          onRefresh: p.load,
          child: ListView.separated(
            itemCount: paid.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final inv = paid[i];
              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(inv.number),
                subtitle: Text('Achitata • Scadenta: ${dmy(inv.dueDate)}'),
                trailing: Text(ron(inv.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        );
      },
    );
  }
}

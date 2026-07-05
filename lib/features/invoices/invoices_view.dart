// ===========================================================================
//  invoices_view.dart  =  PAGINA "ISTORIC FACTURI"
// ---------------------------------------------------------------------------
//  Lista facturilor, cu stare (platita / neplatita / scadenta) si suma.
//  Este continut afisat in ecranul principal (nu are bara proprie).
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format.dart';
import '../../state/account_provider.dart';

class InvoicesView extends StatelessWidget {
  const InvoicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, p, _) {
        if (p.loading && p.invoices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (p.invoices.isEmpty) {
          return const Center(child: Text('Nu exista facturi.'));
        }
        return RefreshIndicator(
          onRefresh: p.load,
          child: ListView.separated(
            itemCount: p.invoices.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final inv = p.invoices[i];
              final color = inv.paid
                  ? Colors.green
                  : (inv.isOverdue ? Colors.red : Colors.orange);
              final status = inv.paid
                  ? 'Platita'
                  : (inv.isOverdue ? 'Scadenta' : 'Neplatita');
              return ListTile(
                leading: Icon(Icons.receipt_long, color: color),
                title: Text(inv.number),
                subtitle: Text(
                    'Emisa: ${dmy(inv.issueDate)}  •  Scadenta: ${dmy(inv.dueDate)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(ron(inv.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(status, style: TextStyle(color: color, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

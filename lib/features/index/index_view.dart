// ===========================================================================
//  index_view.dart  =  PAGINA "TRANSMITERE INDEX"
// ---------------------------------------------------------------------------
//  Arata perioada de transmitere, ultimul index si un camp pentru a trimite
//  un index nou. Campul si butonul sunt active DOAR cand perioada e deschisa.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format.dart';
import '../../state/account_provider.dart';

class IndexView extends StatefulWidget {
  const IndexView({super.key});

  @override
  State<IndexView> createState() => _IndexViewState();
}

class _IndexViewState extends State<IndexView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, p, _) {
        final mi = p.meterIndex;
        if (p.loading && mi == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (mi == null) {
          return const Center(child: Text('Indexul nu este disponibil.'));
        }
        final open = mi.isWindowOpen;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: open ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              child: ListTile(
                isThreeLine: true,
                leading: Icon(open ? Icons.check_circle : Icons.schedule,
                    color: open ? Colors.green : Colors.orange),
                title: Text(
                    open ? 'Perioada este deschisa' : 'Perioada este inchisa'),
                subtitle: Text(
                  'Indexul se transmite de pe 25 pana la finalul lunii.\n'
                  'Interval: ${dmy(mi.windowStart)} - ${dmy(mi.windowEnd)}',
                ),
              ),
            ),
            if (mi.lastValue != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('Ultimul index: ${mi.lastValue}'),
                  subtitle: mi.lastReadDate != null
                      ? Text('Transmis pe ${dmy(mi.lastReadDate!)}')
                      : null,
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Index nou',
                // O singura rubrica: aceeasi valoare merge si la "verificare index".
                helperText: 'Aceeasi valoare se trimite si la verificarea indexului.',
                border: OutlineInputBorder(),
              ),
              enabled: open,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: open ? () => _submit(p) : null,
              icon: const Icon(Icons.send),
              label: const Text('Trimite index'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit(AccountProvider p) async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introdu un numar valid.')),
      );
      return;
    }
    try {
      await p.submitIndex(value);
      if (!mounted) return;
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Index trimis.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nu am putut trimite indexul: $e')),
      );
    }
  }
}

// ===========================================================================
//  index_view.dart  =  PAGINA "TRANSMITERE INDEX"
// ---------------------------------------------------------------------------
//  Arata perioada de transmitere, ultimul index si un camp pentru a trimite
//  un index nou. Campul si butonul sunt active DOAR cand perioada e deschisa.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format.dart';
import '../../data/models/consumption_point.dart';
import '../../data/repositories/aci_repository.dart';
import '../../state/account_provider.dart';

class IndexView extends StatefulWidget {
  const IndexView({super.key});

  @override
  State<IndexView> createState() => _IndexViewState();
}

class _IndexViewState extends State<IndexView> {
  final _controller = TextEditingController();
  List<ConsumptionPoint> _points = [];
  String? _pointError;
  bool _loadingPoints = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPoints());
  }

  Future<void> _loadPoints() async {
    try {
      final points = await context.read<ACIRepository>().getConsumptionPoints();
      if (!mounted) return;
      setState(() {
        _points = points;
        _loadingPoints = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pointError = '$e';
        _loadingPoints = false;
      });
    }
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(open ? Icons.check_circle : Icons.schedule,
                        color: open ? Colors.green : Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        open
                            ? 'Va aflati in perioada de transmitere a indexului.'
                            : 'Nu va aflati in perioada de transmitere a indexului, transmiterea indexului se face dupa data de ${mi.windowStart.day} ale fiecarei luni!',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _pointSection(mi.lastValue, mi.lastReadDate),
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

  Widget _pointSection(int? lastValue, DateTime? lastReadDate) {
    if (_loadingPoints) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pointError != null) {
      return Text('Nu am putut incarca punctul de consum: $_pointError',
          style: const TextStyle(color: Colors.red));
    }
    final point = _points.isNotEmpty ? _points.first : null;
    final meter = point?.meters.isNotEmpty == true ? point!.meters.first : '-';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _kv('Punct Consum', point?.address.isNotEmpty == true ? point!.address : '-'),
            _kv('Contor', meter),
            _kv('Index anterior', lastValue?.toString() ?? '-'),
            _kv('Data citirii anterioare', lastReadDate == null ? '-' : dmy(lastReadDate)),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 148, child: Text(label, style: const TextStyle(color: Colors.black54))),
            Expanded(child: Text(value)),
          ],
        ),
      );

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

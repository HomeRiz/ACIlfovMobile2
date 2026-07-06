import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format.dart';
import '../../state/account_provider.dart';

class InvoicesView extends StatefulWidget {
  const InvoicesView({super.key});

  @override
  State<InvoicesView> createState() => _InvoicesViewState();
}

class _InvoicesViewState extends State<InvoicesView> {
  late DateTime _start;
  late DateTime _end;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    _start = DateTime(now.year, now.month - 24, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, p, _) {
        final invoices = p.invoices
            .where((i) => !i.issueDate.isBefore(_start) && !i.issueDate.isAfter(_end))
            .toList();
        final overdue = invoices.where((i) => !i.paid && i.isOverdue).fold<double>(0, (s, i) => s + i.amount);
        final due = invoices.where((i) => !i.paid).fold<double>(0, (s, i) => s + i.amount);
        return Column(
          children: [
            _filters(p, due, overdue),
            const Divider(height: 1),
            Expanded(
              child: p.loading && p.invoices.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _list(invoices),
            ),
          ],
        );
      },
    );
  }

  Widget _filters(AccountProvider p, double due, double overdue) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('Perioda'),
          Row(
            children: [
              Expanded(child: _dateField('De la', _start, () => _pickDate(start: true))),
              const SizedBox(width: 8),
              Expanded(child: _dateField('Pana la', _end, () => _pickDate(start: false))),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summary('Sold Client', ron((p.account?.balance ?? 0).abs())),
              _summary('Facturi Scadente', ron(overdue)),
              _summary('Plati In Procesare', ron(0)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: const Text('Toate'),
                selected: true,
                onSelected: (_) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Extinde'),
                selected: _expanded,
                onSelected: (v) => setState(() => _expanded = v),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: due > 0 ? () {} : null,
                child: Text('Platesc : ${due.toStringAsFixed(2)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _list(List invoices) {
    if (invoices.isEmpty) return const Center(child: Text('No data'));
    return RefreshIndicator(
      onRefresh: context.read<AccountProvider>().load,
      child: ListView.separated(
        itemCount: invoices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final inv = invoices[i];
          final color = inv.paid ? Colors.green : (inv.isOverdue ? Colors.red : Colors.orange);
          final status = inv.paid ? 'Platita' : (inv.isOverdue ? 'Scadenta' : 'Neplatita');
          return ListTile(
            leading: Icon(Icons.receipt_long, color: color),
            title: Text(inv.number.isEmpty ? 'Factura' : inv.number),
            subtitle: Text('Emisa: ${dmy(inv.issueDate)}  •  Scadenta: ${dmy(inv.dueDate)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(ron(inv.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(status, style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
            isThreeLine: _expanded,
          );
        },
      ),
    );
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(dmy(value)),
      ),
    );
  }

  Widget _summary(String label, String value) => InputChip(
        label: Text('$label: $value'),
        onPressed: () {},
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF335C80))),
      );
}

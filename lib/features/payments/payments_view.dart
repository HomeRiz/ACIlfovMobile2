import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format.dart';
import '../../core/widgets/failsafe_error_state.dart';
import '../../data/models/payment_record.dart';
import '../../data/repositories/aci_repository.dart';

class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  late DateTime _start;
  late DateTime _end;
  bool _loading = true;
  String? _error;
  List<PaymentRecord> _payments = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    _start = DateTime(now.year, now.month - 6, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payments = await context
          .read<ACIRepository>()
          .getPayments(start: _start, end: _end);
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _filters(),
        const Divider(height: 1),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Perioda',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF335C80))),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                  child: _dateField(
                      'De la', _start, () => _pickDate(start: true))),
              const SizedBox(width: 8),
              Expanded(
                  child: _dateField(
                      'Pana la', _end, () => _pickDate(start: false))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return FailsafeErrorState(error: _error, onReload: _load);
    }
    if (_payments.isEmpty) return const Center(child: Text('No data'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _payments.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = _payments[i];
          return ListTile(
            leading: const Icon(Icons.payments, color: Color(0xFF335C80)),
            title: Text(p.document.isEmpty ? 'Plata' : p.document),
            subtitle: Text([
              if (p.paymentDate != null) 'Data plata: ${dmy(p.paymentDate!)}',
              if (p.method.isNotEmpty) p.method,
            ].join(' • ')),
            trailing: Text(ron(p.amount),
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
    await _load();
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
}

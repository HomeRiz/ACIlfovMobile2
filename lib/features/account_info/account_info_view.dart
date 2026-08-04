// ===========================================================================
//  account_info_view.dart  =  PAGINA "INFORMATII CONT"
// ---------------------------------------------------------------------------
//  Structura portalului: perioada + istoricul operatiilor/cererilor pe cont.
//  Datele vin din /rest/self/informatiiCont/InformatiiConts.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format.dart';
import '../../core/widgets/failsafe_error_state.dart';
import '../../data/models/account_activity.dart';
import '../../data/repositories/aci_repository.dart';

class AccountInfoView extends StatefulWidget {
  const AccountInfoView({super.key});

  @override
  State<AccountInfoView> createState() => _AccountInfoViewState();
}

class _AccountInfoViewState extends State<AccountInfoView> {
  late DateTime _start;
  late DateTime _end;
  Future<List<AccountActivity>>? _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    _start = _end.subtract(const Duration(days: 180));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<AccountActivity>> _load() {
    return context.read<ACIRepository>().getAccountActivities(
          start: _start,
          end: _end,
        );
  }

  void _reload() {
    // Corpul lui setState trebuie sa fie un BLOC: cu `=>` closure-ul returneaza
    // Future-ul si Flutter opreste ecranul cu eroare rosie.
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          const _Header('Perioda'),
          Row(
            children: [
              Expanded(
                child:
                    _dateField('De la', _start, () => _pickDate(start: true)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child:
                    _dateField('Pana la', _end, () => _pickDate(start: false)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<AccountActivity>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SizedBox(
                  height: 260,
                  child: FailsafeErrorState(
                    error: snapshot.error,
                    onReload: _reload,
                  ),
                );
              }
              final activities = snapshot.data ?? const <AccountActivity>[];
              if (activities.isEmpty) {
                return const _MessageCard(
                  icon: Icons.info_outline,
                  text: 'Nu exista operatii pentru perioada selectata.',
                );
              }
              return Column(
                children: [
                  for (final activity in activities)
                    _OperationCard(activity: activity),
                ],
              );
            },
          ),
        ],
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
    if (_start.isAfter(_end)) {
      setState(() {
        final tmp = _start;
        _start = _end;
        _end = tmp;
      });
    }
    _reload();
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

class _Header extends StatelessWidget {
  final String text;

  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF335C80),
          ),
        ),
      );
}

class _OperationCard extends StatelessWidget {
  final AccountActivity activity;

  const _OperationCard({required this.activity});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _row('Cod client', activity.clientCode),
              _row('Contract', activity.contractNumber),
              _row('Operatie', activity.operation),
              _row('Alerta', activity.alert),
              _row('Email', activity.email),
              _row('Nr. Operatie', activity.id),
              _row(
                'Data Operatie',
                activity.operationDate == null
                    ? '-'
                    : dmy(activity.operationDate!),
              ),
            ],
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(label, style: const TextStyle(color: Colors.black54)),
            ),
            Expanded(child: Text(value.trim().isEmpty ? '-' : value.trim())),
          ],
        ),
      );
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MessageCard({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF335C80)),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

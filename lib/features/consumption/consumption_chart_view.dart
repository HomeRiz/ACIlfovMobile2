import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format.dart';
import '../../core/widgets/failsafe_error_state.dart';
import '../../data/models/consumption_point.dart';
import '../../data/models/consumption_record.dart';
import '../../data/repositories/aci_repository.dart';

class ConsumptionChartView extends StatefulWidget {
  const ConsumptionChartView({super.key});

  @override
  State<ConsumptionChartView> createState() => _ConsumptionChartViewState();
}

class _ConsumptionChartViewState extends State<ConsumptionChartView> {
  late DateTime _start;
  late DateTime _end;
  bool _loading = true;
  String? _error;
  List<ConsumptionPoint> _points = [];
  String? _idLocatie;
  List<ConsumptionRecord> _records = [];

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
      final repo = context.read<ACIRepository>();
      final points = await repo.getConsumptionPoints();
      final id =
          _idLocatie ?? (points.isNotEmpty ? points.first.idLocatie : null);
      ConsumptionPoint? point;
      for (final p in points) {
        if (p.idLocatie == id) {
          point = p;
          break;
        }
      }
      final meter =
          point?.meters.isNotEmpty == true ? point!.meters.first : null;
      final records = id != null && meter != null
          ? await repo.getConsumption(
              idLocatie: id,
              contor: meter,
              start: _start,
              end: _end,
            )
          : const <ConsumptionRecord>[];
      if (!mounted) return;
      setState(() {
        _points = points;
        _idLocatie = id;
        _records = records;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PortalLabel('Perioda'),
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
              const SizedBox(height: 12),
              const _PortalLabel('Punct Consum'),
              DropdownButtonFormField<String>(
                initialValue: _idLocatie,
                isExpanded: true,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), isDense: true),
                items: [
                  for (final p in _points)
                    DropdownMenuItem(
                      value: p.idLocatie,
                      child: Text(p.address.isEmpty
                          ? 'Locatie ${p.idLocatie}'
                          : p.address),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _idLocatie = v);
                  _load();
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return FailsafeErrorState(error: _error, onReload: _load);
    }
    if (_records.isEmpty) {
      return const Center(
          child: Text('Nu exista consum pentru perioada selectata.'));
    }
    final maxValue =
        _records.map((r) => r.diferenta).fold<int>(1, (a, b) => b > a ? b : a);
    final records = _records.take(12).toList().reversed.toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final r in records)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                    width: 86,
                    child:
                        Text(r.dataConsum == null ? '-' : dmy(r.dataConsum!))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxValue == 0 ? 0 : r.diferenta / maxValue,
                      minHeight: 18,
                      backgroundColor: const Color(0xFFE6EDF3),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF335C80)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 52, child: Text('${r.diferenta} mc')),
              ],
            ),
          ),
      ],
    );
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

class _PortalLabel extends StatelessWidget {
  final String text;
  const _PortalLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF335C80)),
        ),
      );
}

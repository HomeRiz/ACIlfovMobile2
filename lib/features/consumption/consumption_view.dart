// ===========================================================================
//  consumption_view.dart  =  PAGINA "ISTORIC CONSUM"
// ---------------------------------------------------------------------------
//  Ca pe portalul oficial:
//   - Perioada (data de inceput + data de sfarsit)
//   - Punct consum (locatia) + adresa punctului
//   - Contor (util cand ai mai multe contoare)
//   - Cautarea se face AUTOMAT cand schimbi perioada / punctul / contorul.
//
//  Rezultatele arata, exact ca pe web: Contor, Data consum, Index vechi,
//  Index nou, Consum, Tip consum, Factura, Data emitere.
//
//  Datele vin ACUM din repository (sursa reala prin cookie): punctele din
//  /consum/getPuncteConsumValide + /getContoare, iar citirile din /consum/Consums.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format.dart';
import '../../data/models/consumption_point.dart';
import '../../data/models/consumption_record.dart';
import '../../data/repositories/aci_repository.dart';

class ConsumptionView extends StatefulWidget {
  const ConsumptionView({super.key});

  @override
  State<ConsumptionView> createState() => _ConsumptionViewState();
}

class _ConsumptionViewState extends State<ConsumptionView> {
  ACIRepository? _repo;

  // Perioada selectata.
  late DateTime _start;
  late DateTime _end;

  // Punctele de consum + selectiile curente.
  bool _loadingPoints = true;
  String? _pointsError;
  List<ConsumptionPoint> _points = [];
  String? _idLocatie; // locatia selectata
  String? _contor; // contorul selectat

  // Rezultatele (citirile de consum).
  bool _loadingRecords = false;
  String? _recordsError;
  List<ConsumptionRecord> _records = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    _start = DateTime(now.year, now.month - 6, now.day); // ultimele ~6 luni
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPoints());
  }

  ConsumptionPoint? get _selectedPoint {
    for (final p in _points) {
      if (p.idLocatie == _idLocatie) return p;
    }
    return null;
  }

  // Incarca punctele de consum ale clientului si porneste prima cautare.
  Future<void> _loadPoints() async {
    _repo ??= context.read<ACIRepository>();
    setState(() {
      _loadingPoints = true;
      _pointsError = null;
    });
    try {
      final points = await _repo!.getConsumptionPoints();
      if (!mounted) return;
      setState(() {
        _points = points;
        if (points.isNotEmpty) {
          _idLocatie = points.first.idLocatie;
          _contor = points.first.meters.isNotEmpty
              ? points.first.meters.first
              : null;
        }
        _loadingPoints = false;
      });
      await _search();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pointsError = '$e';
        _loadingPoints = false;
      });
    }
  }

  // Cauta citirile pentru locatia + contorul + perioada curente.
  Future<void> _search() async {
    final loc = _idLocatie;
    final contor = _contor;
    if (loc == null || contor == null) {
      setState(() => _records = const []);
      return;
    }
    setState(() {
      _loadingRecords = true;
      _recordsError = null;
    });
    try {
      final recs = await (_repo ??= context.read<ACIRepository>())
          .getConsumption(
        idLocatie: loc,
        contor: contor,
        start: _start,
        end: _end,
      );
      if (!mounted) return;
      setState(() {
        _records = recs;
        _loadingRecords = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recordsError = '$e';
        _records = const [];
        _loadingRecords = false;
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
    if (picked != null) {
      setState(() {
        if (start) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
      _search();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _filters(),
        const Divider(height: 1),
        Expanded(child: _resultsList()),
      ],
    );
  }

  // ------------------------------------------------------------- filtre sus
  Widget _filters() {
    final meters = _selectedPoint?.meters ?? const <String>[];
    final address = _selectedPoint?.address ?? '';
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Perioada',
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
          const SizedBox(height: 12),
          const Text('Punct consum',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF335C80))),
          const SizedBox(height: 6),
          if (_loadingPoints)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text('Se incarca punctele de consum...'),
              ]),
            )
          else if (_pointsError != null)
            Text('Nu am putut incarca punctele: $_pointsError',
                style: const TextStyle(color: Colors.red))
          else
            DropdownButtonFormField<String>(
              initialValue: _idLocatie,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: [
                for (final p in _points)
                  DropdownMenuItem(
                    value: p.idLocatie,
                    child: Text(
                      p.address.isNotEmpty
                          ? p.address
                          : 'Locatie ${p.idLocatie}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _idLocatie = v;
                  final m = _selectedPoint?.meters ?? const <String>[];
                  _contor = m.isNotEmpty ? m.first : null;
                });
                _search();
              },
            ),
          if (address.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(address,
                  style:
                      const TextStyle(color: Colors.black54, fontSize: 12)),
            ),
          const SizedBox(height: 12),
          const Text('Contor',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF335C80))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _contor,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: [
              for (final c in meters)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _contor = v);
              _search();
            },
          ),
        ],
      ),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(dmy(value)),
      ),
    );
  }

  // -------------------------------------------------------------- rezultate
  Widget _resultsList() {
    if (_loadingRecords) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recordsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Nu am putut incarca citirile: $_recordsError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_records.isEmpty) {
      return const Center(
          child: Text('Nu exista citiri in perioada selectata.'));
    }
    return RefreshIndicator(
      onRefresh: _search,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        itemCount: _records.length,
        itemBuilder: (context, i) {
          final r = _records[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('Contor', r.contor, strong: true),
                  _kv('Data consum',
                      r.dataConsum == null ? '-' : dmy(r.dataConsum!)),
                  _kv('Index vechi', '${r.indexVechi}'),
                  _kv('Index nou', '${r.indexNou}'),
                  _kv('Consum', '${r.diferenta} mc'),
                  _kv('Tip consum', r.tipConsum.isEmpty ? '-' : r.tipConsum),
                  _kv('Factura', r.factura.trim().isEmpty ? '-' : r.factura),
                  _kv('Data emitere',
                      r.dataEmitere == null ? '-' : dmy(r.dataEmitere!)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _kv(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:',
                style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight:
                        strong ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}

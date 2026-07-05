// ===========================================================================
//  consumption_view.dart  =  PAGINA "ISTORIC CONSUM"
// ---------------------------------------------------------------------------
//  Ca pe portalul oficial:
//   - Perioada (data de inceput + data de sfarsit)
//   - Punct consum = codul de client (util cand ai mai multi clienti pe cont)
//     + adresa punctului
//   - Contor (util cand esti firma si ai mai multe contoare)
//   - Cautarea se face AUTOMAT imediat ce schimbi perioada / punctul / contorul.
//
//  Rezultatele arata: Contor, Data consum, Index vechi, Index nou, Consum,
//  Tip consum, Factura, Data emitere.
//
//  ACUM datele sunt generate local (exemplu). Cand apare API-ul ACIlfov,
//  aceleasi filtre vor cere date reale (repository), fara sa schimbam ecranul.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format.dart';
import '../../state/account_provider.dart';

// Un punct de consum: adresa + contoarele lui.
class _PunctInfo {
  final String adresa;
  final List<String> contoare;
  const _PunctInfo({required this.adresa, required this.contoare});
}

// O citire de consum (un rand de rezultat).
class _Consum {
  final String contor;
  final DateTime dataConsum;
  final int indexVechi;
  final int indexNou;
  final int consum;
  final String tipConsum;
  final String factura;
  final DateTime? dataEmitere;

  const _Consum({
    required this.contor,
    required this.dataConsum,
    required this.indexVechi,
    required this.indexNou,
    required this.consum,
    required this.tipConsum,
    required this.factura,
    required this.dataEmitere,
  });
}

class ConsumptionView extends StatefulWidget {
  const ConsumptionView({super.key});

  @override
  State<ConsumptionView> createState() => _ConsumptionViewState();
}

class _ConsumptionViewState extends State<ConsumptionView> {
  late DateTime _start;
  late DateTime _end;
  String? _punct; // cod client selectat
  String? _contor; // contor selectat
  bool _seeded = false;

  final Map<String, _PunctInfo> _puncte = {};
  List<_Consum> _results = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    _start = DateTime(now.year, now.month - 6, now.day); // ultimele ~6 luni
  }

  // Prima data pregatim punctele de consum, pornind de la contul curent.
  void _seed(AccountProvider p) {
    if (_seeded) return;
    final acc = p.account;
    final cod = acc?.clientCode ?? '109346';
    final adr = acc?.address ?? 'JILAVA MORII, nr. 69 B';
    _puncte[cod] = _PunctInfo(adresa: adr, contoare: const ['60874265']);
    // Exemplu pentru firme / mai multe puncte (decomenteaza pentru test):
    // _puncte['200111'] = const _PunctInfo(
    //     adresa: 'Alt punct de consum', contoare: ['70123456', '70123457']);
    _punct = cod;
    _contor = _puncte[cod]!.contoare.first;
    _seeded = true;
    _results = _compute(); // fara setState: suntem in timpul build-ului
  }

  // Genereaza citirile lunare din perioada aleasa (functie pura, fara setState).
  List<_Consum> _compute() {
    final list = <_Consum>[];
    var d = DateTime(_start.year, _start.month, 1);
    var index = 500;
    while (!d.isAfter(_end)) {
      final consum = 8 + (d.month % 6); // exemplu variabil
      final vechi = index;
      final nou = index + consum;
      list.add(_Consum(
        contor: _contor ?? '',
        dataConsum: DateTime(d.year, d.month, 1),
        indexVechi: vechi,
        indexNou: nou,
        consum: consum,
        tipConsum: 'CITIRE',
        factura: '',
        dataEmitere: null,
      ));
      index = nou;
      d = DateTime(d.year, d.month + 1, 1);
    }
    return list.reversed.toList(); // cele mai noi sus
  }

  // Cautare automata din handlere (dupa alegerea datei / punctului / contorului).
  void _search() {
    setState(() => _results = _compute());
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
      _search(); // cautare automata dupa alegerea datei
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, p, _) {
        _seed(p);
        return Column(
          children: [
            _filters(),
            const Divider(height: 1),
            Expanded(child: _resultsList()),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------- filtre sus
  Widget _filters() {
    final contoare =
        _punct != null ? _puncte[_punct]!.contoare : const <String>[];
    final adresa = _punct != null ? _puncte[_punct]!.adresa : '';
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Perioada',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF335C80))),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _dateField('De la', _start, () => _pickDate(start: true))),
              const SizedBox(width: 8),
              Expanded(child: _dateField('Pana la', _end, () => _pickDate(start: false))),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Punct consum',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF335C80))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _punct,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: [
              for (final k in _puncte.keys)
                DropdownMenuItem(value: k, child: Text(k)),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _punct = v;
                _contor = _puncte[v]!.contoare.first;
              });
              _search();
            },
          ),
          if (adresa.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(adresa,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ),
          const SizedBox(height: 12),
          const Text('Contor',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF335C80))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _contor,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: [
              for (final c in contoare) DropdownMenuItem(value: c, child: Text(c)),
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
    if (_results.isEmpty) {
      return const Center(child: Text('Nu exista citiri in perioada selectata.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final r = _results[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Contor', r.contor, strong: true),
                _kv('Data consum', dmy(r.dataConsum)),
                _kv('Index vechi', '${r.indexVechi}'),
                _kv('Index nou', '${r.indexNou}'),
                _kv('Consum', '${r.consum} mc'),
                _kv('Tip consum', r.tipConsum),
                _kv('Factura', r.factura.isEmpty ? '-' : r.factura),
                _kv('Data emitere',
                    r.dataEmitere == null ? '-' : dmy(r.dataEmitere!)),
              ],
            ),
          ),
        );
      },
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
                    fontWeight: strong ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}

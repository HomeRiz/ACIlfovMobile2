// ===========================================================================
//  update_data_view.dart  =  PAGINA "ACTUALIZARE DATE CONT"
// ---------------------------------------------------------------------------
//  Ca pe portalul oficial: o LISTA de coduri de client, fiecare cu numele,
//  adresa si contractele asociate. Fiecare rand are o bifa (checkbox).
//
//  Bara de jos are trei actiuni:
//   - Sterge      -> sterge randurile bifate
//   - + Cod client-> deschide un dialog (Cod Client + Nr. Contract) si adauga
//                    un cod nou in lista
//   - + Contract  -> adauga un contract la codul de client BIFAT; daca nu e
//                    bifat niciunul, arata eroarea din portal
//
//  ACUM lista e gestionata local (in memorie), pornind de la contul curent.
//  Cand ACIlfov ofera API, aceleasi actiuni vor trimite/aduce date reale.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/account_provider.dart';

// Model local pentru un cod de client + contractele lui.
class _LinkedAccount {
  final String codClient;
  final String numeClient;
  final String adresa;
  final List<String> contracte;

  _LinkedAccount({
    required this.codClient,
    required this.numeClient,
    required this.adresa,
    List<String>? contracte,
  }) : contracte = contracte ?? [];
}

class UpdateDataView extends StatefulWidget {
  const UpdateDataView({super.key});

  @override
  State<UpdateDataView> createState() => _UpdateDataViewState();
}

class _UpdateDataViewState extends State<UpdateDataView> {
  final List<_LinkedAccount> _accounts = [];
  final Set<int> _selected = {};
  bool _seeded = false;

  // Prima data, pornim lista cu contul curent (din datele aplicatiei).
  void _seed(AccountProvider p) {
    if (_seeded) return;
    final acc = p.account;
    if (acc != null) {
      _accounts.add(_LinkedAccount(
        codClient: acc.clientCode,
        numeClient: acc.holderName,
        adresa: acc.address,
        contracte: ['C-0001'],
      ));
      _seeded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, p, _) {
        _seed(p);
        return Column(
          children: [
            Expanded(child: _accounts.isEmpty ? _emptyState() : _list()),
            _toolbar(),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------- lista
  Widget _list() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      itemCount: _accounts.length,
      itemBuilder: (context, i) {
        final a = _accounts[i];
        final selected = _selected.contains(i);
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _toggle(i),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (_) => _toggle(i),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cod client: ${a.codClient}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Nume: ${a.numeClient}'),
                        Text('Adresa: ${a.adresa}',
                            style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 8),
                        if (a.contracte.isEmpty)
                          const Text('Fara contracte',
                              style: TextStyle(
                                  color: Colors.black45,
                                  fontStyle: FontStyle.italic))
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final c in a.contracte)
                                Chip(
                                  label: Text('Contract $c'),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined, size: 64, color: Color(0xFF335C80)),
            SizedBox(height: 16),
            Text(
              'Nu ai niciun cod de client adaugat.\n'
              'Apasa "+ Cod client" ca sa adaugi unul.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------- bara jos
  Widget _toolbar() {
    final hasSelection = _selected.isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x22000000))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasSelection ? _deleteSelected : null,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Sterge'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _addCodClient,
                icon: const Icon(Icons.person_add_alt, size: 20),
                label: const Text('Cod client'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _addContract,
                icon: const Icon(Icons.note_add_outlined, size: 20),
                label: const Text('Contract'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- actiuni
  void _toggle(int i) {
    setState(() {
      if (_selected.contains(i)) {
        _selected.remove(i);
      } else {
        _selected.add(i);
      }
    });
  }

  void _deleteSelected() {
    if (_selected.isEmpty) return;
    setState(() {
      // Stergem de la coada spre cap, ca sa nu se strice indicii.
      final indices = _selected.toList()..sort((a, b) => b.compareTo(a));
      for (final i in indices) {
        _accounts.removeAt(i);
      }
      _selected.clear();
    });
  }

  Future<void> _addCodClient() async {
    final cod = TextEditingController();
    final contract = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adauga cod client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cod,
              decoration: const InputDecoration(
                labelText: 'Cod Client',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contract,
              decoration: const InputDecoration(
                labelText: 'Nr. Contract',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuleaza')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Adauga')),
        ],
      ),
    );

    if (ok == true) {
      final c = cod.text.trim();
      final nr = contract.text.trim();
      if (c.isEmpty || nr.isEmpty) {
        _snack('Completeaza Cod Client si Nr. Contract.');
      } else {
        setState(() {
          _accounts.add(_LinkedAccount(
            codClient: c,
            numeClient: '(se completeaza din sistem)',
            adresa: '-',
            contracte: [nr],
          ));
        });
      }
    }
    cod.dispose();
    contract.dispose();
  }

  Future<void> _addContract() async {
    // Ca in portal: e nevoie de un cod de client BIFAT.
    if (_selected.isEmpty) {
      await _errorNoClient();
      return;
    }
    final idx = _selected.first;
    final contract = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adauga contract la ${_accounts[idx].codClient}'),
        content: TextField(
          controller: contract,
          decoration: const InputDecoration(
            labelText: 'Nr. Contract',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuleaza')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Adauga')),
        ],
      ),
    );
    if (ok == true) {
      final nr = contract.text.trim();
      if (nr.isNotEmpty) {
        setState(() => _accounts[idx].contracte.add(nr));
      }
    }
    contract.dispose();
  }

  Future<void> _errorNoClient() {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 40),
        title: const Text('Eroare'),
        content: const Text(
            'Nu exista Cod Client pentru care sa se actualizeze lista de Contracte.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

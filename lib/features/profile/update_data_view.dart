import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/failsafe_error_state.dart';
import '../../data/models/linked_account.dart';
import '../../data/repositories/aci_repository.dart';

class UpdateDataView extends StatefulWidget {
  const UpdateDataView({super.key});

  @override
  State<UpdateDataView> createState() => _UpdateDataViewState();
}

class _UpdateDataViewState extends State<UpdateDataView> {
  Future<List<LinkedAccount>>? _future;
  final Set<String> _selected = {};
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<ACIRepository>().getLinkedAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder<List<LinkedAccount>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _errorState(snapshot.error.toString());
              }
              final accounts = snapshot.data ?? const <LinkedAccount>[];
              if (accounts.isEmpty) return _emptyState();
              return RefreshIndicator(
                onRefresh: _reload,
                child: _list(accounts),
              );
            },
          ),
        ),
        _toolbar(),
      ],
    );
  }

  Widget _list(List<LinkedAccount> accounts) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      itemCount: accounts.length,
      itemBuilder: (context, i) {
        final a = accounts[i];
        final selected = _selected.contains(a.clientCode);
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _busy ? null : () => _toggle(a.clientCode),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: _busy ? null : (_) => _toggle(a.clientCode),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cod client: ${a.clientCode}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        if (a.holderName.isNotEmpty)
                          Text('Nume: ${a.holderName}'),
                        if (a.address.isNotEmpty)
                          Text(
                            'Adresa: ${a.address}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        if (a.contractNumber.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(a.contractNumber),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
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
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.badge_outlined, size: 64, color: Color(0xFF335C80)),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Nu ai niciun cod de client adaugat.\nApasa "+ Cod client" ca sa adaugi unul.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _errorState(String error) {
    return FailsafeErrorState(error: error, onReload: _reload);
  }

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
                onPressed: hasSelection && !_busy ? _deleteSelected : null,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Sterge'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _busy ? null : _addCodClient,
                icon: const Icon(Icons.person_add_alt, size: 20),
                label: const Text('Cod client'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _addContract,
                icon: const Icon(Icons.note_add_outlined, size: 20),
                label: const Text('Contract'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(String clientCode) {
    setState(() {
      if (_selected.contains(clientCode)) {
        _selected.remove(clientCode);
      } else {
        _selected.add(clientCode);
      }
    });
  }

  Future<void> _reload() async {
    setState(() {
      _selected.clear();
      _future = context.read<ACIRepository>().getLinkedAccounts();
    });
    await _future;
  }

  Future<void> _deleteSelected() async {
    final ok = await _confirm('Stergi codurile de client selectate?');
    if (!ok) return;
    await _run(
      () => context.read<ACIRepository>().deleteClientCodes(_selected.toList()),
      success: 'Codurile selectate au fost sterse.',
    );
  }

  Future<void> _addCodClient() async {
    final result = await _clientContractDialog('Adauga cod client');
    if (result == null) return;
    await _run(
      () => context.read<ACIRepository>().addClientContract(
            clientCode: result.clientCode,
            contractNumber: result.contractNumber,
          ),
      success: 'Codul de client a fost adaugat.',
    );
  }

  Future<void> _addContract() async {
    try {
      final repo = context.read<ACIRepository>();
      final clients = await repo.getClientCodesWithoutContracts();
      if (!mounted) return;
      if (clients.isEmpty) {
        await _errorNoClient();
        return;
      }
      final selectedClient = await _selectValue(
        title: 'Cod client',
        values: clients,
      );
      if (selectedClient == null) return;
      final contracts = await repo.getContractsWithoutClient(selectedClient);
      if (!mounted) return;
      final selectedContract = contracts.isEmpty
          ? await _textValue('Nr. Contract')
          : await _selectValue(title: 'Nr. Contract', values: contracts);
      if (selectedContract == null || selectedContract.trim().isEmpty) return;
      await _run(
        () => repo.addContract(
          clientCode: selectedClient,
          contractNumber: selectedContract.trim(),
        ),
        success: 'Contractul a fost adaugat.',
      );
    } catch (e) {
      if (mounted) _snack(_cleanError(e));
    }
  }

  Future<({String clientCode, String contractNumber})?> _clientContractDialog(
    String title,
  ) async {
    final cod = TextEditingController();
    final contract = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
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
            child: const Text('Anuleaza'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Adauga'),
          ),
        ],
      ),
    );
    final result = ok == true
        ? (clientCode: cod.text.trim(), contractNumber: contract.text.trim())
        : null;
    cod.dispose();
    contract.dispose();
    if (result == null) return null;
    if (result.clientCode.isEmpty || result.contractNumber.isEmpty) {
      _snack('Completeaza Cod Client si Nr. Contract.');
      return null;
    }
    return result;
  }

  Future<String?> _selectValue({
    required String title,
    required List<String> values,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          for (final v in values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, v),
              child: Text(v),
            ),
        ],
      ),
    );
  }

  Future<String?> _textValue(String title) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuleaza'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Adauga'),
          ),
        ],
      ),
    );
    final value = ok == true ? controller.text.trim() : null;
    controller.dispose();
    return value;
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmare'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Nu'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Da'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _errorNoClient() {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 40),
        title: const Text('Eroare'),
        content: const Text(
          'Nu exista Cod Client pentru care sa se actualizeze lista de Contracte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) _snack(success);
      await _reload();
    } catch (e) {
      if (mounted) _snack(_cleanError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
}

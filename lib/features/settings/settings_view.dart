// ===========================================================================
//  settings_view.dart  =  PAGINA "CONFIGURARI"
// ---------------------------------------------------------------------------
//  Structura portalului: Factura prin email/SMS + Alerte si notificari.
//  Actiunile sunt locale pana validam endpoint-urile de scriere.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../services/notification_service.dart';
import '../../state/account_provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _sendMode = 'Email';
  final _sendValue = TextEditingController();
  bool _accepted = false;
  bool _invoiceEmailActive = false;
  bool _invoiceAlert = true;
  bool _dueAlert = true;
  bool _indexAlert = true;

  @override
  void dispose() {
    _sendValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>().account;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Factura prin email/SMS'),
              Tab(text: 'Alerte si notificari'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _invoiceTab(account?.holderName ?? ''),
                _alertsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceTab(String holderName) {
    if (_sendValue.text.isEmpty && holderName.contains('@')) {
      _sendValue.text = holderName;
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _sendMode,
          decoration: const InputDecoration(
            labelText: 'Mod Trimitere',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Email', child: Text('Email')),
            DropdownMenuItem(value: 'SMS', child: Text('SMS')),
          ],
          onChanged: (v) => setState(() => _sendMode = v ?? 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sendValue,
          keyboardType: _sendMode == 'Email' ? TextInputType.emailAddress : TextInputType.phone,
          decoration: InputDecoration(
            labelText: _sendMode == 'Email' ? 'Adresa Mail' : 'Telefon',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _accepted,
          onChanged: (v) => setState(() => _accepted = v ?? false),
          title: const Text('Accept Conditii de activare factura*'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _accepted ? () => setState(() => _invoiceEmailActive = true) : null,
                child: const Text('Activeaza'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _invoiceEmailActive ? () => setState(() => _invoiceEmailActive = false) : null,
                child: const Text('Dezactiveaza'),
              ),
            ),
          ],
        ),
        const Divider(height: 32),
        _statusRow('Email', _sendValue.text.isEmpty ? '-' : _sendValue.text),
        _statusRow('Data Operatie', _invoiceEmailActive ? 'activ local' : '-'),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () => NotificationService.instance.showTest(),
          icon: const Icon(Icons.notifications_active),
          label: const Text('Trimite notificare de test'),
        ),
        const SizedBox(height: 16),
        Text('Sursa de date curenta: ${AppConfig.dataSource.name}',
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }

  Widget _alertsTab() {
    return ListView(
      children: [
        SwitchListTile(
          value: _invoiceAlert,
          onChanged: (v) => setState(() => _invoiceAlert = v),
          title: const Text('Activare alerta'),
          subtitle: const Text('ALERTA_EMITERE_FACTURA'),
        ),
        SwitchListTile(
          value: _dueAlert,
          onChanged: (v) => setState(() => _dueAlert = v),
          title: const Text('Activare alerta'),
          subtitle: const Text('ALERTA_SCADENTA_AUTOCIT'),
        ),
        SwitchListTile(
          value: _indexAlert,
          onChanged: (v) => setState(() => _indexAlert = v),
          title: const Text('Activare alerta'),
          subtitle: const Text('Perioada de transmitere index'),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Preferintele sunt pastrate local pana cand validam endpoint-urile de configurari ale portalului.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _statusRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.black54))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

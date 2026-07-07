import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format.dart';
import '../../core/widgets/failsafe_error_state.dart';
import '../../data/models/portal_config.dart';
import '../../data/repositories/aci_repository.dart';
import '../../services/notification_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _sendMode = 'EMAIL';
  final _sendValue = TextEditingController();
  final _companyPhone = TextEditingController();
  bool _accepted = false;
  bool _busy = false;
  Future<_SettingsData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void dispose() {
    _sendValue.dispose();
    _companyPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Factura prin email/SMS'),
              Tab(text: 'Notificari aplicatie'),
            ],
          ),
          Expanded(
            child: FutureBuilder<_SettingsData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _errorState(snapshot.error.toString());
                }
                final data = snapshot.data ?? const _SettingsData();
                _applyDefaults(data);
                return TabBarView(
                  children: [
                    _invoiceTab(data),
                    _alertsTab(data),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceTab(_SettingsData data) {
    final configs = data.invoiceConfigs;
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._warningCards(data.invoiceWarnings),
          DropdownButtonFormField<String>(
            initialValue: _sendMode,
            decoration: const InputDecoration(
              labelText: 'Mod Trimitere',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
              DropdownMenuItem(value: 'SMS', child: Text('SMS')),
            ],
            onChanged: _busy
                ? null
                : (v) {
                    setState(() {
                      _sendMode = v ?? 'EMAIL';
                      _future = _load();
                    });
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sendValue,
            enabled: !_busy,
            keyboardType: _sendMode == 'EMAIL'
                ? TextInputType.emailAddress
                : TextInputType.phone,
            decoration: InputDecoration(
              labelText: _sendMode == 'EMAIL' ? 'Adresa Mail' : 'Telefon',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _accepted,
            onChanged:
                _busy ? null : (v) => setState(() => _accepted = v ?? false),
            title: const Text('Accept Conditii de activare factura*'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _accepted && !_busy ? _activateInvoice : null,
                  child: Text(_busy ? 'Se salveaza...' : 'Activeaza'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: configs.isNotEmpty && !_busy
                      ? () => _deactivateInvoice(configs.first)
                      : null,
                  child: const Text('Dezactiveaza'),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          if (configs.isEmpty)
            const Text('Nu exista configurare activa pentru modul selectat.')
          else
            for (final config in configs)
              Card(
                child: ListTile(
                  leading: Icon(
                    _sendMode == 'EMAIL'
                        ? Icons.email_outlined
                        : Icons.sms_outlined,
                    color: const Color(0xFF335C80),
                  ),
                  title: Text(config.destination),
                  subtitle: Text(
                    config.operationDate == null
                        ? 'Data Operatie: -'
                        : 'Data Operatie: ${dmy(config.operationDate!)}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Dezactiveaza',
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _busy ? null : () => _deactivateInvoice(config),
                  ),
                ),
              ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => NotificationService.instance.showTest(),
            icon: const Icon(Icons.notifications_active),
            label: const Text('Trimite notificare de test'),
          ),
        ],
      ),
    );
  }

  Widget _alertsTab(_SettingsData data) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ..._warningCards(data.alertWarnings, horizontal: 16),
          for (final alert in data.alerts)
            SwitchListTile(
              value: alert.active,
              onChanged: _busy
                  ? null
                  : (v) => v
                      ? _activateAlert(alert)
                      : _saveAlert(alert.copyWith(active: false)),
              title: Text(_alertTitle(alert)),
              subtitle: Text(
                [
                  if ((alert.email ?? '').isNotEmpty) alert.email!,
                  if ((alert.phone ?? '').isNotEmpty) alert.phone!,
                ].join(' / '),
              ),
            ),
          const Divider(height: 24),
          SwitchListTile(
            value: data.companyNotification?.emailAccepted ?? false,
            onChanged: _busy
                ? null
                : (v) => _saveCompanyNotification(
                      (data.companyNotification ??
                              const CompanyNotificationConfig(
                                emailAccepted: false,
                                smsAccepted: false,
                              ))
                          .copyWith(emailAccepted: v),
                    ),
            title: const Text('Accept sa primesc e-mail'),
            subtitle: const Text('Notificari companie'),
          ),
          SwitchListTile(
            value: data.companyNotification?.smsAccepted ?? false,
            onChanged: _busy
                ? null
                : (v) => _saveCompanyNotification(
                      (data.companyNotification ??
                              const CompanyNotificationConfig(
                                emailAccepted: false,
                                smsAccepted: false,
                              ))
                          .copyWith(
                        smsAccepted: v,
                        phone: v ? _companyPhone.text.trim() : null,
                      ),
                    ),
            title: const Text('Accept sa primesc telefon'),
            subtitle: const Text('Notificari companie prin SMS'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _companyPhone,
              enabled:
                  !_busy && (data.companyNotification?.smsAccepted ?? false),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nr. telefon',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyDefaults(_SettingsData data) {
    if (_sendValue.text.isEmpty && data.invoiceConfigs.isNotEmpty) {
      _sendValue.text = data.invoiceConfigs.first.destination;
    }
    final phone = data.companyNotification?.phone;
    if (_companyPhone.text.isEmpty && phone != null) _companyPhone.text = phone;
  }

  Future<_SettingsData> _load() async {
    final repo = context.read<ACIRepository>();
    final invoiceWarnings = <String>[];
    final alertWarnings = <String>[];
    var invoiceConfigs = <InvoiceDeliveryConfig>[];
    var alerts = <AlertConfig>[];
    CompanyNotificationConfig? companyNotification;

    try {
      invoiceConfigs = await repo.getInvoiceDeliveryConfigs(_sendMode);
    } catch (e) {
      invoiceWarnings.add(
        'Configurarea facturii nu poate fi citita acum: ${SessionFailsafe.friendlyMessage(e)}',
      );
    }

    try {
      alerts = await repo.getAlertConfigs();
    } catch (e) {
      alertWarnings.add(
        'Alertele aplicatiei nu pot fi citite acum: ${SessionFailsafe.friendlyMessage(e)}',
      );
    }

    try {
      companyNotification = await repo.getCompanyNotificationConfig();
    } catch (e) {
      companyNotification = null;
      alertWarnings.add(
        'Preferintele de notificari companie nu pot fi citite acum: ${SessionFailsafe.friendlyMessage(e)}',
      );
    }
    return _SettingsData(
      invoiceConfigs: invoiceConfigs,
      alerts: alerts,
      companyNotification: companyNotification,
      invoiceWarnings: invoiceWarnings,
      alertWarnings: alertWarnings,
    );
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _activateInvoice() async {
    final destination = _sendValue.text.trim();
    if (destination.isEmpty) {
      _snack('Completeaza adresa sau telefonul.');
      return;
    }
    await _run(
      () => context.read<ACIRepository>().activateInvoiceDelivery(
            mode: _sendMode,
            destination: destination,
          ),
      success: 'Configurarea a fost activata.',
    );
    if (mounted) setState(() => _accepted = false);
  }

  Future<void> _deactivateInvoice(InvoiceDeliveryConfig config) async {
    final ok = await _confirm('Dezactivezi configurarea selectata?');
    if (!ok) return;
    await _run(
      () => context.read<ACIRepository>().deactivateInvoiceDelivery(
            mode: _sendMode,
            config: config,
          ),
      success: 'Configurarea a fost dezactivata.',
    );
  }

  Future<void> _saveAlert(AlertConfig config) async {
    await _run(
      () => context.read<ACIRepository>().saveAlertConfig(config),
      success: 'Alerta a fost salvata.',
    );
  }

  Future<void> _activateAlert(AlertConfig alert) async {
    final email = TextEditingController(text: alert.email ?? '');
    final phone = TextEditingController(text: alert.phone ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_alertTitle(alert)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alert.emailAllowed)
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Adresa email',
                  border: OutlineInputBorder(),
                ),
              ),
            if (alert.emailAllowed && alert.smsAllowed)
              const SizedBox(height: 12),
            if (alert.smsAllowed)
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nr. telefon',
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
            child: const Text('Salveaza'),
          ),
        ],
      ),
    );
    final updated = ok == true
        ? alert.copyWith(
            active: true,
            email: email.text.trim().isEmpty ? null : email.text.trim(),
            phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
          )
        : null;
    email.dispose();
    phone.dispose();
    if (updated == null) return;
    if ((updated.email ?? '').isEmpty && (updated.phone ?? '').isEmpty) {
      _snack('Completeaza emailul sau telefonul pentru alerta.');
      return;
    }
    await _saveAlert(updated);
  }

  Future<void> _saveCompanyNotification(
    CompanyNotificationConfig config,
  ) async {
    if (config.smsAccepted && (_companyPhone.text.trim().isEmpty)) {
      _snack('Completeaza numarul de telefon.');
      return;
    }
    await _run(
      () => context.read<ACIRepository>().saveCompanyNotificationConfig(
            config.copyWith(phone: _companyPhone.text.trim()),
          ),
      success: 'Preferintele au fost salvate.',
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

  Widget _errorState(String error) {
    return FailsafeErrorState(error: error, onReload: _reload);
  }

  List<Widget> _warningCards(List<String> warnings, {double horizontal = 0}) {
    if (warnings.isEmpty) return const [];
    return [
      for (final warning in warnings)
        Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 12),
          child: Card(
            color: Colors.orange.shade50,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade900,
                  ),
                  title: Text(warning),
                  subtitle: const Text(
                    'Daca serverul refuza accesul, restul aplicatiei ramane functional.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: () => SessionFailsafe.reloadOrLogout(
                        context,
                        error: warning,
                        onReload: _reload,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reincarca'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _alertTitle(AlertConfig alert) {
    final code = alert.code.toUpperCase();
    final label = alert.label.toUpperCase();
    if (code.contains('EMITERE_FACTURA') || label.contains('EMITERE')) {
      return 'Emitere factura';
    }
    if (code.contains('SCADENTA_AUTOCIT') || label.contains('AUTOCIT')) {
      return 'Scadenta autocitire';
    }
    if ((code.contains('INDEX') || label.contains('INDEX')) ||
        code.contains('TRANSMITERE')) {
      return 'Perioada trimitere index';
    }
    return _humanizeAlertText(alert.label.isEmpty ? alert.code : alert.label);
  }

  String _humanizeAlertText(String value) {
    final text = value
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
}

class _SettingsData {
  final List<InvoiceDeliveryConfig> invoiceConfigs;
  final List<AlertConfig> alerts;
  final CompanyNotificationConfig? companyNotification;
  final List<String> invoiceWarnings;
  final List<String> alertWarnings;

  const _SettingsData({
    this.invoiceConfigs = const [],
    this.alerts = const [],
    this.companyNotification,
    this.invoiceWarnings = const [],
    this.alertWarnings = const [],
  });
}

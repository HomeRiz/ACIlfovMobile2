// ===========================================================================
//  settings_view.dart  =  CONFIGURARI (un singur ecran, fara taburi)
// ---------------------------------------------------------------------------
//  Trei sectiuni, in ordinea in care ii pasa userului:
//
//   1. "Notificari pe telefon" - anunturi direct in aplicatie, fara email si
//      fara SMS. Astea sunt gratuite si ajung instant. Sunt setarile pe care
//      le controleaza chiar aplicatia.
//   2. "Factura de la Apa Ilfov" - unde iti trimite compania factura. Emailul
//      NU se mai scrie de mana: e cel cu care te-ai autentificat.
//   3. "Alerte si informari de la Apa Ilfov" - preferintele de pe serverul
//      companiei. Si aici emailul se completeaza singur.
//
//  ATENTIE (bug-uri reparate, a nu se reintroduce):
//   - `setState` trebuie sa primeasca un BLOC, nu `=>` cu o atribuire care
//     intoarce un Future: altfel Flutter opreste ecranul cu eroarea rosie.
//   - Valorile implicite ale campurilor de text se pun DUPA ce vin datele,
//     niciodata in timpul unui `build`.
//   - Cererile catre server se fac in PARALEL si un comutator apasat nu mai
//     blocheaza tot ecranul: reactia trebuie sa fie imediata.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/failsafe_error_state.dart';
import '../../data/models/portal_config.dart';
import '../../data/notification_prefs.dart';
import '../../data/repositories/aci_repository.dart';
import '../../services/background_sync.dart';
import '../../services/notification_service.dart';
import '../../state/account_provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _email = TextEditingController();
  final _phone = TextEditingController();

  Future<_SettingsData>? _future;
  _SettingsData? _data;

  // Preferintele locale (notificari pe telefon).
  NotificationPrefs _prefs =
      NotificationPrefsStore.cached ?? const NotificationPrefs();

  // Starea permisiunilor de notificare, ca sa avertizam doar cand chiar e cazul.
  NotificationDiagnostics? _notifications;

  // Ce randuri sunt in curs de salvare. Doar acelea se blocheaza - restul
  // ecranului ramane folosibil.
  final Set<String> _saving = {};

  // Valorile apasate acum, pana confirma serverul.
  final Map<String, bool> _pending = {};

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _refreshNotificationStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SettingsData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _data;
        if (data == null) {
          if (snapshot.hasError) {
            return FailsafeErrorState(
              error: snapshot.error.toString(),
              onReload: _reload,
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              ..._warningCards(data.warnings),
              _phoneSection(data),
              const SizedBox(height: 8),
              _invoiceSection(data),
              const SizedBox(height: 8),
              _alertsSection(data),
            ],
          ),
        );
      },
    );
  }

  // ============================================ 1. NOTIFICARI PE TELEFON
  Widget _phoneSection(_SettingsData data) {
    final blocked = _notifications != null && !_notifications!.permissionGranted;

    return _card(
      icon: Icons.notifications_active_outlined,
      title: 'Notificari pe telefon',
      subtitle: 'Ajung direct in aplicatie, gratuit, fara email si fara SMS.',
      children: [
        if (blocked) _permissionWarning(),
        _prefSwitch(
          title: 'Cand se emite o factura noua',
          subtitle: 'Aplicatia verifica singura, si cand e inchisa.',
          value: _prefs.newInvoice,
          onChanged: (v) => _savePrefs(_prefs.copyWith(newInvoice: v)),
        ),
        _prefSwitch(
          title: 'Inainte de scadenta facturii',
          subtitle: 'Cu 3 zile inainte, la ora 9:00.',
          value: _prefs.invoiceDue,
          onChanged: (v) => _savePrefs(_prefs.copyWith(invoiceDue: v)),
        ),
        _prefSwitch(
          title: 'Cand incepe perioada de index',
          subtitle: 'In prima zi in care poti transmite indexul.',
          value: _prefs.indexWindow,
          onChanged: (v) => _savePrefs(_prefs.copyWith(indexWindow: v)),
        ),
      ],
    );
  }

  Widget _permissionWarning() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.orange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Notificarile sunt oprite din setarile telefonului. '
                  'Pana le permiti, nu iti putem trimite nimic.',
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _requestPermissions,
                child: const Text('Permite'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================= 2. FACTURA DE LA APA ILFOV
  Widget _invoiceSection(_SettingsData data) {
    final byEmail = _pending['invoice:EMAIL'] ?? data.emailConfigs.isNotEmpty;

    return _card(
      icon: Icons.receipt_long_outlined,
      title: 'Factura de la Apa Ilfov',
      subtitle: 'Datele de contact sunt completate automat. '
          'Le poti schimba oricand.',
      children: [
        _contactField(
          controller: _email,
          label: 'Adresa de email',
          helper: data.email == null
              ? 'Scrie adresa pe care vrei sa primesti factura.'
              : 'Completata automat din contul cu care te-ai autentificat.',
          keyboardType: TextInputType.emailAddress,
        ),
        _serverSwitch(
          key: 'invoice:EMAIL',
          title: 'Primesc factura pe email',
          subtitle: 'Documentul fiscal, trimis de Apa Ilfov.',
          value: byEmail,
          onChanged: (v) =>
              _toggleInvoiceDelivery('EMAIL', v, _email.text.trim(), data),
        ),
        // Campul de telefon si toate optiunile prin SMS (factura prin SMS,
        // anunturi generale prin SMS) au fost eliminate intentionat: SMS-ul
        // esueaza cu eroare 500 ("Transaction rolled back because it has
        // been marked as rollback-only") direct pe portalul web ACIlfov, nu
        // doar in aplicatie - e un bug pe partea de server, nu ceva ce putem
        // repara din client. `_phone` ramane in cod (vezi mai jos) doar ca
        // sa nu stricam alertele care verifica `alert.smsAllowed`, dar fara
        // niciun camp vizibil care sa-l completeze, deci practic e mort -
        // intentionat, pana ACIlfov repara partea de server.
      ],
    );
  }

  Widget _contactField({
    required TextEditingController controller,
    required String label,
    required String helper,
    required TextInputType keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // ================================ 3. ALERTE SI INFORMARI DE LA COMPANIE
  Widget _alertsSection(_SettingsData data) {
    final company = data.companyNotification;
    // Folosim exact ce scrie in campurile de mai sus - userul nu mai introduce
    // aceleasi date de doua ori.
    final email = _email.text.trim().isEmpty ? null : _email.text.trim();

    return _card(
      icon: Icons.campaign_outlined,
      title: 'Alerte si informari de la Apa Ilfov',
      subtitle: 'Trimise de companie. Folosesc adresa de email '
          'completata mai sus.',
      children: [
        if (data.alerts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Contul nu are alerte configurabile. Trage in jos pentru '
              'reincarcare.',
            ),
          )
        else
          for (final alert in data.alerts)
            _serverSwitch(
              key: 'alert:${alert.code}',
              title: _alertTitle(alert),
              subtitle: _alertSubtitle(alert, email),
              value: _pending['alert:${alert.code}'] ?? alert.active,
              onChanged: (v) => _toggleAlert(alert, v, email),
            ),
        const Divider(height: 24),
        _serverSwitch(
          key: 'company:email',
          title: 'Anunturi generale pe email',
          subtitle: email ?? '-',
          value: _pending['company:email'] ??
              (company?.emailAccepted ?? false),
          enabled: email != null,
          onChanged: (v) => _saveCompany(
            _companyBase(company).copyWith(emailAccepted: v),
            key: 'company:email',
            value: v,
          ),
        ),
        // "Anunturi generale prin SMS" a fost eliminat alaturi de campul de
        // telefon - vezi comentariul din _invoiceSection despre eroarea 500
        // pe partea de server ACIlfov pentru SMS.
      ],
    );
  }

  // ------------------------------------------------------------- bucatele UI
  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }

  // Comutator pentru o preferinta LOCALA: reactioneaza instant, nu asteapta
  // niciun server.
  Widget _prefSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  // Comutator legat de server: se blocheaza DOAR el cat dureaza salvarea.
  Widget _serverSwitch({
    required String key,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final busy = _saving.contains(key);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: (enabled && !busy) ? onChanged : null,
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }

  List<Widget> _warningCards(List<String> warnings) {
    if (warnings.isEmpty) return const [];
    return [
      for (final warning in warnings)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            color: Colors.orange.shade50.withValues(alpha: 0.85),
            child: ListTile(
              leading: Icon(Icons.info_outline, color: Colors.orange.shade900),
              title: Text(warning),
              trailing: IconButton(
                tooltip: 'Reincarca',
                icon: const Icon(Icons.refresh),
                onPressed: _reload,
              ),
            ),
          ),
        ),
    ];
  }

  // ------------------------------------------------------------- preferinte
  Future<void> _loadPrefs() async {
    final prefs = await NotificationPrefsStore.read();
    if (mounted) setState(() => _prefs = prefs);
  }

  Future<void> _savePrefs(NotificationPrefs prefs) async {
    // Comutatorul se misca imediat: nu depinde de nicio cerere de retea.
    setState(() => _prefs = prefs);
    await NotificationPrefsStore.write(prefs);
    // Reasezam reamintirile si pornim/oprim verificarea din fundal.
    await BackgroundSync.syncWithPrefs(prefs);
    if (!mounted) return;
    try {
      await context.read<AccountProvider>().refreshNotificationPlan();
    } catch (_) {
      // Datele contului poate nu sunt inca incarcate; nu e o problema.
    }
    if (mounted) await _refreshNotificationStatus();
  }

  Future<void> _refreshNotificationStatus() async {
    final status = await NotificationService.instance.diagnostics();
    if (mounted) setState(() => _notifications = status);
  }

  Future<void> _requestPermissions() async {
    final status = await NotificationService.instance.requestPermissions();
    if (mounted) setState(() => _notifications = status);
  }

  // ------------------------------------------------------------------ date
  CompanyNotificationConfig _companyBase(CompanyNotificationConfig? current) {
    return current ??
        const CompanyNotificationConfig(
          emailAccepted: false,
          smsAccepted: false,
        );
  }

  Future<_SettingsData> _load() async {
    final repo = context.read<ACIRepository>();
    final warnings = <String>[];

    // TOATE cererile pornesc odata. Inainte mergeau una dupa alta si ecranul
    // parea blocat cateva secunde la fiecare apasare.
    final results = await Future.wait([
      _safe(() => repo.getSessionEmail(), warnings, null),
      _safe(() => repo.getInvoiceDeliveryConfigs('EMAIL'), warnings,
          <InvoiceDeliveryConfig>[], 'Configurarea facturii pe email'),
      _safe(() => repo.getInvoiceDeliveryConfigs('SMS'), warnings,
          <InvoiceDeliveryConfig>[], 'Configurarea facturii prin SMS'),
      _safe(() => repo.getAlertConfigs(), warnings, <AlertConfig>[],
          'Alertele companiei'),
      _safe(() => repo.getCompanyNotificationConfig(), warnings, null,
          'Preferintele de informari'),
    ]);

    final data = _SettingsData(
      email: results[0] as String?,
      emailConfigs: results[1] as List<InvoiceDeliveryConfig>,
      smsConfigs: results[2] as List<InvoiceDeliveryConfig>,
      alerts: results[3] as List<AlertConfig>,
      companyNotification: results[4] as CompanyNotificationConfig?,
      warnings: warnings,
    );

    // Datele proaspete inlocuiesc valorile "in asteptare".
    _pending.clear();
    _applyDefaults(data);
    _data = data;
    return data;
  }

  // Ruleaza o cerere si, daca esueaza, adauga un avertisment in loc sa darame
  // tot ecranul.
  Future<Object?> _safe(
    Future<Object?> Function() action,
    List<String> warnings,
    Object? fallback, [
    String? label,
  ]) async {
    try {
      return await action();
    } catch (e) {
      if (label != null) {
        warnings.add(
          '$label nu poate fi citita acum: '
          '${SessionFailsafe.friendlyMessage(e)}',
        );
      }
      return fallback;
    }
  }

  // Se apeleaza DUPA ce vin datele, niciodata in timpul unui `build`.
  void _applyDefaults(_SettingsData data) {
    // Emailul: intai cel din sesiunea portalului (adica exact cel cu care
    // te-ai autentificat), apoi cel deja configurat pentru factura.
    if (_email.text.isEmpty) {
      final configured = data.emailConfigs.isNotEmpty
          ? data.emailConfigs.first.destination
          : null;
      final email = data.email ?? configured ?? '';
      if (email.isNotEmpty) _email.text = email;
    }

    if (_phone.text.isEmpty) {
      final fromSms =
          data.smsConfigs.isNotEmpty ? data.smsConfigs.first.destination : null;
      final fromCompany = data.companyNotification?.phone;
      final phone = (fromSms != null && fromSms.isNotEmpty)
          ? fromSms
          : (fromCompany ?? '');
      if (phone.isNotEmpty) _phone.text = phone;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  // Reincarca datele fara sa acopere ecranul cu rotita: pastram ce e afisat.
  Future<void> _reloadSilently() async {
    try {
      final data = await _load();
      if (mounted) {
        setState(() {
          _data = data;
          _future = Future.value(data);
        });
      }
    } catch (_) {
      // Ramanem pe ultimele date bune.
    }
  }

  // --------------------------------------------------------------- actiuni
  Future<void> _toggleInvoiceDelivery(
    String mode,
    bool value,
    String? destination,
    _SettingsData data,
  ) async {
    final key = 'invoice:$mode';
    final target = (destination ?? '').trim();
    if (value && target.isEmpty) {
      _snack(mode == 'EMAIL'
          ? 'Completeaza adresa de email.'
          : 'Completeaza numarul de telefon.');
      return;
    }
    final configs = mode == 'EMAIL' ? data.emailConfigs : data.smsConfigs;

    await _runFor(
      key,
      value,
      () async {
        final repo = context.read<ACIRepository>();
        if (value) {
          await repo.activateInvoiceDelivery(mode: mode, destination: target);
        } else {
          for (final config in configs) {
            await repo.deactivateInvoiceDelivery(mode: mode, config: config);
          }
        }
      },
      success: value
          ? 'Vei primi factura ${mode == 'EMAIL' ? 'pe email' : 'prin SMS'}.'
          : 'Trimiterea a fost oprita.',
    );
  }

  // Activarea unei alerte NU mai deschide niciun dialog: emailul vine din
  // sesiune, iar telefonul din campul de mai sus.
  Future<void> _toggleAlert(AlertConfig alert, bool value, String? email) async {
    final phone = _phone.text.trim();
    final useEmail = alert.emailAllowed ? email : null;
    final usePhone = alert.smsAllowed && phone.isNotEmpty ? phone : null;

    if (value && useEmail == null && usePhone == null) {
      _snack('Completeaza numarul de telefon pentru aceasta alerta.');
      return;
    }

    await _runFor(
      'alert:${alert.code}',
      value,
      () => context.read<ACIRepository>().saveAlertConfig(
            alert.withContacts(
              active: value,
              email: value ? useEmail : alert.email,
              phone: value ? usePhone : alert.phone,
            ),
          ),
      success: value ? 'Alerta a fost activata.' : 'Alerta a fost oprita.',
    );
  }

  Future<void> _saveCompany(
    CompanyNotificationConfig config, {
    required String key,
    required bool value,
  }) async {
    final phone = _phone.text.trim();
    if (config.smsAccepted && phone.isEmpty) {
      _snack('Completeaza numarul de telefon.');
      return;
    }
    await _runFor(
      key,
      value,
      () => context.read<ACIRepository>().saveCompanyNotificationConfig(
            config.withPhone(config.smsAccepted ? phone : null),
          ),
      success: 'Preferintele au fost salvate.',
    );
  }

  // Ruleaza o salvare aratand rotita DOAR pe randul apasat.
  Future<void> _runFor(
    String key,
    bool optimisticValue,
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() {
      _pending[key] = optimisticValue; // comutatorul se misca imediat
      _saving.add(key);
    });
    var ok = true;
    try {
      await action();
    } catch (e) {
      ok = false;
      if (mounted) {
        _pending.remove(key); // punem comutatorul inapoi cum era
        _snack(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving.remove(key));
    }
    if (ok && mounted) _snack(success);
    // Confirmam cu serverul, dar fara sa acoperim ecranul.
    if (mounted) await _reloadSilently();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ------------------------------------------------------------- etichete
  String _alertTitle(AlertConfig alert) {
    final code = alert.code.toUpperCase();
    final label = alert.label.toUpperCase();
    if (code.contains('EMITERE_FACTURA') || label.contains('EMITERE')) {
      return 'Emitere factura';
    }
    if (code.contains('SCADENTA_AUTOCIT') || label.contains('AUTOCIT')) {
      return 'Scadenta autocitire';
    }
    if (code.contains('INDEX') ||
        label.contains('INDEX') ||
        code.contains('TRANSMITERE')) {
      return 'Perioada trimitere index';
    }
    return _humanize(alert.label.isEmpty ? alert.code : alert.label);
  }

  String _alertSubtitle(AlertConfig alert, String? email) {
    final channels = <String>[
      if (alert.emailAllowed && email != null) email,
      if (alert.smsAllowed && _phone.text.trim().isNotEmpty) _phone.text.trim(),
    ];
    if (channels.isEmpty) return 'Completeaza un telefon pentru aceasta alerta.';
    return channels.join(' / ');
  }

  String _humanize(String value) {
    final text = value
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _SettingsData {
  final String? email;
  final List<InvoiceDeliveryConfig> emailConfigs;
  final List<InvoiceDeliveryConfig> smsConfigs;
  final List<AlertConfig> alerts;
  final CompanyNotificationConfig? companyNotification;
  final List<String> warnings;

  const _SettingsData({
    this.email,
    this.emailConfigs = const [],
    this.smsConfigs = const [],
    this.alerts = const [],
    this.companyNotification,
    this.warnings = const [],
  });
}

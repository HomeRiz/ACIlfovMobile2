// ===========================================================================
//  Teste pentru ecranul "Configurari".
// ---------------------------------------------------------------------------
//  Ce pazesc:
//   - comutatoarele nu mai darama ecranul (regresia cu eroarea rosie);
//   - emailul NU se mai cere userului: vine din sesiunea portalului si e
//     folosit automat la activarea facturii pe email si a alertelor;
//   - activarea unei alerte nu mai deschide niciun dialog.
// ===========================================================================

import 'package:acilfov_mobile/data/models/portal_config.dart';
import 'package:acilfov_mobile/data/repositories/aci_repository.dart';
import 'package:acilfov_mobile/data/repositories/mock_aci_repository.dart';
import 'package:acilfov_mobile/features/settings/settings_view.dart';
import 'package:acilfov_mobile/state/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const String _sessionEmail = 'client.logat@exemplu.ro';

class _FakeRepo extends MockACIRepository {
  final List<AlertConfig> savedAlerts = [];
  final List<({String mode, String destination})> activatedDeliveries = [];
  int savedCompanyConfigs = 0;

  @override
  Future<String?> getSessionEmail() async => _sessionEmail;

  @override
  Future<List<InvoiceDeliveryConfig>> getInvoiceDeliveryConfigs(
    String mode,
  ) async =>
      const [];

  @override
  Future<List<AlertConfig>> getAlertConfigs() async => const [
        AlertConfig(
          code: 'ALERTA_EMITERE_FACTURA',
          label: 'Emitere factura',
          active: false,
        ),
      ];

  @override
  Future<CompanyNotificationConfig> getCompanyNotificationConfig() async =>
      const CompanyNotificationConfig(emailAccepted: false, smsAccepted: false);

  @override
  Future<void> activateInvoiceDelivery({
    required String mode,
    required String destination,
  }) async {
    activatedDeliveries.add((mode: mode, destination: destination));
  }

  @override
  Future<void> saveAlertConfig(AlertConfig config) async {
    savedAlerts.add(config);
  }

  @override
  Future<void> saveCompanyNotificationConfig(
    CompanyNotificationConfig config,
  ) async {
    savedCompanyConfigs++;
  }
}

Widget _wrap(ACIRepository repo) {
  return MultiProvider(
    providers: [
      Provider<ACIRepository>.value(value: repo),
      ChangeNotifierProvider(create: (_) => AccountProvider(repo)),
    ],
    child: const MaterialApp(home: Scaffold(body: SettingsView())),
  );
}

Finder _switchFor(String title) => find.ancestor(
      of: find.text(title),
      matching: find.byType(SwitchListTile),
    );

void main() {
  testWidgets('ecranul se incarca fara taburi si fara eroare', (tester) async {
    await tester.pumpWidget(_wrap(_FakeRepo()));
    await tester.pumpAndSettle();

    expect(find.text('Notificari pe telefon'), findsOneWidget);
    expect(find.text('Factura de la Apa Ilfov'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('campul de email vine completat din sesiune', (tester) async {
    await tester.pumpWidget(_wrap(_FakeRepo()));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Adresa de email'),
    );
    expect(field.controller?.text, _sessionEmail);
    expect(tester.takeException(), isNull);
  });

  testWidgets('campul de telefon e vizibil chiar si cu SMS-ul oprit',
      (tester) async {
    // Altfel userul nu poate porni SMS-ul niciodata: activarea cere un numar,
    // iar numarul nu s-ar putea completa nicaieri.
    await tester.pumpWidget(_wrap(_FakeRepo()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Nr. telefon'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(_switchFor('Primesc factura prin SMS')).value,
      isFalse,
    );
  });

  testWidgets('comutatorul de preferinta locala reactioneaza imediat',
      (tester) async {
    await tester.pumpWidget(_wrap(_FakeRepo()));
    await tester.pumpAndSettle();

    final tile = _switchFor('Cand se emite o factura noua');
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tester.tap(tile);
    await tester.pump(); // un singur cadru: nu asteapta niciun server

    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('factura pe email foloseste automat adresa din sesiune',
      (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(_switchFor('Primesc factura pe email'));
    await tester.pumpAndSettle();

    expect(repo.activatedDeliveries.length, 1);
    expect(repo.activatedDeliveries.single.mode, 'EMAIL');
    expect(repo.activatedDeliveries.single.destination, _sessionEmail);
    expect(tester.takeException(), isNull);
  });

  testWidgets('alerta se activeaza fara dialog, cu emailul din sesiune',
      (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    final tile = _switchFor('Emitere factura');
    // Derulam pe lista paginii. `scrollUntilVisible` fara `scrollable` ar da
    // eroare: si campurile de text contin un Scrollable propriu.
    await tester.dragUntilVisible(
      tile,
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing,
        reason: 'userul nu mai trebuie sa scrie emailul de mana');
    expect(repo.savedAlerts.length, 1);
    expect(repo.savedAlerts.single.active, isTrue);
    expect(repo.savedAlerts.single.email, _sessionEmail);
    expect(tester.takeException(), isNull);
  });
}

// ===========================================================================
//  main.dart  =  PUNCTUL DE PORNIRE AL APLICATIEI
// ---------------------------------------------------------------------------
//  Primul fisier care ruleaza cand deschizi aplicatia (iOS si Android).
//
//  Ce face aici:
//   1. Porneste serviciul de notificari locale.
//   2. Alege DE UNDE vin datele (azi: date de test; maine: API-ul Apa Ilfov).
//   3. Ofera datele + starea aplicatiei tuturor ecranelor (prin "Provider").
//
//  IMPORTANT (locul unde treci la API-ul real):
//   Cauta mai jos linia "final ACIRepository repo = MockACIRepository();".
//   Cand Apa Ilfov publica API-ul, o inlocuiesti cu ApiACIRepository() si GATA -
//   restul aplicatiei ramane neschimbat.
// ===========================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/aci_repository.dart';
import 'data/repositories/repository_factory.dart';
import 'services/notification_service.dart';
import 'state/accessibility_provider.dart';
import 'state/account_provider.dart';
import 'state/auth_provider.dart';

Future<void> main() async {
  // Necesare inainte de a folosi pluginuri (notificari) la pornire.
  WidgetsFlutterBinding.ensureInitialized();

  // ----------------------------------------------------------------------
  //  DE UNDE VIN DATELE: sursa e aleasa automat dupa AppConfig.dataSource.
  //  Ca sa schimbi sursa (mock / cookie / api), modifici o SINGURA valoare
  //  in lib/core/config/app_config.dart. Restul aplicatiei nu se atinge.
  // ----------------------------------------------------------------------
  final ACIRepository repo = createRepository();

  runApp(
    // "MultiProvider" pune la dispozitia tuturor ecranelor: repository-ul,
    // starea de autentificare (AuthProvider) si datele contului (AccountProvider).
    MultiProvider(
      providers: [
        Provider<ACIRepository>.value(value: repo),
        ChangeNotifierProvider(create: (_) => AuthProvider(repo)),
        ChangeNotifierProvider(create: (_) => AccountProvider(repo)),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
      ],
      child: const ApaIlfovApp(),
    ),
  );

  // Nu blocam primul ecran pentru permisiunile/pluginurile de notificari.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initNotifications());
  });
}

Future<void> _initNotifications() async {
  try {
    await NotificationService.instance.init();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'notification_service',
        context: ErrorDescription('initializing local notifications'),
      ),
    );
  }
}

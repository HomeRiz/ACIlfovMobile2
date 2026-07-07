// ===========================================================================
//  app.dart  =  "INVELISUL" APLICATIEI (tema + accesibilitate + ce ecran)
// ---------------------------------------------------------------------------
//  Decide ce vede userul (login vs. aplicatia nativa) si aplica setarile de
//  accesibilitate peste toata aplicatia:
//   - tema (culori, contrast, text ingrosat/spatiat) din AppTheme.build
//   - marimea textului (textScaler)
//   - modul intunecat (themeMode)
//   - filtrul alb-negru (grayscale) peste tot
// ===========================================================================

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/home_shell.dart';
import 'state/accessibility_provider.dart';
import 'state/account_provider.dart';
import 'state/auth_provider.dart';

class ApaIlfovApp extends StatelessWidget {
  const ApaIlfovApp({super.key});

  // Filtru alb-negru aplicat peste toata aplicatia cand optiunea e activa.
  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, a11y, _) {
        return MaterialApp(
          title: 'Apa Ilfov',
          debugShowCheckedModeBanner: false,
          themeMode: a11y.darkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.build(
            brightness: Brightness.light,
            highContrast: a11y.highContrast,
            boldText: a11y.boldText,
            extraLetterSpacing: a11y.extraLetterSpacing,
            extraLineHeight: a11y.extraLineHeight,
          ),
          darkTheme: AppTheme.build(
            brightness: Brightness.dark,
            highContrast: a11y.highContrast,
            boldText: a11y.boldText,
            extraLetterSpacing: a11y.extraLetterSpacing,
            extraLineHeight: a11y.extraLineHeight,
          ),
          // Aplicam scalarea textului si (optional) filtrul alb-negru peste tot.
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            Widget result = MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(a11y.textScale)),
              child: child ?? const SizedBox.shrink(),
            );
            if (a11y.grayscale) {
              result = ColorFiltered(colorFilter: _grayscale, child: result);
            }
            return _ConnectivityGate(child: result);
          },
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) =>
                auth.isLoggedIn ? const HomeShell() : const LoginScreen(),
          ),
        );
      },
    );
  }
}

class _ConnectivityGate extends StatefulWidget {
  final Widget child;

  const _ConnectivityGate({required this.child});

  @override
  State<_ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<_ConnectivityGate> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool? _online;

  @override
  void initState() {
    super.initState();
    unawaited(_checkInitialConnection());
    _subscription = _connectivity.onConnectivityChanged.listen(_setStatus);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnection() async {
    try {
      _setStatus(await _connectivity.checkConnectivity());
    } catch (_) {
      if (mounted) setState(() => _online = null);
    }
  }

  void _setStatus(List<ConnectivityResult> results) {
    final nextOnline = results.any((r) => r != ConnectivityResult.none);
    final wasOffline = _online == false;
    if (mounted) setState(() => _online = nextOnline);

    if (wasOffline && nextOnline && mounted) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        unawaited(context.read<AccountProvider>().load());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_online == false)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.orange.shade800,
              child: const SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Verificati conexiunea la internet. Se asteapta conexiunea la internet.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

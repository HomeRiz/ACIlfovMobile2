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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/home_shell.dart';
import 'state/accessibility_provider.dart';
import 'state/auth_provider.dart';

class ACIlfovApp extends StatelessWidget {
  const ACIlfovApp({super.key});

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
          title: 'ACIlfov',
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
            return result;
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

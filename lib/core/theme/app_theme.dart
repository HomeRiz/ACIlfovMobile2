// ===========================================================================
//  app_theme.dart  =  TEMA VIZUALA (culori, bara de sus) + accesibilitate
// ---------------------------------------------------------------------------
//  Construieste tema in functie de setarile de accesibilitate (contrast,
//  text ingrosat, spatiere, inaltime randuri) pentru o luminozitate data
//  (deschis / intunecat).
// ===========================================================================

import 'package:flutter/material.dart';

import '../config/app_config.dart';

class AppTheme {
  AppTheme._();

  // Albastrul din branding.
  static const Color brand = Color(AppConfig.brandColor);

  static ThemeData build({
    required Brightness brightness,
    bool highContrast = false,
    bool boldText = false,
    bool extraLetterSpacing = false,
    bool extraLineHeight = false,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: brightness,
      contrastLevel: highContrast ? 1.0 : 0.0,
    );

    final isLight = brightness == Brightness.light;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? brand : scheme.surfaceContainerHighest,
        foregroundColor: isLight ? Colors.white : scheme.onSurface,
      ),
    );

    var textTheme = base.textTheme;
    if (boldText || extraLetterSpacing || extraLineHeight) {
      textTheme = _adjust(
        textTheme,
        bold: boldText,
        addLetter: extraLetterSpacing ? 0.5 : 0,
        height: extraLineHeight ? 1.6 : null,
      );
    }
    return base.copyWith(textTheme: textTheme);
  }

  // Adauga spatiere intre litere si/sau inaltime randuri la toate stilurile.
  static TextTheme _adjust(TextTheme t,
      {bool bold = false, double addLetter = 0, double? height}) {
    TextStyle? f(TextStyle? s) => s?.copyWith(
          fontWeight: bold ? FontWeight.bold : s.fontWeight,
          letterSpacing: (s.letterSpacing ?? 0) + addLetter,
          height: height ?? s.height,
        );
    return t.copyWith(
      displayLarge: f(t.displayLarge),
      displayMedium: f(t.displayMedium),
      displaySmall: f(t.displaySmall),
      headlineLarge: f(t.headlineLarge),
      headlineMedium: f(t.headlineMedium),
      headlineSmall: f(t.headlineSmall),
      titleLarge: f(t.titleLarge),
      titleMedium: f(t.titleMedium),
      titleSmall: f(t.titleSmall),
      bodyLarge: f(t.bodyLarge),
      bodyMedium: f(t.bodyMedium),
      bodySmall: f(t.bodySmall),
      labelLarge: f(t.labelLarge),
      labelMedium: f(t.labelMedium),
      labelSmall: f(t.labelSmall),
    );
  }
}

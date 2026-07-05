// ===========================================================================
//  accessibility_provider.dart  =  SETARILE DE ACCESIBILITATE
// ---------------------------------------------------------------------------
//  Tine setarile alese de utilizator (marime text, contrast, mod intunecat
//  etc.) si anunta aplicatia sa se redeseneze cand se schimba ceva.
//  Aplicarea lor se face in app.dart (tema + scalarea textului + alb-negru).
// ===========================================================================

import 'package:flutter/foundation.dart';

class AccessibilityProvider extends ChangeNotifier {
  double textScale = 1.0; // 1.0 = 100%
  bool boldText = false;
  bool extraLetterSpacing = false;
  bool extraLineHeight = false;
  bool darkMode = false;
  bool highContrast = false;
  bool grayscale = false;

  int get fontPercent => (textScale * 100).round();

  void increaseFont() {
    textScale = (textScale + 0.1).clamp(0.8, 1.8);
    notifyListeners();
  }

  void decreaseFont() {
    textScale = (textScale - 0.1).clamp(0.8, 1.8);
    notifyListeners();
  }

  void toggleBold(bool v) {
    boldText = v;
    notifyListeners();
  }

  void toggleLetterSpacing(bool v) {
    extraLetterSpacing = v;
    notifyListeners();
  }

  void toggleLineHeight(bool v) {
    extraLineHeight = v;
    notifyListeners();
  }

  void toggleDark(bool v) {
    darkMode = v;
    notifyListeners();
  }

  void toggleHighContrast(bool v) {
    highContrast = v;
    notifyListeners();
  }

  void toggleGrayscale(bool v) {
    grayscale = v;
    notifyListeners();
  }

  void reset() {
    textScale = 1.0;
    boldText = false;
    extraLetterSpacing = false;
    extraLineHeight = false;
    darkMode = false;
    highContrast = false;
    grayscale = false;
    notifyListeners();
  }
}

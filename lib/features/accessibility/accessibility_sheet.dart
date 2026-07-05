// ===========================================================================
//  accessibility_sheet.dart  =  MENIUL DE ACCESIBILITATE
// ---------------------------------------------------------------------------
//  Un panou (se ridica de jos) cu optiuni de accesibilitate, ca pe portal:
//   - Marime text (+/-)
//   - Text ingrosat, Spatiere litere, Inaltime randuri
//   - Mod intunecat, Contrast ridicat, Alb-negru
//   - Reseteaza setarile
//
//  Se deschide cu showAccessibilitySheet(context) (din bara de sus / Configurari).
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/accessibility_provider.dart';

Future<void> showAccessibilitySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AccessibilitySheet(),
  );
}

class _AccessibilitySheet extends StatelessWidget {
  const _AccessibilitySheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, a, _) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Row(
                  children: [
                    const Icon(Icons.accessibility_new, color: Color(0xFF335C80)),
                    const SizedBox(width: 8),
                    Text('Accesibilitate',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                _section('Marime text'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.filledTonal(
                            onPressed: a.decreaseFont,
                            icon: const Icon(Icons.remove)),
                        Text('${a.fontPercent}%',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton.filledTonal(
                            onPressed: a.increaseFont,
                            icon: const Icon(Icons.add)),
                      ],
                    ),
                  ),
                ),
                _section('Text'),
                SwitchListTile(
                  value: a.boldText,
                  onChanged: a.toggleBold,
                  secondary: const Icon(Icons.format_bold),
                  title: const Text('Text ingrosat'),
                ),
                SwitchListTile(
                  value: a.extraLetterSpacing,
                  onChanged: a.toggleLetterSpacing,
                  secondary: const Icon(Icons.space_bar),
                  title: const Text('Spatiere litere'),
                ),
                SwitchListTile(
                  value: a.extraLineHeight,
                  onChanged: a.toggleLineHeight,
                  secondary: const Icon(Icons.format_line_spacing),
                  title: const Text('Inaltime randuri'),
                ),
                _section('Culori'),
                SwitchListTile(
                  value: a.darkMode,
                  onChanged: a.toggleDark,
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Mod intunecat'),
                ),
                SwitchListTile(
                  value: a.highContrast,
                  onChanged: a.toggleHighContrast,
                  secondary: const Icon(Icons.contrast),
                  title: const Text('Contrast ridicat'),
                ),
                SwitchListTile(
                  value: a.grayscale,
                  onChanged: a.toggleGrayscale,
                  secondary: const Icon(Icons.filter_b_and_w),
                  title: const Text('Alb-negru'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: a.reset,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reseteaza setarile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF335C80))),
      );
}

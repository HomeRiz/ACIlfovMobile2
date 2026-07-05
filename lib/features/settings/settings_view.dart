// ===========================================================================
//  settings_view.dart  =  PAGINA "CONFIGURARI"
// ---------------------------------------------------------------------------
//  Setari generale: test notificari, informatii despre integrarea cu Home
//  Assistant (viitor) si versiunea aplicatiei.
// ===========================================================================

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../services/notification_service.dart';
import '../accessibility/accessibility_sheet.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.accessibility_new),
          title: const Text('Accesibilitate'),
          subtitle: const Text('Marime text, contrast, mod intunecat...'),
          onTap: () => showAccessibilitySheet(context),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.notifications_active),
          title: const Text('Testeaza notificarile'),
          subtitle: const Text('Trimite o notificare de test acum.'),
          onTap: () => NotificationService.instance.showTest(),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.home_work_outlined),
          title: Text('Home Assistant'),
          subtitle: Text(
            'In viitor vei putea genera un token read-only pentru a conecta '
            'contul ACIlfov la Home Assistant. Necesita API din partea ACIlfov.',
          ),
          isThreeLine: true,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.storage),
          title: const Text('Sursa de date'),
          subtitle: Text('Curent: ${AppConfig.dataSource.name}'),
        ),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Versiune aplicatie'),
          subtitle: Text('ACIlfov Mobile 2.0.0'),
        ),
      ],
    );
  }
}

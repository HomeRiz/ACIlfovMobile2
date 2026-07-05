// ===========================================================================
//  alerts_view.dart  =  PAGINA "ALERTE SI NOTIFICARI" (+ factura electronica)
// ---------------------------------------------------------------------------
//  Toate optiunile de notificare intr-un singur loc:
//   - Activare alerte (factura noua / scadenta / perioada index)
//   - Factura electronica (fara hartie)
//
//  ACUM: comutatoarele sunt locale (se aplica notificarilor locale). Cand
//  exista API, aceste preferinte se vor sincroniza cu contul ACIlfov.
// ===========================================================================

import 'package:flutter/material.dart';

import '../../services/notification_service.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({super.key});

  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  bool _alertNewInvoice = true;
  bool _alertDue = true;
  bool _alertIndex = true;
  bool _eInvoice = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _section('Activare alerte'),
        SwitchListTile(
          value: _alertNewInvoice,
          onChanged: (v) => setState(() => _alertNewInvoice = v),
          title: const Text('Alerta factura noua'),
          subtitle: const Text('Cand este emisa o factura noua.'),
        ),
        SwitchListTile(
          value: _alertDue,
          onChanged: (v) => setState(() => _alertDue = v),
          title: const Text('Alerta scadenta'),
          subtitle: const Text('Inainte ca o factura sa devina scadenta.'),
        ),
        SwitchListTile(
          value: _alertIndex,
          onChanged: (v) => setState(() => _alertIndex = v),
          title: const Text('Alerta perioada index'),
          subtitle: const Text('Cand incepe perioada de transmitere a indexului.'),
        ),
        const Divider(),
        _section('Factura electronica'),
        SwitchListTile(
          value: _eInvoice,
          onChanged: (v) => setState(() => _eInvoice = v),
          title: const Text('Primesc factura electronica'),
          subtitle: const Text('Renunt la factura pe hartie.'),
        ),
        const Divider(),
        _section('Test'),
        ListTile(
          leading: const Icon(Icons.notifications_active),
          title: const Text('Trimite o notificare de test'),
          onTap: () => NotificationService.instance.showTest(),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Nota: aceste preferinte se aplica notificarilor locale. Cand ACIlfov '
            'va oferi API, ele se vor sincroniza cu contul tau.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF335C80),
          ),
        ),
      );
}

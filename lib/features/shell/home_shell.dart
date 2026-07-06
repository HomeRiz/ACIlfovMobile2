// ===========================================================================
//  home_shell.dart  =  ECRANUL PRINCIPAL (meniu hamburger + continut)
// ---------------------------------------------------------------------------
//  Structura, ca pe portalul acilfov.emsys.ro:
//   - Bara de sus cu iconita hamburger (stanga).
//   - Meniu lateral (Drawer) care se deschide din iconita SAU prin swipe de la
//     marginea stanga spre dreapta (implicit in Flutter).
//   - Continutul se schimba intre toate paginile din meniu, fara sa iesi din
//     ecranul principal (un singur Scaffold, o singura bara, un singur meniu).
//
//  Ca sa adaugi o pagina noua: (1) valoare in ShellPage, (2) o linie in _menu,
//  (3) un caz in _bodyFor. Restul merge automat.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/account_provider.dart';
import '../../state/auth_provider.dart';
import '../accessibility/accessibility_sheet.dart';
import '../account_info/account_info_view.dart';
import '../account_info/delete_account_view.dart';
import '../auth/change_password_view.dart';
import '../consumption/consumption_chart_view.dart';
import '../consumption/consumption_view.dart';
import '../dashboard/home_view.dart';
import '../index/index_view.dart';
import '../info/info_view.dart';
import '../invoices/invoices_view.dart';
import '../message/send_message_view.dart';
import '../payments/payments_view.dart';
import '../profile/update_data_view.dart';
import '../settings/settings_view.dart';
import 'shell_page.dart';

// O intrare de meniu: pagina + iconita + eticheta.
typedef _MenuEntry = ({ShellPage page, IconData icon, String label});

// Lista completa a meniului, in ordinea de afisare.
const List<_MenuEntry> _menu = [
  (page: ShellPage.home, icon: Icons.home, label: 'Acasa'),
  (
    page: ShellPage.invoices,
    icon: Icons.receipt_long,
    label: 'Istoric facturi'
  ),
  (page: ShellPage.indexPage, icon: Icons.speed, label: 'Transmitere index'),
  (page: ShellPage.payments, icon: Icons.payments, label: 'Istoric plati'),
  (
    page: ShellPage.consumption,
    icon: Icons.show_chart,
    label: 'Istoric consum'
  ),
  (page: ShellPage.chart, icon: Icons.bar_chart, label: 'Grafic'),
  (
    page: ShellPage.updateData,
    icon: Icons.edit_note,
    label: 'Actualizare date cont'
  ),
  (page: ShellPage.settings, icon: Icons.settings, label: 'Configurari'),
  (
    page: ShellPage.changePassword,
    icon: Icons.lock_reset,
    label: 'Schimbare parola'
  ),
  (page: ShellPage.contact, icon: Icons.mail_outline, label: 'Contact'),
  (
    page: ShellPage.accountInfo,
    icon: Icons.info_outline,
    label: 'Informatii cont'
  ),
  (
    page: ShellPage.deleteAccount,
    icon: Icons.delete_forever,
    label: 'Stergere cont'
  ),
];

const _MenuEntry _infoMenu =
    (page: ShellPage.info, icon: Icons.info, label: 'Info');

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  ShellPage _page = ShellPage.home;

  @override
  void initState() {
    super.initState();
    // Incarcam datele contului imediat ce intram in aplicatie.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AccountProvider>().load();
    });
  }

  void _go(ShellPage p) => setState(() => _page = p);

  String get _title => _page == _infoMenu.page
      ? _infoMenu.label
      : _menu.firstWhere((e) => e.page == _page).label;

  // Ce continut se afiseaza pentru pagina curenta (widget-uri fara bara proprie).
  Widget _bodyFor(ShellPage p) {
    switch (p) {
      case ShellPage.home:
        return HomeView(onNavigate: _go);
      case ShellPage.invoices:
        return const InvoicesView();
      case ShellPage.indexPage:
        return const IndexView();
      case ShellPage.consumption:
        return const ConsumptionView();
      case ShellPage.chart:
        return const ConsumptionChartView();
      case ShellPage.payments:
        return const PaymentsView();
      case ShellPage.updateData:
        return const UpdateDataView();
      case ShellPage.settings:
        return const SettingsView();
      case ShellPage.changePassword:
        return const ChangePasswordView();
      case ShellPage.contact:
        return const SendMessageView();
      case ShellPage.accountInfo:
        return const AccountInfoView();
      case ShellPage.deleteAccount:
        return const DeleteAccountView();
      case ShellPage.info:
        return const InfoView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Accesibilitate',
            icon: const Icon(Icons.accessibility_new),
            onPressed: () => showAccessibilitySheet(context),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _bodyFor(_page),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Antetul meniului (albastrul din branding).
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF335C80)),
            margin: EdgeInsets.zero,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Text('ACIlfov',
                      style: TextStyle(color: Colors.white, fontSize: 22)),
                ],
              ),
            ),
          ),
          // Lista de pagini (se poate derula daca nu incap toate).
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final e in _menu) _drawerTile(e),
                const SizedBox(height: 12),
                _drawerTile(_infoMenu),
              ],
            ),
          ),
          const Divider(height: 1),
          // Deconectare (mereu jos).
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Deconectare'),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _drawerTile(_MenuEntry e) {
    return ListTile(
      leading: Icon(e.icon),
      title: Text(e.label),
      selected: e.page == _page,
      selectedTileColor: const Color(0x11335C80),
      onTap: () {
        Navigator.pop(context); // inchide meniul
        _go(e.page);
      },
    );
  }
}

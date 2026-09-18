// ===========================================================================
//  login_screen.dart  =  ECRANUL DE LOGIN (WebView cu portalul ACIlfov)
// ---------------------------------------------------------------------------
//  In v2, WebView-ul este folosit DOAR pentru autentificare. Userul se
//  logheaza in portal (inclusiv verificarea anti-robot Cloudflare). Cand
//  ajungem in zona autentificata a portalului, aplicatia trece automat la
//  ecranele native (HomeShell), iar sesiunea (cookie-ul) ramane salvata.
//
// ===========================================================================

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/app_config.dart';
import '../../data/cookie_store.dart';
import '../../state/auth_provider.dart';

// SECURITATE: doar https + portalul oficial + Cloudflare (anti-robot).
bool isAllowedMainFrameUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (uri.scheme != 'https') return false;
  return uri.host == 'acilfov.emsys.ro' ||
      uri.host == 'challenges.cloudflare.com';
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _online = true;
  bool _hasError = false;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (!request.isMainFrame) return NavigationDecision.navigate;
            if (isAllowedMainFrameUrl(request.url)) {
              return NavigationDecision.navigate;
            }
            if (kDebugMode) {
              debugPrint('Navigare externa blocata: ${request.url}');
            }
            return NavigationDecision.prevent;
          },
          onPageStarted: (url) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            CookieStore.save(AppConfig.portalUrl);
            _maybeLoggedIn(url);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          },
        ),
      );
    _initConnectivity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    super.dispose();
  }

  // Cand pagina intra in zona autentificata (/oui/cl/), consideram userul logat
  // si trecem la aplicatia nativa.
  void _maybeLoggedIn(String url) {
    if (url.contains('/oui/cl/')) {
      context.read<AuthProvider>().markLoggedIn();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      CookieStore.save(AppConfig.portalUrl);
    }
  }

  Future<void> _initConnectivity() async {
    final current = await _connectivity.checkConnectivity();
    _applyConnectivity(current, initial: true);
    _connSub = _connectivity.onConnectivityChanged.listen(_applyConnectivity);
  }

  void _applyConnectivity(List<ConnectivityResult> results,
      {bool initial = false}) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online) {
      if (!_online || initial) {
        setState(() {
          _online = true;
          _hasError = false;
          _isLoading = true;
        });
        _loadPortal();
      }
    } else {
      setState(() {
        _online = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPortal() async {
    final restored = await CookieStore.restore(AppConfig.portalUrl);
    final target = restored ? AppConfig.authUrl : AppConfig.portalUrl;
    await _controller.loadRequest(Uri.parse(target));
  }

  // Buton pentru ACIlfov (sau pentru echipele de review App Store/Play
  // Store, daca nu exista un cont real disponibil): intra direct in
  // aplicatie cu date generate, fara sa treaca prin portalul real.
  Future<void> _confirmEnterDemoMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mod Verificare / Demo'),
        content: const Text(
          'Intri in aplicatie cu date generate (cont, facturi, consum, '
          'index), fara sa te conectezi la portalul real ACIlfov. '
          'Foloseste acest mod doar pentru a vedea functionalitatea '
          'aplicatiei.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuleaza'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continua'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AuthProvider>().enterDemoMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showError = !_online || _hasError;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        // Tine-apasat pe logo intra in modul Verificare/Demo (vezi AppConfig.
        // reviewDemoEnabled). Fara buton vizibil, ca sa nu fie un punct de
        // intrare vizibil/tentant pentru userii reali - doar cine stie ca
        // exista il foloseste.
        title: AppConfig.reviewDemoEnabled
            ? GestureDetector(
                onLongPress: _confirmEnterDemoMode,
                child: Image.asset('assets/logo.png', height: 36),
              )
            : Image.asset('assets/logo.png', height: 36),
        backgroundColor: const Color(0xFF335C80),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading && !showError)
            const Center(child: CircularProgressIndicator()),
          if (showError) _buildErrorView(),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 72, color: Color(0xFF335C80)),
            const SizedBox(height: 20),
            const Text(
              'Aplicatia necesita conectare la internet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifica conexiunea. Aplicatia se va actualiza automat cand revine internetul.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _loadPortal();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reincearca'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF335C80),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

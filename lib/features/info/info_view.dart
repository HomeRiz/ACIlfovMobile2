// ===========================================================================
//  info_view.dart  =  PAGINA "INFO"
// ---------------------------------------------------------------------------
//  Lista de documente publice ACIlfov. Continutul se deschide direct din
//  paginile oficiale, ca sa ramana identic cu ACIlfov.ro.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/app_config.dart';

class InfoView extends StatelessWidget {
  const InfoView({super.key});

  static const List<_OfficialDocument> _documents = [
    _OfficialDocument(
      title: 'Licenta de utilizare',
      subtitle: 'Certificari si Licentiere - ACIlfov.ro',
      url: AppConfig.officialLicensingUrl,
      icon: Icons.verified_outlined,
    ),
    _OfficialDocument(
      title: 'Conformitate GDPR',
      subtitle: 'Termeni si conditii - drepturi si prelucrarea datelor',
      url: AppConfig.officialTermsUrl,
      icon: Icons.privacy_tip_outlined,
    ),
    _OfficialDocument(
      title: 'Formular standard GDPR',
      subtitle: 'Document PDF oficial - se deschide in browser',
      url: AppConfig.officialGdprFormUrl,
      icon: Icons.description_outlined,
      opensExternally: true,
    ),
    _OfficialDocument(
      title: 'Politica de cookie',
      subtitle: 'Informatii oficiale despre cookie-uri',
      url: AppConfig.officialCookiePolicyUrl,
      icon: Icons.cookie_outlined,
    ),
    _OfficialDocument(
      title: 'Portal online ACIlfov',
      subtitle: 'Autentificare in portalul online oficial',
      url: AppConfig.officialCustomerPortalUrl,
      icon: Icons.account_circle_outlined,
      opensExternally: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const _SectionTitle('Documente oficiale'),
        for (final document in _documents)
          Card(
            child: ListTile(
              leading: Icon(document.icon, color: const Color(0xFF335C80)),
              title: Text(document.title),
              subtitle: Text(document.subtitle),
              trailing: Icon(
                document.opensExternally
                    ? Icons.open_in_new
                    : Icons.chevron_right,
              ),
              onTap: () => _openDocument(context, document),
            ),
          ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Continut incarcat din sursele oficiale ACIlfov.ro.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _OfficialDocument {
  final String title;
  final String subtitle;
  final String url;
  final IconData icon;
  final bool opensExternally;

  const _OfficialDocument({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.icon,
    this.opensExternally = false,
  });
}

Future<void> _openDocument(
  BuildContext context,
  _OfficialDocument document,
) async {
  if (!document.opensExternally) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OfficialDocumentPage(document: document),
      ),
    );
    return;
  }

  final uri = Uri.parse(document.url);
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nu pot deschide ${document.title}.')),
    );
  }
}

class _OfficialDocumentPage extends StatefulWidget {
  final _OfficialDocument document;

  const _OfficialDocumentPage({required this.document});

  @override
  State<_OfficialDocumentPage> createState() => _OfficialDocumentPageState();
}

class _OfficialDocumentPageState extends State<_OfficialDocumentPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (!request.isMainFrame) return NavigationDecision.navigate;
            return _isAllowedInfoUrl(request.url)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.document.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.document.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const LinearProgressIndicator(),
          if (_hasError) _errorView(context),
        ],
      ),
    );
  }

  Widget _errorView(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 56, color: Color(0xFF335C80)),
            const SizedBox(height: 16),
            const Text(
              'Documentul oficial nu a putut fi incarcat in aplicatie.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SelectableText(
              widget.document.url,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF335C80)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _controller.loadRequest(Uri.parse(widget.document.url));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reincarca'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF335C80),
          ),
        ),
      );
}

bool _isAllowedInfoUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return false;
  return uri.host == 'acilfov.ro' ||
      uri.host == 'www.acilfov.ro' ||
      uri.host == 'acilfov.emsys.ro';
}

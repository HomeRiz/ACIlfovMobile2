import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';

class FailsafeErrorState extends StatelessWidget {
  final Object? error;
  final FutureOr<void> Function() onReload;

  const FailsafeErrorState({
    super.key,
    required this.error,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 42),
            const SizedBox(height: 12),
            Text(
              SessionFailsafe.friendlyMessage(error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => SessionFailsafe.reloadOrLogout(
                context,
                error: error,
                onReload: onReload,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Reincarca'),
            ),
          ],
        ),
      ),
    );
  }
}

class SessionFailsafe {
  SessionFailsafe._();

  static String? _lastSignature;
  static int _attempts = 0;

  static String friendlyMessage(Object? error) {
    final code = _statusCode(error);
    if (code == null) {
      return 'Eroare: nu am putut incarca datele.';
    }
    return 'Eroare $code: ${_meaning(code)}.';
  }

  static Future<void> reloadOrLogout(
    BuildContext context, {
    required Object? error,
    required FutureOr<void> Function() onReload,
  }) async {
    final signature = _signature(error);
    if (_lastSignature == signature) {
      _attempts += 1;
    } else {
      _lastSignature = signature;
      _attempts = 1;
    }

    if (_attempts >= 3) {
      _reset();
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sesiunea a fost resetata. Te rugam sa te autentifici din nou.',
            ),
          ),
        );
      }
      return;
    }

    await onReload();
  }

  static void _reset() {
    _lastSignature = null;
    _attempts = 0;
  }

  static String _signature(Object? error) {
    final code = _statusCode(error);
    if (code != null) return 'http:$code';
    return 'generic:${error.toString()}';
  }

  static int? _statusCode(Object? error) {
    final text = error.toString();
    final match = RegExp(r'\b([1-5][0-9]{2})\b').firstMatch(text);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static String _meaning(int code) {
    switch (code) {
      case 400:
        return 'cerere invalida';
      case 401:
        return 'autentificare necesara';
      case 403:
        return 'autentificare esuata sau sesiune expirata';
      case 404:
        return 'resursa nu a fost gasita';
      case 408:
        return 'serverul nu a raspuns la timp';
      case 429:
        return 'prea multe cereri intr-un timp scurt';
      case 500:
        return 'eroare interna pe server';
      case 502:
      case 503:
      case 504:
        return 'serviciul este temporar indisponibil';
      default:
        if (code >= 400 && code < 500) return 'cererea a fost refuzata';
        if (code >= 500) return 'eroare pe server';
        return 'raspuns neasteptat';
    }
  }
}

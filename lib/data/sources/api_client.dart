// ===========================================================================
//  api_client.dart  =  CLIENTUL API (VIITOR)
// ---------------------------------------------------------------------------
//  Clientul HTTP care va vorbi cu API-ul oficial ACIlfov, folosind tokenul
//  obtinut dupa login (flux OAuth). AZI nu este folosit (dataSource != api).
//  Structura e gata, ca sa poti "umple" doar caile (endpoint-urile) reale.
// ===========================================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../secure_store.dart';

class ApiClient {
  final http.Client _http;
  ApiClient({http.Client? client}) : _http = client ?? http.Client();

  // Cerere GET care intoarce JSON, cu tokenul atasat automat in antet.
  Future<Map<String, dynamic>> getJson(String path) async {
    final token = await SecureStore.readToken();
    final res = await _http.get(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Eroare API (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // Cerere POST cu corp JSON (ex: trimitere index).
  Future<void> postJson(String path, Map<String, dynamic> body) async {
    final token = await SecureStore.readToken();
    final res = await _http.post(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Eroare API (${res.statusCode})');
    }
  }
}

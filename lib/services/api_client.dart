import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.status = 0});
  final String message;
  final int status;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._prefs);

  final SharedPreferences _prefs;

  static const _tokenKey = 'base_access_token';

  String? get token => _prefs.getString(_tokenKey);

  Future<void> setToken(String? value) async {
    if (value == null) {
      await _prefs.remove(_tokenKey);
    } else {
      await _prefs.setString(_tokenKey, value);
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.apiUrl.endsWith('/')
        ? AppConfig.apiUrl.substring(0, AppConfig.apiUrl.length - 1)
        : AppConfig.apiUrl;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool json = true, bool auth = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
    };
    if (auth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = true}) async {
    final response = await http.get(
      _uri(path, query),
      headers: _headers(auth: auth),
    );
    return _parse(response);
  }

  Future<dynamic> post(String path, [Object? body, bool auth = true]) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _parse(response);
  }

  Future<dynamic> put(String path, [Object? body]) async {
    final response = await http.put(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _parse(response);
  }

  Future<void> delete(String path) async {
    final response = await http.delete(_uri(path), headers: _headers());
    if (response.statusCode == 204) return;
    _parse(response);
  }

  dynamic _parse(http.Response response) {
    if (response.statusCode == 401) {
      throw ApiException('Sessão expirada. Faça login novamente.', status: 401);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        body['message']?.toString() ?? 'Erro ${response.statusCode}',
        status: response.statusCode,
      );
    } catch (_) {
      throw ApiException('Erro ${response.statusCode}', status: response.statusCode);
    }
  }
}

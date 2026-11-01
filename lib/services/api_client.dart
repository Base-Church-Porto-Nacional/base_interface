import 'dart:async';
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

  void Function()? onUnauthorized;

  static const timeout = Duration(seconds: 20);

  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(timeout);
    } on TimeoutException {
      throw ApiException('O servidor demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw ApiException(
        'Sem conexão com o servidor. Verifique sua internet e tente novamente.',
      );
    }
  }

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
    return Uri.parse('$base$normalized').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  Map<String, String> _headers({bool auth = true}) {
    final token = this.token;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (auth && token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final response = await _send(
      http.get(_uri(path, query), headers: _headers(auth: auth)),
    );
    return _parse(response, auth: auth);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    bool auth = true,
    Map<String, String>? query,
  }) async {
    final response = await _send(
      http.post(
        _uri(path, query),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _parse(response, auth: auth);
  }

  Future<dynamic> put(String path, [Object? body]) async {
    final response = await _send(
      http.put(
        _uri(path),
        headers: _headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _parse(response);
  }

  Future<void> delete(String path) async {
    final response = await _send(http.delete(_uri(path), headers: _headers()));
    if (response.statusCode == 204) return;
    _parse(response);
  }

  dynamic _parse(http.Response response, {bool auth = true}) {
    if (response.statusCode == 401 && auth) {
      onUnauthorized?.call();
      throw ApiException('Sessão expirada. Faça login novamente.', status: 401);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }
    String? message;
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) message = body['message']?.toString();
    } catch (_) {}
    throw ApiException(
      message ?? 'Erro ${response.statusCode}',
      status: response.statusCode,
    );
  }
}

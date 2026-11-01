import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._api, this._prefs);

  final ApiClient _api;
  final SharedPreferences _prefs;

  static const _userKey = 'base_user';

  AuthUser? getStoredUser() {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<AuthUser> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Informe usuário e senha.');
    }

    final login = await _api.post(
      '/auth/login',
      body: {'username': username, 'senha': password},
      auth: false,
    ) as Map<String, dynamic>;

    await _api.setToken(login['token'] as String);

    Map<String, dynamic> me = login;
    try {
      me = await _api.get('/me') as Map<String, dynamic>;
    } catch (_) {}

    final papeis = (login['papeis'] as List<dynamic>? ?? me['papeis'] as List<dynamic>? ?? [])
        .map((p) => roleFromString(p as String))
        .toList();

    final user = AuthUser(
      id: (login['usuarioId'] ?? me['id']) as String,
      nome: (me['nome'] ?? login['username']) as String,
      email: (me['email'] ?? login['username']) as String,
      roles: papeis,
      pessoaId: me['pessoaId'] as String?,
      igrejaId: me['igrejaId'] as String? ?? '',
      igrejaTipo: igrejaTipoFromString(me['igrejaTipo'] as String?),
      igrejaNome: me['igrejaNome'] as String? ?? '',
      igrejasVisiveis: (me['igrejasVisiveis'] as List<dynamic>? ?? [])
          .map((e) => Igreja.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    return user;
  }

  Future<void> logout() async {
    await _api.setToken(null);
    await _prefs.remove(_userKey);
  }

  bool get isAuthenticated => _api.token != null && getStoredUser() != null;
}

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

    final login = await _api.post('/auth/login', {
      'username': username,
      'senha': password,
    }, false) as Map<String, dynamic>;

    await _api.setToken(login['token'] as String);

    Map<String, dynamic> me = login;
    try {
      me = await _api.get('/me') as Map<String, dynamic>;
    } catch (_) {}

    final user = _montarUsuario(
      me,
      id: (login['usuarioId'] ?? me['id']) as String,
      nome: (me['nome'] ?? login['username']) as String,
      email: (me['email'] ?? login['username']) as String,
    );

    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    return user;
  }

  /// Recarrega `GET /me` e atualiza o usuário persistido (permissões novas
  /// após mudança de papel, ou sessão antiga sem `permissoes`).
  /// Em falha de rede mantém o usuário armazenado.
  Future<AuthUser?> recarregarMe() async {
    final atual = getStoredUser();
    if (atual == null) return null;
    try {
      final me = await _api.get('/me') as Map<String, dynamic>;
      final user = _montarUsuario(
        me,
        id: (me['id'] as String?) ?? atual.id,
        nome: (me['nome'] as String?) ?? atual.nome,
        email: (me['email'] as String?) ?? atual.email,
      );
      await _prefs.setString(_userKey, jsonEncode(user.toJson()));
      return user;
    } on ApiException catch (e) {
      if (e.status == 401) rethrow;
      return atual;
    } catch (_) {
      return atual;
    }
  }

  AuthUser _montarUsuario(
    Map<String, dynamic> me, {
    required String id,
    required String nome,
    required String email,
  }) {
    final visiveisJson = me['igrejasVisiveis'] as List<dynamic>? ?? [];
    return AuthUser(
      id: id,
      nome: nome,
      email: email,
      papeis: (me['papeis'] as List<dynamic>? ?? const [])
          .map((p) => p as String)
          .toList(),
      permissoes: Permissoes.fromJson(
        me['permissoes'] as Map<String, dynamic>?,
      ),
      permissoesAusentes: me['permissoes'] == null,
      pessoaId: me['pessoaId'] as String?,
      igrejaId: me['igrejaId'] as String? ?? '',
      igrejaTipo:
          (me['igrejaTipo'] as String? ?? 'FILIAL').toUpperCase() == 'MATRIZ'
          ? IgrejaTipo.matriz
          : IgrejaTipo.filial,
      igrejaNome: me['igrejaNome'] as String? ?? '',
      igrejasVisiveis: visiveisJson
          .map(
            (e) => Igreja(
              id: e['id'] as String,
              nome: e['nome'] as String,
              tipo: (e['tipo'] as String? ?? 'FILIAL').toUpperCase() == 'MATRIZ'
                  ? IgrejaTipo.matriz
                  : IgrejaTipo.filial,
              pastorPessoaId: e['pastorPessoaId'] as String? ?? '',
              pastorNome: e['pastorNome'] as String? ?? '',
              adminUsuarioId: e['adminUsuarioId'] as String? ?? '',
              adminNome: e['adminNome'] as String? ?? '',
              ativo: e['ativo'] as bool? ?? true,
              igrejaMatrizId: e['igrejaMatrizId'] as String?,
            ),
          )
          .toList(),
    );
  }

  Future<void> logout() async {
    await _api.setToken(null);
    await _prefs.remove(_userKey);
  }

  bool get isAuthenticated => _api.token != null && getStoredUser() != null;
}

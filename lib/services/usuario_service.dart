import '../models/models.dart';
import 'api_client.dart';

class UsuarioService {
  UsuarioService(this._api);

  final ApiClient _api;

  Future<List<UsuarioConta>> list({String? igrejaId}) async {
    final query = igrejaId == null ? null : {'igrejaId': igrejaId};
    final list = await _api.get('/usuarios', query: query) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<UsuarioConta> createFromPessoa({
    required String pessoaId,
    required String username,
    required String email,
    required String senha,
    required String igrejaId,
  }) async {
    final json = await _api.post('/pessoas/$pessoaId/usuario', {
      'username': username,
      'email': email,
      'senha': senha,
      'igrejaId': igrejaId,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  /// Substitui os papéis do usuário. PASTOR/SECRETARIA exigem
  /// `papeisGestaoAtribuir`; papéis customizados exigem `papeisCustomGerir`.
  Future<UsuarioConta> alterarPapeis(String usuarioId, List<String> papeis) async {
    final json = await _api.put('/usuarios/$usuarioId/papeis', {
      'papeis': papeis,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  /// Nomes dos papéis customizados (não-sistema) da igreja.
  Future<List<String>> listarPapeisCustomizados(String igrejaId) async {
    final list = await _api.get('/papeis', query: {'igrejaId': igrejaId})
        as List<dynamic>;
    return [
      for (final e in list)
        if ((e as Map<String, dynamic>)['sistema'] != true) e['nome'] as String,
    ];
  }

  UsuarioConta _map(Map<String, dynamic> json) {
    return UsuarioConta(
      id: json['id'] as String,
      username: json['username'] as String? ?? json['email'] as String? ?? '',
      email: json['email'] as String? ?? '',
      pessoaId: json['pessoaId'] as String?,
      pessoaNome: json['pessoaNome'] as String?,
      igrejaId: json['igrejaId'] as String? ?? '',
      igrejaNome: json['igrejaNome'] as String? ?? '',
      papeis: (json['papeis'] as List<dynamic>? ?? [])
          .map((p) => p as String)
          .toList(),
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

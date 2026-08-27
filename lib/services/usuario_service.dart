import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import 'api_client.dart';

class UsuarioService {
  UsuarioService(this._api);

  final ApiClient _api;

  Future<List<UsuarioConta>> list({String? igrejaId}) async {
    if (AppConfig.useMock) {
      if (igrejaId == null || igrejaId.isEmpty) return mockDelay(<UsuarioConta>[]);
      var items = mockUsuarios.where((u) => u.igrejaId == igrejaId).toList();
      return mockDelay(items);
    }
    final query = igrejaId == null ? null : {'igrejaId': igrejaId};
    final list = await _api.get('/usuarios', query: query) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<UsuarioConta> createFromPessoa({
    required String pessoaId,
    required String username,
    required String email,
    required String senha,
    required List<Role> papeis,
    required String igrejaId,
    required String igrejaNome,
    String? pessoaNome,
  }) async {
    if (AppConfig.useMock) {
      final pessoaIndex = mockPessoas.indexWhere((p) => p.id == pessoaId);
      if (pessoaIndex < 0) throw Exception('Pessoa não encontrada.');
      if (papeis.contains(Role.admin) || papeis.contains(Role.pastor)) {
        throw Exception('Não é permitido atribuir ADMIN ou PASTOR por este fluxo.');
      }
      if (mockPessoas[pessoaIndex].temUsuario) {
        throw Exception('Esta pessoa já possui usuário.');
      }
      final id = 'u${DateTime.now().millisecondsSinceEpoch}';
      final created = UsuarioConta(
        id: id,
        username: username,
        email: email,
        pessoaId: pessoaId,
        pessoaNome: pessoaNome ?? mockPessoas[pessoaIndex].nome,
        igrejaId: igrejaId,
        igrejaNome: igrejaNome,
        papeis: papeis,
        ativo: true,
      );
      mockUsuarios.insert(0, created);
      mockPessoas[pessoaIndex] = mockPessoas[pessoaIndex].copyWith(usuarioId: id);
      return mockDelay(created);
    }
    final json = await _api.post('/pessoas/$pessoaId/usuario', {
      'username': username,
      'email': email,
      'senha': senha,
      'papeis': papeis.map(roleToString).toList(),
      'igrejaId': igrejaId,
    }) as Map<String, dynamic>;
    return _map(json);
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
          .map((p) => roleFromString(p as String))
          .toList(),
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

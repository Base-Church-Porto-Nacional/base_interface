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
    required List<Role> papeis,
    required String igrejaId,
    required String igrejaNome,
    String? pessoaNome,
  }) async {
    if (papeis.contains(Role.contador)) await _garantirPapelContador(igrejaId);
    final json = await _api.post('/pessoas/$pessoaId/usuario', {
      'username': username,
      'email': email,
      'senha': senha,
      'papeis': papeis.map(roleToString).toList(),
      'igrejaId': igrejaId,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<void> _garantirPapelContador(String igrejaId) async {
    final papeis = await _api.get('/papeis', query: {'igrejaId': igrejaId}) as List<dynamic>;
    Map<String, dynamic>? contador;
    for (final e in papeis) {
      final papel = e as Map<String, dynamic>;
      if ((papel['nome'] as String?)?.toUpperCase() == 'CONTADOR') contador = papel;
    }
    final body = {
      'nome': 'CONTADOR',
      'descricao': contador?['descricao'] ?? 'Recepção — lança a contagem do culto',
      'podeLancarContagem': true,
      'igrejaId': igrejaId,
    };
    if (contador == null) {
      await _api.post('/papeis', body);
    } else if (contador['podeLancarContagem'] != true) {
      await _api.put('/papeis/${contador['id']}', body);
    }
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

import '../models/models.dart';
import 'api_client.dart';

class LinkAcesso {
  const LinkAcesso({required this.link, required this.enviadoWhatsapp});

  final String link;
  final bool enviadoWhatsapp;
}

class UsuarioService {
  UsuarioService(this._api);

  final ApiClient _api;

  Future<List<UsuarioConta>> list({String? igrejaId}) async {
    final query = igrejaId == null ? null : {'igrejaId': igrejaId};
    final list = await _api.get('/usuarios', query: query) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  /// Cria a conta CONVIDADO (ou reenvia o convite) e devolve o link de acesso.
  Future<LinkAcesso> convidar(String pessoaId) async {
    final json = await _api.post('/pessoas/$pessoaId/convite', {}) as Map<String, dynamic>;
    return _link(json);
  }

  /// Gera link de redefinição de senha (válido por 1 hora) de conta ATIVA.
  Future<LinkAcesso> gerarRedefinicao(String usuarioId) async {
    final json = await _api.post('/usuarios/$usuarioId/redefinicao-senha', {})
        as Map<String, dynamic>;
    return _link(json);
  }

  Future<UsuarioConta> desativar(String usuarioId) async {
    final json = await _api.post('/usuarios/$usuarioId/desativar', {}) as Map<String, dynamic>;
    return _map(json);
  }

  Future<UsuarioConta> reativar(String usuarioId) async {
    final json = await _api.post('/usuarios/$usuarioId/reativar', {}) as Map<String, dynamic>;
    return _map(json);
  }

  LinkAcesso _link(Map<String, dynamic> json) => LinkAcesso(
        link: json['link'] as String,
        enviadoWhatsapp: json['enviadoWhatsapp'] as bool? ?? false,
      );

  /// Substitui os papéis do usuário. PASTOR/SECRETARIA exigem
  /// `papeisGestaoAtribuir`; papéis customizados exigem `papeisCustomGerir`.
  Future<UsuarioConta> alterarPapeis(String usuarioId, List<String> papeis) async {
    final json = await _api.put('/usuarios/$usuarioId/papeis', {
      'papeis': papeis,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  /// Cria um papel customizado da igreja (`POST /papeis`). Nomes reservados
  /// (PASTOR, LIDER, ...) são recusados pelo servidor. Devolve o nome salvo.
  Future<String> criarPapel({
    required String nome,
    required bool podeLancarContagem,
    required String igrejaId,
  }) async {
    final json = await _api.post('/papeis', {
      'nome': nome,
      'podeLancarContagem': podeLancarContagem,
      'igrejaId': igrejaId,
    }) as Map<String, dynamic>;
    return json['nome'] as String;
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
      email: json['email'] as String? ?? '',
      telefone: json['telefone'] as String?,
      pessoaId: json['pessoaId'] as String?,
      pessoaNome: json['pessoaNome'] as String?,
      igrejaId: json['igrejaId'] as String? ?? '',
      igrejaNome: json['igrejaNome'] as String? ?? '',
      papeis: (json['papeis'] as List<dynamic>? ?? [])
          .map((p) => p as String)
          .toList(),
      status: json['status'] as String? ?? 'ATIVO',
    );
  }
}

import '../models/models.dart';
import 'api_client.dart';

class MinisterioService {
  MinisterioService(this._api);

  final ApiClient _api;

  Future<List<Ministerio>> list({String? igrejaId}) async {
    final query = igrejaId == null ? null : {'igrejaId': igrejaId};
    final list = await _api.get('/ministerios', query: query) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<Ministerio> getById(String id) async {
    final json = await _api.get('/ministerios/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<Ministerio> update(
    String id, {
    required String nome,
    String? descricao,
    required bool ativo,
    MinisterioTipo? tipo,
    String? liderPessoaId,
    String? coordenadorPessoaId,
    String? anotacoes,
    String? ordem,
    String? baseMinisterialId,
  }) async {
    final json = await _api.put('/ministerios/$id', {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      if (tipo != null) 'tipo': ministerioTipoToString(tipo),
      'liderPessoaId': liderPessoaId,
      'coordenadorPessoaId': coordenadorPessoaId,
      'anotacoes': anotacoes,
      'ordem': ordem,
      'baseMinisterialId': baseMinisterialId,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<Ministerio> create({
    required String nome,
    required String igrejaId,
    required MinisterioTipo tipo,
    String? descricao,
    bool ativo = true,
    String? liderPessoaId,
    String? coordenadorPessoaId,
    String? baseMinisterialId,
  }) async {
    final json = await _api.post('/ministerios', body: {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'igrejaId': igrejaId,
      'tipo': ministerioTipoToString(tipo),
      'liderPessoaId': liderPessoaId,
      'coordenadorPessoaId': coordenadorPessoaId,
      'baseMinisterialId': baseMinisterialId,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Ministerio _map(Map<String, dynamic> json) {
    final servicosJson = json['servicos'] as List<dynamic>? ?? [];
    return Ministerio(
      id: json['id'] as String,
      nome: json['nome'] as String,
      liderNome: json['liderNome'] as String? ?? '—',
      liderPessoaId: json['liderPessoaId'] as String?,
      coordenadorPessoaId: json['coordenadorPessoaId'] as String?,
      coordenadorNome: json['coordenadorNome'] as String?,
      totalVoluntarios: json['totalVoluntarios'] as int? ?? 0,
      totalServicos: json['totalServicos'] as int? ?? 0,
      ativo: json['ativo'] as bool? ?? true,
      descricao: json['descricao'] as String?,
      igrejaId: json['igrejaId'] as String? ?? '',
      tipo: ministerioTipoFromString(json['tipo'] as String? ?? 'GERAL'),
      anotacoes: json['anotacoes'] as String?,
      ordem: json['ordem'] as String?,
      baseMinisterialId: json['baseMinisterialId'] as String?,
      baseMinisterialNome: json['baseMinisterialNome'] as String?,
      servicos: servicosJson
          .map(
            (e) => Servico(
              id: e['id'] as String,
              ministerioId: e['ministerioId'] as String? ?? json['id'] as String,
              nome: e['nome'] as String,
              ficcao: e['ficcao'] as bool? ?? false,
              ativo: e['ativo'] as bool? ?? true,
              descricao: e['descricao'] as String?,
            ),
          )
          .toList(),
    );
  }
}

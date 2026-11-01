import '../models/models.dart';
import 'api_client.dart';

class BaseMinisterialService {
  BaseMinisterialService(this._api);

  final ApiClient _api;

  Future<List<BaseMinisterial>> list({String? igrejaId}) async {
    final query = igrejaId == null ? null : {'igrejaId': igrejaId};
    final list = await _api.get('/bases-ministeriais', query: query) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<BaseMinisterial> getById(String id) async {
    final json = await _api.get('/bases-ministeriais/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<BaseMinisterial> update(
    String id, {
    required String nome,
    String? descricao,
    required bool ativo,
    String? liderPessoaId,
    String? liderNome,
    String? coordenadorPessoaId,
    String? coordenadorNome,
    String? ordem,
  }) async {
    final json = await _api.put('/bases-ministeriais/$id', {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'liderPessoaId': liderPessoaId,
      'coordenadorPessoaId': coordenadorPessoaId,
      'ordem': ordem,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<BaseMinisterial> create({
    required String nome,
    required String igrejaId,
    String? descricao,
    bool ativo = true,
    String? liderPessoaId,
    String? liderNome,
    String? coordenadorPessoaId,
    String? coordenadorNome,
  }) async {
    final json = await _api.post('/bases-ministeriais', {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'igrejaId': igrejaId,
      'liderPessoaId': liderPessoaId,
      'coordenadorPessoaId': coordenadorPessoaId,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  BaseMinisterial _map(Map<String, dynamic> json) {
    return BaseMinisterial(
      id: json['id'] as String,
      nome: json['nome'] as String,
      liderNome: json['liderNome'] as String? ?? '—',
      liderPessoaId: json['liderPessoaId'] as String?,
      coordenadorPessoaId: json['coordenadorPessoaId'] as String?,
      coordenadorNome: json['coordenadorNome'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      descricao: json['descricao'] as String?,
      igrejaId: json['igrejaId'] as String? ?? '',
      ordem: json['ordem'] as String?,
    );
  }
}

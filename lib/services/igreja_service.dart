import '../models/models.dart';
import 'api_client.dart';

class IgrejaService {
  IgrejaService(this._api);

  final ApiClient _api;

  Future<List<Igreja>> listVisiveis(AuthUser user) async {
    final list = await _api.get('/igrejas') as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<List<Igreja>> list() async {
    final list = await _api.get('/igrejas') as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<Igreja> getById(String id) async {
    final json = await _api.get('/igrejas/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<Igreja> createFilial({
    required String matrizId,
    required String nome,
    required String pastorPessoaId,
    required String pastorNome,
    required String adminNome,
    required String adminEmail,
    required String adminUsername,
  }) async {
    final json = await _api.post('/igrejas/$matrizId/filiais', {
      'nome': nome,
      'pastorPessoaId': pastorPessoaId,
      'adminNome': adminNome,
      'adminEmail': adminEmail,
      'adminUsername': adminUsername,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<Igreja> update(
    String id, {
    required String nome,
    required String pastorPessoaId,
    required String pastorNome,
    required bool ativo,
  }) async {
    final json = await _api.put('/igrejas/$id', {
      'nome': nome,
      'pastorPessoaId': pastorPessoaId,
      'ativo': ativo,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Igreja _map(Map<String, dynamic> json) {
    return Igreja(
      id: json['id'] as String,
      nome: json['nome'] as String,
      tipo: (json['tipo'] as String? ?? 'FILIAL').toUpperCase() == 'MATRIZ'
          ? IgrejaTipo.matriz
          : IgrejaTipo.filial,
      igrejaMatrizId: json['igrejaMatrizId'] as String?,
      pastorPessoaId: json['pastorPessoaId'] as String? ?? '',
      pastorNome: json['pastorNome'] as String? ?? '',
      adminUsuarioId: json['adminUsuarioId'] as String? ?? '',
      adminNome: json['adminNome'] as String? ?? '',
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

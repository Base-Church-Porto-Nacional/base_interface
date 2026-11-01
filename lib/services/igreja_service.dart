import '../models/models.dart';
import 'api_client.dart';

class IgrejaService {
  IgrejaService(this._api);

  final ApiClient _api;

  Future<List<Igreja>> listVisiveis(AuthUser user) async {
    final list = await _api.get('/igrejas') as List<dynamic>;
    return list.map((e) => Igreja.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Igreja> getById(String id) async {
    final json = await _api.get('/igrejas/$id') as Map<String, dynamic>;
    return Igreja.fromJson(json);
  }

  Future<Igreja> createFilial({
    required String matrizId,
    required String nome,
    required String pastorPessoaId,
    required String adminNome,
    required String adminEmail,
    required String adminUsername,
  }) async {
    final json = await _api.post('/igrejas/$matrizId/filiais', body: {
      'nome': nome,
      'pastorPessoaId': pastorPessoaId,
      'adminNome': adminNome,
      'adminEmail': adminEmail,
      'adminUsername': adminUsername,
    }) as Map<String, dynamic>;
    return Igreja.fromJson(json);
  }
}

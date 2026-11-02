import '../models/models.dart';
import 'api_client.dart';

typedef ResultadoPastor = ({
  Igreja igreja,
  ({String link, bool enviadoWhatsapp})? convite,
});

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

  Future<ResultadoPastor> criarFilial({
    required String matrizId,
    required String nome,
    String? pastorPessoaId,
    String? pastorNome,
    String? pastorEmail,
    String? pastorWhatsapp,
  }) async {
    final pastor = pastorPessoaId != null
        ? {'pessoaId': pastorPessoaId}
        : {
            'nome': pastorNome,
            'email': ?pastorEmail,
            'whatsapp': ?pastorWhatsapp,
          };
    final json = await _api.post('/igrejas/$matrizId/filiais', {
      'nome': nome,
      'pastor': pastor,
    }) as Map<String, dynamic>;
    return _resultado(json);
  }

  Future<ResultadoPastor> trocarPastor(String igrejaId, String pessoaId) async {
    final json = await _api.put('/igrejas/$igrejaId/pastor', {
      'pessoaId': pessoaId,
    }) as Map<String, dynamic>;
    return _resultado(json);
  }

  Future<Igreja> update(
    String id, {
    required String nome,
    required bool ativo,
  }) async {
    final json = await _api.put('/igrejas/$id', {
      'nome': nome,
      'ativo': ativo,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  ResultadoPastor _resultado(Map<String, dynamic> json) {
    final c = json['convite'] as Map<String, dynamic>?;
    return (
      igreja: _map(json['igreja'] as Map<String, dynamic>),
      convite: c == null
          ? null
          : (
              link: c['link'] as String,
              enviadoWhatsapp: c['enviadoWhatsapp'] as bool? ?? false,
            ),
    );
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
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

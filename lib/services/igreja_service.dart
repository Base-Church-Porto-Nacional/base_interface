import '../models/models.dart';
import 'api_client.dart';

typedef ResultadoPastor = ({
  Igreja igreja,
  ({String link, bool enviadoWhatsapp})? convite,
});

/// Resposta da criação de filial. `participacoesAjustadas`: quantas
/// participações futuras do pastor transferido (escalas, cultos, cronograma)
/// foram ajustadas na igreja de origem.
typedef FilialCriada = ({
  Igreja igreja,
  ({String link, bool enviadoWhatsapp})? convite,
  int participacoesAjustadas,
});

/// Resposta da troca de pastor. `anteriorMantevePastor`: o novo ainda não está
/// ativo, então o anterior ficou com o papel PASTOR (remover depois em Papéis).
typedef PastorTrocado = ({
  Igreja igreja,
  ({String link, bool enviadoWhatsapp})? convite,
  bool anteriorMantevePastor,
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

  Future<FilialCriada> criarFilial({
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
    final r = _resultado(json);
    return (
      igreja: r.igreja,
      convite: r.convite,
      participacoesAjustadas: (json['participacoesAjustadas'] as num?)?.toInt() ?? 0,
    );
  }

  Future<PastorTrocado> trocarPastor(String igrejaId, String pessoaId) async {
    final json = await _api.put('/igrejas/$igrejaId/pastor', {
      'pessoaId': pessoaId,
    }) as Map<String, dynamic>;
    final r = _resultado(json);
    return (
      igreja: r.igreja,
      convite: r.convite,
      anteriorMantevePastor: json['anteriorMantevePastor'] as bool? ?? false,
    );
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

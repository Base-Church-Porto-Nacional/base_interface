import '../models/models.dart';
import '../utils/format.dart';
import 'api_client.dart';

class CategoriaCultoService {
  CategoriaCultoService(this._api);

  final ApiClient _api;

  Future<List<CategoriaCulto>> list({String? igrejaId, bool? ativo}) async {
    final query = <String, String>{};
    if (igrejaId != null && igrejaId.isNotEmpty) query['igrejaId'] = igrejaId;
    if (ativo != null) query['ativo'] = '$ativo';
    final list = await _api.get(
      '/categorias-culto',
      query: query.isEmpty ? null : query,
    ) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<CategoriaCulto> getById(String id) async {
    final json = await _api.get('/categorias-culto/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<CategoriaCulto> create(CategoriaCulto categoria) async {
    final json = await _api.post('/categorias-culto', body: {
      'titulo': categoria.titulo.trim(),
      'descricao': categoria.descricao,
      'diaSemana': diaSemanaApiToString(categoria.diaSemana),
      'horaInicio': normalizeHoraApi(categoria.horaInicio),
      'duracaoMinutos': categoria.duracaoMinutos,
      'pregadorPadraoId': categoria.pregadorPadraoId,
      'igrejaId': categoria.igrejaId,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<CategoriaCulto> update(CategoriaCulto categoria) async {
    final json = await _api.put('/categorias-culto/${categoria.id}', {
      'titulo': categoria.titulo.trim(),
      'descricao': categoria.descricao,
      'diaSemana': diaSemanaApiToString(categoria.diaSemana),
      'horaInicio': normalizeHoraApi(categoria.horaInicio),
      'duracaoMinutos': categoria.duracaoMinutos,
      'pregadorPadraoId': categoria.pregadorPadraoId,
      'ativo': categoria.ativo,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<void> delete(String id) async {
    await _api.delete('/categorias-culto/$id');
  }

  Future<String> gerarCultos(String id, {String? competencia}) async {
    final text = await _api.post(
      '/categorias-culto/$id/gerar-cultos',
      query: {'competencia': ?competencia},
    );
    return text?.toString() ?? '';
  }

  CategoriaCulto _map(Map<String, dynamic> json) {
    return CategoriaCulto(
      id: json['id'] as String,
      igrejaId: json['igrejaId'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      descricao: json['descricao'] as String?,
      diaSemana: diaSemanaFromApi(json['diaSemana'] as String? ?? 'DOMINGO'),
      horaInicio: json['horaInicio'] as String? ?? '20:00:00',
      duracaoMinutos: (json['duracaoMinutos'] as num?)?.toInt() ?? 90,
      pregadorPadraoId: json['pregadorPadraoId'] as String?,
      pregadorPadraoNome: json['pregadorPadraoNome'] as String?,
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}
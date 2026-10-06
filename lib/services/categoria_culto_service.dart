import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import '../utils/format.dart';
import 'api_client.dart';

class CategoriaCultoService {
  CategoriaCultoService(this._api);

  final ApiClient _api;

  Future<List<CategoriaCulto>> list({String? igrejaId, bool? ativo}) async {
    if (AppConfig.useMock) {
      final items = mockCategoriasCulto
          .where(
            (c) =>
                (igrejaId == null || igrejaId.isEmpty || c.igrejaId == igrejaId) &&
                (ativo == null || c.ativo == ativo),
          )
          .toList()
        ..sort((a, b) => a.titulo.compareTo(b.titulo));
      return mockDelay(items);
    }
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
    if (AppConfig.useMock) {
      final c = categoriaCultoById(id);
      if (c == null) throw Exception('Categoria não encontrada.');
      return mockDelay(c);
    }
    final json = await _api.get('/categorias-culto/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<CategoriaCulto> create(CategoriaCulto categoria) async {
    if (AppConfig.useMock) {
      final exists = mockCategoriasCulto.any(
        (c) =>
            c.igrejaId == categoria.igrejaId &&
            c.titulo.toLowerCase() == categoria.titulo.trim().toLowerCase(),
      );
      if (exists) throw Exception('Título já existe nesta igreja.');
      final created = CategoriaCulto(
        id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
        igrejaId: categoria.igrejaId,
        titulo: categoria.titulo.trim(),
        descricao: categoria.descricao,
        diaSemana: categoria.diaSemana,
        horaInicio: categoria.horaInicio,
        duracaoMinutos: categoria.duracaoMinutos,
        pregadorPadraoId: categoria.pregadorPadraoId,
        pregadorPadraoNome: categoria.pregadorPadraoNome,
        ativo: true,
      );
      mockCategoriasCulto.insert(0, created);
      return mockDelay(created);
    }
    final json = await _api.post('/categorias-culto', {
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
    if (AppConfig.useMock) {
      final index = mockCategoriasCulto.indexWhere((c) => c.id == categoria.id);
      if (index < 0) throw Exception('Categoria não encontrada.');
      final updated = CategoriaCulto(
        id: categoria.id,
        igrejaId: categoria.igrejaId,
        titulo: categoria.titulo.trim(),
        descricao: categoria.descricao,
        diaSemana: categoria.diaSemana,
        horaInicio: categoria.horaInicio,
        duracaoMinutos: categoria.duracaoMinutos,
        pregadorPadraoId: categoria.pregadorPadraoId,
        pregadorPadraoNome: categoria.pregadorPadraoNome,
        ativo: categoria.ativo,
      );
      mockCategoriasCulto[index] = updated;
      return mockDelay(updated);
    }
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
    if (AppConfig.useMock) {
      final temCultos = mockCultos.any((c) => c.categoriaCultoId == id);
      if (temCultos) {
        final index = mockCategoriasCulto.indexWhere((c) => c.id == id);
        if (index >= 0) {
          final c = mockCategoriasCulto[index];
          mockCategoriasCulto[index] = c.copyWith(ativo: false);
        }
      } else {
        mockCategoriasCulto.removeWhere((c) => c.id == id);
      }
      return mockDelay(null);
    }
    await _api.delete('/categorias-culto/$id');
  }

  Future<String> gerarCultos(String id, {String? competencia}) async {
    if (AppConfig.useMock) {
      final categoria = categoriaCultoById(id);
      if (categoria == null) throw Exception('Categoria não encontrada.');
      final comp = competencia ?? competenciaProximoMes();
      final criados = gerarCultosCategoriaMock(categoria, comp);
      return mockDelay(
        'Cultos de ${categoria.titulo} em $comp: ${criados.length} criados.',
      );
    }
    final query = competencia == null ? '' : '?competencia=$competencia';
    final text = await _api.post('/categorias-culto/$id/gerar-cultos$query');
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
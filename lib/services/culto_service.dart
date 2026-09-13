import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import '../utils/format.dart';
import 'api_client.dart';

class CultoService {
  CultoService(this._api);

  final ApiClient _api;

  Future<List<Culto>> list({
    String? igrejaId,
    String? categoriaId,
    String? competencia,
    CultoStatus? status,
    String? inicio,
    String? fim,
    bool? ativo,
  }) async {
    if (AppConfig.useMock) {
      final items = mockCultos
          .where(
            (c) =>
                (igrejaId == null || igrejaId.isEmpty || c.igrejaId == igrejaId) &&
                (categoriaId == null || c.categoriaCultoId == categoriaId) &&
                (competencia == null || c.competencia == competencia) &&
                (status == null || c.status == status) &&
                (inicio == null || c.data.compareTo(inicio) >= 0) &&
                (fim == null || c.data.compareTo(fim) <= 0) &&
                (ativo == null || c.ativo == ativo),
          )
          .toList()
        ..sort((a, b) => a.data.compareTo(b.data));
      return mockDelay(items);
    }
    final query = <String, String>{};
    if (igrejaId != null && igrejaId.isNotEmpty) query['igrejaId'] = igrejaId;
    if (categoriaId != null && categoriaId.isNotEmpty) {
      query['categoriaId'] = categoriaId;
    }
    if (competencia != null && competencia.isNotEmpty) {
      query['competencia'] = competencia;
    }
    if (status != null) query['status'] = cultoStatusApiToString(status);
    if (inicio != null && inicio.isNotEmpty) query['inicio'] = inicio;
    if (fim != null && fim.isNotEmpty) query['fim'] = fim;
    if (ativo != null) query['ativo'] = '$ativo';
    final list = await _api.get('/cultos', query: query.isEmpty ? null : query)
        as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<Culto> getById(String id) async {
    if (AppConfig.useMock) {
      final culto = _cultoMockById(id);
      if (culto == null) throw Exception('Culto não encontrado.');
      return mockDelay(culto);
    }
    final json = await _api.get('/cultos/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<Culto> create(Culto culto) async {
    if (AppConfig.useMock) {
      final dup = mockCultos.any(
        (c) => c.categoriaCultoId == culto.categoriaCultoId && c.data == culto.data,
      );
      if (dup) throw Exception('Já existe um culto desta categoria nesta data.');
      final created = Culto(
        id: 'culto-${DateTime.now().millisecondsSinceEpoch}',
        igrejaId: culto.igrejaId,
        categoriaCultoId: culto.categoriaCultoId,
        categoriaCultoTitulo: culto.categoriaCultoTitulo,
        titulo: culto.titulo,
        tema: culto.tema,
        data: culto.data,
        horaInicio: culto.horaInicio,
        horaFim: culto.horaFim,
        pregadorId: culto.pregadorId,
        pregadorNome: culto.pregadorNome,
        status: CultoStatus.agendado,
        competencia: culto.competencia,
        ativo: true,
        janelaConfiguracaoAberta: janelaConfiguracaoAbertaMock(culto.data),
        temRelatorio: false,
      );
      mockCultos.insert(0, created);
      return mockDelay(created);
    }
    final body = <String, dynamic>{
      'categoriaCultoId': culto.categoriaCultoId,
    };
    if (culto.igrejaId.isNotEmpty) body['igrejaId'] = culto.igrejaId;
    if (culto.titulo.isNotEmpty) body['titulo'] = culto.titulo;
    if (culto.tema != null) body['tema'] = culto.tema;
    body['data'] = culto.data;
    if (culto.horaInicio.isNotEmpty) {
      body['horaInicio'] = normalizeHoraApi(culto.horaInicio);
    }
    if (culto.horaFim != null && culto.horaFim!.isNotEmpty) {
      body['horaFim'] = normalizeHoraApi(culto.horaFim!);
    }
    if (culto.pregadorId != null && culto.pregadorId!.isNotEmpty) {
      body['pregadorId'] = culto.pregadorId;
    }
    final json = await _api.post('/cultos', body) as Map<String, dynamic>;
    return _map(json);
  }

  Future<Culto> update(Culto culto) async {
    if (AppConfig.useMock) {
      final index = mockCultos.indexWhere((c) => c.id == culto.id);
      if (index < 0) throw Exception('Culto não encontrado.');
      final original = mockCultos[index];
      final updated = Culto(
        id: culto.id,
        igrejaId: original.igrejaId,
        categoriaCultoId: original.categoriaCultoId,
        categoriaCultoTitulo: original.categoriaCultoTitulo,
        titulo: culto.titulo,
        tema: culto.tema,
        data: culto.data,
        horaInicio: culto.horaInicio,
        horaFim: culto.horaFim,
        pregadorId: culto.pregadorId,
        pregadorNome: culto.pregadorNome ?? original.pregadorNome,
        status: culto.status,
        competencia: original.competencia,
        escalaId: original.escalaId,
        ativo: culto.ativo,
        janelaConfiguracaoAberta:
            janelaConfiguracaoAbertaMock(culto.data),
        temRelatorio: original.temRelatorio,
      );
      mockCultos[index] = updated;
      return mockDelay(updated);
    }
    final json = await _api.put('/cultos/${culto.id}', {
      'titulo': culto.titulo,
      'tema': culto.tema,
      'data': culto.data,
      'horaInicio': normalizeHoraApi(culto.horaInicio),
      'horaFim': culto.horaFim == null || culto.horaFim!.isEmpty
          ? null
          : normalizeHoraApi(culto.horaFim!),
      'pregadorId': culto.pregadorId,
      'status': cultoStatusApiToString(culto.status),
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<void> delete(String id) async {
    if (AppConfig.useMock) {
      final index = mockCultos.indexWhere((c) => c.id == id);
      if (index < 0) throw Exception('Culto não encontrado.');
      if (mockCultos[index].temRelatorio) {
        throw Exception('Não é possível excluir um culto que já possui relatório');
      }
      mockCultos.removeAt(index);
      return mockDelay(null);
    }
    await _api.delete('/cultos/$id');
  }

  Future<CultoConteudo> getConteudo(String cultoId) async {
    if (AppConfig.useMock) {
      for (final c in mockCultosConteudos) {
        if (c.cultoId == cultoId) return mockDelay(c);
      }
      return mockDelay(CultoConteudo(cultoId: cultoId));
    }
    final json = await _api.get('/cultos/$cultoId/conteudo') as Map<String, dynamic>;
    return _mapConteudo(json, cultoId);
  }

  Future<CultoConteudo> saveConteudo(
    String cultoId, {
    String? textoPregacao,
    String? louvor,
    String? tema,
    String? pregadorPessoaId,
  }) async {
    final body = <String, dynamic>{};
    if (textoPregacao != null) body['textoPregacao'] = textoPregacao;
    if (louvor != null) body['louvor'] = louvor;
    if (tema != null) body['tema'] = tema;
    if (pregadorPessoaId != null) body['pregadorPessoaId'] = pregadorPessoaId;
    if (AppConfig.useMock) {
      final index = mockCultosConteudos.indexWhere((c) => c.cultoId == cultoId);
      final current = index >= 0
          ? mockCultosConteudos[index]
          : CultoConteudo(cultoId: cultoId);
      final pessoa = pregadorPessoaId == null ? null : pessoaById(pregadorPessoaId);
      final merged = CultoConteudo(
        cultoId: cultoId,
        textoPregacao: textoPregacao ?? current.textoPregacao,
        louvor: louvor ?? current.louvor,
        tema: tema ?? current.tema,
        pregadorId: pregadorPessoaId ?? current.pregadorId,
        pregadorNome: pessoa?.nome ?? current.pregadorNome,
      );
      if (index >= 0) {
        mockCultosConteudos[index] = merged;
      } else {
        mockCultosConteudos.add(merged);
      }
      return mockDelay(merged);
    }
    final json = await _api.put('/cultos/$cultoId/conteudo', body)
        as Map<String, dynamic>;
    return _mapConteudo(json, cultoId);
  }

  Future<CultoRelatorio> getRelatorio(String cultoId) async {
    if (AppConfig.useMock) {
      for (final r in mockCultosRelatorios) {
        if (r.cultoId == cultoId) return mockDelay(r);
      }
      return mockDelay(CultoRelatorio(cultoId: cultoId));
    }
    final json = await _api.get('/cultos/$cultoId/relatorio') as Map<String, dynamic>;
    return _mapRelatorio(json, cultoId);
  }

  Future<CultoRelatorio> saveRelatorio(CultoRelatorio relatorio) async {
    if (AppConfig.useMock) {
      final index = mockCultosRelatorios.indexWhere((r) => r.cultoId == relatorio.cultoId);
      if (index >= 0) {
        mockCultosRelatorios[index] = relatorio;
      } else {
        mockCultosRelatorios.add(relatorio);
      }
      final cultoIndex = mockCultos.indexWhere((c) => c.id == relatorio.cultoId);
      if (cultoIndex >= 0) {
        mockCultos[cultoIndex] = mockCultos[cultoIndex].copyWith(
          status: CultoStatus.realizado,
          temRelatorio: true,
        );
      }
      return mockDelay(relatorio);
    }
    final json = await _api.put('/cultos/${relatorio.cultoId}/relatorio', {
      'adultos': relatorio.adultos,
      'criancas': relatorio.criancas,
      'conversoes': relatorio.conversoes,
      'reconciliacoes': relatorio.reconciliacoes,
      'aliancas': relatorio.aliancas,
      'carros': relatorio.carros,
      'motos': relatorio.motos,
      'bicicletas': relatorio.bicicletas,
      'observacoes': relatorio.observacoes,
    }) as Map<String, dynamic>;
    return _mapRelatorio(json, relatorio.cultoId);
  }

  Future<String> gerarProximoMes({String? igrejaId}) async {
    if (AppConfig.useMock) {
      final comp = competenciaProximoMes();
      return mockDelay(_gerarMesMock(igrejaId, comp));
    }
    final query = igrejaId == null || igrejaId.isEmpty
        ? ''
        : '?igrejaId=$igrejaId';
    final text = await _api.post('/cultos/automacao/proximo-mes$query');
    return text?.toString() ?? '';
  }

  Future<String> gerarMes(String competencia, {String? igrejaId}) async {
    if (AppConfig.useMock) {
      return mockDelay(_gerarMesMock(igrejaId, competencia));
    }
    final query = igrejaId == null || igrejaId.isEmpty
        ? ''
        : '?igrejaId=$igrejaId';
    final text = await _api.post('/cultos/automacao/mes/$competencia$query');
    return text?.toString() ?? '';
  }

  String _gerarMesMock(String? igrejaId, String competencia) {
    final categorias = mockCategoriasCulto
        .where((c) => c.ativo && (igrejaId == null || c.igrejaId == igrejaId))
        .toList();
    var criados = 0;
    var existentes = 0;
    for (final cat in categorias) {
      final datas = datasDaCompetencia(cat.diaSemana, competencia);
      for (final data in datas) {
        final tem = mockCultos.any(
          (c) => c.categoriaCultoId == cat.id && c.data == data,
        );
        if (tem) {
          existentes++;
        } else {
          criados++;
        }
      }
    }
    for (final cat in categorias) {
      gerarCultosCategoriaMock(cat, competencia);
    }
    return 'Cultos de $competencia gerados: $criados criados, $existentes já existentes.';
  }

  Culto? _cultoMockById(String id) {
    for (final c in mockCultos) {
      if (c.id == id) return c;
    }
    return null;
  }

  Culto _map(Map<String, dynamic> json) {
    return Culto(
      id: json['id'] as String,
      igrejaId: json['igrejaId'] as String? ?? '',
      categoriaCultoId: json['categoriaCultoId'] as String? ?? '',
      categoriaCultoTitulo: json['categoriaCultoTitulo'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      tema: json['tema'] as String?,
      data: json['data'] as String? ?? '',
      horaInicio: json['horaInicio'] as String? ?? '',
      horaFim: json['horaFim'] as String?,
      pregadorId: json['pregadorId'] as String?,
      pregadorNome: json['pregadorNome'] as String?,
      status: cultoStatusFromApi(json['status'] as String? ?? 'AGENDADO'),
      competencia: json['competencia'] as String? ?? '',
      escalaId: json['escalaId'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      janelaConfiguracaoAberta: json['janelaConfiguracaoAberta'] as bool? ?? false,
      temRelatorio: json['temRelatorio'] as bool? ?? false,
    );
  }

  CultoConteudo _mapConteudo(Map<String, dynamic> json, String cultoId) {
    return CultoConteudo(
      cultoId: json['cultoId'] as String? ?? cultoId,
      textoPregacao: json['textoPregacao'] as String?,
      louvor: json['louvor'] as String?,
      tema: json['tema'] as String?,
      pregadorId: json['pregadorId'] as String?,
      pregadorNome: json['pregadorNome'] as String?,
    );
  }

  CultoRelatorio _mapRelatorio(Map<String, dynamic> json, String cultoId) {
    return CultoRelatorio(
      cultoId: json['cultoId'] as String? ?? cultoId,
      adultos: (json['adultos'] as num?)?.toInt() ?? 0,
      criancas: (json['criancas'] as num?)?.toInt() ?? 0,
      conversoes: (json['conversoes'] as num?)?.toInt() ?? 0,
      reconciliacoes: (json['reconciliacoes'] as num?)?.toInt() ?? 0,
      aliancas: (json['aliancas'] as num?)?.toInt() ?? 0,
      carros: (json['carros'] as num?)?.toInt() ?? 0,
      motos: (json['motos'] as num?)?.toInt() ?? 0,
      bicicletas: (json['bicicletas'] as num?)?.toInt() ?? 0,
      observacoes: json['observacoes'] as String?,
    );
  }
}
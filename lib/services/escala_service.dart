import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import 'api_client.dart';

class EscalaService {
  EscalaService(this._api);

  final ApiClient _api;

  Future<List<Escala>> list({String? igrejaId, String? competencia, String? pessoaId}) async {
    if (AppConfig.useMock) {
      if (igrejaId == null || igrejaId.isEmpty) return mockDelay(<Escala>[]);
      var items = mockEscalas.where((e) => e.igrejaId == igrejaId).toList();
      if (competencia != null && competencia.isNotEmpty) {
        items = items.where((e) => e.competencia == competencia).toList();
      }
      if (pessoaId != null && pessoaId.isNotEmpty) {
        items = items
            .map(
              (e) => e.copyWith(
                voluntarios: e.voluntarios.where((v) => v.pessoaId == pessoaId).toList(),
                itens: e.itens.where((i) => i.pessoaId == pessoaId).toList(),
              ),
            )
            .where((e) => e.voluntarios.isNotEmpty || e.itens.isNotEmpty)
            .toList();
      }
      return mockDelay(items);
    }
    final query = <String, String>{
      if (igrejaId != null) 'igrejaId': igrejaId,
      if (competencia != null) 'competencia': competencia,
      if (pessoaId != null) 'pessoaId': pessoaId,
    };
    final list = await _api.get('/escalas', query: query.isEmpty ? null : query) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<Escala> getById(String id) async {
    if (AppConfig.useMock) {
      return mockDelay(
        mockEscalas.firstWhere(
          (e) => e.id == id,
          orElse: () => throw Exception('Escala não encontrada.'),
        ),
      );
    }
    final json = await _api.get('/escalas/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<Escala> create(Escala escala) async {
    if (AppConfig.useMock) {
      final created = Escala(
        id: 'e${DateTime.now().millisecondsSinceEpoch}',
        titulo: escala.titulo,
        descricao: escala.descricao,
        competencia: escala.competencia,
        tipo: escala.tipo,
        igrejaId: escala.igrejaId,
        ministerioId: escala.ministerioId,
        ministerioNome: escala.ministerioNome,
        supervisorPessoaId: escala.supervisorPessoaId,
        supervisorNome: escala.supervisorNome,
        pregadorPessoaId: escala.pregadorPessoaId,
        pregadorNome: escala.pregadorNome,
        status: EscalaStatus.editando,
        dataEvento: escala.dataEvento,
        horaInicio: escala.horaInicio,
        horaFim: escala.horaFim,
        eventoId: escala.eventoId,
        ativo: true,
        servicos: List.of(escala.servicos),
        voluntarios: _gerarSugestoesPara(escala, escala.servicos, escala.voluntarios, escala.id),
        itens: List.of(escala.itens),
      );
      mockEscalas.insert(0, created);
      return mockDelay(created);
    }
    final json = await _api.post('/escalas', {
      'titulo': escala.titulo,
      'descricao': escala.descricao,
      'competencia': escala.competencia,
      'tipo': escalaTipoToString(escala.tipo),
      'igrejaId': escala.igrejaId,
      'ministerioId': escala.ministerioId,
      'supervisorPessoaId': escala.supervisorPessoaId,
      'dataEvento': escala.dataEvento,
      'horaInicio': escala.horaInicio,
      'horaFim': escala.horaFim,
      'eventoId': escala.eventoId,
      'servicos': escala.servicos
          .map(
            (s) => {
              'servicoId': s.servicoId,
              'quantidadeNecessaria': s.quantidadeNecessaria,
            },
          )
          .toList(),
      'itens': escala.itens.map(_itemToJson).toList(),
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<Escala> update(String id, Escala escala) async {
    if (AppConfig.useMock) {
      final idx = mockEscalas.indexWhere((e) => e.id == id);
      if (idx < 0) throw Exception('Escala não encontrada.');
      final updated = Escala(
        id: id,
        titulo: escala.titulo,
        descricao: escala.descricao,
        competencia: escala.competencia,
        tipo: escala.tipo,
        igrejaId: escala.igrejaId,
        ministerioId: escala.ministerioId,
        ministerioNome: escala.ministerioNome,
        supervisorPessoaId: escala.supervisorPessoaId,
        supervisorNome: escala.supervisorNome,
        pregadorPessoaId: escala.pregadorPessoaId,
        pregadorNome: escala.pregadorNome,
        status: escala.status,
        dataLancamento: escala.dataLancamento,
        dataFinalizacao: escala.dataFinalizacao,
        dataEvento: escala.dataEvento,
        horaInicio: escala.horaInicio,
        horaFim: escala.horaFim,
        eventoId: escala.eventoId,
        ativo: escala.ativo,
        servicos: escala.servicos,
        voluntarios: escala.voluntarios,
        itens: escala.itens,
      );
      mockEscalas[idx] = updated;
      return mockDelay(updated);
    }
    final json = await _api.put('/escalas/$id', {
      'titulo': escala.titulo,
      'descricao': escala.descricao,
      'competencia': escala.competencia,
      'tipo': escalaTipoToString(escala.tipo),
      'igrejaId': escala.igrejaId,
      'ministerioId': escala.ministerioId,
      'supervisorPessoaId': escala.supervisorPessoaId,
      'dataEvento': escala.dataEvento,
      'horaInicio': escala.horaInicio,
      'horaFim': escala.horaFim,
      'eventoId': escala.eventoId,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<void> delete(String id) async {
    if (AppConfig.useMock) {
      mockEscalas.removeWhere((e) => e.id == id);
      return mockDelay(null);
    }
    await _api.delete('/escalas/$id');
  }

  Future<Escala> updateStatus(String id, EscalaStatus status) async {
    if (AppConfig.useMock) {
      final idx = mockEscalas.indexWhere((e) => e.id == id);
      if (idx < 0) throw Exception('Escala não encontrada.');
      final atual = mockEscalas[idx];
      if (!podeTransicionarEscalaStatus(atual.status, status)) {
        throw Exception(
          'Transição ${escalaStatusLabel(atual.status)} → ${escalaStatusLabel(status)} não permitida.',
        );
      }
      final now = DateTime.now().toIso8601String();
      final updated = atual.copyWith(
        status: status,
        dataLancamento: status == EscalaStatus.emAndamento
            ? (atual.dataLancamento ?? now)
            : atual.dataLancamento,
        dataFinalizacao: status == EscalaStatus.emAndamento
            ? null
            : (status == EscalaStatus.finalizada ? now : atual.dataFinalizacao),
      );
      mockEscalas[idx] = updated;
      return mockDelay(updated);
    }
    final json = await _api.put('/escalas/$id/status', {
      'status': escalaStatusToString(status),
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<EscalaServico> addServico(
    String id, {
    required String servicoId,
    required String servicoNome,
    int quantidadeNecessaria = 1,
  }) async {
    if (AppConfig.useMock) {
      final idx = mockEscalas.indexWhere((e) => e.id == id);
      if (idx < 0) throw Exception('Escala não encontrada.');
      final escala = mockEscalas[idx];
      final servico = EscalaServico(
        id: 'sv${DateTime.now().millisecondsSinceEpoch}',
        escalaId: id,
        servicoId: servicoId,
        servicoNome: servicoNome,
        quantidadeNecessaria: quantidadeNecessaria,
      );
      mockEscalas[idx] = escala.copyWith(servicos: [...escala.servicos, servico]);
      return mockDelay(servico);
    }
    final json = await _api.post('/escalas/$id/servicos', {
      'servicoId': servicoId,
      'quantidadeNecessaria': quantidadeNecessaria,
    }) as Map<String, dynamic>;
    return _mapServico(json);
  }

  Future<EscalaServico> updateServico(
    String id,
    String escalaServicoId, {
    int quantidadeNecessaria = 1,
  }) async {
    if (AppConfig.useMock) {
      final idx = mockEscalas.indexWhere((e) => e.id == id);
      if (idx < 0) throw Exception('Escala não encontrada.');
      final escala = mockEscalas[idx];
      final servicos = escala.servicos.map((s) {
        if (s.id != escalaServicoId) return s;
        return EscalaServico(
          id: s.id,
          escalaId: s.escalaId,
          servicoId: s.servicoId,
          servicoNome: s.servicoNome,
          quantidadeNecessaria: quantidadeNecessaria,
        );
      }).toList();
      mockEscalas[idx] = escala.copyWith(servicos: servicos);
      return mockDelay(servicos.firstWhere((s) => s.id == escalaServicoId));
    }
    final json = await _api.put('/escalas/$id/servicos/$escalaServicoId', {
      'quantidadeNecessaria': quantidadeNecessaria,
    }) as Map<String, dynamic>;
    return _mapServico(json);
  }

  Future<void> removeServico(String id, String escalaServicoId) async {
    if (AppConfig.useMock) {
      final idx = mockEscalas.indexWhere((e) => e.id == id);
      if (idx < 0) throw Exception('Escala não encontrada.');
      final escala = mockEscalas[idx];
      mockEscalas[idx] = escala.copyWith(
        servicos: escala.servicos.where((s) => s.id != escalaServicoId).toList(),
      );
      return mockDelay(null);
    }
    await _api.delete('/escalas/$id/servicos/$escalaServicoId');
  }

  Future<EscalaVoluntario> addVoluntario(
    String id, {
    required String pessoaId,
    required String servicoId,
    String? servicoNome,
    String? observacoes,
    String? data,
  }) async {
    if (AppConfig.useMock) {
      final idx = mockEscalas.indexWhere((e) => e.id == id);
      if (idx < 0) throw Exception('Escala não encontrada.');
      final escala = mockEscalas[idx];
      final nomeServico = servicoNome ?? _servicoNomeDo(escala, servicoId);
      final pessoa = pessoaById(pessoaId);
      final designacao = EscalaVoluntario(
        id: 'v${DateTime.now().millisecondsSinceEpoch}',
        escalaId: id,
        pessoaId: pessoaId,
        pessoaNome: pessoa?.nome,
        servicoId: servicoId,
        servicoNome: nomeServico,
        status: EscalaItemStatus.pendente,
        observacoes: observacoes,
        data: data,
      );
      mockEscalas[idx] = escala.copyWith(voluntarios: [...escala.voluntarios, designacao]);
      return mockDelay(designacao);
    }
    final json = await _api.post('/escalas/$id/voluntarios', {
      'pessoaId': pessoaId,
      'servicoId': servicoId,
      'observacoes': observacoes,
    }) as Map<String, dynamic>;
    return _mapVoluntario(json);
  }

  Future<EscalaVoluntario> updateVoluntario(
    String id,
    String designacaoId, {
    String? pessoaId,
    String? pessoaNome,
    String? servicoId,
    String? servicoNome,
    String? observacoes,
  }) async {
    if (AppConfig.useMock) {
      final idx = mockEscalas.indexWhere((e) => e.id == id);
      if (idx < 0) throw Exception('Escala não encontrada.');
      final escala = mockEscalas[idx];
      var atualizado = escala.voluntarios.firstWhere(
        (v) => v.id == designacaoId,
        orElse: () => throw Exception('Designação não encontrada.'),
      );
      atualizado = EscalaVoluntario(
        id: atualizado.id,
        escalaId: atualizado.escalaId,
        pessoaId: pessoaId ?? atualizado.pessoaId,
        pessoaNome: pessoaNome ?? atualizado.pessoaNome,
        servicoId: servicoId ?? atualizado.servicoId,
        servicoNome: servicoNome ?? atualizado.servicoNome,
        status: atualizado.status,
        observacoes: observacoes ?? atualizado.observacoes,
        data: atualizado.data,
      );
      mockEscalas[idx] = escala.copyWith(
        voluntarios: escala.voluntarios
            .map((v) => v.id == designacaoId ? atualizado : v)
            .toList(),
      );
      return mockDelay(atualizado);
    }
    final body = <String, dynamic>{
      if (pessoaId != null) 'pessoaId': pessoaId,
      if (servicoId != null) 'servicoId': servicoId,
      if (observacoes != null) 'observacoes': observacoes,
    };
    final json = await _api.put('/escalas/$id/voluntarios/$designacaoId', body)
        as Map<String, dynamic>;
    return _mapVoluntario(json);
  }

  Future<EscalaVoluntario> updateVoluntarioStatus(
    String id,
    String designacaoId, {
    required EscalaItemStatus status,
    String? observacoes,
  }) async {
    if (AppConfig.useMock) {
      final idx = mockEscalas.indexWhere((e) => e.id == id);
      if (idx < 0) throw Exception('Escala não encontrada.');
      final escala = mockEscalas[idx];
      final atualizado = escala.voluntarios.firstWhere(
        (v) => v.id == designacaoId,
        orElse: () => throw Exception('Designação não encontrada.'),
      );
      final novo = EscalaVoluntario(
        id: atualizado.id,
        escalaId: atualizado.escalaId,
        pessoaId: atualizado.pessoaId,
        pessoaNome: atualizado.pessoaNome,
        servicoId: atualizado.servicoId,
        servicoNome: atualizado.servicoNome,
        status: status,
        observacoes: observacoes ?? atualizado.observacoes,
        data: atualizado.data,
      );
      mockEscalas[idx] = escala.copyWith(
        voluntarios: escala.voluntarios
            .map((v) => v.id == designacaoId ? novo : v)
            .toList(),
      );
      return mockDelay(novo);
    }
    final json = await _api.put('/escalas/$id/voluntarios/$designacaoId/status', {
      'status': escalaItemStatusToString(status),
      'observacoes': observacoes,
    }) as Map<String, dynamic>;
    return _mapVoluntario(json);
  }

  Future<void> removeVoluntario(String id, String designacaoId) async {
    if (AppConfig.useMock) {
      final idx = mockEscalas.indexWhere((e) => e.id == id);
      if (idx < 0) throw Exception('Escala não encontrada.');
      final escala = mockEscalas[idx];
      mockEscalas[idx] = escala.copyWith(
        voluntarios: escala.voluntarios.where((v) => v.id != designacaoId).toList(),
      );
      return mockDelay(null);
    }
    await _api.delete('/escalas/$id/voluntarios/$designacaoId');
  }

  Future<List<EscalaCandidato>> candidatos(
    String id, {
    String? servicoId,
    String? data,
  }) async {
    if (AppConfig.useMock) {
      final escala = mockEscalas.firstWhere(
        (e) => e.id == id,
        orElse: () => throw Exception('Escala não encontrada.'),
      );
      String? servicoNome;
      if (servicoId != null) {
        servicoNome = _servicoNomeDo(escala, servicoId);
      }
      return mockDelay(
        mockCandidatos(escala.igrejaId, servicoNome: servicoNome, data: data),
        data == null ? 150 : 400,
      );
    }
    final query = <String, String>{
      if (servicoId != null) 'servicoId': servicoId,
      if (data != null) 'data': data,
    };
    final list = await _api.get(
      '/escalas/$id/candidatos',
      query: query.isEmpty ? null : query,
    ) as List<dynamic>;
    return list.map((e) => _mapCandidato(e as Map<String, dynamic>)).toList();
  }

  Future<SugestaoResultado> gerarSugestoes(String id) async {
    if (AppConfig.useMock) {
      final idx = mockEscalas.indexWhere((e) => e.id == id);
      if (idx < 0) throw Exception('Escala não encontrada.');
      final escala = mockEscalas[idx];
      final novas = _gerarSugestoesPara(escala, escala.servicos, escala.voluntarios, id);
      mockEscalas[idx] = escala.copyWith(voluntarios: novas);
      final totalVagas =
          escala.servicos.fold<int>(0, (acc, s) => acc + s.quantidadeNecessaria);
      final preenchidas =
          novas.where((v) => v.status != EscalaItemStatus.recusado).length;
      final status = totalVagas == 0
          ? 'SEM_SERVICOS'
          : preenchidas >= totalVagas
              ? 'COMPLETA'
              : preenchidas == 0
                  ? 'SEM_DISPONIVEL'
                  : 'PARCIAL';
      return mockDelay(
        SugestaoResultado(
          escalaId: id,
          status: status,
          message:
              'Sugestões geradas para ${escala.titulo}: $preenchidas de $totalVagas vagas preenchidas.',
          sugestoes: novas.map((v) {
            return SugestaoItem(
              servicoId: v.servicoId,
              servicoNome: v.servicoNome,
              pessoaId: v.pessoaId,
              pessoaNome: v.pessoaNome,
              data: v.data,
              motivo: 'Disponível e de menor carga no mês',
            );
          }).toList(),
        ),
        500,
      );
    }
    final json = await _api.post('/escalas/$id/gerar-sugestao') as Map<String, dynamic>;
    return _mapSugestao(json);
  }

  Future<String> automatizarProximoMes() async {
    if (AppConfig.useMock) {
      return mockDelay(
        'Escalas recomendadas geradas automaticamente: 2 criadas, 1 atualizadas.',
        400,
      );
    }
    final text = await _api.post('/escalas/automacao/proximo-mes') as String;
    return text;
  }

  List<EscalaVoluntario> _gerarSugestoesPara(
    Escala escala,
    List<EscalaServico> servicos,
    List<EscalaVoluntario> atuais,
    String? escalaId,
  ) {
    final result = List.of(atuais);
    final data = escala.dataEvento;
    var idx = 0;
    for (final s in servicos) {
      final preenchidos = result
          .where((v) => v.servicoId == s.servicoId && v.status != EscalaItemStatus.recusado)
          .length;
      for (var i = preenchidos; i < s.quantidadeNecessaria; i++) {
        final usados = result.map((v) => v.pessoaId).toSet();
        final candidatos = mockCandidatos(
          escala.igrejaId,
          servicoNome: s.servicoNome,
          data: data,
        )
            .where((c) => c.analiseDia?.disponivel ?? true)
            .where((c) => !usados.contains(c.pessoaId))
            .toList();
        if (candidatos.isEmpty) break;
        final c = candidatos[idx % candidatos.length];
        idx++;
        result.add(
          EscalaVoluntario(
            id: 'v${DateTime.now().millisecondsSinceEpoch}-$idx',
            escalaId: escalaId,
            pessoaId: c.pessoaId,
            pessoaNome: c.pessoaNome,
            servicoId: s.servicoId,
            servicoNome: s.servicoNome,
            data: data,
            status: EscalaItemStatus.pendente,
          ),
        );
      }
    }
    return result;
  }

  String? _servicoNomeDo(Escala escala, String servicoId) {
    for (final s in escala.servicos) {
      if (s.servicoId == servicoId) return s.servicoNome;
      if (s.id == servicoId) return s.servicoNome;
    }
    return null;
  }

  Escala _map(Map<String, dynamic> json) {
    return Escala(
      id: json['id'] as String,
      titulo: json['titulo'] as String? ?? '',
      descricao: json['descricao'] as String?,
      competencia: json['competencia'] as String? ?? '',
      tipo: escalaTipoFromString(json['tipo'] as String? ?? 'MINISTERIO'),
      igrejaId: json['igrejaId'] as String? ?? '',
      ministerioId: json['ministerioId'] as String?,
      ministerioNome: json['ministerioNome'] as String?,
      supervisorPessoaId: json['supervisorPessoaId'] as String? ?? '',
      supervisorNome: json['supervisorNome'] as String? ?? '',
      pregadorPessoaId: json['pregadorPessoaId'] as String?,
      pregadorNome: json['pregadorNome'] as String?,
      status: escalaStatusFromString(json['status'] as String? ?? 'EDITANDO'),
      dataLancamento: json['dataLancamento'] as String?,
      dataFinalizacao: json['dataFinalizacao'] as String?,
      dataEvento: json['dataEvento'] as String?,
      horaInicio: json['horaInicio'] as String?,
      horaFim: json['horaFim'] as String?,
      eventoId: json['eventoId'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      servicos: (json['servicos'] as List<dynamic>? ?? []).map(_mapServico).toList(),
      voluntarios: (json['voluntarios'] as List<dynamic>? ?? [])
          .map(_mapVoluntario)
          .toList(),
      itens: (json['itens'] as List<dynamic>? ?? []).map(_mapItem).toList(),
    );
  }

  EscalaItem _mapItem(dynamic e) {
    return EscalaItem(
      id: e['id'] as String? ?? '',
      data: e['data'] as String? ?? '',
      eventoId: e['eventoId'] as String?,
      pessoaId: e['pessoaId'] as String?,
      pessoaNome: e['pessoaNome'] as String?,
      servicoId: e['servicoId'] as String?,
      servicoNome: e['servicoNome'] as String?,
      horario: e['horario'] as String?,
      status: escalaItemStatusFromString(e['status'] as String? ?? 'PENDENTE'),
    );
  }

  Map<String, dynamic> _itemToJson(EscalaItem i) => {
        'data': i.data,
        'eventoId': i.eventoId,
        'pessoaId': i.pessoaId,
        'servicoId': i.servicoId,
        'horario': i.horario,
      };

  EscalaServico _mapServico(dynamic e) {
    return EscalaServico(
      id: e['id'] as String,
      escalaId: e['escalaId'] as String?,
      servicoId: e['servicoId'] as String?,
      servicoNome: e['servicoNome'] as String?,
      quantidadeNecessaria: (e['quantidadeNecessaria'] as num? ?? 1).toInt(),
    );
  }

  EscalaVoluntario _mapVoluntario(dynamic e) {
    return EscalaVoluntario(
      id: e['id'] as String,
      escalaId: e['escalaId'] as String?,
      pessoaId: e['pessoaId'] as String?,
      pessoaNome: e['pessoaNome'] as String?,
      servicoId: e['servicoId'] as String?,
      servicoNome: e['servicoNome'] as String?,
      status: escalaItemStatusFromString(e['status'] as String? ?? 'PENDENTE'),
      observacoes: e['observacoes'] as String?,
      data: e['data'] as String?,
    );
  }

  EscalaCandidato _mapCandidato(Map<String, dynamic> json) {
    return EscalaCandidato(
      servicoId: json['servicoId'] as String?,
      servicoNome: json['servicoNome'] as String?,
      pessoaId: json['pessoaId'] as String,
      pessoaNome: json['pessoaNome'] as String? ?? '',
      servicosQueServe: (json['servicosQueServe'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      diasDisponiveis: (json['diasDisponiveis'] as List<dynamic>? ?? [])
          .map(_mapDiaDisponivel)
          .toList(),
      analiseDia: json['analiseDia'] == null
          ? null
          : _mapAnaliseDia(json['analiseDia'] as Map<String, dynamic>),
    );
  }

  DiaDisponivel _mapDiaDisponivel(dynamic e) {
    return DiaDisponivel(
      diaSemana: diaSemanaFromString(e['diaSemana'] as String? ?? 'DOMINGO'),
      horaInicio: e['horaInicio'] as String?,
      horaFim: e['horaFim'] as String?,
      disponivel: e['disponivel'] as bool? ?? true,
    );
  }

  AnaliseDiaCandidato _mapAnaliseDia(Map<String, dynamic> json) {
    return AnaliseDiaCandidato(
      data: json['data'] as String?,
      tituloEvento: json['tituloEvento'] as String?,
      disponivel: json['disponivel'] as bool? ?? true,
      motivosIndisponibilidade:
          (json['motivosIndisponibilidade'] as List<dynamic>? ?? [])
              .map((e) => e as String)
              .toList(),
      conflitos: (json['conflitos'] as List<dynamic>? ?? [])
          .map((e) => _mapConflito(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ConflitoEscala _mapConflito(Map<String, dynamic> json) {
    return ConflitoEscala(
      escalaId: json['escalaId'] as String?,
      escalaTitulo: json['escalaTitulo'] as String?,
      ministerioNome: json['ministerioNome'] as String?,
      servicoNome: json['servicoNome'] as String?,
      data: json['data'] as String?,
      horario: json['horario'] as String?,
    );
  }

  SugestaoResultado _mapSugestao(Map<String, dynamic> json) {
    return SugestaoResultado(
      escalaId: json['escalaId'] as String,
      status: json['status'] as String,
      message: json['message'] as String? ?? '',
      sugestoes: (json['sugestoes'] as List<dynamic>? ?? [])
          .map(
            (e) => SugestaoItem(
              servicoId: e['servicoId'] as String?,
              servicoNome: e['servicoNome'] as String?,
              pessoaId: e['pessoaId'] as String?,
              pessoaNome: e['pessoaNome'] as String?,
              data: e['data'] as String?,
              eventoId: e['eventoId'] as String?,
              motivo: e['motivo'] as String?,
            ),
          )
          .toList(),
    );
  }
}
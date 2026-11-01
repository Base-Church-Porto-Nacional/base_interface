import '../models/models.dart';
import 'api_client.dart';

class EscalaService {
  EscalaService(this._api);

  final ApiClient _api;

  Future<List<Escala>> list({String? igrejaId, String? competencia, String? pessoaId}) async {
    final query = <String, String>{
      if (igrejaId != null) 'igrejaId': igrejaId,
      if (competencia != null) 'competencia': competencia,
      if (pessoaId != null) 'pessoaId': pessoaId,
    };
    final list = await _api.get('/escalas', query: query.isEmpty ? null : query) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<Escala> getById(String id) async {
    final json = await _api.get('/escalas/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<Escala> create(Escala escala) async {
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
    await _api.delete('/escalas/$id');
  }

  Future<Escala> updateStatus(String id, EscalaStatus status) async {
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
    final json = await _api.put('/escalas/$id/servicos/$escalaServicoId', {
      'quantidadeNecessaria': quantidadeNecessaria,
    }) as Map<String, dynamic>;
    return _mapServico(json);
  }

  Future<void> removeServico(String id, String escalaServicoId) async {
    await _api.delete('/escalas/$id/servicos/$escalaServicoId');
  }

  Future<EscalaVoluntario> addVoluntario(
    String id, {
    required String pessoaId,
    required String servicoId,
    String? servicoNome,
    String? observacoes,
    String? data,
    String? eventoId,
    String? horario,
  }) async {
    final json = await _api.post('/escalas/$id/voluntarios', {
      'pessoaId': pessoaId,
      'servicoId': servicoId,
      'observacoes': observacoes,
      'data': ?data,
      'eventoId': ?eventoId,
      'horario': ?horario,
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
    bool? confirmadoPeloVoluntario,
  }) async {
    final json = await _api.put('/escalas/$id/voluntarios/$designacaoId/status', {
      'status': escalaItemStatusToString(status),
      'observacoes': observacoes,
      'confirmadoPeloVoluntario': ?confirmadoPeloVoluntario,
    }) as Map<String, dynamic>;
    return _mapVoluntario(json);
  }

  Future<EscalaVoluntario> responderDesignacao(
    String id,
    String designacaoId, {
    required EscalaItemStatus status,
    String? observacoes,
    String? pessoaId,
  }) async {
    final json = await _api.post('/escalas/$id/voluntarios/$designacaoId/resposta', {
      'status': escalaItemStatusToString(status),
      'observacoes': observacoes,
    }) as Map<String, dynamic>;
    return _mapVoluntario(json);
  }

  Future<void> removeVoluntario(String id, String designacaoId) async {
    await _api.delete('/escalas/$id/voluntarios/$designacaoId');
  }

  Future<List<EscalaCandidato>> candidatos(
    String id, {
    String? servicoId,
    String? data,
  }) async {
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
    final json = await _api.post('/escalas/$id/gerar-sugestao') as Map<String, dynamic>;
    return _mapSugestao(json);
  }

  Future<String> automatizarProximoMes() async {
    final text = await _api.post('/escalas/automacao/proximo-mes') as String;
    return text;
  }

  Future<List<VisaoMensalEscala>> visaoMensal({
    String? igrejaId,
    String? competencia,
    String? ministerioId,
    String? pessoaId,
    bool administrador = false,
  }) async {
    final query = <String, String>{
      'igrejaId': ?igrejaId,
      'competencia': ?competencia,
      'ministerioId': ?ministerioId,
    };
    final list = await _api.get(
      '/escalas/visao-mensal',
      query: query.isEmpty ? null : query,
    ) as List<dynamic>;
    return list.map((e) => _mapVisaoMensal(e as Map<String, dynamic>)).toList();
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
      confirmadoPeloVoluntario: e['confirmadoPeloVoluntario'] as bool? ?? false,
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

  VisaoMensalEscala _mapVisaoMensal(Map<String, dynamic> json) {
    final escalaStatusRaw = json['escalaStatus'] as String?;
    return VisaoMensalEscala(
      competencia: json['competencia'] as String? ?? '',
      igrejaId: json['igrejaId'] as String? ?? '',
      ministerioId: json['ministerioId'] as String? ?? '',
      ministerioNome: json['ministerioNome'] as String? ?? '',
      escalaId: json['escalaId'] as String?,
      escalaTitulo: json['escalaTitulo'] as String?,
      escalaStatus: escalaStatusRaw == null
          ? null
          : escalaStatusFromString(escalaStatusRaw),
      itens: (json['itens'] as List<dynamic>? ?? [])
          .map((e) => _mapItemVisao(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ItemVisaoMensal _mapItemVisao(Map<String, dynamic> json) {
    return ItemVisaoMensal(
      origem: json['origem'] as String? ?? 'EVENTO',
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      data: json['data'] as String? ?? '',
      horaInicio: json['horaInicio'] as String?,
      horaFim: json['horaFim'] as String?,
      localEvento: json['localEvento'] as String?,
      servicos: (json['servicos'] as List<dynamic>? ?? [])
          .map((e) => _mapServicoVisao(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ServicoVisaoMensal _mapServicoVisao(Map<String, dynamic> json) {
    return ServicoVisaoMensal(
      servicoId: json['servicoId'] as String?,
      servicoNome: json['servicoNome'] as String? ?? 'Serviço',
      quantidadeNecessaria: (json['quantidadeNecessaria'] as num? ?? 1).toInt(),
      designados: (json['designados'] as List<dynamic>? ?? [])
          .map((e) => _mapDesignadoVisao(e as Map<String, dynamic>))
          .toList(),
    );
  }

  DesignadoVisao _mapDesignadoVisao(Map<String, dynamic> json) {
    return DesignadoVisao(
      designacaoId: json['designacaoId'] as String? ?? '',
      pessoaId: json['pessoaId'] as String?,
      pessoaNome: json['pessoaNome'] as String? ?? '—',
      status: escalaItemStatusFromString(json['status'] as String? ?? 'PENDENTE'),
      confirmadoPeloVoluntario: json['confirmadoPeloVoluntario'] as bool? ?? false,
      observacoes: json['observacoes'] as String?,
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
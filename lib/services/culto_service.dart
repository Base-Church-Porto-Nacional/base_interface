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
    final json = await _api.get('/cultos/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<Culto> create(Culto culto) async {
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
    final json = await _api.post('/cultos', body: body) as Map<String, dynamic>;
    return _map(json);
  }

  Future<Culto> update(Culto culto) async {
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
    await _api.delete('/cultos/$id');
  }

  Future<CultoConteudo> getConteudo(String cultoId) async {
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
    final json = await _api.put('/cultos/$cultoId/conteudo', body)
        as Map<String, dynamic>;
    return _mapConteudo(json, cultoId);
  }

  Future<CultoRelatorio> getRelatorio(String cultoId) async {
    final json = await _api.get('/cultos/$cultoId/relatorio') as Map<String, dynamic>;
    return _mapRelatorio(json, cultoId);
  }

  Future<CultoRelatorio> saveRelatorio(CultoRelatorio relatorio) async {
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

  Future<String> gerarMes(String competencia, {String? igrejaId}) async {
    final text = await _api.post(
      '/cultos/automacao/mes/$competencia',
      query: {if (igrejaId != null && igrejaId.isNotEmpty) 'igrejaId': igrejaId},
    );
    return text?.toString() ?? '';
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
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
              (e) => Escala(
                id: e.id,
                titulo: e.titulo,
                competencia: e.competencia,
                tipo: e.tipo,
                igrejaId: e.igrejaId,
                ministerioId: e.ministerioId,
                ministerioNome: e.ministerioNome,
                supervisorPessoaId: e.supervisorPessoaId,
                supervisorNome: e.supervisorNome,
                pregadorPessoaId: e.pregadorPessoaId,
                pregadorNome: e.pregadorNome,
                ativo: e.ativo,
                itens: e.itens.where((i) => i.pessoaId == pessoaId).toList(),
              ),
            )
            .where((e) => e.itens.isNotEmpty)
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
        competencia: escala.competencia,
        tipo: escala.tipo,
        igrejaId: escala.igrejaId,
        ministerioId: escala.ministerioId,
        ministerioNome: escala.ministerioNome,
        supervisorPessoaId: escala.supervisorPessoaId,
        supervisorNome: escala.supervisorNome,
        pregadorPessoaId: escala.pregadorPessoaId,
        pregadorNome: escala.pregadorNome,
        ativo: escala.ativo,
        itens: escala.itens,
      );
      mockEscalas.insert(0, created);
      return mockDelay(created);
    }
    final json = await _api.post('/escalas', {
      'titulo': escala.titulo,
      'competencia': escala.competencia,
      'tipo': escalaTipoToString(escala.tipo),
      'igrejaId': escala.igrejaId,
      'ministerioId': escala.ministerioId,
      'supervisorPessoaId': escala.supervisorPessoaId,
      'pregadorPessoaId': escala.pregadorPessoaId,
      'itens': escala.itens
          .map(
            (i) => {
              'data': i.data,
              'eventoId': i.eventoId,
              'pessoaId': i.pessoaId,
              'servicoId': i.servicoId,
              'horario': i.horario,
            },
          )
          .toList(),
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Escala _map(Map<String, dynamic> json) {
    final itens = (json['itens'] as List<dynamic>? ?? [])
        .map(
          (e) => EscalaItem(
            id: e['id'] as String? ?? '',
            data: e['data'] as String,
            eventoId: e['eventoId'] as String?,
            pessoaId: e['pessoaId'] as String?,
            pessoaNome: e['pessoaNome'] as String?,
            servicoId: e['servicoId'] as String?,
            servicoNome: e['servicoNome'] as String?,
            horario: e['horario'] as String?,
          ),
        )
        .toList();
    return Escala(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      competencia: json['competencia'] as String,
      tipo: escalaTipoFromString(json['tipo'] as String? ?? 'MINISTERIO'),
      igrejaId: json['igrejaId'] as String? ?? '',
      ministerioId: json['ministerioId'] as String?,
      ministerioNome: json['ministerioNome'] as String?,
      supervisorPessoaId: json['supervisorPessoaId'] as String? ?? '',
      supervisorNome: json['supervisorNome'] as String? ?? '',
      pregadorPessoaId: json['pregadorPessoaId'] as String?,
      pregadorNome: json['pregadorNome'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      itens: itens,
    );
  }
}

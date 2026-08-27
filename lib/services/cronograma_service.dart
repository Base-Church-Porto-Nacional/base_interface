import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import 'api_client.dart';

class CronogramaService {
  CronogramaService(this._api);

  final ApiClient _api;

  Future<List<CultoEvento>> list({String? igrejaId}) async {
    if (AppConfig.useMock) {
      if (igrejaId == null || igrejaId.isEmpty) return mockDelay(<CultoEvento>[]);
      var items = mockEventos.where((e) => e.igrejaId == igrejaId).toList();
      items.sort((a, b) => a.data.compareTo(b.data));
      return mockDelay(items);
    }
    final query = igrejaId == null ? null : {'igrejaId': igrejaId};
    final list = await _api.get('/cronograma', query: query) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<CultoEvento> getById(String id) async {
    if (AppConfig.useMock) {
      return mockDelay(
        mockEventos.firstWhere(
          (e) => e.id == id,
          orElse: () => throw Exception('Evento não encontrado.'),
        ),
      );
    }
    final json = await _api.get('/cronograma/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<CultoEvento> create(CultoEvento evento) async {
    if (AppConfig.useMock) {
      final created = CultoEvento(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        titulo: evento.titulo,
        tipo: evento.tipo,
        data: evento.data,
        horaInicio: evento.horaInicio,
        horaFim: evento.horaFim,
        localEvento: evento.localEvento,
        descricao: evento.descricao,
        igrejaId: evento.igrejaId,
        supervisorPessoaId: evento.supervisorPessoaId,
        supervisorNome: evento.supervisorNome,
        ativo: evento.ativo,
      );
      mockEventos.insert(0, created);
      return mockDelay(created);
    }
    final json = await _api.post('/cronograma', {
      'titulo': evento.titulo,
      'tipo': tipoEventoToString(evento.tipo),
      'dataEvento': evento.data,
      'horaInicio': evento.horaInicio,
      'horaFim': evento.horaFim,
      'localEvento': evento.localEvento,
      'descricao': evento.descricao,
      'igrejaId': evento.igrejaId,
      'supervisorPessoaId': evento.supervisorPessoaId,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  CultoEvento _map(Map<String, dynamic> json) {
    return CultoEvento(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      tipo: tipoEventoFromString(json['tipo'] as String? ?? 'CULTO'),
      data: json['data'] as String? ?? json['dataEvento'] as String? ?? '',
      horaInicio: json['horaInicio'] as String? ?? '',
      horaFim: json['horaFim'] as String?,
      localEvento: json['localEvento'] as String?,
      descricao: json['descricao'] as String?,
      igrejaId: json['igrejaId'] as String? ?? '',
      supervisorPessoaId: json['supervisorPessoaId'] as String? ?? '',
      supervisorNome: json['supervisorNome'] as String? ?? '',
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

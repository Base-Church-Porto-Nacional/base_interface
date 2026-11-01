import '../models/models.dart';
import 'api_client.dart';

class CronogramaService {
  CronogramaService(this._api);

  final ApiClient _api;

  Future<List<CultoEvento>> list({String? igrejaId}) async {
    final query = igrejaId == null ? null : {'igrejaId': igrejaId};
    final list = await _api.get('/cronograma', query: query) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<CultoEvento> getById(String id) async {
    final json = await _api.get('/cronograma/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<CultoEvento> create(CultoEvento evento) async {
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

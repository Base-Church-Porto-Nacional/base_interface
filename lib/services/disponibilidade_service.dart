import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import '../utils/disponibilidade_janelas.dart';
import 'api_client.dart';

class DisponibilidadeService {
  DisponibilidadeService(this._api);

  final ApiClient _api;

  Future<DisponibilidadePessoa> getByPessoa(String pessoaId) async {
    if (AppConfig.useMock) {
      return mockDelay(
        mockDisponibilidades[pessoaId] ??
            DisponibilidadePessoa(pessoaId: pessoaId, semanal: const [], datas: const []),
      );
    }
    final semanalJson =
        await _api.get('/disponibilidades/semanal/pessoa/$pessoaId') as List<dynamic>;
    final datasJson =
        await _api.get('/disponibilidades/indisponibilidades/pessoa/$pessoaId') as List<dynamic>;
    return DisponibilidadePessoa(
      pessoaId: pessoaId,
      semanal: indisponibilidadesDasJanelas(_janelas(semanalJson)),
      datas: datasJson.map(_mapData).toList(),
    );
  }

  Future<DisponibilidadePessoa> saveSemanal({
    required String pessoaId,
    required List<IndisponibilidadeSemanal> semanal,
  }) async {
    if (AppConfig.useMock) {
      final current = mockDisponibilidades[pessoaId] ??
          DisponibilidadePessoa(pessoaId: pessoaId, semanal: const [], datas: const []);
      final updated = DisponibilidadePessoa(
        pessoaId: pessoaId,
        semanal: semanal,
        datas: current.datas,
      );
      mockDisponibilidades[pessoaId] = updated;
      return mockDelay(updated);
    }
    final existentes =
        await _api.get('/disponibilidades/semanal/pessoa/$pessoaId') as List<dynamic>;
    for (final e in existentes) {
      await _api.delete('/disponibilidades/semanal/${e['id']}');
    }
    for (final janela in janelasDisponiveis(semanal)) {
      await _api.post('/disponibilidades/semanal', {
        'pessoaId': pessoaId,
        'diaSemana': janela.dia.name.toUpperCase(),
        'horaInicio': janela.horaInicio,
        'horaFim': janela.horaFim,
        'disponivel': true,
      });
    }
    return getByPessoa(pessoaId);
  }

  Future<IndisponibilidadeData> addData({
    required String pessoaId,
    required String data,
    String? motivo,
  }) async {
    if (AppConfig.useMock) {
      final item = IndisponibilidadeData(
        id: 'd${DateTime.now().millisecondsSinceEpoch}',
        pessoaId: pessoaId,
        data: data,
        motivo: motivo,
      );
      final current = mockDisponibilidades[pessoaId] ??
          DisponibilidadePessoa(pessoaId: pessoaId, semanal: const [], datas: const []);
      mockDisponibilidades[pessoaId] = DisponibilidadePessoa(
        pessoaId: pessoaId,
        semanal: current.semanal,
        datas: [...current.datas, item],
      );
      return mockDelay(item);
    }
    final json = await _api.post('/disponibilidades/indisponibilidades', {
      'pessoaId': pessoaId,
      'dataInicio': data,
      'dataFim': data,
      'motivo': motivo,
    }) as Map<String, dynamic>;
    return _mapData(json);
  }

  Future<void> removeData(String pessoaId, String id) async {
    if (AppConfig.useMock) {
      final current = mockDisponibilidades[pessoaId];
      if (current == null) return;
      mockDisponibilidades[pessoaId] = DisponibilidadePessoa(
        pessoaId: pessoaId,
        semanal: current.semanal,
        datas: current.datas.where((d) => d.id != id).toList(),
      );
      return mockDelay(null);
    }
    await _api.delete('/disponibilidades/indisponibilidades/$id');
  }

  List<JanelaDisponivel> _janelas(List<dynamic> json) {
    final janelas = <JanelaDisponivel>[];
    for (final e in json) {
      if (e['disponivel'] != true) continue;
      final diaNome = e['diaSemana'] as String?;
      final inicio = parseHoraMinutos(e['horaInicio'] as String?);
      final fim = parseHoraMinutos(e['horaFim'] as String?);
      if (diaNome == null || inicio == null || fim == null) continue;
      final dia = diaSemanaFromApi(diaNome);
      janelas.add(JanelaDisponivel(dia: dia, inicioMin: inicio, fimMin: fim));
    }
    return janelas;
  }

  IndisponibilidadeData _mapData(dynamic e) {
    return IndisponibilidadeData(
      id: e['id'] as String,
      pessoaId: e['pessoaId'] as String? ?? '',
      data: e['data'] as String? ?? e['dataInicio'] as String? ?? '',
      motivo: e['motivo'] as String?,
    );
  }
}

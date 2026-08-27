import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import 'api_client.dart';

class ConteudoCultoService {
  ConteudoCultoService(this._api);

  final ApiClient _api;

  Future<ConteudoCulto> getByEvento(String eventoId) async {
    if (AppConfig.useMock) {
      for (final c in mockConteudosCulto) {
        if (c.eventoId == eventoId) return mockDelay(c);
      }
      return mockDelay(
        ConteudoCulto(eventoId: eventoId, textoPregacao: '', louvor: ''),
      );
    }
    final json = await _api.get('/cronograma/$eventoId/conteudo') as Map<String, dynamic>;
    return _map(json, eventoId);
  }

  Future<ConteudoCulto> save(ConteudoCulto conteudo) async {
    if (AppConfig.useMock) {
      final index = mockConteudosCulto.indexWhere((c) => c.eventoId == conteudo.eventoId);
      if (index >= 0) {
        mockConteudosCulto[index] = conteudo;
      } else {
        mockConteudosCulto.add(conteudo);
      }
      return mockDelay(conteudo);
    }
    final json = await _api.put('/cronograma/${conteudo.eventoId}/conteudo', {
      'textoPregacao': conteudo.textoPregacao,
      'louvor': conteudo.louvor,
      'pregadorPessoaId': conteudo.pregadorPessoaId,
    }) as Map<String, dynamic>;
    return _map(json, conteudo.eventoId);
  }

  ConteudoCulto _map(Map<String, dynamic> json, String eventoId) {
    return ConteudoCulto(
      eventoId: json['eventoId'] as String? ?? eventoId,
      textoPregacao: json['textoPregacao'] as String? ?? '',
      louvor: json['louvor'] as String? ?? '',
      pregadorPessoaId: json['pregadorPessoaId'] as String?,
      pregadorNome: json['pregadorNome'] as String?,
    );
  }
}

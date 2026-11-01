import '../models/models.dart';
import 'api_client.dart';

class MensagemAniversarioService {
  MensagemAniversarioService(this._api);

  final ApiClient _api;

  Future<MensagemAniversario> get({String? igrejaId}) async {
    final alvo = igrejaId ?? '';
    final query = <String, String>{'igrejaId': alvo};
    final json = await _api.get(
      '/mensagens/aniversario',
      query: query,
    ) as Map<String, dynamic>;
    return _map(json);
  }

  Future<MensagemAniversario> save(MensagemAniversario mensagem) async {
    final texto = mensagem.mensagem.trim();
    if (texto.isEmpty) throw Exception('Informe a mensagem padrão.');
    final payload = MensagemAniversario(
      id: mensagem.id,
      igrejaId: mensagem.igrejaId,
      mensagem: texto,
    );
    final json = await _api.put('/mensagens/aniversario', {
      'id': payload.id,
      'igrejaId': payload.igrejaId,
      'mensagem': texto,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  MensagemAniversario _map(Map<String, dynamic> json) {
    return MensagemAniversario(
      id: json['id'] as String?,
      igrejaId: json['igrejaId'] as String? ?? '',
      mensagem: json['mensagem'] as String? ?? '',
    );
  }
}

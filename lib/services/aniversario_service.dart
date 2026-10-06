import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import '../utils/format.dart';
import 'api_client.dart';

class AniversarioService {
  AniversarioService(this._api);

  final ApiClient _api;

  static const _base = '/aniversarios';

  /// `data` é opcional no back-end (default hoje). Quando vier null, omitimos o
  /// parâmetro para não fixar a data no front.
  Future<List<Aniversariante>> listarAniversariantes({
    required String igrejaId,
    DateTime? data,
  }) async {
    if (AppConfig.useMock) {
      final alvo = DateTime.now();
      return mockDelay(mockAniversariantes(igrejaId, data ?? alvo));
    }
    final query = <String, String>{'igrejaId': igrejaId};
    if (data != null) query['data'] = isoDate(data);
    final list = await _api.get('$_base/aniversariantes', query: query) as List<dynamic>;
    return list
        .map(
          (e) => _mapAniversariante(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<EnvioAniversarioResumo> enviarHoje({required String igrejaId}) async {
    if (AppConfig.useMock) {
      return mockDelay(mockEnviarAniversarios(igrejaId, DateTime.now()));
    }
    final json =
        await _api.post('$_base/enviar', null, true, {'igrejaId': igrejaId})
            as Map<String, dynamic>;
    return _mapResumo(json);
  }

  Future<List<AniversarioEnvio>> listarEnvios({
    required String igrejaId,
    String? de,
    String? ate,
  }) async {
    if (AppConfig.useMock) {
      return mockDelay(mockAniversarioEnviosPeriodo(igrejaId: igrejaId, de: de, ate: ate));
    }
    final query = <String, String>{'igrejaId': igrejaId};
    if (de != null) query['de'] = de;
    if (ate != null) query['ate'] = ate;
    final list = await _api.get('$_base/envios', query: query) as List<dynamic>;
    return list.map((e) => _mapEnvio(e as Map<String, dynamic>)).toList();
  }

  Aniversariante _mapAniversariante(Map<String, dynamic> json) {
    return Aniversariante(
      pessoaId: json['pessoaId'] as String,
      nome: json['nome'] as String,
      dataNascimento: json['dataNascimento'] as String? ?? '',
      idade: (json['idade'] as num?)?.toInt() ?? 0,
      mensagem: json['mensagem'] as String? ?? '',
      enviado: json['enviado'] as bool? ?? false,
    );
  }

  EnvioAniversarioResumo _mapResumo(Map<String, dynamic> json) {
    return EnvioAniversarioResumo(
      data: json['data'] as String? ?? isoDate(DateTime.now()),
      enviados: (json['enviados'] as num?)?.toInt() ?? 0,
      enfileirados: (json['enfileirados'] as num?)?.toInt() ?? 0,
      ignorados: (json['ignorados'] as num?)?.toInt() ?? 0,
      falhas: (json['falhas'] as num?)?.toInt() ?? 0,
    );
  }

  AniversarioEnvio _mapEnvio(Map<String, dynamic> json) {
    return AniversarioEnvio(
      id: json['id'] as String,
      pessoaId: json['pessoaId'] as String,
      igrejaId: json['igrejaId'] as String? ?? '',
      dataAniversario: json['dataAniversario'] as String? ?? '',
      dataProcessamento: json['dataProcessamento'] as String? ?? '',
      mensagem: json['mensagem'] as String? ?? '',
      status: aniversarioEnvioStatusFromString(json['status'] as String? ?? 'PENDENTE'),
      erro: json['erro'] as String?,
    );
  }
}

import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import 'api_client.dart';

class BaseMinisterialService {
  BaseMinisterialService(this._api);

  final ApiClient _api;

  Future<List<BaseMinisterial>> list({String? igrejaId}) async {
    if (AppConfig.useMock) {
      return mockDelay(basesMinisteriaisDaIgreja(igrejaId));
    }
    final query = igrejaId == null ? null : {'igrejaId': igrejaId};
    final list = await _api.get('/bases-ministeriais', query: query) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<BaseMinisterial> getById(String id) async {
    if (AppConfig.useMock) {
      return mockDelay(
        mockBasesMinisteriais.firstWhere(
          (b) => b.id == id,
          orElse: () => throw Exception('Base ministerial não encontrada.'),
        ),
      );
    }
    final json = await _api.get('/bases-ministeriais/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<BaseMinisterial> update(
    String id, {
    required String nome,
    String? descricao,
    required bool ativo,
    String? liderPessoaId,
    String? liderNome,
    String? coordenadorPessoaId,
    String? coordenadorNome,
    String? ordem,
  }) async {
    if (AppConfig.useMock) {
      final index = mockBasesMinisteriais.indexWhere((b) => b.id == id);
      if (index < 0) throw Exception('Base ministerial não encontrada.');
      mockBasesMinisteriais[index] = mockBasesMinisteriais[index].copyWith(
        nome: nome,
        descricao: descricao,
        ativo: ativo,
        liderPessoaId: liderPessoaId,
        liderNome: liderNome,
        coordenadorPessoaId: coordenadorPessoaId,
        coordenadorNome: coordenadorNome,
        ordem: ordem,
      );
      return mockDelay(mockBasesMinisteriais[index]);
    }
    final json = await _api.put('/bases-ministeriais/$id', {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'liderPessoaId': liderPessoaId,
      'coordenadorPessoaId': coordenadorPessoaId,
      'ordem': ordem,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<BaseMinisterial> create({
    required String nome,
    required String igrejaId,
    String? descricao,
    bool ativo = true,
    String? liderPessoaId,
    String? liderNome,
    String? coordenadorPessoaId,
    String? coordenadorNome,
  }) async {
    if (AppConfig.useMock) {
      final id = 'b${DateTime.now().millisecondsSinceEpoch}';
      final created = BaseMinisterial(
        id: id,
        nome: nome,
        liderNome: liderNome ?? '—',
        liderPessoaId: liderPessoaId,
        coordenadorPessoaId: coordenadorPessoaId,
        coordenadorNome: coordenadorNome,
        ativo: ativo,
        descricao: descricao,
        igrejaId: igrejaId,
      );
      mockBasesMinisteriais.insert(0, created);
      return mockDelay(created);
    }
    final json = await _api.post('/bases-ministeriais', {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'igrejaId': igrejaId,
      'liderPessoaId': liderPessoaId,
      'coordenadorPessoaId': coordenadorPessoaId,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  BaseMinisterial _map(Map<String, dynamic> json) {
    return BaseMinisterial(
      id: json['id'] as String,
      nome: json['nome'] as String,
      liderNome: json['liderNome'] as String? ?? '—',
      liderPessoaId: json['liderPessoaId'] as String?,
      coordenadorPessoaId: json['coordenadorPessoaId'] as String?,
      coordenadorNome: json['coordenadorNome'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      descricao: json['descricao'] as String?,
      igrejaId: json['igrejaId'] as String? ?? '',
      ordem: json['ordem'] as String?,
    );
  }
}

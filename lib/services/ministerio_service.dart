import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import 'api_client.dart';

class MinisterioService {
  MinisterioService(this._api);

  final ApiClient _api;

  Future<List<Ministerio>> list({String? igrejaId}) async {
    if (AppConfig.useMock) {
      return mockDelay(ministeriosDaIgreja(igrejaId));
    }
    final query = igrejaId == null ? null : {'igrejaId': igrejaId};
    final list = await _api.get('/ministerios', query: query) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<Ministerio> getById(String id) async {
    if (AppConfig.useMock) {
      return mockDelay(
        mockMinisterios.firstWhere(
          (m) => m.id == id,
          orElse: () => throw Exception('Ministério não encontrado.'),
        ),
      );
    }
    final json = await _api.get('/ministerios/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<Ministerio> update(
    String id, {
    required String nome,
    String? descricao,
    required bool ativo,
    MinisterioTipo? tipo,
    String? liderPessoaId,
    String? liderNome,
    String? coordenadorPessoaId,
    String? coordenadorNome,
    String? anotacoes,
    String? ordem,
    String? baseMinisterialId,
    String? baseMinisterialNome,
  }) async {
    if (AppConfig.useMock) {
      final index = mockMinisterios.indexWhere((m) => m.id == id);
      if (index < 0) throw Exception('Ministério não encontrado.');
      mockMinisterios[index] = mockMinisterios[index].copyWith(
        nome: nome,
        descricao: descricao,
        ativo: ativo,
        tipo: tipo,
        liderPessoaId: liderPessoaId,
        liderNome: liderNome,
        coordenadorPessoaId: coordenadorPessoaId,
        coordenadorNome: coordenadorNome,
        anotacoes: anotacoes,
        ordem: ordem,
        baseMinisterialId: baseMinisterialId,
        baseMinisterialNome: baseMinisterialNome,
      );
      return mockDelay(mockMinisterios[index]);
    }
    final json = await _api.put('/ministerios/$id', {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      if (tipo != null) 'tipo': ministerioTipoToString(tipo),
      'liderPessoaId': liderPessoaId,
      'coordenadorPessoaId': coordenadorPessoaId,
      'anotacoes': anotacoes,
      'ordem': ordem,
      'baseMinisterialId': baseMinisterialId,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<Ministerio> create({
    required String nome,
    required String igrejaId,
    required MinisterioTipo tipo,
    String? descricao,
    bool ativo = true,
    String? liderPessoaId,
    String? liderNome,
    String? coordenadorPessoaId,
    String? coordenadorNome,
    String? baseMinisterialId,
    String? baseMinisterialNome,
  }) async {
    if (AppConfig.useMock) {
      final id = 'm${DateTime.now().millisecondsSinceEpoch}';
      final created = Ministerio(
        id: id,
        nome: nome,
        liderNome: liderNome ?? '—',
        liderPessoaId: liderPessoaId,
        coordenadorPessoaId: coordenadorPessoaId,
        coordenadorNome: coordenadorNome,
        totalVoluntarios: 0,
        totalServicos: 1,
        ativo: ativo,
        descricao: descricao,
        igrejaId: igrejaId,
        tipo: tipo,
        baseMinisterialId: baseMinisterialId,
        baseMinisterialNome: baseMinisterialNome,
        servicos: [
          Servico(
            id: 's${id}c',
            ministerioId: id,
            nome: 'Coordenador',
            ficcao: true,
            ativo: true,
          ),
        ],
      );
      mockMinisterios.insert(0, created);
      return mockDelay(created);
    }
    final json = await _api.post('/ministerios', {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'igrejaId': igrejaId,
      'tipo': ministerioTipoToString(tipo),
      'liderPessoaId': liderPessoaId,
      'coordenadorPessoaId': coordenadorPessoaId,
      'baseMinisterialId': baseMinisterialId,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Ministerio _map(Map<String, dynamic> json) {
    final servicosJson = json['servicos'] as List<dynamic>? ?? [];
    return Ministerio(
      id: json['id'] as String,
      nome: json['nome'] as String,
      liderNome: json['liderNome'] as String? ?? '—',
      liderPessoaId: json['liderPessoaId'] as String?,
      coordenadorPessoaId: json['coordenadorPessoaId'] as String?,
      coordenadorNome: json['coordenadorNome'] as String?,
      totalVoluntarios: json['totalVoluntarios'] as int? ?? 0,
      totalServicos: json['totalServicos'] as int? ?? 0,
      ativo: json['ativo'] as bool? ?? true,
      descricao: json['descricao'] as String?,
      igrejaId: json['igrejaId'] as String? ?? '',
      tipo: ministerioTipoFromString(json['tipo'] as String? ?? 'GERAL'),
      anotacoes: json['anotacoes'] as String?,
      ordem: json['ordem'] as String?,
      baseMinisterialId: json['baseMinisterialId'] as String?,
      baseMinisterialNome: json['baseMinisterialNome'] as String?,
      servicos: servicosJson
          .map(
            (e) => Servico(
              id: e['id'] as String,
              ministerioId: e['ministerioId'] as String? ?? json['id'] as String,
              nome: e['nome'] as String,
              ficcao: e['ficcao'] as bool? ?? false,
              ativo: e['ativo'] as bool? ?? true,
              descricao: e['descricao'] as String?,
            ),
          )
          .toList(),
    );
  }
}

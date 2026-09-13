import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import 'api_client.dart';

class SmallGroupService {
  SmallGroupService(this._api);

  final ApiClient _api;

  Future<List<SmallGroup>> list({String? igrejaId}) async {
    if (AppConfig.useMock) {
      if (igrejaId == null || igrejaId.isEmpty) return mockDelay(<SmallGroup>[]);
      return mockDelay(mockSmallGroups.where((c) => c.igrejaId == igrejaId).toList());
    }
    final query = igrejaId == null ? null : {'igrejaId': igrejaId};
    final list = await _api.get('/small-groups', query: query) as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<SmallGroup> getById(String id) async {
    if (AppConfig.useMock) {
      return mockDelay(
        mockSmallGroups.firstWhere(
          (c) => c.id == id,
          orElse: () => throw Exception('Pequeno grupo não encontrado.'),
        ),
      );
    }
    final json = await _api.get('/small-groups/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<SmallGroup> create({
    required String nome,
    required String igrejaId,
    required DiaSemana diaSemana,
    required String liderPessoaId,
    String? liderNome,
    String? horario,
    required int nota,
    bool ativo = true,
  }) async {
    if (AppConfig.useMock) {
      final id = 'cl${DateTime.now().millisecondsSinceEpoch}';
      final created = SmallGroup(
        id: id,
        nome: nome,
        igrejaId: igrejaId,
        diaSemana: diaSemana,
        horario: horario,
        liderPessoaId: liderPessoaId,
        liderNome: liderNome ?? '—',
        ativo: ativo,
        nota: nota,
      );
      mockSmallGroups.insert(0, created);
      return mockDelay(created);
    }
    final json = await _api.post('/small-groups', {
      'nome': nome,
      'igrejaId': igrejaId,
      'diaSemana': diaSemana.name.toUpperCase(),
      'horario': horario,
      'liderPessoaId': liderPessoaId,
      'ativo': ativo,
      'nota': nota,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<SmallGroup> update(
    String id, {
    required String nome,
    required DiaSemana diaSemana,
    required String liderPessoaId,
    String? liderNome,
    String? horario,
    required int nota,
    bool ativo = true,
  }) async {
    if (AppConfig.useMock) {
      final index = mockSmallGroups.indexWhere((c) => c.id == id);
      if (index < 0) throw Exception('Pequeno grupo não encontrado.');
      final current = mockSmallGroups[index];
      final lider = liderNome ?? current.liderNome;
      mockSmallGroups[index] = SmallGroup(
        id: current.id,
        nome: nome,
        igrejaId: current.igrejaId,
        diaSemana: diaSemana,
        horario: horario,
        liderPessoaId: liderPessoaId,
        liderNome: lider,
        ativo: ativo,
        nota: nota,
        encontros: current.encontros,
      );
      return mockDelay(mockSmallGroups[index]);
    }
    final json = await _api.put('/small-groups/$id', {
      'nome': nome,
      'diaSemana': diaSemana.name.toUpperCase(),
      'horario': horario,
      'liderPessoaId': liderPessoaId,
      'ativo': ativo,
      'nota': nota,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<void> delete(String id) async {
    if (AppConfig.useMock) {
      mockSmallGroups.removeWhere((c) => c.id == id);
      return mockDelay(null);
    }
    await _api.delete('/small-groups/$id');
  }

  Future<SmallGroupEncontro> saveEncontro(SmallGroupEncontro encontro) async {
    if (AppConfig.useMock) {
      final index = mockSmallGroups.indexWhere((c) => c.id == encontro.smallGroupId);
      if (index < 0) throw Exception('Pequeno grupo não encontrado.');
      final group = mockSmallGroups[index];
      final existe = group.encontros.any((e) => e.id == encontro.id);
      final saved = existe
          ? encontro
          : SmallGroupEncontro(
              id: 'ce${DateTime.now().millisecondsSinceEpoch}',
              smallGroupId: encontro.smallGroupId,
              data: encontro.data,
              anfitriaoPessoaId: encontro.anfitriaoPessoaId,
              anfitriaoNome: encontro.anfitriaoNome,
              compareceram: encontro.compareceram,
              anotacoes: encontro.anotacoes,
            );
      final encontros = existe
          ? group.encontros.map((e) => e.id == encontro.id ? saved : e).toList()
          : [...group.encontros, saved];
      mockSmallGroups[index] = SmallGroup(
        id: group.id,
        nome: group.nome,
        igrejaId: group.igrejaId,
        diaSemana: group.diaSemana,
        horario: group.horario,
        liderPessoaId: group.liderPessoaId,
        liderNome: group.liderNome,
        ativo: group.ativo,
        nota: group.nota,
        encontros: encontros,
      );
      return mockDelay(saved);
    }
    final payload = {
      'smallGroupId': encontro.smallGroupId,
      'data': encontro.data,
      'anfitriaoPessoaId': encontro.anfitriaoPessoaId,
      'compareceram': encontro.compareceram
          .map((c) => {'pessoaId': c.pessoaId, 'pessoaNome': c.pessoaNome})
          .toList(),
      'anotacoes': encontro.anotacoes,
    };
    Map<String, dynamic> json;
    if (encontro.id.isEmpty) {
      json = await _api.post('/small-groups/${encontro.smallGroupId}/encontros', payload)
          as Map<String, dynamic>;
    } else {
      json =
          await _api.put('/small-groups/encontros/${encontro.id}', payload) as Map<String, dynamic>;
    }
    return _mapEncontro(json);
  }

  SmallGroup _map(Map<String, dynamic> json) {
    final encontrosJson = json['encontros'] as List<dynamic>? ?? [];
    return SmallGroup(
      id: json['id'] as String,
      nome: json['nome'] as String,
      igrejaId: json['igrejaId'] as String? ?? '',
      diaSemana: diaSemanaFromString(json['diaSemana'] as String? ?? 'DOMINGO'),
      horario: json['horario'] as String?,
      liderPessoaId: json['liderPessoaId'] as String? ?? '',
      liderNome: json['liderNome'] as String? ?? '—',
      ativo: json['ativo'] as bool? ?? true,
      nota: (json['nota'] as num?)?.toInt() ?? 0,
      encontros: encontrosJson.map((e) => _mapEncontro(e as Map<String, dynamic>)).toList(),
    );
  }

  SmallGroupEncontro _mapEncontro(Map<String, dynamic> json) {
    final compareceramJson = json['compareceram'] as List<dynamic>? ?? [];
    return SmallGroupEncontro(
      id: json['id'] as String,
      smallGroupId: json['smallGroupId'] as String? ?? '',
      data: json['data'] as String,
      anfitriaoPessoaId: json['anfitriaoPessoaId'] as String?,
      anfitriaoNome: json['anfitriaoNome'] as String?,
      compareceram: compareceramJson
          .map(
            (c) => SmallGroupParticipante(
              pessoaId: c['pessoaId'] as String? ?? '',
              pessoaNome: c['pessoaNome'] as String? ?? '',
            ),
          )
          .toList(),
      anotacoes: json['anotacoes'] as String?,
    );
  }
}

DiaSemana diaSemanaFromString(String value) {
  final nome = value.toUpperCase();
  for (final d in DiaSemana.values) {
    if (d.name.toUpperCase() == nome) return d;
  }
  return DiaSemana.domingo;
}
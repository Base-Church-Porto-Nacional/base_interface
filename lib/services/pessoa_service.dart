import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import '../utils/pessoa_filtro.dart';
import 'api_client.dart';

class PessoaService {
  PessoaService(this._api);

  final ApiClient _api;

  Future<PageResponse<Pessoa>> list({
    int page = 0,
    int size = 20,
    String search = '',
    String filtro = 'TODOS',
    String? igrejaId,
  }) async {
    if (AppConfig.useMock) {
      var items = pessoasDaIgreja(igrejaId);
      final q = search.trim().toLowerCase();
      if (q.isNotEmpty) {
        items = items
            .where(
              (p) =>
                  p.nome.toLowerCase().contains(q) ||
                  p.email.toLowerCase().contains(q) ||
                  p.telefone.contains(q),
            )
            .toList();
      }
      if (filtro != 'TODOS') {
        items = items.where((p) => pessoaMatchesFiltro(p, filtro)).toList();
      }
      return mockDelay(paginate(items, page: page, size: size));
    }

    final query = igrejaId == null ? null : {'igrejaId': igrejaId};
    final list = await _api.get('/pessoas', query: query) as List<dynamic>;
    var mapped = list.map((e) => _mapPessoa(e as Map<String, dynamic>)).toList();

    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      mapped = mapped
          .where(
            (p) =>
                p.nome.toLowerCase().contains(q) ||
                p.email.toLowerCase().contains(q) ||
                p.telefone.contains(q),
          )
          .toList();
    }
    if (filtro != 'TODOS') {
      mapped = mapped.where((p) => pessoaMatchesFiltro(p, filtro)).toList();
    }
    return paginate(mapped, page: page, size: size);
  }

  Future<Pessoa> getById(String id) async {
    if (AppConfig.useMock) {
      final pessoa = mockPessoas.firstWhere(
        (p) => p.id == id,
        orElse: () => throw Exception('Pessoa não encontrada.'),
      );
      return mockDelay(pessoa);
    }
    final json = await _api.get('/pessoas/$id') as Map<String, dynamic>;
    return _mapPessoa(json);
  }

  Future<Pessoa> create({
    required String nome,
    String? telefone,
    String? email,
    String? igrejaId,
  }) async {
    if (AppConfig.useMock) {
      final created = Pessoa(
        id: 'p${DateTime.now().millisecondsSinceEpoch}',
        nome: nome,
        telefone: telefone ?? '',
        email: email ?? '',
        status: PessoaStatus.ativo,
        tipos: [PessoaTipo.visitante],
        ministerios: [],
        dataCadastro: DateTime.now().toIso8601String().substring(0, 10),
        igrejaId: igrejaId ?? 'i1',
      );
      mockPessoas.insert(0, created);
      return mockDelay(created);
    }
    final json = await _api.post('/pessoas', {
      'nome': nome,
      if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (igrejaId != null) 'igrejaId': igrejaId,
    }) as Map<String, dynamic>;
    return _mapPessoa(json);
  }

  Future<Pessoa> update(
    String id, {
    required String nome,
    String? telefone,
    String? email,
  }) async {
    if (AppConfig.useMock) {
      final index = mockPessoas.indexWhere((p) => p.id == id);
      if (index < 0) throw Exception('Pessoa não encontrada.');
      mockPessoas[index] = mockPessoas[index].copyWith(
        nome: nome,
        telefone: telefone ?? '',
        email: email ?? '',
      );
      return mockDelay(mockPessoas[index]);
    }
    final json = await _api.put('/pessoas/$id', {
      'nome': nome,
      'telefone': telefone,
      'email': email,
    }) as Map<String, dynamic>;
    return _mapPessoa(json);
  }

  Future<List<PessoaHistorico>> listHistorico(String pessoaId) async {
    if (AppConfig.useMock) {
      return mockDelay(
        mockHistoricos.where((h) => h.pessoaId == pessoaId).toList(),
      );
    }
    final list = await _api.get('/pessoas/$pessoaId/historico') as List<dynamic>;
    return list
        .map(
          (e) => PessoaHistorico(
            id: e['id'] as String,
            pessoaId: e['pessoaId'] as String,
            descricao: e['descricao'] as String,
            autorNome: e['autorNome'] as String,
            autorCargo: e['autorCargo'] as String?,
            dataRegistro: e['dataRegistro'] as String,
          ),
        )
        .toList();
  }

  Pessoa _mapPessoa(Map<String, dynamic> json) {
    return Pessoa(
      id: json['id'] as String,
      nome: json['nome'] as String,
      telefone: json['telefone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: (json['ativo'] as bool? ?? true)
          ? PessoaStatus.ativo
          : PessoaStatus.inativo,
      tipos: const [PessoaTipo.visitante],
      ministerios: const [],
      dataCadastro: json['dataCadastro'] as String? ?? '',
      igrejaId: json['igrejaId'] as String? ?? '',
      usuarioId: json['usuarioId'] as String?,
    );
  }
}

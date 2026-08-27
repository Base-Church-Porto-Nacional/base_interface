import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import 'api_client.dart';

class IgrejaService {
  IgrejaService(this._api);

  final ApiClient _api;

  Future<List<Igreja>> listVisiveis(AuthUser user) async {
    if (AppConfig.useMock) {
      if (user.isMatriz) return mockDelay(List<Igreja>.from(mockIgrejas));
      return mockDelay(
        mockIgrejas.where((i) => i.id == user.igrejaId).toList(),
      );
    }
    final list = await _api.get('/igrejas') as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<List<Igreja>> list() async {
    if (AppConfig.useMock) return mockDelay(List<Igreja>.from(mockIgrejas));
    final list = await _api.get('/igrejas') as List<dynamic>;
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  Future<Igreja> getById(String id) async {
    if (AppConfig.useMock) {
      final igreja = igrejaById(id);
      if (igreja == null) throw Exception('Igreja não encontrada.');
      return mockDelay(igreja);
    }
    final json = await _api.get('/igrejas/$id') as Map<String, dynamic>;
    return _map(json);
  }

  Future<Igreja> createFilial({
    required String matrizId,
    required String nome,
    required String pastorPessoaId,
    required String pastorNome,
    required String adminNome,
    required String adminEmail,
    required String adminUsername,
  }) async {
    if (AppConfig.useMock) {
      final id = 'i${DateTime.now().millisecondsSinceEpoch}';
      final adminId = 'u${DateTime.now().millisecondsSinceEpoch}';
      final created = Igreja(
        id: id,
        nome: nome,
        tipo: IgrejaTipo.filial,
        igrejaMatrizId: matrizId,
        pastorPessoaId: pastorPessoaId,
        pastorNome: pastorNome,
        adminUsuarioId: adminId,
        adminNome: adminNome,
        ativo: true,
      );
      mockIgrejas.add(created);
      mockUsuarios.add(
        UsuarioConta(
          id: adminId,
          username: adminUsername,
          email: adminEmail,
          igrejaId: id,
          igrejaNome: nome,
          papeis: const [Role.admin],
          ativo: true,
        ),
      );
      return mockDelay(created);
    }
    final json = await _api.post('/igrejas/$matrizId/filiais', {
      'nome': nome,
      'pastorPessoaId': pastorPessoaId,
      'adminNome': adminNome,
      'adminEmail': adminEmail,
      'adminUsername': adminUsername,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Future<Igreja> update(
    String id, {
    required String nome,
    required String pastorPessoaId,
    required String pastorNome,
    required bool ativo,
  }) async {
    if (AppConfig.useMock) {
      final index = mockIgrejas.indexWhere((i) => i.id == id);
      if (index < 0) throw Exception('Igreja não encontrada.');
      final current = mockIgrejas[index];
      final updated = Igreja(
        id: current.id,
        nome: nome,
        tipo: current.tipo,
        igrejaMatrizId: current.igrejaMatrizId,
        pastorPessoaId: pastorPessoaId,
        pastorNome: pastorNome,
        adminUsuarioId: current.adminUsuarioId,
        adminNome: current.adminNome,
        ativo: ativo,
      );
      mockIgrejas[index] = updated;
      return mockDelay(updated);
    }
    final json = await _api.put('/igrejas/$id', {
      'nome': nome,
      'pastorPessoaId': pastorPessoaId,
      'ativo': ativo,
    }) as Map<String, dynamic>;
    return _map(json);
  }

  Igreja _map(Map<String, dynamic> json) {
    return Igreja(
      id: json['id'] as String,
      nome: json['nome'] as String,
      tipo: (json['tipo'] as String? ?? 'FILIAL').toUpperCase() == 'MATRIZ'
          ? IgrejaTipo.matriz
          : IgrejaTipo.filial,
      igrejaMatrizId: json['igrejaMatrizId'] as String?,
      pastorPessoaId: json['pastorPessoaId'] as String? ?? '',
      pastorNome: json['pastorNome'] as String? ?? '',
      adminUsuarioId: json['adminUsuarioId'] as String? ?? '',
      adminNome: json['adminNome'] as String? ?? '',
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

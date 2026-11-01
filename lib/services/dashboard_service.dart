import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'pessoa_service.dart';

class DashboardService {
  DashboardService(this._api, this._pessoaService);

  final ApiClient _api;
  final PessoaService _pessoaService;

  Future<DashboardStats?> getStats() async {
    if (AppConfig.useMock) return mockDelay(mockDashboard);

    final Map<String, dynamic> json;
    try {
      json = await _api.get('/dashboard') as Map<String, dynamic>;
    } on ApiException catch (e) {
      if (e.status == 403) return null;
      rethrow;
    }

    final pessoas = await _pessoaService.list(filtro: 'MEMBRO', size: 100000);

    return DashboardStats(
      totalPessoas: (json['totalPessoas'] as num? ?? 0).toInt(),
      totalMembros: pessoas.totalElements,
      totalVoluntarios: (json['totalVoluntariosAtivos'] as num? ?? 0).toInt(),
      totalLideres: (json['totalLideres'] as num? ?? 0).toInt(),
    );
  }
}

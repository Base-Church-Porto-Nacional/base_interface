import '../config/app_config.dart';
import '../mocks/mock_data.dart';
import '../models/models.dart';

class DashboardService {
  Future<DashboardStats> getStats() async {
    if (AppConfig.useMock) return mockDelay(mockDashboard);
    // API real: implementar agregação quando conectar ao backend
    return mockDashboard;
  }
}

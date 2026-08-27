import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../utils/permissions.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService) {
    user = _authService.getStoredUser();
  }

  final AuthService _authService;

  AuthUser? user;
  bool isLoading = false;
  String? error;

  bool get isAuthenticated => user != null && _authService.isAuthenticated;

  bool can(String permission) => hasPermission(user?.roles ?? [], permission);

  bool hasRole(Role role) => user?.roles.contains(role) ?? false;

  Future<bool> login(String username, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      user = await _authService.login(username, password);
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user = null;
    notifyListeners();
  }
}

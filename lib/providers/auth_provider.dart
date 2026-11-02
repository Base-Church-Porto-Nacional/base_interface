import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService) {
    user = _authService.getStoredUser();
    // Sessão persistida no formato antigo (sem `permissoes`): busca /me agora;
    // enquanto isso o usuário fica sem permissões (fail-closed).
    if (user?.permissoesAusentes ?? false) {
      unawaited(recarregarMe());
    }
  }

  final AuthService _authService;

  AuthUser? user;
  bool isLoading = false;
  String? error;

  bool get isAuthenticated => user != null && _authService.isAuthenticated;

  bool can(Capacidade capacidade) => user?.permissoes.tem(capacidade) ?? false;

  /// Recarrega `GET /me` (permissões novas após mudar papéis, ou migração de
  /// sessão antiga). Falha de rede mantém o usuário atual.
  Future<void> recarregarMe() async {
    if (user == null) return;
    try {
      final atualizado = await _authService.recarregarMe();
      if (atualizado != null) {
        user = atualizado;
        notifyListeners();
      }
    } catch (_) {
      await expireSession();
    }
  }

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

  Future<void> expireSession() async {
    if (user == null) return;
    await _authService.logout();
    user = null;
    error = 'Sessão expirada. Faça login novamente.';
    notifyListeners();
  }
}

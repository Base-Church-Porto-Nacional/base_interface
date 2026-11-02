import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/models.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  AuthProvider(this._authService) {
    user = _authService.getStoredUser();
    // Sempre revalida a sessão armazenada em /me: papéis/permissões podem ter
    // mudado desde o último uso (e sessões antigas não têm `permissoes`, ficando
    // fail-closed até a resposta).
    if (user != null) {
      unawaited(recarregarMe());
    }
  }

  final AuthService _authService;
  bool _disposed = false;

  /// Ao voltar para o app, revalida as permissões (registrado em `app.dart`).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && user != null) {
      unawaited(recarregarMe());
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

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

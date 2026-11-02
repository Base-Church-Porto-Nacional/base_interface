import 'api_client.dart';

/// Endpoints públicos de acesso (sem Bearer e sem redirecionar a sessão
/// expirada): definir senha por link de uso único e "esqueci minha senha".
class AcessoService {
  AcessoService(this._api);

  final ApiClient _api;

  /// `GET /auth/token/{token}`. 410 quando expirado, usado ou desconhecido.
  Future<({String tipo, String primeiroNome})> info(String token) async {
    final json = await _api.get(
      '/auth/token/${Uri.encodeComponent(token)}',
      auth: false,
    ) as Map<String, dynamic>;
    return (
      tipo: json['tipo'] as String? ?? 'CONVITE',
      primeiroNome: json['primeiroNome'] as String? ?? '',
    );
  }

  /// `POST /auth/definir-senha`. Devolve o LoginResponse.
  Future<Map<String, dynamic>> definirSenha(String token, String senha) async {
    return await _api.post('/auth/definir-senha', {
      'token': token,
      'senha': senha,
    }, false) as Map<String, dynamic>;
  }

  /// `POST /auth/esqueci-senha`: o servidor responde 204 sempre.
  Future<void> esqueciSenha(String identificador) async {
    await _api.post('/auth/esqueci-senha', {
      'identificador': identificador,
    }, false);
  }
}

import 'dart:convert';

import 'package:base_church/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient api;
  late int expiradas;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'base_access_token': 't'});
    api = ApiClient(await SharedPreferences.getInstance());
    expiradas = 0;
    api.onUnauthorized = () => expiradas++;
  });

  Future<T> comResposta<T>(
    int status,
    Object? body,
    Future<T> Function() call,
  ) {
    final client = MockClient(
      (_) async => http.Response(
        body == null ? '' : jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    return http.runWithClient(call, () => client);
  }

  test('401 em chamada autenticada expira a sessão', () async {
    await expectLater(
      comResposta(401, null, () => api.get('/pessoas')),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 401)
            .having((e) => e.message, 'message', contains('Sessão expirada')),
      ),
    );
    expect(expiradas, 1);
  });

  test(
    '401 no login mostra a mensagem do servidor sem expirar sessão',
    () async {
      await expectLater(
        comResposta(
          401,
          {'message': 'Usuário ou senha inválidos'},
          () => api.post('/auth/login', {'username': 'a', 'senha': 'b'}, false),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Usuário ou senha inválidos',
          ),
        ),
      );
      expect(expiradas, 0);
    },
  );

  test('erro de negócio repassa a mensagem do backend', () async {
    await expectLater(
      comResposta(400, {
        'message': 'Hora fim deve ser posterior à hora início',
      }, () => api.post('/disponibilidades/semanal', {})),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 400)
            .having(
              (e) => e.message,
              'message',
              'Hora fim deve ser posterior à hora início',
            ),
      ),
    );
  });

  test('erro sem corpo JSON cai na mensagem genérica', () async {
    final client = MockClient((_) async => http.Response('boom', 500));
    await expectLater(
      http.runWithClient(() => api.get('/x'), () => client),
      throwsA(
        isA<ApiException>().having((e) => e.message, 'message', 'Erro 500'),
      ),
    );
  });

  test('falha de rede vira mensagem amigável', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('Failed host lookup'),
    );
    await expectLater(
      http.runWithClient(() => api.get('/x'), () => client),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Sem conexão'),
        ),
      ),
    );
  });

  test('429 de login repassa a mensagem de bloqueio', () async {
    await expectLater(
      comResposta(429, {
        'message': 'Muitas tentativas de login. Tente mais tarde.',
      }, () => api.post('/auth/login', {}, false)),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 429)
            .having(
              (e) => e.message,
              'message',
              startsWith('Muitas tentativas'),
            ),
      ),
    );
    expect(expiradas, 0);
  });
}

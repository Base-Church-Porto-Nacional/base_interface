import 'dart:convert';

import 'package:base_church/models/models.dart';
import 'package:base_church/providers/auth_provider.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ApiClient, SharedPreferences)> sessaoArmazenada() async {
    SharedPreferences.setMockInitialValues({
      'base_access_token': 't',
      'base_user': jsonEncode(mockUser.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    return (ApiClient(prefs), prefs);
  }

  Future<AuthProvider> iniciar(FakeApi fake, AuthService service) => fake.run(() async {
        final provider = AuthProvider(service);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return provider;
      });

  test('com usuário armazenado, recarrega /me ao iniciar (permissões frescas)', () async {
    final (api, prefs) = await sessaoArmazenada();
    final fake = FakeApi({
      'GET /me': (_) => (
        200,
        {
          'id': 'u1',
          'nome': 'Ana Costa',
          'papeis': ['SECRETARIA'],
          'permissoes': {
            'capacidades': ['PESSOAS_VER_TODAS'],
            'ministeriosLiderados': [],
            'basesLideradas': [],
            'gruposLiderados': [],
            'ehVoluntario': false,
          },
          'igrejaId': 'i1',
          'igrejaTipo': 'MATRIZ',
        },
      ),
    });

    final provider = await iniciar(fake, AuthService(api, prefs));

    expect(fake.log, ['GET /me']);
    expect(provider.user?.papeis, ['SECRETARIA']);
    expect(provider.can(Capacidade.filialCriar), isFalse);
    expect(provider.can(Capacidade.pessoasVerTodas), isTrue);
  });

  test('401 no /me de inicialização expira a sessão', () async {
    final (api, prefs) = await sessaoArmazenada();
    final fake = FakeApi({
      'GET /me': (_) => (401, {'message': 'Token inválido'}),
    });

    final provider = await iniciar(fake, AuthService(api, prefs));

    expect(provider.user, isNull);
  });

  test('erro que não é 401 mantém o usuário armazenado', () async {
    final (api, prefs) = await sessaoArmazenada();
    final fake = FakeApi({});

    final provider = await iniciar(fake, AuthService(api, prefs));

    expect(provider.user?.id, 'u1');
    expect(provider.can(Capacidade.filialCriar), isTrue);
  });
}

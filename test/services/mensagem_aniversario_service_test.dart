import 'package:base_church/config/app_config.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/mensagem_aniversario_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient api;
  late MensagemAniversarioService service;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    api = ApiClient(await SharedPreferences.getInstance());
  });

  setUp(() {
    expect(AppConfig.useMock, isTrue, reason: 'estes testes exigem modo mock');
    service = MensagemAniversarioService(api);
  });

  late MockState snapshot;

  setUp(() => snapshot = MockState.capture());
  tearDown(() => snapshot.restore());

  group('get', () {
    test('devolve a mensagem padrão da igreja', () async {
      final config = await service.get(igrejaId: 'i1');

      expect(config.id, 'ma1');
      expect(config.igrejaId, 'i1');
      expect(config.mensagem, contains('[Nome]'));
    });

    test('isola a mensagem por igreja', () async {
      final matriz = await service.get(igrejaId: 'i1');
      final filial = await service.get(igrejaId: 'i2');

      expect(matriz.mensagem, isNot(filial.mensagem));
      expect(filial.mensagem, contains('[Nome]'));
    });

    test('devolve mensagem vazia quando a igreja ainda não configurou', () async {
      final config = await service.get(igrejaId: 'i9');

      expect(config.id, isNull);
      expect(config.mensagem, isEmpty);
      expect(config.igrejaId, 'i9');
    });
  });

  group('save', () {
    test('persiste a mensagem e devolve o registro salvo', () async {
      const texto = 'Feliz aniversário, [Nome]! Deus te abençoe. 🙏';
      final atual = await service.get(igrejaId: 'i1');

      final saved = await service.save(atual.copyWith(mensagem: texto));

      expect(saved.mensagem, texto);
      expect(saved.id, 'ma1');
      expect((await service.get(igrejaId: 'i1')).mensagem, texto);
    });

    test('remove espaços das pontas', () async {
      final atual = await service.get(igrejaId: 'i1');

      final saved = await service.save(atual.copyWith(mensagem: '  Olá, [Nome]!  '));

      expect(saved.mensagem, 'Olá, [Nome]!');
    });

    test('cria o registro quando a igreja ainda não tinha mensagem', () async {
      final atual = await service.get(igrejaId: 'i9');

      final saved = await service.save(atual.copyWith(mensagem: 'Feliz aniversário, [Nome]!'));

      expect(saved.id, isNotNull);
      expect((await service.get(igrejaId: 'i9')).mensagem, 'Feliz aniversário, [Nome]!');
    });

    test('recusa mensagem vazia', () async {
      final atual = await service.get(igrejaId: 'i1');

      await expectLater(
        service.save(atual.copyWith(mensagem: '   ')),
        throwsWithMessage('Informe a mensagem padrão.'),
      );
      expect((await service.get(igrejaId: 'i1')).mensagem, contains('[Nome]'));
    });
  });
}

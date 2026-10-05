import 'package:base_church/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatarMensagemAniversario', () {
    test('substitui [Nome] pelo nome informado', () {
      final resultado = formatarMensagemAniversario(
        'Feliz aniversário, [Nome]! 🎉',
        valores: {'Nome': 'Gustavo'},
      );

      expect(resultado, 'Feliz aniversário, Gustavo! 🎉');
    });

    test('usa o exemplo da variável quando não há valor informado', () {
      expect(
        formatarMensagemAniversario('Feliz aniversário, [Nome]!'),
        'Feliz aniversário, Gustavo!',
      );
    });

    test('substitui todas as ocorrências do placeholder', () {
      final resultado = formatarMensagemAniversario(
        '[Nome], [Nome]!',
        valores: {'Nome': 'Ana'},
      );

      expect(resultado, 'Ana, Ana!');
    });

    test('preserva emojis e quebras de linha', () {
      const mensagem =
          'Feliz aniversário, [Nome]! 🎉\nQue Deus abençoe sua vida. 🙏🎂';
      final resultado = formatarMensagemAniversario(
        mensagem,
        valores: {'Nome': 'Ana'},
      );

      expect(resultado, 'Feliz aniversário, Ana! 🎉\nQue Deus abençoe sua vida. 🙏🎂');
    });

    test('não confunde [Nome] com [Nome Completo]', () {
      final resultado = formatarMensagemAniversario(
        '[Nome] e [Nome Completo]',
        valores: {'Nome': 'Ana', 'Nome Completo': 'Ana Costa'},
      );

      expect(resultado, 'Ana e Ana Costa');
    });

    test('mantém placeholders desconhecidos para o back-end resolver', () {
      final resultado = formatarMensagemAniversario('Feliz aniversário, [Nome]! [Cidade]');

      expect(resultado, 'Feliz aniversário, Gustavo! [Cidade]');
    });

    test('devolve a mensagem intacta quando não há placeholders', () {
      expect(formatarMensagemAniversario('Parabéns!'), 'Parabéns!');
      expect(formatarMensagemAniversario(''), '');
    });
  });

  group('mensagemUsaVariavel', () {
    test('detecta o placeholder do nome', () {
      expect(mensagemUsaVariavel('Feliz aniversário, [Nome]!', 'Nome'), isTrue);
    });

    test('não confunde [Nome] com [Nome Completo]', () {
      expect(
        mensagemUsaVariavel('Parabéns, [Nome Completo]', 'Nome'),
        isFalse,
      );
    });

    test('detecta ausência do placeholder', () {
      expect(mensagemUsaVariavel('Parabéns!', 'Nome'), isFalse);
    });
  });

  group('MensagemAniversario.copyWith', () {
    test('altera apenas a mensagem e preserva a identidade', () {
      const original = MensagemAniversario(
        id: 'ma1',
        igrejaId: 'i1',
        mensagem: 'Antiga',
      );

      final atualizada = original.copyWith(mensagem: 'Nova');

      expect(atualizada.mensagem, 'Nova');
      expect(atualizada.id, 'ma1');
      expect(atualizada.igrejaId, 'i1');
    });
  });
}

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void expectSemPalavraPartida(WidgetTester t, String texto) {
  final rp = t.renderObject<RenderParagraph>(find.text(texto));
  final painter = TextPainter(
    text: rp.text,
    textDirection: rp.textDirection,
    textScaler: rp.textScaler,
    maxLines: rp.maxLines,
  )..layout(maxWidth: rp.size.width);
  final plano = rp.text.toPlainText();
  for (var i = 1; i < plano.length; i++) {
    final linha = painter.getLineBoundary(TextPosition(offset: i));
    if (linha.start == i) {
      expect(
        plano[i - 1],
        ' ',
        reason: 'quebra dentro de palavra em "$plano" ($i)',
      );
    }
  }
  expect(rp.didExceedMaxLines, isFalse);
  painter.dispose();
}

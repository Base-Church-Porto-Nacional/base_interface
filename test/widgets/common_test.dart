import 'dart:ui' show PointerDeviceKind;

import 'package:base_church/theme/brand_colors.dart';
import 'package:base_church/widgets/brand/brand.dart';
import 'package:base_church/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('EmptyView mostra BrandMark, mensagem e acao', (t) async {
    await pumpBrand(
      t,
      const EmptyView(message: 'Nada aqui', action: Text('Criar')),
    );
    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.text('Nada aqui'), findsOneWidget);
    expect(find.text('Criar'), findsOneWidget);
  });

  testWidgets('StatusBadge success no escuro usa cor de marca', (t) async {
    await pumpBrand(
      t,
      const StatusBadge(label: 'OK', success: true),
      brightness: Brightness.dark,
    );
    final text = t.widget<Text>(find.text('OK'));
    expect(text.style?.color, BrandColors.dark.success);
  });

  testWidgets('LoadingView sem animacoes nao tem animacao rodando', (t) async {
    await pumpBrand(t, const LoadingView(), disableAnimations: true);
    await t.pump();
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('LoadingView anima shimmer quando habilitado', (t) async {
    await pumpBrand(t, const LoadingView());
    await t.pump();
    expect(t.hasRunningAnimations, isTrue);
  });

  testWidgets('ErrorView mostra icone de perigo', (t) async {
    await pumpBrand(t, const ErrorView(message: 'Falhou'));
    final icon = t.widget<Icon>(find.byType(Icon));
    expect(icon.color, BrandColors.light.danger);
  });

  testWidgets('BrandCard hover na borda inferior fica estavel', (t) async {
    await pumpBrand(
      t,
      Center(
        child: BrandCard(
          onTap: () {},
          child: const SizedBox(width: 100, height: 50),
        ),
      ),
    );
    final rect = t.getRect(find.byType(BrandCard));
    final gesture = await t.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(1, 1));
    await gesture.moveTo(Offset(rect.center.dx, rect.bottom - 1));
    double dy() => t
        .widget<AnimatedContainer>(
          find.descendant(
            of: find.byType(BrandCard),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .transform!
        .getTranslation()
        .y;
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 200));
      expect(dy(), -2.0, reason: 'pump $i');
    }
    await gesture.removePointer();
  });

  testWidgets('BrandCard focado mostra anel de foco', (t) async {
    await pumpBrand(
      t,
      Center(
        child: BrandCard(onTap: () {}, child: const Text('card')),
      ),
    );
    final ring = find.byWidgetPredicate((w) => w is FocusRing && w.focused);
    expect(ring, findsNothing);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(ring, findsOneWidget);
    final box = t.widget<DecoratedBox>(
      find.descendant(of: ring, matching: find.byKey(FocusRing.ringKey)),
    );
    final border = (box.decoration as BoxDecoration).border as Border;
    expect(border.top.color, BrandColors.light.focus);
    expect(border.top.width, 2);
    final card = t.getRect(find.byType(BrandCard));
    final anel = t.getRect(find.byKey(FocusRing.ringKey));
    expect(anel, card.inflate(4));
  });
}

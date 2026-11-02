import 'package:base_church/theme/brand_assets.dart';
import 'package:base_church/theme/app_typography.dart';
import 'package:base_church/theme/brand_colors.dart';
import 'package:base_church/widgets/brand/brand.dart';
import 'package:base_church/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump.dart';
import '../helpers/text_lines.dart';

final _ring = find.descendant(
  of: find.byType(BrandSeal),
  matching: find.byType(RotationTransition),
);

void main() {
  testWidgets('GlassSurface usa BackdropFilter', (t) async {
    await pumpBrand(t, const GlassSurface(child: Text('x')));
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('GlassSurface sem vidro em alto contraste', (t) async {
    await pumpBrand(
      t,
      const GlassSurface(child: Text('x')),
      highContrast: true,
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('BrandSeal gira so com animacao habilitada', (t) async {
    await pumpBrand(t, const Center(child: BrandSeal(spinning: true)));
    final animated = t.widget<RotationTransition>(_ring);
    expect(animated.turns.value, 0);
    await t.pump(const Duration(seconds: 15));
    expect(animated.turns.value, closeTo(0.25, 0.01));
    await t.pumpWidget(const SizedBox());

    await pumpBrand(
      t,
      const Center(child: BrandSeal(spinning: true)),
      disableAnimations: true,
    );
    final still = t.widget<RotationTransition>(_ring);
    await t.pump(const Duration(seconds: 15));
    expect(still.turns.value, 0);
  });

  testWidgets('AmbientBackground parado com reduzir movimento', (t) async {
    await pumpBrand(
      t,
      const AmbientBackground(animated: true, child: SizedBox.expand()),
      disableAnimations: true,
    );
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('BrandSeal usa textPrimary no escuro', (t) async {
    await pumpBrand(
      t,
      const Center(child: BrandSeal()),
      brightness: Brightness.dark,
    );
    final b = t
        .widgetList<SvgPicture>(find.byType(SvgPicture))
        .firstWhere(
          (s) =>
              s.bytesLoader is SvgAssetLoader &&
              (s.bytesLoader as SvgAssetLoader).assetName == BrandAssets.b,
        );
    expect(
      b.colorFilter,
      ColorFilter.mode(BrandColors.dark.textPrimary, BlendMode.srcIn),
    );
  });

  testWidgets('PageHeader mostra eyebrow e titulo em caixa-alta', (t) async {
    await pumpBrand(
      t,
      const PageHeader(eyebrow: 'Escalas · Novembro', title: 'Escalas'),
    );
    expect(find.text('ESCALAS · NOVEMBRO'), findsOneWidget);
    expect(find.text('ESCALAS'), findsOneWidget);
  });

  for (final (largura, escala) in [(360.0, 1.0), (390.0, 1.0), (360.0, 2.0)]) {
    testWidgets('PageHeader nao parte palavra em ${largura}px x$escala', (
      t,
    ) async {
      await pumpBrand(
        t,
        const Padding(
          padding: EdgeInsets.all(16),
          child: PageHeader(title: 'Aniversariantes do dia'),
        ),
        size: Size(largura, 800),
        textScale: escala,
      );
      expect(t.takeException(), isNull);
      expectSemPalavraPartida(t, 'ANIVERSARIANTES DO DIA');
    });
  }

  testWidgets('PageHeader usa titulo compacto abaixo de 600px', (t) async {
    await pumpBrand(t, const PageHeader(title: 'Escalas'));
    final rp = t.renderObject<RenderParagraph>(find.text('ESCALAS'));
    expect((rp.text as TextSpan).style!.fontSize, 22);
    await pumpBrand(
      t,
      const PageHeader(title: 'Escalas'),
      size: const Size(1024, 800),
    );
    final largo = t.renderObject<RenderParagraph>(find.text('ESCALAS'));
    expect((largo.text as TextSpan).style!.fontSize, 28);
  });

  testWidgets('saudacao hero nao parte palavra em 360px', (t) async {
    await pumpBrand(
      t,
      Padding(
        padding: const EdgeInsets.all(16),
        child: BrandHeadline(
          'BOA TARDE, MAXIMILIANO',
          style: AppTypography.hero,
          compactSize: 28,
        ),
      ),
      size: const Size(360, 800),
    );
    expectSemPalavraPartida(t, 'BOA TARDE, MAXIMILIANO');
    final rp = t.renderObject<RenderParagraph>(
      find.text('BOA TARDE, MAXIMILIANO'),
    );
    expect((rp.text as TextSpan).style!.fontSize, greaterThanOrEqualTo(12));
  });

  testWidgets('StatTile mostra label e value', (t) async {
    await pumpBrand(t, const StatTile(label: 'Membros', value: '128'));
    expect(find.text('Membros'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
  });

  testWidgets('BrandCard responde ao toque', (t) async {
    var taps = 0;
    await pumpBrand(
      t,
      Center(
        child: BrandCard(onTap: () => taps++, child: const Text('c')),
      ),
    );
    await t.tap(find.text('c'));
    expect(taps, 1);
  });

  testWidgets('SpotlightBlock repassa onInverse e InfoPill renderiza', (
    t,
  ) async {
    await pumpBrand(
      t,
      const Column(
        children: [
          SpotlightBlock(child: Text('s')),
          InfoPill(text: '19h30', icon: Icons.schedule),
        ],
      ),
      brightness: Brightness.dark,
    );
    final style = DefaultTextStyle.of(t.element(find.text('s')));
    expect(style.style.color, BrandColors.dark.onInverse);
    expect(find.text('19h30'), findsOneWidget);
  });
}

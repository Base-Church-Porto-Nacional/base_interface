import 'package:base_church/theme/brand_assets.dart';
import 'package:base_church/theme/brand_colors.dart';
import 'package:base_church/widgets/brand/brand.dart';
import 'package:base_church/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump.dart';

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

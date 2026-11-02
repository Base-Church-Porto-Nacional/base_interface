import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:base_church/theme/brand_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final all = [
    BrandAssets.selo,
    BrandAssets.anel,
    BrandAssets.b,
    BrandAssets.grain,
  ];

  test('brand assets carregam', () async {
    for (final path in all) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('svgs usam um unico fill e nao embutem imagem', () async {
    for (final path in [BrandAssets.selo, BrandAssets.anel, BrandAssets.b]) {
      final text = await rootBundle.loadString(path);
      final fills = RegExp(r'fill="([^"]*)"')
          .allMatches(text)
          .map((m) => m.group(1))
          .toSet();
      expect(fills.length, 1, reason: path);
      expect(text.contains('<image'), isFalse, reason: path);
    }
  });

  test('arquivos oficiais nao entram no bundle', () async {
    for (final path in [
      'assets/brand/logo_base_church.pdf',
      'assets/brand/logo_branca.png',
      'assets/brand/logo_preta.png',
      'assets/brand/app_icon.png',
    ]) {
      await expectLater(
        () => rootBundle.load(path),
        throwsA(anything),
        reason: path,
      );
    }
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib fora do tema nao usa cores fixas', () {
    final pattern = RegExp(r'AppColors|Color\(0x|Colors\.(?!transparent\b)\w+');
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (path.startsWith('lib/theme/') ||
          path.startsWith('lib/widgets/brand/')) {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) offenders.add('$path:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}

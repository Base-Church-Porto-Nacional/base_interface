import 'package:base_church/services/export_service.dart';
import 'package:base_church/widgets/export_menu.dart';
import 'package:base_church/widgets/filter_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('FilterMenu e ExportMenu com alvo de 48', (t) async {
    await pumpBrand(
      t,
      Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilterMenu(value: 'TODOS', onChanged: (_) {}),
            const ExportMenu(recurso: ExportRecurso.dashboard),
          ],
        ),
      ),
    );
    expect(t.getSize(find.byType(FilterMenu)).height, greaterThanOrEqualTo(48));
    expect(t.getSize(find.byType(FilterMenu)).width, greaterThanOrEqualTo(48));
    expect(t.getSize(find.byType(ExportMenu)).height, greaterThanOrEqualTo(48));
  });

  testWidgets('menus usam o popupMenuTheme', (t) async {
    await pumpBrand(
      t,
      Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilterMenu(value: 'TODOS', onChanged: (_) {}),
            const ExportMenu(recurso: ExportRecurso.dashboard),
          ],
        ),
      ),
    );
    for (final menu in t.widgetList<PopupMenuButton>(
      find.byWidgetPredicate((w) => w is PopupMenuButton),
    )) {
      expect(menu.shape, isNull);
      expect(menu.color, isNull);
    }
  });
}

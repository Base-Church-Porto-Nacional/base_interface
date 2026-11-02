import 'package:flutter/material.dart';

import '../theme/brand_colors.dart';
import '../utils/format.dart';

List<int> anosCompetencia(int selecionado) {
  final atual = DateTime.now().year;
  final inicio = selecionado < atual - 1 ? selecionado : atual - 1;
  final fim = selecionado > atual + 2 ? selecionado : atual + 2;
  return [for (var y = inicio; y <= fim; y++) y];
}

(int, int) partesCompetencia(String competencia) {
  final now = DateTime.now();
  final parts = competencia.split('-');
  final year = int.tryParse(parts[0]) ?? now.year;
  final month = parts.length > 1
      ? int.tryParse(parts[1]) ?? now.month
      : now.month;
  return (year, month);
}

Future<String?> pickCompetencia(BuildContext context, String atual) async {
  var (year, month) = partesCompetencia(atual);
  final picked = await showDialog<(int, int)>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: ctx.brand.surfaceOverlay,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Competência'),
        content: StatefulBuilder(
          builder: (context, setLocal) {
            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: month,
                    decoration: const InputDecoration(labelText: 'Mês'),
                    items: [
                      for (var i = 1; i <= 12; i++)
                        DropdownMenuItem(value: i, child: Text(mesesPt[i - 1])),
                    ],
                    onChanged: (v) => setLocal(() => month = v ?? month),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: year,
                    decoration: const InputDecoration(labelText: 'Ano'),
                    items: [
                      for (final y in anosCompetencia(year))
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (v) => setLocal(() => year = v ?? year),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, (year, month)),
            child: const Text('Aplicar'),
          ),
        ],
      );
    },
  );
  if (picked == null) return null;
  return competenciaFrom(DateTime(picked.$1, picked.$2));
}

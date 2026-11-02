import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/export_service.dart';
import '../theme/brand_colors.dart';
import 'common.dart';

class ExportMenu extends StatefulWidget {
  const ExportMenu({
    super.key,
    required this.recurso,
    this.filtro,
    this.allowHistorico = false,
  });

  final ExportRecurso recurso;
  final String? filtro;
  final bool allowHistorico;

  @override
  State<ExportMenu> createState() => _ExportMenuState();
}

class _ExportMenuState extends State<ExportMenu> {
  bool _incluirHistorico = false;
  bool _exporting = false;

  Future<void> _export(ExportFormato formato) async {
    setState(() => _exporting = true);
    try {
      final exportService = context.read<ExportService>();
      await exportService.share(
        widget.recurso,
        formato,
        opcoes: ExportOpcoes(
          filtro: widget.filtro,
          incluirHistorico: _incluirHistorico,
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, 'Erro ao exportar: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return PopupMenuButton<ExportFormato>(
      color: brand.surfaceOverlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: brand.border),
      ),
      enabled: !_exporting,
      tooltip: 'Exportar',
      onSelected: _export,
      itemBuilder: (_) => [
        if (widget.allowHistorico)
          PopupMenuItem(
            enabled: false,
            child: StatefulBuilder(
              builder: (context, setLocal) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Exportar histórico?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                value: _incluirHistorico,
                onChanged: (v) {
                  setLocal(() => _incluirHistorico = v ?? false);
                  setState(() => _incluirHistorico = v ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ),
        if (widget.allowHistorico) const PopupMenuDivider(),
        const PopupMenuItem(value: ExportFormato.txt, child: Text('TXT')),
        const PopupMenuItem(value: ExportFormato.md, child: Text('Markdown')),
        const PopupMenuItem(value: ExportFormato.xlsx, child: Text('Excel')),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: brand.borderStrong),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_exporting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.download_outlined, size: 18),
            const SizedBox(width: 8),
            const Text('Exportar'),
          ],
        ),
      ),
    );
  }
}

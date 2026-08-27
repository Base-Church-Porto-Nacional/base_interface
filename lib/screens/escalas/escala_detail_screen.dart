import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/escala_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class EscalaDetailScreen extends StatefulWidget {
  const EscalaDetailScreen({super.key, required this.escalaId});

  final String escalaId;

  @override
  State<EscalaDetailScreen> createState() => _EscalaDetailScreenState();
}

class _EscalaDetailScreenState extends State<EscalaDetailScreen> {
  Escala? _escala;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final escala = await context.read<EscalaService>().getById(widget.escalaId);
      if (mounted) setState(() => _escala = escala);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null || _escala == null) {
      return ErrorView(message: _error ?? 'Escala não encontrada.', onRetry: _load);
    }
    final e = _escala!;
    final byDate = <String, List<EscalaItem>>{};
    for (final item in e.itens) {
      byDate.putIfAbsent(item.data, () => []).add(item);
    }
    final dates = byDate.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: e.titulo,
          description:
              '${escalaTipoLabel(e.tipo)} · ${formatCompetencia(e.competencia)}',
          actions: [
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Voltar')),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row('Competência', formatCompetencia(e.competencia)),
                _row('Supervisor', e.supervisorNome),
                if (e.pregadorNome != null) _row('Pregador', e.pregadorNome!),
                if (e.ministerioNome != null) _row('Ministério', e.ministerioNome!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final date in dates) ...[
          Text(formatDate(date), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final item in byDate[date]!)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MobileListTile(
                title: item.pessoaNome ?? '—',
                subtitle: [
                  if (item.servicoNome != null) item.servicoNome,
                  if (item.horario != null) item.horario,
                ].whereType<String>().join(' · '),
                trailing: StatusBadge(
                  label: item.status.name.toUpperCase(),
                  success: item.status == EscalaItemStatus.confirmado,
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

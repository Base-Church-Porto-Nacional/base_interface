import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/dashboard_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/export_menu.dart';
import '../../services/export_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  String? _error;
  bool _loading = true;

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
      final stats = await context.read<DashboardService>().getStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null || _stats == null) {
      return ErrorView(message: _error ?? 'Erro ao carregar.', onRetry: _load);
    }

    final stats = _stats!;
    final indicators = [
      ('Pessoas', stats.totalPessoas),
      ('Membros', stats.totalMembros),
      ('Voluntários', stats.totalVoluntarios),
      ('Líderes', stats.totalLideres),
    ];
    final jornada = [
      ('Novos visitantes', stats.jornada.novosVisitantes),
      ('Aceitaram Jesus', stats.jornada.aceitaramJesus),
      ('Batizados', stats.jornada.batizados),
      ('Trilha da Base', stats.jornada.trilhaBase),
      ('Novos membros', stats.jornada.novosMembros),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Dashboard',
          description: 'Visão operacional para líderes, pastores e administradores.',
          actions: const [ExportMenu(recurso: ExportRecurso.dashboard)],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, value) in indicators)
              SizedBox(
                width: (MediaQuery.sizeOf(context).width - 48) / 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          '$value',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${stats.escalasPendentes} escalas pendentes · ${stats.visitantesRecentes} visitantes recentes',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jornada', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final (label, value) in jornada)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label),
                        Text('$value', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Próximas escalas', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (stats.proximasEscalas.isEmpty)
                  Text('Nenhuma escala próxima.', style: Theme.of(context).textTheme.bodySmall)
                else
                  for (final escala in stats.proximasEscalas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            escala.ministerio,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${formatDate(escala.data)} · ${escala.horario}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${escala.confirmados}/${escala.totalVoluntarios} confirmados · ${escala.pendentes} pendentes',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

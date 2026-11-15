import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/dashboard_service.dart';
import '../../utils/format.dart';
import '../../theme/app_typography.dart';
import '../../theme/brand_colors.dart';
import '../../widgets/brand/brand.dart';
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
  bool _semAcesso = false;
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
      if (mounted) {
        setState(() {
          _stats = stats;
          _semAcesso = stats == null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_semAcesso) return _boasVindas(context);
    if (_error != null || _stats == null) {
      return ErrorView(message: _error ?? 'Erro ao carregar.', onRetry: _load);
    }

    final stats = _stats!;
    final indicators = [
      ('Pessoas', stats.totalPessoas, Icons.groups_outlined),
      ('Membros', stats.totalMembros, Icons.badge_outlined),
      (
        'Voluntários',
        stats.totalVoluntarios,
        Icons.volunteer_activism_outlined,
      ),
      ('Líderes', stats.totalLideres, Icons.workspace_premium_outlined),
    ];
    final indicadoresJornada = stats.jornada;
    final jornada = indicadoresJornada == null
        ? null
        : [
            ('Novos visitantes', indicadoresJornada.novosVisitantes),
            ('Aceitaram Jesus', indicadoresJornada.aceitaramJesus),
            ('Batizados', indicadoresJornada.batizados),
            ('Trilha da Base', indicadoresJornada.trilhaBase),
            ('Novos membros', indicadoresJornada.novosMembros),
          ];
    final proximasEscalas = stats.proximasEscalas;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _saudacao(context),
        PageHeader(
          description:
              'Visão operacional para líderes, pastores e administradores.',
          actions: const [ExportMenu(recurso: ExportRecurso.dashboard)],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final colunas = constraints.maxWidth >= 600 ? 4 : 2;
            final largura =
                (constraints.maxWidth - gap * (colunas - 1)) / colunas;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (label, value, icon) in indicators)
                  SizedBox(
                    width: largura,
                    child: StatTile(label: label, value: '$value', icon: icon),
                  ),
              ],
            );
          },
        ),
        if (stats.escalasPendentes != null &&
            stats.visitantesRecentes != null) ...[
          const SizedBox(height: 12),
          Text(
            '${stats.escalasPendentes} escalas pendentes · ${stats.visitantesRecentes} visitantes recentes',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (jornada != null) ...[
          const SizedBox(height: 16),
          BrandCard(
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
                        Text(
                          '$value',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (proximasEscalas != null) ...[
          const SizedBox(height: 16),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próximas escalas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (proximasEscalas.isEmpty)
                  Text(
                    'Nenhuma escala próxima.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  for (final escala in proximasEscalas)
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
        ],
      ],
    );
  }

  Widget _saudacao(BuildContext context) {
    final nome = context.read<AuthProvider>().user?.nome ?? '';
    final igreja = context.watch<IgrejaContext>().selected?.nome;
    final brand = context.brand;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (igreja != null) ...[
            Text(
              igreja.toUpperCase(),
              style: AppTypography.eyebrow.copyWith(color: brand.textSecondary),
            ),
            const SizedBox(height: 4),
          ],
          BrandHeadline(
            saudacao(DateTime.now(), nome),
            style: AppTypography.hero.copyWith(color: brand.textPrimary),
            compactSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _boasVindas(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _saudacao(context),
        const PageHeader(
          description:
              'Use o menu para acessar suas escalas e sua disponibilidade.',
        ),
      ],
    );
  }
}

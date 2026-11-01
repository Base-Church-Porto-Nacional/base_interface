import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../navigation/section_tabs_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/culto_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_search.dart';

class CultosMesScreen extends StatefulWidget {
  const CultosMesScreen({super.key, this.competencia});

  final String? competencia;

  @override
  State<CultosMesScreen> createState() => _CultosMesScreenState();
}

class _CultosMesScreenState extends State<CultosMesScreen> {
  late String _competencia;
  List<Culto> _cultos = [];
  bool _loading = true;
  bool _generating = false;
  String? _error;
  String? _loadedFor;

  String get _proximoMes {
    final hoje = DateTime.now();
    return competenciaFrom(DateTime(hoje.year, hoje.month + 1, 1));
  }

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _competencia = widget.competencia ??
        (competenciaFrom(hoje));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<CultoService>().list(
            igrejaId: igrejaId,
            competencia: _competencia,
          );
      if (mounted) setState(() => _cultos = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _shiftMonth(int delta) {
    final parts = _competencia.split('-');
    if (parts.length != 2) return;
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    _competencia = competenciaFrom(DateTime(year, month + delta, 1));
    _load();
  }

  Future<void> _gerar() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    if (igrejaId == null) return;
    setState(() => _generating = true);
    try {
      final msg = await context.read<CultoService>().gerarMes(
            _competencia,
            igrejaId: igrejaId,
          );
      if (mounted) showSnack(context, msg);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final igrejaId = context.watch<IgrejaContext>().selectedIgrejaId;
    if (igrejaId != _loadedFor) {
      _loadedFor = igrejaId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    final user = context.watch<AuthProvider>().user;
    final canManage = isPastorOuAdmin(user);
    final sugereGerar =
        canManage && _cultos.isEmpty && _competencia == _proximoMes;

    final byDate = <String, List<Culto>>{};
    for (final c in _cultos) {
      byDate.putIfAbsent(c.data, () => []).add(c);
    }
    final dates = byDate.keys.toList()..sort();

    return Column(
      children: [
        const SectionTabs(
          currentPath: '/cultos/mes',
          tabs: cultosMesTabs,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageHeader(
                title: 'Cultos — ${formatCompetencia(_competencia)}',
                description:
                    'Cultos do mês por data. A configuração abre até 8 dias antes do culto.',
                actions: [
                  IconButton(
                    tooltip: 'Mês anterior',
                    onPressed: _loading ? null : () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  TextButton(
                    onPressed: () => _shiftMonth(1),
                    child: Text(formatCompetencia(_competencia)),
                  ),
                  IconButton(
                    tooltip: 'Próximo mês',
                    onPressed: _loading ? null : () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  if (canManage)
                    FilledButton(
                      onPressed: _generating ? null : _gerar,
                      child: const Text('Gerar cultos'),
                    ),
                ],
              ),
              if (sugereGerar)
                Card(
                  color: AppColors.successBg,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'O próximo mês ainda não tem cultos. Rode a automação para gerar.',
                            style: const TextStyle(color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_loading)
                const LoadingView()
              else if (_error != null)
                ErrorView(message: _error!, onRetry: _load)
              else if (_cultos.isEmpty)
                const EmptyView(message: 'Nenhum culto neste mês.')
              else
                ...dates.map(
                  (data) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, top: 8),
                          child: Text(
                            formatDate(data),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        for (final c in byDate[data]!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: MobileListTile(
                              title: c.titulo,
                              subtitle: [
                                c.categoriaCultoTitulo,
                                '${formatHora(c.horaInicio)}–${formatHora(c.horaFim)}',
                                c.pregadorNome ?? 'Sem pregador',
                              ].join(' · '),
                              trailing: StatusBadge(
                                label: cultoStatusLabel(c.status).toUpperCase(),
                                success: c.status == CultoStatus.realizado,
                              ),
                              actions: [
                                if (c.janelaConfiguracaoAberta)
                                  _tag('Janela aberta'),
                                if (c.temRelatorio) _tag('Relatório'),
                              ],
                              onTap: () => context.push('/cultos/culto/${c.id}'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}
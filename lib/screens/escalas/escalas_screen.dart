import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/escala_service.dart';
import '../../services/ministerio_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_search.dart';

class EscalasScreen extends StatefulWidget {
  const EscalasScreen({super.key});

  @override
  State<EscalasScreen> createState() => _EscalasScreenState();
}

class _EscalasScreenState extends State<EscalasScreen> {
  List<Escala> _items = [];
  List<Ministerio> _ministerios = [];
  bool _loading = true;
  String? _error;
  String? _loadedFor;
  late String _competencia;

  @override
  void initState() {
    super.initState();
    _competencia = competenciaFrom(DateTime(2026, 8));
  }

  Future<void> _load() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = context.read<EscalaService>();
      final minService = context.read<MinisterioService>();
      final results = await Future.wait([
        service.list(igrejaId: igrejaId, competencia: _competencia),
        minService.list(igrejaId: igrejaId),
      ]);
      if (mounted) {
        setState(() {
          _items = results[0] as List<Escala>;
          _ministerios = results[1] as List<Ministerio>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCompetencia() async {
    final parts = _competencia.split('-');
    var year = int.tryParse(parts[0]) ?? 2026;
    var month = int.tryParse(parts[1]) ?? 8;
    final picked = await showDialog<(int, int)>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
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
                        for (var y = 2025; y <= 2028; y++)
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, (year, month)),
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
    if (picked == null) return;
    setState(() => _competencia = competenciaFrom(DateTime(picked.$1, picked.$2)));
    _load();
  }

  bool _podeEditar(AuthUser? user, Escala e) {
    if (e.status == EscalaStatus.finalizada) return false;
    return podeGerirEscalas(user);
  }

  Future<void> _editar(Escala e) async {
    if (e.status == EscalaStatus.sugerida) {
      try {
        await context.read<EscalaService>().updateStatus(e.id, EscalaStatus.editando);
        _load();
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
          return;
        }
      }
    }
    if (mounted) {
      context.push('/voluntariado/escalas/${e.id}/editar');
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
    final canCreateAny = EscalaTipo.values.any(
      (t) => podeCriarTipoEscala(
        user: user,
        tipo: t,
        ministerios: _ministerios,
        escalas: _items,
        competencia: _competencia,
        igrejaId: igrejaId ?? '',
      ),
    );

    return Column(
      children: [
        const SectionTabs(
          currentPath: '/voluntariado/escalas',
          tabs: [
            ('/voluntariado/voluntarios', 'Voluntários'),
            ('/voluntariado/escalas', 'Escalas'),
            ('/voluntariado/ministerios', 'Ministérios'),
            ('/voluntariado/relatorios', 'Relatórios'),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageHeader(
                title: 'Escalas',
                description: 'Escalas mensais por igreja. Sugeridas pela automação do dia 20.',
                actions: [
                  OutlinedButton(
                    onPressed: _pickCompetencia,
                    child: Text(formatCompetencia(_competencia)),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(
                      '/voluntariado/escalas/visao-mensal?competencia=$_competencia',
                    ),
                    child: const Text('Visão mensal'),
                  ),
                  if (canCreateAny)
                    FilledButton(
                      onPressed: () => context.push(
                        '/voluntariado/escalas/nova?competencia=$_competencia',
                      ),
                      child: const Text('Nova escala'),
                    ),
                ],
              ),
              if (_loading)
                const LoadingView()
              else if (_error != null)
                ErrorView(message: _error!, onRetry: _load)
              else if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Nenhuma escala nesta competência.')),
                )
              else
                ..._items.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MobileListTile(
                      title: e.titulo,
                      subtitle: [
                        escalaTipoLabel(e.tipo),
                        if (e.ministerioNome != null) e.ministerioNome!,
                        formatCompetencia(e.competencia),
                      ].join(' · '),
                      trailing: StatusBadge(
                        label: escalaStatusLabel(e.status).toUpperCase(),
                        success: e.status == EscalaStatus.finalizada,
                      ),
                      actions: [
                        if (e.geraAuto())
                          const StatusBadge(
                            label: 'RECOMENDADA PELA AUTOMAÇÃO',
                            success: true,
                          ),
                        if (_podeEditar(user, e))
                          TextButton.icon(
                            onPressed: () => _editar(e),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Editar'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                      onTap: () => context.push('/voluntariado/escalas/${e.id}'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../navigation/section_tabs_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/escala_service.dart';
import '../../services/ministerio_service.dart';
import '../../theme/brand_colors.dart';
import '../../utils/format.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';
import '../../widgets/competencia_picker.dart';
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
    _competencia = competenciaFrom(DateTime.now());
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
    final picked = await pickCompetencia(context, _competencia);
    if (picked == null || !mounted) return;
    setState(() => _competencia = picked);
    _load();
  }

  Future<void> _editar(Escala e) async {
    if (e.status == EscalaStatus.sugerida) {
      try {
        await context.read<EscalaService>().updateStatus(e.id, EscalaStatus.editando);
        _load();
      } catch (err) {
        if (mounted) {
          showSnack(context, err);
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
          tabs: voluntariadoTabs,
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
                const EmptyView(message: 'Nenhuma escala nesta competência.')
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
                        if (podeEditarEscala(user, e))
                          TextButton.icon(
                            onPressed: () => _editar(e),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Editar'),
                            style: TextButton.styleFrom(
                              foregroundColor: context.brand.textPrimary,
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
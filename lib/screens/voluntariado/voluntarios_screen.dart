import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../navigation/section_tabs_config.dart';
import '../../providers/igreja_context.dart';
import '../../services/base_ministerial_service.dart';
import '../../services/export_service.dart';
import '../../services/ministerio_service.dart';
import '../../services/pessoa_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/export_menu.dart';
import '../../widgets/filter_search.dart';

enum _EquipeFiltro { todos, lideres, gestores, voluntarios }

class VoluntariosScreen extends StatefulWidget {
  const VoluntariosScreen({super.key});

  @override
  State<VoluntariosScreen> createState() => _VoluntariosScreenState();
}

class _VoluntariosScreenState extends State<VoluntariosScreen> {
  List<Pessoa> _pessoas = [];
  Set<String> _gestorIds = {};
  _EquipeFiltro _filtro = _EquipeFiltro.todos;
  String _search = '';
  bool _loading = true;
  String? _error;
  String? _loadedFor;

  Future<void> _load() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    final pessoaService = context.read<PessoaService>();
    final ministerioService = context.read<MinisterioService>();
    final baseMinisterialService = context.read<BaseMinisterialService>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pessoas = await pessoaService.list(
        filtro: 'TODOS',
        search: _search,
        size: 100,
        igrejaId: igrejaId,
      );
      final ministerios = await ministerioService.list(igrejaId: igrejaId);
      final bases = await baseMinisterialService.list(igrejaId: igrejaId);
      final gestorIds = <String>{
        for (final m in ministerios)
          if (m.coordenadorPessoaId != null) m.coordenadorPessoaId!,
        for (final b in bases)
          if (b.coordenadorPessoaId != null) b.coordenadorPessoaId!,
      };
      if (mounted) {
        setState(() {
          _pessoas = pessoas.content;
          _gestorIds = gestorIds;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Pessoa> get _filtered {
    return _pessoas.where((p) {
      final isLider = p.tipos.contains(PessoaTipo.lider);
      final isGestor = _gestorIds.contains(p.id);
      final isVoluntario = p.tipos.contains(PessoaTipo.voluntario);
      switch (_filtro) {
        case _EquipeFiltro.todos:
          return isLider || isGestor || isVoluntario;
        case _EquipeFiltro.lideres:
          return isLider;
        case _EquipeFiltro.gestores:
          return isGestor;
        case _EquipeFiltro.voluntarios:
          return isVoluntario;
      }
    }).toList();
  }

  String _papelDe(Pessoa p) {
    final papeis = <String>[];
    if (p.tipos.contains(PessoaTipo.lider)) papeis.add('Líder');
    if (_gestorIds.contains(p.id)) papeis.add('Gestor');
    if (p.tipos.contains(PessoaTipo.voluntario)) papeis.add('Voluntário');
    return papeis.isEmpty ? '—' : papeis.join(' · ');
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
    final items = _filtered;

    return Column(
      children: [
        const SectionTabs(
          currentPath: '/voluntariado/voluntarios',
          tabs: voluntariadoTabs,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PageHeader(
                title: 'Voluntários',
                description: 'Líderes, gestores e voluntários da igreja.',
                actions: [ExportMenu(recurso: ExportRecurso.lideres)],
              ),
              SearchField(
                hint: 'Buscar por nome',
                onChanged: (v) {
                  _search = v;
                  _load();
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in _EquipeFiltro.values)
                    ChoiceChip(
                      label: Text(_filtroLabel(f)),
                      selected: _filtro == f,
                      onSelected: (_) => setState(() => _filtro = f),
                      selectedColor: AppColors.black,
                      labelStyle: TextStyle(
                        color: _filtro == f ? AppColors.white : AppColors.black,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const LoadingView()
              else if (_error != null)
                ErrorView(message: _error!, onRetry: _load)
              else if (items.isEmpty)
                const EmptyView(message: 'Ninguém encontrado.')
              else
                ...items.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MobileListTile(
                      title: p.nome,
                      subtitle: '${_papelDe(p)} · ${p.ministerios.join(', ')}',
                      trailing: StatusBadge(
                        label: pessoaStatusLabel(p.status),
                        success: p.status == PessoaStatus.ativo,
                      ),
                      onTap: () => context.push('/membros/pessoa/${p.id}'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _filtroLabel(_EquipeFiltro f) {
    switch (f) {
      case _EquipeFiltro.todos:
        return 'Todos';
      case _EquipeFiltro.lideres:
        return 'Líderes';
      case _EquipeFiltro.gestores:
        return 'Gestores';
      case _EquipeFiltro.voluntarios:
        return 'Voluntários';
    }
  }
}

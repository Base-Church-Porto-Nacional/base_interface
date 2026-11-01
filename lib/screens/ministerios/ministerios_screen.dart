import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/base_ministerial_service.dart';
import '../../services/ministerio_service.dart';
import '../../services/pessoa_service.dart';
import '../../utils/permissions.dart';
import '../../utils/route_access.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_search.dart';
import '../../widgets/form_dialogs.dart';

class MinisteriosScreen extends StatefulWidget {
  const MinisteriosScreen({super.key});

  @override
  State<MinisteriosScreen> createState() => _MinisteriosScreenState();
}

class _MinisteriosScreenState extends State<MinisteriosScreen> {
  List<Ministerio> _ministerios = [];
  List<BaseMinisterial> _bases = [];
  String _search = '';
  bool _loading = true;
  String? _error;
  String? _loadedFor;

  Future<void> _load() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    final ministerioService = context.read<MinisterioService>();
    final baseMinisterialService = context.read<BaseMinisterialService>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ministerios = await ministerioService.list(igrejaId: igrejaId);
      final bases = await baseMinisterialService.list(igrejaId: igrejaId);
      if (mounted) {
        setState(() {
          _ministerios = ministerios;
          _bases = bases;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Ministerio> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _ministerios;
    return _ministerios.where((m) => m.nome.toLowerCase().contains(q)).toList();
  }

  Future<void> _openForm([Ministerio? editing]) async {
    if (editing == null && !canCreateMinisterio(context.read<AuthProvider>().user)) {
      return;
    }
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    final pessoas = await context.read<PessoaService>().list(size: 100, igrejaId: igrejaId);
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => MinisterioFormDialog(
        title: editing == null ? 'Novo ministério' : 'Editar ministério',
        initialNome: editing?.nome ?? '',
        initialDescricao: editing?.descricao ?? '',
        initialAtivo: editing?.ativo ?? true,
        initialTipo: editing?.tipo ?? MinisterioTipo.geral,
        initialLiderId: editing?.liderPessoaId,
        initialCoordenadorId: editing?.coordenadorPessoaId,
        initialBaseMinisterialId: editing?.baseMinisterialId,
        pessoas: pessoas.content,
        bases: _bases,
      ),
    );
    if (result == null || !mounted) return;

    try {
      final service = context.read<MinisterioService>();
      if (editing == null) {
        await service.create(
          nome: result['nome'] as String,
          descricao: result['descricao'] as String?,
          igrejaId: igrejaId ?? '',
          tipo: result['tipo'] as MinisterioTipo,
          liderPessoaId: result['liderPessoaId'] as String?,
          liderNome: result['liderNome'] as String?,
          coordenadorPessoaId: result['coordenadorPessoaId'] as String?,
          coordenadorNome: result['coordenadorNome'] as String?,
          baseMinisterialId: result['baseMinisterialId'] as String?,
          baseMinisterialNome: result['baseMinisterialNome'] as String?,
        );
      } else {
        await service.update(
          editing.id,
          nome: result['nome'] as String,
          descricao: result['descricao'] as String?,
          ativo: result['ativo'] as bool,
          tipo: result['tipo'] as MinisterioTipo,
          liderPessoaId: result['liderPessoaId'] as String?,
          liderNome: result['liderNome'] as String?,
          coordenadorPessoaId: result['coordenadorPessoaId'] as String?,
          coordenadorNome: result['coordenadorNome'] as String?,
          baseMinisterialId: result['baseMinisterialId'] as String?,
          baseMinisterialNome: result['baseMinisterialNome'] as String?,
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _openBaseForm([BaseMinisterial? editing]) async {
    final user = context.read<AuthProvider>().user;
    if (editing == null && !canCreateBaseMinisterial(user)) return;
    if (editing != null && !podeGerenciarBaseMinisterial(user, editing)) return;
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    final pessoas = await context.read<PessoaService>().list(size: 100, igrejaId: igrejaId);
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => BaseMinisterialFormDialog(
        title: editing == null ? 'Nova base ministerial' : 'Editar base ministerial',
        initialNome: editing?.nome ?? '',
        initialDescricao: editing?.descricao ?? '',
        initialAtivo: editing?.ativo ?? true,
        initialLiderId: editing?.liderPessoaId,
        initialCoordenadorId: editing?.coordenadorPessoaId,
        pessoas: pessoas.content,
      ),
    );
    if (result == null || !mounted) return;

    try {
      final service = context.read<BaseMinisterialService>();
      if (editing == null) {
        await service.create(
          nome: result['nome'] as String,
          descricao: result['descricao'] as String?,
          igrejaId: igrejaId ?? '',
          liderPessoaId: result['liderPessoaId'] as String?,
          liderNome: result['liderNome'] as String?,
          coordenadorPessoaId: result['coordenadorPessoaId'] as String?,
          coordenadorNome: result['coordenadorNome'] as String?,
        );
      } else {
        await service.update(
          editing.id,
          nome: result['nome'] as String,
          descricao: result['descricao'] as String?,
          ativo: result['ativo'] as bool,
          liderPessoaId: result['liderPessoaId'] as String?,
          liderNome: result['liderNome'] as String?,
          coordenadorPessoaId: result['coordenadorPessoaId'] as String?,
          coordenadorNome: result['coordenadorNome'] as String?,
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
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
    final podeCriarMinisterio = canCreateMinisterio(user);
    final podeCriarBase = canCreateBaseMinisterial(user);
    final items = _filtered;

    return Column(
      children: [
        const SectionTabs(
          currentPath: '/voluntariado/ministerios',
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
                title: 'Ministérios',
                description: 'Bases ministeriais, ministérios e seus serviços.',
                actions: [
                  if (podeCriarBase)
                    OutlinedButton(
                      onPressed: () => _openBaseForm(),
                      child: const Text('Nova base'),
                    ),
                  if (podeCriarMinisterio)
                    FilledButton(
                      onPressed: () => _openForm(),
                      child: const Text('Novo ministério'),
                    ),
                ],
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar ministério',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const LoadingView()
              else if (_error != null)
                ErrorView(message: _error!, onRetry: _load)
              else if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Nenhum ministério encontrado.')),
                )
              else
                ..._buildGroups(items, user, podeCriarMinisterio),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroups(List<Ministerio> items, AuthUser? user, bool podeCriarMinisterio) {
    final widgets = <Widget>[];
    final semBase = <Ministerio>[];

    for (final base in _bases) {
      final doGrupo = items.where((m) => m.baseMinisterialId == base.id).toList();
      if (doGrupo.isEmpty) continue;
      widgets.add(_buildBaseGroup(base, doGrupo, user, podeCriarMinisterio));
    }
    final baseIds = _bases.map((b) => b.id).toSet();
    semBase.addAll(items.where((m) => m.baseMinisterialId == null || !baseIds.contains(m.baseMinisterialId)));
    if (semBase.isNotEmpty) {
      widgets.add(_buildBaseGroup(null, semBase, user, podeCriarMinisterio));
    }
    return widgets;
  }

  Widget _buildBaseGroup(
    BaseMinisterial? base,
    List<Ministerio> ministerios,
    AuthUser? user,
    bool podeCriarMinisterio,
  ) {
    final podeGerenciarBase = base != null && podeGerenciarBaseMinisterial(user, base);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(base?.nome ?? 'Outros'),
          subtitle: Text(
            base != null
                ? 'Líder: ${base.liderNome} · Coord.: ${base.coordenadorNome ?? '—'}'
                : 'Ministérios sem base ministerial definida',
          ),
          trailing: podeGerenciarBase
              ? IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar base',
                  onPressed: () => _openBaseForm(base),
                )
              : null,
          children: [
            for (final m in ministerios)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: MobileListTile(
                  title: m.nome,
                  subtitle:
                      'Líder: ${m.liderNome} · Coord.: ${m.coordenadorNome ?? '—'} · ${ministerioTipoLabel(m.tipo)}',
                  trailing: StatusBadge(
                    label: m.ativo ? 'ATIVO' : 'INATIVO',
                    success: m.ativo,
                  ),
                  onTap: () => context.push('/voluntariado/ministerios/${m.id}'),
                  actions: [
                    if (podeCriarMinisterio)
                      OutlinedButton(
                        onPressed: () => _openForm(m),
                        child: const Text('Editar'),
                      ),
                    OutlinedButton(
                      onPressed: () => context.push('/voluntariado/ministerios/${m.id}'),
                      child: const Text('Abrir'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

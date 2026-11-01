import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/pessoa_service.dart';
import '../../services/small_group_service.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';
import '../../widgets/form_dialogs.dart';

class SmallGroupsScreen extends StatefulWidget {
  const SmallGroupsScreen({super.key});

  @override
  State<SmallGroupsScreen> createState() => _SmallGroupsScreenState();
}

class _SmallGroupsScreenState extends State<SmallGroupsScreen> {
  List<SmallGroup> _items = [];
  String _search = '';
  bool _loading = true;
  String? _error;
  String? _loadedFor;

  Future<void> _load() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<SmallGroupService>().list(igrejaId: igrejaId);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<SmallGroup> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items
        .where(
          (g) =>
              g.nome.toLowerCase().contains(q) ||
              g.liderNome.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _openForm([SmallGroup? editing]) async {
    if (editing == null && !canCreateSmallGroup(context.read<AuthProvider>().user)) {
      return;
    }
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    final pessoas = await context.read<PessoaService>().list(size: 100, igrejaId: igrejaId);
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => SmallGroupFormDialog(
        title: editing == null ? 'Novo pequeno grupo' : 'Editar pequeno grupo',
        initialNome: editing?.nome ?? '',
        initialHorario: editing?.horario ?? '',
        initialAtivo: editing?.ativo ?? true,
        initialDiaSemana: editing?.diaSemana ?? DiaSemana.domingo,
        initialLiderId: editing?.liderPessoaId,
        initialNota: editing?.nota ?? 0,
        pessoas: pessoas.content,
      ),
    );
    if (result == null || !mounted) return;

    try {
      final service = context.read<SmallGroupService>();
      if (editing == null) {
        await service.create(
          nome: result['nome'] as String,
          igrejaId: igrejaId ?? '',
          diaSemana: result['diaSemana'] as DiaSemana,
          horario: result['horario'] as String?,
          liderPessoaId: result['liderPessoaId'] as String,
          nota: result['nota'] as int,
          ativo: result['ativo'] as bool,
        );
      } else {
        await service.update(
          editing.id,
          nome: result['nome'] as String,
          diaSemana: result['diaSemana'] as DiaSemana,
          horario: result['horario'] as String?,
          liderPessoaId: result['liderPessoaId'] as String,
          nota: result['nota'] as int,
          ativo: result['ativo'] as bool,
        );
      }
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e);
    }
  }

  Future<void> _delete(SmallGroup group) async {
    final confirm = await confirmDialog(
      context,
      title: 'Apagar pequeno grupo',
      message: 'Apagar "${group.nome}" e todos os relatórios dele?',
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!confirm || !mounted) return;
    try {
      await context.read<SmallGroupService>().delete(group.id);
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e);
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
    final podeCriar = canCreateSmallGroup(user);
    final items = _filtered;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Pequenos grupos',
          description: 'Grupos semanais, cada um com seu líder e sua nota.',
          actions: [
            if (podeCriar)
              FilledButton(
                onPressed: () => _openForm(),
                child: const Text('Novo grupo'),
              ),
          ],
        ),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar grupo ou líder',
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
          const EmptyView(message: 'Nenhum pequeno grupo encontrado.')
        else
          ...items.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MobileListTile(
                title: g.nome,
                subtitle:
                    'Líder: ${g.liderNome} · ${diaSemanaLabel(g.diaSemana)} · ${g.horario ?? '—'}',
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(
                      label: g.ativo ? 'ATIVA' : 'INATIVA',
                      success: g.ativo,
                    ),
                    const SizedBox(height: 4),
                    StatusBadge(label: g.notaLabel),
                  ],
                ),
                onTap: () => context.push('/pequenos-grupos/${g.id}'),
                actions: [
                  if (podeGerenciarSmallGroup(user, g)) ...[
                    OutlinedButton(
                      onPressed: () => _openForm(g),
                      child: const Text('Editar'),
                    ),
                    OutlinedButton(
                      onPressed: () => _delete(g),
                      child: const Text('Apagar'),
                    ),
                  ],
                  OutlinedButton(
                    onPressed: () => context.push('/pequenos-grupos/${g.id}'),
                    child: const Text('Abrir'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
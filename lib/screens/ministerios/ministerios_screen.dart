import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/ministerio_service.dart';
import '../../services/pessoa_service.dart';
import '../../utils/route_access.dart';
import '../../widgets/common.dart';
import '../../widgets/form_dialogs.dart';

class MinisteriosScreen extends StatefulWidget {
  const MinisteriosScreen({super.key});

  @override
  State<MinisteriosScreen> createState() => _MinisteriosScreenState();
}

class _MinisteriosScreenState extends State<MinisteriosScreen> {
  List<Ministerio> _items = [];
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
      final items = await context.read<MinisterioService>().list(igrejaId: igrejaId);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Ministerio> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((m) => m.nome.toLowerCase().contains(q)).toList();
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
        pessoas: pessoas.content,
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
    final podeCriar = canCreateMinisterio(context.watch<AuthProvider>().user);
    final items = _filtered;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Ministérios',
          description: 'Áreas de serviço e liderança.',
          actions: [
            if (podeCriar)
              FilledButton(onPressed: () => _openForm(), child: const Text('Novo')),
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
          ...items.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                  if (podeCriar)
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
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/ministerio_service.dart';
import '../../services/pessoa_service.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';
import '../../widgets/form_dialogs.dart';

class MinisterioDetailScreen extends StatefulWidget {
  const MinisterioDetailScreen({super.key, required this.ministerioId});

  final String ministerioId;

  @override
  State<MinisterioDetailScreen> createState() => _MinisterioDetailScreenState();
}

class _MinisterioDetailScreenState extends State<MinisterioDetailScreen> {
  Ministerio? _ministerio;
  bool _loading = true;
  String? _error;
  late final TextEditingController _anotacoes;
  late final TextEditingController _ordem;

  @override
  void initState() {
    super.initState();
    _anotacoes = TextEditingController();
    _ordem = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _anotacoes.dispose();
    _ordem.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final m = await context.read<MinisterioService>().getById(widget.ministerioId);
      if (mounted) {
        _anotacoes.text = m.anotacoes ?? '';
        _ordem.text = m.ordem ?? '';
        setState(() => _ministerio = m);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final m = _ministerio;
    if (m == null) return;
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    final pessoas = await context.read<PessoaService>().listarTodas(igrejaId: igrejaId);
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => MinisterioFormDialog(
        title: 'Editar ministério',
        initialNome: m.nome,
        initialDescricao: m.descricao ?? '',
        initialAtivo: m.ativo,
        initialTipo: m.tipo,
        initialLiderId: m.liderPessoaId,
        initialCoordenadorId: m.coordenadorPessoaId,
        pessoas: pessoas,
      ),
    );
    if (result == null || !mounted) return;

    try {
      final updated = await context.read<MinisterioService>().update(
            widget.ministerioId,
            nome: result['nome'] as String,
            descricao: result['descricao'] as String?,
            ativo: result['ativo'] as bool,
            tipo: result['tipo'] as MinisterioTipo,
            liderPessoaId: result['liderPessoaId'] as String?,
            liderNome: result['liderNome'] as String?,
            coordenadorPessoaId: result['coordenadorPessoaId'] as String?,
            coordenadorNome: result['coordenadorNome'] as String?,
            anotacoes: m.anotacoes,
            ordem: m.ordem,
          );
      if (mounted) setState(() => _ministerio = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _adicionarPessoaExistente() async {
    final m = _ministerio;
    if (m == null) return;
    final pessoaService = context.read<PessoaService>();
    final ministerioService = context.read<MinisterioService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AdicionarPessoaExistenteDialog(
        ministerio: m,
        buscar: pessoaService.buscarPorNome,
        vincular: (pessoaId, servicoId) =>
            ministerioService.vincularPessoa(pessoaId: pessoaId, servicoId: servicoId),
      ),
    );
    if (ok != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pessoa adicionada ao ministério.')),
    );
    _load();
  }

  Future<void> _saveNotas() async {
    final m = _ministerio;
    if (m == null) return;
    try {
      final updated = await context.read<MinisterioService>().update(
            widget.ministerioId,
            nome: m.nome,
            descricao: m.descricao,
            ativo: m.ativo,
            tipo: m.tipo,
            liderPessoaId: m.liderPessoaId,
            liderNome: m.liderNome,
            coordenadorPessoaId: m.coordenadorPessoaId,
            coordenadorNome: m.coordenadorNome,
            anotacoes: _anotacoes.text.trim(),
            ordem: _ordem.text.trim(),
          );
      if (mounted) {
        setState(() => _ministerio = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anotações e ordem salvas.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null || _ministerio == null) {
      return ErrorView(message: _error ?? 'Ministério não encontrado.', onRetry: _load);
    }

    final m = _ministerio!;
    final user = context.watch<AuthProvider>().user;
    final canManage = podeGerenciarMinisterio(user, m);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: m.nome,
          description: m.descricao ?? 'Sem descrição.',
          actions: [
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Voltar')),
            if (canManage) OutlinedButton(onPressed: _edit, child: const Text('Editar')),
            if (canManage)
              OutlinedButton(
                onPressed: _adicionarPessoaExistente,
                child: const Text('Adicionar pessoa existente'),
              ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Tipo', ministerioTipoLabel(m.tipo)),
                _row('Líder espiritual', m.liderNome),
                _row('Coordenador', m.coordenadorNome ?? '—'),
                _row('Voluntários', '${m.totalVoluntarios}'),
                _row('Serviços', '${m.totalServicos}'),
                _row('Status', m.ativo ? 'Ativo' : 'Inativo'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Serviços', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final s in m.servicos)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MobileListTile(
              title: s.nome,
              subtitle: s.ficcao ? 'Serviço ficção (não entra na escala de voluntários)' : null,
              trailing: StatusBadge(
                label: s.ficcao ? 'FICÇÃO' : (s.ativo ? 'ATIVO' : 'INATIVO'),
                success: !s.ficcao && s.ativo,
              ),
            ),
          ),
        if (canManage) ...[
          const SizedBox(height: 8),
          Text('Anotações e ordem', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _anotacoes,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Anotações'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ordem,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Ordem'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(onPressed: _saveNotas, child: const Text('Salvar')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

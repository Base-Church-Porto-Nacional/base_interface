import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/escala_service.dart';
import '../../services/ministerio_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';

class EscalaEditScreen extends StatefulWidget {
  const EscalaEditScreen({super.key, required this.escalaId});

  final String escalaId;

  @override
  State<EscalaEditScreen> createState() => _EscalaEditScreenState();
}

class _EscalaEditScreenState extends State<EscalaEditScreen> {
  Escala? _escala;
  List<Ministerio> _ministerios = [];
  String? _data;
  bool _loading = true;
  bool _nestedLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = context.read<EscalaService>();
      final results = await Future.wait([
        service.getById(widget.escalaId),
        context.read<MinisterioService>().list(igrejaId: null),
      ]);
      final escala = results[0] as Escala;
      final ministerios = (results[1] as List<Ministerio>)
          .where((m) => m.igrejaId == escala.igrejaId)
          .toList();
      if (!mounted) return;
      setState(() {
        _escala = escala;
        _ministerios = ministerios;
        _data ??= escala.dataEvento;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reload() async {
    try {
      final escala = await context.read<EscalaService>().getById(widget.escalaId);
      if (mounted) setState(() => _escala = escala);
    } catch (_) {}
  }

  bool _podeEditar(AuthUser? user) {
    final e = _escala;
    if (e == null || e.status == EscalaStatus.finalizada) return false;
    return podeGerirEscalas(user);
  }

  List<String> get _datasDisponiveis {
    final e = _escala;
    if (e == null) return [];
    final set = <String>{};
    if (e.dataEvento != null && e.dataEvento!.isNotEmpty) set.add(e.dataEvento!);
    for (final v in e.voluntarios) {
      if (v.data != null && v.data!.isNotEmpty) set.add(v.data!);
    }
    for (final i in e.itens) {
      if (i.data.isNotEmpty) set.add(i.data);
    }
    final parts = e.competencia.split('-');
    final y = int.tryParse(parts[0]) ?? 2026;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    for (final d in sundaysInMonth(y, m)) {
      set.add(isoDate(d));
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _alterarQuantidade(EscalaServico servico, int delta) async {
    setState(() => _nestedLoading = true);
    try {
      final nova = (servico.quantidadeNecessaria + delta).clamp(0, 99);
      if (nova == servico.quantidadeNecessaria) return;
      if (nova == 0) {
        await context.read<EscalaService>().removeServico(widget.escalaId, servico.id);
      } else {
        await context
            .read<EscalaService>()
            .updateServico(widget.escalaId, servico.id, quantidadeNecessaria: nova);
      }
      await _reload();
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _nestedLoading = false);
    }
  }

  Future<void> _adicionarServico() async {
    final escala = _escala;
    if (escala == null) return;
    final jaExistentes =
        escala.servicos.map((s) => s.servicoId).whereType<String>().toSet();
    final opcoes = <_ServicoOpcao>[];
    for (final m in _ministerios) {
      for (final s in m.servicos) {
        if (s.ficcao || jaExistentes.contains(s.id)) continue;
        opcoes.add(_ServicoOpcao(servicoId: s.id, nome: '${m.nome} · ${s.nome}'));
      }
    }
    if (opcoes.isEmpty) {
      _snack('Todos os serviços já estão nesta escala.');
      return;
    }
    var selecionado = opcoes.first;
    var quantidade = 1;
    final result = await showDialog<(_ServicoOpcao, int)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Adicionar serviço'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selecionado.servicoId,
                decoration: const InputDecoration(labelText: 'Serviço'),
                items: [
                  for (final o in opcoes)
                    DropdownMenuItem(value: o.servicoId, child: Text(o.nome)),
                ],
                onChanged: (v) {
                  for (final o in opcoes) {
                    if (o.servicoId == v) {
                      setLocal(() => selecionado = o);
                      break;
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Quantidade'),
                  IconButton(
                    onPressed: quantidade > 1
                        ? () => setLocal(() => quantidade--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(width: 24, child: Text('$quantidade', textAlign: TextAlign.center)),
                  IconButton(
                    onPressed: () => setLocal(() => quantidade++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, (selecionado, quantidade)),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _nestedLoading = true);
    try {
      await context.read<EscalaService>().addServico(
            widget.escalaId,
            servicoId: result.$1.servicoId,
            servicoNome: result.$1.nome.split(' · ').last,
            quantidadeNecessaria: result.$2,
          );
      await _reload();
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _nestedLoading = false);
    }
  }

  Future<void> _designar(EscalaServico servico) async {
    final escalas = _escala;
    if (escalas == null) return;
    setState(() => _nestedLoading = true);
    try {
      final candidatos = await context.read<EscalaService>().candidatos(
            widget.escalaId,
            servicoId: servico.servicoId,
            data: _data,
          );
      if (!mounted) return;
      await _escolherCandidato(servico, candidatos);
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _nestedLoading = false);
    }
  }

  Future<void> _escolherCandidato(
    EscalaServico servico,
    List<EscalaCandidato> candidatos,
  ) async {
    final jaDesignados =
        _escala?.voluntarios.map((v) => v.pessoaId).whereType<String>().toSet() ?? {};
    final disponiveis = candidatos
        .where((c) => c.analiseDia?.disponivel ?? true)
        .where((c) => !jaDesignados.contains(c.pessoaId))
        .toList();
    if (disponiveis.isEmpty) {
      _snack('Nenhum candidato disponível para este serviço no dia selecionado.');
      return;
    }
    final escolhido = await showDialog<EscalaCandidato>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Escolher voluntário'),
        children: [
          for (final c in disponiveis)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, c),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${c.pessoaNome} — ${c.servicosQueServe.join(', ')}'),
              ),
            ),
        ],
      ),
    );
    if (escolhido == null || !mounted) return;
    setState(() => _nestedLoading = true);
    try {
      await context.read<EscalaService>().addVoluntario(
            widget.escalaId,
            pessoaId: escolhido.pessoaId,
            servicoId: servico.servicoId ?? '',
            servicoNome: servico.servicoNome,
            data: _data,
          );
      await _reload();
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _nestedLoading = false);
    }
  }

  Future<void> _confirmar(EscalaVoluntario v, EscalaItemStatus status) async {
    setState(() => _nestedLoading = true);
    try {
      await context
          .read<EscalaService>()
          .updateVoluntarioStatus(widget.escalaId, v.id, status: status);
      await _reload();
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _nestedLoading = false);
    }
  }

  Future<void> _aprovarEmNome(EscalaVoluntario v) async {
    setState(() => _nestedLoading = true);
    try {
      await context.read<EscalaService>().updateVoluntarioStatus(
            widget.escalaId,
            v.id,
            status: EscalaItemStatus.confirmado,
            observacoes: 'Confirmado em nome do voluntário',
            confirmadoPeloVoluntario: true,
          );
      await _reload();
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _nestedLoading = false);
    }
  }

  Future<void> _substituir(EscalaVoluntario v) async {
    setState(() => _nestedLoading = true);
    try {
      final candidatos = await context.read<EscalaService>().candidatos(
            widget.escalaId,
            servicoId: v.servicoId,
            data: _data,
          );
      if (!mounted) return;
      final filtrados = candidatos
          .where((c) => c.analiseDia?.disponivel ?? true)
          .where((c) => c.pessoaId != v.pessoaId)
          .toList();
      if (filtrados.isEmpty) {
        _snack('Nenhum substituto disponível.');
        return;
      }
      final escolhido = await showDialog<EscalaCandidato>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Substituir voluntário'),
          children: [
            for (final c in filtrados)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(c.pessoaNome),
                ),
              ),
          ],
        ),
      );
      if (escolhido == null || !mounted) return;
      await context.read<EscalaService>().updateVoluntario(
            widget.escalaId,
            v.id,
            pessoaId: escolhido.pessoaId,
            pessoaNome: escolhido.pessoaNome,
          );
      await _reload();
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _nestedLoading = false);
    }
  }

  Future<void> _removerVoluntario(EscalaVoluntario v) async {
    setState(() => _nestedLoading = true);
    try {
      await context.read<EscalaService>().removeVoluntario(widget.escalaId, v.id);
      await _reload();
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _nestedLoading = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null || _escala == null) {
      return ErrorView(message: _error ?? 'Escala não encontrada.', onRetry: _load);
    }
    final e = _escala!;
    final user = context.watch<AuthProvider>().user;
    if (!_podeEditar(user)) {
      return const ErrorView(message: 'Você não pode editar esta escala.');
    }
    final datas = _datasDisponiveis;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Editar escala',
          description: '${e.titulo} · ${escalaStatusLabel(e.status)}',
          actions: [
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Voltar')),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _data,
                  decoration: const InputDecoration(
                    labelText: 'Data de análise',
                    helperText: 'Usada para recomendar candidatos disponíveis.',
                  ),
                  items: [
                    for (final d in datas)
                      DropdownMenuItem(value: d, child: Text(formatDate(d))),
                  ],
                  onChanged: (v) => setState(() => _data = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text('Serviços necessários', style: Theme.of(context).textTheme.titleMedium),
            ),
            TextButton.icon(
              onPressed: _nestedLoading ? null : _adicionarServico,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar serviço'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (e.servicos.isEmpty)
          const Text('Nenhum serviço. Adicione os serviços necessários para a escala.')
        else
          for (final s in e.servicos) _servicoCard(context, e, s),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _servicoCard(BuildContext context, Escala e, EscalaServico servico) {
    final preenchidos = e.preenchidosDoServico(servico.servicoId);
    final designados = e.voluntariosDoServico(servico.servicoId);
    final faltam = (servico.quantidadeNecessaria - preenchidos).clamp(0, 99);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(servico.servicoNome ?? 'Serviço',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('$preenchidos de ${servico.quantidadeNecessaria} vaga(s) preenchidas'),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: servico.quantidadeNecessaria >= 2
                      ? () => _alterarQuantidade(servico, -1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Reduzir quantidade',
                ),
                IconButton(
                  onPressed: () => _alterarQuantidade(servico, 1),
                  icon: const Icon(Icons.add_circle_outline),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Aumentar quantidade',
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'remover') {
                      _alterarQuantidade(servico, -servico.quantidadeNecessaria);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'remover', child: Text('Remover serviço')),
                  ],
                ),
              ],
            ),
            if (faltam > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _nestedLoading ? null : () => _designar(servico),
                    icon: const Icon(Icons.person_add_alt, size: 18),
                    label: Text('Designar ($faltam aberta(s))'),
                  ),
                ),
              ),
            for (final v in designados)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MobileListTile(
                  title: v.pessoaNome ?? '—',
                  subtitle: '${escalaItemStatusLabel(v.status)}${v.data != null ? ' · ${formatDate(v.data!)}' : ''}',
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(
                        label: v.status.name.toUpperCase(),
                        success: v.status == EscalaItemStatus.confirmado,
                      ),
                      if (v.aprovadoPeloVoluntario) ...[
                        const SizedBox(height: 4),
                        const StatusBadge(
                          label: 'APROVADO PELO VOLUNTÁRIO',
                          success: true,
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: _nestedLoading ? null : () => _confirmar(v, EscalaItemStatus.confirmado),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Confirmar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _nestedLoading ? null : () => _substituir(v),
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('Substituir'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    PopupMenuButton<EscalaItemStatus>(
                      onSelected: (s) {
                        if (s == EscalaItemStatus.confirmado) {
                          _aprovarEmNome(v);
                        } else {
                          _confirmar(v, s);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: EscalaItemStatus.recusado, child: Text('Recusar')),
                        PopupMenuItem(value: EscalaItemStatus.pendente, child: Text('Marcar pendente')),
                        PopupMenuItem(value: EscalaItemStatus.substituido, child: Text('Marcar substituído')),
                        PopupMenuItem(value: EscalaItemStatus.confirmado, child: Text('Aprovar em nome do voluntário')),
                      ],
                      tooltip: 'Mais ações',
                    ),
                    IconButton(
                      onPressed: _nestedLoading ? null : () => _removerVoluntario(v),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.danger,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Remover designação',
                    ),
                  ],
                ),
              ),
            if (designados.isEmpty && faltam == 0)
              const Text('Serviço ainda sem designações.'),
          ],
        ),
      ),
    );
  }
}

class _ServicoOpcao {
  const _ServicoOpcao({required this.servicoId, required this.nome});

  final String servicoId;
  final String nome;
}
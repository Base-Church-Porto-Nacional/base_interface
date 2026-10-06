import 'package:flutter/material.dart';
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

class VisaoMensalScreen extends StatefulWidget {
  const VisaoMensalScreen({super.key, this.competencia});

  final String? competencia;

  @override
  State<VisaoMensalScreen> createState() => _VisaoMensalScreenState();
}

class _VisaoMensalScreenState extends State<VisaoMensalScreen> {
  late String _competencia;
  List<Ministerio> _ministerios = [];
  String? _selectedMinisterioId;
  List<VisaoMensalEscala> _visao = [];
  bool _loading = true;
  bool _loadingMinisterios = true;
  String? _error;
  String? _loadedFor;

  @override
  void initState() {
    super.initState();
    _competencia =
        widget.competencia ?? competenciaFrom(DateTime.now());
    _loadMinisterios();
  }

  Future<void> _loadMinisterios() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    setState(() {
      _loadingMinisterios = true;
      _error = null;
    });
    try {
      final user = context.read<AuthProvider>().user;
      final todos =
          await context.read<MinisterioService>().list(igrejaId: igrejaId);
      final selectables = todos.where((m) {
        if (isPastorOuAdmin(user)) return true;
        return m.liderPessoaId == user?.pessoaId ||
            m.coordenadorPessoaId == user?.pessoaId;
      }).toList();
      if (!mounted) return;
      setState(() {
        _ministerios = selectables;
        final aindaExiste = selectables.any((m) => m.id == _selectedMinisterioId);
        if (selectables.isNotEmpty && !aindaExiste) {
          _selectedMinisterioId = selectables.first.id;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingMinisterios = false);
        _load();
      }
    }
  }

  Future<void> _load() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    final user = context.read<AuthProvider>().user;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resultado = await context
          .read<EscalaService>()
          .visaoMensal(
            igrejaId: igrejaId,
            competencia: _competencia,
            ministerioId: _selectedMinisterioId,
            pessoaId: user?.pessoaId,
            administrador: isPastorOuAdmin(user),
          );
      if (mounted) setState(() => _visao = resultado);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCompetencia() async {
    final parts = _competencia.split('-');
    var year = int.tryParse(parts[0]) ?? DateTime.now().year;
    var month = int.tryParse(parts[1]) ?? DateTime.now().month;
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

  Future<void> _informarQuem(
    VisaoMensalEscala visao,
    ItemVisaoMensal item,
    ServicoVisaoMensal servico,
  ) async {
    final escalaId = visao.escalaId;
    if (escalaId == null) return;
    final candidatos = await context
        .read<EscalaService>()
        .candidatos(
          escalaId,
          servicoId: servico.servicoId,
          data: item.data,
        );
    if (!mounted) return;
    final escolhido = await showModalBottomSheet<EscalaCandidato>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CandidatosSheet(
        item: item,
        servico: servico,
        candidatos: candidatos,
      ),
    );
    if (escolhido == null || !mounted) return;

    setState(() => _loading = true);
    try {
      await context.read<EscalaService>().addVoluntario(
            escalaId,
            pessoaId: escolhido.pessoaId,
            servicoId: servico.servicoId ?? '',
            servicoNome: servico.servicoNome,
            data: item.data,
            eventoId: item.isCulto ? null : item.id,
            horario: item.isCulto ? item.horaInicio : null,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${escolhido.pessoaNome} escalado(a) em ${servico.servicoNome}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final igrejaId = context.watch<IgrejaContext>().selectedIgrejaId;
    if (igrejaId != _loadedFor) {
      _loadedFor = igrejaId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMinisterios();
      });
    }

    final visao = _visao.isNotEmpty ? _visao.first : null;

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
                title: 'Visão mensal',
                description:
                    'Todos os cultos e eventos do mês, com os serviços do ministério e quem está escalado.',
                actions: [
                  OutlinedButton(
                    onPressed: _pickCompetencia,
                    child: Text(formatCompetencia(_competencia)),
                  ),
                  if (_ministerios.length > 1)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 200),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedMinisterioId,
                        decoration: const InputDecoration(
                          labelText: 'Ministério',
                          isDense: true,
                        ),
                        items: [
                          for (final m in _ministerios)
                            DropdownMenuItem(value: m.id, child: Text(m.nome)),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedMinisterioId = v);
                          _load();
                        },
                      ),
                    ),
                ],
              ),
              if (_loadingMinisterios)
                const LoadingView()
              else if (_ministerios.isEmpty && _error == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Você não lidera/coordena nenhum ministério nesta igreja.',
                    ),
                  ),
                )
              else if (_loading)
                const LoadingView()
              else if (_error != null)
                ErrorView(message: _error!, onRetry: _load)
              else if (visao == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Nenhum dado para exibir.')),
                )
              else ..._buildConteudo(context, visao),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildConteudo(BuildContext context, VisaoMensalEscala visao) {
    final widgets = <Widget>[
      Text(
        '${visao.ministerioNome} · ${formatCompetencia(visao.competencia)}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          if (visao.escalaStatus != null)
            StatusBadge(
              label: escalaStatusLabel(visao.escalaStatus!).toUpperCase(),
              success: visao.escalaStatus == EscalaStatus.finalizada,
            ),
          if (visao.escalaId == null) ...[
            const SizedBox(width: 8),
            const StatusBadge(label: 'SEM ESCALA MENSAL'),
          ],
        ],
      ),
    ];
    if (visao.escalaId == null) {
      widgets.addAll(const [
        SizedBox(height: 8),
        Text(
          'Crie uma escala mensal do ministério para poder informar quem escala cada serviço.',
          style: TextStyle(fontSize: 13),
        ),
      ]);
    }
    widgets.add(const SizedBox(height: 12));

    if (visao.itens.isEmpty) {
      widgets.add(const Text('Nenhum culto ou evento neste mês.'));
    } else {
      for (final item in visao.itens) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ItemVisaoCard(
              item: item,
              visao: visao,
              onInformar: (servico) => _informarQuem(visao, item, servico),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

class _ItemVisaoCard extends StatelessWidget {
  const _ItemVisaoCard({
    required this.item,
    required this.visao,
    required this.onInformar,
  });

  final ItemVisaoMensal item;
  final VisaoMensalEscala visao;
  final void Function(ServicoVisaoMensal servico) onInformar;

  String get _horario {
    final inicio = formatHora(item.horaInicio);
    final fim = formatHora(item.horaFim);
    if (inicio.isEmpty) return formatDate(item.data);
    if (fim.isEmpty) return '${formatDate(item.data)} · $inicio';
    return '${formatDate(item.data)} · $inicio às $fim';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(label: item.isCulto ? 'CULTO' : 'EVENTO'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_horario, style: Theme.of(context).textTheme.bodySmall),
            if (item.localEvento != null && item.localEvento!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.localEvento!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (item.servicos.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Nenhum serviço deste ministério.'),
              )
            else
              for (final servico in item.servicos)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _ServicoVisaoLinha(
                    servico: servico,
                    podeInformar: visao.escalaId != null,
                    onInformar: () => onInformar(servico),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ServicoVisaoLinha extends StatelessWidget {
  const _ServicoVisaoLinha({
    required this.servico,
    required this.podeInformar,
    required this.onInformar,
  });

  final ServicoVisaoMensal servico;
  final bool podeInformar;
  final VoidCallback onInformar;

  @override
  Widget build(BuildContext context) {
    final vagas = servico.vagasEmAberto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                servico.servicoNome,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text('${servico.quantidadeNecessaria} vaga(s)'),
          ],
        ),
        const SizedBox(height: 4),
        if (servico.designados.isEmpty)
          Text(
            vagas > 0
                ? '$vagas vaga(s) em aberto'
                : 'Ninguém escalado.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          for (final d in servico.designados)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(d.pessoaNome, style: const TextStyle(fontSize: 13)),
                  ),
                  if (d.confirmadoPeloVoluntario)
                    const StatusBadge(label: 'APROVADO', success: true)
                  else
                    StatusBadge(label: escalaItemStatusLabel(d.status).toUpperCase()),
                ],
              ),
            ),
        if (vagas > 0 && podeInformar) ...[
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: onInformar,
            icon: const Icon(Icons.person_add_alt, size: 16),
            label: Text('Informar quem ($vagas)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ],
    );
  }
}

class _CandidatosSheet extends StatelessWidget {
  const _CandidatosSheet({
    required this.item,
    required this.servico,
    required this.candidatos,
  });

  final ItemVisaoMensal item;
  final ServicoVisaoMensal servico;
  final List<EscalaCandidato> candidatos;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escalar ${servico.servicoNome}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${item.titulo} · ${formatDate(item.data)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (candidatos.isEmpty)
              const Text('Nenhum voluntário disponível para este serviço/data.')
            else
              SizedBox(
                height: 260,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in candidatos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MobileListTile(
                          title: c.pessoaNome,
                          subtitle: c.analiseDia?.disponivel ?? true
                              ? 'Disponível'
                              : (c.analiseDia?.motivosIndisponibilidade.isNotEmpty == true
                                  ? c.analiseDia!.motivosIndisponibilidade.first
                                  : 'Indisponível'),
                          trailing: (c.analiseDia?.disponivel ?? true)
                              ? const Icon(Icons.check_circle_outline,
                                  color: AppColors.success)
                              : const Icon(Icons.cancel_outlined,
                                  color: AppColors.danger),
                          onTap: () {
                            if (c.analiseDia?.disponivel ?? true) {
                              Navigator.pop(context, c);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
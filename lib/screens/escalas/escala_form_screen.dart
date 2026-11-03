import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/cronograma_service.dart';
import '../../services/escala_service.dart';
import '../../services/ministerio_service.dart';
import '../../services/pessoa_service.dart';
import '../../utils/format.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';
import '../../widgets/seletor_pessoa.dart';

class EscalaFormScreen extends StatefulWidget {
  const EscalaFormScreen({super.key, this.competencia});

  final String? competencia;

  @override
  State<EscalaFormScreen> createState() => _EscalaFormScreenState();
}

class _EscalaFormScreenState extends State<EscalaFormScreen> {
  late int _year;
  late int _month;
  EscalaTipo _tipo = EscalaTipo.ministerio;
  String? _ministerioId;
  String? _supervisorId;
  String? _pregadorId;
  String? _eventoId;
  late final TextEditingController _descricao;
  late final TextEditingController _dataEvento;
  late final TextEditingController _horaInicio;
  late final TextEditingController _horaFim;
  final Map<String, int> _quantidades = {};
  List<Pessoa> _pessoas = [];
  List<Ministerio> _ministerios = [];
  List<Escala> _escalas = [];
  List<CultoEvento> _eventos = [];
  List<_ServicoOption> _servicosDisponiveis = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String get _competencia => competenciaFrom(DateTime(_year, _month));

  @override
  void initState() {
    super.initState();
    _descricao = TextEditingController();
    _dataEvento = TextEditingController();
    _horaInicio = TextEditingController(text: '18:00:00');
    _horaFim = TextEditingController(text: '20:00:00');
    final raw = widget.competencia ?? competenciaFrom(DateTime(2026, 8));
    final parts = raw.split('-');
    _year = int.tryParse(parts[0]) ?? 2026;
    _month = int.tryParse(parts.length > 1 ? parts[1] : '8') ?? 8;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _descricao.dispose();
    _dataEvento.dispose();
    _horaInicio.dispose();
    _horaFim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        context.read<PessoaService>().listarTodas(igrejaId: igrejaId),
        context.read<MinisterioService>().list(igrejaId: igrejaId),
        context.read<EscalaService>().list(igrejaId: igrejaId, competencia: _competencia),
        context.read<CronogramaService>().list(igrejaId: igrejaId),
      ]);
      if (!mounted) return;
      final pessoas = results[0] as List<Pessoa>;
      final ministerios = results[1] as List<Ministerio>;
      final escalas = results[2] as List<Escala>;
      final eventos = (results[3] as List<CultoEvento>)
          .where((e) => e.data.startsWith(_competencia))
          .toList();
      final servicos = <String, _ServicoOption>{};
      for (final m in ministerios) {
        for (final s in m.servicos) {
          if (s.ficcao) continue;
          servicos[s.id] = _ServicoOption(
            servicoId: s.id,
            nome: '${m.nome} · ${s.nome}',
            servicoNome: s.nome,
          );
        }
      }
      final igreja = context.read<IgrejaContext>().selected;
      setState(() {
        _pessoas = pessoas;
        _ministerios = ministerios;
        _escalas = escalas;
        _eventos = eventos;
        _servicosDisponiveis = servicos.values.toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
        _supervisorId = _coercePessoa(_supervisorId ?? igreja?.pastorPessoaId);
        _pregadorId = _coercePessoa(_pregadorId ?? igreja?.pastorPessoaId);
        _ministerioId = _coerceId(_ministerioId, ministerios);
        _eventoId = _coerceId(_eventoId, eventos);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<EscalaTipo> get _tiposPermitidos {
    final user = context.read<AuthProvider>().user;
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId ?? '';
    return EscalaTipo.values
        .where(
          (t) => podeCriarTipoEscala(
            user: user,
            tipo: t,
            ministerios: _ministerios,
            escalas: _escalas,
            competencia: _competencia,
            igrejaId: igrejaId,
          ),
        )
        .toList();
  }

  String? _coercePessoa(String? id) {
    if (id != null && _pessoas.any((p) => p.id == id)) return id;
    return _pessoas.isNotEmpty ? _pessoas.first.id : null;
  }

  String? _coerceId(String? id, List<dynamic> items) {
    if (id != null && items.any((i) => (i as dynamic).id == id)) return id;
    return items.isEmpty ? null : (items.first as dynamic).id as String?;
  }

  List<Ministerio> get _ministeriosPermitidos {
    final user = context.read<AuthProvider>().user;
    if (user?.permissoes.tem(Capacidade.escalasGerir) == true ||
        podeAtuarComoSupervisor(
          user: user,
          escalas: _escalas,
          competencia: _competencia,
          igrejaId: context.read<IgrejaContext>().selectedIgrejaId ?? '',
        )) {
      return _ministerios;
    }
    return _ministerios.where((m) => podeGerenciarMinisterio(user, m)).toList();
  }

  void _aplicarEvento(CultoEvento? evento) {
    if (evento == null) return;
    setState(() {
      _eventoId = evento.id;
      _dataEvento.text = evento.data;
      _horaInicio.text = evento.horaInicio.length == 5
          ? '${evento.horaInicio}:00'
          : evento.horaInicio;
      _horaFim.text = evento.horaFim != null
          ? (evento.horaFim!.length == 5 ? '${evento.horaFim}:00' : evento.horaFim!)
          : _horaFim.text;
    });
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().user;
    final igreja = context.read<IgrejaContext>().selected;
    if (igreja == null) return;

    if (_tipo == EscalaTipo.ministerio && _ministerioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o ministério.')),
      );
      return;
    }

    Ministerio? min;
    for (final m in _ministerios) {
      if (m.id == _ministerioId) min = m;
    }

    Pessoa? supervisor;
    Pessoa? pregador;
    for (final p in _pessoas) {
      if (p.id == _supervisorId) supervisor = p;
      if (p.id == _pregadorId) pregador = p;
    }

    final ok = podeCriarTipoEscala(
      user: user,
      tipo: _tipo,
      ministerios: _ministerios,
      escalas: _escalas,
      competencia: _competencia,
      igrejaId: igreja.id,
    );
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você não pode criar este tipo de escala.')),
      );
      return;
    }

    final servicos = <EscalaServico>[];
    for (final sel in _servicosDisponiveis) {
      final quantidade = _quantidades[sel.servicoId] ?? 0;
      if (quantidade <= 0) continue;
      servicos.add(
        EscalaServico(
          id: 'new-${sel.servicoId}',
          servicoId: sel.servicoId,
          servicoNome: sel.servicoNome,
          quantidadeNecessaria: quantidade,
        ),
      );
    }
    if (servicos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um serviço com quantidade.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final titulo = switch (_tipo) {
        EscalaTipo.supervisor => 'Supervisores — ${formatCompetencia(_competencia)}',
        EscalaTipo.pregador => 'Pregadores — ${formatCompetencia(_competencia)}',
        EscalaTipo.culto => 'Escala de culto — ${formatCompetencia(_competencia)}',
        EscalaTipo.ministerio =>
          '${min?.nome ?? 'Ministério'} — ${formatCompetencia(_competencia)}',
      };

      await context.read<EscalaService>().create(
            Escala(
              id: '',
              titulo: titulo,
              descricao: _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
              competencia: _competencia,
              tipo: _tipo,
              igrejaId: igreja.id,
              ministerioId: _tipo == EscalaTipo.ministerio ? _ministerioId : null,
              ministerioNome: min?.nome,
              supervisorPessoaId: supervisor?.id ?? igreja.pastorPessoaId,
              supervisorNome: supervisor?.nome ?? igreja.pastorNome,
              pregadorPessoaId:
                  _tipo == EscalaTipo.culto || _tipo == EscalaTipo.pregador
                      ? (pregador?.id ?? igreja.pastorPessoaId)
                      : null,
              pregadorNome: _tipo == EscalaTipo.culto || _tipo == EscalaTipo.pregador
                  ? (pregador?.nome ?? igreja.pastorNome)
                  : null,
              status: EscalaStatus.editando,
              dataEvento: _dataEvento.text.trim().isEmpty ? null : _dataEvento.text.trim(),
              horaInicio: _horaInicio.text.trim().isEmpty ? null : _horaInicio.text.trim(),
              horaFim: _horaFim.text.trim().isEmpty ? null : _horaFim.text.trim(),
              eventoId: _eventoId,
              ativo: true,
              servicos: servicos,
            ),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final tipos = _tiposPermitidos;
    if (tipos.isEmpty) {
      return const ErrorView(message: 'Você não tem permissão para criar escalas.');
    }
    if (!tipos.contains(_tipo)) {
      final next = tipos.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tipo = next);
      });
    }
    final tipoAtual = tipos.contains(_tipo) ? _tipo : tipos.first;

    final ministerios = _ministeriosPermitidos;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Nova escala',
          description: 'Aberta a partir do dia 20 do mês anterior ao da competência.',
          actions: [
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Cancelar')),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Salvando…' : 'Salvar'),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Competência', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  formatCompetencia(_competencia),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _month,
                        decoration: const InputDecoration(labelText: 'Mês'),
                        items: [
                          for (var i = 1; i <= 12; i++)
                            DropdownMenuItem(value: i, child: Text(mesesPt[i - 1])),
                        ],
                        onChanged: (v) {
                          setState(() => _month = v ?? _month);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _year,
                        decoration: const InputDecoration(labelText: 'Ano'),
                        items: [
                          for (var y = 2025; y <= 2028; y++)
                            DropdownMenuItem(value: y, child: Text('$y')),
                        ],
                        onChanged: (v) {
                          setState(() => _year = v ?? _year);
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<EscalaTipo>(
                  initialValue: tipoAtual,
                  decoration: const InputDecoration(labelText: 'Tipo de escala'),
                  items: [
                    for (final t in tipos)
                      DropdownMenuItem(value: t, child: Text(escalaTipoLabel(t))),
                  ],
                  onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                ),
                if (_tipo == EscalaTipo.ministerio) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _ministerioId,
                    decoration: const InputDecoration(labelText: 'Ministério *'),
                    items: [
                      for (final m in ministerios)
                        DropdownMenuItem(value: m.id, child: Text(m.nome)),
                    ],
                    onChanged: (v) => setState(() => _ministerioId = v),
                  ),
                ],
                const SizedBox(height: 12),
                SeletorPessoa(
                  pessoas: _pessoas,
                  label: 'Supervisor',
                  helperText: 'Padrão: pastor da igreja',
                  inicialId: _supervisorId,
                  permitirVazio: false,
                  onChanged: (v) => setState(() => _supervisorId = v ?? _supervisorId),
                ),
                if (_tipo == EscalaTipo.culto || _tipo == EscalaTipo.pregador) ...[
                  const SizedBox(height: 12),
                  SeletorPessoa(
                    pessoas: _pessoas,
                    label: 'Pregador',
                    helperText: 'Padrão: pastor da igreja',
                    inicialId: _pregadorId,
                    permitirVazio: false,
                    onChanged: (v) => setState(() => _pregadorId = v ?? _pregadorId),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _descricao,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Evento (opcional)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _eventoId,
                  decoration: const InputDecoration(
                    labelText: 'Evento do mês',
                    helperText: 'Preenche data e horário automaticamente.',
                  ),
                  items: [
                    for (final evento in _eventos)
                      DropdownMenuItem(
                        value: evento.id,
                        child: Text('${formatDate(evento.data)} · ${evento.titulo}'),
                      ),
                  ],
                  onChanged: (v) {
                    for (final e in _eventos) {
                      if (e.id == v) {
                        _aplicarEvento(e);
                        break;
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dataEvento,
                  decoration: const InputDecoration(
                    labelText: 'Data do evento',
                    hintText: 'AAAA-MM-DD',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _horaInicio,
                        decoration: const InputDecoration(labelText: 'Início'),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _horaFim,
                        decoration: const InputDecoration(labelText: 'Fim'),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Serviços necessários', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_servicosDisponiveis.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Nenhum serviço disponível.')),
          )
        else
          for (final sel in _servicosDisponiveis)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ServicoPickerRow(
                servico: sel,
                quantidade: _quantidades[sel.servicoId] ?? 0,
                onChanged: (q) => setState(() => _quantidades[sel.servicoId] = q),
              ),
            ),
      ],
    );
  }
}

class _ServicoOption {
  const _ServicoOption({
    required this.servicoId,
    required this.servicoNome,
    required this.nome,
  });

  final String servicoId;
  final String servicoNome;
  final String nome;
}

class _ServicoPickerRow extends StatelessWidget {
  const _ServicoPickerRow({
    required this.servico,
    required this.quantidade,
    required this.onChanged,
  });

  final _ServicoOption servico;
  final int quantidade;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(child: Text(servico.nome)),
            IconButton(
              onPressed: quantidade > 0 ? () => onChanged(quantidade - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(
              width: 24,
              child: Text(
                '$quantidade',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: quantidade < 9 ? () => onChanged(quantidade + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
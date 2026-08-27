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
  List<Pessoa> _pessoas = [];
  List<Ministerio> _ministerios = [];
  List<Escala> _escalas = [];
  List<CultoEvento> _eventos = [];
  final Map<String, String?> _alocacoes = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String get _competencia => competenciaFrom(DateTime(_year, _month));

  @override
  void initState() {
    super.initState();
    final raw = widget.competencia ?? competenciaFrom(DateTime(2026, 8));
    final parts = raw.split('-');
    _year = int.tryParse(parts[0]) ?? 2026;
    _month = int.tryParse(parts.length > 1 ? parts[1] : '8') ?? 8;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        context.read<PessoaService>().list(size: 100, igrejaId: igrejaId),
        context.read<MinisterioService>().list(igrejaId: igrejaId),
        context.read<EscalaService>().list(igrejaId: igrejaId, competencia: _competencia),
        context.read<CronogramaService>().list(igrejaId: igrejaId),
      ]);
      if (!mounted) return;
      final pessoas = (results[0] as PageResponse<Pessoa>).content;
      final ministerios = results[1] as List<Ministerio>;
      final escalas = results[2] as List<Escala>;
      final eventos = (results[3] as List<CultoEvento>)
          .where((e) => e.data.startsWith(_competencia))
          .toList();
      final igreja = context.read<IgrejaContext>().selected;
      setState(() {
        _pessoas = pessoas;
        _ministerios = ministerios;
        _escalas = escalas;
        _eventos = eventos;
        _supervisorId ??= igreja?.pastorPessoaId;
        _pregadorId ??= igreja?.pastorPessoaId;
        _loading = false;
      });
      _seedDatas();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _seedDatas() {
    _alocacoes.clear();
    final datas = _datasDoMes();
    for (final d in datas) {
      _alocacoes[d] ??= _supervisorId;
    }
    setState(() {});
  }

  List<String> _datasDoMes() {
    final cultos = _eventos.where((e) => e.tipo == TipoEvento.culto).map((e) => e.data).toSet();
    if (cultos.isNotEmpty) {
      final list = cultos.toList()..sort();
      return list;
    }
    return sundaysInMonth(_year, _month).map(isoDate).toList();
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

  List<Ministerio> get _ministeriosPermitidos {
    final user = context.read<AuthProvider>().user;
    if (isPastorOuAdmin(user) ||
        isSupervisorNoMes(
          user: user,
          escalas: _escalas,
          competencia: _competencia,
          igrejaId: context.read<IgrejaContext>().selectedIgrejaId ?? '',
        )) {
      return _ministerios;
    }
    return _ministerios.where((m) => podeGerenciarMinisterio(user, m)).toList();
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

    setState(() => _saving = true);
    try {
      final itens = <EscalaItem>[];
      var i = 0;
      _alocacoes.forEach((data, pessoaId) {
        Pessoa? pessoa;
        for (final p in _pessoas) {
          if (p.id == pessoaId) pessoa = p;
        }
        itens.add(
          EscalaItem(
            id: 'new$i',
            data: data,
            pessoaId: pessoaId,
            pessoaNome: pessoa?.nome,
            horario: '18:00',
          ),
        );
        i++;
      });

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
              competencia: _competencia,
              tipo: _tipo,
              igrejaId: igreja.id,
              ministerioId: _tipo == EscalaTipo.ministerio ? _ministerioId : null,
              ministerioNome: min?.nome,
              supervisorPessoaId: supervisor?.id ?? igreja.pastorPessoaId,
              supervisorNome: supervisor?.nome ?? igreja.pastorNome,
              pregadorPessoaId: pregador?.id ?? igreja.pastorPessoaId,
              pregadorNome: pregador?.nome ?? igreja.pastorNome,
              ativo: true,
              itens: itens,
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
          description: 'A escala é mensal. Escolha a competência antes de continuar.',
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
                        value: _month,
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
                        value: _year,
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
                  value: tipoAtual,
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
                    value: _ministerioId,
                    decoration: const InputDecoration(labelText: 'Ministério *'),
                    items: [
                      for (final m in ministerios)
                        DropdownMenuItem(value: m.id, child: Text(m.nome)),
                    ],
                    onChanged: (v) => setState(() => _ministerioId = v),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _supervisorId,
                  decoration: const InputDecoration(
                    labelText: 'Supervisor',
                    helperText: 'Padrão: pastor da igreja',
                  ),
                  items: [
                    for (final p in _pessoas)
                      DropdownMenuItem(value: p.id, child: Text(p.nome)),
                  ],
                  onChanged: (v) => setState(() => _supervisorId = v),
                ),
                if (_tipo == EscalaTipo.culto || _tipo == EscalaTipo.pregador) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _pregadorId,
                    decoration: const InputDecoration(
                      labelText: 'Pregador',
                      helperText: 'Padrão: pastor da igreja',
                    ),
                    items: [
                      for (final p in _pessoas)
                        DropdownMenuItem(value: p.id, child: Text(p.nome)),
                    ],
                    onChanged: (v) => setState(() => _pregadorId = v),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Dias do mês', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final data in _datasDoMes())
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: _alocacoes[data],
                  decoration: InputDecoration(labelText: formatDate(data)),
                  items: [
                    for (final p in _pessoas)
                      DropdownMenuItem(value: p.id, child: Text(p.nome)),
                  ],
                  onChanged: (v) => setState(() => _alocacoes[data] = v),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

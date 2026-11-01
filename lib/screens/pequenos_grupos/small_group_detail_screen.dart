import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/pessoa_service.dart';
import '../../services/small_group_service.dart';
import '../../utils/format.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';
import '../../widgets/form_dialogs.dart';

class SmallGroupDetailScreen extends StatefulWidget {
  const SmallGroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<SmallGroupDetailScreen> createState() => _SmallGroupDetailScreenState();
}

class _SmallGroupDetailScreenState extends State<SmallGroupDetailScreen> {
  SmallGroup? _group;
  List<Pessoa> _pessoas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        context.read<SmallGroupService>().getById(widget.groupId),
        _pessoasFromService(),
      ]);
      if (mounted) {
        setState(() {
          _group = results[0] as SmallGroup;
          _pessoas = results[1] as List<Pessoa>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Pessoa>> _pessoasFromService() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    final response = await context.read<PessoaService>().list(size: 100, igrejaId: igrejaId);
    return response.content;
  }

  Future<void> _refresh() async {
    try {
      final group = await context.read<SmallGroupService>().getById(widget.groupId);
      if (mounted) setState(() => _group = group);
    } catch (e) {
      if (mounted) showSnack(context, e);
    }
  }

  Future<SmallGroupEncontro> _saveEncontro(SmallGroupEncontro encontro) async {
    final saved = await context.read<SmallGroupService>().saveEncontro(encontro);
    await _refresh();
    return saved;
  }

  int _weekday(DiaSemana dia) {
    switch (dia) {
      case DiaSemana.domingo:
        return 7;
      case DiaSemana.segunda:
        return 1;
      case DiaSemana.terca:
        return 2;
      case DiaSemana.quarta:
        return 3;
      case DiaSemana.quinta:
        return 4;
      case DiaSemana.sexta:
        return 5;
      case DiaSemana.sabado:
        return 6;
    }
  }

  List<String> _semanasDoGrupo(SmallGroup g) {
    final target = _weekday(g.diaSemana);
    var d = DateTime.now().subtract(const Duration(days: 56));
    while (d.weekday != target) {
      d = d.add(const Duration(days: 1));
    }
    final result = <String>[];
    for (var i = 0; i < 11; i++) {
      result.add(isoDate(d));
      d = d.add(const Duration(days: 7));
    }
    return result;
  }

  Future<void> _edit() async {
    final g = _group;
    if (g == null) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => SmallGroupFormDialog(
        title: 'Editar pequeno grupo',
        initialNome: g.nome,
        initialHorario: g.horario ?? '',
        initialAtivo: g.ativo,
        initialDiaSemana: g.diaSemana,
        initialLiderId: g.liderPessoaId,
        initialNota: g.nota,
        pessoas: _pessoas,
      ),
    );
    if (result == null || !mounted) return;

    try {
      final updated = await context.read<SmallGroupService>().update(
            widget.groupId,
            nome: result['nome'] as String,
            diaSemana: result['diaSemana'] as DiaSemana,
            horario: result['horario'] as String?,
            liderPessoaId: result['liderPessoaId'] as String,
            nota: result['nota'] as int,
            ativo: result['ativo'] as bool,
          );
      final pessoas = await _pessoasFromService();
      if (mounted) {
        setState(() {
          _group = updated;
          _pessoas = pessoas;
        });
      }
    } catch (e) {
      if (mounted) showSnack(context, e);
    }
  }

  Future<void> _delete() async {
    final confirm = await confirmDialog(
      context,
      title: 'Apagar pequeno grupo',
      message: 'Apagar "${_group?.nome}" e todos os relatórios dele?',
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!confirm || !mounted) return;
    try {
      await context.read<SmallGroupService>().delete(widget.groupId);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null || _group == null) {
      return ErrorView(message: _error ?? 'Pequeno grupo não encontrado.', onRetry: _load);
    }

    final g = _group!;
    final user = context.watch<AuthProvider>().user;
    final canManage = podeGerenciarSmallGroup(user, g);
    final porData = {for (final e in g.encontros) e.data: e};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: g.nome,
          description: 'Pequeno grupo · ocorre toda semana.',
          actions: [
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Voltar')),
            if (canManage) ...[
              OutlinedButton(onPressed: _edit, child: const Text('Editar')),
              OutlinedButton(onPressed: _delete, child: const Text('Apagar')),
            ],
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row('Dia', '${diaSemanaLabel(g.diaSemana)} · ${g.horario ?? '—'}'),
                _row('Frequência', 'Semanal'),
                _row('Líder', g.liderNome),
                _row('Nota', g.notaLabel),
                _row('Status', g.ativo ? 'Ativa' : 'Inativa'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Relatórios semanais', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final data in _semanasDoGrupo(g))
          _SemanaTile(
            smallGroupId: g.id,
            data: data,
            encontro: porData[data],
            pessoas: _pessoas,
            canManage: canManage,
            onSave: _saveEncontro,
          ),
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

class _SemanaTile extends StatefulWidget {
  const _SemanaTile({
    required this.smallGroupId,
    required this.data,
    this.encontro,
    required this.pessoas,
    required this.canManage,
    required this.onSave,
  });

  final String smallGroupId;
  final String data;
  final SmallGroupEncontro? encontro;
  final List<Pessoa> pessoas;
  final bool canManage;
  final Future<SmallGroupEncontro> Function(SmallGroupEncontro encontro) onSave;

  @override
  State<_SemanaTile> createState() => _SemanaTileState();
}

class _SemanaTileState extends State<_SemanaTile> {
  String? _encontroId;
  String? _anfitriaoId;
  late Set<String> _compareceram;
  late TextEditingController _anotacoes;
  bool _saving = false;

  bool get _temRelatorio => widget.encontro != null && widget.encontro!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  void _seed() {
    final e = widget.encontro;
    _encontroId = e?.id;
    _anfitriaoId = e?.anfitriaoPessoaId;
    _compareceram = {...?e?.compareceram.map((p) => p.pessoaId)};
    _anotacoes = TextEditingController(text: e?.anotacoes ?? '');
  }

  @override
  void didUpdateWidget(covariant _SemanaTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.encontro?.id != _encontroId) {
      _encontroId = widget.encontro?.id;
      _anfitriaoId = widget.encontro?.anfitriaoPessoaId;
      _compareceram = {...?widget.encontro?.compareceram.map((p) => p.pessoaId)};
      _anotacoes.text = widget.encontro?.anotacoes ?? '';
    }
  }

  @override
  void dispose() {
    _anotacoes.dispose();
    super.dispose();
  }

  String? _nomeDe(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final p in widget.pessoas) {
      if (p.id == id) return p.nome;
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final presentes = _compareceram
          .map(
            (id) => SmallGroupParticipante(pessoaId: id, pessoaNome: _nomeDe(id) ?? ''),
          )
          .where((p) => p.pessoaId.isNotEmpty)
          .toList();
      final saved = await widget.onSave(
        SmallGroupEncontro(
          id: _encontroId ?? '',
          smallGroupId: widget.smallGroupId,
          data: widget.data,
          anfitriaoPessoaId: _anfitriaoId,
          anfitriaoNome: _nomeDe(_anfitriaoId),
          compareceram: presentes,
          anotacoes: _anotacoes.text.trim(),
        ),
      );
      _encontroId = saved.id;
    } catch (e) {
      if (mounted) showSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.encontro;
    final hasReport = e != null && e.id.isNotEmpty;
    final subtitle = hasReport
        ? [
            if (e.anfitriaoNome != null && e.anfitriaoNome!.isNotEmpty)
              'Anfitrião: ${e.anfitriaoNome}',
            if (e.compareceram.isNotEmpty) 'Compareceram: ${e.compareceram.length}',
          ].join(' · ')
        : 'Sem relatório';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(
            hasReport ? Icons.check_circle : Icons.radio_button_unchecked,
            color: hasReport ? Colors.green : Colors.grey,
          ),
          title: Text(formatDate(widget.data)),
          subtitle: Text(subtitle),
          children: [
            if (!widget.canManage)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _conteudoSomenteLeitura(e),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _editor(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _conteudoSomenteLeitura(SmallGroupEncontro? e) {
    if (e == null || e.id.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('Relatório não preenchido.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _linha('Anfitrião', e.anfitriaoNome ?? '—'),
        _linha(
          'Compareceram',
          e.compareceram.isEmpty
              ? '—'
              : e.compareceram.map((p) => p.pessoaNome).join(', '),
        ),
        if (e.anotacoes != null && e.anotacoes!.isNotEmpty) _linha('Anotações', e.anotacoes!),
      ],
    );
  }

  Widget _editor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _anfitriaoId ?? '',
          decoration: const InputDecoration(labelText: 'Anfitrião', isDense: true),
          items: [
            const DropdownMenuItem(value: '', child: Text('—')),
            for (final p in widget.pessoas)
              DropdownMenuItem(value: p.id, child: Text(p.nome)),
          ],
          onChanged: (v) =>
              setState(() => _anfitriaoId = (v == null || v.isEmpty) ? null : v),
        ),
        const SizedBox(height: 12),
        const Text('Compareceram', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        for (final p in widget.pessoas)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(p.nome),
            value: _compareceram.contains(p.id),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _compareceram.add(p.id);
                } else {
                  _compareceram.remove(p.id);
                }
              });
            },
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _anotacoes,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Anotações', isDense: true),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Salvando…' : (_temRelatorio ? 'Salvar' : 'Salvar relatório')),
          ),
        ),
      ],
    );
  }

  Widget _linha(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
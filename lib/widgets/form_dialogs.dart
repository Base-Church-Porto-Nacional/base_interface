import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';

class PessoaFormDialog extends StatefulWidget {
  const PessoaFormDialog({
    super.key,
    this.initialNome = '',
    this.initialTelefone = '',
    this.initialEmail = '',
    this.initialWhatsapp = '',
    this.title = 'Nova pessoa',
    this.servicos,
  });

  final String initialNome;
  final String initialTelefone;
  final String initialEmail;
  final String initialWhatsapp;
  final String title;

  /// Quando não nulo (líder cadastrando), o campo "Serviço" é obrigatório e
  /// só oferece estes serviços. Observações e "ativo" (dados pastorais) nunca
  /// aparecem aqui: o formulário só cobre contato.
  final List<Servico>? servicos;

  @override
  State<PessoaFormDialog> createState() => _PessoaFormDialogState();
}

class _PessoaFormDialogState extends State<PessoaFormDialog> {
  late final TextEditingController _nome;
  late final TextEditingController _telefone;
  late final TextEditingController _email;
  late final TextEditingController _whatsapp;
  String? _servicoId;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.initialNome);
    _telefone = TextEditingController(text: widget.initialTelefone);
    _email = TextEditingController(text: widget.initialEmail);
    _whatsapp = TextEditingController(text: widget.initialWhatsapp);
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _email.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome *'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefone,
              decoration: const InputDecoration(labelText: 'Telefone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _whatsapp,
              decoration: const InputDecoration(
                labelText: 'WhatsApp',
                helperText: 'Usado para a mensagem de aniversário. Deixe vazio para não enviar.',
              ),
              keyboardType: TextInputType.phone,
            ),
            if (widget.servicos != null) ...[
              const SizedBox(height: 12),
              if (widget.servicos!.isEmpty)
                const Text('Você não lidera nenhum serviço para vincular a pessoa.')
              else
                DropdownButtonFormField<String>(
                  initialValue: _servicoId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Serviço *'),
                  items: [
                    for (final sv in widget.servicos!)
                      DropdownMenuItem(value: sv.id, child: Text(sv.nome)),
                  ],
                  onChanged: (v) => setState(() => _servicoId = v),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_nome.text.trim().isEmpty) return;
            if (widget.servicos != null && _servicoId == null) return;
            Navigator.pop(context, {
              'nome': _nome.text.trim(),
              'telefone': _telefone.text.trim(),
              'email': _email.text.trim(),
              'whatsapp': _whatsapp.text.trim(),
              if (_servicoId != null) 'servicoId': _servicoId!,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class MinisterioFormDialog extends StatefulWidget {
  const MinisterioFormDialog({
    super.key,
    this.initialNome = '',
    this.initialDescricao = '',
    this.initialAtivo = true,
    this.initialTipo = MinisterioTipo.geral,
    this.initialLiderId,
    this.initialCoordenadorId,
    this.initialBaseMinisterialId,
    this.pessoas = const [],
    this.bases = const [],
    this.title = 'Novo ministério',
  });

  final String initialNome;
  final String initialDescricao;
  final bool initialAtivo;
  final MinisterioTipo initialTipo;
  final String? initialLiderId;
  final String? initialCoordenadorId;
  final String? initialBaseMinisterialId;
  final List<Pessoa> pessoas;
  final List<BaseMinisterial> bases;
  final String title;

  @override
  State<MinisterioFormDialog> createState() => _MinisterioFormDialogState();
}

class _MinisterioFormDialogState extends State<MinisterioFormDialog> {
  late final TextEditingController _nome;
  late final TextEditingController _descricao;
  late bool _ativo;
  late MinisterioTipo _tipo;
  String? _liderId;
  String? _coordenadorId;
  String? _baseMinisterialId;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.initialNome);
    _descricao = TextEditingController(text: widget.initialDescricao);
    _ativo = widget.initialAtivo;
    _tipo = widget.initialTipo;
    _liderId = widget.initialLiderId;
    _coordenadorId = widget.initialCoordenadorId;
    _baseMinisterialId = widget.initialBaseMinisterialId;
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome *'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MinisterioTipo>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final t in MinisterioTipo.values)
                  DropdownMenuItem(value: t, child: Text(ministerioTipoLabel(t))),
              ],
              onChanged: (v) => setState(() => _tipo = v ?? MinisterioTipo.geral),
            ),
            const SizedBox(height: 12),
            if (widget.bases.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _baseMinisterialId ?? '',
                decoration: const InputDecoration(labelText: 'Base ministerial'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('—')),
                  for (final b in widget.bases)
                    DropdownMenuItem(value: b.id, child: Text(b.nome)),
                ],
                onChanged: (v) =>
                    setState(() => _baseMinisterialId = (v == null || v.isEmpty) ? null : v),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.pessoas.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _liderId ?? '',
                decoration: const InputDecoration(labelText: 'Líder espiritual'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('—')),
                  for (final p in widget.pessoas)
                    DropdownMenuItem(value: p.id, child: Text(p.nome)),
                ],
                onChanged: (v) => setState(() => _liderId = (v == null || v.isEmpty) ? null : v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _coordenadorId ?? '',
                decoration: const InputDecoration(
                  labelText: 'Coordenador',
                  helperText: 'Serviço ficção do ministério, não é um papel.',
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('—')),
                  for (final p in widget.pessoas)
                    DropdownMenuItem(value: p.id, child: Text(p.nome)),
                ],
                onChanged: (v) => setState(() => _coordenadorId = (v == null || v.isEmpty) ? null : v),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _descricao,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativo'),
              value: _ativo,
              onChanged: (v) => setState(() => _ativo = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_nome.text.trim().isEmpty) return;
            Pessoa? lider;
            Pessoa? coord;
            for (final p in widget.pessoas) {
              if (p.id == _liderId) lider = p;
              if (p.id == _coordenadorId) coord = p;
            }
            BaseMinisterial? base;
            for (final b in widget.bases) {
              if (b.id == _baseMinisterialId) base = b;
            }
            Navigator.pop(context, {
              'nome': _nome.text.trim(),
              'descricao': _descricao.text.trim(),
              'ativo': _ativo,
              'tipo': _tipo,
              'liderPessoaId': _liderId,
              'liderNome': lider?.nome,
              'coordenadorPessoaId': _coordenadorId,
              'coordenadorNome': coord?.nome,
              'baseMinisterialId': _baseMinisterialId,
              'baseMinisterialNome': base?.nome,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class BaseMinisterialFormDialog extends StatefulWidget {
  const BaseMinisterialFormDialog({
    super.key,
    this.initialNome = '',
    this.initialDescricao = '',
    this.initialAtivo = true,
    this.initialLiderId,
    this.initialCoordenadorId,
    this.pessoas = const [],
    this.title = 'Nova base ministerial',
  });

  final String initialNome;
  final String initialDescricao;
  final bool initialAtivo;
  final String? initialLiderId;
  final String? initialCoordenadorId;
  final List<Pessoa> pessoas;
  final String title;

  @override
  State<BaseMinisterialFormDialog> createState() => _BaseMinisterialFormDialogState();
}

class _BaseMinisterialFormDialogState extends State<BaseMinisterialFormDialog> {
  late final TextEditingController _nome;
  late final TextEditingController _descricao;
  late bool _ativo;
  String? _liderId;
  String? _coordenadorId;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.initialNome);
    _descricao = TextEditingController(text: widget.initialDescricao);
    _ativo = widget.initialAtivo;
    _liderId = widget.initialLiderId;
    _coordenadorId = widget.initialCoordenadorId;
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome *'),
            ),
            const SizedBox(height: 12),
            if (widget.pessoas.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _liderId ?? '',
                decoration: const InputDecoration(labelText: 'Líder'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('—')),
                  for (final p in widget.pessoas)
                    DropdownMenuItem(value: p.id, child: Text(p.nome)),
                ],
                onChanged: (v) => setState(() => _liderId = (v == null || v.isEmpty) ? null : v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _coordenadorId ?? '',
                decoration: const InputDecoration(labelText: 'Coordenador'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('—')),
                  for (final p in widget.pessoas)
                    DropdownMenuItem(value: p.id, child: Text(p.nome)),
                ],
                onChanged: (v) =>
                    setState(() => _coordenadorId = (v == null || v.isEmpty) ? null : v),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _descricao,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativa'),
              value: _ativo,
              onChanged: (v) => setState(() => _ativo = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_nome.text.trim().isEmpty) return;
            Pessoa? lider;
            Pessoa? coord;
            for (final p in widget.pessoas) {
              if (p.id == _liderId) lider = p;
              if (p.id == _coordenadorId) coord = p;
            }
            Navigator.pop(context, {
              'nome': _nome.text.trim(),
              'descricao': _descricao.text.trim(),
              'ativo': _ativo,
              'liderPessoaId': _liderId,
              'liderNome': lider?.nome,
              'coordenadorPessoaId': _coordenadorId,
              'coordenadorNome': coord?.nome,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class FilialFormDialog extends StatefulWidget {
  const FilialFormDialog({super.key, required this.pessoas, this.excluirIds = const {}});

  final List<Pessoa> pessoas;

  /// Pessoas que não podem ser escolhidas (pastor titular da matriz, o próprio
  /// usuário): o servidor recusaria a transferência.
  final Set<String> excluirIds;

  @override
  State<FilialFormDialog> createState() => _FilialFormDialogState();
}

class _FilialFormDialogState extends State<FilialFormDialog> {
  final _nome = TextEditingController();
  final _pastorNome = TextEditingController();
  final _pastorEmail = TextEditingController();
  final _pastorWhatsapp = TextEditingController();
  String? _pastorId;
  bool _novaPessoa = false;
  String? _erro;

  /// Só pessoas ativas e elegíveis (inativas e excluídas o servidor recusa).
  late final List<Pessoa> _elegiveis = [
    for (final p in widget.pessoas)
      if (p.status == PessoaStatus.ativo && !widget.excluirIds.contains(p.id)) p,
  ];

  @override
  void initState() {
    super.initState();
    _novaPessoa = _elegiveis.isEmpty;
  }

  @override
  void dispose() {
    _nome.dispose();
    _pastorNome.dispose();
    _pastorEmail.dispose();
    _pastorWhatsapp.dispose();
    super.dispose();
  }

  void _criar() {
    if (_nome.text.trim().isEmpty) return;
    if (!_novaPessoa) {
      if (_pastorId == null) return;
      Navigator.pop(context, {
        'nome': _nome.text.trim(),
        'pastorPessoaId': _pastorId,
      });
      return;
    }
    final email = _pastorEmail.text.trim();
    final whatsapp = _pastorWhatsapp.text.trim();
    if (_pastorNome.text.trim().isEmpty) return;
    if (email.isEmpty && whatsapp.isEmpty) {
      setState(() => _erro = 'Informe e-mail ou WhatsApp.');
      return;
    }
    Navigator.pop(context, {
      'nome': _nome.text.trim(),
      'pastorNome': _pastorNome.text.trim(),
      if (email.isNotEmpty) 'pastorEmail': email,
      if (whatsapp.isNotEmpty) 'pastorWhatsapp': whatsapp,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova filial'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome da filial *'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Pessoa já cadastrada')),
                ButtonSegment(value: true, label: Text('Nova pessoa')),
              ],
              selected: {_novaPessoa},
              onSelectionChanged: (v) => setState(() {
                _novaPessoa = v.first;
                _erro = null;
              }),
            ),
            const SizedBox(height: 12),
            if (!_novaPessoa)
              DropdownButtonFormField<String>(
                initialValue: _pastorId,
                decoration: const InputDecoration(labelText: 'Pastor *'),
                items: [
                  for (final p in _elegiveis)
                    DropdownMenuItem(value: p.id, child: Text(p.nome)),
                ],
                onChanged: (v) => setState(() => _pastorId = v),
              )
            else ...[
              TextField(
                controller: _pastorNome,
                decoration: const InputDecoration(labelText: 'Nome do pastor *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pastorEmail,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pastorWhatsapp,
                decoration: const InputDecoration(labelText: 'WhatsApp'),
                keyboardType: TextInputType.phone,
              ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _erro!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _criar, child: const Text('Criar')),
      ],
    );
  }
}

/// Escolha do novo pastor entre as pessoas ativas da própria igreja (sem o atual).
class TrocarPastorDialog extends StatefulWidget {
  const TrocarPastorDialog({super.key, required this.pessoas, this.atualId});

  final List<Pessoa> pessoas;
  final String? atualId;

  @override
  State<TrocarPastorDialog> createState() => _TrocarPastorDialogState();
}

class _TrocarPastorDialogState extends State<TrocarPastorDialog> {
  String? _id;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trocar pastor'),
      content: DropdownButtonFormField<String>(
        initialValue: _id,
        decoration: const InputDecoration(labelText: 'Novo pastor *'),
        items: [
          for (final p in widget.pessoas)
            if (p.id != widget.atualId && p.status == PessoaStatus.ativo)
              DropdownMenuItem(value: p.id, child: Text(p.nome)),
        ],
        onChanged: (v) => setState(() => _id = v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _id == null ? null : () => Navigator.pop(context, _id),
          child: const Text('Trocar'),
        ),
      ],
    );
  }
}

/// Atribuição de papéis de uma conta. PASTOR/SECRETARIA só aparecem com
/// `podeGestao` (capacidade papeisGestaoAtribuir); os customizados só com
/// `podeCustom` (papeisCustomGerir). Devolve a lista COMPLETA de papéis: os
/// que o diálogo não gerencia (ex.: MEMBRO, LIDER) são preservados.
class PapeisDialog extends StatefulWidget {
  const PapeisDialog({
    super.key,
    required this.pessoaNome,
    required this.atuais,
    required this.customizados,
    required this.podeGestao,
    required this.podeCustom,
    this.onCriarPapel,
  });

  static const papeisGestao = ['PASTOR', 'SECRETARIA'];

  final String pessoaNome;
  final List<String> atuais;
  final List<String> customizados;
  final bool podeGestao;
  final bool podeCustom;

  /// Cria um papel customizado e devolve a lista atualizada de customizados.
  /// Só usado com `podeCustom`; erros do servidor aparecem no diálogo.
  final Future<List<String>> Function(String nome, bool podeLancarContagem)? onCriarPapel;

  @override
  State<PapeisDialog> createState() => _PapeisDialogState();
}

class _PapeisDialogState extends State<PapeisDialog> {
  late final Set<String> _sel;
  late List<String> _customizados;
  final _novoNome = TextEditingController();
  bool _novoContagem = false;
  bool _criando = false;
  String? _erroNovo;

  List<String> get _gerenciaveis => [
        if (widget.podeGestao) ...PapeisDialog.papeisGestao,
        if (widget.podeCustom) ..._customizados,
      ];

  bool get _podeCriar => widget.podeCustom && widget.onCriarPapel != null;

  @override
  void initState() {
    super.initState();
    _sel = widget.atuais.map((p) => p.toUpperCase()).toSet();
    _customizados = [...widget.customizados];
  }

  @override
  void dispose() {
    _novoNome.dispose();
    super.dispose();
  }

  Future<void> _criarPapel() async {
    final nome = _novoNome.text.trim();
    if (nome.isEmpty) {
      setState(() => _erroNovo = 'Informe o nome do papel.');
      return;
    }
    setState(() {
      _criando = true;
      _erroNovo = null;
    });
    try {
      final lista = await widget.onCriarPapel!(nome, _novoContagem);
      if (!mounted) return;
      setState(() {
        _customizados = lista;
        _novoNome.clear();
        _novoContagem = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _erroNovo = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _criando = false);
    }
  }

  Widget _novoPapelForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(),
        const Text('Novo papel', style: TextStyle(fontWeight: FontWeight.w600)),
        TextField(
          key: const Key('novoPapelNome'),
          controller: _novoNome,
          decoration: InputDecoration(labelText: 'Nome', errorText: _erroNovo),
          textCapitalization: TextCapitalization.characters,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Pode lançar contagem do culto'),
          value: _novoContagem,
          onChanged: (v) => setState(() => _novoContagem = v ?? false),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: _criando ? null : _criarPapel,
            child: const Text('Criar papel'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final itens = _gerenciaveis;
    return AlertDialog(
      title: Text('Papéis — ${widget.pessoaNome}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (itens.isEmpty)
              const Text('Nenhum papel disponível para atribuir.'),
            for (final papel in itens)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(papelLabel(papel)),
                value: _sel.contains(papel),
                onChanged: (v) => setState(() {
                  if (v ?? false) {
                    _sel.add(papel);
                  } else {
                    _sel.remove(papel);
                  }
                }),
              ),
            if (_podeCriar) _novoPapelForm(),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: itens.isEmpty
              ? null
              : () {
                  final gerenciados = itens.toSet();
                  final preservados = widget.atuais
                      .map((p) => p.toUpperCase())
                      .where((p) => !gerenciados.contains(p));
                  Navigator.pop(context, <String>[
                    ...preservados,
                    ...itens.where(_sel.contains),
                  ]);
                },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class SmallGroupFormDialog extends StatefulWidget {
  const SmallGroupFormDialog({
    super.key,
    this.initialNome = '',
    this.initialHorario = '',
    this.initialAtivo = true,
    this.initialDiaSemana = DiaSemana.domingo,
    this.initialLiderId,
    this.initialNota = 0,
    this.pessoas = const [],
    this.title = 'Novo pequeno grupo',
  });

  final String initialNome;
  final String initialHorario;
  final bool initialAtivo;
  final DiaSemana initialDiaSemana;
  final String? initialLiderId;
  final int initialNota;
  final List<Pessoa> pessoas;
  final String title;

  @override
  State<SmallGroupFormDialog> createState() => _SmallGroupFormDialogState();
}

class _SmallGroupFormDialogState extends State<SmallGroupFormDialog> {
  late final TextEditingController _nome;
  late final TextEditingController _horario;
  late bool _ativo;
  late DiaSemana _diaSemana;
  String? _liderId;
  late int _nota;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.initialNome);
    _horario = TextEditingController(text: widget.initialHorario);
    _ativo = widget.initialAtivo;
    _diaSemana = widget.initialDiaSemana;
    _liderId = widget.initialLiderId;
    _nota = widget.initialNota;
  }

  @override
  void dispose() {
    _nome.dispose();
    _horario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome *'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DiaSemana>(
              initialValue: _diaSemana,
              decoration: const InputDecoration(
                labelText: 'Dia da semana',
                helperText: 'O pequeno grupo ocorre toda semana neste dia.',
              ),
              items: [
                for (final d in DiaSemana.values)
                  DropdownMenuItem(value: d, child: Text(diaSemanaLabel(d))),
              ],
              onChanged: (v) => setState(() => _diaSemana = v ?? DiaSemana.domingo),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _horario,
              decoration: const InputDecoration(labelText: 'Horário'),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 12),
            if (widget.pessoas.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _liderId ?? '',
                decoration: const InputDecoration(labelText: 'Líder *'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('—')),
                  for (final p in widget.pessoas)
                    DropdownMenuItem(value: p.id, child: Text(p.nome)),
                ],
                onChanged: (v) =>
                    setState(() => _liderId = (v == null || v.isEmpty) ? null : v),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Text('Nota'),
                const SizedBox(width: 4),
                for (var i = 1; i <= 5; i++)
                  InkWell(
                    onTap: () => setState(() => _nota = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        i <= _nota ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: () => setState(() => _nota = 0),
                  icon: const Icon(Icons.clear, size: 18),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Limpar nota',
                ),
                Text(_nota == 0 ? 'Sem nota' : '$_nota / 5'),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativa'),
              value: _ativo,
              onChanged: (v) => setState(() => _ativo = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_nome.text.trim().isEmpty || _liderId == null) return;
            Pessoa? lider;
            for (final p in widget.pessoas) {
              if (p.id == _liderId) lider = p;
            }
            Navigator.pop(context, {
              'nome': _nome.text.trim(),
              'diaSemana': _diaSemana,
              'horario': _horario.text.trim(),
              'liderPessoaId': _liderId,
              'liderNome': lider?.nome,
              'nota': _nota,
              'ativo': _ativo,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

/// Líder (ou gestão) vincula uma pessoa já cadastrada da igreja a um serviço
/// real do ministério: busca só por nome (sem ver a ficha) e escolhe o serviço.
/// Fecha com `true` quando o vínculo é criado.
class AdicionarPessoaExistenteDialog extends StatefulWidget {
  const AdicionarPessoaExistenteDialog({
    super.key,
    required this.ministerio,
    required this.buscar,
    required this.vincular,
  });

  final Ministerio ministerio;
  final Future<List<PessoaResumo>> Function(String termo) buscar;
  final Future<void> Function(String pessoaId, String servicoId) vincular;

  @override
  State<AdicionarPessoaExistenteDialog> createState() => _AdicionarPessoaExistenteDialogState();
}

class _AdicionarPessoaExistenteDialogState extends State<AdicionarPessoaExistenteDialog> {
  final _busca = TextEditingController();
  Timer? _debounce;
  List<PessoaResumo> _resultados = const [];
  PessoaResumo? _pessoa;
  String? _servicoId;
  bool _buscando = false;
  bool _salvando = false;
  String? _erro;

  List<Servico> get _servicos =>
      widget.ministerio.servicos.where((s) => !s.ficcao && s.ativo).toList();

  @override
  void dispose() {
    _debounce?.cancel();
    _busca.dispose();
    super.dispose();
  }

  void _onBusca(String texto) {
    _debounce?.cancel();
    final termo = texto.trim();
    if (termo.length < 2) {
      setState(() => _resultados = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _buscar(termo));
  }

  Future<void> _buscar(String termo) async {
    setState(() {
      _buscando = true;
      _erro = null;
    });
    try {
      final r = await widget.buscar(termo);
      if (mounted) setState(() => _resultados = r);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _adicionar() async {
    final pessoa = _pessoa;
    final servicoId = _servicoId;
    if (pessoa == null || servicoId == null) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.vincular(pessoa.id, servicoId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicos = _servicos;
    return AlertDialog(
      title: const Text('Adicionar pessoa existente'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_pessoa == null) ...[
                TextField(
                  key: const Key('buscaPessoaExistente'),
                  controller: _busca,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nome da pessoa',
                    helperText: 'Digite ao menos 2 letras',
                  ),
                  onChanged: _onBusca,
                ),
                if (_buscando) const LinearProgressIndicator(),
                for (final r in _resultados)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.nome),
                    onTap: () => setState(() => _pessoa = r),
                  ),
                if (!_buscando && _busca.text.trim().length >= 2 && _resultados.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Nenhuma pessoa encontrada.'),
                  ),
              ] else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_pessoa!.nome),
                  trailing: TextButton(
                    onPressed: () => setState(() => _pessoa = null),
                    child: const Text('Trocar'),
                  ),
                ),
                if (servicos.isEmpty)
                  const Text('Este ministério ainda não tem serviços para vincular.')
                else
                  DropdownButtonFormField<String>(
                    key: const Key('servicoPessoaExistente'),
                    initialValue: _servicoId,
                    decoration: const InputDecoration(labelText: 'Serviço'),
                    items: [
                      for (final s in servicos)
                        DropdownMenuItem(value: s.id, child: Text(s.nome)),
                    ],
                    onChanged: (v) => setState(() => _servicoId = v),
                  ),
              ],
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _salvando || _pessoa == null || _servicoId == null ? null : _adicionar,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

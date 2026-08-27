import 'package:flutter/material.dart';

import '../models/models.dart';

class PessoaFormDialog extends StatefulWidget {
  const PessoaFormDialog({
    super.key,
    this.initialNome = '',
    this.initialTelefone = '',
    this.initialEmail = '',
    this.title = 'Nova pessoa',
  });

  final String initialNome;
  final String initialTelefone;
  final String initialEmail;
  final String title;

  @override
  State<PessoaFormDialog> createState() => _PessoaFormDialogState();
}

class _PessoaFormDialogState extends State<PessoaFormDialog> {
  late final TextEditingController _nome;
  late final TextEditingController _telefone;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.initialNome);
    _telefone = TextEditingController(text: widget.initialTelefone);
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _email.dispose();
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
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_nome.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'nome': _nome.text.trim(),
              'telefone': _telefone.text.trim(),
              'email': _email.text.trim(),
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
    this.pessoas = const [],
    this.title = 'Novo ministério',
  });

  final String initialNome;
  final String initialDescricao;
  final bool initialAtivo;
  final MinisterioTipo initialTipo;
  final String? initialLiderId;
  final String? initialCoordenadorId;
  final List<Pessoa> pessoas;
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

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.initialNome);
    _descricao = TextEditingController(text: widget.initialDescricao);
    _ativo = widget.initialAtivo;
    _tipo = widget.initialTipo;
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
            Navigator.pop(context, {
              'nome': _nome.text.trim(),
              'descricao': _descricao.text.trim(),
              'ativo': _ativo,
              'tipo': _tipo,
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
  const FilialFormDialog({super.key, required this.pessoas});

  final List<Pessoa> pessoas;

  @override
  State<FilialFormDialog> createState() => _FilialFormDialogState();
}

class _FilialFormDialogState extends State<FilialFormDialog> {
  final _nome = TextEditingController();
  final _adminNome = TextEditingController();
  final _adminEmail = TextEditingController();
  final _adminUsername = TextEditingController();
  String? _pastorId;

  @override
  void dispose() {
    _nome.dispose();
    _adminNome.dispose();
    _adminEmail.dispose();
    _adminUsername.dispose();
    super.dispose();
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
            DropdownButtonFormField<String>(
              initialValue: _pastorId,
              decoration: const InputDecoration(labelText: 'Pastor *'),
              items: [
                for (final p in widget.pessoas)
                  DropdownMenuItem(value: p.id, child: Text(p.nome)),
              ],
              onChanged: (v) => setState(() => _pastorId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _adminNome,
              decoration: const InputDecoration(labelText: 'Nome do admin *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _adminEmail,
              decoration: const InputDecoration(labelText: 'E-mail do admin *'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _adminUsername,
              decoration: const InputDecoration(labelText: 'Usuário do admin *'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_nome.text.trim().isEmpty ||
                _pastorId == null ||
                _adminNome.text.trim().isEmpty ||
                _adminEmail.text.trim().isEmpty ||
                _adminUsername.text.trim().isEmpty) {
              return;
            }
            Pessoa? pastor;
            for (final p in widget.pessoas) {
              if (p.id == _pastorId) pastor = p;
            }
            Navigator.pop(context, {
              'nome': _nome.text.trim(),
              'pastorPessoaId': _pastorId,
              'pastorNome': pastor?.nome ?? '',
              'adminNome': _adminNome.text.trim(),
              'adminEmail': _adminEmail.text.trim(),
              'adminUsername': _adminUsername.text.trim(),
            });
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}

class UsuarioFormDialog extends StatefulWidget {
  const UsuarioFormDialog({
    super.key,
    required this.pessoaNome,
    required this.email,
    this.voluntario = false,
  });

  final String pessoaNome;
  final String email;
  final bool voluntario;

  @override
  State<UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<UsuarioFormDialog> {
  late final TextEditingController _username;
  late final TextEditingController _email;
  final _senha = TextEditingController();
  late bool _membro;
  late bool _voluntario;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(
      text: widget.email.contains('@') ? widget.email.split('@').first : '',
    );
    _email = TextEditingController(text: widget.email);
    _membro = true;
    _voluntario = widget.voluntario;
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Criar usuário — ${widget.pessoaNome}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Usuário *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'E-mail *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senha,
              decoration: const InputDecoration(labelText: 'Senha *'),
              obscureText: true,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Membro'),
              value: _membro,
              onChanged: (v) => setState(() => _membro = v ?? true),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Voluntário'),
              value: _voluntario,
              onChanged: (v) => setState(() => _voluntario = v ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_username.text.trim().isEmpty ||
                _email.text.trim().isEmpty ||
                _senha.text.trim().isEmpty) {
              return;
            }
            final papeis = <Role>[
              if (_membro) Role.membro,
              if (_voluntario) Role.voluntario,
            ];
            if (papeis.isEmpty) papeis.add(Role.membro);
            Navigator.pop(context, {
              'username': _username.text.trim(),
              'email': _email.text.trim(),
              'senha': _senha.text.trim(),
              'papeis': papeis,
            });
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}

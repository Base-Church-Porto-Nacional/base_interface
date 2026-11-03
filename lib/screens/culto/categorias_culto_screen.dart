import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/categoria_culto_service.dart';
import '../../services/pessoa_service.dart';
import '../../utils/format.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_search.dart';

class CategoriasCultoScreen extends StatefulWidget {
  const CategoriasCultoScreen({super.key});

  @override
  State<CategoriasCultoScreen> createState() => _CategoriasCultoScreenState();
}

class _CategoriasCultoScreenState extends State<CategoriasCultoScreen> {
  List<CategoriaCulto> _categorias = [];
  List<Pessoa> _pessoas = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _loadedFor;

  bool get _canManage => isGestao(context.read<AuthProvider>().user);

  Future<void> _load() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        context.read<CategoriaCultoService>().list(igrejaId: igrejaId),
        context.read<PessoaService>().listarTodas(igrejaId: igrejaId),
      ]);
      if (!mounted) return;
      setState(() {
        _categorias = results[0] as List<CategoriaCulto>;
        _pessoas = results[1] as List<Pessoa>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Pessoa? _pessoaById(String? id) {
    if (id == null) return null;
    for (final p in _pessoas) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _openForm({CategoriaCulto? existing}) async {
    if (!_canManage) return;
    final igreja = context.read<IgrejaContext>().selected;
    if (igreja == null) return;

    final titulo = TextEditingController(text: existing?.titulo ?? '');
    final descricao = TextEditingController(text: existing?.descricao ?? '');
    final hora = TextEditingController(
      text: formatHora(existing?.horaInicio ?? '20:00'),
    );
    final duracao = TextEditingController(
      text: (existing?.duracaoMinutos ?? 90).toString(),
    );
    var dia = existing?.diaSemana ?? DiaSemana.domingo;
    String? pregadorId = existing?.pregadorPadraoId;
    var ativo = existing?.ativo ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(existing == null ? 'Nova categoria' : 'Editar categoria'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titulo,
                      decoration: const InputDecoration(labelText: 'Título *'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descricao,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DiaSemana>(
                      initialValue: dia,
                      decoration: const InputDecoration(labelText: 'Dia da semana'),
                      items: [
                        for (final d in DiaSemana.values)
                          DropdownMenuItem(value: d, child: Text(diaSemanaLabel(d))),
                      ],
                      onChanged: (v) => setLocal(() => dia = v ?? dia),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hora,
                      decoration: const InputDecoration(
                        labelText: 'Horário de início',
                        hintText: 'HH:mm',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: duracao,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duração (minutos)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: pregadorId,
                      decoration: const InputDecoration(
                        labelText: 'Pregador padrão',
                        helperText: 'Usado de padrão nos cultos gerados',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('— Sem padrão —'),
                        ),
                        for (final p in _pessoas)
                          DropdownMenuItem(value: p.id, child: Text(p.nome)),
                      ],
                      onChanged: (v) => setLocal(() => pregadorId = v),
                    ),
                    if (existing != null) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ativa'),
                        value: ativo,
                        onChanged: (v) => setLocal(() => ativo = v),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) return;
    final duracaoMin = int.tryParse(duracao.text.trim()) ?? 90;
    final pregador = _pessoaById(pregadorId);
    final categoria = CategoriaCulto(
      id: existing?.id ?? '',
      igrejaId: existing?.igrejaId ?? igreja.id,
      titulo: titulo.text.trim(),
      descricao: descricao.text.trim().isEmpty ? null : descricao.text.trim(),
      diaSemana: dia,
      horaInicio: normalizeHoraApi(hora.text),
      duracaoMinutos: duracaoMin < 0 ? 90 : duracaoMin,
      pregadorPadraoId: pregadorId,
      pregadorPadraoNome: pregador?.nome ?? existing?.pregadorPadraoNome,
      ativo: ativo,
    );

    setState(() => _saving = true);
    try {
      if (existing == null) {
        await context.read<CategoriaCultoService>().create(categoria);
      } else {
        await context.read<CategoriaCultoService>().update(categoria);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _gerar(CategoriaCulto categoria) async {
    if (!_canManage) return;
    setState(() => _saving = true);
    try {
      final msg = await context.read<CategoriaCultoService>().gerarCultos(categoria.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _excluir(CategoriaCulto categoria) async {
    if (!_canManage) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir categoria'),
        content: Text(
          'Excluir "${categoria.titulo}"? Se houver cultos vinculados ela será apenas desativada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    try {
      await context.read<CategoriaCultoService>().delete(categoria.id);
      await _load();
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

    return Column(
      children: [
        const SectionTabs(
          currentPath: '/cultos/categorias',
          tabs: [
            ('/cultos/mes', 'Mês'),
            ('/cultos/categorias', 'Categorias'),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageHeader(
                title: 'Categorias de culto',
                description:
                    'Padrões de culto recorrentes. A automação gera os cultos do mês a partir daqui.',
                actions: [
                  if (_canManage)
                    FilledButton(
                      onPressed: _saving ? null : _openForm,
                      child: const Text('Nova categoria'),
                    ),
                ],
              ),
              if (_loading)
                const LoadingView()
              else if (_error != null)
                ErrorView(message: _error!, onRetry: _load)
              else if (_categorias.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Nenhuma categoria cadastrada.')),
                )
              else
                ..._categorias.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MobileListTile(
                      title: c.titulo,
                      subtitle: [
                        diaSemanaLabel(c.diaSemana),
                        formatHora(c.horaInicio),
                        '${c.duracaoMinutos} min',
                        if (c.pregadorPadraoNome != null)
                          'Pregador: ${c.pregadorPadraoNome}',
                        if (c.descricao != null && c.descricao!.isNotEmpty)
                          c.descricao!,
                      ].join(' · '),
                      trailing: StatusBadge(
                        label: c.ativo ? 'ATIVA' : 'INATIVA',
                        success: c.ativo,
                      ),
                      actions: [
                        if (_canManage)
                          OutlinedButton(
                            onPressed: _saving ? null : () => _gerar(c),
                            child: const Text('Gerar cultos'),
                          ),
                        if (_canManage)
                          OutlinedButton(
                            onPressed: _saving ? null : () => _excluir(c),
                            child: const Text('Excluir'),
                          ),
                      ],
                      onTap: _canManage ? () => _openForm(existing: c) : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
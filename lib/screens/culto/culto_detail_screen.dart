import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/culto_service.dart';
import '../../services/ministerio_service.dart';
import '../../services/pessoa_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';

class CultoDetailScreen extends StatefulWidget {
  const CultoDetailScreen({super.key, required this.cultoId});

  final String cultoId;

  @override
  State<CultoDetailScreen> createState() => _CultoDetailScreenState();
}

class _CultoDetailScreenState extends State<CultoDetailScreen> {
  Culto? _culto;
  CultoConteudo _conteudo = const CultoConteudo(cultoId: '');
  CultoRelatorio _relatorio = const CultoRelatorio(cultoId: '');
  List<Ministerio> _ministerios = [];
  List<Pessoa> _pessoas = [];
  bool _loading = true;
  bool _savingStatus = false;
  bool _savingConteudo = false;
  bool _savingRelatorio = false;
  String? _error;

  late final TextEditingController _tema;
  late final TextEditingController _texto;
  late final TextEditingController _louvor;
  String? _pregadorId;
  late final TextEditingController _rAdultos;
  late final TextEditingController _rCriancas;
  late final TextEditingController _rConversoes;
  late final TextEditingController _rReconciliacoes;
  late final TextEditingController _rAliancas;
  late final TextEditingController _rCarros;
  late final TextEditingController _rMotos;
  late final TextEditingController _rBicicletas;
  late final TextEditingController _rObs;

  @override
  void initState() {
    super.initState();
    _tema = TextEditingController();
    _texto = TextEditingController();
    _louvor = TextEditingController();
    _rAdultos = TextEditingController();
    _rCriancas = TextEditingController();
    _rConversoes = TextEditingController();
    _rReconciliacoes = TextEditingController();
    _rAliancas = TextEditingController();
    _rCarros = TextEditingController();
    _rMotos = TextEditingController();
    _rBicicletas = TextEditingController();
    _rObs = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tema.dispose();
    _texto.dispose();
    _louvor.dispose();
    _rAdultos.dispose();
    _rCriancas.dispose();
    _rConversoes.dispose();
    _rReconciliacoes.dispose();
    _rAliancas.dispose();
    _rCarros.dispose();
    _rMotos.dispose();
    _rBicicletas.dispose();
    _rObs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        context.read<CultoService>().getById(widget.cultoId),
        context.read<CultoService>().getConteudo(widget.cultoId),
        context.read<CultoService>().getRelatorio(widget.cultoId),
        context.read<MinisterioService>().list(igrejaId: _igrejaId()),
        context.read<PessoaService>().list(size: 100, igrejaId: _igrejaId()),
      ]);
      if (!mounted) return;
      final culto = results[0] as Culto;
      final conteudo = results[1] as CultoConteudo;
      final relatorio = results[2] as CultoRelatorio;
      final ministerios = results[3] as List<Ministerio>;
      final pessoas = (results[4] as PageResponse<Pessoa>).content;
      setState(() {
        _culto = culto;
        _conteudo = conteudo;
        _relatorio = relatorio;
        _ministerios = ministerios;
        _pessoas = pessoas;
        _tema.text = conteudo.tema ?? culto.tema ?? '';
        _texto.text = conteudo.textoPregacao ?? '';
        _louvor.text = conteudo.louvor ?? '';
        _pregadorId = conteudo.pregadorId ?? culto.pregadorId;
        _rAdultos.text = '${relatorio.adultos}';
        _rCriancas.text = '${relatorio.criancas}';
        _rConversoes.text = '${relatorio.conversoes}';
        _rReconciliacoes.text = '${relatorio.reconciliacoes}';
        _rAliancas.text = '${relatorio.aliancas}';
        _rCarros.text = '${relatorio.carros}';
        _rMotos.text = '${relatorio.motos}';
        _rBicicletas.text = '${relatorio.bicicletas}';
        _rObs.text = relatorio.observacoes ?? '';
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _igrejaId() => context.read<IgrejaContext>().selectedIgrejaId;

  Pessoa? _pessoaById(String? id) {
    if (id == null) return null;
    for (final p in _pessoas) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _mudarStatus(CultoStatus novo) async {
    final culto = _culto;
    if (culto == null) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar situação'),
        content: Text(
          'Mudar o status para "${cultoStatusLabel(novo)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    setState(() => _savingStatus = true);
    try {
      final updated = await context
          .read<CultoService>()
          .update(culto.copyWith(status: novo));
      if (mounted) setState(() => _culto = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _savingStatus = false);
    }
  }

  Future<void> _salvarConteudo() async {
    final culto = _culto;
    if (culto == null) return;
    final user = context.read<AuthProvider>().user;
    final canTexto = podeEditarTextoCulto(user, pregadorPessoaId: _pregadorId);
    final canLouvor = podeEditarLouvor(user, _ministerios);
    final canManage = isPastorOuAdmin(user);

    final temaAtual = _conteudo.tema ?? culto.tema ?? '';
    var mudou = false;
    String? textoParaEnviar;
    String? louvorParaEnviar;
    String? temaParaEnviar;
    String? pregadorParaEnviar;

    if (canTexto && _texto.text != (_conteudo.textoPregacao ?? '')) {
      textoParaEnviar = _texto.text;
      mudou = true;
    }
    if (canLouvor && _louvor.text != (_conteudo.louvor ?? '')) {
      louvorParaEnviar = _louvor.text;
      mudou = true;
    }
    if (canTexto && _tema.text != temaAtual) {
      temaParaEnviar = _tema.text;
      mudou = true;
    }
    final pregadorAtual = _conteudo.pregadorId ?? culto.pregadorId;
    if (canManage && _pregadorId != null && _pregadorId != pregadorAtual) {
      pregadorParaEnviar = _pregadorId;
      mudou = true;
    }

    if (!mudou) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nada para salvar.')));
      return;
    }

    setState(() => _savingConteudo = true);
    try {
      final saved = await context.read<CultoService>().saveConteudo(
            culto.id,
            textoPregacao: textoParaEnviar,
            louvor: louvorParaEnviar,
            tema: temaParaEnviar,
            pregadorPessoaId: pregadorParaEnviar,
          );
      if (!mounted) return;
      setState(() {
        _conteudo = saved;
        if (saved.pregadorNome != null) {
          _pregadorId = saved.pregadorId;
          _culto = _culto?.copyWith(
            pregadorId: saved.pregadorId,
            pregadorNome: saved.pregadorNome,
          );
        }
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Conteúdo salvo.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _savingConteudo = false);
    }
  }

  Future<void> _salvarRelatorio() async {
    final culto = _culto;
    if (culto == null) return;

    final numeros = <String, String>{
      'Adultos': _rAdultos.text,
      'Crianças': _rCriancas.text,
      'Conversões': _rConversoes.text,
      'Reconciliações': _rReconciliacoes.text,
      'Alianças': _rAliancas.text,
      'Carros': _rCarros.text,
      'Motos': _rMotos.text,
      'Bicicletas': _rBicicletas.text,
    };
    final valores = <String, int>{};
    for (final e in numeros.entries) {
      final v = int.tryParse(e.value.trim());
      if (v == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${e.key}" deve ser um número inteiro.')),
        );
        return;
      }
      if (v < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${e.key}" não pode ser negativo.')),
        );
        return;
      }
      valores[e.key] = v;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salvar relatório'),
        content: const Text(
          'Salvar o relatório marca o culto como Realizado e encerra a configuração. Continuar?',
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
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _savingRelatorio = true);
    final relatorio = CultoRelatorio(
      cultoId: culto.id,
      adultos: valores['Adultos']!,
      criancas: valores['Crianças']!,
      conversoes: valores['Conversões']!,
      reconciliacoes: valores['Reconciliações']!,
      aliancas: valores['Alianças']!,
      carros: valores['Carros']!,
      motos: valores['Motos']!,
      bicicletas: valores['Bicicletas']!,
      observacoes: _rObs.text.trim().isEmpty ? null : _rObs.text.trim(),
    );
    try {
      final saved = await context.read<CultoService>().saveRelatorio(relatorio);
      if (mounted) {
        setState(() {
          _relatorio = saved;
          _culto = _culto?.copyWith(
            status: CultoStatus.realizado,
            temRelatorio: true,
          );
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Relatório salvo.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _savingRelatorio = false);
    }
  }

  Future<void> _excluir() async {
    final culto = _culto;
    if (culto == null) return;
    if (culto.temRelatorio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é possível excluir um culto com relatório lançado.'),
        ),
      );
      return;
    }
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir culto'),
        content: Text('Excluir "${culto.titulo}"?'),
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
      await context.read<CultoService>().delete(culto.id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null || _culto == null) {
      return ErrorView(message: _error ?? 'Culto não encontrado.', onRetry: _load);
    }
    final culto = _culto!;
    final user = context.watch<AuthProvider>().user;
    final canManage = isPastorOuAdmin(user);
    final canTexto = podeEditarTextoCulto(user, pregadorPessoaId: _pregadorId);
    final canLouvor = podeEditarLouvor(user, _ministerios);

    return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PageHeader(
              title: culto.titulo,
              description:
                  '${culto.categoriaCultoTitulo} · ${formatDate(culto.data)} — ${formatHora(culto.horaInicio)}',
              actions: [
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Voltar'),
                ),
                if (canManage)
                  OutlinedButton(
                    onPressed: _savingStatus ? null : _excluir,
                    child: const Text('Excluir'),
                  ),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Situação', cultoStatusLabel(culto.status),
                        badge: true,
                        success: culto.status == CultoStatus.realizado),
                    _row('Categoria', culto.categoriaCultoTitulo),
                    _row('Data', formatDate(culto.data)),
                    _row('Horário',
                        '${formatHora(culto.horaInicio)}–${formatHora(culto.horaFim)}'),
                    _row('Tema', culto.tema ?? '—'),
                    _row('Pregador', culto.pregadorNome ?? '—'),
                    _row('Competência', formatCompetencia(culto.competencia)),
                    _row('Relatório', culto.temRelatorio ? 'Lançado' : 'Não lançado'),
                  ],
                ),
              ),
            ),
            if (canManage && culto.status != CultoStatus.realizado &&
                culto.status != CultoStatus.cancelado) ...[
              const SizedBox(height: 12),
              _acoesStatus(culto.status, _savingStatus),
            ],
            const SizedBox(height: 16),
            _cardConteudo(canTexto, canLouvor, canManage),
            const SizedBox(height: 16),
            _cardRelatorio(podeLancarContagem(user)),
          ],
        );
  }

  Widget _acoesStatus(CultoStatus status, bool saving) {
    Widget envolver(Widget child) => saving
        ? const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircularProgressIndicator(),
          )
        : child;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        switch (status) {
          CultoStatus.agendado => envolver(
              FilledButton.icon(
                onPressed: () => _mudarStatus(CultoStatus.aberto),
                icon: const Icon(Icons.lock_open),
                label: const Text('Abrir'),
              ),
            ),
          CultoStatus.aberto => envolver(
              OutlinedButton.icon(
                onPressed: () => _mudarStatus(CultoStatus.agendado),
                icon: const Icon(Icons.replay),
                label: const Text('Reagendar'),
              ),
            ),
          _ => const SizedBox.shrink(),
        },
        if (status == CultoStatus.agendado || status == CultoStatus.aberto)
          envolver(
            OutlinedButton.icon(
              onPressed: () => _mudarStatus(CultoStatus.cancelado),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar'),
            ),
          ),
      ],
    );
  }

  Widget _cardConteudo(bool canTexto, bool canLouvor, bool canManage) {
    final selPregadorFora = _pregadorId != null && _pessoaById(_pregadorId) == null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Conteúdo do culto', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Pastor/pregador edita o texto e o tema. Ministério de música edita o louvor.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tema,
              readOnly: !canTexto,
              decoration: const InputDecoration(labelText: 'Tema'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _texto,
              readOnly: !canTexto,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'Texto da pregação',
                hintText: canTexto ? 'Escreva aqui…' : 'Somente leitura',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _louvor,
              readOnly: !canLouvor,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Louvor',
                hintText: canLouvor ? 'Escreva aqui…' : 'Somente leitura',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _pregadorId,
              decoration: InputDecoration(
                labelText: 'Pregador',
                helperText: canManage
                    ? 'Trocar o pregador é permitido só a pastores/administradores'
                    : null,
              ),
              items: [
                if (selPregadorFora)
                  DropdownMenuItem<String?>(
                    value: _pregadorId,
                    child: Text(_culto?.pregadorNome ?? 'Pregador atual'),
                  ),
                for (final p in _pessoas)
                  DropdownMenuItem(value: p.id, child: Text(p.nome)),
              ],
              onChanged: canManage
                  ? (v) => setState(() => _pregadorId = v)
                  : null,
            ),
            if (canTexto || canLouvor || canManage) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _savingConteudo ? null : _salvarConteudo,
                  child: const Text('Salvar conteúdo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cardRelatorio(bool canManage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Relatório', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Campos ausentes são zerados no envio. Salvar marca o culto como Realizado.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _numField('Adultos', _rAdultos),
            _numField('Crianças', _rCriancas),
            _numField('Conversões', _rConversoes),
            _numField('Reconciliações', _rReconciliacoes),
            _numField('Alianças', _rAliancas),
            _numField('Carros', _rCarros),
            _numField('Motos', _rMotos),
            _numField('Bicicletas', _rBicicletas),
            const SizedBox(height: 12),
            TextField(
              controller: _rObs,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: 8),
Text(
                'Presentes: ${_relatorio.totalPresentes} · Veículos: ${_relatorio.totalVeiculos}',
                style: TextStyle(
                  fontSize: 12,
                  color: _culto!.status == CultoStatus.realizado
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
              ),
            if (canManage) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _savingRelatorio ? null : _salvarRelatorio,
                  child: const Text('Salvar relatório'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _row(String label, String value, {bool badge = false, bool success = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: badge
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(
                      label: value.toUpperCase(),
                      success: success,
                    ),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }
}
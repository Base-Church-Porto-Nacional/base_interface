import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/mensagem_aniversario_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/route_access.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_search.dart';

class MensagemAniversarioScreen extends StatefulWidget {
  const MensagemAniversarioScreen({super.key});

  @override
  State<MensagemAniversarioScreen> createState() =>
      _MensagemAniversarioScreenState();
}

class _MensagemAniversarioScreenState extends State<MensagemAniversarioScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  MensagemAniversario? _carregada;
  bool _loading = true;
  bool _saving = false;
  bool _editavel = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _editavel = canEditMensagemAniversario(
      context.read<AuthProvider>().user,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId ?? '';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await context
          .read<MensagemAniversarioService>()
          .get(igrejaId: igrejaId);
      _carregada = config;
      _controller.text = config.mensagem;
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _inserirVariavel(MensagemVariavel variavel) {
    final selecao = _controller.selection;
    final texto = _controller.text;
    final inicio = selecao.isValid ? selecao.start : texto.length;
    final fim = selecao.isValid ? selecao.end : texto.length;
    final proximo = texto.replaceRange(inicio, fim, variavel.placeholder);
    _controller.value = TextEditingValue(
      text: proximo,
      selection: TextSelection.collapsed(offset: inicio + variavel.placeholder.length),
    );
    _focus.requestFocus();
    setState(() {});
  }

  void _descartar() {
    _controller.text = _carregada?.mensagem ?? '';
    setState(() {});
  }

  Future<void> _salvar() async {
    final config = _carregada;
    if (config == null) return;
    setState(() => _saving = true);
    try {
      final saved = await context
          .read<MensagemAniversarioService>()
          .save(config.copyWith(mensagem: _controller.text));
      _carregada = saved;
      _controller.text = saved.mensagem;
      if (mounted) showSnack(context, 'Mensagem padrão salva.');
    } catch (e) {
      if (mounted) showSnack(context, '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTabs(
          currentPath: '/configuracoes/mensagem-aniversario',
          tabs: [
            ('/configuracoes/mensagem-aniversario', 'Mensagem de aniversário'),
          ],
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    return _corpo();
  }

  Widget _corpo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Mensagem de aniversário',
          description:
              'Defina o texto padrão do parabéns. A identificação dos aniversariantes e o envio ficam a cargo do servidor.',
          actions: [
            if (_editavel)
              FilledButton(
                onPressed: _saving ? null : _salvar,
                child: Text(_saving ? 'Salvando…' : 'Salvar mensagem'),
              ),
          ],
        ),
        if (!_editavel)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: StatusBadge(label: 'Somente leitura para o seu papel'),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focus,
                  readOnly: !_editavel,
                  minLines: 5,
                  maxLines: 12,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Mensagem padrão',
                    hintText:
                        'Feliz aniversário, [Nome]! Que Deus continue abençoando sua vida.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Variáveis disponíveis — toque para inserir no cursor',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final variavel in mensagemAniversarioVariaveis)
                      ActionChip(
                        label: Text(variavel.placeholder),
                        avatar: _editavel
                            ? null
                            : const Icon(Icons.lock_outline, size: 14),
                        onPressed: _editavel ? () => _inserirVariavel(variavel) : null,
                        tooltip: variavel.rotulo,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => _previa(value.text),
        ),
        if (_editavel && _temAlteracoes()) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _descartar,
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Descartar alterações'),
            ),
          ),
        ],
      ],
    );
  }

  bool _temAlteracoes() =>
      _carregada != null && _controller.text.trim() != _carregada!.mensagem.trim();

  Widget _previa(String texto) {
    final formatada = formatarMensagemAniversario(texto);
    final usaNome = mensagemUsaVariavel(texto, 'Nome');
    final vazia = formatada.trim().isEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pré-visualização',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Exemplo com nome de exemplo — o servidor troca pelo nome de cada membro.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: vazia
                  ? Text(
                      'A mensagem formatada aparece aqui.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : Text(formatada, style: Theme.of(context).textTheme.bodyLarge),
            ),
            if (!vazia && !usaNome) ...[
              const SizedBox(height: 12),
              const StatusBadge(label: 'A mensagem não usa [Nome]', success: false),
            ],
          ],
        ),
      ),
    );
  }
}

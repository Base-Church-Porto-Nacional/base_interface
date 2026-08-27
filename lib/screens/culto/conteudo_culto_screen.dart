import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/conteudo_culto_service.dart';
import '../../services/cronograma_service.dart';
import '../../services/ministerio_service.dart';
import '../../utils/format.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';

class ConteudoCultoScreen extends StatefulWidget {
  const ConteudoCultoScreen({super.key, this.eventoId});

  final String? eventoId;

  @override
  State<ConteudoCultoScreen> createState() => _ConteudoCultoScreenState();
}

class _ConteudoCultoScreenState extends State<ConteudoCultoScreen> {
  List<CultoEvento> _cultos = [];
  List<Ministerio> _ministerios = [];
  String? _eventoId;
  ConteudoCulto? _conteudo;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  late final TextEditingController _texto;
  late final TextEditingController _louvor;

  @override
  void initState() {
    super.initState();
    _eventoId = widget.eventoId;
    _texto = TextEditingController();
    _louvor = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLista());
  }

  @override
  void dispose() {
    _texto.dispose();
    _louvor.dispose();
    super.dispose();
  }

  Future<void> _loadLista() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        context.read<CronogramaService>().list(igrejaId: igrejaId),
        context.read<MinisterioService>().list(igrejaId: igrejaId),
      ]);
      final eventos = (results[0] as List<CultoEvento>)
          .where((e) => e.tipo == TipoEvento.culto)
          .toList();
      if (!mounted) return;
      setState(() {
        _cultos = eventos;
        _ministerios = results[1] as List<Ministerio>;
        _eventoId ??= eventos.isNotEmpty ? eventos.first.id : null;
      });
      if (_eventoId != null) await _loadConteudo(_eventoId!);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadConteudo(String id) async {
    final c = await context.read<ConteudoCultoService>().getByEvento(id);
    if (!mounted) return;
    _texto.text = c.textoPregacao;
    _louvor.text = c.louvor;
    setState(() {
      _eventoId = id;
      _conteudo = c;
    });
  }

  Future<void> _save({required bool texto, required bool louvor}) async {
    final id = _eventoId;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      final current = _conteudo ?? ConteudoCulto(eventoId: id, textoPregacao: '', louvor: '');
      final saved = await context.read<ConteudoCultoService>().save(
            current.copyWith(
              textoPregacao: texto ? _texto.text : current.textoPregacao,
              louvor: louvor ? _louvor.text : current.louvor,
            ),
          );
      if (mounted) {
        setState(() => _conteudo = saved);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conteúdo salvo.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copy(String label, String value) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copiado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canTexto = podeEditarTextoCulto(user, pregadorPessoaId: _conteudo?.pregadorPessoaId);
    final canLouvor = podeEditarLouvor(user, _ministerios);
    final midia = soLeituraConteudoCulto(user, _ministerios) ||
        podeVerConteudoMidia(user, _ministerios);
    final readOnly = !canTexto && !canLouvor && midia;

    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _loadLista);

    CultoEvento? culto;
    for (final c in _cultos) {
      if (c.id == _eventoId) culto = c;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Gestão de culto',
          description: readOnly
              ? 'Mídia: pregação e louvor em somente leitura, com cópia.'
              : 'Pastor/pregador informa o texto. Música informa o louvor.',
        ),
        if (_cultos.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Nenhum culto para gerenciar.')),
          )
        else ...[
          DropdownButtonFormField<String>(
            value: _eventoId,
            decoration: const InputDecoration(labelText: 'Culto'),
            items: [
              for (final c in _cultos)
                DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.titulo} · ${formatDate(c.data)}'),
                ),
            ],
            onChanged: (v) {
              if (v != null) _loadConteudo(v);
            },
          ),
          if (culto != null) ...[
            const SizedBox(height: 8),
            Text(
              'Supervisor: ${culto.supervisorNome}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          _section(
            title: 'Texto do culto (slides)',
            controller: _texto,
            editable: canTexto,
            onSave: canTexto ? () => _save(texto: true, louvor: false) : null,
            onCopy: () => _copy('Texto', _texto.text),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Louvor',
            controller: _louvor,
            editable: canLouvor,
            onSave: canLouvor ? () => _save(texto: false, louvor: true) : null,
            onCopy: () => _copy('Louvor', _louvor.text),
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ],
    );
  }

  Widget _section({
    required String title,
    required TextEditingController controller,
    required bool editable,
    VoidCallback? onSave,
    required VoidCallback onCopy,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                IconButton(
                  tooltip: 'Copiar',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              readOnly: !editable,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: editable ? 'Escreva aqui…' : 'Somente leitura',
              ),
            ),
            if (onSave != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(onPressed: onSave, child: const Text('Salvar')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/models.dart';

/// Campo de busca por nome para escolher uma pessoa de uma lista grande.
///
/// Mostra até [maxSugestoes] pessoas, em ordem alfabética, cujo nome contém o
/// texto digitado (ignorando maiúsculas e acentos), com e-mail e telefone para
/// distinguir homônimos.
///
/// - [inicialId]: pessoa já escolhida; se não estiver em [pessoas], o campo
///   mostra [inicialNome].
/// - [permitirVazio]: com `true`, apagar ou alterar o texto depois de escolher
///   desfaz a escolha ([onChanged] com `null`). Com `false` (campo obrigatório
///   com valor padrão), a escolha nunca vira `null`: ao sair do campo sem
///   escolher outra pessoa, o texto volta para a escolhida.
class SeletorPessoa extends StatefulWidget {
  const SeletorPessoa({
    super.key,
    required this.pessoas,
    required this.label,
    required this.onChanged,
    this.inicialId,
    this.inicialNome,
    this.enabled = true,
    this.permitirVazio = true,
    this.helperText = 'Digite parte do nome',
    this.maxSugestoes = 8,
  });

  final List<Pessoa> pessoas;
  final String label;
  final ValueChanged<String?> onChanged;
  final String? inicialId;
  final String? inicialNome;
  final bool enabled;
  final bool permitirVazio;
  final String? helperText;
  final int maxSugestoes;

  @override
  State<SeletorPessoa> createState() => _SeletorPessoaState();
}

class _SeletorPessoaState extends State<SeletorPessoa> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// Nome da pessoa escolhida (ou do valor inicial), `null` se nenhuma.
  String? _nomeEscolhido;

  late List<Pessoa> _ordenadas = _ordenar(widget.pessoas);

  static List<Pessoa> _ordenar(List<Pessoa> pessoas) => [...pessoas]
    ..sort((a, b) => normalizarBusca(a.nome).compareTo(normalizarBusca(b.nome)));

  @override
  void initState() {
    super.initState();
    final id = widget.inicialId;
    if (id != null) {
      Pessoa? inicial;
      for (final p in widget.pessoas) {
        if (p.id == id) inicial = p;
      }
      _nomeEscolhido = inicial?.nome ?? widget.inicialNome;
      _controller.text = _nomeEscolhido ?? '';
    }
    _focusNode.addListener(_aoMudarFoco);
  }

  @override
  void didUpdateWidget(SeletorPessoa oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pessoas, widget.pessoas)) _ordenadas = _ordenar(widget.pessoas);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_aoMudarFoco);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _aoMudarFoco() {
    if (_focusNode.hasFocus || widget.permitirVazio) return;
    final nome = _nomeEscolhido;
    if (nome != null && _controller.text != nome) _controller.text = nome;
  }

  Iterable<Pessoa> _sugestoes(TextEditingValue valor) {
    final termo = normalizarBusca(valor.text);
    final candidatas = termo.isEmpty
        ? _ordenadas
        : _ordenadas.where((p) => normalizarBusca(p.nome).contains(termo));
    return candidatas.take(widget.maxSugestoes);
  }

  void _aoDigitar(String texto) {
    if (!widget.permitirVazio) return;
    if (_nomeEscolhido != null && texto != _nomeEscolhido) {
      _nomeEscolhido = null;
      widget.onChanged(null);
    }
  }

  /// E-mail e telefone: distinguem pessoas com o mesmo nome.
  static String _contato(Pessoa p) =>
      [p.email, p.telefone].where((v) => v.trim().isNotEmpty).join(' · ');

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Pessoa>(
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (p) => p.nome,
      optionsBuilder: _sugestoes,
      onSelected: (p) {
        _nomeEscolhido = p.nome;
        widget.onChanged(p.id);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: widget.enabled ? widget.helperText : null,
          suffixIcon: const Icon(Icons.search),
        ),
        onChanged: _aoDigitar,
        onSubmitted: (_) => onSubmitted(),
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280, maxWidth: 400),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final p in options)
                  ListTile(
                    dense: true,
                    title: Text(p.nome),
                    subtitle: _contato(p).isEmpty ? null : Text(_contato(p)),
                    onTap: () => onSelected(p),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Minúsculas e sem acentos, para comparar nomes digitados.
String normalizarBusca(String texto) {
  const com = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const sem = 'aaaaaeeeeiiiiooooouuuucn';
  final buffer = StringBuffer();
  for (final c in texto.trim().toLowerCase().split('')) {
    final i = com.indexOf(c);
    buffer.write(i >= 0 ? sem[i] : c);
  }
  return buffer.toString();
}

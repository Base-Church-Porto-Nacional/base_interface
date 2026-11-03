import 'package:flutter/material.dart';

import '../models/models.dart';

/// Campo de busca por nome para escolher uma pessoa de uma lista grande.
///
/// Mostra até [maxSugestoes] pessoas que contêm o texto digitado (ignorando
/// maiúsculas e acentos). Ao escolher, chama [onChanged] com o id; se o texto
/// for alterado depois, a escolha é desfeita ([onChanged] com `null`).
class SeletorPessoa extends StatefulWidget {
  const SeletorPessoa({
    super.key,
    required this.pessoas,
    required this.label,
    required this.onChanged,
    this.maxSugestoes = 8,
  });

  final List<Pessoa> pessoas;
  final String label;
  final ValueChanged<String?> onChanged;
  final int maxSugestoes;

  @override
  State<SeletorPessoa> createState() => _SeletorPessoaState();
}

class _SeletorPessoaState extends State<SeletorPessoa> {
  Pessoa? _escolhida;

  Iterable<Pessoa> _sugestoes(TextEditingValue valor) {
    final termo = normalizarBusca(valor.text);
    final candidatas = termo.isEmpty
        ? widget.pessoas
        : widget.pessoas.where((p) => normalizarBusca(p.nome).contains(termo));
    return candidatas.take(widget.maxSugestoes);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Pessoa>(
      displayStringForOption: (p) => p.nome,
      optionsBuilder: _sugestoes,
      onSelected: (p) {
        _escolhida = p;
        widget.onChanged(p.id);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: 'Digite parte do nome',
          suffixIcon: const Icon(Icons.search),
        ),
        onChanged: (texto) {
          if (_escolhida != null && texto != _escolhida!.nome) {
            _escolhida = null;
            widget.onChanged(null);
          }
        },
        onSubmitted: (_) => onSubmitted(),
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

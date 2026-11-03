import 'package:flutter/material.dart';

import '../models/models.dart';
import 'seletor_pessoa.dart' show normalizarBusca;

/// Lista de presença com busca, para listas grandes de pessoas.
///
/// Quem está marcado aparece sempre no topo. Com até [limiteSemBusca] pessoas,
/// todas aparecem; acima disso, só as que combinam com o texto digitado
/// (até [maxResultados]), para a lista não ficar enorme.
class ListaPresenca extends StatefulWidget {
  const ListaPresenca({
    super.key,
    required this.pessoas,
    required this.marcados,
    required this.onChanged,
    this.limiteSemBusca = 30,
    this.maxResultados = 30,
  });

  final List<Pessoa> pessoas;
  final Set<String> marcados;
  final ValueChanged<Set<String>> onChanged;
  final int limiteSemBusca;
  final int maxResultados;

  @override
  State<ListaPresenca> createState() => _ListaPresencaState();
}

class _ListaPresencaState extends State<ListaPresenca> {
  String _termo = '';

  void _alternar(String id, bool marcar) {
    final novos = {...widget.marcados};
    if (marcar) {
      novos.add(id);
    } else {
      novos.remove(id);
    }
    widget.onChanged(novos);
  }

  Widget _item(Pessoa p) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    controlAffinity: ListTileControlAffinity.leading,
    title: Text(p.nome),
    value: widget.marcados.contains(p.id),
    onChanged: (v) => _alternar(p.id, v == true),
  );

  @override
  Widget build(BuildContext context) {
    final ordenadas = [...widget.pessoas]
      ..sort((a, b) => normalizarBusca(a.nome).compareTo(normalizarBusca(b.nome)));
    final marcadas = ordenadas.where((p) => widget.marcados.contains(p.id)).toList();
    final naoMarcadas = ordenadas.where((p) => !widget.marcados.contains(p.id));

    final termo = normalizarBusca(_termo);
    final listaPequena = widget.pessoas.length <= widget.limiteSemBusca;
    final candidatas = termo.isEmpty
        ? (listaPequena ? naoMarcadas : const <Pessoa>[])
        : naoMarcadas.where((p) => normalizarBusca(p.nome).contains(termo));
    final resultados = candidatas.take(widget.maxResultados).toList();
    final total = widget.marcados.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          total == 1 ? '1 presente' : '$total presentes',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Buscar pessoa',
            isDense: true,
            suffixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _termo = v),
        ),
        const SizedBox(height: 4),
        for (final p in marcadas) _item(p),
        if (marcadas.isNotEmpty && resultados.isNotEmpty) const Divider(height: 8),
        for (final p in resultados) _item(p),
        if (termo.isEmpty && !listaPequena)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Digite o nome para marcar quem compareceu.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else if (termo.isNotEmpty && resultados.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Ninguém encontrado com esse nome.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

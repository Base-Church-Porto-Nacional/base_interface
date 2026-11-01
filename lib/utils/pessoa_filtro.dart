import '../models/models.dart';

const tipoFiltros = {
  'VISITANTE',
  'MEMBRO',
  'VOLUNTARIO',
  'LIDER',
  'PASTOR',
};

bool pessoaMatchesFiltro(Pessoa pessoa, String? filtro) {
  final value = filtro?.trim().toUpperCase();
  if (value == null || value.isEmpty || value == 'TODOS') return true;

  if (tipoFiltros.contains(value)) {
    final tipo = _tipoFromFiltro(value);
    return tipo != null && pessoa.tipos.contains(tipo);
  }

  return switch (value) {
    'BATIZADO' => pessoa.batizado,
    'ACEITOU_JESUS' => pessoa.aceitouJesus,
    'TRILHA' => pessoa.concluiuTrilhaBase,
    _ => false,
  };
}

PessoaTipo? _tipoFromFiltro(String value) {
  switch (value) {
    case 'VISITANTE':
      return PessoaTipo.visitante;
    case 'MEMBRO':
      return PessoaTipo.membro;
    case 'VOLUNTARIO':
      return PessoaTipo.voluntario;
    case 'LIDER':
      return PessoaTipo.lider;
    case 'PASTOR':
      return PessoaTipo.pastor;
    default:
      return null;
  }
}

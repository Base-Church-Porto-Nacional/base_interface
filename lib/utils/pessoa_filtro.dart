import '../models/models.dart';

const tipoFiltros = {
  'VISITANTE',
  'MEMBRO',
  'VOLUNTARIO',
  'LIDER',
  'PASTOR',
};

bool etapaConcluida(Pessoa pessoa, String trecho) {
  final needle = trecho.toLowerCase();
  return pessoa.jornada.any(
    (e) =>
        e.status == JornadaEtapaStatus.concluido &&
        e.titulo.toLowerCase().contains(needle),
  );
}

bool pessoaMatchesFiltro(Pessoa pessoa, String? filtro) {
  final value = filtro?.trim().toUpperCase();
  if (value == null || value.isEmpty || value == 'TODOS') return true;

  if (tipoFiltros.contains(value)) {
    final tipo = _tipoFromFiltro(value);
    return tipo != null && pessoa.tipos.contains(tipo);
  }

  switch (value) {
    case 'COM_ACESSO':
      return pessoa.acessoStatus != null;
    case 'BATIZADO':
      return etapaConcluida(pessoa, 'batiz');
    case 'ACEITOU_JESUS':
      return etapaConcluida(pessoa, 'aceitou') ||
          etapaConcluida(pessoa, 'jesus');
    case 'TRILHA':
      return etapaConcluida(pessoa, 'trilha');
    default:
      return false;
  }
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

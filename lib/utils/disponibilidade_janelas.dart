import '../models/models.dart';

class JanelaDisponivel {
  const JanelaDisponivel({
    required this.dia,
    required this.inicioMin,
    required this.fimMin,
  });

  final DiaSemana dia;
  final int inicioMin;
  final int fimMin;

  String get horaInicio => formatHoraMinutos(inicioMin);
  String get horaFim => formatHoraMinutos(fimMin);
}

const _fimDoDia = 23 * 60 + 59;

const _periodos = [(0, 12 * 60), (12 * 60, 18 * 60), (18 * 60, _fimDoDia)];

List<bool> _bloqueios(IndisponibilidadeSemanal? d) => [
  d?.manha ?? false,
  d?.tarde ?? false,
  d?.noite ?? false,
];

List<JanelaDisponivel> janelasDisponiveis(
  List<IndisponibilidadeSemanal> semanal,
) {
  if (!semanal.any((d) => d.marcado)) return const [];

  final janelas = <JanelaDisponivel>[];
  for (final dia in DiaSemana.values) {
    final registro = semanal.where((d) => d.dia == dia).firstOrNull;
    final bloqueado = _bloqueios(registro);
    int? inicio;
    int? fim;
    for (var i = 0; i < _periodos.length; i++) {
      if (bloqueado[i]) {
        if (inicio != null) {
          janelas.add(
            JanelaDisponivel(dia: dia, inicioMin: inicio, fimMin: fim!),
          );
          inicio = null;
        }
        continue;
      }
      inicio ??= _periodos[i].$1;
      fim = _periodos[i].$2;
    }
    if (inicio != null) {
      janelas.add(JanelaDisponivel(dia: dia, inicioMin: inicio, fimMin: fim!));
    }
  }
  return janelas;
}

List<IndisponibilidadeSemanal> indisponibilidadesDasJanelas(
  List<JanelaDisponivel> janelas,
) {
  if (janelas.isEmpty) return const [];

  final result = <IndisponibilidadeSemanal>[];
  for (final dia in DiaSemana.values) {
    final doDia = janelas.where((j) => j.dia == dia).toList();
    bool livre(int i) => doDia.any(
      (j) => j.inicioMin <= _periodos[i].$1 && j.fimMin >= _periodos[i].$2,
    );
    final item = IndisponibilidadeSemanal(
      dia: dia,
      manha: !livre(0),
      tarde: !livre(1),
      noite: !livre(2),
    );
    if (item.marcado) result.add(item);
  }
  return result;
}

int? parseHoraMinutos(String? value) {
  if (value == null) return null;
  final partes = value.split(':');
  if (partes.length < 2) return null;
  final h = int.tryParse(partes[0]);
  final m = int.tryParse(partes[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

String formatHoraMinutos(int minutos) {
  final h = (minutos ~/ 60).toString().padLeft(2, '0');
  final m = (minutos % 60).toString().padLeft(2, '0');
  return '$h:$m:00';
}

import 'package:intl/intl.dart';

final _dateBr = DateFormat('dd/MM/yyyy');
final _dateShort = DateFormat('dd/MM');

const mesesPt = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

String formatDate(String iso) {
  try {
    final date = DateTime.parse(iso);
    return _dateBr.format(date);
  } catch (_) {
    return iso;
  }
}

String formatDateShort(String iso) {
  try {
    final date = DateTime.parse(iso);
    return _dateShort.format(date);
  } catch (_) {
    return iso;
  }
}

String formatCompetencia(String yyyyMm) {
  final parts = yyyyMm.split('-');
  if (parts.length < 2) return yyyyMm;
  final month = int.tryParse(parts[1]) ?? 1;
  return '${mesesPt[(month - 1).clamp(0, 11)]} ${parts[0]}';
}

String competenciaFrom(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  return '${date.year}-$m';
}

List<DateTime> sundaysInMonth(int year, int month) {
  final first = DateTime(year, month, 1);
  final days = DateTime(year, month + 1, 0).day;
  final result = <DateTime>[];
  for (var d = 1; d <= days; d++) {
    final date = DateTime(year, month, d);
    if (date.weekday == DateTime.sunday) result.add(date);
  }
  if (first.weekday == DateTime.sunday && result.isEmpty) {
    result.add(first);
  }
  return result;
}

String isoDate(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

String formatHora(String? hora) {
  if (hora == null || hora.isEmpty) return '';
  if (hora.length >= 5) return hora.substring(0, 5);
  return hora;
}

String normalizeHoraApi(String hora) {
  final h = hora.trim();
  if (h.isEmpty) return h;
  final parts = h.split(':');
  if (parts.length == 2) return '$h:00';
  return h;
}

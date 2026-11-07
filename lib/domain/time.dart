// Utilidades de fecha/hora.
//
// Las horas de las tareas se guardan como hora local de pared ("wall clock")
// más el nombre de la zona horaria (RNF-11). En Dart se representan con
// DateTime locales construidos por componentes: DateTime(y, m, d, h, min).
// Toda la aritmética de días se hace por componentes para que el cambio de
// horario de verano no desplace las tareas.

/// Solo la fecha (00:00) de [d].
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [d] + [days] días conservando la hora de pared.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days, d.hour, d.minute, d.second);

/// [d] + [months] meses (día recortado al último del mes).
DateTime addMonthsClamped(DateTime d, int months) {
  final first = DateTime(d.year, d.month + months, 1);
  final day = d.day.clamp(1, daysInMonth(first.year, first.month));
  return DateTime(first.year, first.month, day, d.hour, d.minute);
}

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Días naturales entre las fechas de [a] y [b] (b − a), sin efecto del DST.
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Lunes (o domingo, si [weekStartsMonday] es false) de la semana de [d].
DateTime startOfWeek(DateTime d, {bool weekStartsMonday = true}) {
  final wd = d.weekday; // 1 = lunes
  final offset = weekStartsMonday ? wd - 1 : wd % 7;
  return DateTime(d.year, d.month, d.day - offset);
}

/// Número de semana ISO 8601.
int isoWeekNumber(DateTime d) {
  final thursday = DateTime(d.year, d.month, d.day - d.weekday + 4);
  final firstJan = DateTime(thursday.year, 1, 1);
  return daysBetween(firstJan, thursday) ~/ 7 + 1;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `yyyy-MM-dd`.
String formatDateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${_two(d.month)}-${_two(d.day)}';

DateTime parseDateKey(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// `yyyyMMdd` (formato de UNTIL en RRULE).
String formatCompactDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${_two(d.month)}${_two(d.day)}';

DateTime parseCompactDate(String s) => DateTime(
      int.parse(s.substring(0, 4)),
      int.parse(s.substring(4, 6)),
      int.parse(s.substring(6, 8)),
    );

/// Hora de pared como texto `yyyy-MM-ddTHH:mm` (sin zona).
String formatWallClock(DateTime d) =>
    '${formatDateKey(d)}T${_two(d.hour)}:${_two(d.minute)}';

DateTime parseWallClock(String s) {
  final t = s.indexOf('T');
  if (t < 0) return parseDateKey(s);
  final date = parseDateKey(s.substring(0, t));
  final hm = s.substring(t + 1).split(':');
  return DateTime(
      date.year, date.month, date.day, int.parse(hm[0]), int.parse(hm[1]));
}

DateTime? tryParseWallClock(String? s) =>
    s == null || s.isEmpty ? null : parseWallClock(s);

/// Combina la fecha de [date] con la hora de [time].
DateTime withTimeOf(DateTime date, DateTime time) =>
    DateTime(date.year, date.month, date.day, time.hour, time.minute);

/// Minutos desde medianoche.
int minutesOfDay(DateTime d) => d.hour * 60 + d.minute;

/// Redondea [minutes] al múltiplo de [step] más cercano.
int snapMinutes(int minutes, [int step = 15]) =>
    ((minutes / step).round() * step);

/// Abstracción del reloj para poder probar la lógica que depende de "ahora".
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

class FixedClock implements Clock {
  FixedClock(this.value);
  DateTime value;
  @override
  DateTime now() => value;
}

// Motor de repetición: calcula al vuelo las ocurrencias de una serie dentro
// de un rango (no se guardan una a una). RF-19, RF-20, RF-21.

import '../time.dart';
import 'recurrence_rule.dart';

class RecurrenceEngine {
  const RecurrenceEngine._();

  /// Ocurrencias de la serie que empieza en [seriesStart] cuya fecha cae en
  /// [[from], [to]) (solo cuenta la fecha). Cada ocurrencia lleva la hora de
  /// pared de [seriesStart]. Ordenadas.
  static List<DateTime> occurrencesBetween(
    RecurrenceRule rule,
    DateTime seriesStart,
    DateTime from,
    DateTime to, {
    int maxResults = 5000,
  }) {
    final result = <DateTime>[];
    final fromDay = dateOnly(from);
    final toDay = dateOnly(to);
    if (!toDay.isAfter(fromDay)) return result;
    for (final occ in _generate(rule, seriesStart, fromDay)) {
      final day = dateOnly(occ);
      if (!day.isBefore(toDay)) break;
      if (!day.isBefore(fromDay)) {
        result.add(occ);
        if (result.length >= maxResults) break;
      }
    }
    return result;
  }

  /// Todas las ocurrencias desde el inicio (útil para listas «seleccionadas»).
  /// Limitado a [limit] o hasta [horizon].
  static List<DateTime> occurrences(
    RecurrenceRule rule,
    DateTime seriesStart, {
    DateTime? horizon,
    int limit = 500,
  }) {
    final out = <DateTime>[];
    for (final occ in _generate(rule, seriesStart, null)) {
      if (horizon != null && dateOnly(occ).isAfter(dateOnly(horizon))) break;
      out.add(occ);
      if (out.length >= limit) break;
    }
    return out;
  }

  /// ¿Cae una ocurrencia en la fecha [day]?
  static bool occursOn(RecurrenceRule rule, DateTime seriesStart, DateTime day) {
    final d = dateOnly(day);
    return occurrencesBetween(rule, seriesStart, d, addDays(d, 1)).isNotEmpty;
  }

  /// Número de ocurrencias anteriores a [day] (para partir series con COUNT).
  static int countBefore(RecurrenceRule rule, DateTime seriesStart, DateTime day) {
    final d = dateOnly(day);
    var n = 0;
    for (final occ in _generate(rule, seriesStart, null)) {
      if (!dateOnly(occ).isBefore(d)) break;
      n++;
    }
    return n;
  }

  /// Primera ocurrencia en o después de [day], o null si la serie ha acabado.
  static DateTime? nextOnOrAfter(
      RecurrenceRule rule, DateTime seriesStart, DateTime day) {
    final d = dateOnly(day);
    for (final occ in _generate(rule, seriesStart, d)) {
      if (!dateOnly(occ).isBefore(d)) return occ;
    }
    return null;
  }

  /// Generador perezoso de ocurrencias, en orden. Si [hint] se da y la regla
  /// no tiene COUNT, salta directamente cerca de [hint] para no recorrer años.
  static Iterable<DateTime> _generate(
      RecurrenceRule rule, DateTime start, DateTime? hint) sync* {
    final startDay = dateOnly(start);
    final until = rule.until == null ? null : dateOnly(rule.until!);
    final count = rule.count;
    var emitted = 0;
    final hour = start.hour;
    final minute = start.minute;

    DateTime at(int y, int m, int d) => DateTime(y, m, d, hour, minute);

    // Periodo inicial (k). Con COUNT hay que contar desde el principio.
    var k = 0;
    if (hint != null && count == null && hint.isAfter(startDay)) {
      switch (rule.freq) {
        case Frequency.daily:
          k = daysBetween(startDay, hint) ~/ rule.interval;
        case Frequency.weekly:
          final w0 = startOfWeek(startDay);
          k = (daysBetween(w0, hint) ~/ 7) ~/ rule.interval;
        case Frequency.monthly:
          final months =
              (hint.year - startDay.year) * 12 + hint.month - startDay.month;
          k = months ~/ rule.interval;
        case Frequency.yearly:
          k = (hint.year - startDay.year) ~/ rule.interval;
      }
      k = k > 0 ? k - 1 : 0;
    }

    // Tope de seguridad: series sin fin se cortan a 200 años.
    final hardLimit = DateTime(startDay.year + 200);

    while (true) {
      final candidates = <DateTime>[];
      switch (rule.freq) {
        case Frequency.daily:
          final d = DateTime(
              startDay.year, startDay.month, startDay.day + k * rule.interval);
          candidates.add(at(d.year, d.month, d.day));
        case Frequency.weekly:
          final w0 = startOfWeek(startDay);
          final weekStart =
              DateTime(w0.year, w0.month, w0.day + 7 * k * rule.interval);
          final days = rule.byWeekdays.isEmpty
              ? [startDay.weekday]
              : (rule.byWeekdays.toList()..sort());
          for (final wd in days) {
            final d = DateTime(
                weekStart.year, weekStart.month, weekStart.day + wd - 1);
            candidates.add(at(d.year, d.month, d.day));
          }
        case Frequency.monthly:
          final first = DateTime(startDay.year, startDay.month + k * rule.interval, 1);
          final dim = daysInMonth(first.year, first.month);
          if (rule.isPositional) {
            final day = _nthWeekdayOfMonth(
                first.year, first.month, rule.byPosWeekday!, rule.bySetPos!);
            if (day != null) candidates.add(at(first.year, first.month, day));
          } else {
            final day = rule.byMonthDay ?? startDay.day;
            // Si el mes no tiene ese día (31 en febrero), se salta (RF-20).
            if (day <= dim) candidates.add(at(first.year, first.month, day));
          }
        case Frequency.yearly:
          final y = startDay.year + k * rule.interval;
          final m = startDay.month;
          final day = startDay.day;
          if (day <= daysInMonth(y, m)) candidates.add(at(y, m, day));
      }

      for (final c in candidates) {
        final cd = dateOnly(c);
        if (cd.isBefore(startDay)) continue;
        if (until != null && cd.isAfter(until)) return;
        if (cd.isAfter(hardLimit)) return;
        yield c;
        emitted++;
        if (count != null && emitted >= count) return;
      }
      k++;
      // Salvaguarda ante bucles sin candidatos.
      if (k > 200 * 400) return;
    }
  }

  /// Día del mes del n-ésimo [weekday] (n = 1..5, o -1 = último).
  static int? _nthWeekdayOfMonth(int year, int month, int weekday, int n) {
    final dim = daysInMonth(year, month);
    if (n > 0) {
      final firstWd = DateTime(year, month, 1).weekday;
      final day = 1 + (weekday - firstWd + 7) % 7 + (n - 1) * 7;
      return day <= dim ? day : null;
    } else {
      final lastWd = DateTime(year, month, dim).weekday;
      final day = dim - (lastWd - weekday + 7) % 7 + (n + 1) * 7;
      return day >= 1 ? day : null;
    }
  }
}

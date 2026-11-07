// RF-15: detección de solapamientos y reparto en columnas lado a lado.

import 'snapshot.dart';

class _Interval {
  _Interval(this.item, this.start, this.end);
  final Occurrence item;
  final DateTime start;
  final DateTime end;
}

/// Posición horizontal de un bloque dentro de su grupo de solapamiento.
class LaidOutBlock {
  const LaidOutBlock(this.occurrence, this.column, this.columns);
  final Occurrence occurrence;
  final int column;
  final int columns;
}

bool overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) =>
    aStart.isBefore(bEnd) && bStart.isBefore(aEnd);

/// Ocurrencias con hora (no «todo el día») que chocan con [start, end).
List<Occurrence> findConflicts(
  Iterable<Occurrence> others,
  DateTime start,
  DateTime end, {
  String? excludeKey,
}) {
  return [
    for (final o in others)
      if (o.key != excludeKey &&
          !o.task.allDay &&
          o.start != null &&
          overlaps(start, end, o.start!, o.end!))
        o,
  ];
}

/// Reparte bloques con hora en columnas: los que se solapan quedan lado a lado.
List<LaidOutBlock> layoutDay(List<Occurrence> items) {
  final timed = [
    for (final o in items)
      if (!o.task.allDay && o.start != null) _Interval(o, o.start!, o.end!),
  ]..sort((a, b) {
      final c = a.start.compareTo(b.start);
      return c != 0 ? c : b.end.compareTo(a.end);
    });

  final result = <LaidOutBlock>[];
  var group = <_Interval>[];
  final columnsEnd = <DateTime>[];
  final columnOf = <_Interval, int>{};
  DateTime? groupEnd;

  void flush() {
    final n = columnsEnd.length;
    for (final it in group) {
      result.add(LaidOutBlock(it.item, columnOf[it]!, n));
    }
    group = [];
    columnsEnd.clear();
    columnOf.clear();
    groupEnd = null;
  }

  for (final it in timed) {
    if (groupEnd != null && !it.start.isBefore(groupEnd!)) flush();
    var col = -1;
    for (var i = 0; i < columnsEnd.length; i++) {
      if (!it.start.isBefore(columnsEnd[i])) {
        col = i;
        break;
      }
    }
    if (col == -1) {
      columnsEnd.add(it.end);
      col = columnsEnd.length - 1;
    } else {
      columnsEnd[col] = it.end;
    }
    columnOf[it] = col;
    group.add(it);
    if (groupEnd == null || it.end.isAfter(groupEnd!)) groupEnd = it.end;
  }
  flush();
  return result;
}

/// RF-50: primer hueco libre de [durationMin] minutos desde [from], entre
/// [dayStartMin] y [dayEndMin] de cada día, mirando [days] días.
DateTime? findFreeSlot(
  List<Occurrence> Function(DateTime day) occurrencesOnDay,
  DateTime from,
  int durationMin, {
  int dayStartMin = 9 * 60,
  int dayEndMin = 21 * 60,
  int days = 7,
  int stepMin = 15,
}) {
  for (var i = 0; i < days; i++) {
    final day = DateTime(from.year, from.month, from.day + i);
    final busy = [
      for (final o in occurrencesOnDay(day))
        if (!o.task.allDay && o.start != null && !o.completed) (o.start!, o.end!),
    ];
    var m = dayStartMin;
    if (i == 0) {
      final nowMin = from.hour * 60 + from.minute;
      if (nowMin > m) m = ((nowMin + stepMin - 1) ~/ stepMin) * stepMin;
    }
    for (; m + durationMin <= dayEndMin; m += stepMin) {
      final s = DateTime(day.year, day.month, day.day, 0, m);
      final e = s.add(Duration(minutes: durationMin));
      if (busy.every((b) => !overlaps(s, e, b.$1, b.$2))) return s;
    }
  }
  return null;
}

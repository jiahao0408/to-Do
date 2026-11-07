// RF-49: rachas y estadísticas. Se calculan por ocurrencia (RF-27).

import 'models/task.dart';
import 'snapshot.dart';
import 'time.dart';

class Rate {
  const Rate(this.done, this.total);
  final int done;
  final int total;
  double get ratio => total == 0 ? 0 : done / total;
}

class HabitStat {
  const HabitStat(this.task, this.current, this.best, this.rate);
  final Task task;
  final int current;
  final int best;
  final Rate rate;
}

class CategoryTime {
  const CategoryTime(this.categoryId, this.estimatedMin, this.realMin);
  final int? categoryId;
  final int estimatedMin;
  final int realMin;
}

class Stats {
  Stats(this.snap, this.now, {this.weekStartsMonday = true});
  final AppSnapshot snap;
  final DateTime now;
  final bool weekStartsMonday;

  DateTime get today => dateOnly(now);

  /// Tasa de completado en [[from], [to]) (fechas), sin contar el futuro.
  Rate rate(DateTime from, DateTime to) {
    final end = to.isAfter(addDays(today, 1)) ? addDays(today, 1) : to;
    if (!end.isAfter(from)) return const Rate(0, 0);
    final occ = snap.occurrencesBetween(from, end);
    return Rate(occ.where((o) => o.completed).length, occ.length);
  }

  Rate get todayRate => rate(today, addDays(today, 1));
  Rate get weekRate {
    final ws = startOfWeek(today, weekStartsMonday: weekStartsMonday);
    return rate(ws, addDays(ws, 7));
  }

  Rate get monthRate => rate(DateTime(today.year, today.month, 1), DateTime(today.year, today.month + 1, 1));

  /// Tasa por día de los últimos [days] días (el último es hoy).
  List<(DateTime, Rate)> lastDays(int days) => [
        for (var i = days - 1; i >= 0; i--)
          (addDays(today, -i), rate(addDays(today, -i), addDays(today, -i + 1))),
      ];

  /// Racha de días seguidos completando todo. Un día sin tareas no rompe la
  /// racha ni suma. Hoy cuenta solo si ya está completo.
  (int current, int best) dayStreak({int lookback = 365}) {
    final from = addDays(today, -lookback);
    final occ = snap.occurrencesBetween(from, addDays(today, 1));
    final byDay = <String, List<Occurrence>>{};
    for (final o in occ) {
      (byDay[formatDateKey(o.task.start!)] ??= []).add(o);
    }
    var current = 0, best = 0, run = 0;
    var currentOpen = true;
    for (var i = 0; i <= lookback; i++) {
      final d = addDays(today, -i);
      final items = byDay[formatDateKey(d)];
      if (items == null || items.isEmpty) continue;
      final allDone = items.every((o) => o.completed);
      if (i == 0 && !allDone) continue; // hoy aún en curso
      if (allDone) {
        run++;
        if (currentOpen) current = run;
      } else {
        currentOpen = false;
        if (run > best) best = run;
        run = 0;
      }
    }
    if (run > best) best = run;
    if (current > best) best = current;
    return (current, best);
  }

  /// Rachas por tarea repetida (hábitos).
  List<HabitStat> habits({int lookback = 120}) {
    final out = <HabitStat>[];
    final from = addDays(today, -lookback);
    for (final t in snap.tasks.where((t) => t.isSeries)) {
      final occ = snap
          .occurrencesBetween(from, addDays(today, 1))
          .where((o) => o.taskId == t.id)
          .toList();
      if (occ.isEmpty) continue;
      var current = 0, best = 0, run = 0;
      var open = true;
      for (final o in occ.reversed) {
        final isToday = isSameDay(o.task.start!, now);
        if (isToday && !o.completed) continue;
        if (o.completed) {
          run++;
          if (open) current = run;
        } else {
          open = false;
          if (run > best) best = run;
          run = 0;
        }
      }
      if (run > best) best = run;
      out.add(HabitStat(t, current, best < current ? current : best,
          Rate(occ.where((o) => o.completed).length, occ.length)));
    }
    out.sort((a, b) => b.current.compareTo(a.current));
    return out;
  }

  /// Minutos reales dedicados (cronómetro) por tarea en [[from], [to]).
  int realMinutes({int? taskId, DateTime? from, DateTime? to}) {
    var total = 0;
    for (final e in snap.timeEntries) {
      if (taskId != null && e.taskId != taskId) continue;
      if (from != null && e.start.isBefore(from)) continue;
      if (to != null && !e.start.isBefore(to)) continue;
      total += e.elapsed(now).inMinutes;
    }
    return total;
  }

  /// Estimado vs. real por categoría en los últimos [days] días.
  List<CategoryTime> timeByCategory({int days = 30}) {
    final from = addDays(today, -days);
    final est = <int?, int>{};
    final real = <int?, int>{};
    for (final o in snap.occurrencesBetween(from, addDays(today, 1))) {
      if (!o.completed || o.task.estimateMin == null) continue;
      est[o.task.categoryId] = (est[o.task.categoryId] ?? 0) + o.task.estimateMin!;
    }
    for (final e in snap.timeEntries) {
      if (e.start.isBefore(from)) continue;
      final t = snap.taskById(e.taskId);
      if (t == null) continue;
      real[t.categoryId] = (real[t.categoryId] ?? 0) + e.elapsed(now).inMinutes;
    }
    final keys = {...est.keys, ...real.keys};
    return [for (final k in keys) CategoryTime(k, est[k] ?? 0, real[k] ?? 0)]
      ..sort((a, b) => (b.realMin + b.estimatedMin).compareTo(a.realMin + a.estimatedMin));
  }
}

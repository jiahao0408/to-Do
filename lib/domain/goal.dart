// Meta de la semana: ligada a un proyecto («p:ID») o a una categoría («c:ID»).
//   Proyecto  → avance total del proyecto + lo completado esta semana.
//   Categoría → tareas de esa categoría esta semana: hechas / totales.

import 'models/task.dart';
import 'snapshot.dart';
import 'time.dart';

class GoalProgress {
  const GoalProgress({
    required this.title,
    required this.color,
    required this.done,
    required this.total,
    required this.thisWeek,
    this.projectId,
  });
  final String title;
  final int color;
  final int done, total;

  /// Completadas esta semana.
  final int thisWeek;

  /// Si la meta es un proyecto, su id (para abrirlo).
  final int? projectId;

  double get ratio => total == 0 ? 0 : done / total;
}

/// null si no hay meta o ya no existe lo elegido.
GoalProgress? weeklyGoal(AppSnapshot s, String? raw, DateTime now, {bool weekStartsMonday = true}) {
  if (raw == null || raw.length < 3 || raw[1] != ':') return null;
  final id = int.tryParse(raw.substring(2));
  if (id == null) return null;
  final ws = startOfWeek(dateOnly(now), weekStartsMonday: weekStartsMonday);
  final we = addDays(ws, 7);
  bool inWeek(DateTime? d) {
    if (d == null) return false;
    final l = d.toLocal();
    return !l.isBefore(ws) && l.isBefore(we);
  }

  switch (raw[0]) {
    case 'p':
      final p = s.projectById(id);
      if (p == null) return null;
      final (done, total) = s.projectProgress(id);
      final tasks = s.tasksOfProject(id);
      final seriesIds = {for (final t in tasks.where((t) => t.isSeries)) t.id};
      final week = tasks.where((t) => !t.isSeries && t.isCompleted && inWeek(t.completedAt)).length +
          s.completions.where((c) => seriesIds.contains(c.seriesId) && inWeek(c.completedAt)).length;
      return GoalProgress(title: p.name, color: p.color, done: done, total: total, thisWeek: week, projectId: id);
    case 'c':
      final cat = s.categories.where((c) => c.id == id).firstOrNull;
      if (cat == null) return null;
      final occ = s.occurrencesBetween(ws, we).where((o) => o.task.categoryId == id && o.task.status != TaskStatus.discarded);
      final done = occ.where((o) => o.completed).length;
      return GoalProgress(title: cat.name, color: cat.color, done: done, total: occ.length, thisWeek: done);
  }
  return null;
}

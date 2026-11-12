// Meta de la semana: proyecto o categoría.
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/domain/goal.dart';
import 'package:todo_calendar/domain/models/entities.dart';
import 'package:todo_calendar/domain/models/task.dart';
import 'package:todo_calendar/domain/snapshot.dart';

void main() {
  final now = DateTime(2026, 11, 12, 20); // jueves
  Task t(int id, {DateTime? start, int? project, int? cat, DateTime? doneAt}) => Task(
        id: id,
        title: 'T$id',
        start: start,
        projectId: project,
        categoryId: cat,
        status: doneAt == null ? TaskStatus.pending : TaskStatus.completed,
        completedAt: doneAt,
        tz: 'UTC',
        createdAt: now,
        updatedAt: now,
      );

  AppSnapshot snap(List<Task> tasks) => AppSnapshot(
        tasks: tasks,
        subtasks: const [],
        categories: const [Category(id: 2, name: 'Salud', color: 7)],
        reminders: const [],
        attachments: const [],
        exceptions: const [],
        completions: const [],
        timeEntries: const [],
        templates: const [],
        settings: const {},
        projects: const [Project(id: 3, name: 'TFG', color: 5)],
      );

  test('sin meta o meta borrada: null', () {
    final s = snap([]);
    expect(weeklyGoal(s, null, now), isNull);
    expect(weeklyGoal(s, '', now), isNull);
    expect(weeklyGoal(s, 'p:99', now), isNull);
    expect(weeklyGoal(s, 'x:3', now), isNull);
  });

  test('proyecto: avance total y lo completado esta semana', () {
    final s = snap([
      t(1, project: 3, doneAt: DateTime(2026, 11, 3, 9)), // semana pasada
      t(2, project: 3, doneAt: DateTime(2026, 11, 10, 9)), // esta semana (lunes 9)
      t(3, project: 3),
      t(4, project: 3),
    ]);
    final g = weeklyGoal(s, 'p:3', now)!;
    expect(g.title, 'TFG');
    expect((g.done, g.total, g.thisWeek), (2, 4, 1));
    expect(g.ratio, 0.5);
    expect(g.projectId, 3);
  });

  test('categoría: tareas de esta semana hechas / totales', () {
    final s = snap([
      t(1, cat: 2, start: DateTime(2026, 11, 10, 9), doneAt: DateTime(2026, 11, 10, 10)),
      t(2, cat: 2, start: DateTime(2026, 11, 14, 9)),
      t(3, cat: 2, start: DateTime(2026, 11, 20, 9)), // semana siguiente
      t(4, start: DateTime(2026, 11, 11, 9)), // otra categoría
    ]);
    final g = weeklyGoal(s, 'c:2', now)!;
    expect(g.title, 'Salud');
    expect((g.done, g.total, g.thisWeek), (1, 2, 1));
    expect(g.projectId, isNull);
  });
}

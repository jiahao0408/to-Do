// RF-49: estadísticas y rachas.
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/domain/models/entities.dart';
import 'package:todo_calendar/domain/models/task.dart';
import 'package:todo_calendar/domain/snapshot.dart';
import 'package:todo_calendar/domain/stats.dart';

void main() {
  final now = DateTime(2026, 11, 7, 20);
  Task t(int id, DateTime start, {String? rrule, int? estimate, int? cat}) => Task(
        id: id,
        title: 'T$id',
        start: start,
        rrule: rrule,
        estimateMin: estimate,
        categoryId: cat,
        tz: 'UTC',
        createdAt: now,
        updatedAt: now,
      );
  OccurrenceCompletion c(int id, DateTime d) => OccurrenceCompletion(seriesId: id, occurrenceDate: d, completedAt: now);

  AppSnapshot snap(List<Task> tasks, {List<OccurrenceCompletion> comp = const [], List<TimeEntry> time = const []}) =>
      AppSnapshot(
        tasks: tasks,
        subtasks: const [],
        categories: const [],
        reminders: const [],
        attachments: const [],
        exceptions: const [],
        completions: comp,
        timeEntries: time,
        templates: const [],
        settings: const {},
      );

  test('hábito diario: racha actual y mejor', () {
    // Del 1 al 7 nov: completados 1,2,3, falla 4, completados 5,6; hoy (7) pendiente.
    final s = snap([t(1, DateTime(2026, 11, 1, 8), rrule: 'FREQ=DAILY')], comp: [
      for (final d in [1, 2, 3, 5, 6]) c(1, DateTime(2026, 11, d)),
    ]);
    final stats = Stats(s, now);
    final h = stats.habits().single;
    expect(h.current, 2);
    expect(h.best, 3);
    expect(h.rate.done, 5);
    expect(h.rate.total, 7);
    final (cur, best) = stats.dayStreak();
    expect(cur, 2);
    expect(best, 3);
  });

  test('hoy completo suma a la racha', () {
    final s = snap([t(1, DateTime(2026, 11, 5, 8), rrule: 'FREQ=DAILY')],
        comp: [for (final d in [5, 6, 7]) c(1, DateTime(2026, 11, d))]);
    expect(Stats(s, now).dayStreak().$1, 3);
  });

  test('tasas por periodo no cuentan el futuro', () {
    final done = t(1, DateTime(2026, 11, 7, 9)).copyWith(status: TaskStatus.completed);
    final s = snap([done, t(2, DateTime(2026, 11, 7, 12)), t(3, DateTime(2026, 11, 20, 9))]);
    final stats = Stats(s, now);
    expect(stats.todayRate.done, 1);
    expect(stats.todayRate.total, 2);
    expect(stats.monthRate.total, 2);
    expect(stats.lastDays(7).last.$2.total, 2);
  });

  test('estimado vs real por categoría', () {
    final a = t(1, DateTime(2026, 11, 6, 9), estimate: 60, cat: 5).copyWith(status: TaskStatus.completed);
    final s = snap([a], time: [
      TimeEntry(taskId: 1, start: DateTime(2026, 11, 6, 9), end: DateTime(2026, 11, 6, 10, 30)),
    ]);
    final ct = Stats(s, now).timeByCategory().single;
    expect(ct.categoryId, 5);
    expect(ct.estimatedMin, 60);
    expect(ct.realMin, 90);
    expect(Stats(s, now).realMinutes(taskId: 1), 90);
  });
}

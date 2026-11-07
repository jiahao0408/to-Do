// Tests de la programación de avisos (RF-43, RF-44, RF-46, RF-47).
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/domain/models/entities.dart';
import 'package:todo_calendar/domain/models/task.dart';
import 'package:todo_calendar/domain/notification_plan.dart';
import 'package:todo_calendar/domain/snapshot.dart';

AppSnapshot snap(List<Task> tasks, List<Reminder> reminders,
        {List<OccurrenceCompletion> completions = const []}) =>
    AppSnapshot(
      tasks: tasks,
      subtasks: const [],
      categories: const [],
      reminders: reminders,
      attachments: const [],
      exceptions: const [],
      completions: completions,
      timeEntries: const [],
      templates: const [],
      settings: const {},
    );

void main() {
  final now = DateTime(2026, 11, 7, 10);
  Task t(int id, DateTime start, {String? rrule, bool allDay = false}) => Task(
        id: id,
        title: 'T$id',
        start: start,
        rrule: rrule,
        allDay: allDay,
        tz: 'Europe/Madrid',
        createdAt: now,
        updatedAt: now,
      );

  test('RF-43/44 varios avisos por tarea, solo futuros', () {
    final s = snap([t(1, DateTime(2026, 11, 8, 9))], const [
      Reminder(taskId: 1, minutesBefore: 1440),
      Reminder(taskId: 1, minutesBefore: 15),
      Reminder(taskId: 1, minutesBefore: 2000), // ya pasado
    ]);
    final plan = const NotificationPlanner().plan(s, now, tz: 'Europe/Madrid');
    // 1 día antes = hoy 9:00, ya pasado; solo queda el de 15 min.
    expect(plan.map((p) => p.fireAt), [DateTime(2026, 11, 8, 8, 45)]);
    expect(plan.last.payload, 'task|1|');
    expect(plan.map((p) => p.id).toSet().length, plan.length, reason: 'ids únicos');
  });

  test('RF-47 límite de pendientes: se programan los más próximos', () {
    final s = snap(
      [t(1, DateTime(2026, 11, 7, 12), rrule: 'FREQ=DAILY')],
      const [Reminder(taskId: 1, minutesBefore: 0), Reminder(taskId: 1, minutesBefore: 30)],
    );
    final plan = const NotificationPlanner(maxPending: 10).plan(s, now, tz: 'UTC');
    expect(plan.length, 10);
    expect(plan.first.fireAt, DateTime(2026, 11, 7, 11, 30));
    for (var i = 1; i < plan.length; i++) {
      expect(!plan[i].fireAt.isBefore(plan[i - 1].fireAt), isTrue);
    }
    expect(plan.first.payload, 'task|1|2026-11-07');
  });

  test('ocurrencias completadas no avisan', () {
    final s = snap(
      [t(1, DateTime(2026, 11, 7, 12), rrule: 'FREQ=DAILY')],
      const [Reminder(taskId: 1, minutesBefore: 0)],
      completions: [OccurrenceCompletion(seriesId: 1, occurrenceDate: DateTime(2026, 11, 7), completedAt: now)],
    );
    final plan = const NotificationPlanner(horizonDays: 2).plan(s, now, tz: 'UTC');
    expect(plan.first.fireAt, DateTime(2026, 11, 8, 12));
  });

  test('RF-46 resúmenes reservan sitio', () {
    final s = snap([t(1, DateTime(2026, 11, 7, 12), rrule: 'FREQ=DAILY')],
        const [Reminder(taskId: 1, minutesBefore: 0)]);
    final plan = const NotificationPlanner(maxPending: 6).plan(s, now,
        tz: 'UTC',
        summaries: const SummarySettings(
            dailyEnabled: true, weeklyEnabled: true, weeklyWeekday: DateTime.monday, monthlyEnabled: true));
    final kinds = plan.map((p) => p.kind).toList();
    expect(kinds.where((k) => k == PlannedKind.dailySummary).length, 2, reason: 'hoy 8:00 ya pasó');
    expect(kinds, contains(PlannedKind.weeklySummary));
    expect(kinds, contains(PlannedKind.monthlySummary));
    expect(plan.length, 6);
    final monthly = plan.firstWhere((p) => p.kind == PlannedKind.monthlySummary);
    expect(monthly.fireAt, DateTime(2026, 12, 1, 8));
    final weekly = plan.firstWhere((p) => p.kind == PlannedKind.weeklySummary);
    expect(weekly.fireAt, DateTime(2026, 11, 9, 8));
  });

  test('todo el día avisa desde las 9:00', () {
    final s = snap([t(1, DateTime(2026, 11, 8), allDay: true)], const [Reminder(taskId: 1, minutesBefore: 60)]);
    final plan = const NotificationPlanner().plan(s, now, tz: 'UTC');
    expect(plan.single.fireAt, DateTime(2026, 11, 8, 8));
  });
}

// Foto en memoria de todos los datos. Una app personal tiene a lo sumo unos
// miles de tareas, así que cargar todo y calcular las ocurrencias al vuelo
// es rápido y simplifica la lógica.

import 'models/entities.dart';
import 'models/task.dart';
import 'recurrence/recurrence_engine.dart';
import 'time.dart';

class Occurrence {
  const Occurrence({
    required this.task,
    required this.series,
    required this.occurrenceDate,
    required this.completed,
    this.modified = false,
  });

  /// Tarea efectiva (con las sobrescrituras de la excepción aplicadas).
  final Task task;

  /// Tarea base guardada (igual a [task] si no es serie o no hay excepción).
  final Task series;

  /// Fecha original de la ocurrencia dentro de la serie (null si no es serie).
  final DateTime? occurrenceDate;
  final bool completed;
  final bool modified;

  bool get isSeries => series.isSeries;
  int get taskId => series.id!;
  DateTime? get start => task.start;
  DateTime? get end => task.end;

  /// Clave única de la ocurrencia.
  String get key => occurrenceDate == null
      ? '$taskId'
      : '$taskId@${formatDateKey(occurrenceDate!)}';

  @override
  bool operator ==(Object other) => other is Occurrence && other.key == key;
  @override
  int get hashCode => key.hashCode;
}

class AppSnapshot {
  AppSnapshot({
    required this.tasks,
    required this.subtasks,
    required this.categories,
    required this.reminders,
    required this.attachments,
    required this.exceptions,
    required this.completions,
    required this.timeEntries,
    required this.templates,
    required this.settings,
  }) {
    for (final e in exceptions) {
      (_exceptionsBySeries[e.seriesId] ??= {})[e.dateKey] = e;
    }
    for (final c in completions) {
      (_completionsBySeries[c.seriesId] ??= {})[formatDateKey(c.occurrenceDate)] = c;
    }
    for (final s in subtasks) {
      (_subtasksByTask[s.taskId] ??= []).add(s);
    }
    for (final list in _subtasksByTask.values) {
      list.sort((a, b) => a.order.compareTo(b.order));
    }
    for (final r in reminders) {
      (_remindersByTask[r.taskId] ??= []).add(r);
    }
    for (final a in attachments) {
      (_attachmentsByTask[a.taskId] ??= []).add(a);
    }
    for (final t in tasks) {
      _taskById[t.id!] = t;
    }
    for (final c in categories) {
      _categoryById[c.id!] = c;
    }
  }

  factory AppSnapshot.empty() => AppSnapshot(
        tasks: const [],
        subtasks: const [],
        categories: const [],
        reminders: const [],
        attachments: const [],
        exceptions: const [],
        completions: const [],
        timeEntries: const [],
        templates: const [],
        settings: const {},
      );

  final List<Task> tasks;
  final List<Subtask> subtasks;
  final List<Category> categories;
  final List<Reminder> reminders;
  final List<Attachment> attachments;
  final List<SeriesException> exceptions;
  final List<OccurrenceCompletion> completions;
  final List<TimeEntry> timeEntries;
  final List<TaskTemplate> templates;
  final Map<String, String> settings;

  final _exceptionsBySeries = <int, Map<String, SeriesException>>{};
  final _completionsBySeries = <int, Map<String, OccurrenceCompletion>>{};
  final _subtasksByTask = <int, List<Subtask>>{};
  final _remindersByTask = <int, List<Reminder>>{};
  final _attachmentsByTask = <int, List<Attachment>>{};
  final _taskById = <int, Task>{};
  final _categoryById = <int, Category>{};

  Task? taskById(int id) => _taskById[id];
  Category? categoryById(int? id) => id == null ? null : _categoryById[id];
  List<Subtask> subtasksOf(int taskId) => _subtasksByTask[taskId] ?? const [];
  List<Reminder> remindersOf(int taskId) => _remindersByTask[taskId] ?? const [];
  List<Attachment> attachmentsOf(int taskId) =>
      _attachmentsByTask[taskId] ?? const [];
  Map<String, SeriesException> exceptionsOf(int seriesId) =>
      _exceptionsBySeries[seriesId] ?? const {};
  Map<String, OccurrenceCompletion> completionsOf(int seriesId) =>
      _completionsBySeries[seriesId] ?? const {};
  List<TimeEntry> timeEntriesOf(int taskId) =>
      timeEntries.where((e) => e.taskId == taskId).toList();

  /// Tareas sin hora (bandeja, RF-02), pendientes.
  List<Task> get inbox => tasks
      .where((t) => t.isUnscheduled && t.status == TaskStatus.pending)
      .toList()
    ..sort(compareTasks);

  /// Ocurrencia concreta de una tarea (para abrir el detalle desde un aviso).
  Occurrence? occurrenceOf(int taskId, DateTime? date) {
    final t = taskById(taskId);
    if (t == null) return null;
    if (!t.isSeries || date == null) {
      if (t.isSeries) return null;
      return Occurrence(
        task: t,
        series: t,
        occurrenceDate: null,
        completed: t.isCompleted,
      );
    }
    final key = formatDateKey(date);
    final ex = exceptionsOf(taskId)[key];
    if (ex?.type == ExceptionType.skipped) return null;
    if (ex == null && !RecurrenceEngine.occursOn(t.rule!, t.start!, date)) {
      return null;
    }
    final eff = ex == null
        ? t.copyWith(start: () => withTimeOf(date, t.start!))
        : t
            .copyWith(start: () => withTimeOf(date, t.start!))
            .applyOverrides(ex.overrides);
    return Occurrence(
      task: eff,
      series: t,
      occurrenceDate: dateOnly(date),
      completed: completionsOf(taskId).containsKey(key),
      modified: ex != null,
    );
  }

  /// Ocurrencias cuyo inicio cae en [[from], [to]) (por fecha), con hora.
  /// Incluye las tareas completadas y excluye las descartadas.
  List<Occurrence> occurrencesBetween(DateTime from, DateTime to) {
    final fromDay = dateOnly(from);
    final toDay = dateOnly(to);
    final out = <Occurrence>[];
    bool inRange(DateTime d) {
      final day = dateOnly(d);
      return !day.isBefore(fromDay) && day.isBefore(toDay);
    }

    for (final t in tasks) {
      if (t.start == null || t.status == TaskStatus.discarded) continue;
      if (!t.isSeries) {
        if (inRange(t.start!)) {
          out.add(Occurrence(
            task: t,
            series: t,
            occurrenceDate: null,
            completed: t.isCompleted,
          ));
        }
        continue;
      }
      final rule = t.rule!;
      final exc = exceptionsOf(t.id!);
      final comp = completionsOf(t.id!);
      final seen = <String>{};
      for (final occ in RecurrenceEngine.occurrencesBetween(
          rule, t.start!, fromDay, toDay)) {
        final key = formatDateKey(occ);
        seen.add(key);
        final ex = exc[key];
        if (ex == null) {
          out.add(Occurrence(
            task: t.copyWith(start: () => occ),
            series: t,
            occurrenceDate: dateOnly(occ),
            completed: comp.containsKey(key),
          ));
        } else if (ex.type == ExceptionType.modified) {
          final eff = t.copyWith(start: () => occ).applyOverrides(ex.overrides);
          if (eff.start != null && inRange(eff.start!)) {
            out.add(Occurrence(
              task: eff,
              series: t,
              occurrenceDate: dateOnly(occ),
              completed: comp.containsKey(key),
              modified: true,
            ));
          }
        }
      }
      // Ocurrencias modificadas cuya fecha original está fuera del rango pero
      // que se movieron dentro de él.
      for (final ex in exc.values) {
        if (ex.type != ExceptionType.modified || seen.contains(ex.dateKey)) {
          continue;
        }
        if (!RecurrenceEngine.occursOn(rule, t.start!, ex.originalDate)) {
          continue;
        }
        final base = t.copyWith(start: () => withTimeOf(ex.originalDate, t.start!));
        final eff = base.applyOverrides(ex.overrides);
        if (eff.start != null && inRange(eff.start!)) {
          out.add(Occurrence(
            task: eff,
            series: t,
            occurrenceDate: ex.originalDate,
            completed: comp.containsKey(ex.dateKey),
            modified: true,
          ));
        }
      }
    }
    out.sort(compareOccurrences);
    return out;
  }

  List<Occurrence> occurrencesOnDay(DateTime day) =>
      occurrencesBetween(dateOnly(day), addDays(dateOnly(day), 1));

  /// Tareas atrasadas (RF-17): no completadas con fecha anterior a hoy.
  /// Para las series solo se miran los últimos [seriesLookbackDays] días, para
  /// no inundar el diálogo con hábitos diarios.
  List<Occurrence> overdue(DateTime now, {int seriesLookbackDays = 7}) {
    final today = dateOnly(now);
    final out = <Occurrence>[];
    for (final t in tasks) {
      if (t.start == null || t.isSeries) continue;
      if (t.status != TaskStatus.pending) continue;
      if (dateOnly(t.start!).isBefore(today)) {
        out.add(Occurrence(
            task: t, series: t, occurrenceDate: null, completed: false));
      }
    }
    final from = addDays(today, -seriesLookbackDays);
    for (final o in occurrencesBetween(from, today)) {
      if (o.isSeries && !o.completed) out.add(o);
    }
    out.sort(compareOccurrences);
    return out;
  }

  String? setting(String key) => settings[key];
}

int _priorityRank(Priority p) => switch (p) {
      Priority.high => 0,
      Priority.medium => 1,
      Priority.low => 2,
    };

/// Orden: todo el día primero, luego por hora y, a igual hora, por prioridad
/// (RF-07).
int compareOccurrences(Occurrence a, Occurrence b) {
  if (a.task.allDay != b.task.allDay) return a.task.allDay ? -1 : 1;
  final sa = a.task.start, sb = b.task.start;
  if (sa != null && sb != null) {
    final c = sa.compareTo(sb);
    if (c != 0) return c;
  }
  final p = _priorityRank(a.task.priority).compareTo(_priorityRank(b.task.priority));
  if (p != 0) return p;
  return a.task.title.compareTo(b.task.title);
}

int compareTasks(Task a, Task b) {
  if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
  final p = _priorityRank(a.priority).compareTo(_priorityRank(b.priority));
  if (p != 0) return p;
  return a.createdAt.compareTo(b.createdAt);
}

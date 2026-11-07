// Casos de uso sobre tareas: crear, editar y borrar con alcance (RF-23 a
// RF-26), completar (RF-04, RF-27), posponer (RF-14), duplicar (RF-13),
// plantillas (RF-16) y atrasadas (RF-17). Todas las operaciones que cambian
// datos devuelven un [UndoPoint] (RF-37).

import '../data/repository.dart';
import '../domain/models/entities.dart';
import '../domain/models/task.dart';
import '../domain/recurrence/recurrence_engine.dart';
import '../domain/recurrence/recurrence_rule.dart';
import '../domain/snapshot.dart';
import '../domain/time.dart';

/// Alcance al editar o borrar una ocurrencia de una serie.
enum SeriesScope { thisOne, thisAndFollowing, all, selected }

class TaskService {
  TaskService(this.repo);
  final Repository repo;

  DateTime get now => repo.now;

  // ----------------------------------------------------------------- crear

  Future<int> create(
    Task task, {
    List<Subtask> subtasks = const [],
    List<int> reminders = const [],
  }) {
    return repo.insertTask(task, subtasks: subtasks, reminders: reminders);
  }

  // ----------------------------------------------------------- completar

  Future<UndoPoint> setCompleted(Occurrence o, bool done) {
    return repo.withUndo([o.taskId], () async {
      if (o.isSeries && o.occurrenceDate != null) {
        await repo.setOccurrenceCompleted(o.taskId, o.occurrenceDate!, done);
      } else {
        await repo.updateTask(o.series.copyWith(
          status: done ? TaskStatus.completed : TaskStatus.pending,
          completedAt: () => done ? now : null,
        ));
      }
      return const [];
    });
  }

  Future<UndoPoint> setCompletedMany(List<Occurrence> items, bool done) {
    return repo.withUndo(items.map((o) => o.taskId), () async {
      for (final o in items) {
        if (o.isSeries && o.occurrenceDate != null) {
          await repo.setOccurrenceCompleted(o.taskId, o.occurrenceDate!, done);
        } else {
          final t = (await repo.loadTask(o.taskId)) ?? o.series;
          await repo.updateTask(t.copyWith(
            status: done ? TaskStatus.completed : TaskStatus.pending,
            completedAt: () => done ? now : null,
          ));
        }
      }
      return const [];
    });
  }

  // --------------------------------------------------------------- editar

  /// Guarda [edited] (la tarea efectiva editada) para la ocurrencia [o].
  /// Para tareas no repetidas, [scope] se ignora.
  Future<UndoPoint> edit(
    Occurrence o,
    Task edited, {
    SeriesScope scope = SeriesScope.all,
    List<DateTime> selectedDates = const [],
    List<Subtask>? subtasks,
    List<int>? reminders,
  }) {
    return repo.withUndo([o.taskId], () async {
      final created = <int>[];
      if (!o.isSeries || o.occurrenceDate == null) {
        await repo.updateTask(edited.copyWith(id: () => o.taskId));
        if (subtasks != null) await repo.setSubtasks(o.taskId, subtasks);
        if (reminders != null) await repo.setReminders(o.taskId, reminders);
        return created;
      }
      final series = o.series;
      final date = o.occurrenceDate!;
      switch (scope) {
        case SeriesScope.thisOne:
          await _overrideOccurrence(series, date, o.task, edited);
        case SeriesScope.selected:
          for (final d in selectedDates) {
            final occ = (await repo.loadSnapshotOccurrence(series.id!, d));
            final base = occ?.task ??
                series.copyWith(start: () => withTimeOf(d, series.start!));
            // Se aplican los cambios de campos; la hora (no la fecha) se copia.
            var target = base.applyOverrides(o.task.diffOverridable(edited)
              ..remove('start'));
            if (edited.start != null &&
                minutesOfDay(edited.start!) != minutesOfDay(o.task.start!)) {
              target = target.copyWith(
                  start: () => withTimeOf(target.start!, edited.start!));
            }
            await _overrideOccurrence(series, d, base, target);
          }
        case SeriesScope.all:
          await _editAll(series, o, edited);
          if (subtasks != null) await repo.setSubtasks(series.id!, subtasks);
          if (reminders != null) await repo.setReminders(series.id!, reminders);
        case SeriesScope.thisAndFollowing:
          if (!dateOnly(date).isAfter(dateOnly(series.start!))) {
            await _editAll(series, o, edited);
            if (subtasks != null) await repo.setSubtasks(series.id!, subtasks);
            if (reminders != null) {
              await repo.setReminders(series.id!, reminders);
            }
          } else {
            final newId = await _split(series, date, edited,
                subtasks: subtasks, reminders: reminders);
            if (newId != null) created.add(newId);
          }
      }
      return created;
    });
  }

  Future<void> _overrideOccurrence(
      Task series, DateTime date, Task current, Task edited) async {
    final base = series.copyWith(start: () => withTimeOf(date, series.start!));
    final overrides = base.diffOverridable(edited);
    if (overrides.isEmpty) {
      await repo.deleteException(series.id!, date);
    } else {
      await repo.upsertException(SeriesException(
        seriesId: series.id!,
        originalDate: date,
        type: ExceptionType.modified,
        overrides: overrides,
      ));
    }
  }

  Future<void> _editAll(Task series, Occurrence o, Task edited) async {
    // Desplaza el inicio de la serie lo mismo que se movió la ocurrencia.
    DateTime? newStart = series.start;
    if (edited.start != null && o.task.start != null) {
      final dayDelta = daysBetween(o.task.start!, edited.start!);
      final shifted = addDays(series.start!, dayDelta);
      newStart = withTimeOf(shifted, edited.start!);
    } else if (edited.start == null) {
      newStart = null;
    }
    await repo.updateTask(edited.copyWith(
      id: () => series.id,
      start: () => newStart,
      status: series.status,
      completedAt: () => series.completedAt,
      createdAt: series.createdAt,
      rrule: () => newStart == null ? null : edited.rrule,
    ));
  }

  /// Parte la serie en [date]: la antigua acaba el día anterior y se crea una
  /// nueva desde [date] con los cambios. Devuelve el id de la nueva serie.
  Future<int?> _split(
    Task series,
    DateTime date,
    Task edited, {
    List<Subtask>? subtasks,
    List<int>? reminders,
  }) async {
    final oldRule = series.rule!;
    final before = RecurrenceEngine.countBefore(oldRule, series.start!, date);
    final dayBefore = addDays(dateOnly(date), -1);
    final truncated = oldRule.copyWith(
      until: () => dayBefore,
      count: () => null,
    );
    await repo.updateTask(series.copyWith(rrule: () => truncated.toRRule()));

    var newRule = RecurrenceRule.tryParse(edited.rrule);
    if (newRule != null && newRule.count != null && edited.rrule == series.rrule) {
      final remaining = newRule.count! - before;
      if (remaining <= 0) return null;
      newRule = newRule.copyWith(count: () => remaining);
    }
    final newStart = edited.start == null
        ? withTimeOf(date, series.start!)
        : edited.start!;
    final newId = await repo.insertTask(
      edited.copyWith(
        id: () => null,
        start: () => newStart,
        rrule: () => newRule?.toRRule(),
        status: TaskStatus.pending,
        completedAt: () => null,
      ),
      subtasks: subtasks ?? await repo.loadSubtasks(series.id!),
      reminders:
          reminders ?? (await repo.loadReminders(series.id!)),
    );
    await repo.moveSeriesChildren(series.id!, newId, date);
    return newId;
  }

  // --------------------------------------------------------------- borrar

  Future<UndoPoint> delete(
    Occurrence o, {
    SeriesScope scope = SeriesScope.all,
    List<DateTime> selectedDates = const [],
  }) {
    return repo.withUndo([o.taskId], () async {
      if (!o.isSeries || o.occurrenceDate == null) {
        await repo.deleteTask(o.taskId);
        return const [];
      }
      final series = o.series;
      final date = o.occurrenceDate!;
      switch (scope) {
        case SeriesScope.thisOne:
          await skip(series.id!, date);
        case SeriesScope.selected:
          for (final d in selectedDates) {
            await skip(series.id!, d);
          }
        case SeriesScope.all:
          await repo.deleteTask(series.id!);
        case SeriesScope.thisAndFollowing:
          if (!dateOnly(date).isAfter(dateOnly(series.start!))) {
            await repo.deleteTask(series.id!);
          } else {
            final rule = series.rule!.copyWith(
              until: () => addDays(dateOnly(date), -1),
              count: () => null,
            );
            await repo.updateTask(series.copyWith(rrule: () => rule.toRRule()));
            await repo.deleteSeriesChildrenFrom(series.id!, date);
          }
      }
      return const [];
    });
  }

  /// Borra varias ocurrencias (selección múltiple). Las de series se saltan.
  Future<UndoPoint> deleteMany(List<Occurrence> items) {
    return repo.withUndo(items.map((o) => o.taskId), () async {
      for (final o in items) {
        if (o.isSeries && o.occurrenceDate != null) {
          await skip(o.taskId, o.occurrenceDate!);
        } else {
          await repo.deleteTask(o.taskId);
        }
      }
      return const [];
    });
  }

  /// RF-26: salta una ocurrencia sin borrar la serie.
  Future<void> skip(int seriesId, DateTime date) => repo.upsertException(
        SeriesException(
          seriesId: seriesId,
          originalDate: dateOnly(date),
          type: ExceptionType.skipped,
        ),
      );

  // ---------------------------------------------------- mover / posponer

  /// Mueve una ocurrencia a [newStart] (y opcionalmente cambia su duración).
  /// En series afecta solo a esa ocurrencia.
  Future<UndoPoint> move(Occurrence o, DateTime newStart, {int? durationMin}) {
    var edited = o.task.copyWith(start: () => newStart);
    if (durationMin != null) edited = edited.copyWith(durationMin: () => durationMin);
    if (o.task.allDay && durationMin == null) {
      edited = edited.copyWith(start: () => dateOnly(newStart));
    }
    return edit(o, edited, scope: SeriesScope.thisOne);
  }

  Future<UndoPoint> moveMany(List<Occurrence> items, DateTime toDate) {
    return repo.withUndo(items.map((o) => o.taskId), () async {
      for (final o in items) {
        final start = o.task.start == null
            ? dateOnly(toDate)
            : withTimeOf(toDate, o.task.start!);
        final edited = o.task.copyWith(start: () => start);
        if (o.isSeries && o.occurrenceDate != null) {
          await _overrideOccurrence(o.series, o.occurrenceDate!, o.task, edited);
        } else {
          final t = (await repo.loadTask(o.taskId)) ?? o.series;
          await repo.updateTask(t.copyWith(start: () => start));
        }
      }
      return const [];
    });
  }

  Future<UndoPoint> setCategoryMany(List<Occurrence> items, int? categoryId) {
    return repo.withUndo(items.map((o) => o.taskId), () async {
      for (final o in items) {
        if (o.isSeries && o.occurrenceDate != null) {
          await _overrideOccurrence(o.series, o.occurrenceDate!, o.task,
              o.task.copyWith(categoryId: () => categoryId));
        } else {
          final t = (await repo.loadTask(o.taskId)) ?? o.series;
          await repo.updateTask(t.copyWith(categoryId: () => categoryId));
        }
      }
      return const [];
    });
  }

  /// Descarta una tarea atrasada (RF-17). En series, salta la ocurrencia.
  Future<UndoPoint> discard(Occurrence o) {
    return repo.withUndo([o.taskId], () async {
      if (o.isSeries && o.occurrenceDate != null) {
        await skip(o.taskId, o.occurrenceDate!);
      } else {
        await repo.updateTask(o.series.copyWith(status: TaskStatus.discarded));
      }
      return const [];
    });
  }

  // -------------------------------------------------------------- duplicar

  /// RF-13: copia la tarea (sin repetición) a [start].
  Future<int> duplicate(Occurrence o, DateTime? start) async {
    final subtasks = await repo.loadSubtasks(o.taskId);
    final reminders = await repo.loadReminders(o.taskId);
    return repo.insertTask(
      o.task.copyWith(
        id: () => null,
        start: () => start,
        rrule: () => null,
        status: TaskStatus.pending,
        completedAt: () => null,
      ),
      subtasks: [for (final s in subtasks) s.copyWith(done: false)],
      reminders: reminders,
    );
  }

  // ------------------------------------------------------------ plantillas

  /// RF-16: crea las tareas de la plantilla en [day].
  Future<UndoPoint> applyTemplate(TaskTemplate template, DateTime day, String tz) {
    return repo.withUndo(const [], () async {
      final ids = <int>[];
      for (final item in template.items) {
        final start = item.startMinute == null
            ? dateOnly(day)
            : DateTime(day.year, day.month, day.day, 0, item.startMinute!);
        ids.add(await repo.insertTask(Task(
          title: item.title,
          start: start,
          allDay: item.startMinute == null,
          durationMin: item.durationMin,
          categoryId: item.categoryId,
          priority: item.priority,
          tz: tz,
          createdAt: now,
          updatedAt: now,
        )));
      }
      return ids;
    });
  }
}

/// Opciones de «posponer rápido» (RF-14).
enum PostponeOption { plusHour, thisAfternoon, tomorrow, nextWeek }

/// Nueva hora de inicio al posponer [start] con [option], respecto a [now].
DateTime postponeTarget(PostponeOption option, DateTime? start, DateTime now,
    {bool weekStartsMonday = true}) {
  final base = start ?? now;
  switch (option) {
    case PostponeOption.plusHour:
      final from = base.isBefore(now) ? now : base;
      final t = from.add(const Duration(hours: 1));
      return DateTime(t.year, t.month, t.day, t.hour, snapMinutes(t.minute, 5));
    case PostponeOption.thisAfternoon:
      final at = DateTime(now.year, now.month, now.day, 17);
      return now.isBefore(at) ? at : DateTime(now.year, now.month, now.day + 1, 17);
    case PostponeOption.tomorrow:
      final t = addDays(dateOnly(now), 1);
      return start == null ? DateTime(t.year, t.month, t.day, 9) : withTimeOf(t, start);
    case PostponeOption.nextWeek:
      final week = startOfWeek(now, weekStartsMonday: weekStartsMonday);
      final t = addDays(week, 7);
      return start == null ? DateTime(t.year, t.month, t.day, 9) : withTimeOf(t, start);
  }
}

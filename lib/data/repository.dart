// Repositorio único sobre la base de datos. La capa de presentación solo
// habla con esta clase (y con los servicios), así se podría añadir
// sincronización en el futuro sin reescribir las pantallas.

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/models/entities.dart';
import '../domain/models/task.dart';
import '../domain/snapshot.dart';
import '../domain/time.dart';
import 'db/database.dart';
import 'mappers.dart';

/// Copia completa de una tarea y sus hijos, para deshacer (RF-37).
class TaskBundle {
  TaskBundle({
    required this.task,
    required this.subtasks,
    required this.reminders,
    required this.attachments,
    required this.exceptions,
    required this.completions,
    required this.timeEntries,
  });
  final TaskRow task;
  final List<SubtaskRow> subtasks;
  final List<ReminderRow> reminders;
  final List<AttachmentRow> attachments;
  final List<SeriesExceptionRow> exceptions;
  final List<CompletionRow> completions;
  final List<TimeEntryRow> timeEntries;
}

/// Estado guardado antes de una operación, para poder revertirla.
class UndoPoint {
  UndoPoint(this.before, this.affectedIds);

  /// Tareas tal como estaban (las que no existían no aparecen).
  final List<TaskBundle> before;

  /// Ids de todas las tareas tocadas, incluidas las creadas.
  final Set<int> affectedIds;
}

class Repository {
  Repository(this.db, {Clock clock = const SystemClock()}) : _clock = clock; // ignore: prefer_initializing_formals

  final AppDatabase db;
  final Clock _clock;

  DateTime get now => _clock.now();

  // ---------------------------------------------------------------- lectura

  Future<AppSnapshot> loadSnapshot() async {
    final results = await Future.wait([
      db.select(db.tasks).get(),
      db.select(db.subtasks).get(),
      db.select(db.categories).get(),
      db.select(db.reminders).get(),
      db.select(db.attachments).get(),
      db.select(db.seriesExceptions).get(),
      db.select(db.occurrenceCompletions).get(),
      db.select(db.timeEntries).get(),
      db.select(db.templates).get(),
      db.select(db.settings).get(),
    ]);
    return AppSnapshot(
      tasks: (results[0] as List<TaskRow>).map(taskFromRow).toList(),
      subtasks: (results[1] as List<SubtaskRow>).map(subtaskFromRow).toList(),
      categories:
          (results[2] as List<CategoryRow>).map(categoryFromRow).toList(),
      reminders:
          (results[3] as List<ReminderRow>).map(reminderFromRow).toList(),
      attachments:
          (results[4] as List<AttachmentRow>).map(attachmentFromRow).toList(),
      exceptions: (results[5] as List<SeriesExceptionRow>)
          .map(exceptionFromRow)
          .toList(),
      completions:
          (results[6] as List<CompletionRow>).map(completionFromRow).toList(),
      timeEntries:
          (results[7] as List<TimeEntryRow>).map(timeEntryFromRow).toList(),
      templates:
          (results[8] as List<TemplateRow>).map(templateFromRow).toList(),
      settings: {
        for (final s in results[9] as List<SettingRow>) s.key: s.value,
      },
    );
  }

  /// Emite una foto nueva cada vez que cambia cualquier tabla.
  Stream<AppSnapshot> watchSnapshot() async* {
    yield await loadSnapshot();
    await for (final _ in db.tableUpdates().debounce(const Duration(milliseconds: 30))) {
      yield await loadSnapshot();
    }
  }

  Future<Task?> loadTask(int id) async {
    final row = await (db.select(db.tasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : taskFromRow(row);
  }

  Future<List<Subtask>> loadSubtasks(int taskId) async {
    final rows = await (db.select(db.subtasks)
          ..where((s) => s.taskId.equals(taskId))
          ..orderBy([(s) => OrderingTerm(expression: s.ord)]))
        .get();
    return rows.map(subtaskFromRow).toList();
  }

  Future<List<int>> loadReminders(int taskId) async {
    final rows = await (db.select(db.reminders)
          ..where((s) => s.taskId.equals(taskId)))
        .get();
    return rows.map((r) => r.minutesBefore).toList();
  }

  /// Ocurrencia efectiva de una serie en [date] (con excepciones aplicadas).
  Future<Occurrence?> loadSnapshotOccurrence(int seriesId, DateTime date) async {
    final snap = await loadSnapshot();
    return snap.occurrenceOf(seriesId, date);
  }

  // ---------------------------------------------------------------- tareas

  Future<int> insertTask(
    Task task, {
    List<Subtask> subtasks = const [],
    List<int> reminders = const [],
  }) {
    return db.transaction(() async {
      final t = task.copyWith(createdAt: now, updatedAt: now);
      final id = await db.into(db.tasks).insert(taskToCompanion(t));
      await _writeSubtasks(id, subtasks);
      await _writeReminders(id, reminders);
      return id;
    });
  }

  Future<void> updateTask(Task task) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(task.id!)))
        .write(taskToCompanion(task.copyWith(updatedAt: now)));
  }

  Future<void> deleteTask(int id) =>
      (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();

  Future<void> setSubtasks(int taskId, List<Subtask> subtasks) =>
      db.transaction(() => _writeSubtasks(taskId, subtasks));

  Future<void> _writeSubtasks(int taskId, List<Subtask> subtasks) async {
    await (db.delete(db.subtasks)..where((s) => s.taskId.equals(taskId))).go();
    for (var i = 0; i < subtasks.length; i++) {
      final s = subtasks[i];
      await db.into(db.subtasks).insert(SubtasksCompanion.insert(
            taskId: taskId,
            title: s.title,
            done: Value(s.done),
            ord: Value(i),
          ));
    }
  }

  Future<void> toggleSubtask(int subtaskId, bool done) =>
      (db.update(db.subtasks)..where((s) => s.id.equals(subtaskId)))
          .write(SubtasksCompanion(done: Value(done)));

  Future<void> setReminders(int taskId, List<int> minutes) =>
      db.transaction(() => _writeReminders(taskId, minutes));

  Future<void> _writeReminders(int taskId, List<int> minutes) async {
    await (db.delete(db.reminders)..where((r) => r.taskId.equals(taskId))).go();
    for (final m in minutes.toSet()) {
      await db.into(db.reminders).insert(
          RemindersCompanion.insert(taskId: taskId, minutesBefore: m));
    }
  }

  // ---------------------------------------------------- series: excepciones

  Future<void> upsertException(SeriesException e) async {
    await db.into(db.seriesExceptions).insert(
          SeriesExceptionsCompanion.insert(
            seriesId: e.seriesId,
            originalDate: formatDateKey(e.originalDate),
            type: e.type.index,
            overrides: Value(jsonEncode(e.overrides)),
          ),
          onConflict: DoUpdate(
            (_) => SeriesExceptionsCompanion(
              type: Value(e.type.index),
              overrides: Value(jsonEncode(e.overrides)),
            ),
            target: [db.seriesExceptions.seriesId, db.seriesExceptions.originalDate],
          ),
        );
  }

  Future<void> deleteException(int seriesId, DateTime date) =>
      (db.delete(db.seriesExceptions)
            ..where((e) =>
                e.seriesId.equals(seriesId) &
                e.originalDate.equals(formatDateKey(date))))
          .go();

  /// Mueve excepciones y completados con fecha >= [from] a otra serie (al
  /// partir una serie con «esta y las siguientes»).
  Future<void> moveSeriesChildren(int fromSeries, int toSeries, DateTime from) async {
    final key = formatDateKey(from);
    await (db.update(db.seriesExceptions)
          ..where((e) =>
              e.seriesId.equals(fromSeries) &
              e.originalDate.isBiggerOrEqualValue(key)))
        .write(SeriesExceptionsCompanion(seriesId: Value(toSeries)));
    await (db.update(db.occurrenceCompletions)
          ..where((e) =>
              e.seriesId.equals(fromSeries) &
              e.occurrenceDate.isBiggerOrEqualValue(key)))
        .write(OccurrenceCompletionsCompanion(seriesId: Value(toSeries)));
  }

  /// Borra excepciones y completados con fecha >= [from].
  Future<void> deleteSeriesChildrenFrom(int seriesId, DateTime from) async {
    final key = formatDateKey(from);
    await (db.delete(db.seriesExceptions)
          ..where((e) =>
              e.seriesId.equals(seriesId) &
              e.originalDate.isBiggerOrEqualValue(key)))
        .go();
    await (db.delete(db.occurrenceCompletions)
          ..where((e) =>
              e.seriesId.equals(seriesId) &
              e.occurrenceDate.isBiggerOrEqualValue(key)))
        .go();
  }

  Future<void> setOccurrenceCompleted(int seriesId, DateTime date, bool done) async {
    final key = formatDateKey(date);
    if (done) {
      await db.into(db.occurrenceCompletions).insert(
            OccurrenceCompletionsCompanion.insert(
              seriesId: seriesId,
              occurrenceDate: key,
              completedAt: now,
            ),
            mode: InsertMode.insertOrReplace,
          );
    } else {
      await (db.delete(db.occurrenceCompletions)
            ..where((c) => c.seriesId.equals(seriesId) & c.occurrenceDate.equals(key)))
          .go();
    }
  }

  // ------------------------------------------------------------ categorías

  Future<int> insertCategory(String name, int color) => db
      .into(db.categories)
      .insert(CategoriesCompanion.insert(name: name, color: color));

  Future<void> updateCategory(Category c) =>
      (db.update(db.categories)..where((x) => x.id.equals(c.id!))).write(
          CategoriesCompanion(name: Value(c.name), color: Value(c.color)));

  /// Borra la categoría; sus tareas quedan sin categoría.
  Future<void> deleteCategory(int id) => db.transaction(() async {
        await (db.update(db.tasks)..where((t) => t.categoryId.equals(id)))
            .write(const TasksCompanion(categoryId: Value(null)));
        await (db.delete(db.categories)..where((c) => c.id.equals(id))).go();
      });

  // ------------------------------------------------------------- adjuntos

  Future<int> insertAttachment(Attachment a) =>
      db.into(db.attachments).insert(AttachmentsCompanion.insert(
            taskId: a.taskId,
            path: a.path,
            name: a.name,
            type: a.type.index,
            size: a.size,
          ));

  Future<void> deleteAttachment(int id) =>
      (db.delete(db.attachments)..where((a) => a.id.equals(id))).go();

  // ------------------------------------------------------------- cronómetro

  Future<int> startTimer(int taskId, DateTime? occurrenceDate) =>
      db.into(db.timeEntries).insert(TimeEntriesCompanion.insert(
            taskId: taskId,
            occurrenceDate: Value(
                occurrenceDate == null ? null : formatDateKey(occurrenceDate)),
            start: now,
          ));

  Future<void> stopTimer(int entryId) =>
      (db.update(db.timeEntries)..where((e) => e.id.equals(entryId)))
          .write(TimeEntriesCompanion(end: Value(now)));

  Future<void> deleteTimeEntriesOf(int taskId) =>
      (db.delete(db.timeEntries)..where((e) => e.taskId.equals(taskId))).go();

  // -------------------------------------------------------------- plantillas

  Future<int> saveTemplate(TaskTemplate t) async {
    final items = jsonEncode([for (final i in t.items) i.toJson()]);
    if (t.id == null) {
      return db
          .into(db.templates)
          .insert(TemplatesCompanion.insert(name: t.name, items: items));
    }
    await (db.update(db.templates)..where((x) => x.id.equals(t.id!)))
        .write(TemplatesCompanion(name: Value(t.name), items: Value(items)));
    return t.id!;
  }

  Future<void> deleteTemplate(int id) =>
      (db.delete(db.templates)..where((t) => t.id.equals(id))).go();

  // ---------------------------------------------------------------- ajustes

  Future<void> setSetting(String key, String value) => db
      .into(db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  Future<String?> getSetting(String key) async {
    final row = await (db.select(db.settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Fuerza recargar la foto (tras cambios hechos por otro aislado, p. ej.
  /// una acción de notificación con la app en segundo plano).
  void notifyExternalChange() => db.markTablesUpdated(db.allTables);

  // --------------------------------------------------------------- deshacer

  Future<TaskBundle?> captureBundle(int taskId) async {
    final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId)))
        .getSingleOrNull();
    if (task == null) return null;
    return TaskBundle(
      task: task,
      subtasks: await (db.select(db.subtasks)..where((s) => s.taskId.equals(taskId))).get(),
      reminders:
          await (db.select(db.reminders)..where((s) => s.taskId.equals(taskId))).get(),
      attachments:
          await (db.select(db.attachments)..where((s) => s.taskId.equals(taskId))).get(),
      exceptions: await (db.select(db.seriesExceptions)
            ..where((s) => s.seriesId.equals(taskId)))
          .get(),
      completions: await (db.select(db.occurrenceCompletions)
            ..where((s) => s.seriesId.equals(taskId)))
          .get(),
      timeEntries:
          await (db.select(db.timeEntries)..where((s) => s.taskId.equals(taskId))).get(),
    );
  }

  /// Ejecuta [action] guardando antes el estado de [taskIds]. Devuelve un
  /// punto de deshacer que incluye también las tareas creadas por [action].
  Future<UndoPoint> withUndo(
      Iterable<int> taskIds, Future<Iterable<int>> Function() action) async {
    final ids = taskIds.toSet();
    final before = <TaskBundle>[];
    for (final id in ids) {
      final b = await captureBundle(id);
      if (b != null) before.add(b);
    }
    final created = await action();
    return UndoPoint(before, {...ids, ...created});
  }

  Future<void> undo(UndoPoint p) => db.transaction(() async {
        for (final id in p.affectedIds) {
          await deleteTask(id);
        }
        for (final b in p.before) {
          await db.into(db.tasks).insert(b.task);
          for (final r in b.subtasks) {
            await db.into(db.subtasks).insert(r);
          }
          for (final r in b.reminders) {
            await db.into(db.reminders).insert(r);
          }
          for (final r in b.attachments) {
            await db.into(db.attachments).insert(r);
          }
          for (final r in b.exceptions) {
            await db.into(db.seriesExceptions).insert(r);
          }
          for (final r in b.completions) {
            await db.into(db.occurrenceCompletions).insert(r);
          }
          for (final r in b.timeEntries) {
            await db.into(db.timeEntries).insert(r);
          }
        }
      });
}

extension _Debounce<T> on Stream<T> {
  Stream<T> debounce(Duration d) {
    Timer? timer;
    T? last;
    late StreamController<T> controller;
    StreamSubscription<T>? sub;
    controller = StreamController<T>(
      onListen: () {
        sub = listen(
          (e) {
            last = e;
            timer?.cancel();
            timer = Timer(d, () => controller.add(last as T));
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            controller.close();
          },
        );
      },
      onCancel: () {
        timer?.cancel();
        return sub?.cancel();
      },
    );
    return controller.stream;
  }
}

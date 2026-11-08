// Base de datos SQLite local (Drift) con migraciones versionadas (RNF-05).

import 'package:drift/drift.dart';

part 'database.g.dart';

@DataClassName('TaskRow')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Hora de pared `yyyy-MM-ddTHH:mm`; null = sin hora.
  TextColumn get start => text().nullable()();
  IntColumn get durationMin => integer().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  IntColumn get categoryId => integer().nullable()();

  /// 0 alta, 1 media, 2 baja.
  IntColumn get priority => integer().withDefault(const Constant(1))();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get countdown => boolean().withDefault(const Constant(false))();
  IntColumn get estimateMin => integer().nullable()();

  /// 0 pendiente, 1 completada, 2 descartada.
  IntColumn get status => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get rrule => text().nullable()();
  TextColumn get tz => text().withDefault(const Constant('UTC'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // --- v2 ---
  /// Proyecto al que pertenece (aparte de la categoría).
  IntColumn get projectId => integer().nullable()();

  /// UID del evento .ics del que se importó (para no duplicar).
  TextColumn get icsUid => text().nullable()();
}

/// v2: proyectos con color, fecha límite opcional y avance.
@DataClassName('ProjectRow')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get color => integer()();

  /// `yyyy-MM-dd`, opcional.
  TextColumn get dueDate => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// v2: diario, una nota por día.
@DataClassName('DayNoteRow')
class DayNotes extends Table {
  /// `yyyy-MM-dd`.
  TextColumn get date => text()();
  TextColumn get body => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date};
}

@DataClassName('SubtaskRow')
class Subtasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get ord => integer().withDefault(const Constant(0))();
}

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get color => integer()();
}

@DataClassName('ReminderRow')
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get minutesBefore => integer()();
}

@DataClassName('AttachmentRow')
class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get path => text()();
  TextColumn get name => text()();

  /// 0 imagen, 1 archivo.
  IntColumn get type => integer()();
  IntColumn get size => integer()();
}

@DataClassName('SeriesExceptionRow')
class SeriesExceptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get seriesId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();

  /// `yyyy-MM-dd`.
  TextColumn get originalDate => text()();

  /// 0 saltada, 1 modificada.
  IntColumn get type => integer()();

  /// JSON con los campos sobrescritos.
  TextColumn get overrides => text().withDefault(const Constant('{}'))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {seriesId, originalDate},
      ];
}

@DataClassName('CompletionRow')
class OccurrenceCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get seriesId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get occurrenceDate => text()();
  DateTimeColumn get completedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {seriesId, occurrenceDate},
      ];
}

@DataClassName('TimeEntryRow')
class TimeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get occurrenceDate => text().nullable()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime().nullable()();
}

@DataClassName('TemplateRow')
class Templates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// JSON: lista de elementos con hora relativa.
  TextColumn get items => text()();
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  Tasks,
  Subtasks,
  Categories,
  Reminders,
  Attachments,
  SeriesExceptions,
  OccurrenceCompletions,
  TimeEntries,
  Templates,
  Settings,
  Projects,
  DayNotes,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Versión del esquema. Súbela y añade un paso en [migration] al cambiarlo.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_tasks_start ON tasks (start)');
        },
        onUpgrade: (m, from, to) async {
          // Migraciones versionadas: un bloque por versión.
          if (from < 2) {
            await m.addColumn(tasks, tasks.projectId);
            await m.addColumn(tasks, tasks.icsUid);
            await m.createTable(projects);
            await m.createTable(dayNotes);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

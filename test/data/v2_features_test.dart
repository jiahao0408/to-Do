// Esquema v2: proyectos, diario, categorías ocultas y copia de seguridad.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/application/task_service.dart';
import 'package:todo_calendar/data/backup_service.dart';
import 'package:todo_calendar/data/db/database.dart';
import 'package:todo_calendar/data/repository.dart';
import 'package:todo_calendar/domain/models/entities.dart';
import 'package:todo_calendar/domain/models/task.dart';
import 'package:todo_calendar/domain/snapshot.dart';
import 'package:todo_calendar/domain/time.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Repository repo;
  late TaskService service;
  final clock = FixedClock(DateTime(2026, 11, 8, 10));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: clock);
    service = TaskService(repo);
  });
  tearDown(() => db.close());

  Task t(String title, {DateTime? start, int? cat, int? project, String? rrule}) => Task(
        title: title,
        start: start,
        categoryId: cat,
        projectId: project,
        rrule: rrule,
        tz: 'UTC',
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  test('categorías ocultas solo en el calendario', () async {
    final uni = await repo.insertCategory('Uni', 1);
    await service.create(t('a', start: DateTime(2026, 11, 8, 9), cat: uni));
    await service.create(t('b', start: DateTime(2026, 11, 8, 11)));
    await repo.setSetting(AppSnapshot.hiddenCategoriesKey, '$uni');
    final snap = await repo.loadSnapshot();
    expect(snap.hiddenCategories, {uni});
    expect(snap.calendarOccurrencesOnDay(DateTime(2026, 11, 8)).map((o) => o.task.title), ['b']);
    expect(snap.occurrencesOnDay(DateTime(2026, 11, 8)).length, 2, reason: 'avisos y búsqueda ven todo');
  });

  test('proyectos: avance, borrar deja tareas sin proyecto', () async {
    final p = await repo.saveProject(Project(name: 'TFG', color: 1, dueDate: DateTime(2027, 6, 15)));
    final a = await service.create(t('Cap 1', project: p));
    await service.create(t('Cap 2', project: p, start: DateTime(2026, 11, 10, 9)));
    await service.create(t('Reunión', project: p, start: DateTime(2026, 11, 9, 9), rrule: 'FREQ=WEEKLY'));
    var snap = await repo.loadSnapshot();
    await service.setCompleted(snap.occurrenceOf(a, null)!, true);
    snap = await repo.loadSnapshot();
    expect(snap.projectById(p)!.dueDate, DateTime(2027, 6, 15));
    expect(snap.projectProgress(p), (1, 2), reason: 'las series no cuentan');
    expect(snap.tasksOfProject(p).length, 3);
    await repo.deleteProject(p);
    snap = await repo.loadSnapshot();
    expect(snap.projects, isEmpty);
    expect(snap.tasks.every((x) => x.projectId == null), isTrue);
  });

  test('duplicar no copia el UID de .ics', () async {
    final id = await service.create(t('x', start: DateTime(2026, 11, 8, 9)).copyWith(icsUid: () => 'abc@x'));
    final snap = await repo.loadSnapshot();
    final copy = await service.duplicate(snap.occurrenceOf(id, null)!, DateTime(2026, 11, 9, 9));
    expect((await repo.loadSnapshot()).taskById(copy)!.icsUid, isNull);
  });

  test('diario: guardar, editar y borrar con texto vacío', () async {
    await repo.saveDayNote(DateTime(2026, 11, 8), 'Buen día');
    expect((await repo.loadSnapshot()).noteOn(DateTime(2026, 11, 8))!.body, 'Buen día');
    await repo.saveDayNote(DateTime(2026, 11, 8), 'Mejor día');
    expect((await repo.loadSnapshot()).dayNotes.single.body, 'Mejor día');
    await repo.saveDayNote(DateTime(2026, 11, 8), '  ');
    expect((await repo.loadSnapshot()).dayNotes, isEmpty);
  });

  test('copia de seguridad incluye proyectos y diario', () async {
    final tmp = await Directory.systemTemp.createTemp('v2');
    final p = await repo.saveProject(const Project(name: 'Casa', color: 5));
    await service.create(t('Pintar', project: p));
    await repo.saveDayNote(DateTime(2026, 11, 8), 'nota');
    final zip = await BackupService(db, attachmentsDir: tmp).exportZip(tmp);
    final db2 = AppDatabase(NativeDatabase.memory());
    await BackupService(db2, attachmentsDir: tmp).importFile(zip);
    final s2 = await Repository(db2).loadSnapshot();
    expect(s2.projects.single.name, 'Casa');
    expect(s2.tasks.single.projectId, s2.projects.single.id);
    expect(s2.dayNotes.single.body, 'nota');
    await db2.close();
    await tmp.delete(recursive: true);
  });

  test('copia antigua (esquema 1) se importa', () async {
    final tmp = await Directory.systemTemp.createTemp('v1');
    final json = <String, Object?>{
      'format': 'todo_calendar_backup',
      'formatVersion': 1,
      'schemaVersion': 1,
      'tables': {
        'tasks': [
          {
            'id': 1, 'title': 'vieja', 'notes': '', 'start': '2026-11-08T09:00', 'durationMin': 60,
            'allDay': false, 'categoryId': null, 'priority': 1, 'location': '', 'url': '', 'pinned': false,
            'countdown': false, 'estimateMin': null, 'status': 0, 'completedAt': null, 'rrule': null,
            'tz': 'UTC', 'createdAt': '2026-11-01T00:00:00.000Z', 'updatedAt': '2026-11-01T00:00:00.000Z',
          },
        ],
      },
    };
    await BackupService(db, attachmentsDir: tmp).importJson(json);
    final snap = await repo.loadSnapshot();
    expect(snap.tasks.single.title, 'vieja');
    expect(snap.tasks.single.projectId, isNull);
    expect(formatWallClock(snap.tasks.single.start!), '2026-11-08T09:00');
    await tmp.delete(recursive: true);
  });
}

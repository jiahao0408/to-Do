// RNF-05 / RF-52 / RF-53: copia de seguridad de ida y vuelta sin pérdidas.
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
import 'package:todo_calendar/domain/time.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final clock = FixedClock(DateTime(2026, 11, 7, 10));

  test('exportar a zip e importar en otra base de datos deja todo igual', () async {
    final tmp = await Directory.systemTemp.createTemp('backup_test');
    final attA = Directory('${tmp.path}/a')..createSync();
    final attB = Directory('${tmp.path}/b')..createSync();
    File('${attA.path}/foto.jpg').writeAsBytesSync([1, 2, 3, 4]);

    final dbA = AppDatabase(NativeDatabase.memory());
    final repoA = Repository(dbA, clock: clock);
    final service = TaskService(repoA);
    final cat = await repoA.insertCategory('Uni', 0xFF3F51B5);
    final id = await service.create(
      Task(
        title: 'Examen «Álgebra» 期末',
        notes: 'línea 1\nlínea 2',
        start: DateTime(2026, 12, 15, 9, 30),
        durationMin: 120,
        categoryId: cat,
        priority: Priority.high,
        countdown: true,
        rrule: 'FREQ=WEEKLY;BYDAY=TU',
        tz: 'Europe/Madrid',
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
      subtasks: const [Subtask(taskId: 0, title: 'Tema 1', done: true), Subtask(taskId: 0, title: 'Tema 2')],
      reminders: const [1440, 30],
    );
    await service.skip(id, DateTime(2026, 12, 22));
    await repoA.setOccurrenceCompleted(id, DateTime(2026, 12, 15), true);
    await repoA.insertAttachment(Attachment(taskId: id, path: 'foto.jpg', name: 'foto.jpg', type: AttachmentType.image, size: 4));
    await repoA.saveTemplate(const TaskTemplate(name: 'Rutina', items: [TemplateItem(title: 'Leer', startMinute: 480)]));
    await repoA.setSetting('locale', 'zh');

    final zip = await BackupService(dbA, attachmentsDir: attA).exportZip(tmp);
    final before = await BackupService(dbA, attachmentsDir: attA).exportJson();

    final dbB = AppDatabase(NativeDatabase.memory());
    await Repository(dbB).insertCategory('basura', 0); // se reemplaza
    await BackupService(dbB, attachmentsDir: attB).importFile(zip);
    final after = await BackupService(dbB, attachmentsDir: attB).exportJson();

    // La importación añade el aviso para que la ballenita no «coma» lo importado.
    final afterTables = Map<String, dynamic>.from(after['tables'] as Map);
    final settings = (afterTables['settings'] as List).cast<Map<String, dynamic>>();
    expect(settings.where((r) => r['key'] == 'whale.rebase').single['value'], '1');
    afterTables['settings'] = settings.where((r) => r['key'] != 'whale.rebase').toList();
    expect(afterTables, before['tables']);
    expect(File('${attB.path}/foto.jpg').readAsBytesSync(), [1, 2, 3, 4]);
    final snap = await Repository(dbB).loadSnapshot();
    expect(snap.tasks.single.start, DateTime(2026, 12, 15, 9, 30));
    expect(snap.exceptionsOf(id).length, 1);
    expect(snap.completionsOf(id).length, 1);

    await dbA.close();
    await dbB.close();
    await tmp.delete(recursive: true);
  });

  test('rechaza archivos que no son copias', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final tmp = await Directory.systemTemp.createTemp('backup_test2');
    final f = File('${tmp.path}/x.json')..writeAsStringSync('{"hola": 1}');
    expect(() => BackupService(db, attachmentsDir: tmp).importFile(f), throwsA(isA<BackupException>()));
    await db.close();
  });
}

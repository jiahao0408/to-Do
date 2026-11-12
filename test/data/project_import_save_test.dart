// Guardar un proyecto importado desde texto.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/application/project_importer.dart';
import 'package:todo_calendar/data/db/database.dart';
import 'package:todo_calendar/data/repository.dart';
import 'package:todo_calendar/domain/models/task.dart';
import 'package:todo_calendar/domain/nlp/quick_parser.dart';
import 'package:todo_calendar/domain/project_import.dart';
import 'package:todo_calendar/domain/time.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Repository repo;
  final clock = FixedClock(DateTime(2026, 11, 13, 10));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: clock);
  });
  tearDown(() => db.close());

  test('crea el proyecto, una tarea por módulo y sus subtareas', () async {
    final parsed = parseProjectMarkdown('''
# TFG
## Investigación mañana a las 9
- Leer
- [x] Entrevistar
## Diseño
- Bocetos
''', dates: QuickParser(now: clock.now()));
    final id = await ProjectImporter(repo).save(parsed, title: 'Mi TFG', color: 0xFF5B7CFA, building: 'school', tz: 'UTC');

    final snap = await repo.loadSnapshot();
    final project = snap.projectById(id)!;
    expect(project.name, 'Mi TFG');
    expect(project.building, 'school');
    final tasks = snap.tasksOfProject(id)..sort((a, b) => a.id!.compareTo(b.id!));
    expect(tasks.map((t) => t.title), ['Investigación', 'Diseño']);
    expect(tasks[0].start, DateTime(2026, 11, 14, 9));
    expect(tasks[1].start, isNull);
    expect(snap.subtasksOf(tasks[0].id!).map((s) => (s.title, s.done)), [('Leer', false), ('Entrevistar', true)]);
    expect(snap.subtasksOf(tasks[1].id!).single.title, 'Bocetos');
    expect(snap.projectProgress(id), (0, 2));
  });

  test('módulo marcado como hecho cuenta en el avance', () async {
    final parsed = parseProjectMarkdown('- [x] Uno\n- [ ] Dos');
    final id = await ProjectImporter(repo).save(parsed, title: 'P', color: 1, tz: 'UTC');
    final snap = await repo.loadSnapshot();
    expect(snap.projectProgress(id), (1, 2));
    expect(snap.tasksOfProject(id).where((t) => t.status == TaskStatus.completed).single.title, 'Uno');
  });
}

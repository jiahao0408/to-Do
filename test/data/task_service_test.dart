// Tests de casos de uso con base de datos en memoria:
// RF-04, RF-17, RF-23 a RF-27, RF-37, RNF-05.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/application/task_service.dart';
import 'package:todo_calendar/data/db/database.dart';
import 'package:todo_calendar/data/repository.dart';
import 'package:todo_calendar/domain/models/entities.dart';
import 'package:todo_calendar/domain/models/task.dart';
import 'package:todo_calendar/domain/recurrence/recurrence_rule.dart';
import 'package:todo_calendar/domain/snapshot.dart';
import 'package:todo_calendar/domain/time.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Repository repo;
  late TaskService service;
  final clock = FixedClock(DateTime(2026, 11, 7, 10));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: clock);
    service = TaskService(repo);
  });
  tearDown(() => db.close());

  Task task(String title, DateTime? start, {String? rrule, int duration = 60}) => Task(
        title: title,
        start: start,
        durationMin: duration,
        rrule: rrule,
        tz: 'Europe/Madrid',
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  List<String> keys(List<Occurrence> l) =>
      l.map((o) => '${formatDateKey(o.task.start!)} ${o.task.title}').toList();

  test('crear, completar y deshacer (RF-04, RF-37)', () async {
    final id = await service.create(task('Comprar', DateTime(2026, 11, 7, 18)),
        subtasks: const [Subtask(taskId: 0, title: 'pan')], reminders: const [15]);
    var snap = await repo.loadSnapshot();
    expect(snap.subtasksOf(id).single.title, 'pan');
    expect(snap.remindersOf(id).single.minutesBefore, 15);
    final o = snap.occurrencesOnDay(DateTime(2026, 11, 7)).single;
    final point = await service.setCompleted(o, true);
    snap = await repo.loadSnapshot();
    expect(snap.occurrencesOnDay(DateTime(2026, 11, 7)).single.completed, isTrue);
    await repo.undo(point);
    snap = await repo.loadSnapshot();
    final back = snap.occurrencesOnDay(DateTime(2026, 11, 7)).single;
    expect(back.completed, isFalse);
    expect(snap.subtasksOf(id).single.title, 'pan', reason: 'deshacer restaura hijos');
  });

  test('RF-27 completar una ocurrencia no afecta a las demás', () async {
    await service.create(task('Gym', DateTime(2026, 11, 2, 18), rrule: 'FREQ=DAILY'));
    var snap = await repo.loadSnapshot();
    final occ = snap.occurrencesBetween(DateTime(2026, 11, 3), DateTime(2026, 11, 6));
    await service.setCompleted(occ[1], true);
    snap = await repo.loadSnapshot();
    final after = snap.occurrencesBetween(DateTime(2026, 11, 3), DateTime(2026, 11, 6));
    expect(after.map((o) => o.completed), [false, true, false]);
  });

  group('RF-23 alcance al editar', () {
    late Occurrence wed;
    setUp(() async {
      // Lunes, miércoles y viernes a las 9:00 desde el 2 nov.
      await service.create(task('Clase', DateTime(2026, 11, 2, 9), rrule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR'));
      final snap = await repo.loadSnapshot();
      wed = snap.occurrencesOnDay(DateTime(2026, 11, 4)).single;
    });

    test('solo esta', () async {
      await service.edit(wed, wed.task.copyWith(title: 'Clase (aula 2)', start: () => DateTime(2026, 11, 4, 11)),
          scope: SeriesScope.thisOne);
      final snap = await repo.loadSnapshot();
      expect(keys(snap.occurrencesBetween(DateTime(2026, 11, 2), DateTime(2026, 11, 7))), [
        '2026-11-02 Clase',
        '2026-11-04 Clase (aula 2)',
        '2026-11-06 Clase',
      ]);
      expect(snap.occurrencesOnDay(DateTime(2026, 11, 4)).single.task.start!.hour, 11);
    });

    test('esta y las siguientes parte la serie', () async {
      await service.edit(wed, wed.task.copyWith(title: 'Clase nueva'), scope: SeriesScope.thisAndFollowing);
      final snap = await repo.loadSnapshot();
      expect(snap.tasks.length, 2);
      expect(keys(snap.occurrencesBetween(DateTime(2026, 11, 2), DateTime(2026, 11, 10))), [
        '2026-11-02 Clase',
        '2026-11-04 Clase nueva',
        '2026-11-06 Clase nueva',
        '2026-11-09 Clase nueva',
      ]);
    });

    test('todas, moviendo la hora', () async {
      await service.edit(wed, wed.task.copyWith(start: () => DateTime(2026, 11, 4, 10)), scope: SeriesScope.all);
      final snap = await repo.loadSnapshot();
      final occ = snap.occurrencesBetween(DateTime(2026, 11, 2), DateTime(2026, 11, 7));
      expect(occ.length, 3);
      expect(occ.every((o) => o.task.start!.hour == 10), isTrue);
    });

    test('seleccionadas', () async {
      await service.edit(wed, wed.task.copyWith(title: 'Examen'),
          scope: SeriesScope.selected, selectedDates: [DateTime(2026, 11, 6), DateTime(2026, 11, 11)]);
      final snap = await repo.loadSnapshot();
      expect(keys(snap.occurrencesBetween(DateTime(2026, 11, 2), DateTime(2026, 11, 12))), [
        '2026-11-02 Clase',
        '2026-11-04 Clase',
        '2026-11-06 Examen',
        '2026-11-09 Clase',
        '2026-11-11 Examen',
      ]);
    });

    test('esta y las siguientes con COUNT conserva el total', () async {
      await service.create(task('Curso', DateTime(2026, 12, 1, 9), rrule: 'FREQ=DAILY;COUNT=5'));
      var snap = await repo.loadSnapshot();
      final third = snap.occurrencesOnDay(DateTime(2026, 12, 3)).single;
      await service.edit(third, third.task.copyWith(title: 'Curso B'), scope: SeriesScope.thisAndFollowing);
      snap = await repo.loadSnapshot();
      expect(
          keys(snap.occurrencesBetween(DateTime(2026, 12, 1), DateTime(2026, 12, 31)))
              .where((k) => k.contains('Curso')),
          [
        '2026-12-01 Curso',
        '2026-12-02 Curso',
        '2026-12-03 Curso B',
        '2026-12-04 Curso B',
        '2026-12-05 Curso B',
      ]);
    });
  });

  group('RF-24 alcance al borrar', () {
    late Occurrence wed;
    setUp(() async {
      await service.create(task('Clase', DateTime(2026, 11, 2, 9), rrule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR'));
      final snap = await repo.loadSnapshot();
      wed = snap.occurrencesOnDay(DateTime(2026, 11, 4)).single;
    });
    Future<List<String>> week() async =>
        keys((await repo.loadSnapshot()).occurrencesBetween(DateTime(2026, 11, 2), DateTime(2026, 11, 10)));

    test('solo esta (RF-26 saltar)', () async {
      await service.delete(wed, scope: SeriesScope.thisOne);
      expect(await week(), ['2026-11-02 Clase', '2026-11-06 Clase', '2026-11-09 Clase']);
    });
    test('esta y las siguientes', () async {
      await service.delete(wed, scope: SeriesScope.thisAndFollowing);
      expect(await week(), ['2026-11-02 Clase']);
    });
    test('todas', () async {
      await service.delete(wed, scope: SeriesScope.all);
      expect(await week(), isEmpty);
    });
    test('seleccionadas y deshacer', () async {
      final p = await service.delete(wed,
          scope: SeriesScope.selected, selectedDates: [DateTime(2026, 11, 4), DateTime(2026, 11, 9)]);
      expect(await week(), ['2026-11-02 Clase', '2026-11-06 Clase']);
      await repo.undo(p);
      expect((await week()).length, 4);
    });
  });

  test('mover una ocurrencia a otro día la saca de su fecha original', () async {
    await service.create(task('Gym', DateTime(2026, 11, 2, 18), rrule: 'FREQ=DAILY'));
    var snap = await repo.loadSnapshot();
    final o = snap.occurrencesOnDay(DateTime(2026, 11, 10)).single;
    await service.move(o, DateTime(2026, 11, 12, 7));
    snap = await repo.loadSnapshot();
    expect(snap.occurrencesOnDay(DateTime(2026, 11, 10)), isEmpty);
    expect(snap.occurrencesOnDay(DateTime(2026, 11, 12)).length, 2);
    // Aparece aunque el rango no incluya su fecha original.
    expect(snap.occurrencesBetween(DateTime(2026, 11, 12), DateTime(2026, 11, 13)).first.task.start,
        DateTime(2026, 11, 12, 7));
  });

  test('RF-17 atrasadas: puntuales sin completar y series recientes', () async {
    await service.create(task('Informe', DateTime(2026, 11, 5, 9)));
    await service.create(task('Hecha', DateTime(2026, 11, 5, 9)));
    await service.create(task('Hábito', DateTime(2026, 10, 1, 8), rrule: 'FREQ=DAILY'));
    var snap = await repo.loadSnapshot();
    final hecha = snap.occurrencesOnDay(DateTime(2026, 11, 5)).firstWhere((o) => o.task.title == 'Hecha');
    await service.setCompleted(hecha, true);
    snap = await repo.loadSnapshot();
    final overdue = snap.overdue(clock.now());
    expect(overdue.where((o) => o.task.title == 'Informe').length, 1);
    expect(overdue.where((o) => o.task.title == 'Hecha'), isEmpty);
    expect(overdue.where((o) => o.task.title == 'Hábito').length, 7, reason: 'solo últimos 7 días');
    await service.discard(overdue.firstWhere((o) => o.task.title == 'Informe'));
    snap = await repo.loadSnapshot();
    expect(snap.overdue(clock.now()).where((o) => o.task.title == 'Informe'), isEmpty);
  });

  test('RF-13 duplicar y RF-14 posponer', () async {
    await service.create(task('Cita', DateTime(2026, 11, 9, 10), rrule: 'FREQ=WEEKLY'));
    var snap = await repo.loadSnapshot();
    final o = snap.occurrencesOnDay(DateTime(2026, 11, 9)).single;
    final copy = await service.duplicate(o, DateTime(2026, 11, 20, 16));
    snap = await repo.loadSnapshot();
    expect(snap.taskById(copy)!.rrule, isNull);
    expect(snap.occurrencesOnDay(DateTime(2026, 11, 20)).single.task.start!.hour, 16);
    final now = DateTime(2026, 11, 7, 10, 7);
    expect(postponeTarget(PostponeOption.plusHour, DateTime(2026, 11, 7, 9), now), DateTime(2026, 11, 7, 11, 5));
    expect(postponeTarget(PostponeOption.thisAfternoon, null, now), DateTime(2026, 11, 7, 17));
    expect(postponeTarget(PostponeOption.tomorrow, DateTime(2026, 11, 7, 9), now), DateTime(2026, 11, 8, 9));
    expect(postponeTarget(PostponeOption.nextWeek, DateTime(2026, 11, 7, 9), now), DateTime(2026, 11, 9, 9));
  });

  test('RF-16 plantilla aplicada a un día', () async {
    const tpl = TaskTemplate(name: 'Mañana', items: [
      TemplateItem(title: 'Correr', startMinute: 7 * 60, durationMin: 30),
      TemplateItem(title: 'Leer'),
    ]);
    final p = await service.applyTemplate(tpl, DateTime(2026, 11, 10), 'Europe/Madrid');
    var snap = await repo.loadSnapshot();
    expect(keys(snap.occurrencesOnDay(DateTime(2026, 11, 10))), ['2026-11-10 Leer', '2026-11-10 Correr']);
    await repo.undo(p);
    snap = await repo.loadSnapshot();
    expect(snap.tasks, isEmpty);
  });

  test('RF-15 orden y prioridad a igual hora (RF-07)', () async {
    await service.create(task('B baja', DateTime(2026, 11, 7, 9)).copyWith(priority: Priority.low));
    await service.create(task('A alta', DateTime(2026, 11, 7, 9)).copyWith(priority: Priority.high));
    final snap = await repo.loadSnapshot();
    expect(snap.occurrencesOnDay(DateTime(2026, 11, 7)).map((o) => o.task.title), ['A alta', 'B baja']);
  });

  test('RRULE de serie guardada es válida', () async {
    final id = await service.create(task('X', DateTime(2026, 11, 2, 9), rrule: 'FREQ=MONTHLY;BYDAY=-1FR'));
    final t = (await repo.loadSnapshot()).taskById(id)!;
    expect(t.rule, const RecurrenceRule(freq: Frequency.monthly, bySetPos: -1, byPosWeekday: 5));
  });
}

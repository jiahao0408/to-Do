// Importar y exportar .ics (RFC 5545).
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/application/ics_service.dart';
import 'package:todo_calendar/application/task_service.dart';
import 'package:todo_calendar/data/db/database.dart';
import 'package:todo_calendar/data/repository.dart';
import 'package:todo_calendar/domain/ics/ics.dart';
import 'package:todo_calendar/domain/models/entities.dart';
import 'package:todo_calendar/domain/models/task.dart';
import 'package:todo_calendar/domain/recurrence/recurrence_rule.dart';
import 'package:todo_calendar/domain/time.dart';

const _google = '''BEGIN:VCALENDAR\r
VERSION:2.0\r
PRODID:-//Google Inc//Google Calendar 70.9054//EN\r
X-WR-CALNAME:Uni\r
BEGIN:VTIMEZONE\r
TZID:Europe/Madrid\r
BEGIN:STANDARD\r
DTSTART:19701025T030000\r
TZOFFSETFROM:+0200\r
TZOFFSETTO:+0100\r
END:STANDARD\r
END:VTIMEZONE\r
BEGIN:VEVENT\r
DTSTART;TZID=Europe/Madrid:20261102T090000\r
DTEND;TZID=Europe/Madrid:20261102T110000\r
RRULE:FREQ=WEEKLY;BYDAY=MO,WE;UNTIL=20261231T225959Z\r
EXDATE;TZID=Europe/Madrid:20261104T090000\r
UID:clase123@google.com\r
SUMMARY:Clase de álgebra\\, aula 2\r
DESCRIPTION:Traer apuntes\\nY calculadora\r
LOCATION:Edificio A\r
CATEGORIES:uni\r
PRIORITY:1\r
BEGIN:VALARM\r
ACTION:DISPLAY\r
TRIGGER:-PT30M\r
END:VALARM\r
BEGIN:VALARM\r
ACTION:DISPLAY\r
TRIGGER:-P1D\r
END:VALARM\r
END:VEVENT\r
BEGIN:VEVENT\r
DTSTART;TZID=Europe/Madrid:20261111T120000\r
DTEND;TZID=Europe/Madrid:20261111T130000\r
RECURRENCE-ID;TZID=Europe/Madrid:20261111T090000\r
UID:clase123@google.com\r
SUMMARY:Clase de álgebra (recuperación)\r
END:VEVENT\r
BEGIN:VEVENT\r
DTSTART;VALUE=DATE:20261215\r
DTEND;VALUE=DATE:20261216\r
UID:examen@google.com\r
SUMMARY:Examen final de una línea muy larga que hay que plegar porque pasa d\r
 e setenta y cinco octetos\r
END:VEVENT\r
BEGIN:VEVENT\r
DTSTART:20261120T170000Z\r
DURATION:PT45M\r
UID:utc@x\r
SUMMARY:Llamada\r
RRULE:FREQ=MONTHLY;BYDAY=MO,TU\r
END:VEVENT\r
BEGIN:VEVENT\r
DTSTART:20261121T100000\r
UID:cancel@x\r
STATUS:CANCELLED\r
SUMMARY:Cancelado\r
END:VEVENT\r
BEGIN:VTODO\r
UID:todo1@x\r
SUMMARY:Comprar libro\r
STATUS:NEEDS-ACTION\r
END:VTODO\r
END:VCALENDAR\r
''';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('Utilidades', () {
    test('escape ida y vuelta', () {
      const s = 'a,b;c\\d\nline';
      expect(icsUnescape(icsEscape(s)), s);
    });
    test('plegado a 75 octetos sin romper caracteres', () {
      final line = 'SUMMARY:${'ñ' * 60}';
      final folded = icsFold(line);
      for (final l in folded.split('\r\n')) {
        expect(l.codeUnits.length <= 75, isTrue);
      }
      expect(folded.replaceAll('\r\n ', ''), line);
    });
    test('duraciones', () {
      expect(parseIcsDuration('-PT15M'), -15);
      expect(parseIcsDuration('-P1D'), -1440);
      expect(parseIcsDuration('PT1H30M'), 90);
      expect(parseIcsDuration('-P1W'), -10080);
      expect(icsDuration(15, negative: true), '-PT15M');
      expect(icsDuration(1440, negative: true), '-P1D');
      expect(icsDuration(90), 'PT1H30M');
    });
  });

  group('Importar', () {
    final result = IcsParser().parse(_google);
    final byUid = {for (final i in result.items) i.uid: i};

    test('lee eventos, tareas y nombre del calendario; ignora cancelados', () {
      expect(result.calendarName, 'Uni');
      expect(byUid.keys.toSet(), {'clase123@google.com', 'examen@google.com', 'utc@x', 'todo1@x'});
    });

    test('serie semanal con EXDATE, RECURRENCE-ID y alarmas', () {
      final c = byUid['clase123@google.com']!;
      expect(c.title, 'Clase de álgebra, aula 2');
      expect(c.notes, 'Traer apuntes\nY calculadora');
      expect(c.location, 'Edificio A');
      expect(c.start, DateTime(2026, 11, 2, 9));
      expect(c.durationMin, 120);
      expect(c.priority, Priority.high);
      expect(c.categoryName, 'uni');
      expect(c.unsupportedRule, isFalse);
      expect(RecurrenceRule.parse(c.rrule!).byWeekdays, {1, 3});
      expect(c.exdates, [DateTime(2026, 11, 4)]);
      expect(c.reminders..sort(), [30, 1440]);
      expect(c.overrides.keys, ['2026-11-11']);
      expect(c.overrides['2026-11-11']!.start, DateTime(2026, 11, 11, 12));
    });

    test('todo el día, líneas plegadas', () {
      final e = byUid['examen@google.com']!;
      expect(e.allDay, isTrue);
      expect(e.start, DateTime(2026, 12, 15));
      expect(e.title, endsWith('de setenta y cinco octetos'));
      expect(e.multiDay, isFalse);
    });

    test('regla no soportada se marca', () {
      final u = byUid['utc@x']!;
      expect(u.unsupportedRule, isTrue);
      expect(u.durationMin, 45);
    });

    test('VTODO sin fecha va a la bandeja', () {
      final t = byUid['todo1@x']!;
      expect(t.isTodo, isTrue);
      expect(t.start, isNull);
    });

    test('subtareas al final de las notas', () {
      final (notes, subs) = splitSubtasks('Hola\n\n- [x] uno\n- [ ] dos');
      expect(notes, 'Hola');
      expect(subs.map((s) => '${s.title}:${s.done}'), ['uno:true', 'dos:false']);
    });
  });

  group('Con base de datos', () {
    late AppDatabase db;
    late Repository repo;
    final clock = FixedClock(DateTime(2026, 11, 8, 10));
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = Repository(db, clock: clock);
    });
    tearDown(() => db.close());

    test('importar crea series con excepciones, sin duplicar por UID', () async {
      await repo.insertCategory('Uni', 1);
      final items = IcsParser().parse(_google).items;
      final service = IcsService(repo);
      await service.import(items, snap: await repo.loadSnapshot(), tz: 'Europe/Madrid');
      var snap = await repo.loadSnapshot();
      expect(snap.tasks.length, 4);
      final clase = snap.tasks.firstWhere((t) => t.icsUid == 'clase123@google.com');
      expect(clase.categoryId, snap.categories.single.id, reason: 'categoría por nombre');
      final occ = snap.occurrencesBetween(DateTime(2026, 11, 2), DateTime(2026, 11, 14))
          .where((o) => o.taskId == clase.id)
          .map((o) => '${formatDateKey(o.task.start!)} ${o.task.start!.hour}h')
          .toList();
      expect(occ, ['2026-11-02 9h', '2026-11-09 9h', '2026-11-11 12h']);
      expect(snap.remindersOf(clase.id!).length, 2);

      // Reimportar no duplica.
      final p = await service.import(items, snap: snap, tz: 'Europe/Madrid');
      snap = await repo.loadSnapshot();
      expect(snap.tasks.length, 4);
      await repo.undo(p);
      expect((await repo.loadSnapshot()).tasks.length, 4);
    });

    test('exportar e importar de nuevo conserva los datos', () async {
      final service = TaskService(repo);
      final cat = await repo.insertCategory('Trabajo', 2);
      final id = await service.create(
        Task(
          title: 'Reunión; semanal, equipo',
          notes: 'Orden del día',
          start: DateTime(2026, 11, 9, 10, 30),
          durationMin: 45,
          categoryId: cat,
          priority: Priority.low,
          rrule: 'FREQ=WEEKLY;BYDAY=MO;UNTIL=20261231',
          tz: 'Europe/Madrid',
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
        subtasks: const [Subtask(taskId: 0, title: 'Acta', done: true)],
        reminders: const [10],
      );
      await service.skip(id, DateTime(2026, 11, 16));
      var snap = await repo.loadSnapshot();
      final o23 = snap.occurrencesOnDay(DateTime(2026, 11, 23)).single;
      await service.edit(o23, o23.task.copyWith(start: () => DateTime(2026, 11, 23, 12)), scope: SeriesScope.thisOne);
      await service.create(Task(title: 'Idea suelta', tz: 'Europe/Madrid', createdAt: clock.now(), updatedAt: clock.now()));
      snap = await repo.loadSnapshot();

      final ics = IcsExporter(snap, now: clock.now()).export(const IcsExportOptions());
      expect(ics, contains('BEGIN:VTODO'));
      expect(ics, contains('RRULE:FREQ=WEEKLY;BYDAY=MO;UNTIL=2026123'));
      expect(ics, contains('EXDATE;TZID=Europe/Madrid:20261116T103000'));
      expect(ics, contains('RECURRENCE-ID;TZID=Europe/Madrid:20261123T103000'));
      expect(ics, contains('SUMMARY:Reunión\\; semanal\\, equipo'));

      // Importar en una base nueva.
      final db2 = AppDatabase(NativeDatabase.memory());
      final repo2 = Repository(db2, clock: clock);
      await repo2.insertCategory('trabajo', 3);
      await IcsService(repo2).import(IcsParser().parse(ics).items,
          snap: await repo2.loadSnapshot(), tz: 'Europe/Madrid');
      final s2 = await repo2.loadSnapshot();
      expect(s2.tasks.length, 2);
      final t = s2.tasks.firstWhere((t) => t.title.startsWith('Reunión'));
      expect(t.title, 'Reunión; semanal, equipo');
      expect(t.notes, 'Orden del día');
      expect(s2.subtasksOf(t.id!).single.done, isTrue);
      expect(s2.remindersOf(t.id!).single.minutesBefore, 10);
      expect(t.priority, Priority.low);
      expect(t.categoryId, isNotNull);
      final occ = s2.occurrencesBetween(DateTime(2026, 11, 9), DateTime(2026, 12, 1))
          .map((o) => '${formatDateKey(o.task.start!)} ${o.task.start!.hour}')
          .toList();
      expect(occ, ['2026-11-09 10', '2026-11-23 12', '2026-11-30 10']);
      expect(s2.tasks.firstWhere((t) => t.title == 'Idea suelta').start, isNull);
      await db2.close();
    });

    test('opciones de exportación', () async {
      final service = TaskService(repo);
      final a = await repo.insertCategory('A', 1);
      await service.create(Task(title: 'a', start: DateTime(2026, 11, 10, 9), categoryId: a, tz: 'UTC', createdAt: clock.now(), updatedAt: clock.now()));
      await service.create(Task(title: 'b', start: DateTime(2026, 12, 10, 9), tz: 'UTC', createdAt: clock.now(), updatedAt: clock.now()));
      final done = await service.create(Task(title: 'c', start: DateTime(2026, 11, 11, 9), tz: 'UTC', createdAt: clock.now(), updatedAt: clock.now()));
      var snap = await repo.loadSnapshot();
      await service.setCompleted(snap.occurrenceOf(done, null)!, true);
      snap = await repo.loadSnapshot();
      final ex = IcsExporter(snap, now: clock.now());
      List<String> titles(IcsExportOptions o) => ex.select(o).map((t) => t.title).toList()..sort();
      expect(titles(const IcsExportOptions()), ['a', 'b']);
      expect(titles(const IcsExportOptions(includeCompleted: true)), ['a', 'b', 'c']);
      expect(titles(IcsExportOptions(from: DateTime(2026, 12, 1))), ['b']);
      expect(titles(IcsExportOptions(categoryIds: {a})), ['a']);
      expect(titles(const IcsExportOptions(categoryIds: {-1})), ['b']);
    });
  });
}

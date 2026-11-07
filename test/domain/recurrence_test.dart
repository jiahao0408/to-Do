// Tests del motor de repetición (RF-19 a RF-22).
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/domain/recurrence/recurrence_engine.dart';
import 'package:todo_calendar/domain/recurrence/recurrence_rule.dart';
import 'package:todo_calendar/domain/time.dart';

List<String> keys(List<DateTime> ds) => ds.map(formatDateKey).toList();

void main() {
  group('RRULE ida y vuelta', () {
    test('RF-19 semanal con días', () {
      final r = RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,WE,FR');
      expect(r.freq, Frequency.weekly);
      expect(r.byWeekdays, {1, 3, 5});
      expect(r.toRRule(), 'FREQ=WEEKLY;BYDAY=MO,WE,FR');
    });

    test('RF-20 posicional y fin', () {
      final r = RecurrenceRule.parse('FREQ=MONTHLY;INTERVAL=2;BYDAY=-1FR;UNTIL=20270630');
      expect(r.bySetPos, -1);
      expect(r.byPosWeekday, 5);
      expect(r.interval, 2);
      expect(r.until, DateTime(2027, 6, 30));
      expect(RecurrenceRule.parse(r.toRRule()), r);
    });

    test('RRULE inválida', () {
      expect(() => RecurrenceRule.parse('INTERVAL=2'), throwsFormatException);
      expect(RecurrenceRule.tryParse('basura'), isNull);
    });
  });

  group('Ocurrencias', () {
    test('RF-19 diaria', () {
      const r = RecurrenceRule(freq: Frequency.daily);
      final occ = RecurrenceEngine.occurrencesBetween(
          r, DateTime(2026, 11, 1, 9), DateTime(2026, 11, 3), DateTime(2026, 11, 6));
      expect(keys(occ), ['2026-11-03', '2026-11-04', '2026-11-05']);
      expect(occ.first.hour, 9);
    });

    test('RF-19 semanal L-X-V', () {
      const r = RecurrenceRule(freq: Frequency.weekly, byWeekdays: {1, 3, 5});
      // 2 nov 2026 es lunes.
      final occ = RecurrenceEngine.occurrencesBetween(
          r, DateTime(2026, 11, 2, 18), DateTime(2026, 11, 1), DateTime(2026, 11, 15));
      expect(keys(occ), [
        '2026-11-02', '2026-11-04', '2026-11-06',
        '2026-11-09', '2026-11-11', '2026-11-13',
      ]);
    });

    test('RF-19 semanal sin días usa el día de inicio', () {
      const r = RecurrenceRule(freq: Frequency.weekly);
      final occ = RecurrenceEngine.occurrences(r, DateTime(2026, 11, 4), limit: 3);
      expect(keys(occ), ['2026-11-04', '2026-11-11', '2026-11-18']);
    });

    test('RF-19 mensual día 15', () {
      const r = RecurrenceRule(freq: Frequency.monthly, byMonthDay: 15);
      final occ = RecurrenceEngine.occurrences(r, DateTime(2026, 11, 15), limit: 3);
      expect(keys(occ), ['2026-11-15', '2026-12-15', '2027-01-15']);
    });

    test('RF-20 día 31 se salta los meses que no lo tienen', () {
      const r = RecurrenceRule(freq: Frequency.monthly);
      final occ = RecurrenceEngine.occurrences(r, DateTime(2027, 1, 31), limit: 4);
      expect(keys(occ), ['2027-01-31', '2027-03-31', '2027-05-31', '2027-07-31']);
    });

    test('RF-20 cada 2 semanas lunes y jueves', () {
      const r = RecurrenceRule(
          freq: Frequency.weekly, interval: 2, byWeekdays: {1, 4});
      final occ = RecurrenceEngine.occurrences(r, DateTime(2026, 11, 2), limit: 4);
      expect(keys(occ), ['2026-11-02', '2026-11-05', '2026-11-16', '2026-11-19']);
    });

    test('RF-20 cada 3 días', () {
      const r = RecurrenceRule(freq: Frequency.daily, interval: 3);
      final occ = RecurrenceEngine.occurrences(r, DateTime(2026, 11, 1), limit: 3);
      expect(keys(occ), ['2026-11-01', '2026-11-04', '2026-11-07']);
    });

    test('RF-20 segundo martes', () {
      const r = RecurrenceRule(
          freq: Frequency.monthly, bySetPos: 2, byPosWeekday: DateTime.tuesday);
      final occ = RecurrenceEngine.occurrences(r, DateTime(2026, 11, 1), limit: 3);
      expect(keys(occ), ['2026-11-10', '2026-12-08', '2027-01-12']);
    });

    test('RF-20 último viernes', () {
      const r = RecurrenceRule(
          freq: Frequency.monthly, bySetPos: -1, byPosWeekday: DateTime.friday);
      final occ = RecurrenceEngine.occurrences(r, DateTime(2026, 11, 1), limit: 3);
      expect(keys(occ), ['2026-11-27', '2026-12-25', '2027-01-29']);
    });

    test('RF-20 anual y 29 de febrero', () {
      const r = RecurrenceRule(freq: Frequency.yearly);
      final occ = RecurrenceEngine.occurrences(r, DateTime(2028, 2, 29), limit: 2);
      expect(keys(occ), ['2028-02-29', '2032-02-29']);
    });

    test('RF-21 hasta fecha (incluida)', () {
      final r = RecurrenceRule(freq: Frequency.daily, until: DateTime(2026, 11, 3));
      final occ = RecurrenceEngine.occurrences(r, DateTime(2026, 11, 1));
      expect(keys(occ), ['2026-11-01', '2026-11-02', '2026-11-03']);
    });

    test('RF-21 tras N repeticiones', () {
      const r = RecurrenceRule(freq: Frequency.weekly, byWeekdays: {1, 3}, count: 3);
      final occ = RecurrenceEngine.occurrences(r, DateTime(2026, 11, 2));
      expect(keys(occ), ['2026-11-02', '2026-11-04', '2026-11-09']);
      // El rango posterior no devuelve más.
      expect(
        RecurrenceEngine.occurrencesBetween(
            r, DateTime(2026, 11, 2), DateTime(2026, 11, 10), DateTime(2026, 12, 1)),
        isEmpty,
      );
    });

    test('El salto por rango da lo mismo que recorrer desde el inicio', () {
      const r = RecurrenceRule(freq: Frequency.weekly, interval: 3, byWeekdays: {2, 6});
      final start = DateTime(2020, 1, 7, 7, 30);
      final all = RecurrenceEngine.occurrences(r, start, horizon: DateTime(2027, 1, 1), limit: 10000);
      final expected = all
          .where((d) => !d.isBefore(DateTime(2026, 3, 1)) && d.isBefore(DateTime(2026, 6, 1)))
          .toList();
      final ranged = RecurrenceEngine.occurrencesBetween(
          r, start, DateTime(2026, 3, 1), DateTime(2026, 6, 1));
      expect(keys(ranged), keys(expected));
    });

    test('RNF-11 la hora de pared no se mueve con el cambio de horario', () {
      const r = RecurrenceRule(freq: Frequency.daily);
      // En Europa el horario cambia el 29 mar y el 25 oct de 2026.
      final occ = RecurrenceEngine.occurrencesBetween(
          r, DateTime(2026, 3, 20, 9), DateTime(2026, 3, 27), DateTime(2026, 4, 1));
      expect(occ.every((d) => d.hour == 9 && d.minute == 0), isTrue);
    });

    test('countBefore y nextOnOrAfter', () {
      const r = RecurrenceRule(freq: Frequency.daily, interval: 2);
      final s = DateTime(2026, 11, 1);
      expect(RecurrenceEngine.countBefore(r, s, DateTime(2026, 11, 6)), 3);
      expect(formatDateKey(RecurrenceEngine.nextOnOrAfter(r, s, DateTime(2026, 11, 6))!),
          '2026-11-07');
      expect(RecurrenceEngine.occursOn(r, s, DateTime(2026, 11, 3)), isTrue);
      expect(RecurrenceEngine.occursOn(r, s, DateTime(2026, 11, 4)), isFalse);
    });
  });

  group('Utilidades de tiempo', () {
    test('número de semana ISO', () {
      expect(isoWeekNumber(DateTime(2026, 1, 1)), 1);
      expect(isoWeekNumber(DateTime(2027, 1, 1)), 53);
      expect(isoWeekNumber(DateTime(2026, 11, 7)), 45);
    });

    test('inicio de semana', () {
      expect(startOfWeek(DateTime(2026, 11, 7)), DateTime(2026, 11, 2));
      expect(startOfWeek(DateTime(2026, 11, 7), weekStartsMonday: false),
          DateTime(2026, 11, 1));
      expect(startOfWeek(DateTime(2026, 11, 8), weekStartsMonday: false),
          DateTime(2026, 11, 8));
    });

    test('hora de pared ida y vuelta', () {
      final d = DateTime(2026, 11, 7, 9, 5);
      expect(formatWallClock(d), '2026-11-07T09:05');
      expect(parseWallClock('2026-11-07T09:05'), d);
    });
  });
}

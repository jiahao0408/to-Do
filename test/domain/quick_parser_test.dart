// Tests del parser de texto natural (RF-48).
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/domain/models/task.dart';
import 'package:todo_calendar/domain/nlp/quick_parser.dart';
import 'package:todo_calendar/domain/recurrence/recurrence_rule.dart';
import 'package:todo_calendar/domain/time.dart';

void main() {
  // Sábado 7 nov 2026, 10:00.
  final now = DateTime(2026, 11, 7, 10);
  final parser = QuickParser(now: now, categories: {'Uni': 1, 'Trabajo': 2, 'Personal': 3});
  String? d(ParsedTask p) => p.date == null ? null : formatDateKey(p.date!);

  group('Español', () {
    test('gym mañana 18h cada lunes', () {
      final p = parser.parse('gym mañana 18h cada lunes');
      expect(p.title, 'gym');
      expect(p.time, const HourMinute(18, 0));
      expect(p.rule, const RecurrenceRule(freq: Frequency.weekly, byWeekdays: {1}));
      expect(d(p), '2026-11-09'); // primer lunes desde mañana
    });

    test('entrega práctica viernes 23:59 !alta #Uni', () {
      final p = parser.parse('entrega práctica viernes 23:59 !alta #Uni');
      expect(p.title, 'entrega práctica');
      expect(d(p), '2026-11-13');
      expect(p.time, const HourMinute(23, 59));
      expect(p.priority, Priority.high);
      expect(p.categoryId, 1);
    });

    test('a las 9 de la mañana / por la tarde', () {
      final p = parser.parse('llamar a mamá mañana a las 9 de la mañana');
      expect(p.title, 'llamar a mamá');
      expect(d(p), '2026-11-08');
      expect(p.time, const HourMinute(9, 0));
      final q = parser.parse('café el lunes a las 5 de la tarde durante 30 min');
      expect(q.title, 'café');
      expect(d(q), '2026-11-09');
      expect(q.time, const HourMinute(17, 0));
      expect(q.durationMin, 30);
    });

    test('fechas absolutas', () {
      expect(d(parser.parse('examen 15 de diciembre')), '2026-12-15');
      expect(d(parser.parse('pagar alquiler el 1')), '2026-12-01');
      expect(d(parser.parse('viaje 3/1')), '2027-01-03');
      expect(d(parser.parse('cumple pasado mañana')), '2026-11-09');
    });

    test('repetición avanzada', () {
      expect(parser.parse('regar cada 3 días').rule,
          const RecurrenceRule(freq: Frequency.daily, interval: 3));
      expect(parser.parse('inglés los martes y jueves 19:00').rule,
          const RecurrenceRule(freq: Frequency.weekly, byWeekdays: {2, 4}));
      expect(parser.parse('stand-up entre semana 9:30').rule!.byWeekdays, {1, 2, 3, 4, 5});
    });

    test('etiqueta desconocida queda en el título', () {
      final p = parser.parse('comprar pan #casa');
      expect(p.title, 'comprar pan #casa');
      expect(p.categoryId, isNull);
    });
  });

  group('Inglés', () {
    test('dentist next tuesday 10am for 1h', () {
      final p = parser.parse('dentist next tuesday 10am for 1h');
      expect(p.title, 'dentist');
      expect(d(p), '2026-11-10');
      expect(p.time, const HourMinute(10, 0));
      expect(p.durationMin, 60);
    });

    test('tomorrow at 7pm, every day', () {
      final p = parser.parse('run tomorrow at 7pm every day !low');
      expect(p.title, 'run');
      expect(p.time, const HourMinute(19, 0));
      expect(p.rule, const RecurrenceRule(freq: Frequency.daily));
      expect(p.priority, Priority.low);
      expect(d(p), '2026-11-08');
    });

    test('month names', () {
      expect(d(parser.parse('flight dec 24')), '2026-12-24');
      expect(d(parser.parse('party 31st of december')), '2026-12-31');
    });
  });

  group('Chino', () {
    test('明天下午6点健身', () {
      final p = parser.parse('明天下午6点健身');
      expect(p.title, '健身');
      expect(d(p), '2026-11-08');
      expect(p.time, const HourMinute(18, 0));
    });

    test('每周一上午9点开会', () {
      final p = parser.parse('每周一上午9点开会');
      expect(p.title, '开会');
      expect(p.rule, const RecurrenceRule(freq: Frequency.weekly, byWeekdays: {1}));
      expect(p.time, const HourMinute(9, 0));
      expect(d(p), '2026-11-09');
    });

    test('下周三 两个小时 / 12月25日', () {
      final p = parser.parse('下周三晚上8点半看电影两个小时');
      expect(p.title, '看电影');
      expect(d(p), '2026-11-11');
      expect(p.time, const HourMinute(20, 30));
      expect(p.durationMin, 120);
      expect(d(parser.parse('12月25日聚会')), '2026-12-25');
    });
  });

  test('zhNumber', () {
    expect(zhNumber('十'), 10);
    expect(zhNumber('十二'), 12);
    expect(zhNumber('二十三'), 23);
    expect(zhNumber('七'), 7);
    expect(zhNumber('8'), 8);
  });
}

// Regla de repetición: subconjunto de RRULE (RFC 5545).
// RF-19 (básicas), RF-20 (avanzadas), RF-21 (fin de repetición).

import '../time.dart';

enum Frequency { daily, weekly, monthly, yearly }

/// Fin de la repetición (RF-21).
enum RecurrenceEnd { never, until, count }

class RecurrenceRule {
  const RecurrenceRule({
    required this.freq,
    this.interval = 1,
    this.byWeekdays = const {},
    this.byMonthDay,
    this.bySetPos,
    this.byPosWeekday,
    this.until,
    this.count,
  })  : assert(interval >= 1),
        assert(until == null || count == null);

  final Frequency freq;

  /// Cada N días/semanas/meses/años (RF-20).
  final int interval;

  /// Días de la semana para reglas semanales. 1 = lunes … 7 = domingo
  /// (igual que [DateTime.weekday]). Vacío = el día de la fecha de inicio.
  final Set<int> byWeekdays;

  /// Día del mes para reglas mensuales (1–31). Null = el de la fecha de inicio.
  final int? byMonthDay;

  /// Posición en el mes («segundo martes» = 2, «último viernes» = -1).
  /// Se usa junto con [byPosWeekday]. Tiene prioridad sobre [byMonthDay].
  final int? bySetPos;
  final int? byPosWeekday;

  /// Última fecha (incluida) en la que puede caer una ocurrencia.
  final DateTime? until;

  /// Número total de ocurrencias.
  final int? count;

  RecurrenceEnd get end => until != null
      ? RecurrenceEnd.until
      : count != null
          ? RecurrenceEnd.count
          : RecurrenceEnd.never;

  bool get isPositional => bySetPos != null && byPosWeekday != null;

  RecurrenceRule copyWith({
    Frequency? freq,
    int? interval,
    Set<int>? byWeekdays,
    int? Function()? byMonthDay,
    int? Function()? bySetPos,
    int? Function()? byPosWeekday,
    DateTime? Function()? until,
    int? Function()? count,
  }) {
    return RecurrenceRule(
      freq: freq ?? this.freq,
      interval: interval ?? this.interval,
      byWeekdays: byWeekdays ?? this.byWeekdays,
      byMonthDay: byMonthDay != null ? byMonthDay() : this.byMonthDay,
      bySetPos: bySetPos != null ? bySetPos() : this.bySetPos,
      byPosWeekday: byPosWeekday != null ? byPosWeekday() : this.byPosWeekday,
      until: until != null ? until() : this.until,
      count: count != null ? count() : this.count,
    );
  }

  static const _dayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  /// Serializa a texto RRULE, p. ej. `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,TH`.
  String toRRule() {
    final parts = <String>['FREQ=${freq.name.toUpperCase()}'];
    if (interval != 1) parts.add('INTERVAL=$interval');
    if (freq == Frequency.weekly && byWeekdays.isNotEmpty) {
      final days = byWeekdays.toList()..sort();
      parts.add('BYDAY=${days.map((d) => _dayCodes[d - 1]).join(',')}');
    }
    if (freq == Frequency.monthly) {
      if (isPositional) {
        parts.add('BYDAY=$bySetPos${_dayCodes[byPosWeekday! - 1]}');
      } else if (byMonthDay != null) {
        parts.add('BYMONTHDAY=$byMonthDay');
      }
    }
    if (until != null) parts.add('UNTIL=${formatCompactDate(until!)}');
    if (count != null) parts.add('COUNT=$count');
    return parts.join(';');
  }

  /// Interpreta un texto RRULE. Lanza [FormatException] si no es válido.
  static RecurrenceRule parse(String input) {
    var text = input.trim();
    if (text.toUpperCase().startsWith('RRULE:')) text = text.substring(6);
    Frequency? freq;
    var interval = 1;
    final weekdays = <int>{};
    int? monthDay;
    int? setPos;
    int? posWeekday;
    DateTime? until;
    int? count;

    for (final part in text.split(';')) {
      if (part.isEmpty) continue;
      final eq = part.indexOf('=');
      if (eq < 0) throw FormatException('Parte RRULE inválida: $part');
      final key = part.substring(0, eq).toUpperCase();
      final value = part.substring(eq + 1).toUpperCase();
      switch (key) {
        case 'FREQ':
          freq = Frequency.values.firstWhere(
            (f) => f.name.toUpperCase() == value,
            orElse: () => throw FormatException('FREQ no soportada: $value'),
          );
        case 'INTERVAL':
          interval = int.parse(value);
          if (interval < 1) throw const FormatException('INTERVAL < 1');
        case 'BYMONTHDAY':
          monthDay = int.parse(value);
        case 'UNTIL':
          until = parseCompactDate(value.substring(0, 8));
        case 'COUNT':
          count = int.parse(value);
        case 'BYDAY':
          for (final token in value.split(',')) {
            final m = RegExp(r'^([+-]?\d+)?([A-Z]{2})$').firstMatch(token);
            if (m == null) throw FormatException('BYDAY inválido: $token');
            final wd = _dayCodes.indexOf(m.group(2)!) + 1;
            if (wd == 0) throw FormatException('Día inválido: $token');
            if (m.group(1) != null) {
              setPos = int.parse(m.group(1)!);
              posWeekday = wd;
            } else {
              weekdays.add(wd);
            }
          }
        case 'WKST':
        case 'BYSETPOS':
          break; // Ignorados: se asume WKST=MO.
        default:
          break;
      }
    }
    if (freq == null) throw const FormatException('Falta FREQ');
    return RecurrenceRule(
      freq: freq,
      interval: interval,
      byWeekdays: weekdays,
      byMonthDay: monthDay,
      bySetPos: setPos,
      byPosWeekday: posWeekday,
      until: until,
      count: count,
    );
  }

  static RecurrenceRule? tryParse(String? input) {
    if (input == null || input.isEmpty) return null;
    try {
      return parse(input);
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule && other.toRRule() == toRRule();

  @override
  int get hashCode => toRRule().hashCode;

  @override
  String toString() => toRRule();
}

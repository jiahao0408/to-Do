// Importar y exportar calendarios .ics (iCalendar, RFC 5545).
//
// Exportar: tareas con fecha → VEVENT (con RRULE, EXDATE para ocurrencias
// saltadas, VEVENT con RECURRENCE-ID para las modificadas y VALARM por cada
// recordatorio); tareas sin fecha → VTODO. Las horas van con TZID (zona IANA
// de la tarea) para que las repeticiones respeten el cambio de horario.
//
// Importar: VEVENT y VTODO. Horas UTC, con TZID o «flotantes»; la
// conversión de zona la hace una función que se inyecta (en la app usa el
// paquete timezone; en los tests puede ser la identidad).

import '../models/entities.dart';
import '../models/task.dart';
import '../recurrence/recurrence_rule.dart';
import '../snapshot.dart';
import '../time.dart';

// =========================================================== utilidades

String icsEscape(String s) => s
    .replaceAll('\\', '\\\\')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,')
    .replaceAll('\r\n', '\\n')
    .replaceAll('\n', '\\n');

String icsUnescape(String s) {
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c == '\\' && i + 1 < s.length) {
      final n = s[++i];
      b.write(switch (n) {
        'n' || 'N' => '\n',
        _ => n, // \\ \; \, \:
      });
    } else {
      b.write(c);
    }
  }
  return b.toString();
}

/// Pliega una línea a 75 octetos (UTF-8) como exige el RFC.
String icsFold(String line) {
  final out = StringBuffer();
  var bytes = 0;
  for (final rune in line.runes) {
    final ch = String.fromCharCode(rune);
    final len = rune < 0x80 ? 1 : rune < 0x800 ? 2 : rune < 0x10000 ? 3 : 4;
    if (bytes + len > 75) {
      out.write('\r\n ');
      bytes = 1;
    }
    out.write(ch);
    bytes += len;
  }
  return out.toString();
}

String _two(int n) => n.toString().padLeft(2, '0');
String _date(DateTime d) => formatCompactDate(d);
String _dateTime(DateTime d) => '${_date(d)}T${_two(d.hour)}${_two(d.minute)}${_two(d.second)}';
String _utc(DateTime d) {
  final u = d.toUtc();
  return '${_dateTime(u)}Z';
}

/// Duración ISO 8601 de iCalendar, p. ej. `-PT15M`, `-P1D`.
String icsDuration(int minutes, {bool negative = false}) {
  final sign = negative && minutes != 0 ? '-' : '';
  if (minutes == 0) return 'PT0M';
  if (minutes % 1440 == 0) return '${sign}P${minutes ~/ 1440}D';
  final h = minutes ~/ 60, m = minutes % 60;
  return '${sign}PT${h > 0 ? '${h}H' : ''}${m > 0 ? '${m}M' : ''}';
}

/// Minutos de una duración iCalendar (con signo). Null si no es válida.
int? parseIcsDuration(String s) {
  final m = RegExp(r'^([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$')
      .firstMatch(s.trim().toUpperCase());
  if (m == null) return null;
  int g(int i) => int.tryParse(m.group(i) ?? '') ?? 0;
  final total = g(2) * 7 * 1440 + g(3) * 1440 + g(4) * 60 + g(5) + (g(6) >= 30 ? 1 : 0);
  return m.group(1) == '-' ? -total : total;
}

// =========================================================== exportar

class IcsExportOptions {
  const IcsExportOptions({
    this.from,
    this.to,
    this.categoryIds,
    this.includeCompleted = false,
    this.includeUndated = true,
  });

  /// Rango de fechas (incluido); null = sin límite.
  final DateTime? from;
  final DateTime? to;

  /// Categorías a incluir; null = todas. Usa -1 para «sin categoría».
  final Set<int>? categoryIds;
  final bool includeCompleted;

  /// Tareas sin fecha como VTODO.
  final bool includeUndated;
}

class IcsExporter {
  IcsExporter(this.snap, {required this.now, this.prodId = '-//chenj//to Do//ES'});
  final AppSnapshot snap;
  final DateTime now;
  final String prodId;

  final _lines = <String>[];
  void _p(String line) => _lines.add(icsFold(line));

  String uidOf(Task t) => t.icsUid ?? 'task-${t.id}-${t.createdAt.millisecondsSinceEpoch}@todo.chenj';

  bool _inCategories(Task t, IcsExportOptions o) {
    final ids = o.categoryIds;
    if (ids == null) return true;
    return ids.contains(t.categoryId ?? -1);
  }

  bool _inRange(Task t, IcsExportOptions o) {
    final from = o.from == null ? null : dateOnly(o.from!);
    final to = o.to == null ? null : dateOnly(o.to!);
    final start = dateOnly(t.start!);
    if (!t.isSeries) {
      if (from != null && start.isBefore(from)) return false;
      if (to != null && start.isAfter(to)) return false;
      return true;
    }
    // Series: entra si se solapa con el rango.
    if (to != null && start.isAfter(to)) return false;
    final until = t.rule?.until;
    if (from != null && until != null && until.isBefore(from)) return false;
    return true;
  }

  /// Tareas que se exportarían con [o] (para mostrar el recuento).
  List<Task> select(IcsExportOptions o) => [
        for (final t in snap.tasks)
          if (t.status != TaskStatus.discarded &&
              _inCategories(t, o) &&
              (o.includeCompleted || !t.isCompleted) &&
              (t.start == null ? o.includeUndated : _inRange(t, o)))
            t,
      ];

  String export(IcsExportOptions o) {
    _lines.clear();
    _p('BEGIN:VCALENDAR');
    _p('VERSION:2.0');
    _p('PRODID:$prodId');
    _p('CALSCALE:GREGORIAN');
    _p('METHOD:PUBLISH');
    for (final t in select(o)) {
      if (t.start == null) {
        _todo(t);
      } else {
        _event(t, t, null);
        if (t.isSeries) {
          for (final ex in snap.exceptionsOf(t.id!).values) {
            if (ex.type == ExceptionType.modified) {
              final base = t.copyWith(start: () => withTimeOf(ex.originalDate, t.start!));
              _event(base.applyOverrides(ex.overrides), t, ex.originalDate);
            }
          }
        }
      }
    }
    _p('END:VCALENDAR');
    return '${_lines.join('\r\n')}\r\n';
  }

  void _start(String name, Task t, DateTime when) {
    if (t.allDay) {
      _p('$name;VALUE=DATE:${_date(when)}');
    } else {
      _p('$name;TZID=${t.tz}:${_dateTime(when)}');
    }
  }

  void _common(Task t) {
    _p('SUMMARY:${icsEscape(t.title)}');
    final subs = snap.subtasksOf(t.id!);
    final desc = [
      if (t.notes.isNotEmpty) t.notes,
      if (subs.isNotEmpty) subs.map((s) => '- [${s.done ? 'x' : ' '}] ${s.title}').join('\n'),
    ].join('\n\n');
    if (desc.isNotEmpty) _p('DESCRIPTION:${icsEscape(desc)}');
    if (t.location.isNotEmpty) _p('LOCATION:${icsEscape(t.location)}');
    if (t.url.isNotEmpty) _p('URL:${t.url}');
    _p('PRIORITY:${switch (t.priority) { Priority.high => 1, Priority.medium => 5, Priority.low => 9 }}');
    final cat = snap.categoryById(t.categoryId);
    if (cat != null) _p('CATEGORIES:${icsEscape(cat.name)}');
  }

  void _event(Task t, Task series, DateTime? recurrenceDate) {
    _p('BEGIN:VEVENT');
    _p('UID:${uidOf(series)}');
    _p('DTSTAMP:${_utc(now)}');
    if (recurrenceDate != null) {
      _start('RECURRENCE-ID', series, withTimeOf(recurrenceDate, series.start!));
    }
    final start = t.start!;
    _start('DTSTART', t, start);
    if (t.allDay) {
      _p('DTEND;VALUE=DATE:${_date(addDays(start, 1))}');
    } else {
      _start('DTEND', t, start.add(Duration(minutes: t.effectiveDurationMin)));
    }
    _common(t);
    if (recurrenceDate == null && series.isSeries) {
      var rule = series.rule!;
      var rrule = rule.toRRule();
      if (rule.until != null && !series.allDay) {
        // Con DTSTART con hora, UNTIL debe ser fecha-hora (UTC).
        final u = rule.until!;
        rrule = rule.copyWith(until: () => null).toRRule();
        rrule += ';UNTIL=${_utc(DateTime(u.year, u.month, u.day, 23, 59, 59))}';
      }
      _p('RRULE:$rrule');
      final skipped = [
        for (final ex in snap.exceptionsOf(series.id!).values)
          if (ex.type == ExceptionType.skipped) ex.originalDate,
      ]..sort();
      for (final d in skipped) {
        _start('EXDATE', series, withTimeOf(d, series.start!));
      }
    }
    for (final r in snap.remindersOf(series.id!)) {
      _p('BEGIN:VALARM');
      _p('ACTION:DISPLAY');
      _p('DESCRIPTION:${icsEscape(t.title)}');
      _p('TRIGGER:${icsDuration(r.minutesBefore, negative: true)}');
      _p('END:VALARM');
    }
    _p('END:VEVENT');
  }

  void _todo(Task t) {
    _p('BEGIN:VTODO');
    _p('UID:${uidOf(t)}');
    _p('DTSTAMP:${_utc(now)}');
    _common(t);
    _p('STATUS:${t.isCompleted ? 'COMPLETED' : 'NEEDS-ACTION'}');
    if (t.isCompleted && t.completedAt != null) _p('COMPLETED:${_utc(t.completedAt!)}');
    _p('END:VTODO');
  }
}

// =========================================================== importar

/// Convierte una hora leída del .ics a hora de pared local del dispositivo.
/// [tzid] es el TZID del parámetro (o null); [utc] si acababa en «Z».
typedef IcsTimeConverter = DateTime Function(DateTime wall, String? tzid, bool utc);

DateTime identityConverter(DateTime wall, String? tzid, bool utc) =>
    utc ? DateTime.utc(wall.year, wall.month, wall.day, wall.hour, wall.minute, wall.second).toLocal() : wall;

/// Evento o tarea leído de un .ics.
class IcsItem {
  IcsItem({this.uid = ''});
  String uid;
  String title = '';
  String notes = '';
  DateTime? start;
  bool allDay = false;
  int? durationMin;
  String location = '';
  String url = '';
  Priority priority = Priority.medium;
  String? categoryName;
  String? rrule;

  /// La regla usa partes que la app no soporta: se importa sin repetición.
  bool unsupportedRule = false;

  /// Evento de varios días: se importa en su primer día.
  bool multiDay = false;
  bool isTodo = false;
  bool completed = false;

  /// STATUS:CANCELLED: no se importa.
  bool cancelled = false;
  final List<DateTime> exdates = [];
  final List<int> reminders = [];

  /// Ocurrencias modificadas (VEVENT con RECURRENCE-ID): fecha original → item.
  final Map<String, IcsItem> overrides = {};
  DateTime? recurrenceDate;

  /// Convierte el item en tarea de la app.
  Task toTask({required String tz, required DateTime now, int? categoryId}) => Task(
        title: title.isEmpty ? '(sin título)' : title,
        notes: notes,
        start: start,
        allDay: allDay,
        durationMin: allDay ? null : durationMin,
        location: location,
        url: url,
        priority: priority,
        categoryId: categoryId,
        status: completed ? TaskStatus.completed : TaskStatus.pending,
        completedAt: completed ? now : null,
        rrule: unsupportedRule ? null : rrule,
        tz: tz,
        createdAt: now,
        updatedAt: now,
        icsUid: uid,
      );
}

class _Prop {
  _Prop(this.name, this.params, this.value);
  final String name;
  final Map<String, String> params;
  final String value;
}

_Prop? _parseLine(String line) {
  var inQuotes = false;
  var colon = -1;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') inQuotes = !inQuotes;
    if (c == ':' && !inQuotes) {
      colon = i;
      break;
    }
  }
  if (colon < 0) return null;
  final left = line.substring(0, colon);
  final value = line.substring(colon + 1);
  final parts = <String>[];
  final cur = StringBuffer();
  inQuotes = false;
  for (var i = 0; i < left.length; i++) {
    final c = left[i];
    if (c == '"') inQuotes = !inQuotes;
    if (c == ';' && !inQuotes) {
      parts.add(cur.toString());
      cur.clear();
    } else {
      cur.write(c);
    }
  }
  parts.add(cur.toString());
  final params = <String, String>{};
  for (final p in parts.skip(1)) {
    final eq = p.indexOf('=');
    if (eq > 0) params[p.substring(0, eq).toUpperCase()] = p.substring(eq + 1).replaceAll('"', '');
  }
  return _Prop(parts.first.toUpperCase(), params, value);
}

class IcsParseResult {
  IcsParseResult(this.items, this.calendarName);
  final List<IcsItem> items;
  final String? calendarName;
}

class IcsParser {
  IcsParser({IcsTimeConverter? convert}) : convert = convert ?? identityConverter;
  final IcsTimeConverter convert;

  static const _supportedKeys = {'FREQ', 'INTERVAL', 'BYDAY', 'BYMONTHDAY', 'UNTIL', 'COUNT', 'WKST', 'BYMONTH'};

  (DateTime, bool allDay)? _time(_Prop p) {
    final v = p.value.trim();
    final isDate = p.params['VALUE'] == 'DATE' || RegExp(r'^\d{8}$').hasMatch(v);
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?').firstMatch(v);
    if (m == null) return null;
    int g(int i) => int.tryParse(m.group(i) ?? '') ?? 0;
    final wall = DateTime(g(1), g(2), g(3), g(4), g(5), g(6));
    if (isDate) return (DateTime(g(1), g(2), g(3)), true);
    final local = convert(wall, p.params['TZID'], m.group(7) != null);
    return (DateTime(local.year, local.month, local.day, local.hour, local.minute), false);
  }

  /// Comprueba si la RRULE se puede representar en la app.
  bool _ruleSupported(String rrule, DateTime start) {
    final parts = <String, String>{};
    for (final p in rrule.split(';')) {
      final eq = p.indexOf('=');
      if (eq > 0) parts[p.substring(0, eq).toUpperCase()] = p.substring(eq + 1).toUpperCase();
    }
    if (!parts.keys.every(_supportedKeys.contains)) return false;
    final freq = parts['FREQ'];
    if (!{'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'}.contains(freq)) return false;
    final byDay = parts['BYDAY'];
    if (byDay != null) {
      final positional = byDay.split(',').any((d) => RegExp(r'^[+-]?\d').hasMatch(d));
      if (freq == 'WEEKLY' && positional) return false;
      if (freq == 'MONTHLY' && (!positional || byDay.contains(','))) return false;
      if (freq == 'DAILY' || freq == 'YEARLY') return false;
    }
    final byMonthDay = parts['BYMONTHDAY'];
    if (byMonthDay != null && (byMonthDay.contains(',') || byMonthDay.startsWith('-') || freq != 'MONTHLY')) {
      return false;
    }
    final byMonth = parts['BYMONTH'];
    if (byMonth != null && (freq != 'YEARLY' || int.tryParse(byMonth) != start.month)) return false;
    return RecurrenceRule.tryParse(rrule) != null;
  }

  IcsParseResult parse(String text) {
    final unfolded = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').replaceAll(RegExp(r'\n[ \t]'), '');
    final items = <String, IcsItem>{};
    final overrides = <IcsItem>[];
    String? calName;
    IcsItem? cur;
    var inAlarm = false;
    var depthUnknown = 0;
    DateTime? end;
    int? duration;

    void finish() {
      final it = cur;
      if (it == null) return;
      if (it.start != null && !it.isTodo) {
        if (duration != null) {
          it.durationMin = duration;
        } else if (end != null) {
          final mins = end!.difference(it.start!).inMinutes;
          if (it.allDay) {
            if (daysBetween(it.start!, end!) > 1) it.multiDay = true;
          } else {
            it.durationMin = mins > 0 ? mins : null;
            if (daysBetween(it.start!, end!) >= 1 && mins > 24 * 60) it.multiDay = true;
          }
        }
      }
      if (it.rrule != null && it.start != null && !_ruleSupported(it.rrule!, it.start!)) {
        it.unsupportedRule = true;
      }
      if (it.recurrenceDate != null) {
        overrides.add(it);
      } else {
        items[it.uid] = it;
      }
      cur = null;
      end = null;
      duration = null;
    }

    var uidCounter = 0;
    for (final raw in unfolded.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;
      final p = _parseLine(line);
      if (p == null) continue;
      if (p.name == 'BEGIN') {
        final comp = p.value.toUpperCase();
        if (cur != null && comp == 'VALARM') {
          inAlarm = true;
        } else if (comp == 'VEVENT' || comp == 'VTODO') {
          cur = IcsItem()..isTodo = comp == 'VTODO';
        } else if (cur != null) {
          depthUnknown++;
        }
        continue;
      }
      if (p.name == 'END') {
        final comp = p.value.toUpperCase();
        if (comp == 'VALARM') {
          inAlarm = false;
        } else if (comp == 'VEVENT' || comp == 'VTODO') {
          if (cur != null && cur!.uid.isEmpty) cur!.uid = 'noid-${uidCounter++}';
          finish();
        } else if (depthUnknown > 0) {
          depthUnknown--;
        }
        continue;
      }
      if (cur == null) {
        if (p.name == 'X-WR-CALNAME') calName = icsUnescape(p.value);
        continue;
      }
      if (depthUnknown > 0) continue;
      final it = cur!;
      if (inAlarm) {
        if (p.name == 'TRIGGER' && p.params['VALUE'] != 'DATE-TIME') {
          final mins = parseIcsDuration(p.value);
          if (mins != null) {
            final before = mins <= 0 ? -mins : 0;
            if (!it.reminders.contains(before)) it.reminders.add(before);
          }
        }
        continue;
      }
      switch (p.name) {
        case 'UID':
          it.uid = p.value.trim();
        case 'SUMMARY':
          it.title = icsUnescape(p.value).trim();
        case 'DESCRIPTION':
          it.notes = icsUnescape(p.value).trim();
        case 'LOCATION':
          it.location = icsUnescape(p.value).trim();
        case 'URL':
          it.url = p.value.trim();
        case 'CATEGORIES':
          final first = icsUnescape(p.value).split(',').first.trim();
          if (first.isNotEmpty) it.categoryName = first;
        case 'PRIORITY':
          final n = int.tryParse(p.value.trim()) ?? 0;
          it.priority = n == 0 ? Priority.medium : n <= 4 ? Priority.high : n == 5 ? Priority.medium : Priority.low;
        case 'DTSTART':
          final t = _time(p);
          if (t != null) {
            it.start = t.$1;
            it.allDay = t.$2;
          }
        case 'DUE':
          if (it.isTodo && it.start == null) {
            final t = _time(p);
            if (t != null) {
              it.start = t.$1;
              it.allDay = t.$2;
            }
          }
        case 'DTEND':
          end = _time(p)?.$1;
        case 'DURATION':
          final d = parseIcsDuration(p.value);
          if (d != null && d > 0) duration = d;
        case 'RRULE':
          it.rrule = p.value.trim();
        case 'EXDATE':
          for (final v in p.value.split(',')) {
            final t = _time(_Prop('EXDATE', p.params, v));
            if (t != null) it.exdates.add(dateOnly(t.$1));
          }
        case 'RECURRENCE-ID':
          final t = _time(p);
          if (t != null) it.recurrenceDate = dateOnly(t.$1);
        case 'STATUS':
          final s = p.value.trim().toUpperCase();
          if (s == 'COMPLETED') it.completed = true;
          if (s == 'CANCELLED') it.cancelled = true;
        case 'COMPLETED':
          it.completed = true;
      }
    }

    // Ocurrencias modificadas → a su serie.
    for (final o in overrides) {
      final master = items[o.uid];
      if (master != null && master.rrule != null && !master.unsupportedRule) {
        master.overrides[formatDateKey(o.recurrenceDate!)] = o;
      } else {
        // Sin serie a la que asociarse: se importa como evento suelto.
        items['${o.uid}#${formatDateKey(o.recurrenceDate!)}'] = IcsItem(uid: '${o.uid}#${formatDateKey(o.recurrenceDate!)}')
          ..title = o.title
          ..notes = o.notes
          ..start = o.start
          ..allDay = o.allDay
          ..durationMin = o.durationMin
          ..location = o.location
          ..priority = o.priority
          ..categoryName = o.categoryName;
      }
    }
    final list = items.values.where((i) => !i.cancelled).toList()
      ..sort((a, b) {
        if (a.start == null && b.start == null) return a.title.compareTo(b.title);
        if (a.start == null) return 1;
        if (b.start == null) return -1;
        return a.start!.compareTo(b.start!);
      });
    for (final i in list) {
      // Una ocurrencia cancelada equivale a saltarla.
      for (final e in i.overrides.entries.where((e) => e.value.cancelled).toList()) {
        i.exdates.add(parseDateKey(e.key));
        i.overrides.remove(e.key);
      }
    }
    return IcsParseResult(list, calName);
  }
}

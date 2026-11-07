// RF-48: creación por texto natural, offline y basada en reglas.
// Idiomas: español, inglés y chino (se aceptan mezclados).
// Lo no reconocido queda en el título.

import '../models/task.dart';
import '../recurrence/recurrence_engine.dart';
import '../recurrence/recurrence_rule.dart';
import '../time.dart';

class HourMinute {
  const HourMinute(this.hour, this.minute);
  final int hour;
  final int minute;
  @override
  bool operator ==(Object other) => other is HourMinute && other.hour == hour && other.minute == minute;
  @override
  int get hashCode => hour * 60 + minute;
  @override
  String toString() => '$hour:${minute.toString().padLeft(2, '0')}';
}

class ParsedTask {
  ParsedTask({
    required this.title,
    this.date,
    this.time,
    this.durationMin,
    this.rule,
    this.priority,
    this.categoryId,
  });
  final String title;
  final DateTime? date;
  final HourMinute? time;
  final int? durationMin;
  final RecurrenceRule? rule;
  final Priority? priority;
  final int? categoryId;

  @override
  String toString() =>
      'ParsedTask($title, ${date == null ? null : formatDateKey(date!)}, $time, ${durationMin}min, $rule, $priority, cat=$categoryId)';
}

// Límites de palabra que funcionan con ñ, acentos y caracteres chinos.
const _b = r'(?<![\p{L}\p{N}])';
const _e = r'(?![\p{L}\p{N}])';

const _weekdays = <String, int>{
  // español
  'lunes': 1, 'martes': 2, 'miércoles': 3, 'miercoles': 3, 'jueves': 4,
  'viernes': 5, 'sábado': 6, 'sabado': 6, 'sábados': 6, 'sabados': 6,
  'domingo': 7, 'domingos': 7,
  // inglés
  'monday': 1, 'mondays': 1, 'mon': 1, 'tuesday': 2, 'tuesdays': 2, 'tue': 2,
  'tues': 2, 'wednesday': 3, 'wednesdays': 3, 'wed': 3, 'thursday': 4,
  'thursdays': 4, 'thu': 4, 'thur': 4, 'thurs': 4, 'friday': 5, 'fridays': 5,
  'fri': 5, 'saturday': 6, 'saturdays': 6, 'sat': 6, 'sunday': 7,
  'sundays': 7, 'sun': 7,
};

const _months = <String, int>{
  'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4, 'mayo': 5, 'junio': 6,
  'julio': 7, 'agosto': 8, 'septiembre': 9, 'setiembre': 9, 'octubre': 10,
  'noviembre': 11, 'diciembre': 12,
  'january': 1, 'jan': 1, 'february': 2, 'feb': 2, 'march': 3, 'mar': 3,
  'april': 4, 'apr': 4, 'may': 5, 'june': 6, 'jun': 6, 'july': 7, 'jul': 7,
  'august': 8, 'aug': 8, 'september': 9, 'sep': 9, 'sept': 9, 'october': 10,
  'oct': 10, 'november': 11, 'nov': 11, 'december': 12, 'dec': 12,
};

const _zhWeekday = <String, int>{
  '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7,
};

String _alt(Iterable<String> words) {
  final list = words.toList()..sort((a, b) => b.length.compareTo(a.length));
  return list.map(RegExp.escape).join('|');
}

/// Convierte números chinos sencillos (hasta 99) o dígitos.
int? zhNumber(String s) {
  final d = int.tryParse(s);
  if (d != null) return d;
  const digits = {'零': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4, '五': 5,
    '六': 6, '七': 7, '八': 8, '九': 9};
  if (s == '十') return 10;
  if (s.contains('十')) {
    final parts = s.split('十');
    final tens = parts[0].isEmpty ? 1 : digits[parts[0]];
    final ones = parts[1].isEmpty ? 0 : digits[parts[1]];
    if (tens == null || ones == null) return null;
    return tens * 10 + ones;
  }
  if (s.length == 1) return digits[s];
  return null;
}

class QuickParser {
  QuickParser({
    required this.now,
    this.categories = const {},
    this.weekStartsMonday = true,
  });

  final DateTime now;

  /// Nombre de categoría → id.
  final Map<String, int> categories;
  final bool weekStartsMonday;

  late String _text;
  DateTime? _date;
  HourMinute? _time;
  int? _duration;
  RecurrenceRule? _rule;
  Priority? _priority;
  int? _category;
  int? _meridiemHint; // 0 = am, 12 = pm

  DateTime get _today => dateOnly(now);

  ParsedTask parse(String input) {
    _text = ' $input ';
    _date = null;
    _time = null;
    _duration = null;
    _rule = null;
    _priority = null;
    _category = null;
    _meridiemHint = null;

    _tags();
    _recurrence();
    _duration_();
    _times();
    _dates();
    _normalize();

    final title = _text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s,.;:\-]+|[\s,.;:\-]+$'), '')
        .trim();
    return ParsedTask(
      title: title,
      date: _date,
      time: _time,
      durationMin: _duration,
      rule: _rule,
      priority: _priority,
      categoryId: _category,
    );
  }

  /// Busca [pattern]; si hay coincidencia llama a [onMatch] y, si devuelve
  /// true, borra el fragmento del texto.
  bool _take(String pattern, bool Function(RegExpMatch m) onMatch) {
    final re = RegExp(pattern, caseSensitive: false, unicode: true);
    final m = re.firstMatch(_text);
    if (m == null) return false;
    if (!onMatch(m)) return false;
    _text = _text.replaceRange(m.start, m.end, ' ');
    return true;
  }

  void _takeAll(String pattern, bool Function(RegExpMatch m) onMatch) {
    while (_take(pattern, onMatch)) {}
  }

  // ------------------------------------------------------------- etiquetas

  void _tags() {
    _takeAll(r'(?<!\S)!(alta|high|h|1|高|media|medium|m|2|中|baja|low|l|3|低)' + _e, (m) {
      final v = m.group(1)!.toLowerCase();
      _priority = switch (v) {
        'alta' || 'high' || 'h' || '1' || '高' => Priority.high,
        'media' || 'medium' || 'm' || '2' || '中' => Priority.medium,
        _ => Priority.low,
      };
      return true;
    });
    final lower = {for (final e in categories.entries) e.key.toLowerCase(): e.value};
    _takeAll(r'(?<!\S)#([\p{L}\p{N}_\-]+)', (m) {
      final id = lower[m.group(1)!.toLowerCase()];
      if (id == null) return false; // Desconocida: se queda en el título.
      _category = id;
      return true;
    });
  }

  // ------------------------------------------------------------ repetición

  void _recurrence() {
    final wd = _alt(_weekdays.keys);
    // Días laborables.
    _take('$_b(?:entre\\s+semana|(?:los\\s+)?días\\s+laborables|every\\s+weekday|weekdays)$_e', (_) {
      _rule = const RecurrenceRule(freq: Frequency.weekly, byWeekdays: {1, 2, 3, 4, 5});
      return true;
    });
    if (_rule != null) return;
    // «cada 2 semanas», «every 3 days».
    _take('$_b(?:cada|every)\\s+(\\d+)\\s+(días|dias|days|semanas|weeks|meses|months|años|anos|years)$_e', (m) {
      final n = int.parse(m.group(1)!);
      final u = m.group(2)!.toLowerCase();
      final f = u.startsWith('d')
          ? Frequency.daily
          : (u.startsWith('s') || u.startsWith('w'))
              ? Frequency.weekly
              : (u.startsWith('me') || u.startsWith('mo'))
                  ? Frequency.monthly
                  : Frequency.yearly;
      _rule = RecurrenceRule(freq: f, interval: n < 1 ? 1 : n);
      return true;
    });
    // «cada lunes y jueves», «los martes», «every monday and wednesday».
    _take('$_b(?:cada|todos\\s+los|los|every|on)\\s+((?:$wd)(?:\\s*(?:,|y|e|and|&)\\s*(?:$wd))*)$_e', (m) {
      final days = RegExp(wd, caseSensitive: false, unicode: true)
          .allMatches(m.group(1)!)
          .map((x) => _weekdays[x.group(0)!.toLowerCase()]!)
          .toSet();
      // «on monday» solo es repetición si es plural («on mondays»).
      final word = m.group(0)!.trim().toLowerCase();
      if (word.startsWith('on ') && !m.group(1)!.toLowerCase().endsWith('s')) return false;
      if (word.startsWith('los ') &&
          !RegExp(r'(es|os|s)$').hasMatch(m.group(1)!.toLowerCase()) ) {
        return false;
      }
      final r = _rule;
      _rule = RecurrenceRule(
          freq: Frequency.weekly, interval: r?.interval ?? 1, byWeekdays: days);
      return true;
    });
    if (_rule != null) return;
    _take('$_b(?:cada\\s+día|cada\\s+dia|todos\\s+los\\s+días|todos\\s+los\\s+dias|diariamente|a\\s+diario|every\\s*day|daily)$_e', (_) {
      _rule = const RecurrenceRule(freq: Frequency.daily);
      return true;
    });
    _take('$_b(?:cada\\s+semana|semanalmente|todas\\s+las\\s+semanas|every\\s+week|weekly)$_e', (_) {
      _rule = const RecurrenceRule(freq: Frequency.weekly);
      return true;
    });
    _take('$_b(?:cada\\s+mes|mensualmente|todos\\s+los\\s+meses|every\\s+month|monthly)$_e', (_) {
      _rule = const RecurrenceRule(freq: Frequency.monthly);
      return true;
    });
    _take('$_b(?:cada\\s+año|anualmente|todos\\s+los\\s+años|every\\s+year|yearly|annually)$_e', (_) {
      _rule = const RecurrenceRule(freq: Frequency.yearly);
      return true;
    });
    if (_rule != null) return;

    // Chino.
    _take(r'(?:每个?工作日|工作日)', (_) {
      _rule = const RecurrenceRule(freq: Frequency.weekly, byWeekdays: {1, 2, 3, 4, 5});
      return true;
    });
    if (_rule != null) return;
    _take(r'每(?:个)?(?:周|星期|礼拜)([一二三四五六日天、和,，]+)', (m) {
      final days = <int>{
        for (final ch in m.group(1)!.split(''))
          if (_zhWeekday[ch] != null) _zhWeekday[ch]!,
      };
      _rule = RecurrenceRule(freq: Frequency.weekly, byWeekdays: days);
      return true;
    });
    _take(r'每(\d+|[一二两三四五六七八九十]+)(天|周|个月|月|年)', (m) {
      final n = zhNumber(m.group(1)!) ?? 1;
      final f = switch (m.group(2)) {
        '天' => Frequency.daily,
        '周' => Frequency.weekly,
        '年' => Frequency.yearly,
        _ => Frequency.monthly,
      };
      _rule = RecurrenceRule(freq: f, interval: n);
      return true;
    });
    _take(r'每(?:个)?月(\d{1,2}|[一二三四五六七八九十]+)[号日]', (m) {
      _rule = RecurrenceRule(freq: Frequency.monthly, byMonthDay: zhNumber(m.group(1)!));
      return true;
    });
    _take(r'(?:每天|每日)', (_) {
      _rule = const RecurrenceRule(freq: Frequency.daily);
      return true;
    });
    _take(r'(?:每周|每星期)', (_) {
      _rule = const RecurrenceRule(freq: Frequency.weekly);
      return true;
    });
    _take(r'每(?:个)?月', (_) {
      _rule = const RecurrenceRule(freq: Frequency.monthly);
      return true;
    });
    _take(r'每年', (_) {
      _rule = const RecurrenceRule(freq: Frequency.yearly);
      return true;
    });
  }

  // --------------------------------------------------------------- duración

  void _duration_() {
    int minutesOf(String n, String unit) {
      final v = double.parse(n.replaceAll(',', '.'));
      final u = unit.toLowerCase();
      return u.startsWith('h') ? (v * 60).round() : v.round();
    }

    _take('$_b(?:durante|por|for)\\s+(\\d+)\\s*h\\s*(\\d{1,2})\\s*(?:m|min)?$_e', (m) {
      _duration = int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
      return true;
    });
    if (_duration == null) {
      _take('$_b(?:durante|por|for)\\s+(?:una?\\s+|an?\\s+)?(\\d+(?:[.,]\\d+)?)?\\s*(h|horas?|hours?|hrs?|min|minutos?|minutes?|mins?)$_e', (m) {
        _duration = minutesOf(m.group(1) ?? '1', m.group(2)!);
        return true;
      });
    }
    if (_duration == null) {
      _take('$_b(\\d+)\\s*(?:min|mins|minutos|minutes)$_e', (m) {
        _duration = int.parse(m.group(1)!);
        return true;
      });
    }
    if (_duration == null) {
      _take(r'(\d+|[一二两三四五六七八九十]+|半)\s*(?:个)?(半)?\s*(?:小时|钟头)', (m) {
        final g = m.group(1)!;
        final base = g == '半' ? 0.5 : (zhNumber(g) ?? 1).toDouble();
        _duration = ((base + (m.group(2) != null ? 0.5 : 0)) * 60).round();
        return true;
      });
    }
    if (_duration == null) {
      _take(r'(\d+|[一二两三四五六七八九十]+)\s*分钟', (m) {
        _duration = zhNumber(m.group(1)!);
        return true;
      });
    }
  }

  // ------------------------------------------------------------------ horas

  void _setTime(int h, int m, {String? meridiem}) {
    var hour = h;
    final mer = meridiem?.toLowerCase().replaceAll('.', '');
    if (mer != null) {
      if ((mer == 'pm' || mer == 'tarde' || mer == 'noche') && hour < 12) hour += 12;
      if ((mer == 'am' || mer == 'mañana' || mer == 'manana') && hour == 12) hour = 0;
    }
    if (hour > 23 || m > 59) return;
    _time = HourMinute(hour, m);
  }

  void _times() {
    // Chino: 下午6点、上午9点半、18:30.
    _take(r'(凌晨|早上|早晨|上午|中午|下午|傍晚|晚上|今晚)?\s*(\d{1,2}|[零一二两三四五六七八九十]{1,3})\s*[点點时時]\s*(?:(\d{1,2}|[零一二三四五六七八九十]{1,3})\s*分?|(半)|(一刻)|(三刻))?', (m) {
      var h = zhNumber(m.group(2)!);
      if (h == null) return false;
      final pre = m.group(1);
      var min = 0;
      if (m.group(3) != null) min = zhNumber(m.group(3)!) ?? 0;
      if (m.group(4) != null) min = 30;
      if (m.group(5) != null) min = 15;
      if (m.group(6) != null) min = 45;
      if (pre == '下午' || pre == '傍晚' || pre == '晚上' || pre == '今晚') {
        if (h < 12) h += 12;
      } else if (pre == '中午' && h < 6) {
        h += 12;
      }
      if (pre == '今晚') _date ??= _today;
      _setTime(h, min);
      return true;
    });
    if (_time != null) return;

    // «por la mañana», «in the evening», «tonight» sin hora concreta: se
    // recuerda como pista y se quita del texto (evita confundir «mañana»).
    _take('$_b(?:por|de)\\s+la\\s+(mañana|manana|tarde|noche)$_e', (m) {
      final w = m.group(1)!.toLowerCase();
      _meridiemHint = (w == 'tarde' || w == 'noche') ? 12 : 0;
      return true;
    });
    _take('$_b(?:in\\s+the\\s+)(morning|afternoon|evening)$_e', (m) {
      _meridiemHint = m.group(1)!.toLowerCase() == 'morning' ? 0 : 12;
      return true;
    });
    _take('${_b}tonight$_e', (_) {
      _meridiemHint = 12;
      _date ??= _today;
      return true;
    });

    // 10am, 6:30 pm, 6 p.m.
    _take('$_b(?:a\\s+las?\\s+|at\\s+)?(\\d{1,2})(?::(\\d{2}))?\\s*(a\\.?m\\.?|p\\.?m\\.?)(?![\\p{L}])', (m) {
      final h = int.parse(m.group(1)!);
      if (h > 12) return false;
      _setTime(h, int.tryParse(m.group(2) ?? '') ?? 0, meridiem: m.group(3));
      return true;
    });
    if (_time != null) return _applyHint();

    // 18:30, 18h30, 18.30, a las 9:15
    _take('$_b(?:a\\s+las?\\s+|at\\s+)?(\\d{1,2})(?::|h|\\.)(\\d{2})$_e', (m) {
      _setTime(int.parse(m.group(1)!), int.parse(m.group(2)!));
      return _time != null;
    });
    if (_time != null) return _applyHint();

    // 18h, 18 horas
    _take('$_b(?:a\\s+las?\\s+)?(\\d{1,2})\\s*(?:h|hrs?|horas)$_e', (m) {
      _setTime(int.parse(m.group(1)!), 0);
      return _time != null;
    });
    if (_time != null) return _applyHint();

    // «a las 9», «at 7»
    _take('$_b(?:a\\s+las?|at)\\s+(\\d{1,2})$_e', (m) {
      _setTime(int.parse(m.group(1)!), 0);
      return _time != null;
    });
    if (_time != null) return _applyHint();

    _take('$_b(?:al\\s+|a\\s+)?(?:mediodía|mediodia|noon|midday)$_e', (_) {
      _time = const HourMinute(12, 0);
      return true;
    });
    if (_time != null) return;

    // Solo pista de franja: hora por defecto.
    if (_meridiemHint != null) {
      _time = _meridiemHint == 12 ? const HourMinute(18, 0) : const HourMinute(9, 0);
      _meridiemHint = null;
    }
  }

  void _applyHint() {
    if (_meridiemHint == 12 && _time != null && _time!.hour < 12) {
      _time = HourMinute(_time!.hour + 12, _time!.minute);
    }
    _meridiemHint = null;
  }

  // ----------------------------------------------------------------- fechas

  DateTime _nextWeekday(int wd, {bool includeToday = true}) {
    final diff = (wd - _today.weekday + 7) % 7;
    return addDays(_today, diff == 0 && !includeToday ? 7 : diff);
  }

  DateTime _weekdayNextWeek(int wd) {
    final ws = startOfWeek(_today, weekStartsMonday: weekStartsMonday);
    final next = addDays(ws, 7);
    final offset = weekStartsMonday ? wd - 1 : wd % 7;
    return addDays(next, offset);
  }

  DateTime _withYear(int month, int day, [int? year]) {
    if (year != null) {
      final y = year < 100 ? 2000 + year : year;
      return DateTime(y, month, day);
    }
    var d = DateTime(_today.year, month, day);
    if (d.isBefore(_today)) d = DateTime(_today.year + 1, month, day);
    return d;
  }

  void _dates() {
    final wd = _alt(_weekdays.keys);
    final mo = _alt(_months.keys);

    // Chino.
    _take(r'(大后天|后天|明天|今天|明日|今日)', (m) {
      _date = addDays(_today, switch (m.group(1)) {
        '大后天' => 3,
        '后天' => 2,
        '明天' || '明日' => 1,
        _ => 0,
      });
      return true;
    });
    _take(r'(下|这|本)?(?:个)?(?:周|星期|礼拜)([一二三四五六日天])', (m) {
      final d = _zhWeekday[m.group(2)!]!;
      _date = m.group(1) == '下' ? _weekdayNextWeek(d) : _nextWeekday(d);
      return true;
    });
    _take(r'(?:(\d{4})年)?(\d{1,2})月(\d{1,2})[日号]?', (m) {
      _date = _withYear(int.parse(m.group(2)!), int.parse(m.group(3)!),
          m.group(1) == null ? null : int.parse(m.group(1)!));
      return true;
    });
    if (_date == null) {
      _take(r'(?<!\d)(\d{1,2})[号日]', (m) {
        _date = _nextMonthDay(int.parse(m.group(1)!));
        return true;
      });
    }

    // Español / inglés.
    _take('$_b(?:pasado\\s+mañana|pasado\\s+manana|(?:the\\s+)?day\\s+after\\s+tomorrow)$_e', (_) {
      _date = addDays(_today, 2);
      return true;
    });
    _take('$_b(?:mañana|manana|tomorrow)$_e', (_) {
      _date = addDays(_today, 1);
      return true;
    });
    _take('$_b(?:hoy|today)$_e', (_) {
      _date = _today;
      return true;
    });
    _take('$_b(?:el\\s+)?(?:próximo|proximo|next)\\s+($wd)$_e', (m) {
      _date = _weekdayNextWeek(_weekdays[m.group(1)!.toLowerCase()]!);
      return true;
    });
    _take('$_b(?:el\\s+)?($wd)\\s+(?:que\\s+viene|próximo|proximo)$_e', (m) {
      _date = _weekdayNextWeek(_weekdays[m.group(1)!.toLowerCase()]!);
      return true;
    });
    _take('$_b(?:el\\s+|este\\s+|on\\s+|this\\s+)?($wd)$_e', (m) {
      _date = _nextWeekday(_weekdays[m.group(1)!.toLowerCase()]!);
      return true;
    });
    _take('$_b(?:el\\s+)?(\\d{1,2})\\s+de\\s+($mo)(?:\\s+(?:de\\s+)?(\\d{4}))?$_e', (m) {
      _date = _withYear(_months[m.group(2)!.toLowerCase()]!, int.parse(m.group(1)!),
          m.group(3) == null ? null : int.parse(m.group(3)!));
      return true;
    });
    _take('$_b(?:on\\s+)?($mo)\\.?\\s+(\\d{1,2})(?:st|nd|rd|th)?(?:,?\\s+(\\d{4}))?$_e', (m) {
      _date = _withYear(_months[m.group(1)!.toLowerCase()]!, int.parse(m.group(2)!),
          m.group(3) == null ? null : int.parse(m.group(3)!));
      return true;
    });
    _take('$_b(?:on\\s+)?(\\d{1,2})(?:st|nd|rd|th)?\\s+(?:of\\s+)?($mo)(?:\\s+(\\d{4}))?$_e', (m) {
      _date = _withYear(_months[m.group(2)!.toLowerCase()]!, int.parse(m.group(1)!),
          m.group(3) == null ? null : int.parse(m.group(3)!));
      return true;
    });
    // dd/mm(/aaaa) — formato día/mes.
    _take('$_b(\\d{1,2})/(\\d{1,2})(?:/(\\d{2,4}))?$_e', (m) {
      final d = int.parse(m.group(1)!), mo = int.parse(m.group(2)!);
      if (mo < 1 || mo > 12 || d < 1 || d > 31) return false;
      _date = _withYear(mo, d, m.group(3) == null ? null : int.parse(m.group(3)!));
      return true;
    });
    _take('$_b(?:el\\s+(?:día\\s+|dia\\s+)?|the\\s+)(\\d{1,2})(?:st|nd|rd|th)?$_e', (m) {
      final d = int.parse(m.group(1)!);
      if (d < 1 || d > 31) return false;
      _date = _nextMonthDay(d);
      return true;
    });
  }

  DateTime _nextMonthDay(int day) {
    for (var i = 0; i < 13; i++) {
      final first = DateTime(_today.year, _today.month + i, 1);
      if (day <= daysInMonth(first.year, first.month)) {
        final d = DateTime(first.year, first.month, day);
        if (!d.isBefore(_today)) return d;
      }
    }
    return _today;
  }

  // ------------------------------------------------------------ coherencia

  void _normalize() {
    final r = _rule;
    if (r == null) return;
    // Sin fecha: la primera ocurrencia desde hoy.
    var start = _date ?? _today;
    if (r.freq == Frequency.monthly && r.byMonthDay != null && _date == null) {
      start = _nextMonthDay(r.byMonthDay!);
    }
    final next = RecurrenceEngine.nextOnOrAfter(r, start, start);
    _date = next == null ? start : dateOnly(next);
    // «18h cada lunes» sin hora → la de inicio por defecto la pone la UI.
  }
}

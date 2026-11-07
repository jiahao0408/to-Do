import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/task.dart';
import '../../domain/recurrence/recurrence_rule.dart';
import '../../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get localeTag => Localizations.localeOf(this).toLanguageTag();
}

class Fmt {
  Fmt(this.locale);
  final String locale;

  factory Fmt.of(BuildContext context) => Fmt(context.localeTag);

  String time(DateTime d) => DateFormat.Hm(locale).format(d);
  String dayMonth(DateTime d) => DateFormat.MMMd(locale).format(d);
  String weekdayDayMonth(DateTime d) => DateFormat.MMMEd(locale).format(d);
  String fullDate(DateTime d) => DateFormat.yMMMMEEEEd(locale).format(d);
  String monthYear(DateTime d) => DateFormat.yMMMM(locale).format(d);
  String monthYearShort(DateTime d) => DateFormat.yMMM(locale).format(d);
  String shortDate(DateTime d) => DateFormat.yMMMd(locale).format(d);
  String weekdayShort(DateTime d) => DateFormat.E(locale).format(d);
  String weekdayName(int weekday) =>
      DateFormat.EEEE(locale).format(DateTime(2024, 1, weekday)); // 1 ene 2024 = lunes
  String weekdayNarrow(int weekday) =>
      DateFormat.E(locale).format(DateTime(2024, 1, weekday));
  String dateTime(DateTime d) => '${weekdayDayMonth(d)} ${time(d)}';

  String duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

String priorityLabel(AppLocalizations l, Priority p) => switch (p) {
      Priority.high => l.priorityHigh,
      Priority.medium => l.priorityMedium,
      Priority.low => l.priorityLow,
    };

Color priorityColor(Priority p) => switch (p) {
      Priority.high => const Color(0xFFE53935),
      Priority.medium => const Color(0xFFFFA000),
      Priority.low => const Color(0xFF9E9E9E),
    };

String reminderLabel(AppLocalizations l, int minutes) {
  if (minutes == 0) return l.reminderAtTime;
  if (minutes % 1440 == 0) return l.reminderDaysBefore(minutes ~/ 1440);
  if (minutes % 60 == 0) return l.reminderHoursBefore(minutes ~/ 60);
  return l.reminderMinutesBefore(minutes);
}

String joinList(AppLocalizations l, List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.first;
  return '${items.sublist(0, items.length - 1).join(l.listSeparator)} ${l.listAnd} ${items.last}';
}

/// RF-22: resumen legible de una regla, p. ej. «Cada 2 semanas, lunes y
/// jueves, hasta el 30 jun».
String describeRule(AppLocalizations l, Fmt f, RecurrenceRule r, DateTime start) {
  final parts = <String>[];
  switch (r.freq) {
    case Frequency.daily:
      parts.add(l.rrEveryDay(r.interval));
    case Frequency.weekly:
      parts.add(l.rrEveryWeek(r.interval));
      final days = (r.byWeekdays.isEmpty ? {start.weekday} : r.byWeekdays).toList()
        ..sort();
      parts.add(joinList(l, [for (final d in days) f.weekdayName(d)]));
    case Frequency.monthly:
      parts.add(l.rrEveryMonth(r.interval));
      if (r.isPositional) {
        parts.add(l.rrOnNth(l.ordinal(r.bySetPos == -1 ? 'last' : '${r.bySetPos}'),
            f.weekdayName(r.byPosWeekday!)));
      } else {
        parts.add(l.rrOnMonthDay(r.byMonthDay ?? start.day));
      }
    case Frequency.yearly:
      parts.add(l.rrEveryYear(r.interval));
      parts.add(l.rrOnDate(f.dayMonth(start)));
  }
  if (r.until != null) parts.add(l.rrUntil(f.dayMonth(r.until!)));
  if (r.count != null) parts.add(l.rrCount(r.count!));
  return parts.join(l.listSeparator);
}

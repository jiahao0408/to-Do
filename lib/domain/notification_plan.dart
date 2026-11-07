// Cálculo puro de qué notificaciones programar (RF-43, RF-44, RF-46, RF-47).
// iOS solo admite ~64 notificaciones pendientes: se programan las más
// próximas y se repone al abrir la app.

import 'models/task.dart';
import 'snapshot.dart';
import 'time.dart';

enum PlannedKind { reminder, dailySummary, weeklySummary, monthlySummary }

class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.fireAt,
    required this.tz,
    this.occurrence,
    this.minutesBefore = 0,
    this.summaryDay,
  });

  /// Id estable (31 bits) para poder cancelar/actualizar.
  final int id;
  final PlannedKind kind;

  /// Hora de pared local en la que debe sonar.
  final DateTime fireAt;
  final String tz;
  final Occurrence? occurrence;
  final int minutesBefore;

  /// Para los resúmenes: el día/periodo resumido.
  final DateTime? summaryDay;

  /// Carga útil del aviso: `taskId|yyyy-MM-dd` o `summary`.
  String get payload {
    final o = occurrence;
    if (o == null) return 'summary|${formatDateKey(summaryDay ?? fireAt)}';
    final date = o.occurrenceDate == null ? '' : formatDateKey(o.occurrenceDate!);
    return 'task|${o.taskId}|$date';
  }
}

class SummarySettings {
  const SummarySettings({
    this.dailyEnabled = false,
    this.dailyMinute = 8 * 60,
    this.weeklyEnabled = false,
    this.weeklyWeekday = DateTime.monday,
    this.weeklyMinute = 8 * 60,
    this.monthlyEnabled = false,
    this.monthlyMinute = 8 * 60,
  });
  final bool dailyEnabled;
  final int dailyMinute;
  final bool weeklyEnabled;
  final int weeklyWeekday;
  final int weeklyMinute;
  final bool monthlyEnabled;
  final int monthlyMinute;
}

/// Id estable para un recordatorio de una ocurrencia.
int reminderNotificationId(Occurrence o, int minutesBefore) {
  final s = '${o.key}#$minutesBefore';
  // FNV-1a de 31 bits; los ids < 1000 se reservan para resúmenes.
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0x7fffffff;
  }
  return h < 1000 ? h + 1000 : h;
}

class NotificationPlanner {
  const NotificationPlanner({this.maxPending = 60, this.horizonDays = 30});

  /// Máximo de avisos programados a la vez (iOS: 64 en total).
  final int maxPending;
  final int horizonDays;

  List<PlannedNotification> plan(
    AppSnapshot snap,
    DateTime now, {
    required String tz,
    SummarySettings summaries = const SummarySettings(),
  }) {
    final out = <PlannedNotification>[];
    final today = dateOnly(now);

    // Resúmenes: reservan sitio primero.
    if (summaries.dailyEnabled) {
      for (var i = 0; i < 3; i++) {
        final day = addDays(today, i);
        final at = day.add(Duration(minutes: summaries.dailyMinute));
        if (at.isAfter(now)) {
          out.add(PlannedNotification(
            id: 100 + i,
            kind: PlannedKind.dailySummary,
            fireAt: at,
            tz: tz,
            summaryDay: day,
          ));
        }
      }
    }
    if (summaries.weeklyEnabled) {
      for (var i = 0; i < 8; i++) {
        final day = addDays(today, i);
        if (day.weekday != summaries.weeklyWeekday) continue;
        final at = day.add(Duration(minutes: summaries.weeklyMinute));
        if (at.isAfter(now)) {
          out.add(PlannedNotification(
            id: 200,
            kind: PlannedKind.weeklySummary,
            fireAt: at,
            tz: tz,
            summaryDay: day,
          ));
          break;
        }
      }
    }
    if (summaries.monthlyEnabled) {
      var first = DateTime(now.year, now.month, 1);
      var at = first.add(Duration(minutes: summaries.monthlyMinute));
      if (!at.isAfter(now)) {
        first = DateTime(now.year, now.month + 1, 1);
        at = first.add(Duration(minutes: summaries.monthlyMinute));
      }
      out.add(PlannedNotification(
        id: 300,
        kind: PlannedKind.monthlySummary,
        fireAt: at,
        tz: tz,
        summaryDay: first,
      ));
    }

    // Recordatorios. Se mira 1 día atrás por avisos «1 día antes» que caen hoy.
    final reminders = <PlannedNotification>[];
    final occs = snap.occurrencesBetween(today, addDays(today, horizonDays + 1));
    for (final o in occs) {
      if (o.completed || o.task.status == TaskStatus.discarded) continue;
      final start = o.task.start;
      if (start == null) continue;
      final mins = snap.remindersOf(o.taskId);
      for (final r in mins) {
        // Todo el día: el aviso se calcula desde las 9:00 de ese día.
        final anchor = o.task.allDay ? DateTime(start.year, start.month, start.day, 9) : start;
        final at = anchor.subtract(Duration(minutes: r.minutesBefore));
        if (!at.isAfter(now)) continue;
        reminders.add(PlannedNotification(
          id: reminderNotificationId(o, r.minutesBefore),
          kind: PlannedKind.reminder,
          fireAt: at,
          tz: o.task.tz,
          occurrence: o,
          minutesBefore: r.minutesBefore,
        ));
      }
    }
    reminders.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    final room = maxPending - out.length;
    out.addAll(reminders.take(room < 0 ? 0 : room));
    return out;
  }
}

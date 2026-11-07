// Notificaciones locales programadas (RF-43 a RF-47, RNF-04).
//
// - Se recalcula el plan completo con [NotificationPlanner] cada vez que
//   cambian los datos y al abrir la app (iOS limita a 64 pendientes).
// - Android: alarmas exactas si el sistema lo permite; el plugin vuelve a
//   programar tras reiniciar el móvil (ScheduledNotificationBootReceiver).
// - Acciones «Completar» y «Posponer 10 min» funcionan sin abrir la app
//   gracias a un manejador en segundo plano.

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/db/open.dart';
import '../data/repository.dart';
import '../domain/models/task.dart' show TaskStatus;
import '../domain/notification_plan.dart';
import '../domain/settings.dart';
import '../domain/snapshot.dart';
import '../domain/time.dart';
import '../l10n/app_localizations.dart';

const _channelReminders = 'reminders';
const _channelSummaries = 'summaries';
const _categoryTask = 'task';
const actionComplete = 'complete';
const actionSnooze = 'snooze';

/// Carga útil decodificada de una notificación de tarea.
class TaskPayload {
  TaskPayload(this.taskId, this.date);
  final int taskId;
  final DateTime? date;

  static TaskPayload? parse(String? payload) {
    if (payload == null) return null;
    final p = payload.split('|');
    if (p.length < 3 || p[0] != 'task') return null;
    final id = int.tryParse(p[1]);
    if (id == null) return null;
    return TaskPayload(id, p[2].isEmpty ? null : parseDateKey(p[2]));
  }
}

AppLocalizations _l10nFor(String? code) {
  final sys = PlatformDispatcher.instance.locale.languageCode;
  final lang = code ?? sys;
  return lookupAppLocalizations(
      Locale(AppLocalizations.supportedLocales.any((l) => l.languageCode == lang) ? lang : 'es'));
}

bool _tzReady = false;
void ensureTimeZones() {
  if (_tzReady) return;
  tzdata.initializeTimeZones();
  _tzReady = true;
}

tz.Location _location(String name) {
  ensureTimeZones();
  try {
    return tz.getLocation(name);
  } catch (_) {
    return tz.UTC;
  }
}

tz.TZDateTime _tzTime(DateTime wall, String tzName) {
  final loc = _location(tzName);
  return tz.TZDateTime(loc, wall.year, wall.month, wall.day, wall.hour, wall.minute);
}

NotificationDetails _details(AppLocalizations l, {required bool reminder}) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      reminder ? _channelReminders : _channelSummaries,
      reminder ? l.notifChannelReminders : l.notifChannelSummaries,
      importance: reminder ? Importance.high : Importance.defaultImportance,
      priority: reminder ? Priority.high : Priority.defaultPriority,
      category: reminder ? AndroidNotificationCategory.reminder : null,
      actions: reminder
          ? [
              AndroidNotificationAction(actionComplete, l.notifActionComplete),
              AndroidNotificationAction(actionSnooze, l.notifActionSnooze),
            ]
          : null,
    ),
    iOS: DarwinNotificationDetails(categoryIdentifier: reminder ? _categoryTask : null),
  );
}

/// Manejador de acciones con la app cerrada (aislado en segundo plano).
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  unawaited(handleNotificationAction(response));
}

/// Ejecuta «Completar» o «Posponer» abriendo la base de datos directamente.
Future<void> handleNotificationAction(NotificationResponse response, {Repository? repo}) async {
  final payload = TaskPayload.parse(response.payload);
  if (payload == null) return;
  final ownDb = repo == null;
  if (ownDb) await initializeDateFormatting();
  final r = repo ?? Repository(openAppDatabase());
  try {
    if (response.actionId == actionComplete) {
      final snap = await r.loadSnapshot();
      final o = snap.occurrenceOf(payload.taskId, payload.date);
      if (o != null && !o.completed) {
        if (o.isSeries) {
          await r.setOccurrenceCompleted(o.taskId, o.occurrenceDate!, true);
        } else {
          await r.updateTask(o.series.copyWith(
              status: TaskStatus.completed, completedAt: () => DateTime.now()));
        }
      }
      if (ownDb) {
        final settings = AppSettings(snap.settings);
        await NotificationService.instance
            .reschedule(await r.loadSnapshot(), settings, initialize: true);
      }
    } else if (response.actionId == actionSnooze) {
      final snap = await r.loadSnapshot();
      final o = snap.occurrenceOf(payload.taskId, payload.date);
      if (o == null) return;
      final settings = AppSettings(snap.settings);
      await NotificationService.instance.snooze(o, settings, initialize: true);
    }
  } finally {
    if (ownDb) await r.db.close();
  }
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Se llama al tocar una notificación (abre la tarea).
  void Function(TaskPayload payload)? onOpenTask;

  /// Se llama al pulsar una acción con la app abierta.
  Future<void> Function(NotificationResponse response)? onForegroundAction;

  /// Carga útil con la que se abrió la app desde una notificación.
  String? launchPayload;

  Future<void> init({String? localeCode}) async {
    if (_initialized || !_supported) return;
    ensureTimeZones();
    final l = _l10nFor(localeCode);
    await plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(_categoryTask, actions: [
              DarwinNotificationAction.plain(actionComplete, l.notifActionComplete),
              DarwinNotificationAction.plain(actionSnooze, l.notifActionSnooze),
            ]),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      launchPayload = launch!.notificationResponse?.payload;
    }
    _initialized = true;
  }

  void _onResponse(NotificationResponse r) {
    if (r.actionId == actionComplete || r.actionId == actionSnooze) {
      final h = onForegroundAction;
      if (h != null) unawaited(h(r));
      return;
    }
    final p = TaskPayload.parse(r.payload);
    if (p != null) onOpenTask?.call(p);
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  IOSFlutterLocalNotificationsPlugin? get _ios =>
      plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  /// Pide permiso de notificaciones (Android 13+, iOS) y de alarmas exactas.
  Future<bool> requestPermissions() async {
    if (!_supported) return false;
    if (Platform.isAndroid) {
      final ok = await _android?.requestNotificationsPermission() ?? false;
      final exact = await _android?.canScheduleExactNotifications() ?? true;
      if (!exact) await _android?.requestExactAlarmsPermission();
      return ok;
    }
    return await _ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  Future<bool> notificationsEnabled() async {
    if (!_supported) return true;
    if (Platform.isAndroid) return await _android?.areNotificationsEnabled() ?? true;
    return true;
  }

  Future<bool> exactAlarmsAllowed() async {
    if (!_supported || !Platform.isAndroid) return true;
    return await _android?.canScheduleExactNotifications() ?? true;
  }

  Future<AndroidScheduleMode> _mode() async =>
      await exactAlarmsAllowed() ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

  /// Recalcula y programa todos los avisos.
  Future<void> reschedule(AppSnapshot snap, AppSettings settings,
      {String? tzName, bool initialize = false}) async {
    if (!_supported) return;
    if (initialize) await init(localeCode: settings.localeCode);
    if (!_initialized) return;
    final l = _l10nFor(settings.localeCode);
    final now = DateTime.now();
    final zone = tzName ?? (snap.tasks.isNotEmpty ? snap.tasks.first.tz : 'UTC');
    final plan = const NotificationPlanner().plan(snap, now, tz: zone, summaries: settings.summaries);
    final mode = await _mode();
    await plugin.cancelAllPendingNotifications();
    final locale = settings.localeCode ?? PlatformDispatcher.instance.locale.languageCode;
    final timeFmt = DateFormat.Hm(locale);
    for (final p in plan) {
      final (title, body) = _content(p, snap, l, timeFmt);
      try {
        await plugin.zonedSchedule(
          id: p.id,
          scheduledDate: _tzTime(p.fireAt, p.tz),
          notificationDetails: _details(l, reminder: p.kind == PlannedKind.reminder),
          androidScheduleMode: mode,
          title: title,
          body: body,
          payload: p.payload,
        );
      } catch (e) {
        debugPrint('No se pudo programar ${p.id}: $e');
      }
    }
  }

  (String, String) _content(PlannedNotification p, AppSnapshot snap, AppLocalizations l, DateFormat timeFmt) {
    switch (p.kind) {
      case PlannedKind.reminder:
        final o = p.occurrence!;
        final start = o.task.start!;
        final body = o.task.allDay
            ? l.allDayShort
            : p.minutesBefore == 0
                ? l.startsNow
                : p.minutesBefore < 60
                    ? l.startsIn(p.minutesBefore)
                    : l.startsAt('${DateFormat.MMMEd(timeFmt.locale).format(start)} ${timeFmt.format(start)}');
        return (o.task.title, body);
      case PlannedKind.dailySummary:
        final day = p.summaryDay!;
        final items = snap.occurrencesOnDay(day).where((o) => !o.completed).toList();
        final first = items.take(3).map((o) {
          final t = o.task;
          return t.allDay ? t.title : '${timeFmt.format(t.start!)} ${t.title}';
        }).join(', ');
        return (l.dailySummaryTitle, l.dailySummaryBody(items.length, first));
      case PlannedKind.weeklySummary:
        final day = p.summaryDay!;
        final n = snap.occurrencesBetween(day, addDays(day, 7)).where((o) => !o.completed).length;
        return (l.weeklySummaryTitle, l.weeklySummaryBody(n));
      case PlannedKind.monthlySummary:
        final first = p.summaryDay!;
        final next = DateTime(first.year, first.month + 1, 1);
        final occ = snap.occurrencesBetween(first, next);
        final countdowns = occ
            .where((o) => o.task.countdown)
            .take(3)
            .map((o) => '${o.task.title} (${DateFormat.MMMd(timeFmt.locale).format(o.task.start!)})')
            .join(', ');
        return (l.monthlySummaryTitle, l.monthlySummaryBody(occ.length, countdowns.isEmpty ? '' : ' · $countdowns'));
    }
  }

  /// RF-45: vuelve a avisar dentro de 10 minutos.
  Future<void> snooze(Occurrence o, AppSettings settings, {bool initialize = false}) async {
    if (!_supported) return;
    if (initialize) await init(localeCode: settings.localeCode);
    final l = _l10nFor(settings.localeCode);
    final at = DateTime.now().add(const Duration(minutes: 10));
    await plugin.zonedSchedule(
      id: reminderNotificationId(o, -10),
      scheduledDate: _tzTime(at, o.task.tz),
      notificationDetails: _details(l, reminder: true),
      androidScheduleMode: await _mode(),
      title: o.task.title,
      body: l.startsNow,
      payload: 'task|${o.taskId}|${o.occurrenceDate == null ? '' : formatDateKey(o.occurrenceDate!)}',
    );
  }
}

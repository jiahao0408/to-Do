// RF-51: widget de pantalla de inicio «Tareas de hoy».
//
// La app escribe los datos (hasta 6 filas, fijadas arriba y luego por hora)
// con home_widget; el widget nativo los pinta. El check llama a
// [widgetInteractivityCallback] en segundo plano, que completa la tarea en
// la base de datos y repinta el widget sin abrir la app.
//
// Android: TodayWidgetProvider (Kotlin). iOS: ios/TodayWidget (WidgetKit);
// en iOS 17+ el check usa App Intents, en versiones anteriores es solo lectura.

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../data/db/open.dart';
import '../data/repository.dart';
import '../domain/models/task.dart';
import '../domain/settings.dart';
import '../domain/snapshot.dart';
import '../domain/time.dart';
import '../l10n/app_localizations.dart';
import 'notification_service.dart';

const _androidProvider = 'com.chenj.todo_calendar.TodayWidgetProvider';
const _iosWidget = 'TodayWidget';
const appGroupId = 'group.com.chenj.todoCalendar';
const _maxRows = 6;

/// Datos a mostrar en el widget (puro, para poder probarlo).
class WidgetRow {
  const WidgetRow(this.time, this.title, this.done, this.payload);
  final String time;
  final String title;
  final bool done;
  final String payload;
}

List<Occurrence> widgetItems(AppSnapshot snap, DateTime now) {
  final today = snap.occurrencesOnDay(now);
  // Fijadas arriba (RF-11), luego por hora.
  return [
    ...today.where((o) => o.task.pinned),
    ...today.where((o) => !o.task.pinned),
  ];
}

String occurrencePayload(Occurrence o) =>
    'task|${o.taskId}|${o.occurrenceDate == null ? '' : formatDateKey(o.occurrenceDate!)}';

@pragma('vm:entry-point')
Future<void> widgetInteractivityCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  if (uri == null || uri.host != 'toggle') return;
  final payload = TaskPayload.parse(uri.queryParameters['p']);
  if (payload == null) return;
  await initializeDateFormatting();
  final repo = Repository(openAppDatabase());
  try {
    final snap = await repo.loadSnapshot();
    final o = snap.occurrenceOf(payload.taskId, payload.date);
    if (o == null) return;
    final done = !o.completed;
    if (o.isSeries) {
      await repo.setOccurrenceCompleted(o.taskId, o.occurrenceDate!, done);
    } else {
      await repo.updateTask(o.series.copyWith(
        status: done ? TaskStatus.completed : TaskStatus.pending,
        completedAt: () => done ? DateTime.now() : null,
      ));
    }
    final fresh = await repo.loadSnapshot();
    final settings = AppSettings(fresh.settings);
    await WidgetService.instance.update(fresh, settings, DateTime.now());
    await NotificationService.instance.reschedule(fresh, settings, initialize: true);
  } finally {
    await repo.db.close();
  }
}

class WidgetService {
  WidgetService._();
  static final instance = WidgetService._();

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Se llama al tocar una tarea del widget con la app ya abierta.
  void Function(TaskPayload payload)? onOpenTask;
  StreamSubscription<Uri?>? _clicks;

  Future<void> init(Repository repo) async {
    if (!_supported) return;
    try {
      if (Platform.isIOS) await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.registerInteractivityCallback(widgetInteractivityCallback);
      final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
      _handle(initial);
      _clicks = HomeWidget.widgetClicked.listen(_handle);
    } catch (e) {
      debugPrint('home_widget no disponible: $e');
    }
  }

  void _handle(Uri? uri) {
    if (uri == null || uri.host != 'open') return;
    final p = TaskPayload.parse(uri.queryParameters['p']);
    if (p != null) {
      // Espera a que la app esté lista.
      Future.delayed(const Duration(milliseconds: 300), () => onOpenTask?.call(p));
    }
  }

  void dispose() => _clicks?.cancel();

  Future<void> update(AppSnapshot snap, AppSettings settings, DateTime now) async {
    if (!_supported) return;
    try {
      final lang = settings.localeCode ?? PlatformDispatcher.instance.locale.languageCode;
      final code = AppLocalizations.supportedLocales.any((l) => l.languageCode == lang) ? lang : 'es';
      final l = lookupAppLocalizations(Locale(code));
      final time = DateFormat.Hm(code);
      final items = widgetItems(snap, now);
      final done = items.where((o) => o.completed).length;
      await HomeWidget.saveWidgetData<String>(
          'header', '${l.widgetTodayTitle} · ${DateFormat.MMMEd(code).format(now)}');
      await HomeWidget.saveWidgetData<String>(
          'progress', items.isEmpty ? '' : l.completedCount(done, items.length));
      await HomeWidget.saveWidgetData<String>('empty', l.noTasks);
      final shown = items.take(_maxRows).toList();
      await HomeWidget.saveWidgetData<int>('count', shown.length);
      await HomeWidget.saveWidgetData<String>(
          'more', items.length > _maxRows ? '+${items.length - _maxRows}' : '');
      for (var i = 0; i < shown.length; i++) {
        final o = shown[i];
        await HomeWidget.saveWidgetData<String>(
            'row${i}_time', o.task.allDay ? l.allDayShort : time.format(o.task.start!));
        await HomeWidget.saveWidgetData<String>('row${i}_title', '${o.task.pinned ? '📌 ' : ''}${o.task.title}');
        await HomeWidget.saveWidgetData<bool>('row${i}_done', o.completed);
        await HomeWidget.saveWidgetData<String>('row${i}_payload', occurrencePayload(o));
      }
      await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider, iOSName: _iosWidget);
    } catch (e) {
      debugPrint('No se pudo actualizar el widget: $e');
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/task_service.dart';
import '../data/db/database.dart';
import '../data/repository.dart';
import '../domain/settings.dart';
import '../domain/snapshot.dart';
import '../domain/time.dart';

/// Se sobrescribe en main() con la base de datos abierta.
final databaseProvider = Provider<AppDatabase>(
    (ref) => throw UnimplementedError('databaseProvider sin inicializar'));

/// Zona horaria IANA del dispositivo; se sobrescribe en main().
final timeZoneProvider = Provider<String>((ref) => 'UTC');

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final repositoryProvider = Provider<Repository>(
    (ref) => Repository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)));

final taskServiceProvider =
    Provider<TaskService>((ref) => TaskService(ref.watch(repositoryProvider)));

final snapshotStreamProvider = StreamProvider<AppSnapshot>(
    (ref) => ref.watch(repositoryProvider).watchSnapshot());

/// Última foto disponible (vacía mientras carga).
final snapshotProvider = Provider<AppSnapshot>((ref) {
  final async = ref.watch(snapshotStreamProvider);
  return switch (async) {
    AsyncData(:final value) => value,
    _ => AppSnapshot.empty(),
  };
});

final settingsProvider = Provider<AppSettings>(
    (ref) => AppSettings(ref.watch(snapshotProvider).settings));

// ----------------------------------------------------------- estado de vista

class CalendarState {
  const CalendarState({required this.view, required this.anchor});
  final CalendarView view;

  /// Día de referencia visible.
  final DateTime anchor;

  CalendarState copyWith({CalendarView? view, DateTime? anchor}) =>
      CalendarState(view: view ?? this.view, anchor: anchor ?? this.anchor);
}

class CalendarController extends Notifier<CalendarState> {
  @override
  CalendarState build() {
    final now = ref.read(clockProvider).now();
    final initialView = ref.read(settingsProvider).lastView;
    return CalendarState(view: initialView, anchor: dateOnly(now));
  }

  void setView(CalendarView v) {
    state = state.copyWith(view: v);
    ref.read(repositoryProvider).setSetting(AppSettings.kLastView, v.name);
  }

  void goTo(DateTime day) => state = state.copyWith(anchor: dateOnly(day));

  void today() => goTo(ref.read(clockProvider).now());

  void openDay(DateTime day) {
    state = CalendarState(view: CalendarView.day, anchor: dateOnly(day));
    ref.read(repositoryProvider).setSetting(AppSettings.kLastView, CalendarView.day.name);
  }
}

final calendarProvider =
    NotifierProvider<CalendarController, CalendarState>(CalendarController.new);

// --------------------------------------------------------- selección múltiple

class SelectionController extends Notifier<Set<Occurrence>> {
  @override
  Set<Occurrence> build() => {};

  bool get active => state.isNotEmpty;

  void toggle(Occurrence o) {
    final s = {...state};
    if (!s.remove(o)) s.add(o);
    state = s;
  }

  void clear() => state = {};
}

final selectionProvider =
    NotifierProvider<SelectionController, Set<Occurrence>>(SelectionController.new);

// ---------------------------------------------------------- escala de horas

class HourHeightController extends Notifier<double> {
  @override
  double build() => ref.read(settingsProvider).hourHeight;

  void set(double v) => state = v.clamp(28.0, 200.0);

  void persist() => ref
      .read(repositoryProvider)
      .setSetting(AppSettings.kHourHeight, state.toStringAsFixed(1));
}

final hourHeightProvider =
    NotifierProvider<HourHeightController, double>(HourHeightController.new);

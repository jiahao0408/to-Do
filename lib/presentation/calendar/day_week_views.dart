// Vista día (RF-28) y vista semana (RF-29).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/settings.dart';
import '../../domain/time.dart';
import '../common/format.dart';
import '../providers.dart';
import 'date_pager.dart';
import '../screens/diary_screen.dart';
import 'timeline.dart';
import '../common/ph_icons.dart';

class DayView extends ConsumerWidget {
  const DayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DatePager(
      dateAt: (base, i) => addDays(base, i),
      offsetOf: (base, t) => daysBetween(base, t),
      builder: (context, day) => Column(
        children: [
          _DayHeader(day: day),
          Expanded(child: Timeline(days: [day])),
        ],
      ),
    );
  }
}

/// Cabecera con el progreso del día («5/8 completadas»).
class _DayHeader extends ConsumerWidget {
  const _DayHeader({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final items = ref.watch(snapshotProvider).calendarOccurrencesOnDay(day);
    final done = items.where((o) => o.completed).length;
    final now = ref.watch(clockProvider).now();
    final theme = Theme.of(context);
    final isToday = isSameDay(day, now);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              f.fullDate(day),
              style: theme.textTheme.titleMedium!.copyWith(
                color: isToday ? theme.colorScheme.primary : null,
                fontWeight: isToday ? FontWeight.bold : null,
              ),
            ),
          ),
          if (items.isNotEmpty) ...[
            SizedBox(
              width: 28,
              height: 28,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: done / items.length),
                duration: const Duration(milliseconds: 400),
                builder: (_, v, _) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(l.completedCount(done, items.length), style: theme.textTheme.labelLarge),
          ],
          // Diario: nota del día (icono relleno si ya hay nota).
          IconButton(
            tooltip: l.dayNote,
            icon: Icon(
              ref.watch(snapshotProvider).noteOn(day) == null ? PhosphorIconsRegular.notePencil : PhosphorIconsRegular.note,
              color: ref.watch(snapshotProvider).noteOn(day) == null ? null : theme.colorScheme.primary,
            ),
            onPressed: () => openDayNote(context, day),
          ),
        ],
      ),
    );
  }
}

class WeekView extends ConsumerWidget {
  const WeekView({super.key, this.workWeek = false});

  /// Solo de lunes a viernes (vista entre semana).
  final bool workWeek;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Entre semana siempre empieza en lunes, sea cual sea el ajuste.
    final monday = workWeek || ref.watch(settingsProvider).weekStartsMonday;
    final count = workWeek ? 5 : 7;
    DateTime ws(DateTime d) => startOfWeek(d, weekStartsMonday: monday);
    return DatePager(
      dateAt: (base, i) => addDays(ws(base), 7 * i),
      offsetOf: (base, t) => daysBetween(ws(base), ws(t)) ~/ 7,
      builder: (context, start) {
        final days = [for (var i = 0; i < count; i++) addDays(start, i)];
        return Column(
          children: [
            _WeekHeader(days: days, toggle: workWeek ? CalendarView.week : CalendarView.workWeek),
            Expanded(child: Timeline(days: days)),
          ],
        );
      },
    );
  }
}

/// Vista de 3 días: hoy, mañana y pasado (o desde el día de referencia).
/// Al deslizar avanza de 1 en 1 día.
class ThreeDayView extends ConsumerWidget {
  const ThreeDayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DatePager(
      dateAt: (base, i) => addDays(base, i),
      offsetOf: (base, t) => daysBetween(base, t),
      builder: (context, start) {
        final days = [for (var i = 0; i < 3; i++) addDays(start, i)];
        return Column(
          children: [
            _WeekHeader(days: days),
            Expanded(child: Timeline(days: days)),
          ],
        );
      },
    );
  }
}

class _WeekHeader extends ConsumerWidget {
  const _WeekHeader({required this.days, this.toggle});
  final List<DateTime> days;

  /// Vista a la que cambia el botón de la esquina (semana ⇄ entre semana).
  final CalendarView? toggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = Fmt.of(context);
    final l = context.l10n;
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider).now();
    final showWeek = ref.watch(settingsProvider).showWeekNumbers;
    return Row(
      children: [
        SizedBox(
          width: kHourLabelWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (toggle != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  tooltip: toggle == CalendarView.workWeek ? l.viewWorkWeek : l.viewWeek,
                  icon: Icon(toggle == CalendarView.workWeek ? PhosphorIconsRegular.briefcase : PhosphorIconsRegular.calendarDots),
                  onPressed: () => ref.read(calendarProvider.notifier).setView(toggle!),
                ),
              if (showWeek)
                Text(l.weekNumberShort(isoWeekNumber(days[days.length > 3 ? 3 : 0])),
                    style: theme.textTheme.labelSmall),
            ],
          ),
        ),
        for (final d in days)
          Expanded(
            child: InkWell(
              onTap: () => ref.read(calendarProvider.notifier).openDay(d),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Text(f.weekdayShort(d), style: theme.textTheme.labelSmall),
                    const SizedBox(height: 2),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: isSameDay(d, now)
                          ? BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle)
                          : null,
                      child: Text(
                        '${d.day}',
                        style: theme.textTheme.titleSmall!.copyWith(
                          color: isSameDay(d, now) ? theme.colorScheme.onPrimary : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

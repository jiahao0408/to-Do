// Vista día (RF-28) y vista semana (RF-29).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/time.dart';
import '../common/format.dart';
import '../providers.dart';
import 'date_pager.dart';
import 'timeline.dart';

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
    final items = ref.watch(snapshotProvider).occurrencesOnDay(day);
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
        ],
      ),
    );
  }
}

class WeekView extends ConsumerWidget {
  const WeekView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monday = ref.watch(settingsProvider).weekStartsMonday;
    DateTime ws(DateTime d) => startOfWeek(d, weekStartsMonday: monday);
    return DatePager(
      dateAt: (base, i) => addDays(ws(base), 7 * i),
      offsetOf: (base, t) => daysBetween(ws(base), ws(t)) ~/ 7,
      builder: (context, start) {
        final days = [for (var i = 0; i < 7; i++) addDays(start, i)];
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
  const _WeekHeader({required this.days});
  final List<DateTime> days;

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
          child: showWeek
              ? Center(
                  child: Text(l.weekNumberShort(isoWeekNumber(days[3])),
                      style: theme.textTheme.labelSmall),
                )
              : null,
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

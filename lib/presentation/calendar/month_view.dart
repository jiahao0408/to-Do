// Vista mes (RF-30) con mover tareas a otro día arrastrando (RF-35).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../common/task_tile.dart';
import '../providers.dart';
import 'date_pager.dart';
import 'event_style.dart';

class MonthView extends ConsumerWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DatePager(
      dateAt: (base, i) => DateTime(base.year, base.month + i, 1),
      offsetOf: (base, t) => (t.year - base.year) * 12 + t.month - base.month,
      builder: (context, first) => _MonthGrid(first: first),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({required this.first});
  final DateTime first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final f = Fmt.of(context);
    final l = context.l10n;
    final theme = Theme.of(context);
    final gridStart = startOfWeek(first, weekStartsMonday: settings.weekStartsMonday);
    final weeks = ((daysBetween(gridStart, first) + daysInMonth(first.year, first.month)) / 7).ceil();
    final snap = ref.watch(snapshotProvider);
    final occ = snap.calendarOccurrencesBetween(gridStart, addDays(gridStart, weeks * 7));
    final byDay = <String, List<Occurrence>>{};
    for (final o in occ) {
      (byDay[formatDateKey(o.task.start!)] ??= []).add(o);
    }
    final now = ref.watch(clockProvider).now();
    final showWeek = settings.showWeekNumbers;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(f.monthYear(first), style: theme.textTheme.titleMedium),
        ),
        Row(
          children: [
            if (showWeek) const SizedBox(width: 28),
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(f.weekdayShort(addDays(gridStart, i)),
                      style: theme.textTheme.labelSmall),
                ),
              ),
          ],
        ),
        Expanded(
          child: Column(
            children: [
              for (var w = 0; w < weeks; w++)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showWeek)
                        SizedBox(
                          width: 28,
                          child: Center(
                            child: Text(
                              l.weekNumberShort(isoWeekNumber(addDays(gridStart, w * 7 + 3))),
                              style: theme.textTheme.labelSmall!
                                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      for (var d = 0; d < 7; d++)
                        Expanded(
                          child: _DayCell(
                            day: addDays(gridStart, w * 7 + d),
                            inMonth: addDays(gridStart, w * 7 + d).month == first.month,
                            isToday: isSameDay(addDays(gridStart, w * 7 + d), now),
                            items: byDay[formatDateKey(addDays(gridStart, w * 7 + d))] ?? const [],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCell extends ConsumerWidget {
  const _DayCell({required this.day, required this.inMonth, required this.isToday, required this.items});
  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final List<Occurrence> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return DragTarget<Occurrence>(
      onWillAcceptWithDetails: (d) => !isSameDay(d.data.task.start!, day),
      onAcceptWithDetails: (d) async {
        final ui = Ui.of(context);
        final o = d.data;
        ui.haptic(HapticKind.light);
        final point = await ui.service.moveMany([o], day);
        final start = withTimeOf(day, o.task.start!);
        ui.undo(point,
            ui.overlap(start, start.add(Duration(minutes: o.task.effectiveDurationMin)),
                    excludeKey: o.key, allDay: o.task.allDay) ??
                ui.l.taskMoved);
      },
      builder: (context, candidates, _) => InkWell(
        onTap: () => ref.read(calendarProvider.notifier).openDay(day),
        child: Container(
          decoration: BoxDecoration(
            color: candidates.isNotEmpty
                ? theme.colorScheme.primaryContainer
                : inMonth
                    ? null
                    : theme.colorScheme.onSurface.withValues(alpha: 0.025),
            border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.25),
          ),
          padding: const EdgeInsets.all(2),
          child: LayoutBuilder(builder: (context, c) {
            // Cuántas líneas de tareas caben; el resto se resume con «+N».
            final maxLines = ((c.maxHeight - 24) / 18).floor().clamp(0, 6);
            final shown = items.length > maxLines ? (maxLines - 1).clamp(0, 6) : items.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: isToday
                        ? BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle)
                        : null,
                    child: Text(
                      '${day.day}',
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: isToday
                            ? theme.colorScheme.onPrimary
                            : inMonth
                                ? null
                                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                for (final o in items.take(shown)) _MonthChip(occurrence: o),
                if (items.length > shown)
                  shown == 0
                      ? Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 2,
                          children: [
                            for (final o in items.take(6))
                              CircleAvatar(
                                  radius: 3, backgroundColor: categoryColorOf(ref, o.task.categoryId, context)),
                          ],
                        )
                      : Text('+${items.length - shown}',
                          textAlign: TextAlign.center, style: theme.textTheme.labelSmall),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _MonthChip extends ConsumerWidget {
  const _MonthChip({required this.occurrence});
  final Occurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = occurrence;
    final color = categoryColorOf(ref, o.task.categoryId, context);
    final ev = EventColors.of(context, color, completed: o.completed);
    final chip = Container(
      height: 16,
      margin: const EdgeInsets.only(top: 2, left: 1, right: 1),
      padding: const EdgeInsets.only(left: 3, right: 2),
      decoration: BoxDecoration(
        color: ev.background,
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: ev.accent, width: 2.5)),
      ),
      child: Text(
        o.task.title,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontSize: 10,
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: ev.foreground,
          decoration: o.completed ? TextDecoration.lineThrough : null,
        ),
      ),
    );
    return LongPressDraggable<Occurrence>(
      data: o,
      hapticFeedbackOnStart: ref.watch(settingsProvider).haptics,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 80, child: chip),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
  }
}

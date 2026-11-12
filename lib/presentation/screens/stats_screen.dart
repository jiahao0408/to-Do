// RF-49: pantalla de rachas y estadísticas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/stats.dart';
import '../../domain/time.dart';
import '../common/format.dart';
import '../providers.dart';
import '../common/ph_icons.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final theme = Theme.of(context);
    final snap = ref.watch(snapshotProvider);
    final now = ref.watch(clockProvider).now();
    final stats = Stats(snap, now, weekStartsMonday: ref.watch(settingsProvider).weekStartsMonday);
    final (streak, best) = stats.streak(ref.watch(settingsProvider).streakRule);
    final scheme = theme.colorScheme;

    Widget box(Widget child, {Color? color}) => Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color ?? scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(18)),
      child: child,
    );
    final days = stats.lastDays(7);
    final ws = startOfWeek(now, weekStartsMonday: ref.watch(settingsProvider).weekStartsMonday);
    final weekMinutes = stats.realMinutes(from: ws, to: addDays(ws, 7));

    Widget rateCard(String label, Rate r) => Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: r.ratio,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        color: scheme.primary,
                        backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    Text('${(r.ratio * 100).round()}%', style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text('${r.done}/${r.total}', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );

    final maxTotal = days.fold<int>(1, (m, d) => d.$2.total > m ? d.$2.total : m);

    return Scaffold(
      appBar: AppBar(title: Text(l.statistics)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(l.statsCompletionRate, style: theme.textTheme.titleSmall),
          ),
          Row(
            children: [
              rateCard(l.statsToday, stats.todayRate),
              rateCard(l.statsThisWeek, stats.weekRate),
              rateCard(l.statsThisMonth, stats.monthRate),
            ],
          ),
          box(
            color: const Color(0xFFFF7043).withValues(alpha: 0.14),
            Row(
              children: [
                const Icon(PhosphorIconsFill.fire, color: Color(0xFFF4511E), size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.statsStreak, style: theme.textTheme.labelLarge),
                      Text(l.statsStreakDays(streak), style: theme.textTheme.headlineSmall),
                    ],
                  ),
                ),
                Text(l.statsBestStreak(best), style: theme.textTheme.labelMedium),
              ],
            ),
          ),
          box(
            Row(
              children: [
                Icon(PhosphorIconsRegular.listChecks, color: scheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.statsWeeklySummary, style: theme.textTheme.titleSmall),
                      Text(
                        l.statsWeeklySummaryBody(stats.weekRate.done, stats.weekRate.total, weekMinutes),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          box(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.statsLast7Days, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (d, r) in days)
                        Expanded(
                          child: Semantics(
                            label: '${f.weekdayShort(d)} ${r.done}/${r.total}',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('${r.done}/${r.total}', style: theme.textTheme.labelSmall),
                                const SizedBox(height: 2),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  height: 90.0 * r.total / maxTotal,
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: r.ratio,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSameDay(d, now)
                                            ? scheme.primary
                                            : scheme.primary.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  f.weekdayShort(d),
                                  style: theme.textTheme.labelSmall!.copyWith(
                                    fontWeight: isSameDay(d, now) ? FontWeight.w700 : null,
                                    color: isSameDay(d, now) ? scheme.primary : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          YearHeatmap(stats: stats, year: now.year),
          const SizedBox(height: 16),
          Text(l.statsHabits, style: theme.textTheme.titleSmall),
          for (final h in stats.habits())
            ListTile(
              leading: Icon(PhosphorIconsRegular.repeat, color: scheme.primary),
              title: Text(h.task.title),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: h.rate.ratio,
                    minHeight: 6,
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  ),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsFill.fire, size: 16, color: Color(0xFFF4511E)),
                      const SizedBox(width: 2),
                      Text('${h.current}', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  Text(l.statsBestStreak(h.best), style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(l.statsTimeByCategory, style: theme.textTheme.titleSmall),
          for (final ct in stats.timeByCategory())
            ListTile(
              leading: CircleAvatar(
                radius: 8,
                backgroundColor: snap.categoryById(ct.categoryId) == null
                    ? theme.colorScheme.outline
                    : Color(snap.categoryById(ct.categoryId)!.color),
              ),
              title: Text(snap.categoryById(ct.categoryId)?.name ?? l.noCategory),
              trailing: Text(l.estimatedVsReal(f.duration(ct.estimatedMin), f.duration(ct.realMin))),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Mapa de calor anual: cada día coloreado según el % completado.
class YearHeatmap extends StatelessWidget {
  const YearHeatmap({super.key, required this.stats, required this.year});
  final Stats stats;
  final int year;

  static const double _cell = 13;
  static const double _gap = 3;

  Color _color(BuildContext context, Rate? r, bool future) {
    final cs = Theme.of(context).colorScheme;
    if (future || r == null || r.total == 0) return cs.surfaceContainerHighest;
    final ratio = r.ratio;
    final alpha = ratio == 0
        ? 0.12
        : ratio < 0.34
        ? 0.35
        : ratio < 0.67
        ? 0.6
        : ratio < 1
        ? 0.8
        : 1.0;
    return cs.primary.withValues(alpha: alpha);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final theme = Theme.of(context);
    final first = DateTime(year, 1, 1);
    final last = DateTime(year, 12, 31);
    final rates = stats.dailyRates(first, addDays(last, 1));
    final gridStart = startOfWeek(first); // columnas = semanas (lunes arriba)
    final weeks = (daysBetween(gridStart, last) ~/ 7) + 1;
    final today = stats.today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.heatmapTitle(year), style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // empieza mostrando las semanas recientes
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var w = 0; w < weeks; w++)
                Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: Column(
                    children: [
                      for (var d = 0; d < 7; d++)
                        Builder(
                          builder: (context) {
                            final day = addDays(gridStart, w * 7 + d);
                            if (day.year != year) return const SizedBox(width: _cell, height: _cell + _gap);
                            final r = rates[formatDateKey(day)];
                            final future = day.isAfter(today);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: _gap),
                              child: Tooltip(
                                triggerMode: TooltipTriggerMode.tap,
                                message:
                                    '${f.weekdayDayMonth(day)} · ${r == null ? l.noTasks : '${r.done}/${r.total}'}',
                                child: Container(
                                  width: _cell,
                                  height: _cell,
                                  decoration: BoxDecoration(
                                    color: _color(context, r, future),
                                    borderRadius: BorderRadius.circular(3),
                                    border: isSameDay(day, today)
                                        ? Border.all(color: theme.colorScheme.onSurface, width: 1.5)
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(l.heatLess, style: theme.textTheme.labelSmall),
            const SizedBox(width: 4),
            for (final a in [0.12, 0.35, 0.6, 0.8, 1.0])
              Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: a),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const SizedBox(width: 4),
            Text(l.heatMore, style: theme.textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

// RF-49: pantalla de rachas y estadísticas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/stats.dart';
import '../../domain/time.dart';
import '../common/format.dart';
import '../providers.dart';

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
    final (streak, best) = stats.dayStreak();
    final days = stats.lastDays(7);
    final ws = startOfWeek(now, weekStartsMonday: ref.watch(settingsProvider).weekStartsMonday);
    final weekMinutes = stats.realMinutes(from: ws, to: addDays(ws, 7));

    Widget rateCard(String label, Rate r) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                            strokeWidth: 6,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
          Text(l.statsCompletionRate, style: theme.textTheme.titleSmall),
          Row(children: [
            rateCard(l.statsToday, stats.todayRate),
            rateCard(l.statsThisWeek, stats.weekRate),
            rateCard(l.statsThisMonth, stats.monthRate),
          ]),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 36),
              title: Text('${l.statsStreak}: ${l.statsStreakDays(streak)}', style: theme.textTheme.titleMedium),
              subtitle: Text(l.statsBestStreak(best)),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.summarize_outlined),
              title: Text(l.statsWeeklySummary),
              subtitle: Text(l.statsWeeklySummaryBody(stats.weekRate.done, stats.weekRate.total, weekMinutes)),
            ),
          ),
          const SizedBox(height: 12),
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
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: r.ratio,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(f.weekdayShort(d), style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l.statsHabits, style: theme.textTheme.titleSmall),
          for (final h in stats.habits())
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text(h.task.title),
              subtitle: LinearProgressIndicator(value: h.rate.ratio),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('🔥 ${h.current}', style: theme.textTheme.titleSmall),
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

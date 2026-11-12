// B：carrusel arriba del menú lateral. Páginas (configurables en Ajustes):
// Hoy, Racha, Meta de la semana y Habitante.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/goal.dart';
import '../../domain/settings.dart';
import '../../domain/stats.dart';
import '../../domain/villager/villager_lines.dart';
import '../common/format.dart';
import '../providers.dart';
import '../screens/projects_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart';
import 'village_screen.dart';
import 'villager_controller.dart';
import 'villager_copy.dart';
import 'villager_sprite.dart';

class MenuCarousel extends ConsumerStatefulWidget {
  const MenuCarousel({super.key});

  static const double height = 128;

  @override
  ConsumerState<MenuCarousel> createState() => _MenuCarouselState();
}

class _MenuCarouselState extends ConsumerState<MenuCarousel> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    if (!s.villagerDrawer) return const SizedBox.shrink();
    final cards = [
      for (final c in s.menuCards)
        if (c != MenuCard.villager || s.villagerEnabled) c,
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    final page = min(_page, cards.length - 1);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(children: [
        SizedBox(
          height: MenuCarousel.height,
          child: PageView(
            controller: _pages,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              for (final c in cards)
                _CardShell(
                  key: ValueKey(c),
                  child: switch (c) {
                    MenuCard.today => const _TodayPage(),
                    MenuCard.streak => const _StreakPage(),
                    MenuCard.goal => const _GoalPage(),
                    MenuCard.villager => const _VillagerPage(),
                  },
                ),
            ],
          ),
        ),
        if (cards.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < cards.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == page ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == page ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ]),
          ),
      ]),
    );
  }
}

/// Cierra el menú y abre [page].
void _open(BuildContext context, Widget page) {
  final nav = Navigator.of(context);
  nav.pop();
  nav.push(MaterialPageRoute(builder: (_) => page));
}

class _CardShell extends StatelessWidget {
  const _CardShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      );
}

class _Title extends StatelessWidget {
  const _Title(this.icon, this.text, {this.trailing});
  final IconData icon;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(icon, size: 16, color: theme.colorScheme.primary),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge!.copyWith(color: theme.colorScheme.primary)),
      ),
      ?trailing,
    ]);
  }
}

Widget _bar(BuildContext context, double value, Color color) => ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        color: color,
        backgroundColor: color.withValues(alpha: 0.15),
      ),
    );

class _TodayPage extends ConsumerWidget {
  const _TodayPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider).now();
    final snap = ref.watch(snapshotProvider);
    final today = snap.occurrencesOnDay(now);
    final done = today.where((o) => o.completed).length;
    final overdue = snap.overdue(now).length;
    final next = today
        .where((o) => !o.completed && !o.task.allDay && o.start != null && !o.start!.isBefore(now))
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Title(Icons.today_outlined, l.cardToday,
            trailing: Text('$done/${today.length}', style: theme.textTheme.labelLarge)),
        const SizedBox(height: 8),
        _bar(context, today.isEmpty ? 0 : done / today.length, theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          next == null ? l.cardNothingNext : '${l.cardNext(next.task.title)} · ${f.time(next.start!)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 2),
        Text(l.cardOverdue(overdue),
            style: theme.textTheme.bodySmall!.copyWith(color: overdue > 0 ? theme.colorScheme.error : null)),
      ]),
    );
  }
}

class _StreakPage extends ConsumerWidget {
  const _StreakPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final s = ref.watch(settingsProvider);
    final stats = Stats(ref.watch(snapshotProvider), ref.watch(clockProvider).now(),
        weekStartsMonday: s.weekStartsMonday);
    final (current, best) = stats.streak(s.streakRule);
    final marks = stats.streakMarks(28, s.streakRule);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: () => _open(context, const StatsScreen()),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Title(Icons.local_fire_department_outlined, l.cardStreak,
              trailing: Text(l.statsBestStreak(best), style: theme.textTheme.labelSmall)),
          const SizedBox(height: 4),
          Text(l.statsStreakDays(current), style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          // Últimos 28 días en dos filas de 14.
          for (final row in [marks.sublist(0, 14), marks.sublist(14)])
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(children: [
                for (final m in row)
                  Expanded(
                    child: Container(
                      height: 9,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: switch (m) {
                          true => scheme.primary,
                          false => scheme.error.withValues(alpha: 0.35),
                          null => scheme.outlineVariant.withValues(alpha: 0.6),
                        },
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _GoalPage extends ConsumerWidget {
  const _GoalPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final s = ref.watch(settingsProvider);
    final goal = weeklyGoal(ref.watch(snapshotProvider), s.weeklyGoal, ref.watch(clockProvider).now(),
        weekStartsMonday: s.weekStartsMonday);
    if (goal == null) {
      return InkWell(
        onTap: () => _open(context, const SettingsScreen()),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Title(Icons.flag_outlined, l.cardGoal),
            const Spacer(),
            Text(l.goalPick, style: theme.textTheme.bodyMedium),
            const Spacer(),
          ]),
        ),
      );
    }
    final color = Color(goal.color);
    return InkWell(
      onTap: goal.projectId == null ? null : () => _open(context, ProjectScreen(projectId: goal.projectId!)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Title(Icons.flag_outlined, l.cardGoal,
              trailing: Text('${(goal.ratio * 100).round()} %', style: theme.textTheme.labelLarge)),
          const SizedBox(height: 6),
          Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          _bar(context, goal.ratio, color),
          const SizedBox(height: 6),
          Text('${goal.done}/${goal.total} · ${l.goalThisWeek(goal.thisWeek)}', style: theme.textTheme.bodySmall),
        ]),
      ),
    );
  }
}

class _VillagerPage extends ConsumerWidget {
  const _VillagerPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final s = ref.watch(settingsProvider);
    final v = ref.watch(villagerProvider);
    // Frase estable mientras no cambie el ánimo ni haya interacción.
    final line = pickLine(
      villagerCandidates(l, Fmt.of(context), kindForMood(v.mood, v.context), v.context),
      Random(v.reactionTick * 7 + v.mood.index),
    );
    return InkWell(
      onTap: s.villagerTank ? () => _open(context, const VillageScreen()) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const VillagerSprite(size: 80, bubble: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              _Title(Icons.construction_outlined, l.villagerTitle),
              const SizedBox(height: 6),
              _bar(context, v.state.fullness / 100, kVillagerBlue),
              const SizedBox(height: 2),
              Text(l.villagerFullness(v.state.fullness.round()), style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(line, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
            ]),
          ),
        ]),
      ),
    );
  }
}

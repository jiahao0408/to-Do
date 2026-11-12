// Ajustes: tema (RF-54), idiomas (RF-55), semana (RF-56), avisos (RF-57).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/settings.dart';
import '../../domain/stats.dart';
import '../common/format.dart';
import '../providers.dart';
import 'backup_tiles.dart';
import 'categories_screen.dart';
import '../common/ph_icons.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final s = ref.watch(settingsProvider);
    final repo = ref.read(repositoryProvider);
    final theme = Theme.of(context);
    Future<void> set(String k, String v) => repo.setSetting(k, v);
    Future<void> setBool(String k, bool v) => repo.setSetting(k, v ? '1' : '0');

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(text, style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.primary)),
        );

    Future<void> pickMinute(String key, int current) async {
      final t = await showTimePicker(
          context: context, initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60));
      if (t != null) await set(key, '${t.hour * 60 + t.minute}');
    }

    String hm(int m) => f.time(DateTime(2000, 1, 1, m ~/ 60, m % 60));
    final sum = s.summaries;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          header(l.appearanceSection),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.circleHalf),
            title: Text(l.theme),
            trailing: SegmentedButton<AppThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: AppThemeMode.system, icon: const Icon(PhosphorIconsRegular.deviceMobile), tooltip: l.themeSystem),
                ButtonSegment(value: AppThemeMode.light, icon: const Icon(PhosphorIconsRegular.sun), tooltip: l.themeLight),
                ButtonSegment(value: AppThemeMode.dark, icon: const Icon(PhosphorIconsRegular.moon), tooltip: l.themeDark),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => set(AppSettings.kTheme, v.first.name),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(PhosphorIconsRegular.palette),
            title: Text(l.dynamicColor),
            value: s.dynamicColor,
            onChanged: (v) => setBool(AppSettings.kDynamicColor, v),
          ),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.palette),
            title: Text(l.accentColor),
            enabled: !s.dynamicColor,
            trailing: CircleAvatar(backgroundColor: Color(s.accentColor), radius: 12),
            onTap: () async {
              final c = await pickColor(context, s.accentColor);
              if (c != null) await set(AppSettings.kAccent, '$c');
            },
          ),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.globe),
            title: Text(l.language),
            trailing: DropdownButton<String>(
              value: s.localeCode ?? 'system',
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: 'system', child: Text(l.languageSystem)),
                const DropdownMenuItem(value: 'es', child: Text('Español')),
                const DropdownMenuItem(value: 'en', child: Text('English')),
                const DropdownMenuItem(value: 'zh', child: Text('简体中文')),
              ],
              onChanged: (v) => set(AppSettings.kLocale, v ?? 'system'),
            ),
          ),
          header(l.calendarSection),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.columns),
            title: Text(l.weekStart),
            trailing: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: true, label: Text(l.monday)),
                ButtonSegment(value: false, label: Text(l.sunday)),
              ],
              selected: {s.weekStartsMonday},
              onSelectionChanged: (v) => setBool(AppSettings.kWeekStartsMonday, v.first),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(PhosphorIconsRegular.hash),
            title: Text(l.showWeekNumbers),
            value: s.showWeekNumbers,
            onChanged: (v) => setBool(AppSettings.kShowWeekNumbers, v),
          ),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.tag),
            title: Text(l.categories),
            trailing: const Icon(PhosphorIconsRegular.caretRight),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
          ),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.notePencil),
            title: Text(l.reviewDay),
            trailing: DropdownButton<int>(
              value: s.reviewWeekday,
              underline: const SizedBox.shrink(),
              items: [
                for (var d = 1; d <= 7; d++) DropdownMenuItem(value: d, child: Text(f.weekdayName(d))),
              ],
              onChanged: (v) => set(AppSettings.kReviewWeekday, '$v'),
            ),
          ),
          header(l.notificationsSection),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.bell),
            title: Text(l.defaultReminder),
            trailing: DropdownButton<int>(
              value: s.defaultReminder,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: -1, child: Text(l.none)),
                for (final m in {0, 5, 10, 15, 30, 60, 120, 1440, s.defaultReminder}.where((m) => m >= 0))
                  DropdownMenuItem(value: m, child: Text(reminderLabel(l, m))),
              ],
              onChanged: (v) => set(AppSettings.kDefaultReminder, '$v'),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(PhosphorIconsRegular.sun),
            title: Text(l.dailySummary),
            subtitle: Text('${l.summaryTime}: ${hm(sum.dailyMinute)}'),
            value: sum.dailyEnabled,
            onChanged: (v) async {
              await setBool(AppSettings.kDailySummary, v);
              if (v) await pickMinute(AppSettings.kDailySummaryMinute, sum.dailyMinute);
            },
          ),
          SwitchListTile(
            secondary: const Icon(PhosphorIconsRegular.calendarDots),
            title: Text(l.weeklySummary),
            subtitle: Text('${f.weekdayName(sum.weeklyWeekday)} · ${hm(sum.weeklyMinute)}'),
            value: sum.weeklyEnabled,
            onChanged: (v) async {
              await setBool(AppSettings.kWeeklySummary, v);
              if (!v || !context.mounted) return;
              final day = await showDialog<int>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: Text(l.summaryDay),
                  children: [
                    for (var d = 1; d <= 7; d++)
                      SimpleDialogOption(onPressed: () => Navigator.pop(ctx, d), child: Text(f.weekdayName(d))),
                  ],
                ),
              );
              if (day != null) await set(AppSettings.kWeeklySummaryWeekday, '$day');
              await pickMinute(AppSettings.kWeeklySummaryMinute, sum.weeklyMinute);
            },
          ),
          SwitchListTile(
            secondary: const Icon(PhosphorIconsRegular.calendar),
            title: Text(l.monthlySummary),
            subtitle: Text('${l.summaryTime}: ${hm(sum.monthlyMinute)}'),
            value: sum.monthlyEnabled,
            onChanged: (v) async {
              await setBool(AppSettings.kMonthlySummary, v);
              if (v) await pickMinute(AppSettings.kMonthlySummaryMinute, sum.monthlyMinute);
            },
          ),
          header(l.interactionSection),
          SwitchListTile(
            secondary: const Icon(PhosphorIconsRegular.vibrate),
            title: Text(l.haptics),
            value: s.haptics,
            onChanged: (v) => setBool(AppSettings.kHaptics, v),
          ),
          SwitchListTile(
            secondary: const Icon(PhosphorIconsRegular.filmStrip),
            title: Text(l.animations),
            value: s.animations,
            onChanged: (v) => setBool(AppSettings.kAnimations, v),
          ),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.handSwipeLeft),
            title: Text(l.swipeLeftAction),
            trailing: SegmentedButton<SwipeLeftAction>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: SwipeLeftAction.delete, label: Text(l.swipeDelete)),
                ButtonSegment(value: SwipeLeftAction.postpone, label: Text(l.swipePostpone)),
              ],
              selected: {s.swipeLeft},
              onSelectionChanged: (v) => set(AppSettings.kSwipeLeft, v.first.name),
            ),
          ),
          header(l.villageSection),
          SwitchListTile(
            secondary: const Icon(PhosphorIconsRegular.buildings),
            title: Text(l.villagerShow),
            value: s.villagerEnabled,
            onChanged: (v) => setBool(AppSettings.kVillagerEnabled, v),
          ),
          if (s.villagerEnabled) ...[
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 24),
              title: Text(l.villagerFloating),
              value: s.villagerFloating,
              onChanged: (v) => setBool(AppSettings.kVillagerFloating, v),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 24),
              title: Text(l.villagerTank),
              value: s.villagerTank,
              onChanged: (v) => setBool(AppSettings.kVillagerTank, v),
            ),
          ],
          header(l.menuCardSection),
          SwitchListTile(
            secondary: const Icon(PhosphorIconsRegular.cardsThree),
            title: Text(l.menuCardShow),
            value: s.villagerDrawer,
            onChanged: (v) => setBool(AppSettings.kVillagerDrawer, v),
          ),
          if (s.villagerDrawer) ...[
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 24),
              title: Text(l.cardPages),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final c in MenuCard.values)
                    FilterChip(
                      label: Text(switch (c) {
                        MenuCard.today => l.cardToday,
                        MenuCard.streak => l.cardStreak,
                        MenuCard.goal => l.cardGoal,
                        MenuCard.villager => l.cardVillager,
                      }),
                      selected: s.menuCards.contains(c),
                      onSelected: c == MenuCard.villager && !s.villagerEnabled
                          ? null
                          : (on) {
                              final next = {...s.menuCards};
                              on ? next.add(c) : next.remove(c);
                              set(AppSettings.kMenuCards,
                                  [for (final m in MenuCard.values) if (next.contains(m)) m.name].join(','));
                            },
                    ),
                ]),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 24),
              title: Text(l.streakRule),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SegmentedButton<StreakRule>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: StreakRule.any, label: Text(l.streakRuleAny)),
                    ButtonSegment(value: StreakRule.all, label: Text(l.streakRuleAll)),
                  ],
                  selected: {s.streakRule},
                  onSelectionChanged: (v) => set(AppSettings.kStreakRule, v.first.name),
                ),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 24),
              title: Text(l.goalTarget),
              trailing: DropdownButton<String>(
                value: _goalValue(ref, s.weeklyGoal),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: '', child: Text(l.goalNone)),
                  for (final p in ref.watch(snapshotProvider).projects.where((p) => !p.archived))
                    DropdownMenuItem(
                      value: 'p:${p.id}',
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(PhosphorIconsFill.folder, size: 16, color: Color(p.color)),
                        const SizedBox(width: 6),
                        Text(p.name),
                      ]),
                    ),
                  for (final c in ref.watch(snapshotProvider).categories)
                    DropdownMenuItem(
                      value: 'c:${c.id}',
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        CircleAvatar(radius: 6, backgroundColor: Color(c.color)),
                        const SizedBox(width: 6),
                        Text(c.name),
                      ]),
                    ),
                ],
                onChanged: (v) => set(AppSettings.kWeeklyGoal, v ?? ''),
              ),
            ),
          ],
          header(l.dataSection),
          const BackupTiles(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Valor del desplegable de la meta: '' si no hay o ya no existe.
String _goalValue(WidgetRef ref, String? raw) {
  if (raw == null) return '';
  final snap = ref.watch(snapshotProvider);
  final id = int.tryParse(raw.substring(2));
  final exists = raw.startsWith('p:')
      ? snap.projects.any((p) => p.id == id && !p.archived)
      : snap.categories.any((c) => c.id == id);
  return exists ? raw : '';
}

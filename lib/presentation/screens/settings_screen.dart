// Ajustes: tema (RF-54), idiomas (RF-55), semana (RF-56), avisos (RF-57).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/settings.dart';
import '../common/format.dart';
import '../providers.dart';
import 'backup_tiles.dart';
import 'categories_screen.dart';

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
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l.theme),
            trailing: SegmentedButton<AppThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: AppThemeMode.system, icon: const Icon(Icons.phone_android), tooltip: l.themeSystem),
                ButtonSegment(value: AppThemeMode.light, icon: const Icon(Icons.light_mode), tooltip: l.themeLight),
                ButtonSegment(value: AppThemeMode.dark, icon: const Icon(Icons.dark_mode), tooltip: l.themeDark),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => set(AppSettings.kTheme, v.first.name),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wallpaper),
            title: Text(l.dynamicColor),
            value: s.dynamicColor,
            onChanged: (v) => setBool(AppSettings.kDynamicColor, v),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.accentColor),
            enabled: !s.dynamicColor,
            trailing: CircleAvatar(backgroundColor: Color(s.accentColor), radius: 12),
            onTap: () async {
              final c = await pickColor(context, s.accentColor);
              if (c != null) await set(AppSettings.kAccent, '$c');
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
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
            leading: const Icon(Icons.view_week_outlined),
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
            secondary: const Icon(Icons.numbers),
            title: Text(l.showWeekNumbers),
            value: s.showWeekNumbers,
            onChanged: (v) => setBool(AppSettings.kShowWeekNumbers, v),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(l.categories),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.rate_review_outlined),
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
            leading: const Icon(Icons.notifications_outlined),
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
            secondary: const Icon(Icons.wb_sunny_outlined),
            title: Text(l.dailySummary),
            subtitle: Text('${l.summaryTime}: ${hm(sum.dailyMinute)}'),
            value: sum.dailyEnabled,
            onChanged: (v) async {
              await setBool(AppSettings.kDailySummary, v);
              if (v) await pickMinute(AppSettings.kDailySummaryMinute, sum.dailyMinute);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.date_range_outlined),
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
            secondary: const Icon(Icons.calendar_month_outlined),
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
            secondary: const Icon(Icons.vibration),
            title: Text(l.haptics),
            value: s.haptics,
            onChanged: (v) => setBool(AppSettings.kHaptics, v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.animation),
            title: Text(l.animations),
            value: s.animations,
            onChanged: (v) => setBool(AppSettings.kAnimations, v),
          ),
          ListTile(
            leading: const Icon(Icons.swipe_left_outlined),
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
          header(l.dataSection),
          const BackupTiles(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

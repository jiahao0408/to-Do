// Menú lateral: bandeja, cuentas atrás y fijadas, proyectos, categorías
// visibles, diario, herramientas y ayuda.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../common/format.dart';
import '../providers.dart';
import '../screens/categories_screen.dart';
import '../screens/diary_screen.dart';
import '../screens/gesture_guide_screen.dart';
import '../screens/inbox_screen.dart';
import '../screens/process_inbox_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/templates_screen.dart';
import '../screens/weekly_review_screen.dart';
import '../task/task_detail.dart';
import '../whale/whale_drawer_card.dart';
import '../whale/whale_tank_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final theme = Theme.of(context);
    final snap = ref.watch(snapshotProvider);
    final settings = ref.watch(settingsProvider);
    final now = ref.watch(clockProvider).now();
    final today = dateOnly(now);

    void open(Widget page) {
      final nav = Navigator.of(context);
      nav.pop();
      nav.push(MaterialPageRoute(builder: (_) => page));
    }

    void openTask(Occurrence o) {
      final nav = Navigator.of(context);
      nav.pop();
      showTaskDetail(nav.context, o);
    }

    Widget header(String text, {Widget? trailing}) => Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 12, 4),
          child: Row(children: [
            Expanded(
              child: Text(text, style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.primary)),
            ),
            ?trailing,
          ]),
        );

    Widget item(IconData icon, String label, VoidCallback onTap, {Widget? trailing}) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          visualDensity: VisualDensity.compact,
          leading: Icon(icon),
          title: Text(label),
          trailing: trailing,
          onTap: onTap,
        );

    // Cuentas atrás (próximas) y fijadas (pendientes).
    final countdowns = snap
        .occurrencesBetween(today, addDays(today, 400))
        .where((o) => o.task.countdown && !o.completed)
        .take(5)
        .toList();
    final pinned = [
      for (final t in snap.tasks.where((t) => t.pinned && !t.isCompleted && !t.isSeries))
        Occurrence(task: t, series: t, occurrenceDate: null, completed: false),
    ].take(5).toList();
    final projects = snap.projects.where((p) => !p.archived).toList()
      ..sort((a, b) {
        final da = a.dueDate, db = b.dueDate;
        if (da == null && db == null) return a.name.compareTo(b.name);
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    final hidden = snap.hiddenCategories;
    final inboxCount = snap.inbox.length;

    Future<void> toggleCategory(int id, bool visible) async {
      final set = {...hidden};
      visible ? set.remove(id) : set.add(id);
      await ref.read(repositoryProvider).setSetting(AppSnapshot.hiddenCategoriesKey, set.join(','));
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 16, 4),
              child: Text(l.appTitle, style: theme.textTheme.headlineSmall),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 16, 8),
              child: Text(f.fullDate(now), style: theme.textTheme.bodySmall),
            ),
            const WhaleDrawerCard(),
            item(Icons.inbox_outlined, l.inbox, () => open(const InboxScreen()),
                trailing: inboxCount > 0 ? Badge(label: Text('$inboxCount')) : null),
            if (inboxCount > 0) item(Icons.playlist_add_check, l.processInbox, () => open(const ProcessInboxScreen())),
            item(Icons.search, l.search, () => open(const SearchScreen())),
            const Divider(),

            // ---- Cuentas atrás y fijadas
            header(l.countdownsAndPinned),
            if (countdowns.isEmpty && pinned.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 4, 16, 8),
                child: Text(l.nothingPinned, style: theme.textTheme.bodySmall),
              ),
            for (final o in countdowns)
              item(Icons.hourglass_bottom, o.task.title, () => openTask(o),
                  trailing: Text(l.daysLeft(daysBetween(now, o.task.start!)), style: theme.textTheme.labelMedium)),
            for (final o in pinned) item(Icons.push_pin_outlined, o.task.title, () => openTask(o)),
            const Divider(),

            // ---- Proyectos
            header(
              l.projects,
              trailing: IconButton(
                tooltip: l.newProject,
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final id = await editProject(context, ref);
                  if (id != null && context.mounted) open(ProjectScreen(projectId: id));
                },
              ),
            ),
            for (final p in projects)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                visualDensity: VisualDensity.compact,
                leading: Icon(Icons.folder, color: Color(p.color)),
                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProjectProgress(project: p, dense: true),
                    if (p.dueDate != null && daysBetween(now, p.dueDate!) >= 0)
                      Text(l.daysLeft(daysBetween(now, p.dueDate!)), style: theme.textTheme.labelSmall),
                  ],
                ),
                onTap: () => open(ProjectScreen(projectId: p.id!)),
              ),
            const Divider(),

            // ---- Categorías visibles
            header(l.showInCalendar),
            for (final c in snap.categories)
              CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                visualDensity: VisualDensity.compact,
                dense: true,
                activeColor: Color(c.color),
                secondary: CircleAvatar(radius: 7, backgroundColor: Color(c.color)),
                title: Text(c.name),
                value: !hidden.contains(c.id),
                onChanged: (v) => toggleCategory(c.id!, v ?? true),
              ),
            item(Icons.label_outline, l.manageCategories, () => open(const CategoriesScreen())),
            const Divider(),

            // ---- Herramientas
            item(Icons.book_outlined, l.diary, () => open(const DiaryScreen())),
            if (settings.whaleEnabled && settings.whaleTank && !settings.whaleDrawer)
              item(Icons.water, l.whaleTitle, () => open(const WhaleTankScreen())),
            item(Icons.dashboard_customize_outlined, l.templates, () => open(const TemplatesScreen())),
            item(Icons.insights_outlined, l.statistics, () => open(const StatsScreen())),
            item(Icons.rate_review_outlined, l.weeklyReview, () => open(const WeeklyReviewScreen())),
            const Divider(),
            item(Icons.gesture, l.gestureGuide, () => open(const GestureGuideScreen())),
            item(Icons.settings_outlined, l.settings, () => open(const SettingsScreen())),
          ],
        ),
      ),
    );
  }
}

// Pantalla principal: selector de vista siempre visible, navegación (RF-32),
// barra de selección múltiple (RF-33), bandeja (RF-02) y avisos de inicio.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/entities.dart';
import '../../domain/settings.dart';
import '../../domain/time.dart';
import '../../l10n/app_localizations.dart';
import '../../services/notification_service.dart';
import '../calendar/agenda_view.dart';
import '../calendar/day_week_views.dart';
import '../calendar/month_view.dart';
import '../common/actions.dart';
import '../common/celebration.dart';
import '../common/format.dart';
import '../providers.dart';
import '../screens/inbox_screen.dart';
import '../screens/overdue_dialog.dart';
import '../screens/search_screen.dart';
import '../task/quick_add.dart';
import 'app_drawer.dart';
import 'extra_destinations.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _inboxOpen = false;
  bool _startupDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startup());
  }

  Future<void> _startup() async {
    // Espera a que la primera foto esté cargada.
    await ref.read(snapshotStreamProvider.future);
    if (!mounted || _startupDone) return;
    _startupDone = true;
    await _askPermissionIfNeeded();
    if (!mounted) return;
    await _checkOverdue();
    if (!mounted) return;
    await maybeOfferWeeklyReview(context, ref);
  }

  Future<void> _askPermissionIfNeeded() async {
    final settings = ref.read(settingsProvider);
    if (settings.permissionAsked) return;
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: Text(l.notifPermissionTitle),
        content: Text(l.notifPermissionBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.later)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.allow)),
        ],
      ),
    );
    await ref.read(repositoryProvider).setSetting(AppSettings.kPermissionAsked, '1');
    if (ok == true) await NotificationService.instance.requestPermissions();
  }

  Future<void> _checkOverdue() async {
    final repo = ref.read(repositoryProvider);
    final now = ref.read(clockProvider).now();
    final today = formatDateKey(now);
    final last = await repo.getSetting(AppSettings.kLastOverdueCheck);
    if (last == today) return;
    await repo.setSetting(AppSettings.kLastOverdueCheck, today);
    final overdue = ref.read(snapshotProvider).overdue(now);
    if (overdue.isEmpty || !mounted) return;
    await showOverdueDialog(context, overdue);
  }

  String _title(CalendarState s, Fmt f, AppLocalizations l) {
    switch (s.view) {
      case CalendarView.day:
      case CalendarView.agenda:
        return f.monthYearShort(s.anchor);
      case CalendarView.week:
        final ws = startOfWeek(s.anchor, weekStartsMonday: ref.read(settingsProvider).weekStartsMonday);
        final we = addDays(ws, 6);
        return ws.month == we.month
            ? f.monthYearShort(ws)
            : '${f.dayMonth(ws)} – ${f.dayMonth(we)}';
      case CalendarView.threeDays:
        final end = addDays(s.anchor, 2);
        return s.anchor.month == end.month
            ? f.monthYearShort(s.anchor)
            : '${f.dayMonth(s.anchor)} – ${f.dayMonth(end)}';
      case CalendarView.workWeek:
        final mon = startOfWeek(s.anchor);
        final fri = addDays(mon, 4);
        return mon.month == fri.month
            ? f.monthYearShort(mon)
            : '${f.dayMonth(mon)} – ${f.dayMonth(fri)}';
      case CalendarView.month:
        return f.monthYearShort(s.anchor);
    }
  }

  /// Destinos de la barra inferior (máx. 5). Semana y entre semana comparten
  /// el mismo destino; tocarlo otra vez alterna entre ambas.
  static const _navViews = [
    CalendarView.day,
    CalendarView.threeDays,
    CalendarView.week,
    CalendarView.month,
    CalendarView.agenda,
  ];

  int _navIndex(CalendarView v) =>
      v == CalendarView.workWeek ? 2 : _navViews.indexOf(v);

  void _onNav(int i) {
    final ctrl = ref.read(calendarProvider.notifier);
    final current = ref.read(calendarProvider).view;
    final target = _navViews[i];
    if (target == CalendarView.week &&
        (current == CalendarView.week || current == CalendarView.workWeek)) {
      ctrl.setView(current == CalendarView.week ? CalendarView.workWeek : CalendarView.week);
    } else {
      ctrl.setView(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final state = ref.watch(calendarProvider);
    final selection = ref.watch(selectionProvider);
    final inboxCount = ref.watch(snapshotProvider.select((s) => s.inbox.length));
    final selecting = selection.isNotEmpty;
    final timeline = const {
      CalendarView.day,
      CalendarView.threeDays,
      CalendarView.week,
      CalendarView.workWeek,
    }.contains(state.view);

    final body = switch (state.view) {
      CalendarView.day => const DayView(key: ValueKey('day')),
      CalendarView.threeDays => const ThreeDayView(key: ValueKey('3d')),
      CalendarView.week => const WeekView(key: ValueKey('week')),
      CalendarView.workWeek => const WeekView(key: ValueKey('workWeek'), workWeek: true),
      CalendarView.month => const MonthView(key: ValueKey('month')),
      CalendarView.agenda => const AgendaView(key: ValueKey('agenda')),
    };

    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && selecting) ref.read(selectionProvider.notifier).clear();
      },
      child: CelebrationOverlay(
        child: Scaffold(
          appBar: selecting ? _selectionBar(context, selection.length) : _mainBar(context, state, f, l, inboxCount, timeline),
          drawer: selecting ? null : const AppDrawer(),
          body: Column(
            children: [
              Expanded(child: body),
              if (_inboxOpen && timeline) InboxPanel(onClose: () => setState(() => _inboxOpen = false)),
            ],
          ),
          floatingActionButton: selecting || (_inboxOpen && timeline)
              ? null
              : FloatingActionButton(
                  tooltip: l.newTask,
                  onPressed: () => showQuickAdd(context),
                  child: const Icon(Icons.add),
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _navIndex(state.view),
            onDestinationSelected: _onNav,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(icon: const Icon(Icons.view_day_outlined), selectedIcon: const Icon(Icons.view_day), label: l.viewDay),
              NavigationDestination(icon: const Icon(Icons.view_column_outlined), selectedIcon: const Icon(Icons.view_column), label: l.viewThreeDays),
              NavigationDestination(
                icon: const Icon(Icons.view_week_outlined),
                selectedIcon: Icon(state.view == CalendarView.workWeek ? Icons.work : Icons.view_week),
                label: state.view == CalendarView.workWeek ? l.viewWorkWeek : l.viewWeek,
                tooltip: '${l.viewWeek} / ${l.viewWorkWeek}',
              ),
              NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: l.viewMonth),
              NavigationDestination(icon: const Icon(Icons.view_agenda_outlined), selectedIcon: const Icon(Icons.view_agenda), label: l.viewAgenda),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _mainBar(BuildContext context, CalendarState state, Fmt f, AppLocalizations l,
      int inboxCount, bool timeline) {
    return AppBar(
      title: GestureDetector(onTap: _goToDate, child: Text(_title(state, f, l))),
      actions: [
        IconButton(
          tooltip: l.today,
          icon: const Icon(Icons.today),
          onPressed: () => ref.read(calendarProvider.notifier).today(),
        ),
        IconButton(tooltip: l.goToDate, icon: const Icon(Icons.event_outlined), onPressed: _goToDate),
        IconButton(
          tooltip: l.search,
          icon: const Icon(Icons.search),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
        ),
        IconButton(
          tooltip: l.inbox,
          icon: Badge(
            isLabelVisible: inboxCount > 0,
            label: Text('$inboxCount'),
            child: const Icon(Icons.inbox_outlined),
          ),
          onPressed: () {
            if (timeline) {
              setState(() => _inboxOpen = !_inboxOpen);
            } else {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InboxScreen()));
            }
          },
        ),
      ],
    );
  }

  Future<void> _goToDate() async {
    final anchor = ref.read(calendarProvider).anchor;
    final d = await showDatePicker(
      context: context,
      initialDate: anchor,
      firstDate: DateTime(anchor.year - 20),
      lastDate: DateTime(anchor.year + 20),
    );
    if (d != null) ref.read(calendarProvider.notifier).goTo(d);
  }

  PreferredSizeWidget _selectionBar(BuildContext context, int count) {
    final l = context.l10n;
    final sel = ref.read(selectionProvider.notifier);
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.close), onPressed: sel.clear),
      title: Text(l.selectedCount(count)),
      actions: [
        IconButton(
          tooltip: l.complete,
          icon: const Icon(Icons.done_all),
          onPressed: () async {
            final ui = Ui.of(context);
            final list = ref.read(selectionProvider).toList();
            sel.clear();
            final allDone = list.every((o) => o.completed);
            final point = await ui.service.setCompletedMany(list, !allDone);
            ui.haptic(HapticKind.light);
            ui.undo(point, l.tasksCompleted(list.length));
          },
        ),
        IconButton(
          tooltip: l.moveTo,
          icon: const Icon(Icons.drive_file_move_outline),
          onPressed: () async {
            final ui = Ui.of(context);
            final list = ref.read(selectionProvider).toList();
            final d = await showDatePicker(
              context: context,
              initialDate: ref.read(calendarProvider).anchor,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (d == null) return;
            sel.clear();
            final point = await ui.service.moveMany(list, d);
            ui.undo(point, l.tasksMoved(list.length));
          },
        ),
        IconButton(
          tooltip: l.changeCategory,
          icon: const Icon(Icons.label_outline),
          onPressed: () async {
            final ui = Ui.of(context);
            final list = ref.read(selectionProvider).toList();
            final cats = ref.read(snapshotProvider).categories;
            final picked = await showDialog<Category?>(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: Text(l.changeCategory),
                children: [
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, const Category(id: -1, name: '', color: 0)),
                    child: Text(l.noCategory),
                  ),
                  for (final c in cats)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, c),
                      child: Row(children: [
                        CircleAvatar(radius: 7, backgroundColor: Color(c.color)),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ]),
                    ),
                ],
              ),
            );
            if (picked == null) return;
            sel.clear();
            final point = await ui.service.setCategoryMany(list, picked.id == -1 ? null : picked.id);
            ui.undo(point, l.taskSaved);
          },
        ),
        IconButton(
          tooltip: l.delete,
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final ui = Ui.of(context);
            final list = ref.read(selectionProvider).toList();
            sel.clear();
            final point = await ui.service.deleteMany(list);
            ui.haptic(HapticKind.medium);
            ui.undo(point, l.tasksDeleted(list.length));
          },
        ),
      ],
    );
  }
}

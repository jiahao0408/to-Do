// Búsqueda y filtros (RF-40).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/task.dart';
import '../../domain/recurrence/recurrence_engine.dart';
import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../calendar/agenda_view.dart';
import '../common/format.dart';
import '../providers.dart';

enum StatusFilter { pending, completed, overdue }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  final Set<int?> _categories = {};
  final Set<Priority> _priorities = {};
  StatusFilter? _status;
  DateTimeRange? _range;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Ocurrencia representativa de una tarea (la próxima, para series).
  Occurrence? _representative(AppSnapshot snap, Task t, DateTime now) {
    if (!t.isSeries) {
      return Occurrence(task: t, series: t, occurrenceDate: null, completed: t.isCompleted);
    }
    final from = _range?.start ?? dateOnly(now);
    final next = RecurrenceEngine.nextOnOrAfter(t.rule!, t.start!, from);
    if (next == null) return null;
    return snap.occurrenceOf(t.id!, next);
  }

  List<Occurrence> _results(AppSnapshot snap, DateTime now) {
    final q = _query.trim().toLowerCase();
    final today = dateOnly(now);
    final out = <Occurrence>[];
    for (final t in snap.tasks) {
      if (t.status == TaskStatus.discarded) continue;
      if (q.isNotEmpty) {
        final inSubs = snap.subtasksOf(t.id!).any((s) => s.title.toLowerCase().contains(q));
        if (!t.title.toLowerCase().contains(q) && !t.notes.toLowerCase().contains(q) && !inSubs) {
          continue;
        }
      }
      if (_categories.isNotEmpty && !_categories.contains(t.categoryId)) continue;
      if (_priorities.isNotEmpty && !_priorities.contains(t.priority)) continue;
      final o = _representative(snap, t, now);
      if (o == null) continue;
      if (_range != null) {
        final s = o.task.start;
        if (s == null || dateOnly(s).isBefore(_range!.start) || dateOnly(s).isAfter(_range!.end)) {
          continue;
        }
      }
      switch (_status) {
        case StatusFilter.pending:
          if (o.completed) continue;
        case StatusFilter.completed:
          if (!o.completed) continue;
        case StatusFilter.overdue:
          if (o.completed || o.task.start == null || !dateOnly(o.task.start!).isBefore(today)) continue;
        case null:
          break;
      }
      out.add(o);
    }
    out.sort((a, b) {
      final sa = a.task.start, sb = b.task.start;
      if (sa == null && sb == null) return compareTasks(a.task, b.task);
      if (sa == null) return 1;
      if (sb == null) return -1;
      return sa.compareTo(sb);
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final snap = ref.watch(snapshotProvider);
    final now = ref.watch(clockProvider).now();
    final results = _results(snap, now);
    final hasFilters =
        _categories.isNotEmpty || _priorities.isNotEmpty || _status != null || _range != null;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: l.searchHint, border: InputBorder.none),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                _ctrl.clear();
                _query = '';
              }),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                if (hasFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: const Icon(Icons.filter_alt_off, size: 18),
                      label: Text(l.clearFilters),
                      onPressed: () => setState(() {
                        _categories.clear();
                        _priorities.clear();
                        _status = null;
                        _range = null;
                      }),
                    ),
                  ),
                for (final (s, label) in [
                  (StatusFilter.pending, l.statusPending),
                  (StatusFilter.completed, l.statusCompleted),
                  (StatusFilter.overdue, l.statusOverdue),
                ])
                  _chip(label, _status == s, (v) => setState(() => _status = v ? s : null)),
                for (final p in Priority.values)
                  _chip(priorityLabel(l, p), _priorities.contains(p),
                      (v) => setState(() => v ? _priorities.add(p) : _priorities.remove(p)),
                      icon: Icon(Icons.flag, size: 16, color: priorityColor(p))),
                for (final c in snap.categories)
                  _chip(c.name, _categories.contains(c.id),
                      (v) => setState(() => v ? _categories.add(c.id) : _categories.remove(c.id)),
                      icon: CircleAvatar(radius: 6, backgroundColor: Color(c.color))),
                _chip(
                  _range == null ? l.dateRange : '${f.dayMonth(_range!.start)} – ${f.dayMonth(_range!.end)}',
                  _range != null,
                  (_) async {
                    final r = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(now.year - 10),
                      lastDate: DateTime(now.year + 10),
                      initialDateRange: _range,
                    );
                    setState(() => _range = r);
                  },
                  icon: const Icon(Icons.date_range, size: 16),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: results.isEmpty
                ? Center(child: Text(l.noResults))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (_, i) => SwipeableTaskTile(occurrence: results[i], showDate: true),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, ValueChanged<bool> onSelected, {Widget? icon}) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          avatar: icon,
          label: Text(label),
          selected: selected,
          onSelected: onSelected,
        ),
      );
}

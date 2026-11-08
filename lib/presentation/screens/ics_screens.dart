// Importar .ics con vista previa y exportar .ics con opciones.
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/ics_service.dart';
import '../../domain/ics/ics.dart';
import '../../domain/recurrence/recurrence_rule.dart';
import '../../domain/time.dart';
import '../../services/ics_files.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../providers.dart';

/// Elige un .ics y abre la vista previa.
Future<void> pickAndImportIcs(BuildContext context) async {
  final nav = Navigator.of(context);
  final files = await FilePicker.pickFiles(type: FileType.any);
  final path = files.isEmpty ? null : files.first.path;
  if (path == null) return;
  nav.push(MaterialPageRoute(builder: (_) => IcsImportScreen(path: path)));
}

class IcsImportScreen extends ConsumerStatefulWidget {
  const IcsImportScreen({super.key, required this.path});
  final String path;

  @override
  ConsumerState<IcsImportScreen> createState() => _IcsImportScreenState();
}

class _IcsImportScreenState extends ConsumerState<IcsImportScreen> {
  IcsParseResult? _result;
  Object? _error;
  Map<String, int> _existing = {};
  final Set<String> _selected = {};

  /// null = según el archivo; -1 = sin categoría; otro = id.
  int? _category;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final text = await readIcsFile(widget.path);
      final parser = IcsParser(convert: deviceConverter(ref.read(timeZoneProvider)));
      final result = parser.parse(text);
      final existing = await ref.read(repositoryProvider).taskIdsByIcsUid();
      if (!mounted) return;
      setState(() {
        _result = result;
        _existing = existing;
        _selected
          ..clear()
          ..addAll(result.items.where((i) => !existing.containsKey(i.uid)).map((i) => i.uid));
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _import() async {
    final result = _result;
    if (result == null || _selected.isEmpty) return;
    setState(() => _busy = true);
    final ui = Ui.of(context);
    final items = result.items.where((i) => _selected.contains(i.uid)).toList();
    final choice = _category == null
        ? const FromFile()
        : FixedCategory(_category == -1 ? null : _category);
    final point = await IcsService(ui.repo).import(
      items,
      snap: ui.read(snapshotProvider),
      tz: ui.read(timeZoneProvider),
      category: choice,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ui.undo(point, ui.l.icsImported(items.length));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final theme = Theme.of(context);
    final cats = ref.watch(snapshotProvider).categories;
    final result = _result;

    Widget body;
    if (_error != null) {
      body = Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l.icsError('$_error'))));
    } else if (result == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (result.items.isEmpty) {
      body = Center(child: Text(l.icsNothing));
    } else {
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _category,
                    decoration: InputDecoration(labelText: l.category),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l.icsCategoryFromFile)),
                      DropdownMenuItem(value: -1, child: Text(l.noCategory)),
                      for (final c in cats)
                        DropdownMenuItem(
                          value: c.id,
                          child: Row(children: [
                            CircleAvatar(radius: 6, backgroundColor: Color(c.color)),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ]),
                        ),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _selected.addAll(result.items.map((i) => i.uid))),
                  child: Text(l.icsSelectAll),
                ),
                TextButton(onPressed: () => setState(_selected.clear), child: Text(l.icsSelectNone)),
                const Spacer(),
                Text('${_selected.length}/${result.items.length}', style: theme.textTheme.labelLarge),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: result.items.length,
              itemBuilder: (context, i) {
                final it = result.items[i];
                final when = it.start == null
                    ? l.unscheduled
                    : it.allDay
                        ? f.weekdayDayMonth(it.start!)
                        : '${f.weekdayDayMonth(it.start!)} ${f.time(it.start!)}';
                final rule = it.unsupportedRule ? null : RecurrenceRule.tryParse(it.rrule);
                final notes = <String>[
                  if (rule != null && it.start != null) describeRule(l, f, rule, it.start!),
                  if (it.unsupportedRule) l.icsUnsupportedRule,
                  if (it.multiDay) l.icsMultiDay,
                  if (_existing.containsKey(it.uid)) l.icsAlreadyImported,
                ];
                return CheckboxListTile(
                  value: _selected.contains(it.uid),
                  onChanged: (v) => setState(() => v == true ? _selected.add(it.uid) : _selected.remove(it.uid)),
                  title: Text(it.title.isEmpty ? '—' : it.title),
                  subtitle: Text([when, if (it.categoryName != null) it.categoryName!, ...notes].join(' · ')),
                  secondary: Icon(it.isTodo
                      ? Icons.check_box_outlined
                      : rule != null
                          ? Icons.repeat
                          : Icons.event),
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(result?.calendarName ?? l.icsImport)),
      body: body,
      bottomNavigationBar: result == null || result.items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download),
                  label: Text(l.icsImportButton(_selected.length)),
                  onPressed: _selected.isEmpty || _busy ? null : _import,
                ),
              ),
            ),
    );
  }
}

class IcsExportScreen extends ConsumerStatefulWidget {
  const IcsExportScreen({super.key});

  @override
  ConsumerState<IcsExportScreen> createState() => _IcsExportScreenState();
}

class _IcsExportScreenState extends ConsumerState<IcsExportScreen> {
  DateTimeRange? _range;
  Set<int>? _categories; // null = todas
  bool _completed = false;
  bool _undated = true;

  IcsExportOptions get _options => IcsExportOptions(
        from: _range?.start,
        to: _range?.end,
        categoryIds: _categories,
        includeCompleted: _completed,
        includeUndated: _undated,
      );

  Future<void> _export() async {
    final ui = Ui.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final snap = ui.read(snapshotProvider);
    final content = IcsExporter(snap, now: DateTime.now()).export(_options);
    final File file = await writeIcsExport(content);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'text/calendar')],
      subject: file.uri.pathSegments.last,
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final snap = ref.watch(snapshotProvider);
    final count = IcsExporter(snap, now: DateTime.now()).select(_options).length;
    final allCats = {for (final c in snap.categories) c.id!, -1};
    bool isOn(int id) => _categories == null || _categories!.contains(id);
    void toggle(int id, bool on) => setState(() {
          final s = {...(_categories ?? allCats)};
          on ? s.add(id) : s.remove(id);
          _categories = s.length == allCats.length ? null : s;
        });

    return Scaffold(
      appBar: AppBar(title: Text(l.icsExport)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.icsRange, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l.icsAllDates)),
              ButtonSegment(
                value: true,
                label: Text(_range == null ? l.icsChooseRange : '${f.dayMonth(_range!.start)} – ${f.dayMonth(_range!.end)}'),
              ),
            ],
            selected: {_range != null},
            onSelectionChanged: (v) async {
              if (!v.first) {
                setState(() => _range = null);
                return;
              }
              final now = DateTime.now();
              final r = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 10),
                lastDate: DateTime(now.year + 10),
                initialDateRange: _range ?? DateTimeRange(start: dateOnly(now), end: addDays(dateOnly(now), 30)),
              );
              if (r != null) setState(() => _range = r);
            },
          ),
          const SizedBox(height: 16),
          Text(l.categories, style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 6,
            children: [
              for (final c in snap.categories)
                FilterChip(
                  avatar: CircleAvatar(radius: 6, backgroundColor: Color(c.color)),
                  label: Text(c.name),
                  selected: isOn(c.id!),
                  onSelected: (v) => toggle(c.id!, v),
                ),
              FilterChip(label: Text(l.noCategory), selected: isOn(-1), onSelected: (v) => toggle(-1, v)),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.icsIncludeCompleted),
            value: _completed,
            onChanged: (v) => setState(() => _completed = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.icsIncludeUndated),
            value: _undated,
            onChanged: (v) => setState(() => _undated = v),
          ),
          const SizedBox(height: 8),
          Text(l.icsWillExport(count), style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            icon: const Icon(Icons.ios_share),
            label: Text(l.icsExportButton),
            onPressed: count == 0 ? null : _export,
          ),
        ),
      ),
    );
  }
}

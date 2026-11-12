// Diario: una nota por día, desde la vista día y desde el menú.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/time.dart';
import '../common/format.dart';
import '../providers.dart';
import '../common/ph_icons.dart';

/// Abre el editor de la nota de [day].
Future<void> openDayNote(BuildContext context, DateTime day) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => DayNoteEditor(day: dateOnly(day))));

class DayNoteEditor extends ConsumerStatefulWidget {
  const DayNoteEditor({super.key, required this.day});
  final DateTime day;

  @override
  ConsumerState<DayNoteEditor> createState() => _DayNoteEditorState();
}

class _DayNoteEditorState extends ConsumerState<DayNoteEditor> {
  late final TextEditingController _ctrl =
      TextEditingController(text: ref.read(snapshotProvider).noteOn(widget.day)?.body ?? '');
  late final String _initial = _ctrl.text;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_ctrl.text != _initial) {
      await ref.read(repositoryProvider).saveDayNote(widget.day, _ctrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    return PopScope(
      // Guarda al salir (también con el botón atrás).
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(f.fullDate(widget.day))),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _ctrl,
            autofocus: _initial.isEmpty,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.dayNoteHint, border: InputBorder.none),
          ),
        ),
      ),
    );
  }
}

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final now = ref.watch(clockProvider).now();
    final notes = ref
        .watch(snapshotProvider)
        .dayNotes
        .where((n) => _q.isEmpty || n.body.toLowerCase().contains(_q.toLowerCase()))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final hasToday = ref.watch(snapshotProvider).noteOn(now) != null;
    return Scaffold(
      appBar: AppBar(title: Text(l.diary)),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(hasToday ? PhosphorIconsRegular.notePencil : PhosphorIconsRegular.plus),
        label: Text('${l.dayNote} · ${l.today}'),
        onPressed: () => openDayNote(context, now),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
                hintText: l.searchDiary,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? Center(child: Text(l.diaryEmpty))
                : ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (_, i) {
                      final n = notes[i];
                      return ListTile(
                        leading: const Icon(PhosphorIconsRegular.bookOpenText),
                        title: Text(f.fullDate(n.date)),
                        subtitle: Text(n.body, maxLines: 3, overflow: TextOverflow.ellipsis),
                        onTap: () => openDayNote(context, n.date),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Editor de repetición: RF-19 (básicas), RF-20 (avanzadas), RF-21 (fin),
// RF-22 (resumen legible).
import 'package:flutter/material.dart';

import '../../domain/recurrence/recurrence_rule.dart';
import '../../domain/time.dart';
import '../common/format.dart';

/// Devuelve la regla elegida, o `''` si se quitó la repetición, o null si
/// se canceló.
Future<String?> showRecurrenceEditor(
    BuildContext context, RecurrenceRule? initial, DateTime start) {
  return Navigator.of(context).push<String>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => RecurrenceEditor(initial: initial, start: start),
  ));
}

enum _MonthlyMode { byDay, byPosition, lastWeekday }

class RecurrenceEditor extends StatefulWidget {
  const RecurrenceEditor({super.key, this.initial, required this.start});
  final RecurrenceRule? initial;
  final DateTime start;

  @override
  State<RecurrenceEditor> createState() => _RecurrenceEditorState();
}

class _RecurrenceEditorState extends State<RecurrenceEditor> {
  Frequency? freq;
  int interval = 1;
  Set<int> weekdays = {};
  _MonthlyMode monthlyMode = _MonthlyMode.byDay;
  RecurrenceEnd end = RecurrenceEnd.never;
  DateTime? until;
  int count = 10;
  late final TextEditingController intervalCtrl;
  late final TextEditingController countCtrl;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    if (r != null) {
      freq = r.freq;
      interval = r.interval;
      weekdays = {...r.byWeekdays};
      if (r.isPositional) {
        monthlyMode = r.bySetPos == -1 ? _MonthlyMode.lastWeekday : _MonthlyMode.byPosition;
      }
      end = r.end;
      until = r.until;
      count = r.count ?? 10;
    }
    if (weekdays.isEmpty) weekdays = {widget.start.weekday};
    intervalCtrl = TextEditingController(text: '$interval');
    countCtrl = TextEditingController(text: '$count');
  }

  @override
  void dispose() {
    intervalCtrl.dispose();
    countCtrl.dispose();
    super.dispose();
  }

  int get _nth => (widget.start.day - 1) ~/ 7 + 1;

  RecurrenceRule? build_() {
    if (freq == null) return null;
    final s = widget.start;
    return RecurrenceRule(
      freq: freq!,
      interval: interval < 1 ? 1 : interval,
      byWeekdays: freq == Frequency.weekly ? weekdays : const {},
      byMonthDay: freq == Frequency.monthly && monthlyMode == _MonthlyMode.byDay ? s.day : null,
      bySetPos: freq == Frequency.monthly && monthlyMode != _MonthlyMode.byDay
          ? (monthlyMode == _MonthlyMode.lastWeekday ? -1 : _nth)
          : null,
      byPosWeekday:
          freq == Frequency.monthly && monthlyMode != _MonthlyMode.byDay ? s.weekday : null,
      until: end == RecurrenceEnd.until ? (until ?? addDays(s, 30)) : null,
      count: end == RecurrenceEnd.count ? (count < 1 ? 1 : count) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final rule = build_();
    final s = widget.start;
    final mondayFirst = MaterialLocalizations.of(context).firstDayOfWeekIndex == 1;
    final order = mondayFirst ? [1, 2, 3, 4, 5, 6, 7] : [7, 1, 2, 3, 4, 5, 6];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.repeat),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, rule?.toRRule() ?? ''),
            child: Text(l.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                rule == null ? l.noRepeat : describeRule(l, f, rule, s),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<Frequency?>(
            segments: [
              ButtonSegment(value: null, label: Text(l.none)),
              ButtonSegment(value: Frequency.daily, label: Text(l.freqDaily)),
              ButtonSegment(value: Frequency.weekly, label: Text(l.freqWeekly)),
              ButtonSegment(value: Frequency.monthly, label: Text(l.freqMonthly)),
              ButtonSegment(value: Frequency.yearly, label: Text(l.freqYearly)),
            ],
            selected: {freq},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() => freq = v.first),
          ),
          if (freq != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(l.every),
                const SizedBox(width: 12),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: intervalCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (v) => setState(() => interval = int.tryParse(v) ?? 1),
                  ),
                ),
                const SizedBox(width: 12),
                Text(l.intervalUnit(switch (freq!) {
                  Frequency.daily => 'day',
                  Frequency.weekly => 'week',
                  Frequency.monthly => 'month',
                  Frequency.yearly => 'year',
                })),
              ],
            ),
          ],
          if (freq == Frequency.weekly) ...[
            const SizedBox(height: 16),
            Text(l.onDays, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final d in order)
                  FilterChip(
                    label: Text(f.weekdayNarrow(d)),
                    selected: weekdays.contains(d),
                    onSelected: (v) => setState(() {
                      if (v) {
                        weekdays.add(d);
                      } else if (weekdays.length > 1) {
                        weekdays.remove(d);
                      }
                    }),
                  ),
              ],
            ),
          ],
          if (freq == Frequency.monthly) ...[
            const SizedBox(height: 8),
            RadioGroup<_MonthlyMode>(
              groupValue: monthlyMode,
              onChanged: (v) => setState(() => monthlyMode = v!),
              child: Column(
                children: [
                  RadioListTile(
                    value: _MonthlyMode.byDay,
                    title: Text(l.monthlyByDay(s.day)),
                  ),
                  if (_nth <= 4)
                    RadioListTile(
                      value: _MonthlyMode.byPosition,
                      title: Text(l.monthlyByPosition(l.ordinal('$_nth'), f.weekdayName(s.weekday))),
                    ),
                  RadioListTile(
                    value: _MonthlyMode.lastWeekday,
                    title: Text(l.monthlyByPosition(l.ordinal('last'), f.weekdayName(s.weekday))),
                  ),
                ],
              ),
            ),
          ],
          if (freq != null) ...[
            const Divider(height: 32),
            Text(l.endsLabel, style: Theme.of(context).textTheme.titleSmall),
            RadioGroup<RecurrenceEnd>(
              groupValue: end,
              onChanged: (v) => setState(() => end = v!),
              child: Column(
                children: [
                  RadioListTile(value: RecurrenceEnd.never, title: Text(l.endsNever)),
                  RadioListTile(
                    value: RecurrenceEnd.until,
                    title: Text(l.endsUntil),
                    subtitle: end == RecurrenceEnd.until
                        ? Text(f.fullDate(until ?? addDays(s, 30)))
                        : null,
                    secondary: end == RecurrenceEnd.until
                        ? IconButton(
                            icon: const Icon(Icons.event),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: until ?? addDays(s, 30),
                                firstDate: dateOnly(s),
                                lastDate: DateTime(s.year + 50),
                              );
                              if (d != null) setState(() => until = d);
                            },
                          )
                        : null,
                  ),
                  RadioListTile(
                    value: RecurrenceEnd.count,
                    title: Text(l.endsCount),
                    secondary: end == RecurrenceEnd.count
                        ? SizedBox(
                            width: 72,
                            child: TextField(
                              controller: countCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(labelText: l.repetitions),
                              onChanged: (v) => setState(() => count = int.tryParse(v) ?? 1),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// RF-10: cronómetro iniciar/pausar/parar; muestra estimado vs. real.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/snapshot.dart';
import '../common/format.dart';
import '../providers.dart';

class TimerSection extends ConsumerStatefulWidget {
  const TimerSection({super.key, required this.occurrence});
  final Occurrence occurrence;

  @override
  ConsumerState<TimerSection> createState() => _TimerSectionState();
}

class _TimerSectionState extends ConsumerState<TimerSection> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _running != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  dynamic get _running {
    final entries = ref.read(snapshotProvider).timeEntriesOf(widget.occurrence.taskId);
    for (final e in entries) {
      if (e.running) return e;
    }
    return null;
  }

  String _clock(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final theme = Theme.of(context);
    final repo = ref.read(repositoryProvider);
    final o = widget.occurrence;
    final entries = ref.watch(snapshotProvider).timeEntriesOf(o.taskId);
    final now = DateTime.now();
    final total = entries.fold<Duration>(Duration.zero, (s, e) => s + e.elapsed(now));
    final running = entries.where((e) => e.running).firstOrNull;
    final est = o.task.estimateMin;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: running != null ? theme.colorScheme.primary : null),
                  const SizedBox(width: 8),
                  Text(l.timer, style: theme.textTheme.titleSmall),
                  const Spacer(),
                  Text(_clock(total),
                      style: theme.textTheme.titleLarge!.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
              if (est != null) ...[
                const SizedBox(height: 4),
                Text(l.estimatedVsReal(f.duration(est), f.duration(total.inMinutes))),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (total.inMinutes / est).clamp(0.0, 1.0),
                  color: total.inMinutes > est ? theme.colorScheme.error : null,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (running == null)
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l.timerStart),
                      onPressed: () => repo.startTimer(o.taskId, o.occurrenceDate),
                    )
                  else ...[
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.pause),
                      label: Text(l.timerPause),
                      onPressed: () => repo.stopTimer(running.id!),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.stop),
                      label: Text(l.timerStop),
                      onPressed: () async {
                        await repo.stopTimer(running.id!);
                        if (context.mounted) {
                          ScaffoldMessenger.maybeOf(context)
                              ?.showSnackBar(SnackBar(content: Text('${l.timer}: ${_clock(total)}')));
                        }
                      },
                    ),
                  ],
                  if (entries.isNotEmpty && running == null)
                    TextButton.icon(
                      icon: const Icon(Icons.restart_alt),
                      label: Text(l.timerReset),
                      onPressed: () => repo.deleteTimeEntriesOf(o.taskId),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

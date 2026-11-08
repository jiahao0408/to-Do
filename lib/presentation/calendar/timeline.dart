// Línea de tiempo por horas para las vistas día (1 columna) y semana
// (7 columnas). RF-28, RF-29, RF-15 (lado a lado), RF-33 (selección),
// RF-34 (arrastrar/estirar), RF-35 (mover de día), RF-36 (pulsar hueco),
// RF-39 (pellizcar), RF-02 (soltar desde la bandeja).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/task.dart';
import '../../domain/overlap.dart';
import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../common/task_tile.dart';
import '../providers.dart';
import '../task/quick_add.dart';
import '../task/task_detail.dart';

const double kHourLabelWidth = 48;

class Timeline extends ConsumerStatefulWidget {
  const Timeline({super.key, required this.days});
  final List<DateTime> days;

  @override
  ConsumerState<Timeline> createState() => _TimelineState();
}

class _TimelineState extends ConsumerState<Timeline> {
  final _scroll = ScrollController();
  final _stackKey = GlobalKey();
  Timer? _ticker;
  final Map<int, Offset> _pointers = {};
  double? _pinchStartDistance;
  double? _pinchStartHeight;
  double? _pinchFocalMinutes;
  bool _scaling = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToNow() {
    if (!_scroll.hasClients) return;
    final hh = ref.read(hourHeightProvider);
    final now = ref.read(clockProvider).now();
    final containsToday = widget.days.any((d) => isSameDay(d, now));
    final minutes = containsToday ? minutesOfDay(now) : 8 * 60;
    final target = (minutes / 60 * hh - 120).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.jumpTo(target);
  }

  // ------------------------------------------------- pellizcar (RF-39)

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 2) {
      final pts = _pointers.values.toList();
      _pinchStartDistance = (pts[0].dy - pts[1].dy).abs().clamp(20.0, 2000.0);
      _pinchStartHeight = ref.read(hourHeightProvider);
      final focalY = (pts[0].dy + pts[1].dy) / 2 + (_scroll.hasClients ? _scroll.offset : 0);
      _pinchFocalMinutes = focalY / _pinchStartHeight! * 60;
      setState(() => _scaling = true);
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    if (_scaling && _pointers.length == 2 && _pinchStartDistance != null) {
      final pts = _pointers.values.toList();
      final dist = (pts[0].dy - pts[1].dy).abs().clamp(20.0, 2000.0);
      final ctrl = ref.read(hourHeightProvider.notifier);
      ctrl.set(_pinchStartHeight! * dist / _pinchStartDistance!);
      final hh = ref.read(hourHeightProvider);
      final focalScreenY = (pts[0].dy + pts[1].dy) / 2;
      if (_scroll.hasClients) {
        final target = _pinchFocalMinutes! / 60 * hh - focalScreenY;
        _scroll.jumpTo(target.clamp(0.0, 24 * hh));
      }
    }
  }

  void _onPointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_scaling && _pointers.length < 2) {
      ref.read(hourHeightProvider.notifier).persist();
      setState(() => _scaling = false);
    }
  }

  // --------------------------------------------- soltar desde la bandeja

  DateTime? _slotAt(Offset global, double colWidth) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);
    final hh = ref.read(hourHeightProvider);
    final col = (local.dx / colWidth).floor().clamp(0, widget.days.length - 1);
    final minutes = snapMinutes((local.dy / hh * 60).round()).clamp(0, 24 * 60 - 15);
    final d = widget.days[col];
    return DateTime(d.year, d.month, d.day, 0, minutes);
  }

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(snapshotProvider);
    final hh = ref.watch(hourHeightProvider);
    final now = ref.watch(clockProvider).now();
    final theme = Theme.of(context);
    final f = Fmt.of(context);
    final days = widget.days;
    final perDay = [for (final d in days) snap.calendarOccurrencesOnDay(d)];

    return Column(
      children: [
        _AllDayStrip(days: days, perDay: perDay),
        const Divider(height: 1),
        Expanded(
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerUp,
            child: SingleChildScrollView(
              controller: _scroll,
              physics: _scaling ? const NeverScrollableScrollPhysics() : null,
              child: SizedBox(
                height: 24 * hh,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: kHourLabelWidth,
                      child: Stack(
                        children: [
                          for (var h = 1; h < 24; h++)
                            Positioned(
                              top: h * hh - 7,
                              right: 6,
                              child: Text(
                                f.time(DateTime(2000, 1, 1, h)),
                                style: theme.textTheme.labelSmall!.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(builder: (context, c) {
                        final colWidth = c.maxWidth / days.length;
                        return DragTarget<Task>(
                          onAcceptWithDetails: (details) async {
                            final slot = _slotAt(details.offset + const Offset(8, 8), colWidth);
                            if (slot == null) return;
                            final t = details.data;
                            final o = Occurrence(task: t, series: t, occurrenceDate: null, completed: false);
                            final ui = Ui.of(context);
                            final msg = ui.overlap(slot,
                                    slot.add(Duration(minutes: t.durationMin ?? 60)),
                                    excludeKey: o.key) ??
                                ui.l.taskMoved;
                            ui.haptic(HapticKind.medium);
                            final point = await ui.service.move(o, slot,
                                durationMin: t.durationMin ?? 60);
                            ui.undo(point, msg);
                          },
                          builder: (context, candidates, _) => Stack(
                            key: _stackKey,
                            clipBehavior: Clip.none,
                            children: [
                              // Fondo: líneas de hora y huecos pulsables (RF-36).
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onLongPressStart: (d) {
                                    final slot = _slotAt(d.globalPosition, colWidth);
                                    if (slot == null) return;
                                    haptic(ref, HapticKind.medium);
                                    showQuickAdd(context, start: slot);
                                  },
                                  child: CustomPaint(
                                    painter: _GridPainter(
                                      hourHeight: hh,
                                      columns: days.length,
                                      color: theme.colorScheme.outlineVariant,
                                      highlight: candidates.isNotEmpty
                                          ? theme.colorScheme.primaryContainer
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              for (var i = 0; i < days.length; i++)
                                for (final b in layoutDay(perDay[i]))
                                  _positioned(b, i, colWidth, hh),
                              // Línea de «ahora».
                              for (var i = 0; i < days.length; i++)
                                if (isSameDay(days[i], now))
                                  Positioned(
                                    top: minutesOfDay(now) / 60 * hh - 1,
                                    left: i * colWidth,
                                    width: colWidth,
                                    child: IgnorePointer(
                                      child: Row(children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                              color: theme.colorScheme.error,
                                              shape: BoxShape.circle),
                                        ),
                                        Expanded(
                                            child: Container(
                                                height: 2, color: theme.colorScheme.error)),
                                      ]),
                                    ),
                                  ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _positioned(LaidOutBlock b, int dayIndex, double colWidth, double hh) {
    final o = b.occurrence;
    final start = o.start!;
    var minutes = o.task.effectiveDurationMin;
    // Bloques que pasan de medianoche se cortan al final del día.
    final startMin = minutesOfDay(start);
    if (startMin + minutes > 24 * 60) minutes = 24 * 60 - startMin;
    final top = startMin / 60 * hh;
    final height = (minutes / 60 * hh).clamp(18.0, 24 * hh);
    final w = colWidth / b.columns;
    return Positioned(
      key: ValueKey(o.key),
      top: top,
      left: dayIndex * colWidth + b.column * w,
      width: w,
      height: height,
      child: TimelineBlock(
        occurrence: o,
        hourHeight: hh,
        colWidth: colWidth,
        dayIndex: dayIndex,
        days: widget.days,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.hourHeight, required this.columns, required this.color, this.highlight});
  final double hourHeight;
  final int columns;
  final Color color;
  final Color? highlight;

  @override
  void paint(Canvas canvas, Size size) {
    if (highlight != null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = highlight!.withValues(alpha: 0.25));
    }
    final p = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    for (var h = 0; h <= 24; h++) {
      final y = h * hourHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final half = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 0.5;
    if (hourHeight >= 48) {
      for (var h = 0; h < 24; h++) {
        final y = h * hourHeight + hourHeight / 2;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), half);
      }
    }
    for (var c = 0; c <= columns; c++) {
      final x = c * size.width / columns;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.hourHeight != hourHeight || old.columns != columns || old.color != color || old.highlight != highlight;
}

/// Bloque de tarea en la línea de tiempo.
class TimelineBlock extends ConsumerStatefulWidget {
  const TimelineBlock({
    super.key,
    required this.occurrence,
    required this.hourHeight,
    required this.colWidth,
    required this.dayIndex,
    required this.days,
  });
  final Occurrence occurrence;
  final double hourHeight;
  final double colWidth;
  final int dayIndex;
  final List<DateTime> days;

  @override
  ConsumerState<TimelineBlock> createState() => _TimelineBlockState();
}

class _TimelineBlockState extends ConsumerState<TimelineBlock> {
  Offset _drag = Offset.zero;
  bool _dragging = false;
  double _resize = 0;
  bool _resizing = false;

  int get _deltaMinutes => snapMinutes((_drag.dy / widget.hourHeight * 60).round());
  int get _deltaDays => widget.days.length == 1
      ? 0
      : (_drag.dx / widget.colWidth).round().clamp(-widget.dayIndex, widget.days.length - 1 - widget.dayIndex);

  int get _newDuration => (snapMinutes(
              ((widget.occurrence.task.effectiveDurationMin) + _resize / widget.hourHeight * 60).round()))
      .clamp(15, 24 * 60);

  Future<void> _commitMove() async {
    final o = widget.occurrence;
    final dm = _deltaMinutes;
    final dd = _deltaDays;
    setState(() {
      _dragging = false;
      _drag = Offset.zero;
    });
    if (dm == 0 && dd == 0) return;
    final s = o.start!;
    final newStart = DateTime(s.year, s.month, s.day + dd, s.hour, s.minute + dm);
    final ui = Ui.of(context);
    final msg = ui.overlap(newStart, newStart.add(Duration(minutes: o.task.effectiveDurationMin)),
            excludeKey: o.key) ??
        ui.l.taskMoved;
    final point = await ui.service.move(o, newStart);
    ui.undo(point, msg);
  }

  Future<void> _commitResize() async {
    final o = widget.occurrence;
    final d = _newDuration;
    setState(() {
      _resizing = false;
      _resize = 0;
    });
    if (d == o.task.effectiveDurationMin) return;
    final ui = Ui.of(context);
    final msg = ui.overlap(o.start!, o.start!.add(Duration(minutes: d)), excludeKey: o.key) ??
        ui.l.taskMoved;
    ui.haptic(HapticKind.light);
    final point = await ui.service.move(o, o.start!, durationMin: d);
    ui.undo(point, msg);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.occurrence;
    final t = o.task;
    final theme = Theme.of(context);
    final f = Fmt.of(context);
    final color = categoryColorOf(ref, t.categoryId, context);
    final selection = ref.watch(selectionProvider);
    final selected = selection.contains(o);
    final selecting = selection.isNotEmpty;
    final hh = widget.hourHeight;
    final baseHeight = t.effectiveDurationMin / 60 * hh;

    final previewStart = _dragging
        ? DateTime(t.start!.year, t.start!.month, t.start!.day + _deltaDays, t.start!.hour,
            t.start!.minute + _deltaMinutes)
        : t.start!;
    final duration = _resizing ? _newDuration : t.effectiveDurationMin;
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    Widget block = Container(
      margin: const EdgeInsets.fromLTRB(1, 1, 2, 1),
      decoration: BoxDecoration(
        color: o.completed ? color.withValues(alpha: 0.35) : color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        border: selected
            ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
            : Border(left: BorderSide(color: priorityColor(t.priority), width: 3)),
        boxShadow: _dragging || _resizing
            ? [const BoxShadow(blurRadius: 8, color: Colors.black26)]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: LayoutBuilder(builder: (context, c) {
        final compact = c.maxHeight < 34;
        final narrow = c.maxWidth < 56;
        // Líneas de título que caben, dejando sitio a la hora si procede.
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final lineH = 17.0 * scale;
        final showTime = !compact && !narrow && c.maxHeight > 44 * scale;
        final titleLines =
            ((c.maxHeight - (showTime ? lineH : 0)) / lineH).floor().clamp(1, 6);
        final title = Text(
          t.title,
          maxLines: titleLines,
          overflow: narrow ? TextOverflow.clip : TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium!.copyWith(
            color: onColor,
            fontWeight: FontWeight.w600,
            decoration: o.completed ? TextDecoration.lineThrough : null,
          ),
        );
        return ClipRect(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (showTime)
                    Text(
                      '${f.time(previewStart)}–${f.time(previewStart.add(Duration(minutes: duration)))}',
                      style: theme.textTheme.labelSmall!.copyWith(color: onColor.withValues(alpha: 0.85)),
                      maxLines: 1,
                    ),
                ],
              ),
            ),
            if (c.maxWidth > 40)
              CompleteCheck(
                completed: o.completed,
                color: onColor,
                size: compact ? 14 : 18,
                animate: ref.watch(settingsProvider).animations,
                onTap: () => toggleComplete(context, o),
              ),
          ],
          ),
        );
      }),
    );

    block = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          bottom: _resizing ? -_resize : 0,
          child: block,
        ),
        // Asa para estirar la duración (RF-34).
        if (!t.allDay && !selecting)
          Positioned(
            left: 0,
            right: 0,
            bottom: _resizing ? -_resize - 6 : -6,
            height: 16,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragStart: (_) {
                haptic(ref, HapticKind.selection);
                setState(() => _resizing = true);
              },
              onVerticalDragUpdate: (d) => setState(() {
                final minH = -baseHeight + hh / 4;
                _resize = (_resize + d.delta.dy).clamp(minH, 24 * hh);
              }),
              onVerticalDragEnd: (_) => _commitResize(),
              onVerticalDragCancel: () => setState(() {
                _resizing = false;
                _resize = 0;
              }),
              child: Center(
                child: Container(
                  width: 24,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return Transform.translate(
      offset: _dragging
          ? Offset(_deltaDays * widget.colWidth, _deltaMinutes / 60 * hh)
          : Offset.zero,
      child: Semantics(
        button: true,
        label: '${t.title}, ${f.time(t.start!)}',
        child: GestureDetector(
          onTap: () {
            if (selecting) {
              haptic(ref, HapticKind.selection);
              ref.read(selectionProvider.notifier).toggle(o);
            } else {
              showTaskDetail(context, o);
            }
          },
          // Mantener pulsado: si se mueve, arrastra (RF-34/35); si se suelta
          // sin mover, activa la selección múltiple (RF-33).
          onLongPressStart: (_) {
            haptic(ref, HapticKind.medium);
            setState(() {
              _drag = Offset.zero;
              _dragging = false;
            });
          },
          onLongPressMoveUpdate: (d) {
            if (selecting) return;
            final moved = d.offsetFromOrigin;
            if (!_dragging && moved.distance > 6) {
              setState(() => _dragging = true);
            }
            if (_dragging) {
              final prevMin = _deltaMinutes, prevDay = _deltaDays;
              setState(() => _drag = moved);
              if (prevMin != _deltaMinutes || prevDay != _deltaDays) {
                haptic(ref, HapticKind.selection);
              }
            }
          },
          onLongPressEnd: (_) {
            if (_dragging) {
              haptic(ref, HapticKind.light);
              _commitMove();
            } else {
              ref.read(selectionProvider.notifier).toggle(o);
            }
          },
          child: Opacity(opacity: _dragging ? 0.85 : 1, child: block),
        ),
      ),
    );
  }
}

/// Franja superior con tareas de todo el día (RF-03).
class _AllDayStrip extends ConsumerWidget {
  const _AllDayStrip({required this.days, required this.perDay});
  final List<DateTime> days;
  final List<List<Occurrence>> perDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAny = perDay.any((l) => l.any((o) => o.task.allDay));
    if (!hasAny) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 96),
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: kHourLabelWidth,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.wb_sunny_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Column(
                  children: [
                    for (final o in perDay[i].where((o) => o.task.allDay))
                      _AllDayChip(occurrence: o),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AllDayChip extends ConsumerWidget {
  const _AllDayChip({required this.occurrence});
  final Occurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = occurrence;
    final color = categoryColorOf(ref, o.task.categoryId, context);
    final selected = ref.watch(selectionProvider).contains(o);
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return GestureDetector(
      onTap: () => ref.read(selectionProvider).isNotEmpty
          ? ref.read(selectionProvider.notifier).toggle(o)
          : showTaskDetail(context, o),
      onLongPress: () {
        haptic(ref, HapticKind.medium);
        ref.read(selectionProvider.notifier).toggle(o);
      },
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withValues(alpha: o.completed ? 0.35 : 0.9),
          borderRadius: BorderRadius.circular(4),
          border: selected ? Border.all(width: 2) : null,
        ),
        child: Text(
          o.task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: onColor,
                decoration: o.completed ? TextDecoration.lineThrough : null,
              ),
        ),
      ),
    );
  }
}

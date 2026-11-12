// C：la aldea. Cada proyecto es un edificio que crece con su avance (una
// fase por cada 10 %). Los archivados viven en el barrio histórico, al otro
// lado del río. El habitante pasea por las calles. Tocar un edificio abre su
// proyecto.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/entities.dart';
import '../../domain/village/building.dart';
import '../../domain/village/layout.dart';
import '../../domain/villager/villager_mood.dart';
import '../common/format.dart';
import '../providers.dart';
import '../screens/projects_screen.dart';
import '../village/villager_controller.dart';
import '../village/villager_sprite.dart';
import 'building_painter.dart';
import 'building_widgets.dart';
import 'iso.dart';
import 'villager_painter.dart';
import '../common/ph_icons.dart';

/// Lo que hace falta para pintar un solar.
class VillageLot {
  const VillageLot({required this.lot, required this.project, required this.type, required this.stage});
  final Lot lot;
  final Project project;
  final BuildingType type;
  final int stage;
}

List<VillageLot> villageLots(List<Project> projects, (int, int) Function(int id) progress, VillageLayout layout) {
  final byId = {for (final p in projects) p.id!: p};
  return [
    for (final l in layout.lots)
      if (byId[l.projectId] case final p?)
        VillageLot(
          lot: l,
          project: p,
          type: BuildingType.parse(p.building, projectId: p.id),
          stage: buildingStage(progress(p.id!).$1, progress(p.id!).$2),
        ),
  ];
}

class VillageScreen extends ConsumerStatefulWidget {
  const VillageScreen({super.key});

  @override
  ConsumerState<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends ConsumerState<VillageScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 40));
  final _view = TransformationController();
  Size? _fittedFor;

  @override
  void dispose() {
    _t.dispose();
    _view.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final animate = settings.animations && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_t.isAnimating) _t.repeat();
    if (!animate && _t.isAnimating) _t.stop();

    final snap = ref.watch(snapshotProvider);
    final projects = [...snap.projects]..sort((a, b) => a.id!.compareTo(b.id!));
    final layout = VillageLayout.of(
      [for (final p in projects.where((p) => !p.archived)) p.id!],
      [for (final p in projects.where((p) => p.archived)) p.id!],
    );
    final lots = villageLots(projects, snap.projectProgress, layout);
    final v = ref.watch(villagerProvider);
    final villager = settings.villagerEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.villageTitle),
        actions: [
          IconButton(
            tooltip: l.newProject,
            icon: const Icon(PhosphorIconsRegular.plusCircle),
            onPressed: () => editProject(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFCFE8FF), Color(0xFFEAF6E4)],
                ),
              ),
              child: lots.isEmpty ? _empty(context) : _map(lots, layout, v, villager, animate),
            ),
          ),
          if (villager) _VillagerPanel(view: v),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const BuildingThumb(type: BuildingType.house, stage: 0, color: kVillagerBlue, size: 120),
            const SizedBox(height: 16),
            Text(context.l10n.villageEmpty, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(context.l10n.villageHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(PhosphorIconsRegular.plus),
              label: Text(context.l10n.newProject),
              onPressed: () => editProject(context, ref),
            ),
          ]),
        ),
      );

  Widget _map(List<VillageLot> lots, VillageLayout layout, VillagerView v, bool villager, bool animate) {
    final geo = VillageGeometry(layout);
    return LayoutBuilder(builder: (context, box) {
      final viewport = box.biggest;
      if (_fittedFor != viewport) {
        _fittedFor = viewport;
        final s = min(1.0, min(viewport.width / geo.size.width, viewport.height / geo.size.height)).clamp(0.4, 1.0);
        final dx = (viewport.width - geo.size.width * s) / 2, dy = max(0.0, (viewport.height - geo.size.height * s) / 2);
        _view.value = Matrix4.identity()
          ..translateByDouble(dx, dy, 0, 1)
          ..scaleByDouble(s, s, 1, 1);
      }
      return InteractiveViewer(
        transformationController: _view,
        constrained: false,
        minScale: 0.4,
        maxScale: 2.5,
        boundaryMargin: const EdgeInsets.all(240),
        child: GestureDetector(
          onTapUp: (d) {
            final hit = geo.hitTest(lots, d.localPosition);
            if (hit != null) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectScreen(projectId: hit.project.id!)));
            }
          },
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) => CustomPaint(
              size: geo.size,
              painter: VillagePainter(
                geo: geo,
                lots: lots,
                t: _t.value,
                labelStyle: Theme.of(context).textTheme.labelSmall!,
                historicLabel: context.l10n.villageHistoric,
                stageLabel: (n) => context.l10n.villageStage(n),
                villager: villager ? v : null,
                walking: animate,
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Medidas del lienzo de la aldea.
class VillageGeometry {
  VillageGeometry(this.layout, {this.u = 56}) {
    const pad = 24.0, sky = 2.2; // espacio para edificios altos y banderas
    final x0 = -0.5, y0 = -0.5, x1 = layout.width + 0.5, y1 = layout.depth + 0.5;
    final left = (x0 - y1) * u, right = (x1 - y0) * u;
    final top = (x0 + y0) * u / 2 - sky * u, bottom = (x1 + y1) * u / 2 + 0.3 * u;
    iso = Iso(Offset(-left + pad, -top + pad), u);
    size = Size(right - left + pad * 2, bottom - top + pad * 2 + 24);
  }

  final VillageLayout layout;
  final double u;
  late final Iso iso;
  late final Size size;

  /// Rectángulo de pantalla que ocupa un solar con su edificio.
  Rect lotRect(VillageLot v) {
    final x = v.lot.x, y = v.lot.y;
    final h = (v.stage == 0 ? 0.3 : buildingHeight(v.type) + 0.3) * u;
    return Rect.fromLTRB(iso.p(x, y + 1).dx, iso.p(x, y).dy - h, iso.p(x + 1, y).dx, iso.p(x + 1, y + 1).dy);
  }

  /// El solar tocado (el de más delante si se solapan).
  VillageLot? hitTest(List<VillageLot> lots, Offset point) {
    final front = [...lots]..sort((a, b) => (b.lot.x + b.lot.y).compareTo(a.lot.x + a.lot.y));
    for (final v in front) {
      if (lotRect(v).contains(point)) return v;
    }
    return null;
  }

  /// Paseo del habitante por la calle que rodea el barrio principal (p en 0–1).
  (double, double) walk(double p) {
    final w = layout.width + 0.24, d = layout.mainDepth + 0.24;
    final per = 2 * (w + d);
    var s = (p % 1) * per;
    const x0 = -0.12, y0 = -0.12;
    if (s < w) return (x0 + s, y0);
    s -= w;
    if (s < d) return (x0 + w, y0 + s);
    s -= d;
    if (s < w) return (x0 + w - s, y0 + d);
    s -= w;
    return (x0, y0 + d - s);
  }
}

class VillagePainter extends CustomPainter {
  VillagePainter({
    required this.geo,
    required this.lots,
    required this.t,
    required this.labelStyle,
    required this.historicLabel,
    required this.stageLabel,
    required this.villager,
    required this.walking,
  });

  final VillageGeometry geo;
  final List<VillageLot> lots;
  final double t;
  final TextStyle labelStyle;
  final String historicLabel;
  final String Function(int) stageLabel;
  final VillagerView? villager;
  final bool walking;

  @override
  void paint(Canvas c, Size size) {
    final iso = geo.iso, layout = geo.layout;
    final w = layout.width, d = layout.depth;

    // Terreno: tierra y césped.
    drawPrism(c, iso, -0.5, -0.5, -0.25, w + 1, d + 1, 0.25, const Color(0xFF9C7A54));
    c.drawPath(iso.floor(-0.5, -0.5, w + 1, d + 1), Paint()..color = const Color(0xFF9BD07F));

    // Calles del barrio principal.
    c.drawPath(iso.floor(-0.25, -0.25, w + 0.5, layout.mainDepth + 0.5), Paint()..color = const Color(0xFFE5DCC8));

    // Río y barrio histórico.
    final ht = layout.historicTop;
    if (ht != null) {
      final riverY = layout.mainDepth + 0.45;
      c.drawPath(iso.floor(-0.5, riverY, w + 1, 0.6), Paint()..color = const Color(0xFF7FC4E8));
      final shimmer = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 1.2;
      for (var i = 0; i < 4; i++) {
        final x = ((t * 3 + i / 4) % 1) * (w + 0.6) - 0.3;
        c.drawLine(iso.p(x, riverY + 0.3), iso.p(x + 0.2, riverY + 0.3), shimmer);
      }
      drawPrism(c, iso, w / 2 - 0.2, riverY - 0.05, 0, 0.4, 0.7, 0.05, const Color(0xFFB07A4A));
      c.drawPath(iso.floor(-0.25, ht - 0.25, w + 0.5, d - ht + 0.5), Paint()..color = const Color(0xFFD8CDB5));
      _label(c, iso.p(-0.35, ht - 0.25) + const Offset(0, -8), historicLabel, bold: true, align: -1);
    }

    // Edificios y habitante, de atrás hacia delante.
    final order = <(double, void Function())>[
      for (final v in lots)
        (v.lot.x + v.lot.y + 1, () => paintBuilding(c, iso, v.lot.x, v.lot.y, v.type, v.stage, Color(v.project.color), t: (t * 10) % 1)),
    ];
    final vv = villager;
    if (vv != null) {
      final moving = walking && vv.mood != VillagerMood.sleep && vv.reaction == null;
      // Quieto: en la calle de delante, a mitad.
      final (px, py) = moving ? geo.walk(t) : (layout.width / 2, layout.mainDepth + 0.12);
      order.add((px + py, () => paintVillager(c, iso.p(px, py), geo.u * 0.75, vv.mood,
          reaction: vv.reaction, t: (t * 20) % 1, walking: moving)));
    }
    order.sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, draw) in order) {
      draw();
    }

    // Rótulos encima de todo.
    for (final v in lots) {
      final pos = iso.p(v.lot.x + 1, v.lot.y + 1) + const Offset(0, 4);
      _label(c, pos, '${v.project.name} · ${stageLabel(v.stage)}', faded: v.lot.archived);
    }
  }

  void _label(Canvas c, Offset at, String text, {bool bold = false, bool faded = false, int align = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: labelStyle.copyWith(
          color: faded ? const Color(0xFF6B6B6B) : const Color(0xFF1B2559),
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: geo.u * 2.4);
    final dx = align < 0 ? at.dx : at.dx - tp.width / 2;
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(dx - 6, at.dy - 2, tp.width + 12, tp.height + 4), const Radius.circular(8));
    c.drawRRect(box, Paint()..color = Colors.white.withValues(alpha: 0.85));
    tp.paint(c, Offset(dx, at.dy));
  }

  @override
  bool shouldRepaint(VillagePainter old) => true;
}

/// Panel inferior: el habitante, su energía, las tareas de hoy y botones.
class _VillagerPanel extends ConsumerWidget {
  const _VillagerPanel({required this.view});
  final VillagerView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final snap = ref.watch(snapshotProvider);
    final today = snap.occurrencesOnDay(ref.watch(clockProvider).now());
    final done = today.where((o) => o.completed).length;
    final ctrl = ref.read(villagerProvider.notifier);
    final theme = Theme.of(context);
    return Material(
      elevation: 6,
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            const VillagerSprite(size: 72, bubble: false),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${l.villagerTitle} · ${villagerMoodLabel(context, view.mood)}', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: view.state.fullness / 100,
                    minHeight: 8,
                    color: kVillagerBlue,
                    backgroundColor: kVillagerBlue.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${l.villagerFullness(view.state.fullness.round())} · ${l.villagerTodayDone(done, today.length)}',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(PhosphorIconsRegular.handWaving, size: 18),
                    label: Text(l.villagerPetButton),
                    onPressed: ctrl.pet,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(PhosphorIconsRegular.handTap, size: 18),
                    label: Text(l.villagerPokeButton),
                    onPressed: ctrl.poke,
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

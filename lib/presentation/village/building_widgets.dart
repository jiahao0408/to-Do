// Aldea: nombres traducidos, miniatura de un edificio y selector de tipo.

import 'package:flutter/material.dart';

import '../../domain/village/building.dart';
import '../../l10n/app_localizations.dart';
import '../common/format.dart';
import 'building_painter.dart';
import 'iso.dart';
import '../common/ph_icons.dart';

String buildingName(AppLocalizations l, BuildingType t) => switch (t) {
      BuildingType.house => l.buildingHouse,
      BuildingType.cabin => l.buildingCabin,
      BuildingType.apartments => l.buildingApartments,
      BuildingType.school => l.buildingSchool,
      BuildingType.library => l.buildingLibrary,
      BuildingType.office => l.buildingOffice,
      BuildingType.workshop => l.buildingWorkshop,
      BuildingType.bridge => l.buildingBridge,
      BuildingType.waterTower => l.buildingWaterTower,
      BuildingType.powerPlant => l.buildingPowerPlant,
      BuildingType.station => l.buildingStation,
      BuildingType.park => l.buildingPark,
      BuildingType.farm => l.buildingFarm,
      BuildingType.lighthouse => l.buildingLighthouse,
      BuildingType.castle => l.buildingCastle,
    };

String buildingGroupName(AppLocalizations l, BuildingGroup g) => switch (g) {
      BuildingGroup.homes => l.buildingGroupHomes,
      BuildingGroup.work => l.buildingGroupWork,
      BuildingGroup.infrastructure => l.buildingGroupInfrastructure,
      BuildingGroup.leisure => l.buildingGroupLeisure,
    };

/// Miniatura cuadrada de un edificio en una fase.
class BuildingThumb extends StatelessWidget {
  const BuildingThumb({super.key, required this.type, this.stage = 10, required this.color, this.size = 56});
  final BuildingType type;
  final int stage;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _ThumbPainter(type, stage, color)),
      );
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.type, this.stage, this.color);
  final BuildingType type;
  final int stage;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final h = buildingHeight(type) + 0.35;
    // Ancho del rombo = 2u; alto total ≈ u (suelo) + h·u.
    final u = size.width / 2.1 < size.height / (1 + h) ? size.width / 2.1 : size.height / (1 + h);
    final iso = Iso(Offset(size.width / 2, size.height - u * 1.02), u);
    canvas.save();
    canvas.clipRect(Offset.zero & size); // el haz del faro no se sale
    paintBuilding(canvas, iso, 0, 0, type, stage, color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => old.type != type || old.stage != stage || old.color != color;
}

/// Hoja para elegir el edificio. Devuelve el nombre del tipo, '' para
/// «automático» o null si se cancela.
Future<String?> pickBuilding(BuildContext context, {required Color color, String? current}) {
  final l = context.l10n;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(l.building, style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(l.villageHint, style: Theme.of(ctx).textTheme.bodySmall),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(PhosphorIconsRegular.sparkle),
            title: Text(l.buildingAuto),
            selected: current == null || current.isEmpty,
            onTap: () => Navigator.pop(ctx, ''),
          ),
          for (final g in BuildingGroup.values) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(buildingGroupName(l, g), style: Theme.of(ctx).textTheme.titleSmall),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in BuildingType.values.where((b) => b.group == g))
                  _BuildingChoice(
                    type: b,
                    color: color,
                    selected: current == b.name,
                    onTap: () => Navigator.pop(ctx, b.name),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _BuildingChoice extends StatelessWidget {
  const _BuildingChoice({required this.type, required this.color, required this.selected, required this.onTap});
  final BuildingType type;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 92,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
        ),
        child: Column(children: [
          BuildingThumb(type: type, color: color, size: 64),
          const SizedBox(height: 4),
          Text(buildingName(context.l10n, type),
              maxLines: 2, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
        ]),
      ),
    );
  }
}

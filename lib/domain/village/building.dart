// Aldea: cada proyecto es un edificio que se construye por fases (una cada
// 10 % de avance: 0 = solar vacío … 10 = terminado y decorado).

enum BuildingGroup { homes, work, infrastructure, leisure }

enum BuildingType {
  house(BuildingGroup.homes),
  cabin(BuildingGroup.homes),
  apartments(BuildingGroup.homes),
  school(BuildingGroup.work),
  library(BuildingGroup.work),
  office(BuildingGroup.work),
  workshop(BuildingGroup.work),
  bridge(BuildingGroup.infrastructure),
  waterTower(BuildingGroup.infrastructure),
  powerPlant(BuildingGroup.infrastructure),
  station(BuildingGroup.infrastructure),
  park(BuildingGroup.leisure),
  farm(BuildingGroup.leisure),
  lighthouse(BuildingGroup.leisure),
  castle(BuildingGroup.leisure);

  const BuildingType(this.group);
  final BuildingGroup group;

  /// Lee el nombre guardado; si falta o no se reconoce, uno fijo según el id
  /// (así los proyectos antiguos tienen variedad sin tocar nada).
  static BuildingType parse(String? raw, {int? projectId}) {
    for (final b in values) {
      if (b.name == raw) return b;
    }
    return projectId == null ? house : values[projectId % values.length];
  }
}

/// Fase de obra 0–10: una por cada 10 % completo (hacia abajo).
/// Sin tareas = solar vacío.
int buildingStage(int done, int total) {
  if (total <= 0 || done <= 0) return 0;
  if (done >= total) return 10;
  return (done * 10 ~/ total).clamp(0, 9);
}

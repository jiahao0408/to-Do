// Aldea: tipos de edificio y fases de obra.
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/domain/village/building.dart';
import 'package:todo_calendar/domain/village/layout.dart';

void main() {
  group('buildingStage', () {
    test('sin tareas o sin nada hecho: solar vacío', () {
      expect(buildingStage(0, 0), 0);
      expect(buildingStage(0, 7), 0);
    });

    test('una fase por cada 10 %, hacia abajo', () {
      expect(buildingStage(1, 10), 1);
      expect(buildingStage(19, 100), 1);
      expect(buildingStage(20, 100), 2);
      expect(buildingStage(1, 3), 3);
      expect(buildingStage(2, 3), 6);
    });

    test('el 10 solo al terminarlo todo', () {
      expect(buildingStage(99, 100), 9);
      expect(buildingStage(5, 5), 10);
    });
  });

  group('BuildingType.parse', () {
    test('lee el nombre guardado', () {
      expect(BuildingType.parse('lighthouse'), BuildingType.lighthouse);
    });

    test('sin valor: fijo según el id del proyecto', () {
      expect(BuildingType.parse(null, projectId: 3), BuildingType.values[3]);
      expect(BuildingType.parse('???', projectId: 3), BuildingType.values[3]);
      expect(BuildingType.parse(null), BuildingType.house);
    });

    test('hay de los cuatro grupos', () {
      expect(BuildingType.values.map((b) => b.group).toSet(), BuildingGroup.values.toSet());
    });
  });

  group('VillageLayout', () {
    test('activos en filas de 3 con calle entre solares', () {
      final v = VillageLayout.of([1, 2, 3, 4], []);
      expect([for (final l in v.lots) (l.x, l.y)], [(0.0, 0.0), (1.5, 0.0), (3.0, 0.0), (0.0, 1.5)]);
      expect(v.width, 4.0);
      expect(v.mainDepth, 2.5);
      expect(v.historicTop, isNull);
    });

    test('archivados en el barrio histórico, al otro lado del río', () {
      final v = VillageLayout.of([1], [7, 8]);
      final hist = v.lots.where((l) => l.archived).toList();
      expect(hist.map((l) => l.projectId), [7, 8]);
      expect(v.historicTop, 2.5);
      expect(hist.first.y, 2.5);
      expect(hist.every((l) => l.y >= v.historicTop!), isTrue);
      expect(v.width, 2.5);
      expect(v.depth, 3.5);
    });

    test('se pinta de atrás hacia delante', () {
      final v = VillageLayout.of([1, 2, 3, 4, 5], [6]);
      final sums = v.paintOrder.map((l) => l.x + l.y).toList();
      expect(sums, [...sums]..sort());
    });

    test('vacía: un solo hueco', () {
      final v = VillageLayout.of([], []);
      expect(v.lots, isEmpty);
      expect(v.width, 1.0);
    });
  });
}

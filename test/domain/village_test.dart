// Aldea: tipos de edificio y fases de obra.
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/domain/village/building.dart';

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
}

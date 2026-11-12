// Aldea: dónde va cada solar. Los proyectos activos forman el barrio
// principal; los archivados, el barrio histórico, al otro lado del río.
// Coordenadas en baldosas; cada solar mide 1 × 1 y entre solares hay calle.

class Lot {
  const Lot({required this.projectId, required this.x, required this.y, required this.archived});
  final int projectId;
  final double x, y;
  final bool archived;
}

class VillageLayout {
  const VillageLayout._(this.lots, this.width, this.mainDepth, this.historicTop, this.depth);

  /// Paso entre solares: 1 de solar + 0,5 de calle.
  static const double step = 1.5;

  final List<Lot> lots;

  /// Ancho total en baldosas (eje x).
  final double width;

  /// Fondo del barrio principal (eje y).
  final double mainDepth;

  /// y donde empieza el barrio histórico (null si no hay archivados).
  final double? historicTop;

  /// Fondo total (eje y).
  final double depth;

  factory VillageLayout.of(List<int> active, List<int> archived, {int cols = 3}) {
    int rows(int n) => n == 0 ? 0 : (n + cols - 1) ~/ cols;
    final lots = <Lot>[
      for (var i = 0; i < active.length; i++)
        Lot(projectId: active[i], x: (i % cols) * step, y: (i ~/ cols) * step, archived: false),
    ];
    final mainDepth = active.isEmpty ? 1.0 : rows(active.length) * step - 0.5;
    double? historicTop;
    var depth = mainDepth;
    if (archived.isNotEmpty) {
      historicTop = mainDepth + 1.5; // calle + río
      for (var i = 0; i < archived.length; i++) {
        lots.add(Lot(projectId: archived[i], x: (i % cols) * step, y: historicTop + (i ~/ cols) * step, archived: true));
      }
      depth = historicTop + rows(archived.length) * step - 0.5;
    }
    final used = (active.length > archived.length ? active.length : archived.length).clamp(1, cols);
    return VillageLayout._(lots, used * step - 0.5, mainDepth, historicTop, depth);
  }

  /// Orden de pintado: de atrás (x + y pequeño) hacia delante.
  List<Lot> get paintOrder => [...lots]..sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
}

import 'package:drift_flutter/drift_flutter.dart';

import 'database.dart';

/// Abre la base de datos SQLite de la app (archivo `app.sqlite` en la
/// carpeta de documentos de la app).
AppDatabase openAppDatabase() => AppDatabase(driftDatabase(name: 'app'));

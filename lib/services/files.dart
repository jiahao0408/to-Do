import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Carpeta de adjuntos dentro del almacenamiento de la app (RF-08).
Future<Directory> attachmentsDirectory() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'attachments'));
  if (!dir.existsSync()) await dir.create(recursive: true);
  return dir;
}

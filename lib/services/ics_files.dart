// .ics en la app: conversión de zonas horarias, compartir el archivo
// exportado y recibir archivos .ics abiertos desde otras apps.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/ics/ics.dart';
import 'notification_service.dart';

/// Algunos nombres de zona de Windows/Outlook → IANA.
const _windowsZones = {
  'romance standard time': 'Europe/Madrid',
  'w. europe standard time': 'Europe/Berlin',
  'central europe standard time': 'Europe/Budapest',
  'gmt standard time': 'Europe/London',
  'greenwich standard time': 'Atlantic/Reykjavik',
  'eastern standard time': 'America/New_York',
  'central standard time': 'America/Chicago',
  'pacific standard time': 'America/Los_Angeles',
  'china standard time': 'Asia/Shanghai',
  'utc': 'UTC',
};

tz.Location? _lookup(String id) {
  var name = id.trim();
  // TZID de Mozilla/Thunderbird: «/mozilla.org/20070129_1/Europe/Madrid».
  final m = RegExp(r'([A-Za-z]+/[A-Za-z_\-+0-9]+(?:/[A-Za-z_\-]+)?)$').firstMatch(name);
  try {
    return tz.getLocation(name);
  } catch (_) {}
  if (m != null) {
    try {
      return tz.getLocation(m.group(1)!);
    } catch (_) {}
  }
  final win = _windowsZones[name.toLowerCase()];
  return win == null ? null : tz.getLocation(win);
}

/// Conversor de horas del .ics a hora de pared de la zona del dispositivo.
IcsTimeConverter deviceConverter(String deviceTz) {
  ensureTimeZones();
  final local = _lookup(deviceTz) ?? tz.UTC;
  return (wall, tzid, utc) {
    tz.TZDateTime? src;
    if (utc) {
      src = tz.TZDateTime.utc(wall.year, wall.month, wall.day, wall.hour, wall.minute, wall.second);
    } else if (tzid != null) {
      final loc = _lookup(tzid);
      if (loc != null) {
        src = tz.TZDateTime(loc, wall.year, wall.month, wall.day, wall.hour, wall.minute, wall.second);
      }
    }
    if (src == null) return wall; // hora «flotante»: se toma tal cual
    final t = tz.TZDateTime.from(src, local);
    return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
  };
}

/// Lee un .ics como texto (UTF-8, con BOM o no).
Future<String> readIcsFile(String path) async {
  final bytes = await File(path).readAsBytes();
  return utf8.decode(bytes, allowMalformed: true).replaceFirst('﻿', '');
}

/// Escribe el .ics exportado en la carpeta temporal y devuelve el archivo.
Future<File> writeIcsExport(String content) async {
  final dir = await getTemporaryDirectory();
  final stamp = DateTime.now().toIso8601String().substring(0, 10);
  final f = File(p.join(dir.path, 'to-do-$stamp.ics'));
  await f.writeAsString(content);
  return f;
}

/// Archivos .ics abiertos con la app desde otras apps («Abrir con…»).
class IcsIntents {
  IcsIntents._();
  static final instance = IcsIntents._();

  static const _channel = MethodChannel('todo/ics');
  final _controller = StreamController<String>.broadcast();
  String? _initial;
  bool _ready = false;

  /// Rutas de archivos .ics recibidos mientras la app está abierta.
  Stream<String> get files => _controller.stream;

  Future<void> init() async {
    if (_ready || !(Platform.isAndroid || Platform.isIOS)) return;
    _ready = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'icsFile' && call.arguments is String) {
        _controller.add(call.arguments as String);
      }
    });
    try {
      _initial = await _channel.invokeMethod<String>('initialIcsFile');
    } on PlatformException {
      _initial = null;
    } on MissingPluginException {
      _initial = null;
    }
  }

  /// Archivo con el que se abrió la app (solo se devuelve una vez).
  String? takeInitial() {
    final f = _initial;
    _initial = null;
    return f;
  }
}

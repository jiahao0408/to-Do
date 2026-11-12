// Ballenita：读取 assets/whale/manifest.json。清单缺失或损坏时返回空列表。

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/whale/whale_mood.dart';

export '../../domain/whale/whale_mood.dart' show WhaleMood, WhaleReaction;

class WhaleAssets {
  const WhaleAssets._(this._groups);

  /// Grupo del manifiesto → rutas completas (`assets/whale/...`).
  final Map<String, List<String>> _groups;

  static const empty = WhaleAssets._({});

  /// Para tests: grupos con rutas completas.
  @visibleForTesting
  factory WhaleAssets.fromGroups(Map<String, List<String>> groups) => WhaleAssets._(groups);
  static const manifestPath = 'assets/whale/manifest.json';

  static Future<WhaleAssets> load(AssetBundle bundle) async {
    try {
      final raw = jsonDecode(await bundle.loadString(manifestPath, cache: false));
      if (raw is! Map) return empty;
      return WhaleAssets._({
        for (final e in raw.entries)
          if (e.value is List)
            '${e.key}': [for (final p in e.value as List) if (p is String) 'assets/whale/$p'],
      });
    } catch (_) {
      return empty;
    }
  }

  List<String> forMood(WhaleMood m) => _groups[m.name] ?? const [];

  List<String> forReaction(WhaleReaction r) => _groups[r.name] ?? const [];
}

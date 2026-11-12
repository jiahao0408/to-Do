// Ballenita: sin imágenes empaquetadas, la carga devuelve listas vacías y no falla.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/presentation/whale/whale_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sin manifiesto en la app: listas vacías', () async {
    final a = await WhaleAssets.load(rootBundle);
    for (final m in WhaleMood.values) {
      expect(a.forMood(m), isEmpty, reason: '$m');
    }
  });

  test('清单是坏 JSON 时返回空列表、不抛异常', () async {
    final a = await WhaleAssets.load(_TextBundle('not json {'));
    expect(a.forMood(WhaleMood.normal), isEmpty);
    expect(a.forReaction(WhaleReaction.pet), isEmpty);
  });

  test('清单缺失时返回空列表', () async {
    final a = await WhaleAssets.load(_TextBundle(null));
    expect(a.forMood(WhaleMood.sleep), isEmpty);
  });
}

class _TextBundle extends CachingAssetBundle {
  _TextBundle(this.text);
  final String? text;

  @override
  Future<ByteData> load(String key) async {
    final t = text;
    if (t == null) throw Exception('missing $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(t)));
  }
}

// 鲸鱼娘素材：清单完整、文件存在、pubspec 已声明。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const groups = {'normal', 'celebrate', 'worried', 'sleep', 'pet', 'poked', 'eat', 'easter'};

  Map<String, dynamic> manifest() =>
      jsonDecode(File('assets/whale/manifest.json').readAsStringSync()) as Map<String, dynamic>;

  test('manifest 有八个分组，每组至少一张', () {
    final m = manifest();
    expect(m.keys.toSet(), groups);
    for (final g in groups) {
      expect((m[g] as List).isNotEmpty, isTrue, reason: g);
    }
  });

  test('manifest 里的每个文件都存在于 assets/whale/', () {
    final m = manifest();
    for (final g in groups) {
      for (final p in (m[g] as List).cast<String>()) {
        expect(File('assets/whale/$p').existsSync(), isTrue, reason: p);
      }
    }
  });

  test('pubspec 声明了 assets/whale/ 的五个子文件夹', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final d in ['normal', 'celebrate', 'worried', 'sleep', 'reactions']) {
      expect(pubspec, contains('assets/whale/$d/'), reason: d);
    }
    expect(pubspec, contains('assets/whale/manifest.json'));
  });

  test('有 LICENSE.md 并写明署名和协议', () {
    final text = File('assets/whale/LICENSE.md').readAsStringSync();
    for (final s in ['上善无形', 'ZipZipPipe', 'EDMOK/blue-fish-archive', 'CC BY-NC-SA 4.0']) {
      expect(text, contains(s));
    }
  });
}

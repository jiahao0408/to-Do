// Habitante：饱腹度、心情与台词（领域层）。
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:todo_calendar/domain/models/entities.dart';
import 'package:todo_calendar/domain/models/task.dart';
import 'package:todo_calendar/domain/snapshot.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:todo_calendar/domain/villager/villager_lines.dart';
import 'package:todo_calendar/domain/villager/villager_mood.dart';
import 'package:todo_calendar/l10n/app_localizations.dart';
import 'package:todo_calendar/presentation/common/format.dart';
import 'package:todo_calendar/presentation/village/villager_copy.dart';
import 'package:todo_calendar/domain/villager/villager_state.dart';

AppSnapshot snap({
  List<Task> tasks = const [],
  List<OccurrenceCompletion> completions = const [],
  Map<String, String> settings = const {},
}) =>
    AppSnapshot(
      tasks: tasks,
      subtasks: const [],
      categories: const [],
      reminders: const [],
      attachments: const [],
      exceptions: const [],
      completions: completions,
      timeEntries: const [],
      templates: const [],
      settings: settings,
    );

final t0 = DateTime(2026, 11, 12, 12);

Task task(int id, DateTime start, {bool done = false, String? rrule, int? cat}) => Task(
      id: id,
      title: 'T$id',
      start: start,
      rrule: rrule,
      categoryId: cat,
      status: done ? TaskStatus.completed : TaskStatus.pending,
      tz: 'UTC',
      createdAt: t0,
      updatedAt: t0,
    );

void main() {
  setUpAll(() => initializeDateFormatting());

  group('VillagerState', () {
    test('新养的从 70 开始', () {
      final s = VillagerState.initial(t0, 3);
      expect(s.fullness, 70);
      expect(s.baseline, 3);
      expect(s.updatedAt, t0);
    });

    test('24 小时后下降 50，48 小时后到 30，四天后是 0 而不是负数', () {
      final s = VillagerState(fullness: 80, updatedAt: t0, baseline: 0);
      expect(s.decayed(t0.add(const Duration(hours: 24))).fullness, closeTo(30, 1e-9));
      expect(VillagerState(fullness: 100, updatedAt: t0, baseline: 0)
          .decayed(t0.add(const Duration(hours: 48)))
          .fullness, closeTo(0, 1e-9));
      expect(VillagerState(fullness: 70, updatedAt: t0, baseline: 0)
          .decayed(t0.add(const Duration(hours: 12)))
          .fullness, closeTo(45, 1e-9));
      expect(s.decayed(t0.add(const Duration(days: 4))).fullness, 0);
      expect(s.decayed(t0.add(const Duration(hours: 24))).updatedAt, t0.add(const Duration(hours: 24)));
    });

    test('完成 2 件 +30；从 90 开始再完成 1 件，封顶 100', () {
      final s = VillagerState(fullness: 40, updatedAt: t0, baseline: 5).applyCompletions(7);
      expect(s.fullness, 70);
      expect(s.baseline, 7);
      expect(VillagerState(fullness: 90, updatedAt: t0, baseline: 0).applyCompletions(1).fullness, 100);
    });

    test('取消完成扣回，最低 0', () {
      expect(VillagerState(fullness: 70, updatedAt: t0, baseline: 5).applyCompletions(4).fullness, 55);
      expect(VillagerState(fullness: 10, updatedAt: t0, baseline: 5).applyCompletions(2).fullness, 0);
    });

    test('rebased 不改 fullness', () {
      final s = VillagerState(fullness: 42, updatedAt: t0, baseline: 5).rebased(100);
      expect(s.fullness, 42);
      expect(s.baseline, 100);
    });

    test('frozenAt 让下次 decayed 从冻结时刻开始算', () {
      final s = VillagerState(fullness: 60, updatedAt: t0, baseline: 0)
          .frozenAt(t0.add(const Duration(days: 7)));
      expect(s.fullness, 60);
      expect(s.decayed(t0.add(const Duration(days: 7))).fullness, 60);
    });

    test('hungry 低于 25', () {
      expect(VillagerState(fullness: 24.9, updatedAt: t0, baseline: 0).hungry, isTrue);
      expect(VillagerState(fullness: 25, updatedAt: t0, baseline: 0).hungry, isFalse);
    });

    test('fromSettings 往返；缺键时返回 null', () {
      final s = VillagerState(fullness: 33.5, updatedAt: t0, baseline: 9);
      final back = VillagerState.fromSettings(s.toSettings())!;
      expect(back.fullness, 33.5);
      expect(back.updatedAt, t0);
      expect(back.baseline, 9);
      expect(VillagerState.fromSettings(const {}), isNull);
      expect(VillagerState.fromSettings(const {'whale.fullness': 'x', 'whale.updatedAt': 'y', 'whale.completedBaseline': '1'}), isNull);
    });

    test('completedCount 同时数单次任务和重复任务的完成次数', () {
      final s = snap(
        tasks: [
          task(1, t0, done: true),
          task(2, t0),
          task(3, t0, rrule: 'FREQ=DAILY'),
        ],
        completions: [
          OccurrenceCompletion(seriesId: 3, occurrenceDate: DateTime(2026, 11, 12), completedAt: t0),
          OccurrenceCompletion(seriesId: 3, occurrenceDate: DateTime(2026, 11, 11), completedAt: t0),
        ],
      );
      expect(completedCount(s), 3);
    });
  });

  group('moodFor', () {
    VillagerMood at(int h, int m, {AppSnapshot? s, double fullness = 70}) =>
        moodFor(snap: s ?? snap(), now: DateTime(2026, 11, 12, h, m), fullness: fullness);

    test('心情边界：21:59 平常、22:00 睡觉、6:59 睡觉、7:00 平常', () {
      expect(at(21, 59), VillagerMood.normal);
      expect(at(22, 0), VillagerMood.sleep);
      expect(at(6, 59), VillagerMood.sleep);
      expect(at(7, 0), VillagerMood.normal);
    });

    test('庆祝需要今天至少 1 件且全部完成', () {
      expect(at(12, 0), VillagerMood.normal, reason: '今天 0 件');
      final allDone = snap(tasks: [task(1, DateTime(2026, 11, 12, 9), done: true)]);
      expect(at(12, 0, s: allDone), VillagerMood.celebrate);
      final notAll = snap(tasks: [task(1, DateTime(2026, 11, 12, 9), done: true), task(2, DateTime(2026, 11, 12, 15))]);
      expect(at(12, 0, s: notAll), VillagerMood.normal);
    });

    test('逾期或饱腹度 24 时是着急，饱腹度 25 不是', () {
      final overdue = snap(tasks: [task(1, DateTime(2026, 11, 10, 9))]);
      expect(at(12, 0, s: overdue), VillagerMood.worried);
      expect(at(12, 0, fullness: 24), VillagerMood.worried);
      expect(at(12, 0, fullness: 25), VillagerMood.normal);
    });

    test('睡觉优先于着急和庆祝', () {
      final overdue = snap(tasks: [task(1, DateTime(2026, 11, 10, 9))]);
      expect(at(23, 0, s: overdue, fullness: 5), VillagerMood.sleep);
    });

    test('隐藏的类别仍然参与判断', () {
      final s = snap(
        tasks: [task(1, DateTime(2026, 11, 10, 9), cat: 7)],
        settings: {AppSnapshot.hiddenCategoriesKey: '7'},
      );
      expect(at(12, 0, s: s), VillagerMood.worried);
    });
  });


  group('台词', () {
    test('pickLine 不连续重复', () {
      for (var seed = 0; seed <= 20; seed++) {
        expect(pickLine(['a', 'b'], Random(seed), last: 'a'), 'b');
      }
    });

    test('只有一句时可以重复', () {
      expect(pickLine(['a'], Random(1), last: 'a'), 'a');
    });

    test('kindForMood：着急 + 饿 + 无逾期 → hungry；着急 + 逾期 → worried', () {
      const hungry = VillagerContext(remainingToday: 0, overdue: 0, fullness: 10);
      const late = VillagerContext(remainingToday: 0, overdue: 2, fullness: 10);
      expect(kindForMood(VillagerMood.worried, hungry), VillagerLineKind.hungry);
      expect(kindForMood(VillagerMood.worried, late), VillagerLineKind.worried);
      expect(kindForMood(VillagerMood.sleep, hungry), VillagerLineKind.sleep);
      expect(kindForMood(VillagerMood.celebrate, hungry), VillagerLineKind.celebrate);
      expect(kindForMood(VillagerMood.normal, hungry), VillagerLineKind.normal);
    });

    test('villagerCandidates 在没有下一件任务时不含「下一件」', () {
      final l = lookupAppLocalizations(const Locale('zh'));
      final f = Fmt('zh');
      const noNext = VillagerContext(remainingToday: 3, overdue: 0, fullness: 70);
      final a = villagerCandidates(l, f, VillagerLineKind.normal, noNext);
      expect(a, isNotEmpty);
      expect(a.any((s) => s.contains('下一件')), isFalse);
      expect(a.any((s) => s.contains('3')), isTrue);
      final withNext = VillagerContext(
          remainingToday: 3, overdue: 0, fullness: 70, nextTitle: '英语课', nextStart: DateTime(2026, 11, 12, 19));
      final b = villagerCandidates(l, f, VillagerLineKind.normal, withNext);
      expect(b.any((s) => s.contains('英语课') && s.contains('19:00')), isTrue);
    });

    test('每种台词在三种语言里都非空', () {
      for (final code in ['es', 'en', 'zh']) {
        final l = lookupAppLocalizations(Locale(code));
        const c = VillagerContext(remainingToday: 0, overdue: 1, fullness: 10);
        for (final k in VillagerLineKind.values) {
          expect(villagerCandidates(l, Fmt(code), k, c), isNotEmpty, reason: '$code $k');
        }
      }
    });
  });
}

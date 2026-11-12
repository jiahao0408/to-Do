// Ballenita：控制器（喂食、撤销、恢复备份、总开关冻结、戳醒）。
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/application/task_service.dart';
import 'package:todo_calendar/data/backup_service.dart';
import 'package:todo_calendar/data/db/database.dart';
import 'package:todo_calendar/data/repository.dart';
import 'package:todo_calendar/domain/models/task.dart';
import 'package:todo_calendar/domain/settings.dart';
import 'package:todo_calendar/domain/time.dart';
import 'package:todo_calendar/domain/whale/whale_mood.dart';
import 'package:todo_calendar/presentation/providers.dart';
import 'package:todo_calendar/presentation/whale/whale_controller.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Repository repo;
  late TaskService service;
  late ProviderContainer c;
  late FixedClock clock;

  Future<void> settle() => Future.delayed(const Duration(milliseconds: 150));

  setUp(() async {
    clock = FixedClock(DateTime(2026, 11, 12, 12));
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: clock);
    service = TaskService(repo);
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock),
    ]);
    c.listen(whaleProvider, (_, _) {}, fireImmediately: true);
    await settle();
  });

  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Task task(String title) => Task(
        title: title,
        start: DateTime(2026, 11, 12, 15),
        tz: 'UTC',
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  Future<void> complete(int id, bool done) async {
    final o = (await repo.loadSnapshot()).occurrenceOf(id, null)!;
    await service.setCompleted(o, done);
    await settle();
  }

  test('新养的从 70 开始', () {
    expect(c.read(whaleProvider).state.fullness, 70);
  });

  test('完成一件任务后饱腹度 +15，reaction == eat', () async {
    final id = await service.create(task('a'));
    await settle();
    final tick = c.read(whaleProvider).reactionTick;
    await complete(id, true);
    final v = c.read(whaleProvider);
    expect(v.state.fullness, 85);
    expect(v.reaction, WhaleReaction.eat);
    expect(v.reactionTick, greaterThan(tick));
  });

  test('撤销后饱腹度回到原值', () async {
    final id = await service.create(task('a'));
    await settle();
    await complete(id, true);
    await complete(id, false);
    expect(c.read(whaleProvider).state.fullness, 70);
  });

  test('恢复备份后不跳变', () async {
    final tmp = await Directory.systemTemp.createTemp('whale');
    final db2 = AppDatabase(NativeDatabase.memory());
    final r2 = Repository(db2, clock: clock);
    final s2 = TaskService(r2);
    for (var i = 0; i < 10; i++) {
      final id = await s2.create(task('b$i'));
      await s2.setCompleted((await r2.loadSnapshot()).occurrenceOf(id, null)!, true);
    }
    final zip = await BackupService(db2, attachmentsDir: tmp).exportZip(tmp);
    await BackupService(db, attachmentsDir: tmp).importFile(zip);
    await settle();
    await settle();
    expect(c.read(whaleProvider).state.fullness, 70);
    expect((await repo.getSetting(AppSettings.kWhaleRebase)) == '1', isFalse, reason: 'el aviso se consume');
    await db2.close();
    await tmp.delete(recursive: true);
  });

  test('关闭总开关 7 天后再打开，饱腹度不变', () async {
    await repo.setSetting(AppSettings.kWhaleEnabled, '0');
    await settle();
    expect(c.read(whaleProvider).enabled, isFalse);
    clock.value = clock.value.add(const Duration(days: 7));
    c.read(whaleProvider.notifier).refresh();
    await repo.setSetting(AppSettings.kWhaleEnabled, '1');
    await settle();
    expect(c.read(whaleProvider).state.fullness, closeTo(70, 0.01));
  });

  test('开着时一天后饿了 50', () async {
    clock.value = clock.value.add(const Duration(hours: 24));
    c.read(whaleProvider.notifier).refresh();
    expect(c.read(whaleProvider).state.fullness, closeTo(20, 0.01));
    expect(c.read(whaleProvider).mood, WhaleMood.worried);
  });

  test('22:30 poke 时 reaction == poked；12:00 poke 时 reaction == null', () async {
    c.read(whaleProvider.notifier).poke();
    expect(c.read(whaleProvider).reaction, isNull);
    clock.value = DateTime(2026, 11, 12, 22, 30);
    c.read(whaleProvider.notifier).refresh();
    c.read(whaleProvider.notifier).poke();
    expect(c.read(whaleProvider).reaction, WhaleReaction.poked);
  });

  test('pet / easter / clearReaction', () {
    final n = c.read(whaleProvider.notifier);
    n.pet();
    expect(c.read(whaleProvider).reaction, WhaleReaction.pet);
    n.easter();
    expect(c.read(whaleProvider).reaction, WhaleReaction.easter);
    n.clearReaction();
    expect(c.read(whaleProvider).reaction, isNull);
  });

  test('上下文：今天剩几件和下一件', () async {
    await service.create(task('Inglés'));
    await settle();
    final ctx = c.read(whaleProvider).context;
    expect(ctx.remainingToday, 1);
    expect(ctx.nextTitle, 'Inglés');
    expect(ctx.nextStart, DateTime(2026, 11, 12, 15));
  });

  test('guardar no crea un bucle: sin cambios, no hay escrituras nuevas', () async {
    await Future.delayed(const Duration(milliseconds: 2500)); // primer guardado
    var emissions = 0;
    final sub = db.tableUpdates().listen((_) => emissions++);
    await Future.delayed(const Duration(milliseconds: 5000));
    await sub.cancel();
    expect(emissions, 0);
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('al completar una tarea, la nueva base se guarda', () async {
    final id = await service.create(task('a'));
    await settle();
    await complete(id, true);
    await Future.delayed(const Duration(milliseconds: 2500));
    expect(await repo.getSetting('whale.completedBaseline'), '1');
    expect(double.parse((await repo.getSetting('whale.fullness'))!), 85);
  }, timeout: const Timeout(Duration(seconds: 20)));
}

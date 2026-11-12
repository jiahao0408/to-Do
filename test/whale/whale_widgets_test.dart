// 鲸鱼娘：组件测试（WhaleSprite；Task 6 再追加三个位置）。
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:todo_calendar/domain/settings.dart';
import 'package:todo_calendar/domain/whale/whale_lines.dart';
import 'package:todo_calendar/domain/whale/whale_mood.dart';
import 'package:todo_calendar/domain/whale/whale_state.dart';
import 'package:todo_calendar/l10n/app_localizations.dart';
import 'package:todo_calendar/presentation/providers.dart';
import 'package:todo_calendar/presentation/whale/whale_assets.dart';
import 'package:todo_calendar/presentation/whale/whale_controller.dart';
import 'package:todo_calendar/presentation/whale/whale_sprite.dart';

class FakeWhale extends WhaleController {
  FakeWhale(this.initial);
  final WhaleView initial;
  final calls = <String>[];

  @override
  WhaleView build() => initial;
  @override
  void pet() {
    calls.add('pet');
    super.pet();
  }

  @override
  void poke() {
    calls.add('poke');
    super.poke();
  }

  @override
  void easter() {
    calls.add('easter');
    super.easter();
  }

  @override
  void clearReaction() {
    calls.add('clear');
    super.clearReaction();
  }
}

WhaleView view({WhaleMood mood = WhaleMood.normal, double fullness = 70}) => WhaleView(
      state: WhaleState(fullness: fullness, updatedAt: DateTime(2026, 11, 12), baseline: 0),
      mood: mood,
      context: WhaleContext(remainingToday: 2, overdue: 0, fullness: fullness),
      enabled: true,
    );

final testAssets = WhaleAssets.fromGroups({
  for (final g in ['normal', 'celebrate', 'worried', 'sleep', 'pet', 'poked', 'eat', 'easter'])
    g: ['assets/whale/test-$g.webp'],
});

Widget host(FakeWhale fake, {bool animations = true, Widget? child}) => ProviderScope(
      overrides: [
        whaleProvider.overrideWith(() => fake),
        whaleAssetsProvider.overrideWith((ref) async => testAssets),
        settingsProvider.overrideWithValue(AppSettings({
          AppSettings.kAnimations: animations ? '1' : '0',
          AppSettings.kHaptics: '0',
        })),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: Center(child: child ?? const WhaleSprite(size: 120))),
      ),
    );

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('轻点后出现气泡文字，3 秒后消失', (tester) async {
    final fake = FakeWhale(view());
    await tester.pumpWidget(host(fake, animations: false));
    await tester.pump();
    await tester.tap(find.byType(WhaleSprite));
    await tester.pump();
    expect(fake.calls, contains('poke'));
    expect(find.byKey(const ValueKey('whale-bubble')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('whale-bubble')), findsNothing);
  });

  testWidgets('长按调用 pet', (tester) async {
    final fake = FakeWhale(view());
    await tester.pumpWidget(host(fake, animations: false));
    await tester.pump();
    await tester.longPress(find.byType(WhaleSprite));
    await tester.pump();
    expect(fake.calls, contains('pet'));
    await tester.pump(const Duration(seconds: 3));
    expect(fake.calls, contains('clear'), reason: 'la reacción dura unos 2 s');
  });

  testWidgets('3 秒内连续点 5 下调用 easter', (tester) async {
    final fake = FakeWhale(view());
    await tester.pumpWidget(host(fake, animations: false));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byType(WhaleSprite));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(fake.calls.where((c) => c == 'easter').length, 1);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('关闭动画时，漂浮的 AnimationController 不会运行', (tester) async {
    await tester.pumpWidget(host(FakeWhale(view()), animations: false));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('打开动画时会持续漂浮', (tester) async {
    await tester.pumpWidget(host(FakeWhale(view()), animations: true));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('语义标签包含饱腹度', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(FakeWhale(view(fullness: 42.4)), animations: false));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('鲸鱼娘.*饱腹度 42%')), findsOneWidget);
    handle.dispose();
  });
}

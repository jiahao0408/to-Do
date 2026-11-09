# 鲸鱼娘陪伴 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 to Do 里加入一只离线的鲸鱼娘陪伴：心情跟着任务走，可以点、摸，完成任务就是喂它，出现在日历角落、侧边菜单小鱼缸和单独的鱼缸页面，全部可在设置里关闭。

**Architecture:**
- 纯 Dart 领域层（`lib/domain/whale/`）：心情、饱腹度、台词选择，可单元测试。
- Riverpod 控制器（`whaleProvider`）：读快照和设置，算出 `WhaleView`，把状态写回 settings 表。
- 展示层（`lib/presentation/whale/`）：一个 `WhaleSprite`，用在 A / B / C 三处。
- 素材：从 EDMOK/blue-fish-archive 下载，用 Pillow 处理后放进 `assets/whale/`，配一份清单 JSON。

**Tech Stack:** Flutter 3.47 / Dart 3.13，flutter_riverpod 3.5，Drift（只用现有的 settings 表），Python 3 + Pillow 12（只在处理素材时用）。

**Spec:** `docs/superpowers/specs/2026-11-09-whale-companion-design.md`

## Global Constraints

- 离线：不联网、不接 AI、不发推送。
- 不改数据库结构：状态只存在 settings 表，键名为 `whale.fullness`、`whale.updatedAt`、`whale.completedBaseline`、`whale.pos`、`whale.enabled`、`whale.floating`、`whale.drawer`、`whale.tank`，另有一个仅供内部使用的 `whale.rebase`。
- 数值：新养的鲸鱼娘饱腹度 70；每 24 小时下降 50；每完成一件任务 +15；上下限 0–100；低于 25 算饿。
- 心情优先级：22:00–7:00 睡觉 → 今天至少 1 件且全部完成是庆祝 → 有逾期或饱腹度低于 25 是着急 → 其余平常。所有任务都参与，包括在日历里隐藏的类别。
- 署名：原设 上善无形，二设 ZipZipPipe，来源 EDMOK/blue-fish-archive，协议 CC BY-NC-SA 4.0。应用内两处显示（鱼缸页面底部、设置 › 关于形象），`assets/whale/LICENSE.md` 里也要写。
- 新文案三种语言（es 模板、en、zh），不能在代码里写死文字。用 `C:\Users\chenj\AppData\Local\Temp\claude\59c2970db4f669a7\107029cc-491a-42fe-8ab6-2cb8ef312a55\scratchpad\add_arb.py` 的写法往 ARB 里加键，然后运行 `flutter gen-l10n`。
- 运行 Flutter 前：`$env:PUB_CACHE='D:\pub-cache'`，用 `D:\flutter\bin\flutter.bat`（PowerShell）。
- 一切动画都受「应用设置 › 动画」（`settings.animations`）和系统的减少动态效果（`MediaQuery.disableAnimations`）控制。
- `flutter analyze` 零问题，`flutter test` 全绿。

## 与设计文档不同、请你确认的两点

1. **GIF 太大：** 3 张 GIF 超过 1 MB（电饭煲里 10.3 MB、电饭煲偷看 10.2 MB、你坑 4.8 MB，沙发转圈圈 1.25 MB 也略超）。计划默认把 GIF 缩到 256 px 并转成动态 WebP（预计每张 0.2–1 MB），其余做法照设计文档。
2. **背景不透明：** 很多 JPG 是白底，直接放在蓝色鱼缸里会是一块白方块。计划默认把每张图显示在圆角白卡片里（像贴纸），而不是去抠背景。
3. **彩蛋：** 设计文档没写彩蛋图什么时候出现。计划默认 3 秒内连续点 5 下显示彩蛋图。

如果这三点你要别的做法，告诉我，我改计划。

## Review Focus

1. **撤销、导入、恢复不能刷饱腹度：** 恢复备份或导入 .ics 后，「已完成总数」可能突然大涨或大跌，饱腹度不能因此跳变。由 Task 4 的 `rebase` 测试覆盖。
2. **关掉总开关后冻结：** 关掉一周再打开，饱腹度应和关掉时一样，而不是饿到 0。由 Task 2 的冻结测试和 Task 4 的控制器测试覆盖。
3. **时区和夜间边界：** 21:59 和 7:00 应是醒着，22:00 和 6:59 应在睡觉。由 Task 2 测试覆盖。
4. **漂浮的鲸鱼娘挡住操作：** 多选模式、收件箱面板、键盘弹出时都要隐藏；拖到底部导航栏或屏幕外时要夹回可见区域。由 Task 6 的布局测试覆盖。
5. **素材缺失或损坏：** 清单里的文件缺失时，应该跳过那张图，而不是让应用崩溃。由 Task 1 的清单测试和 Task 3 的 `WhaleAssets.load` 测试覆盖。

---

## 文件结构

- 新建 `tool/whale_assets.py`：下载并处理素材。只在开发时运行，不打包进应用。
- 新建 `assets/whale/{normal,celebrate,worried,sleep,reactions}/*.webp`、`assets/whale/manifest.json`、`assets/whale/LICENSE.md`
- 新建 `lib/domain/whale/whale_state.dart`：饱腹度 + 已完成总数
- 新建 `lib/domain/whale/whale_mood.dart`：心情判断
- 新建 `lib/domain/whale/whale_lines.dart`：台词种类、上下文、挑选
- 新建 `lib/presentation/whale/whale_assets.dart`：读清单
- 新建 `lib/presentation/whale/whale_controller.dart`：`whaleProvider`
- 新建 `lib/presentation/whale/whale_copy.dart`：从 ARB 生成候选台词
- 新建 `lib/presentation/whale/whale_sprite.dart`：图 + 漂浮 + 气泡 + 手势
- 新建 `lib/presentation/whale/whale_floating.dart`：A
- 新建 `lib/presentation/whale/whale_drawer_card.dart`：B
- 新建 `lib/presentation/whale/whale_tank_screen.dart`：C，含 `TankPainter`
- 修改 `lib/domain/settings.dart`：鲸鱼娘相关的键和 getter
- 修改 `lib/data/backup_service.dart`、`lib/application/ics_service.dart`：导入后设置 `whale.rebase=1`
- 修改 `lib/presentation/home/home_shell.dart`、`lib/presentation/home/app_drawer.dart`、`lib/presentation/screens/settings_screen.dart`
- 修改 `pubspec.yaml`：声明 assets
- 修改 `lib/l10n/app_{es,en,zh}.arb`
- 测试：`test/domain/whale_test.dart`、`test/whale/whale_assets_test.dart`、`test/whale/whale_controller_test.dart`、`test/whale/whale_widgets_test.dart`

---

### Task 1: 素材下载、处理和清单

**Files:**
- Create: `tool/whale_assets.py`、`assets/whale/**`、`assets/whale/manifest.json`、`assets/whale/LICENSE.md`
- Modify: `pubspec.yaml`（在 `flutter: assets:` 下列出 `assets/whale/` 及其五个子文件夹）
- Test: `test/whale/whale_assets_test.dart`

**Interfaces:**
- Produces：`assets/whale/manifest.json` 的格式为
  `{"normal":[...], "celebrate":[...], "worried":[...], "sleep":[...], "pet":[...], "poked":[...], "eat":[...], "easter":[...]}`。
  值是相对于 `assets/whale/` 的路径，例如 `"normal/deepseek-jushou-dazhaohu.webp"`。

- [ ] **Step 1：征得同意后再下载。** 先告诉你：34 个文件，原始大小合计 45 MB，来自 `https://raw.githubusercontent.com/EDMOK/blue-fish-archive/main/media/<文件名>`，先下载到 scratchpad 临时文件夹，处理后放进项目的大约 3–6 MB。等你说可以再继续。
- [ ] **Step 2：写 `tool/whale_assets.py`**
  - 用法：`python tool/whale_assets.py <下载目录> <输出目录 assets/whale>`。
  - 文件名和分组照设计文档第 1 节的表格（34 个；反应组分为 pet / poked / eat / easter）。
  - 静态图：居中裁成正方形，最多 512 px，存成质量 82 的 WebP。
  - GIF：逐帧缩到 256 px，保留每帧时长和循环，存成动态 WebP。
  - 最后写出 `manifest.json`，并打印每个输出文件的大小。
- [ ] **Step 3：运行脚本。** `curl` 下载到 scratchpad，再运行脚本输出到 `assets/whale/`。预期：打印 34 行，总大小不超过 6 MB，单个文件不超过 1.2 MB；超出的列出来。
- [ ] **Step 4：写 `assets/whale/LICENSE.md`。** 内容包括作者、来源链接、CC BY-NC-SA 4.0 协议链接、原始文件名和所做的修改（裁剪、缩放、转格式）。
- [ ] **Step 5：写失败的测试 `test/whale/whale_assets_test.dart`**
  - `manifest 有八个分组，每组至少一张`：读文件解析 JSON，断言键集合等于 `{normal, celebrate, worried, sleep, pet, poked, eat, easter}`，且每组非空。
  - `manifest 里的每个文件都存在于 assets/whale/`：对每个路径断言 `File('assets/whale/$p').existsSync()`。
  - `pubspec 声明了 assets/whale/ 的五个子文件夹`。
- [ ] **Step 6：运行测试。** `flutter test test/whale/whale_assets_test.dart`，预期 PASS。
- [ ] **Step 7：提交。** `git commit -m "鲸鱼娘：素材（CC BY-NC-SA 4.0，来自 EDMOK/blue-fish-archive）"`

### Task 2: 领域层，饱腹度与心情

**Files:**
- Create: `lib/domain/whale/whale_state.dart`、`lib/domain/whale/whale_mood.dart`
- Test: `test/domain/whale_test.dart`

**Interfaces:**
- Produces：
  - `class WhaleState { final double fullness; final DateTime updatedAt; final int baseline; }`
    - 常量：`kInitial = 70`、`kDecayPerDay = 50`、`kFeedPerTask = 15`、`kHungry = 25`
    - `factory WhaleState.initial(DateTime now, int completedNow)`
    - `WhaleState decayed(DateTime now)`：按经过的时间线性下降，夹在 0–100
    - `WhaleState applyCompletions(int completedNow)`：`fullness += (completedNow - baseline) * 15`，夹在 0–100，`baseline = completedNow`
    - `WhaleState rebased(int completedNow)`：只改 `baseline`
    - `WhaleState frozenAt(DateTime now)`：只改 `updatedAt`，用于总开关关闭期间
    - `bool get hungry`（`fullness < 25`）
    - `Map<String, String> toSettings()`
    - `static WhaleState? fromSettings(Map<String, String> raw)`：缺键或格式错误时返回 null
  - `int completedCount(AppSnapshot s)`：已完成的单次任务数 + 重复任务的完成次数
  - `enum WhaleMood { normal, celebrate, worried, sleep }`
  - `WhaleMood moodFor({required AppSnapshot snap, required DateTime now, required double fullness})`

- [ ] **Step 1：写失败的测试**
  - `新养的从 70 开始`
  - `24 小时后下降 50，48 小时后到 30，四天后是 0 而不是负数`
  - `完成 2 件 +30；从 90 开始再完成 1 件，封顶 100`
  - `取消完成扣回，最低 0`
  - `rebased 不改 fullness`
  - `frozenAt 让下次 decayed 从冻结时刻开始算`
  - `fromSettings 往返；缺键时返回 null`
  - `completedCount 同时数单次任务和重复任务的完成次数`
  - `心情边界`：21:59 平常、22:00 睡觉、6:59 睡觉、7:00 平常
  - `庆祝需要今天至少 1 件且全部完成`：今天 0 件时不是庆祝
  - `逾期或饱腹度 24 时是着急，饱腹度 25 不是`
  - `隐藏的类别仍然参与判断`：设置 `hiddenCategories` 后，结论不变
- [ ] **Step 2：运行测试。** `flutter test test/domain/whale_test.dart`，预期因为类型未定义而 FAIL。
- [ ] **Step 3：按上面的签名实现。** 逾期用 `snap.overdue(now)`；今天的任务用 `snap.occurrencesOnDay(now)`（不带日历过滤）。
- [ ] **Step 4：运行测试。** 预期 PASS。
- [ ] **Step 5：提交。** `git commit -m "鲸鱼娘：饱腹度与心情（领域层）"`

### Task 3: 台词与素材加载

**Files:**
- Create: `lib/domain/whale/whale_lines.dart`、`lib/presentation/whale/whale_copy.dart`、`lib/presentation/whale/whale_assets.dart`
- Modify: `lib/l10n/app_{es,en,zh}.arb`
- Test: `test/domain/whale_test.dart`（追加）、`test/whale/whale_assets_test.dart`（追加）

**Interfaces:**
- Consumes：Task 2 的 `WhaleMood`
- Produces：
  - `enum WhaleLineKind { normal, celebrate, worried, hungry, sleep, pet, poked, eat }`
  - `class WhaleContext { final int remainingToday; final String? nextTitle; final DateTime? nextStart; final int overdue; final double fullness; }`
  - `WhaleLineKind kindForMood(WhaleMood m, WhaleContext c)`：着急时，若 `fullness < 25` 且没有逾期，返回 `hungry`
  - `String pickLine(List<String> candidates, Random rnd, {String? last})`：候选多于 1 句时不返回 `last`
  - `List<String> whaleCandidates(AppLocalizations l, Fmt f, WhaleLineKind k, WhaleContext c)`（在 `whale_copy.dart`）：只收录上下文能填进去的句子，例如没有下一件任务时，不收「下一件：…」
  - `enum WhaleReaction { pet, poked, eat, easter }`
  - `class WhaleAssets { static Future<WhaleAssets> load(AssetBundle b); List<String> forMood(WhaleMood m); List<String> forReaction(WhaleReaction r); }`：返回完整资源路径 `assets/whale/...`；清单缺失或损坏时返回空列表，不抛异常
- ARB 键（es / en / zh 都要写，中文文案见设计文档第 3 节；每组 2–4 句）：
  - 台词：`whaleNormal1..4`（`whaleNormal1` 带 `{n}` 剩余件数，`whaleNormal2` 带 `{title}` 和 `{time}`）、`whaleCelebrate1..3`、`whaleWorried1..2`（`{n}` 逾期件数）、`whaleHungry1..2`、`whaleSleep1..2`、`whalePet1..3`、`whalePoked1..2`、`whaleEat1..3`
  - 界面：`whaleTitle`「鲸鱼娘」、`whaleFullness`「饱腹度 {p}%」、`whaleTodayDone`「今天完成 {done}/{total}」、`whaleMoodNormal/Celebrate/Worried/Sleep`、`whalePetButton`「摸摸头」、`whalePokeButton`「戳一下」
  - 设置：`whaleShow`「显示鲸鱼娘」、`whaleFloating`「日历角落」、`whaleDrawer`「菜单鱼缸」、`whaleTank`「鱼缸页面」、`whaleAbout`「关于形象」
  - 署名：`whaleCredits`，例如「原设 上善无形 · 二设 ZipZipPipe · 来源 EDMOK/blue-fish-archive · CC BY-NC-SA 4.0」
  - 无障碍：`whaleSemantics`「鲸鱼娘，{mood}，饱腹度 {p}%」

- [ ] **Step 1：写失败的测试**
  - `pickLine 不连续重复`：候选为 `['a', 'b']`、`last: 'a'` 时，种子 0..20 都返回 `'b'`
  - `只有一句时可以重复`
  - `kindForMood：着急 + 饿 + 无逾期 → hungry；着急 + 逾期 → worried`
  - `whaleCandidates 在没有下一件任务时不含「下一件」`：用 `lookupAppLocalizations(Locale('zh'))` 生成
  - `WhaleAssets.load` 用 `rootBundle`，断言每种心情至少 1 张
  - `WhaleAssets.load` 在清单是坏 JSON 时（假的 AssetBundle）返回空列表、不抛异常
- [ ] **Step 2：运行测试。** 预期 FAIL。
- [ ] **Step 3：加 ARB 键，运行 `flutter gen-l10n`，实现三个文件。**
- [ ] **Step 4：运行测试。** 预期 PASS。
- [ ] **Step 5：提交。** `git commit -m "鲸鱼娘：台词（es/en/zh）与素材清单加载"`

### Task 4: 控制器与设置键

**Files:**
- Create: `lib/presentation/whale/whale_controller.dart`
- Modify: `lib/domain/settings.dart`、`lib/data/backup_service.dart`（`importJson` 最后写入 `whale.rebase=1`）、`lib/application/ics_service.dart`（`import` 最后写入 `whale.rebase=1`）
- Test: `test/whale/whale_controller_test.dart`

**Interfaces:**
- Consumes：Task 2 / 3 的类型，以及现有的 `snapshotProvider`、`settingsProvider`、`clockProvider`、`repositoryProvider`
- Produces：
  - `AppSettings`：getter `whaleEnabled`、`whaleFloating`、`whaleDrawer`、`whaleTank`（默认都是 true），常量 `kWhaleEnabled = 'whale.enabled'` 等
  - `class WhaleView { final WhaleState state; final WhaleMood mood; final WhaleContext context; final WhaleReaction? reaction; final int reactionTick; }`
  - `final whaleProvider = NotifierProvider<WhaleController, WhaleView>(...)`
  - `WhaleController`：
    - `void pet()`：`reaction = pet`
    - `void poke()`：睡觉时 `reaction = poked`，否则 `reaction = null`，只换图换台词
    - `void easter()`：`reaction = easter`
    - `void clearReaction()`
    - 不对外公开的逻辑：监听快照，计算 `decayed(now).applyCompletions(count)`；`completedCount` 增加时设 `reaction = eat`。值变化时写回 settings，节流 2 秒，避免频繁写库。
  - 规则：
    - 设置里没有鲸鱼娘状态时，用 `WhaleState.initial`。
    - 看到 `whale.rebase=1` 时，执行 `rebased(count)` 并删除这个键。
    - `whaleEnabled == false` 时，执行 `frozenAt(now)`，不下降也不喂食。
    - 定时器：每分钟刷新一次心情和饱腹度。

- [ ] **Step 1：写失败的测试。** 用 `ProviderContainer` 加内存数据库，并用 `FixedClock` 推进时间。
  - `完成一件任务后饱腹度 +15，reaction == eat`
  - `撤销后饱腹度回到原值`
  - `恢复备份后不跳变`：导入包含 10 件已完成任务的备份，饱腹度不变
  - `关闭总开关 7 天后再打开，饱腹度不变`
  - `22:30 poke 时 reaction == poked；12:00 poke 时 reaction == null`
- [ ] **Step 2：运行测试。** 预期 FAIL。
- [ ] **Step 3：按 Interfaces 实现，并改 backup / ics 两处。**
- [ ] **Step 4：运行全部测试。** `flutter test`，预期全部通过，含原来的 80 个。
- [ ] **Step 5：提交。** `git commit -m "鲸鱼娘：控制器、设置键与导入重置"`

### Task 5: `WhaleSprite`

**Files:**
- Create: `lib/presentation/whale/whale_sprite.dart`
- Test: `test/whale/whale_widgets_test.dart`

**Interfaces:**
- Consumes：`whaleProvider`、`WhaleAssets`（用 `FutureProvider` 提供：`whaleAssetsProvider`，在本文件里定义）、`whaleCandidates`、`pickLine`、现有的 `haptic`
- Produces：`class WhaleSprite extends ConsumerStatefulWidget { const WhaleSprite({required double size, bool bubble = true, Alignment bubbleAlignment = Alignment.topCenter}); }`
- 行为：
  - 白色圆角卡片里放 `Image.asset(fit: BoxFit.cover)`，圆角为 size × 0.25，2 px 蓝色描边 `#5B7CFA`。
  - 同一心情约 20 秒随机换图，不连续重复；心情或 `reactionTick` 变化时立刻换。
  - 漂浮：±4 dp，周期 3 秒，同时 ±2° 摆动。
  - 轻点：缩放 1→1.15→1（250 ms），调用 `poke()`，气泡显示 3 秒，轻振一下。
  - 长按：调用 `pet()`，显示 2 秒，飘 3 颗小爱心。
  - 3 秒内连续点 5 下：调用控制器的 `easter()`，即 `reaction = easter`，显示彩蛋图 3 秒。Task 4 的 `WhaleController` 也要加上 `void easter()`。
  - 反应图显示 2 秒（被戳醒为 3 秒）后调用 `clearReaction()`。
  - `Semantics`：label 用 `whaleSemantics`，onTap 和 onLongPress 都有。

- [ ] **Step 1：写失败的组件测试。** 用 `ProviderScope` 覆盖 `whaleProvider` 和 `whaleAssetsProvider`，素材用 1×1 的内存图。
  - `轻点后出现气泡文字，3 秒后消失`：`pump(3.1s)`
  - `3 秒内连续点 5 下调用 easter`：假控制器记录调用
  - `长按调用 pet`：假控制器记录调用
  - `关闭动画时，漂浮的 AnimationController 不会运行`
  - `语义标签包含饱腹度`
- [ ] **Step 2：运行测试。** 预期 FAIL。
- [ ] **Step 3：实现。**
- [ ] **Step 4：运行测试。** 预期 PASS。
- [ ] **Step 5：提交。** `git commit -m "鲸鱼娘：WhaleSprite（漂浮、气泡、点与摸）"`

### Task 6: 三个位置与设置

**Files:**
- Create: `lib/presentation/whale/whale_floating.dart`、`lib/presentation/whale/whale_drawer_card.dart`、`lib/presentation/whale/whale_tank_screen.dart`
- Modify:
  - `lib/presentation/home/home_shell.dart`：`body` 外包一层 `Stack`，加入 `WhaleFloating`
  - `lib/presentation/home/app_drawer.dart`：在日期下方加 `WhaleDrawerCard`；B 关闭但 C 开启时，加一个「鲸鱼娘」菜单项
  - `lib/presentation/screens/settings_screen.dart`：新增「鲸鱼娘」一节
- Test: `test/whale/whale_widgets_test.dart`（追加）

**Interfaces:**
- Consumes：`WhaleSprite`、`whaleProvider`、`settingsProvider`、`selectionProvider`
- Produces：
  - `class WhaleFloating extends ConsumerWidget { const WhaleFloating({required bool hidden}); }`
    - 72 dp。默认位置在左下角，距左边 12、距导航栏上方 12。
    - 可以拖动，松手后贴到最近的左边或右边，y 夹在安全区内。
    - 位置以 `"<side>:<fractionY>"` 的格式存进 `whale.pos`，例如 `"left:0.82"`。
    - 以下任一成立时隐藏：`hidden`、`MediaQuery.viewInsets.bottom > 0`、`whaleEnabled` 或 `whaleFloating` 为 false。
  - `home_shell` 传入 `hidden: selecting || (_inboxOpen && timeline)`
  - `class WhaleDrawerCard extends ConsumerWidget`：淡蓝底卡片，内含 64 dp 的 `WhaleSprite`（不显示气泡）、饱腹度 `LinearProgressIndicator` 和当前台词。点卡片进入 `WhaleTankScreen`；C 关闭时点击无效。
  - `class WhaleTankScreen extends ConsumerWidget`：
    - `CustomPaint(painter: TankPainter(t))`：水色 `#BFE3FF`、沙底 `#E9D8A6`、三株水草 `#5FB37C`、上升的气泡；`t` 来自 `AnimationController`，周期 8 秒。
    - 中间是 200 dp 的 `WhaleSprite`，下面依次是：
      - 饱腹度条 `whaleFullness`
      - `whaleTodayDone`
      - 心情文字
      - 「摸摸头」「戳一下」两个按钮
    - 底部是 `whaleCredits`。
  - 设置：
    - 总开关 `whaleShow`；总开关打开时显示三个分开关。
    - `whaleAbout` 打开一个对话框，显示 `whaleCredits`，以及 GitHub 仓库和 CC BY-NC-SA 4.0 两个链接（`url_launcher`）。

- [ ] **Step 1：写失败的组件测试**
  - `总开关关闭时，home_shell 和 drawer 里都找不到 WhaleSprite`
  - `只关 floating 时，drawer 卡片仍在`
  - `hidden: true 时不显示 WhaleFloating`
  - `键盘弹出（viewInsets.bottom = 300）时隐藏`
  - `whale.pos = "right:2.0"（越界）时，夹回可见区域`：断言 Positioned 的 top 小于等于屏幕高减去 72 和导航栏高度
  - `鱼缸页面显示署名文字`
- [ ] **Step 2：运行测试。** 预期 FAIL。
- [ ] **Step 3：实现三个组件，改三处现有文件。**
- [ ] **Step 4：运行测试并分析。** `flutter test` 全绿，`flutter analyze` 零问题。
- [ ] **Step 5：提交。** `git commit -m "鲸鱼娘：日历角落、菜单鱼缸、鱼缸页面与设置"`

### Task 7: 模拟器验证与文档

**Files:**
- Modify: `README.md`（新增「鲸鱼娘」一行功能表格，以及素材的署名与协议说明）

- [ ] **Step 1：编译 debug 版并装到模拟器。** `flutter build apk --debug`，然后 `adb install -r`。预期 Success。
- [ ] **Step 2：用 adb 操作并截图，逐项确认**
  1. 日历左下角有鲸鱼娘在漂浮；点它出现气泡。
  2. 长按出现摸头图和爱心。
  3. 拖到右边并重启应用，位置还在。
  4. 完成一件任务，出现吃饭图，饱腹度 +15。
  5. 侧边菜单顶部有鱼缸卡片，点进去是鱼缸页面（水草、气泡、署名）。
  6. 设置里关掉总开关，A / B / C 都消失。
  7. 运行 `adb logcat` 确认没有 `E flutter`。
- [ ] **Step 3：更新 README 并提交。** `git commit -m "鲸鱼娘：README 与验证"`

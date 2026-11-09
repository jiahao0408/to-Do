# 鲸鱼娘陪伴（大肥鱼宠物）设计

日期：2026-11-09 · 状态：设计已口头确认，待审阅本文档

## 目标

在 to Do 应用里「养」一只拟人的 DeepSeek 鲸鱼娘（大肥鱼）。它的心情跟着你的任务走，可以点、摸，完成任务就是喂它；全部可以在设置里关闭。完全离线，不接 AI。

## 已确认的决定

| 问题 | 决定 |
| --- | --- |
| 形象 | 采用 [EDMOK/blue-fish-archive](https://github.com/EDMOK/blue-fish-archive) 中的「鲸鱼娘 DeepSeek」表情包 |
| 用途与授权 | 只自己用、不上架、不收费；按 CC BY-NC-SA 4.0 署名 |
| 每种心情的图 | 几张随机轮换，尽量能动，可以裁剪 |
| 位置 | A 日历角落漂浮 + B 侧边菜单小鱼缸 + C 单独的鱼缸页面 |
| 互动 | 点、摸、喂有反应，离线；不接 DeepSeek AI |
| 开关 | 总开关 + 三个位置分别开关 |
| 喂食 | 完成任务 = 喂食；饱腹度随时间慢慢下降，永远不会「死」 |

## 1. 素材

### 来源与授权

- 原设：上善无形（Bilibili）；DeepSeek 元素女仆鲸鱼娘二设：ZipZipPipe（Bilibili）；收集：EDMOK/blue-fish-archive。
- 协议：CC BY-NC-SA 4.0（署名、非商业、相同方式共享）。仓库没有 LICENSE 文件，以 README 的「版权与来源」为准。
- 裁剪和转格式后的图同样是 CC BY-NC-SA 4.0。`assets/whale/LICENSE.md` 写明作者、来源、协议、原始文件名和所做的修改。
- 应用内署名：鱼缸页面底部，以及「设置 › 鲸鱼娘 › 关于形象」。

### 文件（34 张，来自 `media/`）

| 用途 | 文件 |
| --- | --- |
| 平常（8） | deepseek-jushou-dazhaohu.png, deepseek-zuohao-yizi.webp, deepseek-biye-ciallo.webp, deepseek-hai-jing-mai-meng.png, deepseek-lanse-dafeiyu.png, deepseek-mo-yu.webp, deepseek-shafa-quanquan.gif, deepseek-dianfanbao-li.gif |
| 庆祝（7） | deepseek-zhangkai-shuangshou-huanhu.webp, deepseek-shuangshou-dianzan.jpg, deepseek-bixin.jpg, deepseek-zhayan-bixin.png, deepseek-zhenbi-huanhu.webp, deepseek-xuanfu-dianzan.png, deepseek-jushou-jiayou.jpg |
| 着急（7） | deepseek-renzhu.webp, deepseek-shangxiawen-bao-le.png, deepseek-da-ku.jpg, deepseek-kuqi.jpg, deepseek-juzhe-laba-ku.jpg, deepseek-maohan.png, deepseek-bao-tou-wei-qu.png |
| 睡觉（5） | deepseek-baozhe-jingyu-shuijiao.webp, deepseek-bao-jing-shui-jiao.png, deepseek-pa-zhe-shui-jiao.webp, deepseek-kan-pingban-shuijiao.png, deepseek-zhuo-qian-shui-zhao.webp |
| 反应（7） | 摸头：deepseek-mo-tou.png, deepseek-mo-tou-bian-ke-ai.webp；被戳醒：deepseek-shuijiao-bei-chuo.png；吃饭（喂食）：deepseek-chi-baifan.png, deepseek-ken-jitui.webp；彩蛋：deepseek-dianfanbao-touchaoxia.gif, deepseek-ni-keng.gif |

### 处理

- 下载前单独征得你同意，并说明总大小（预计 3–6 MB）。
- 静态图裁成方形（以主体为中心，留少量边距），长边不超过 512 px，转成 WebP。
- GIF 保持原样。如果某张 GIF 超过 1 MB，先问你是删掉还是保留。
- 存放：`assets/whale/{normal,celebrate,worried,sleep,reactions}/`。另有一个清单 `assets/whale/manifest.json`：文件 → 分组 → 用途（反应组细分为 pet / poked / eat / easter）。

## 2. 心情和饱腹度（纯 Dart，`lib/domain/whale/`）

### 心情

`WhaleMood { normal, celebrate, worried, sleep }`，按优先级判断：

1. 睡觉：本地时间 22:00–7:00。
2. 庆祝：今天至少有 1 件任务，并且今天的任务全部完成。
3. 着急：有逾期任务（与 RF-17 的定义相同），或饱腹度低于 25%。
4. 平常：其余情况。

所有任务都参与判断，包括在日历里隐藏的类别：隐藏只影响日历显示，和提醒、小组件一样。

### 饱腹度

- 范围 0–100，新养的鲸鱼娘从 70 开始。
- 随时间线性下降：每 24 小时 −50，从上次更新时刻算起，最低 0。
- 喂食：每完成一件任务 +15，上限 100。取消完成就扣回 15，最低 0。
- 计算方式：保存「已完成总数」（完成的单次任务数 + 重复任务的完成次数）。每次数据变化时用新旧差值 × 15 来加减，这样撤销、导入、备份恢复也都能算对。导入或恢复备份时，只重置基准，不算作喂食。
- 永远不会死，也不会消失。饱腹度低于 25% 时只是换成着急的表情和「饿饿」类台词。

### 保存

存在现有的 settings 表里，不改数据库结构：

- `whale.fullness`
- `whale.updatedAt`
- `whale.completedBaseline`
- `whale.pos`（A 的位置）
- 开关：`whale.enabled`、`whale.floating`、`whale.drawer`、`whale.tank`

## 3. 台词（`lib/domain/whale/whale_lines.dart` + ARB）

- 按心情和上下文随机挑选，同一句不连续出现。三种语言（es / en / zh）。
- 上下文：今天剩几件、下一件任务（标题 + 时间）、逾期几件、饱腹度、刚完成了一件。
- 示例（中文）：
  - 平常：「今天还剩 3 件事」「下一件：英语课 19:00」「摸鱼一下下就好」
  - 庆祝：「全部完成！今天好棒」「今天的我也很能干」
  - 着急：「有 2 件逾期了…一起处理一下？」「饿饿…完成一件喂喂我」
  - 睡觉：「Zzz…」「明天再说…」
  - 摸头：「嘿嘿」「再摸一下」
  - 被戳醒：「唔…几点了」
  - 吃饭：「好吃！」「再来一件！」

## 4. 互动与动效（`lib/presentation/whale/`）

### 核心组件 `WhaleSprite`

- 显示当前心情组里的一张图。同一心情下每约 20 秒随机换一张（不连续重复）；心情一变立刻换图。
- 平时轻轻上下漂浮（±4 dp，约 3 秒一个周期）并稍微摆动。系统开启「减少动态效果」或应用关闭「动画」（RF-42）时停止漂浮。
- 轻点：弹一下（缩放 1→1.15→1），换一张图，冒出对话气泡约 3 秒；开启振动时轻振一下。
- 长按（摸头）：显示摸头图约 2 秒，飘出小爱心。
- 睡觉时轻点：显示「被戳醒」图和台词，约 3 秒后继续睡。
- 完成任务时：如果 `WhaleSprite` 正在屏幕上，显示吃饭图约 2 秒，并说一句吃饭台词。
- GIF 正常循环播放。
- 无障碍：带语义标签（「鲸鱼娘，平常，饱腹度 70%」），提供「轻点」「摸头」两个动作。

### A 日历角落漂浮

- 约 72 dp，叠在日、3 天、周、月、日程视图上方；默认在左下角，位于底部导航栏上方，不挡右侧的加号按钮。
- 可以拖动，松手后贴到最近的左边或右边，并记住位置。
- 多选模式、收件箱面板打开时，或者键盘弹出时，自动隐藏。

### B 侧边菜单小鱼缸

- 在侧边菜单顶部、日期下方放一张卡片：淡蓝色水底背景，鲸鱼娘约 64 dp，一条饱腹度进度条，加当前一句台词。
- 点卡片进入 C；卡片上的鲸鱼娘本身也能点、能摸。

### C 鱼缸页面

- 从侧边菜单进入（开启 B 时点卡片，或菜单里的「鲸鱼娘」入口）。
- 用 CustomPainter 画水族箱：水的颜色、沙底、两三株水草、上升的气泡动画。
- 中间是大鲸鱼娘（约 200 dp）、对话气泡，下面依次是：
  - 饱腹度条和百分比
  - 今天完成几件 / 共几件
  - 当前心情
  - 「摸摸头」「戳一下」两个按钮
- 底部是署名和协议。

## 5. 设置

在「设置」中新增「鲸鱼娘」一节：

- 总开关「显示鲸鱼娘」。默认开启，可以随时关掉。
- 总开关打开时显示三个分开关：日历角落、菜单鱼缸、鱼缸页面，默认都开启。
- 「关于形象」：显示署名、协议和来源链接。
- 总开关关闭时三个位置都不出现，饱腹度也冻结；重新打开时从关闭时的数值继续。

## 6. 测试

- 单元测试：
  - 心情优先级，包括边界时间 21:59 / 22:00 / 6:59 / 7:00。
  - 饱腹度随时间下降和上下限；喂食与取消喂食；导入或恢复只重置基准；总开关关闭时冻结。
  - 台词选择：上下文填充、不连续重复。
  - 素材清单完整：每组至少一张，文件都存在。
- 组件测试：`WhaleSprite` 的轻点、长按和睡觉时被戳。
- 模拟器实测：A、B、C 三个位置，开关的效果，拖动并记住位置。

## 不做的事

- 不接 AI 聊天，不联网。
- 不做换装和商店。
- 鲸鱼娘不会死；不发推送通知催喂。
- 不改数据库结构。

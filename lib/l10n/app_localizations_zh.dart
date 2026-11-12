// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'to Do';

  @override
  String get viewDay => '日';

  @override
  String get viewWeek => '周';

  @override
  String get viewMonth => '月';

  @override
  String get viewAgenda => '日程';

  @override
  String get today => '今天';

  @override
  String get goToDate => '跳转到日期';

  @override
  String get search => '搜索';

  @override
  String get inbox => '收集箱';

  @override
  String get settings => '设置';

  @override
  String get categories => '分类';

  @override
  String get templates => '模板';

  @override
  String get statistics => '统计';

  @override
  String get weeklyReview => '每周回顾';

  @override
  String get backup => '备份';

  @override
  String get newTask => '新建任务';

  @override
  String get editTask => '编辑任务';

  @override
  String get title => '标题';

  @override
  String get titleRequired => '标题不能为空';

  @override
  String get notes => '备注';

  @override
  String get date => '日期';

  @override
  String get noDate => '无日期（收集箱）';

  @override
  String get allDay => '全天';

  @override
  String get startTime => '开始';

  @override
  String get endTime => '结束';

  @override
  String get duration => '时长';

  @override
  String durationMinutes(int n) {
    return '$n 分钟';
  }

  @override
  String get category => '分类';

  @override
  String get noCategory => '无分类';

  @override
  String get priority => '优先级';

  @override
  String get priorityHigh => '高';

  @override
  String get priorityMedium => '中';

  @override
  String get priorityLow => '低';

  @override
  String get location => '地点';

  @override
  String get link => '链接';

  @override
  String get estimate => '预计用时（分钟）';

  @override
  String get pinned => '置顶';

  @override
  String get countdownLabel => '倒计时（重要日期）';

  @override
  String get subtasks => '子任务';

  @override
  String get addSubtask => '添加子任务';

  @override
  String get reminders => '提醒';

  @override
  String get reminderAtTime => '准时';

  @override
  String reminderMinutesBefore(int n) {
    return '提前 $n 分钟';
  }

  @override
  String reminderHoursBefore(int n) {
    return '提前 $n 小时';
  }

  @override
  String reminderDaysBefore(int n) {
    return '提前 $n 天';
  }

  @override
  String get customReminder => '自定义…';

  @override
  String get minutesBeforeLabel => '提前分钟数';

  @override
  String get repeat => '重复';

  @override
  String get noRepeat => '不重复';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get complete => '完成';

  @override
  String get uncomplete => '标为未完成';

  @override
  String get postpone => '推迟';

  @override
  String get duplicate => '复制';

  @override
  String get skipOccurrence => '跳过这次';

  @override
  String get undo => '撤销';

  @override
  String get moreOptions => '更多选项';

  @override
  String get close => '关闭';

  @override
  String get ok => '确定';

  @override
  String completedCount(int done, int total) {
    return '已完成 $done/$total';
  }

  @override
  String get taskCompleted => '任务已完成';

  @override
  String get taskUncompleted => '任务未完成';

  @override
  String get taskDeleted => '任务已删除';

  @override
  String get taskMoved => '任务已移动';

  @override
  String get taskSaved => '任务已保存';

  @override
  String get taskSkipped => '已跳过这次';

  @override
  String get taskDuplicated => '任务已复制';

  @override
  String taskPostponed(String when) {
    return '已推迟到 $when';
  }

  @override
  String tasksCompleted(int n) {
    return '已完成 $n 个任务';
  }

  @override
  String tasksDeleted(int n) {
    return '已删除 $n 个任务';
  }

  @override
  String tasksMoved(int n) {
    return '已移动 $n 个任务';
  }

  @override
  String overlapWarning(String title) {
    return '与「$title」时间冲突';
  }

  @override
  String get deleteConfirmTitle => '删除任务？';

  @override
  String get deleteConfirmBody => '几秒内可以撤销。';

  @override
  String get scopeEditTitle => '编辑重复任务';

  @override
  String get scopeDeleteTitle => '删除重复任务';

  @override
  String get scopeThisOne => '仅此一次';

  @override
  String get scopeThisAndFollowing => '此次及以后';

  @override
  String get scopeAll => '全部';

  @override
  String get scopeSelected => '选择的…';

  @override
  String get selectOccurrences => '选择要修改的次数';

  @override
  String get postponePlusHour => '+1 小时';

  @override
  String get postponeThisAfternoon => '今天下午';

  @override
  String get postponeTomorrow => '明天';

  @override
  String get postponeNextWeek => '下周';

  @override
  String get postponePickDate => '选择日期…';

  @override
  String get freqDaily => '每天';

  @override
  String get freqWeekly => '每周';

  @override
  String get freqMonthly => '每月';

  @override
  String get freqYearly => '每年';

  @override
  String get every => '每';

  @override
  String intervalUnit(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': '天',
      'week': '周',
      'month': '个月',
      'year': '年',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get onDays => '星期';

  @override
  String monthlyByDay(int day) {
    return '每月 $day 日';
  }

  @override
  String monthlyByPosition(String ordinal, String weekday) {
    return '$ordinal$weekday';
  }

  @override
  String ordinal(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': '第一个',
      '2': '第二个',
      '3': '第三个',
      '4': '第四个',
      '5': '第五个',
      'other': '最后一个',
    });
    return '$_temp0';
  }

  @override
  String get endsLabel => '结束';

  @override
  String get endsNever => '永不';

  @override
  String get endsUntil => '到某日期';

  @override
  String get endsCount => '重复 N 次后';

  @override
  String get repetitions => '次数';

  @override
  String rrEveryDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '每 $n 天',
      one: '每天',
    );
    return '$_temp0';
  }

  @override
  String rrEveryWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '每 $n 周',
      one: '每周',
    );
    return '$_temp0';
  }

  @override
  String rrEveryMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '每 $n 个月',
      one: '每月',
    );
    return '$_temp0';
  }

  @override
  String rrEveryYear(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '每 $n 年',
      one: '每年',
    );
    return '$_temp0';
  }

  @override
  String rrOnMonthDay(int day) {
    return '$day 日';
  }

  @override
  String rrOnNth(String ordinal, String weekday) {
    return '$ordinal$weekday';
  }

  @override
  String rrOnDate(String date) {
    return '$date';
  }

  @override
  String rrUntil(String date) {
    return '直到 $date';
  }

  @override
  String rrCount(int n) {
    return '共 $n 次';
  }

  @override
  String get listAnd => '和';

  @override
  String get listSeparator => '、';

  @override
  String get overdueTitle => '逾期任务';

  @override
  String overdueBody(int n) {
    return '你有 $n 个过去未完成的任务。';
  }

  @override
  String get moveToToday => '移到今天';

  @override
  String get reschedule => '重新安排';

  @override
  String get discard => '放弃';

  @override
  String get allToToday => '全部移到今天';

  @override
  String get discardAll => '全部放弃';

  @override
  String get later => '稍后';

  @override
  String get inboxEmpty => '没有无日期的任务';

  @override
  String get dragToCalendar => '长按任务并拖到日历的空闲时段';

  @override
  String get searchHint => '搜索标题、备注和子任务';

  @override
  String get statusPending => '未完成';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusOverdue => '已逾期';

  @override
  String get status => '状态';

  @override
  String get dateRange => '日期';

  @override
  String get anyDate => '任意日期';

  @override
  String get clearFilters => '清除筛选';

  @override
  String get noResults => '没有结果';

  @override
  String selectedCount(int n) {
    return '已选择 $n 项';
  }

  @override
  String get moveTo => '移动到…';

  @override
  String get changeCategory => '更改分类';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get accentColor => '强调色';

  @override
  String get dynamicColor => '壁纸取色（Android 12+）';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '系统语言';

  @override
  String get weekStart => '每周开始于';

  @override
  String get monday => '周一';

  @override
  String get sunday => '周日';

  @override
  String get showWeekNumbers => '显示周数';

  @override
  String get notificationsSection => '提醒';

  @override
  String get defaultReminder => '默认提醒';

  @override
  String get none => '无';

  @override
  String get dailySummary => '每日摘要';

  @override
  String get weeklySummary => '每周摘要';

  @override
  String get monthlySummary => '每月摘要（1 日）';

  @override
  String get summaryTime => '时间';

  @override
  String get summaryDay => '星期';

  @override
  String get haptics => '振动';

  @override
  String get animations => '动画';

  @override
  String get swipeLeftAction => '向左滑动';

  @override
  String get swipeDelete => '删除';

  @override
  String get swipePostpone => '推迟';

  @override
  String get reviewDay => '每周回顾日';

  @override
  String get appearanceSection => '外观';

  @override
  String get calendarSection => '日历';

  @override
  String get interactionSection => '交互';

  @override
  String get dataSection => '数据';

  @override
  String get exportBackup => '导出备份';

  @override
  String get importBackup => '导入备份';

  @override
  String get exportBackupHint => '包含任务和附件的 .zip 文件，可保存到任意位置';

  @override
  String get importBackupHint => '从之前导出的 .zip 文件恢复';

  @override
  String get importConfirm => '导入将替换当前所有数据。继续吗？';

  @override
  String get backupExported => '备份已导出';

  @override
  String get backupImported => '备份已恢复';

  @override
  String backupError(String error) {
    return '错误：$error';
  }

  @override
  String get newCategory => '新建分类';

  @override
  String get categoryName => '名称';

  @override
  String deleteCategoryConfirm(String name) {
    return '删除「$name」？其任务将没有分类。';
  }

  @override
  String get catUni => '学校';

  @override
  String get catWork => '工作';

  @override
  String get catPersonal => '个人';

  @override
  String get notifPermissionTitle => '开启提醒';

  @override
  String get notifPermissionBody => '即使应用关闭，也会在每个任务前提醒你。为此需要通知权限和精确闹钟权限。';

  @override
  String get allow => '允许';

  @override
  String get notifActionComplete => '完成';

  @override
  String get notifActionSnooze => '推迟 10 分钟';

  @override
  String get notifChannelReminders => '提醒';

  @override
  String get notifChannelSummaries => '摘要';

  @override
  String startsIn(int n) {
    return '$n 分钟后开始';
  }

  @override
  String get startsNow => '现在开始';

  @override
  String startsAt(String time) {
    return '$time 开始';
  }

  @override
  String get dailySummaryTitle => '今日安排';

  @override
  String dailySummaryBody(int n, String first) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '今天有 $n 个任务：$first',
      zero: '今天没有任务',
    );
    return '$_temp0';
  }

  @override
  String get weeklySummaryTitle => '本周安排';

  @override
  String weeklySummaryBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '本周有 $n 个任务',
      zero: '本周没有任务',
    );
    return '$_temp0';
  }

  @override
  String get monthlySummaryTitle => '本月安排';

  @override
  String monthlySummaryBody(int n, String countdowns) {
    return '本月有 $n 个任务$countdowns';
  }

  @override
  String daysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '还有 $n 天',
      zero: '就是今天',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int n) {
    return '$n 天前';
  }

  @override
  String get suggestCompleteTask => '子任务已全部完成。要完成这个任务吗？';

  @override
  String get quickAddHint => '要做什么？';

  @override
  String weekNumberShort(int n) {
    return '第$n周';
  }

  @override
  String get noTasks => '没有任务';

  @override
  String get pinnedSection => '置顶';

  @override
  String get countdownSection => '倒计时';

  @override
  String get loadMore => '显示更多';

  @override
  String get repeats => '重复';

  @override
  String get error => '出错了';

  @override
  String get allDayShort => '全天';

  @override
  String get unscheduled => '无日期';

  @override
  String get attachments => '附件';

  @override
  String get addPhoto => '拍照';

  @override
  String get addFromGallery => '相册';

  @override
  String get addFile => '文件';

  @override
  String get timer => '实际用时';

  @override
  String get timerStart => '开始';

  @override
  String get timerPause => '暂停';

  @override
  String get timerStop => '停止';

  @override
  String get timerReset => '重置';

  @override
  String estimatedVsReal(String est, String real) {
    return '预计 $est · 实际 $real';
  }

  @override
  String get applyTemplate => '应用到某天';

  @override
  String get newTemplate => '新建模板';

  @override
  String get templateName => '模板名称';

  @override
  String get templateApplied => '模板已应用';

  @override
  String get saveAsTemplate => '将这天保存为模板';

  @override
  String get noTemplates => '还没有模板。可以在日视图中把某天保存为模板。';

  @override
  String get addItem => '添加任务';

  @override
  String get statsCompletionRate => '完成率';

  @override
  String get statsThisWeek => '本周';

  @override
  String get statsThisMonth => '本月';

  @override
  String get statsToday => '今天';

  @override
  String get statsStreak => '连续天数';

  @override
  String statsStreakDays(int n) {
    return '$n 天';
  }

  @override
  String statsBestStreak(int n) {
    return '最长连续：$n';
  }

  @override
  String get statsHabits => '习惯（重复任务）';

  @override
  String get statsTimeByCategory => '各分类预计与实际用时';

  @override
  String get statsLast7Days => '最近 7 天';

  @override
  String get statsWeeklySummary => '每周总结';

  @override
  String statsWeeklySummaryBody(int done, int total, int minutes) {
    return '完成 $done/$total · 用时 $minutes 分钟';
  }

  @override
  String get reviewStep1 => '未完成';

  @override
  String get reviewStep1Body => '上周逾期或未完成的任务';

  @override
  String get reviewStep2 => '下周';

  @override
  String get reviewStep2Body => '你已安排的内容';

  @override
  String get reviewStep3 => '收集箱';

  @override
  String get reviewStep3Body => '把无日期的任务放进空闲时段';

  @override
  String get reviewDone => '回顾完成';

  @override
  String get reviewNothing => '这里没有内容';

  @override
  String get next => '下一步';

  @override
  String get back => '上一步';

  @override
  String get finish => '完成';

  @override
  String get placeInFreeSlot => '放进空闲时段';

  @override
  String placedAt(String when) {
    return '已安排在 $when';
  }

  @override
  String get reviewReminder => '该做每周回顾了';

  @override
  String get allDoneCelebration => '今天全部完成！';

  @override
  String get quickAddPreview => '识别结果';

  @override
  String get naturalLanguageHint => '例如「明天下午6点健身」「每周一上午9点开会」';

  @override
  String get widgetTodayTitle => '今天';

  @override
  String get openMap => '在地图中打开';

  @override
  String get openLink => '打开链接';

  @override
  String get notificationsDisabled => '系统已关闭通知';

  @override
  String get exactAlarmsDisabled => '精确闹钟已关闭：提醒可能延迟';

  @override
  String get openSystemSettings => '打开设置';

  @override
  String get about => '关于';

  @override
  String get viewThreeDays => '3天';

  @override
  String get viewWorkWeek => '工作日';

  @override
  String get icsImport => '导入 .ics';

  @override
  String get icsExport => '导出 .ics';

  @override
  String get icsImportHint => '添加来自 Google 日历、Outlook 等应用的日程';

  @override
  String get icsExportHint => '把任务分享为日历文件';

  @override
  String get icsSelectAll => '全选';

  @override
  String get icsSelectNone => '全不选';

  @override
  String get icsAlreadyImported => '已导入过：勾选将替换';

  @override
  String get icsUnsupportedRule => '不支持的重复规则：只导入第一次';

  @override
  String get icsMultiDay => '多日活动：只导入第一天';

  @override
  String get icsCategoryFromFile => '按文件';

  @override
  String icsImportButton(int n) {
    return '导入 $n 项';
  }

  @override
  String icsImported(int n) {
    return '已导入 $n 个任务';
  }

  @override
  String get icsNothing => '文件中没有日程或任务';

  @override
  String icsError(String error) {
    return '无法读取文件：$error';
  }

  @override
  String get icsRange => '日期';

  @override
  String get icsAllDates => '全部';

  @override
  String get icsChooseRange => '选择范围';

  @override
  String get icsIncludeCompleted => '包括已完成';

  @override
  String get icsIncludeUndated => '包括无日期的任务（作为待办）';

  @override
  String icsWillExport(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '将导出 $n 个任务',
      zero: '没有可导出的任务',
    );
    return '$_temp0';
  }

  @override
  String get icsExportButton => '导出并分享';

  @override
  String get projects => '项目';

  @override
  String get project => '项目';

  @override
  String get newProject => '新建项目';

  @override
  String get projectName => '项目名称';

  @override
  String get noProject => '无项目';

  @override
  String get projectDue => '截止日期';

  @override
  String get noDueDate => '无截止日期';

  @override
  String deleteProjectConfirm(String name) {
    return '删除「$name」？其任务将没有项目。';
  }

  @override
  String get projectEmpty => '这个项目还没有任务';

  @override
  String get projectSeriesNote => '重复任务不计入进度';

  @override
  String get diary => '日记';

  @override
  String get dayNote => '今日笔记';

  @override
  String get dayNoteHint => '今天过得怎么样？';

  @override
  String get diaryEmpty => '还没有写过日记';

  @override
  String get searchDiary => '搜索日记';

  @override
  String get showInCalendar => '在日历中显示';

  @override
  String get manageCategories => '管理分类';

  @override
  String get countdownsAndPinned => '倒计时和置顶';

  @override
  String get nothingPinned => '没有置顶或倒计时';

  @override
  String get processInbox => '整理收集箱';

  @override
  String processInboxProgress(int i, int n) {
    return '第 $i / $n 项';
  }

  @override
  String get skip => '跳过';

  @override
  String get inboxDone => '收集箱已清空！';

  @override
  String get gestureGuide => '手势指南';

  @override
  String get gestures => '手势';

  @override
  String get naturalLanguage => '自然语言';

  @override
  String get gTapBlock => '点按任务：查看详情';

  @override
  String get gLongPressMove => '长按并移动：更改时间（周视图和3天视图中也可改日期）';

  @override
  String get gLongPress => '长按不移动：多选';

  @override
  String get gResize => '拖动任务块底边：更改时长';

  @override
  String get gPinch => '双指捏合：放大或缩小时间轴';

  @override
  String get gSwipePages => '左右滑动：切换到前后一天、一周或一个月';

  @override
  String get gSwipeList => '列表中：向右滑动完成，向左滑动删除或推迟';

  @override
  String get gLongPressEmpty => '长按空白时段：在该时间新建任务';

  @override
  String get gWeekTap => '再次点按「周」：切换为工作日（周一至周五）';

  @override
  String get gInboxDrag => '收集箱：长按任务并拖到日历空闲时段';

  @override
  String get gMonthDrag => '月视图：长按任务并拖到另一天';

  @override
  String get nlTips => '输入任务时可写日期、时间、重复、#分类 和 !优先级';

  @override
  String heatmapTitle(int year) {
    return '$year 年';
  }

  @override
  String get heatLess => '少';

  @override
  String get heatMore => '多';

  @override
  String villagerNormal1(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '今天还剩 $n 件事',
      zero: '今天没有剩下的事了',
    );
    return '$_temp0';
  }

  @override
  String villagerNormal2(String title, String time) {
    return '下一件：$title $time';
  }

  @override
  String get villagerNormal3 => '摸鱼一下下就好';

  @override
  String get villagerNormal4 => '我在这儿陪你盖房子～';

  @override
  String get villagerCelebrate1 => '全部完成！今天好棒';

  @override
  String get villagerCelebrate2 => '今天完成啦，村子在庆祝！';

  @override
  String get villagerCelebrate3 => '今天好能干！';

  @override
  String villagerWorried1(int n) {
    return '有 $n 件逾期了…一起处理一下？';
  }

  @override
  String get villagerWorried2 => '逾期的事让我好着急…';

  @override
  String get villagerHungry1 => '没力气了…完成一件任务我们继续盖';

  @override
  String get villagerHungry2 => '浑身没劲…';

  @override
  String get villagerSleep1 => 'Zzz…';

  @override
  String get villagerSleep2 => '明天再说…';

  @override
  String get villagerPet1 => '你好呀！';

  @override
  String get villagerPet2 => '谢谢你来看我';

  @override
  String get villagerPet3 => '今天天气真好';

  @override
  String get villagerPoked1 => '唔…几点了';

  @override
  String get villagerPoked2 => '再睡五分钟…';

  @override
  String get villagerEat1 => '又多一块砖！';

  @override
  String get villagerEat2 => '再来一件！';

  @override
  String get villagerEat3 => '开工啦！';

  @override
  String get villagerTitle => '村民';

  @override
  String villagerFullness(int p) {
    return '体力 $p%';
  }

  @override
  String villagerTodayDone(int done, int total) {
    return '今天完成 $done/$total';
  }

  @override
  String get villagerMoodNormal => '平常';

  @override
  String get villagerMoodCelebrate => '庆祝';

  @override
  String get villagerMoodWorried => '着急';

  @override
  String get villagerMoodSleep => '睡觉';

  @override
  String get villagerPetButton => '打招呼';

  @override
  String get villagerPokeButton => '戳一下';

  @override
  String get villagerShow => '显示村民和村庄';

  @override
  String get villagerFloating => '日历角落';

  @override
  String get villagerDrawer => '菜单卡片';

  @override
  String get villagerTank => '村庄页面';

  @override
  String villagerSemantics(String mood, int p) {
    return '村民，$mood，体力 $p%';
  }

  @override
  String get villageTitle => '村庄';

  @override
  String get villageEmpty => '创建一个项目，打下第一块基石';

  @override
  String get villageHistoric => '历史街区';

  @override
  String villageStage(int n) {
    return '第 $n/10 阶段';
  }

  @override
  String get villageHint => '项目每完成 10%，它的建筑就多盖一层';

  @override
  String get building => '村庄建筑';

  @override
  String get buildingAuto => '自动';

  @override
  String get buildingGroupHomes => '住宅';

  @override
  String get buildingGroupWork => '工作学习';

  @override
  String get buildingGroupInfrastructure => '基础设施';

  @override
  String get buildingGroupLeisure => '休闲自然';

  @override
  String get buildingHouse => '房子';

  @override
  String get buildingCabin => '小木屋';

  @override
  String get buildingApartments => '公寓楼';

  @override
  String get buildingSchool => '学校';

  @override
  String get buildingLibrary => '图书馆';

  @override
  String get buildingOffice => '办公楼';

  @override
  String get buildingWorkshop => '工坊';

  @override
  String get buildingBridge => '桥';

  @override
  String get buildingWaterTower => '水塔';

  @override
  String get buildingPowerPlant => '发电站';

  @override
  String get buildingStation => '车站';

  @override
  String get buildingPark => '公园';

  @override
  String get buildingFarm => '农场';

  @override
  String get buildingLighthouse => '灯塔';

  @override
  String get buildingCastle => '城堡';

  @override
  String get cardToday => '今天';

  @override
  String get cardStreak => '连续';

  @override
  String get cardGoal => '本周目标';

  @override
  String get cardVillager => '村民';

  @override
  String get cardPages => '卡片页面';

  @override
  String cardOverdue(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 件逾期',
      zero: '没有逾期',
    );
    return '$_temp0';
  }

  @override
  String cardNext(String title) {
    return '下一件：$title';
  }

  @override
  String get cardNothingNext => '今天没有别的了';

  @override
  String get streakRule => '连续规则';

  @override
  String get streakRuleAny => '至少 1 件';

  @override
  String get streakRuleAll => '当天全部';

  @override
  String get goalTarget => '本周目标';

  @override
  String get goalNone => '没有目标';

  @override
  String get goalPick => '在设置里选一个项目或分类';

  @override
  String goalThisWeek(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '本周 +$n',
      zero: '本周还没有',
    );
    return '$_temp0';
  }

  @override
  String get villageSection => '村庄和村民';

  @override
  String get menuCardSection => '菜单卡片';

  @override
  String get menuCardShow => '显示卡片';

  @override
  String get whenSection => '时间';

  @override
  String get organizeSection => '归类';

  @override
  String get detailsSection => '详情';

  @override
  String get moreSection => '更多';
}

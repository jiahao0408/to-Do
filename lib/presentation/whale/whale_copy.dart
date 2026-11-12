// Ballenita：从 ARB 生成候选台词（只收录上下文能填进去的句子）。

import '../../domain/whale/whale_lines.dart';
import '../../l10n/app_localizations.dart';
import '../common/format.dart';

List<String> whaleCandidates(AppLocalizations l, Fmt f, WhaleLineKind k, WhaleContext c) {
  switch (k) {
    case WhaleLineKind.normal:
      return [
        l.whaleNormal1(c.remainingToday),
        if (c.nextTitle != null && c.nextStart != null) l.whaleNormal2(c.nextTitle!, f.time(c.nextStart!)),
        l.whaleNormal3,
        l.whaleNormal4,
      ];
    case WhaleLineKind.celebrate:
      return [l.whaleCelebrate1, l.whaleCelebrate2, l.whaleCelebrate3];
    case WhaleLineKind.worried:
      return [if (c.overdue > 0) l.whaleWorried1(c.overdue), l.whaleWorried2];
    case WhaleLineKind.hungry:
      return [l.whaleHungry1, l.whaleHungry2];
    case WhaleLineKind.sleep:
      return [l.whaleSleep1, l.whaleSleep2];
    case WhaleLineKind.pet:
      return [l.whalePet1, l.whalePet2, l.whalePet3];
    case WhaleLineKind.poked:
      return [l.whalePoked1, l.whalePoked2];
    case WhaleLineKind.eat:
      return [l.whaleEat1, l.whaleEat2, l.whaleEat3];
  }
}

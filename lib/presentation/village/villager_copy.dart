// Habitante：从 ARB 生成候选台词（只收录上下文能填进去的句子）。

import '../../domain/villager/villager_lines.dart';
import '../../l10n/app_localizations.dart';
import '../common/format.dart';

List<String> villagerCandidates(AppLocalizations l, Fmt f, VillagerLineKind k, VillagerContext c) {
  switch (k) {
    case VillagerLineKind.normal:
      return [
        l.villagerNormal1(c.remainingToday),
        if (c.nextTitle != null && c.nextStart != null) l.villagerNormal2(c.nextTitle!, f.time(c.nextStart!)),
        l.villagerNormal3,
        l.villagerNormal4,
      ];
    case VillagerLineKind.celebrate:
      return [l.villagerCelebrate1, l.villagerCelebrate2, l.villagerCelebrate3];
    case VillagerLineKind.worried:
      return [if (c.overdue > 0) l.villagerWorried1(c.overdue), l.villagerWorried2];
    case VillagerLineKind.hungry:
      return [l.villagerHungry1, l.villagerHungry2];
    case VillagerLineKind.sleep:
      return [l.villagerSleep1, l.villagerSleep2];
    case VillagerLineKind.pet:
      return [l.villagerPet1, l.villagerPet2, l.villagerPet3];
    case VillagerLineKind.poked:
      return [l.villagerPoked1, l.villagerPoked2];
    case VillagerLineKind.eat:
      return [l.villagerEat1, l.villagerEat2, l.villagerEat3];
  }
}

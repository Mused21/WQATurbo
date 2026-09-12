# Known Limitations and Technical Debt

This document intentionally distinguishes shipped behavior from research ideas.

## 1. Dynamic reward results can disappear during refresh

Static achievement relevance is recreated immediately from addon data.

Reward-derived relevance such as transmog depends on Blizzard reward/item data and can take longer to rediscover after an explicit refresh.

Current behavior does not retain a session-local stale-while-revalidate dynamic reward cache.

Possible future improvement:

```text
retain last resolved dynamic reward
→ immediately rehydrate if quest still active
→ re-evaluate collection state
→ scanner replaces/removes it with fresh data
```

This is a candidate optimization, not current architecture.

## 2. Blizzard reward data is asynchronous

Even active WQs can temporarily lack:

- reward data;
- item links;
- transmog source data.

The scanner handles this with bounded per-quest pending/retry state.

No implementation can assume every API is complete on the first call after login/reload.

## 3. Some reward preload APIs are misleading

`SkipRewardDataPreloadQuests` exists because certain quests produce inaccurate or problematic preload behavior.

If duplicate skip lists still exist in legacy and optimized paths, they are maintenance debt.

Potential cleanup:

```text
one shared skip-list source
```

Do not centralize immediately before release without need.

## 4. Legacy/special daily and weekly quests do not use one universal API

Research showed that historical content uses different discovery mechanisms.

Examples:

- Mechagon can use quest-line/pin style data and already has existing support for known mappings.
- other old daily systems may only expose reliable availability after NPC interaction.

Do not create a generic "scan all legacy dailies" abstraction until concrete sources are proven.

## 5. Abomination Stitchyard research is NOT shipped

An experimental Abomination Stitchyard transmog feature was investigated and then deliberately reverted.

Findings:

- setting Maldraxxus map context can load dynamic reward payloads;
- reward counts can expose cached/stale rewards for quests that are not currently offered;
- map quest pins do not expose every Stitchyard quest;
- quest-line APIs tested did not provide a complete current-offer source;
- therefore reward presence/count is not a safe availability signal.

Conclusion:

> Do not infer current Stitchyard quest availability from `GetNumQuestLogRewards()` alone.

No Stitchyard adapter is part of 1.1.0.

If revisited, first prove a complete authoritative current-offer mechanism.

## 6. External transmog addons are intentionally not authoritative

ATT/CanIMogIt may disagree with Blizzard state or initialize asynchronously.

WQA therefore uses them only for icons.

This can mean WQA's displayed status differs from an external addon's internal interpretation; that is intentional if Blizzard's source state says otherwise.

## 7. Legacy gear scoring integrations

Pawn, StatWeightScore, Azerite and conduit paths are retained for compatibility.

Older expansion item-level comparisons may be meaningless to a modern character.

1.1.0 fixes category eligibility for caches, but the old metadata/scoring code remains.

## 8. Main module retains legacy implementations

`WQATurbo.lua` contains runtime methods that later Turbo modules supersede.

This increases cognitive load and creates a risk of patching an inactive implementation.

Long-term cleanup could separate:

```text
shared classifier/helpers
from
legacy fallback/runtime orchestration
```

but should be done incrementally with strong regression tests.

## 9. Data completeness is manual

Achievement/collectible mappings are curated.

Blizzard adding or changing:

- map IDs;
- quest IDs;
- currencies;
- factions;
- reward containers;
- achievements

can require a data update.

## 10. Zone fallback mappings can age

`Utilities.lua` contains some quest-to-zone fallback mappings for cases where direct APIs are incomplete.

These mappings need maintenance when content moves/changes.

## 11. Settings labels have constrained width

Blizzard Settings UI can clip long labels.

Use short option labels and full-width descriptions rather than embedding explanations into the label.

## 12. Current docs baseline

These docs target planned 1.1.0 on `feature/popupandcontainers`.

If additional commits land before 1.1.0 merge, update `VERSION_1.1.0.md` and any affected architectural reference in the same PR.

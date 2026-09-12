# Development Guide

## 1. Standard development workflow

Before changing code:

```powershell
git fetch origin
git branch --show-current
git status
git log --oneline --decorate -5
git rev-list --left-right --count origin/master...HEAD
```

Work on a feature/fix branch rather than assuming `master`.

Before release/PR:

```powershell
git diff --check
git diff
git status
```

Before commit, also inspect staged changes:

```powershell
git diff --cached --check
git diff --cached
git status
```

## 2. Trace the runtime owner first

Because later-loaded Turbo modules override core methods, never patch based only on the first function definition you find.

Use:

```powershell
git grep -n "function WQA:CheckWQ"
git grep -n "WQA.CheckWQ"
```

Then inspect TOC load order.

This rule applies especially to:

- `Reward`
- `CheckWQ`
- `Show`
- `OnEnable`
- collection registration helpers.

### Shared constants and tracking rules

Use `WQA.Constants.RewardType`, `CriteriaType`, `TaskType` and `TrackingMode` in
runtime code. `WQA.Rewards.RewardType` and `WQA.Criterias.CriteriaType` remain
compatible aliases. Keep persisted string values stable; declarative content
can continue using those strings.

Use `WQA.TrackingPolicy` for shared mode flags, bulk eligibility and ownership
writes. Do not move collection API calls or refresh scheduling into this module.
Run `lua5.1 tools/test_tracking_policy.lua` after changing tracking rules.

Stable currency, reputation, emissary and World Quest type lookup metadata
belongs in `DB/RuntimeData.lua`. Keep `Options.lua` focused on AceConfig tree
construction and UI-only ordering/label metadata. When adding a runtime-data
consumer, keep `DB/RuntimeData.lua` earlier in TOC load order.

## 3. Adding a new achievement mapping

1. Identify the expansion data file.
2. Determine criterion type.
3. Add declarative data only.
4. Do not add scan loops to the data file.
5. Verify faction restrictions if applicable.
6. Verify completed state.
7. Verify search/settings entry.
8. Verify popup result.

Example:

```lua
{
    name = "Example Achievement",
    id = 12345,
    criteriaType = "QUEST_SINGLE",
    criteria = 67890
}
```

For alternatives:

```lua
criteria = {
    {67890, 67891}
}
```

meaning either quest can satisfy that criterion position.

## 4. Adding an Area POI achievement

Use `AREA_POI` criteria and provide map/POI identifiers.

Example shape:

```lua
{
    name = "Example",
    id = 12345,
    criteriaType = "AREA_POI",
    criteria = {
        { AreaPoiId = 7342, MapId = 1978 }
    }
}
```

Test:

- POI active;
- POI inactive;
- completion state;
- link readiness;
- new/watched behavior.

## 5. Adding a quest-pin mapping

Use only when Blizzard's quest-line/map APIs have been proven to expose the required quest remotely.

Example pattern already used by Mechagon:

```lua
{
    id = ...,
    criteriaType = "QUEST_PIN",
    mapID = "1462",
    criteriaInfo = {...}
}
```

Do not assume every old daily/weekly quest system behaves like Mechagon.

## 6. Adding a zone

1. Verify actual Blizzard map ID.
2. Add to correct expansion in `DB/Zones.lua`.
3. Decide whether any quest-zone fallback mapping is needed.
4. Verify Settings > Zones.
5. Verify scanner map count.
6. Verify disabling the zone removes all relevance, including static achievement relevance.

Do not blindly add parent/continent maps solely because child maps exist.

## 7. Adding a mount/pet/toy

Put stable source mapping in the expansion data file.

Include the correct identifying field:

- mount: `spellID`, often `itemID`;
- pet: `creatureID`, usually `itemID`;
- toy: `itemID`.

Use quest mappings with `trackingID` when completion gating is required.

Test both unowned and owned/forced states.

## 8. Adding a reward item classification

Preferred process:

1. prove Blizzard exposes the reward item on an active WQ;
2. record authoritative item ID;
3. decide which existing user category it belongs to;
4. add a small lookup table/classification in reward logic;
5. use `AddRewardToQuest`;
6. avoid scanner changes;
7. add/update Settings only if a new user-facing category is truly necessary;
8. test option ON/OFF.

The 1.1.0 racing-purse change is a good example.

Keep reward meaning in the focused classifiers orchestrated by `CheckReward()`.
Do not move category logic into `RewardScanner.lua`. Run
`lua5.1 tools/test_reward_classifier.lua` after changing item-link acquisition,
retry propagation or any reward category.

## 9. Cache/category semantics

A category toggle should mean what its label says.

For example:

```text
Azerite Armor Cache = enabled
```

should track an Azerite Armor Cache reward.

It should not secretly mean:

```text
show Azerite Armor Cache only when its obsolete BfA item level
is an upgrade for my current Midnight character
```

Upgrade estimates can enrich display metadata, but category eligibility and upgrade usefulness should remain separate concepts.

## 10. Adding a currency

1. identify currency ID;
2. add it to the relevant expansion settings/data source;
3. ensure `CheckCurrencies` can see it;
4. test amount/link rendering;
5. test toggle OFF.

## 11. Adding reputation

Prefer Blizzard's direct quest/faction APIs for active reward detection.

Do not create a hardcoded mapping if Blizzard can answer:

> Does this quest award reputation with faction X?

Hardcoded item/currency mappings still exist for legacy token behavior.

For a new reputation, test:

- enabled and unmaxed;
- disabled;
- classic Exalted;
- Major Faction max Renown;
- friendship max rank where applicable.

## 12. Adding a profession/reward recipe case

Use authoritative reward item ID from:

```lua
GetQuestLogRewardInfo()
```

Do not trust an arbitrary hyperlink extracted from reward tooltip text.

The tooltip may contain the item produced by the recipe.

## 13. Transmog changes

Never change collection truth to ATT/CanIMogIt.

Required model:

```text
exact source owned?
    → GetAppearanceSourceInfo(sourceID)

appearance owned from any source?
    → GetAllAppearanceSources(appearanceID)
    → any source collected
```

Test at least:

1. totally unknown appearance;
2. exact source owned;
3. appearance owned from another source, exact source missing;
4. Unknown Appearance setting on/off;
5. Unknown Source setting on/off;
6. ATT installed;
7. CanIMogIt installed;
8. neither installed.

## 14. Adding a setting

Checklist:

- correct DB scope;
- correct default/wildcard behavior;
- concise label;
- useful description;
- correct Settings tree position;
- setter schedules debounced refresh;
- no per-item refresh loop for bulk changes;
- documented in `SETTINGS_REFERENCE.md`;
- functional ON/OFF test.

## 15. Minimap changes

Maintain these UX semantics:

```text
hover             → tiny hints only
left-click         → cached persistent popup
right-click        → Settings
Shift+left-click   → cached popup + silent refresh (1.1.0)
```

Always hide the hover GameTooltip before opening another UI.

## 16. Popup changes

Respect LibQTip lifecycle safety.

Never release a tooltip from a stale delayed callback.

Capture the tooltip object and call `WQA:ReleaseQTip(capturedTooltip)`. Use
`WQA:RebuildQTip("popup", tasks)` or `WQA:RebuildQTip("LDB")` when replacing a
display. Do not add another direct `LibQTip:Release()` or `WQA.tooltip = nil`
path.

When rebuilding:

```text
detach global reference
clear attached quest/mission/POI references
release old tooltip
acquire/build new tooltip
```

Avoid releasing a QTip from inside one of its own click handlers; schedule the rebuild next frame where necessary.

## 17. Performance-sensitive changes

Before changing scanner architecture, prove there is a real bug that requires it.

Ask:

- can this be solved in classification instead?
- can the pending quest be retried individually?
- will this call a collection API inside a large nested loop?
- will this cause a full refresh per setting/item?
- does this block static results while dynamic data is pending?

Use `/wqat perf` and `/wqat scan`.

## 18. Adding a new special/legacy quest source

Do not start from architecture.

Start by proving Blizzard exposes:

1. current availability;
2. current quest ID;
3. current reward data;
4. completion/reset state.

Only after those are deterministic should a source adapter be designed.

Past research showed that old daily/weekly systems use different APIs.

Do not create one universal "legacy daily API."

## 19. Documentation requirement

Every PR that changes architecture, behavior, settings, data shape, release flow or invariants must update the corresponding file under `docs/`.

See [MAINTAINING_DOCUMENTATION.md](MAINTAINING_DOCUMENTATION.md).

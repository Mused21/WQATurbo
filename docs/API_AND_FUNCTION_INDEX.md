# API and Function Index

This is a maintainer-oriented index of the important public/shared methods and runtime entry points.

It is not intended to replace source search. WQA Turbo deliberately overrides some methods in later-loaded modules, so always confirm the final implementation in the current branch.

## Core / initialization

### `WQA:OnInitialize()`

Defined in the compatibility/core layer.

Responsibilities include:

- faction-specific data pruning;
- AceDB defaults;
- pre-AceDB migration application;
- `WQATurboDB` creation;
- legacy custom-data normalization;
- minimap icon registration.

Important ordering rule:

```text
Apply pending migration
BEFORE
AceDB opens WQATurboDB
```

### `WQA:OnEnable()`

A compatibility implementation exists in the core module, while optimized startup/runtime behavior is owned by `Runtime/Runtime.lua`.

Always inspect the later-loaded implementation when debugging startup.

## Quest-list construction

### `WQA:CreateQuestList()`

Rebuilds the current relevance model.

Conceptually:

```text
clear transient lists
→ register expansion achievements
→ add mounts
→ add pets
→ add toys
→ add custom mappings
→ special/static handling
→ dynamic reward scan
→ emissary rewards
```

The optimized modules alter how the dynamic phases execute.

### `WQA:AddRewardToQuest(questID, rewardType, reward, emissary)`

Ensures `questList[questID]` exists and delegates to canonical reward merge behavior.

Prefer this over direct mutation of `questList`.

### `WQA:AddEmissaryReward(...)`

Quest reward wrapper marking emissary context.

### `WQA:AddRewardToMission(...)`

Mission equivalent.

## Static collectible registration

### `WQA:AddMounts(mounts)`

Registers relevant mapped mount sources.

The optimized collection-cache layer may replace/augment this implementation.

### `WQA:AddPets(pets)`

Registers relevant mapped pet sources.

### `WQA:AddToys(toys)`

Registers relevant mapped toy sources.

### `WQA:AddCustom()`

Registers enabled user-defined World Quest/mission/custom tracking data.

## Achievement registration

### `WQA.Achievements:Register(definition)`

Interprets declarative achievement data.

Can dispatch to quest, nested achievement, Area POI, mission, quest-pin or quest-flag logic depending on criterion type.

## Area POI criteria

### `WQA.Criterias.AreaPoi:AddReward(criteria, rewardType, reward)`

Registers relevance for an Area POI/map pair.

### `WQA.Criterias.AreaPoi:Check()`

Evaluates current POI availability/readiness and returns active/new/retry information.

## Reward scanner

### `WQA:Reward()`

A compatibility implementation exists in `WQATurbo.lua`.

The optimized active runtime implementation is supplied by `Scanning/RewardScanner.lua`.

Do not patch the legacy broad scanner expecting runtime behavior to change unless the optimized override intentionally calls that helper.

### `WQA:CheckItems(questID, isEmissary)`

Iterates the quest's reward item slots and calls `CheckReward`.

Returns whether item information still needs retry.

This is shared classification logic and remains an important seam for the optimized scanner.

### `WQA:CheckReward(questID, isEmissary, rewardIndex)`

Classifies one quest reward item.

Responsibilities include:

- obtain authoritative reward item ID;
- obtain/correct canonical item link;
- gear scoring;
- cache/container classification;
- transmog;
- reputation tokens;
- recipes;
- custom item IDs;
- configured static item IDs;
- Azerite traits/conduits.

This is generally where a new ordinary reward-item category belongs.

### `WQA:CheckCurrencies(questID, isEmissary)`

Processes quest currencies and gold.

Also supports legacy reputation-currency mappings.

## Transmog helpers

### `WQA:IsTransmogable(itemLink)`

Rejects irrelevant qualities/slots and determines whether an item is a candidate for transmog state evaluation.

### `WQA:GetTrackedTransmogIcon(itemLink)`

Determines whether the reward should be surfaced under Unknown Appearance / Unknown Source settings.

Collection truth:

```text
appearanceID/sourceID
→ exact source state
→ all-source appearance state
```

Returns icon/retry state.

## World Quest filtering

### `WQA:GetEffectiveWorldQuestType(questID, questTagInfo)`

Normalizes Blizzard quest type.

Notably uses `tradeskillLineID` as a profession fallback for older WQs.

### `WQA:ShouldIncludeWorldQuestForCurrentMode(questID, questTagInfo)`

Final publication gate for World Quests.

Covers:

- configured WQ type;
- War Mode/PvP;
- zone enabled state.

Static relevance must pass this gate too.

## Reputation

### `WQA:IsReputationMaxed(factionID)`

Handles:

- friendship reputation;
- Major Faction max Renown;
- classic Exalted.

Used by hide-maxed behavior.

## Emissaries

### `WQA:EmissaryReward()`

Compatibility/core emissary reward processing.

Inspects enabled emissaries and feeds rewards through shared item/currency classifiers.

### `WQA:EmissaryIsActive(questID)`

Checks whether a known emissary quest is currently in the quest log/active model.

## Missions

### `WQA:CheckMissions()`

Inspects supported mission tables and builds relevant mission state.

Supports configured currencies/reputation, custom items, transmog and legacy reward categories.

## Display/readiness

### `WQA:CheckWQ(mode, ...)`

A compatibility implementation exists in `WQATurbo.lua`.

The optimized runtime owner is `Runtime/TaskResolver.lua`.

The Turbo implementation:

- applies final activity/eligibility;
- resolves task/reward links;
- publishes ready tasks without waiting for every unresolved task;
- populates `activeTasks` and `newTasks`;
- routes to chat/popup/LDB behavior by mode.

### `WQA:Show(...)`

Core display/refresh behavior is augmented/overridden by specialized modules.

Do not assume a call named `Show` always performs a scan; Turbo display intentionally separates cached display from explicit refresh.

### `WQA:Refresh(...)`

Turbo explicit refresh entry point.

Used by commands/settings/minimap Shift+Left-click.

### `WQA:ShowCached(...)`

Turbo cache-first display helper.

### `WQA:TurboPublishEnrichment(mode)`

Called when background dynamic scanning discovers useful additional relevance.

Triggers readiness/publication without restarting the global scan, retaining
silent `settings` mode when that refresh started the scanner.

### `WQA:TurboRefreshOpenPopup()`

Delegates persistent-popup replacement to the canonical `RebuildQTip()` path.

## Popup / tooltip

### `WQA:CreateQTip()`

Creates/acquires a LibQTip instance.

### `WQA:ReleaseQTip(tooltip)`

Releases only the exact tooltip still owned by WQA. It detaches shared state
before LibQTip callbacks run, clears attached tasks and safely ignores stale or
repeated calls.

### `WQA:RebuildQTip(mode, tasks)`

Canonical release/rebuild path for persistent popup and transient LDB output.

### `WQA:UpdateQTip(tasks)`

Populates task rows/rewards.

### `WQA:ApplyQTipScrolling(tooltip)`

Applies height cap and scrolling behavior.

### `WQA:RefreshVisibleQTip()`

Routes expansion-collapse refreshes through `RebuildQTip()`.

### `WQA:AnnouncePopUp(...)`

Persistent popup output route.

### `WQA:AnnounceChat(...)`

Chat output route.

### `WQA:AnnounceLDB(...)`

Transient LibDataBroker tooltip route.

Minimap hover uses a small GameTooltip in the modern behavior; do not reintroduce a full WQ list on hover.

## Minimap DataBroker callbacks

### `dataobj:OnEnter()`

Shows the small minimap hint tooltip.

### `dataobj:OnLeave()`

Hides it.

### `dataobj:OnClick(button)`

Current 1.1.0 semantics:

```text
Left              → popup
Right             → Settings
Shift + Left      → popup + silent refresh
```

## Sorting / task metadata

### `WQA:SortQuestList(list)`

Applies configured sorting.

### `WQA:GetQuestZoneID(questID)`

Returns Blizzard/fallback quest zone information.

### `WQA:GetTaskZoneID(task)`
### `WQA:GetTaskZoneName(task)`
### `WQA:GetExpansion(task)`
### `WQA:GetExpansionName(expansion)`

Used by display/sort/output code.

Verify exact definitions in utility/tooltip modules before modifying.

## Reward rendering

### `WQA:GetRewardTextByID(...)`

Converts a normalized reward structure into display text.

### `WQA:GetRewardLinkByID(...)`

Resolves links for reward types.

### `WQA:SetRewardLinkByID(...)`

Caches resolved links into reward structures where applicable.

Mission wrappers delegate to equivalent quest reward behavior.

## Migration

### `WQA:ApplyPendingWQAMigrationBeforeAceDB()`

Applies captured original SavedVariables before AceDB initialization.

### `WQA:StartWQAMigration()`

Starts interactive/reload-assisted migration.

Exact helper names around migration prompts/state should be confirmed in `Migration.lua`.

## Settings

### `WQA:GetOptions()`

Returns/builds AceConfig options.

### `WQA:UpdateOptions()`

Rebuilds dynamic options tree where appropriate.

### `WQA:ScheduleOptionsRefresh()`

Debounces settings-driven full refresh.

All result-affecting settings should normally use this rather than invoke repeated direct scans.

## Performance

### `WQA:PerfStart()`

Returns a profiling timestamp based on WoW profiling APIs.

### performance record helpers

`Performance.lua` records count/total/max style timing metrics for important operations.

Use `/wqat perf`, `/wqat scan`, `/wqat cache` rather than adding permanent print spam.

## Command dispatch

Modern command handling lives in `Runtime/Runtime.lua`.

Supported commands documented by the project:

```text
/wqat
/wqat refresh
/wqat new
/wqat popup
/wqat perf
/wqat scan
/wqat cache
/wqat reset
/wqat import
```

Legacy `/wqa` compatibility remains.

## Function ownership warning

A useful debugging command is:

```powershell
git grep -n "function WQA:"
```

For one function:

```powershell
git grep -n "function WQA:CheckWQ"
git grep -n "WQA.CheckWQ"
```

Then resolve the actual runtime implementation using TOC load order.

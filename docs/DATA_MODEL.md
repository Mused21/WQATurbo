# Data Model

## 1. SavedVariables

Primary SavedVariables object:

```text
WQATurboDB
```

Original addon migration source:

```text
WQADB
```

AceDB provides three important scopes:

- `profile` — normal user-configurable tracking/settings;
- `char` — character-specific state such as profession max-level flags;
- `global` — account-wide/shared state such as some completion/custom mappings.

Always confirm scope before adding a new setting.

## 2. Important profile structures

Conceptually:

```lua
db.profile.options
db.profile.achievements
db.profile.mounts
db.profile.pets
db.profile.toys
db.profile.custom
```

### Collection tracking modes

Achievement/mount/pet/toy tables use wildcard defaults with per-ID override values such as:

```text
default
disabled
always
exclusive
wasEarnedByMe
```

Exclusive ownership metadata is stored separately under `.exclusive`.
`Constants.lua` defines these stable values in `WQA.Constants.TrackingMode`;
`TrackingPolicy.lua` reads/writes the existing schema without migration.
`wasEarnedByMe` retains the legacy achievement-specific behavior; collectibles
handle it like Default.

## 3. Core runtime tables

### `WQA.data`

Declarative built-in content database, indexed by expansion.

Example:

```lua
WQA.data[8]   -- Battle for Azeroth
WQA.data[10]  -- Dragonflight
WQA.data[12]  -- Midnight
```

Each expansion can contain:

```lua
{
    name = ...,
    achievements = {...},
    mounts = {...},
    pets = {...},
    toys = {...},
    miscellaneous = {...}
}
```

Not every expansion defines every collection.

### `WQA.RuntimeData`

Stable, read-only lookup metadata loaded from `DB/RuntimeData.lua` before its
runtime and Settings consumers:

```lua
WQA.RuntimeData.CurrencyIDsByExpansion
WQA.RuntimeData.FactionIDsByExpansion
WQA.RuntimeData.EmissaryQuestIDsByExpansion
WQA.RuntimeData.WorldQuestTypesByLabel
```

Faction-restricted entries keep the existing `{ id = ..., faction = ... }`
shape. `WQA.EmissaryQuestIDList` aliases the canonical emissary table so
existing integrations retain the same access path.

### `WQA.questList`

Current relevance model keyed by quest ID.

Conceptually:

```lua
questList[questID] = {
    reward = {
        achievement = ...,
        item = ...,
        chance = ...,
        reputation = ...,
        currency = ...,
        ...
    },
    isEmissary = ...
}
```

This table answers:

> "Why does WQA currently care about this quest?"

It does not by itself prove that the quest is currently active/displayable.

### `WQA.missionList`

Mission equivalent of `questList`.

### `WQA.activeTasks`

Sorted list of currently displayable tasks.

Entries use task descriptors such as:

```lua
{ id = questID, type = "WORLD_QUEST" }
{ id = missionID, type = "MISSION" }
{ id = areaPoiID, mapId = mapID, type = "AREA_POI" }
```

`WQA.Constants.TaskType` names these three task values. Task descriptors keep
their existing string representation.

### `WQA.newTasks`

Tasks considered newly discovered relative to watched state.

### `WQA.watched`

Tracks World Quests already seen for "new" behavior.

### `WQA.watchedMissions`

Mission equivalent.

### `WQA.itemList`

Item IDs that should make a reward relevant when encountered.

Used by mapped collectible/custom item flows.

### `questPinList` / `questPinMapList`

State for custom/achievement quest-pin style criteria.

### `questFlagList`

State for quest-flag based criteria.

## 4. Reward types

`Constants.lua` defines canonical reward type constants under
`WQA.Constants.RewardType`. `Rewards/RewardType.lua` keeps the existing
`WQA.Rewards.RewardType` access path as an alias to that same table:

```text
ACHIEVEMENT
AZERITE_TRAIT
CHANCE
CURRENCY
CUSTOM
CUSTOM_ITEM
GOLD
ITEM
MISCELLANEOUS
PROFESSION_SKILLUP
RECIPE
REPUTATION
```

Use these concepts consistently rather than inventing ad-hoc parallel structures.

## 5. Reward merge semantics

`Rewards/Reward.lua` is the canonical merge layer.

This is important because a single quest can gain relevance from multiple passes.

### Item reward

The `ITEM` reward is a table and fields are merged.

Typical fields include:

```lua
{
    itemLink = "...",
    transmog = "...",
    itemLevelUpgrade = 10,
    itemPercentUpgrade = 5,
    AzeriteArmorCache = {...},
    cache = {
        upgradeNum = ...,
        n = ...,
        upgradeMax = ...
    }
}
```

Because fields merge, code may safely first add the item itself and later enrich it with upgrade metadata without creating a duplicate task.

This behavior is used by the 1.1.0 cache fixes.

### Achievement/chance rewards

These may contain arrays of distinct mapped rewards and are de-duplicated.

### Reputation/currency rewards

Structured values include faction/currency identifiers and amounts or links.

## 6. Achievement data schema

Expansion data uses objects broadly shaped like:

```lua
{
    name = "Achievement Name",
    id = 12345,
    criteriaType = "QUESTS",
    criteria = {...},
    faction = "Alliance" -- optional
}
```

### `QUEST_SINGLE`

One quest corresponds to the criterion.

```lua
{
    id = 12345,
    criteriaType = "QUEST_SINGLE",
    criteria = 67890
}
```

### `QUESTS`

A list of criteria.

Nested arrays can represent alternatives for one criterion.

Example concept:

```lua
criteria = {
    10001,
    {10002, 10003}, -- either quest can satisfy this criterion
    10004
}
```

### `ACHIEVEMENT`

Nested achievement definitions.

Useful where a meta achievement depends on child achievements which themselves map to quests/POIs.

### `AREA_POI`

Uses data shaped approximately:

```lua
{
    AreaPoiId = 7342,
    MapId = 1978
}
```

### `QUEST_PIN`

Remote quest-line availability mapping.

Typical fields:

```lua
criteriaType = "QUEST_PIN",
mapID = 1462,
criteriaInfo = {...}
```

### `QUEST_FLAG`

Uses Blizzard completed-quest flag state.

### `MISSION_TABLE`

Marks an achievement as related to supported missions.

### `SPECIAL`

Used for special cases such as expansion-wide World Quest count achievements.

## 7. Collectible data schema

### Mount

Typical:

```lua
{
    name = "Mollie",
    itemID = 174842,
    spellID = 298367,
    quest = {
        { wqID = 52196 }
    }
}
```

### Pet

Typical:

```lua
{
    name = "Pet Name",
    itemID = ...,
    creatureID = ...,
    quest = {
        {
            trackingID = ...,
            wqID = ...
        }
    },
    faction = ... -- optional
}
```

### Toy

Typical:

```lua
{
    name = "Toy",
    itemID = ...,
    quest = {
        {
            trackingID = ...,
            wqID = ...
        }
    }
}
```

## 8. Expansion index model

Internal expansion indexes are WQA-specific and intentionally align with the data files/settings architecture.

Current map:

| WQA index | Expansion |
|---:|---|
| 6 | Warlords of Draenor |
| 7 | Legion |
| 8 | Battle for Azeroth |
| 9 | Shadowlands |
| 10 | Dragonflight |
| 11 | The War Within |
| 12 | Midnight |

Do not confuse these values with arbitrary Blizzard expansion enum values without checking the code.

## 9. Zone data

`ZoneIDList[expansion]` is the map scan list.

A map must generally be present there for the standard World Quest scanner to consider it.

Zone profile defaults use wildcard `true`, and individual maps can be disabled.

## 10. Criteria model

`Constants.lua` defines all eight achievement/POI criteria types under
`WQA.Constants.CriteriaType`. `Criterias/CriteriaType.lua` exposes the same table
as `WQA.Criterias.CriteriaType`. Declarative data retains its existing strings.

`Criterias/AreaPoi.lua` maintains:

- registered POI rewards;
- watched POIs;
- active/new results;
- link readiness/retry state.

Achievement criteria are dispatched by `Achievements.lua` using these constants.

## 11. Collection caches

Collection caches are ephemeral runtime indexes, not SavedVariables.

Their purpose is performance, not persistence. Runtime collectible registration
and Settings completion grouping share the same spell-ID/creature-ID ownership
indexes.

If collection state changes, a refresh should rebuild/re-evaluate it.

## 12. Scanner pending model

Reward scanner pending state is per quest.

A pending entry tracks enough state to retry only that quest, including concepts such as:

- pending kind (reward/item);
- time first pending;
- last preload request;
- preload reissue count.

This state must remain ephemeral.

## 13. Popup collapse state

Persistent popup expansion collapse state is profile-scoped:

```lua
db.profile.options.popupCollapsedExpansions
```

## 14. 1.1.0 settings data

The new Dragonflight racing-container option lives under expansion reward settings:

```lua
db.profile.options.reward[10].racingRewardContainers
```

The existing wildcard reward defaults make expansion reward toggles default to enabled unless explicitly overridden.

## 15. Data ownership rule

Use this decision:

```text
Is this a stable mapping between game IDs?
    → DB/Data, DB/Zones or DB/RuntimeData

Is this user preference?
    → AceDB profile/char/global as appropriate

Is this transient scan state?
    → runtime table, never SavedVariables

Is this a normalized relevance result?
    → questList / missionList reward merge model

Is this display-ready state?
    → activeTasks/newTasks
```

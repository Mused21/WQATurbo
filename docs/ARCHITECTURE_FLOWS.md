# Architecture Flows

This companion document contains end-to-end flow traces for common behaviors.

## Flow A: ordinary `/wqat`

```text
user: /wqat
    ↓
TurboRuntime command dispatch
    ↓
TurboDisplay cache-first path
    ↓
current activeTasks / questList
    ↓
render current output
```

Expected:

- no broad World Quest map scan;
- no collection journal rebuild;
- no reward-data preload storm.

## Flow B: `/wqat refresh`

```text
user: /wqat refresh
    ↓
explicit Refresh
    ↓
CreateQuestList
    ├─ clear/rebuild relevance state
    ├─ register achievements
    ├─ register mounts/pets/toys using collection cache
    ├─ custom/special mappings
    └─ start reward/emissary dynamic work
         ↓
RewardScanner incremental initial phase
         ↓
per-quest pending/retry
         ↓
TurboPublishEnrichment when useful results appear
         ↓
TurboCheck
         ↓
activeTasks/newTasks
```

## Flow C: setting toggle

```text
AceConfig setter
    ↓
update AceDB
    ↓
ScheduleOptionsRefresh
    ↓
debounce (~short delay)
    ↓
silent refresh
    ↓
if popup already open:
    update as results become ready
```

Expected:

- no chat spam;
- no popup forced open;
- many bulk changes coalesce.

## Flow D: 1.1.0 Shift+Left-click

```text
click
    ↓
hide minimap GameTooltip
    ↓
Show("popup")
    ↓
cached popup immediately visible
    ↓
Refresh("settings", true)
    ↓
silent rebuild/scanner
    ↓
open popup receives refreshed/enriched result set
```

## Flow E: static achievement relevance

```text
CreateQuestList
    ↓
Achievements:Register(definition)
    ↓
inspect completion / criteria
    ↓
AddRewardToQuest(wqID, ACHIEVEMENT, ...)
    ↓
questList populated immediately
    ↓
TurboCheck final activity/type/zone filter
    ↓
ready task appears
```

Dynamic reward APIs are not required for the achievement reason itself.

## Flow F: transmog relevance

```text
RewardScanner discovers active WQ
    ↓
reward data ready?
    ├─ no → pending/retry
    └─ yes
         ↓
CheckItems
         ↓
CheckReward
         ↓
authoritative reward item ID
         ↓
canonical reward item link ready?
         ├─ no → pending/retry
         └─ yes
              ↓
IsTransmogable
              ↓
GetTrackedTransmogIcon
              ├─ exact source state
              └─ enumerate all sources for appearance
                   ↓
Unknown Appearance / Unknown Source setting
                   ↓
AddRewardToQuest(ITEM)
                   ↓
TurboPublishEnrichment
```

## Flow G: reputation relevance

```text
active WQ
    ↓
for enabled reputation factions
    ↓
DoesQuestAwardReputationWithFaction(questID, factionID)
    ↓
match?
    ├─ no
    └─ yes
         ↓
resolve amount/major-faction data when available
         ↓
AddRewardToQuest(REPUTATION)
```

Maxed factions can be hidden/skipped before matching depending on settings.

## Flow H: cache/container classification in 1.1.0

```text
CheckReward(itemID)
    ↓
is recognized cache/container?
    ↓
is corresponding option enabled?
    ├─ no → no relevance from this category
    └─ yes
         ↓
AddRewardToQuest(ITEM, itemLink)
         ↓
optional legacy upgrade calculation
         ↓
merge upgrade metadata into same ITEM reward if available
```

Eligibility and upgrade usefulness are separate.

## Flow I: popup rebuild safety

```text
enrichment/settings causes popup refresh
    ↓
capture old tooltip
    ↓
detach WQA.tooltip reference
    ↓
clear old attached quests/missions/pois
    ↓
LibQTip:Release(old)
    ↓
acquire/rebuild popup
```

Any delayed old callback verifies it still owns the same tooltip before releasing.

## Flow J: migration

```text
addon load
    ↓
Migration captures raw WQADB
    ↓
before AceDB opens WQATurboDB:
    ApplyPendingWQAMigrationBeforeAceDB
    ↓
deep-copy compatible DB structure
    ↓
AceDB initializes WQATurboDB
```

If original addon data is unavailable because the addon is disabled/not loaded, the import command can temporarily enable it and use a reload-assisted flow.

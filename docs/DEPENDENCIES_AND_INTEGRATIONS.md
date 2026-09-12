# Dependencies and Integrations

## 1. Embedded libraries

The release package obtains libraries through `.pkgmeta` externals.

### AceAddon-3.0

Addon object/lifecycle and module-style foundation.

### AceConsole-3.0

Slash-command support.

### AceTimer-3.0

Timers used for:

- delayed startup work;
- retry scheduling;
- debounced refresh;
- periodic behavior.

### AceDB-3.0

SavedVariables/profile management.

### AceDBOptions-3.0

Profile Settings page integration.

### AceConfig-3.0 / AceGUI-3.0

Settings tree and controls.

### CallbackHandler-1.0 / LibStub

Library infrastructure.

### LibDataBroker-1.1

Minimap/data-object integration surface.

### LibDBIcon-1.0

Minimap icon.

### LibQTip-1.0

World Quest popup/tabular tooltip.

LibQTip lifecycle is safety-critical; see invariants.

## 2. Blizzard APIs

WQA Turbo relies on multiple API families.

### World Quest / quest APIs

Examples:

```text
C_TaskQuest
C_QuestLog
C_QuestLine
QuestUtils_IsQuestWorldQuest
```

Used for:

- active map quests;
- quest tags;
- reward data;
- reward preload;
- quest completion;
- quest-line/pin criteria.

### Item APIs

```text
C_Item
GetItemInfo
GetQuestLogRewardInfo
GetQuestLogItemLink
```

Reward item ID from quest APIs is authoritative when tooltip links disagree.

### Transmog

```text
C_TransmogCollection
```

Authoritative collection state.

### Collections

```text
C_MountJournal
C_PetJournal
PlayerHasToy
```

CollectionCache optimizes repeated access.

### Reputation

```text
C_Reputation
C_MajorFactions
C_GossipInfo.GetFriendshipReputation
C_QuestLog.DoesQuestAwardReputationWithFaction
```

Different reputation systems require different max-state logic.

### PvP

```text
C_PvP.IsWarModeDesired
```

Used by PvP WQ final eligibility.

### Area POI

```text
C_AreaPoiInfo
```

Used for supported Area POI achievement criteria.

### Professions

```text
C_TradeSkillUI
```

Used with `tradeskillLineID`.

### Garrison/mission

```text
C_Garrison
```

Legacy mission-table support.

## 3. Optional addon integrations

### WQAchievements

Purpose:

- migration source only.

It is declared as an optional dependency so migration can access legacy SavedVariables/addon state.

WQA Turbo must remain usable after the old addon is disabled/removed.

### AllTheThings

Purpose:

- transmog icon presentation.

`SafeATTSearchForLink()` protects startup races around ATT search initialization.

ATT collection flags are not authoritative for WQA relevance.

### CanIMogIt

Purpose:

- transmog icon presentation fallback.

Not authoritative for relevance.

### Pawn

Optional gear upgrade scoring.

Only used when installed and user setting enables it.

### StatWeightScore

Optional gear scoring integration.

## 4. Integration failure policy

Optional integrations must fail soft.

Examples:

- ATT search unavailable during startup → retry/fallback, no addon crash;
- Pawn absent → skip Pawn classification;
- CanIMogIt absent → use ATT or Blizzard/WQA fallback icons.

Core WQA tracking must not depend on optional addon initialization order.

## 5. Dependency update caution

Embedded library updates can change UI callback/lifecycle behavior.

Before upgrading LibQTip specifically, retest:

- popup release;
- stale auto-hide callback;
- scrolling;
- collapse click rebuild;
- persistent popup;
- minimap transient tooltip.

## 6. Packaging

Libraries are expected to be embedded in the release ZIP.

CI validates key library directories after packaging.

Do not assume a user's WoW installation already contains Ace3/LibQTip globally.

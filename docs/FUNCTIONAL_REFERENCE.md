# Functional Reference

This document describes WQA Turbo from the user's point of view while tying each behavior back to its internal subsystem.

## 1. What WQA Turbo tracks

Depending on settings and available data, WQA Turbo can surface active tasks useful for:

- achievements;
- mounts;
- pets;
- toys;
- transmog appearances/sources;
- gear upgrades;
- gear/reward containers;
- currencies;
- reputation;
- professions and recipes;
- gold;
- custom World Quests/items;
- supported mission-table goals;
- Area POI based criteria.

A single task can be relevant for multiple reasons and is merged into one displayed task with multiple reward/relevance annotations.

## 2. Static collectible tracking

### Achievements

Achievement mappings are stored in expansion data and registered during list creation.

Supported criterion styles include:

- direct World Quest;
- alternatives/groups of quests;
- nested achievements;
- quest completion flags;
- quest-line/pin discovery;
- Area POI;
- mission table;
- special expansion-wide World Quest counters.

Completed criteria are excluded according to achievement state and tracking mode.

### Mounts

Mapped mount sources are shown when the mount is not collected, unless tracking mode forces the entry to be shown.

Collection journal state is indexed through the collection cache.

### Pets

Mapped pet sources are shown when the pet is not owned, subject to configured
tracking mode. One collected copy counts as owned; the species' maximum copy
limit is not a completion target. The cached journal row is cross-checked with
Blizzard's per-species collected count for mapped pets.

### Toys

Mapped toy sources are shown when `PlayerHasToy()` is false, subject to configured tracking mode.

## 3. Tracking modes

Collection/achievement entries support ordinary modes such as:

- Don't track
- Default
- Always track

Character-specific/exclusive ownership modes remain individual-entry concepts and are intentionally not exposed as bulk values.

Bulk operations should clear incompatible exclusive ownership state when changing entries to ordinary modes.

## 4. Search

Tracking search supports:

- full names;
- partial names;
- IDs;
- case-insensitive text.

Search spans:

- achievements;
- mounts;
- pets;
- toys.

Search text is transient and is not intended to persist across reloads.

## 5. World Quest type filtering

World Quest types are filtered through the effective type helper.

Important types include:

- normal/default;
- PvP;
- pet battle;
- dungeon;
- profession.

Older profession World Quests can be recognized by `tradeskillLineID` even when Blizzard's `worldQuestType` is incomplete/inconsistent.

## 6. War Mode

Setting:

> Show PvP World Quests while War Mode is disabled

Stored under:

```lua
db.profile.options.showWarModeQuestsWithoutWarMode
```

Default: false.

PvP WQs are excluded while War Mode is disabled unless this setting is enabled.

## 7. Zone filtering

Zone enable/disable state is a **final eligibility gate**, not merely a scanner optimization.

This is important because achievement/static mappings can identify a WQ before the dynamic reward scanner visits it.

A disabled zone must suppress a WQ regardless of why it is relevant.

Val and Naigtal are also subject to their weekly portal availability. Even
with both zone settings enabled, WQA Turbo scans and displays only the current
destination. This availability check applies to dynamic rewards and
achievement-backed World Quests. The localized live portal Area POI is the
primary signal and the regional weekly-reset clock is the fallback. If neither
signal or a quest's zone is available, the check fails open rather than hiding
an uncertain task.

## 8. Transmog

Settings:

- Unknown appearance
- Unknown source

### Semantics

**Unknown appearance** means the visual appearance has not been collected from any source.

**Unknown source** means the appearance exists in the collection, but the exact item/source being rewarded is not collected.

For:

```text
appearance collected = yes
exact source collected = no
```

the expected matrix is:

| Unknown appearance | Unknown source | Show? |
|---|---|---|
| On | On | Yes |
| On | Off | No |
| Off | On | Yes |
| Off | Off | No |

### Collection-state authority

Blizzard APIs are authoritative.

The logic is approximately:

```text
GetItemInfo(itemLink)
    ↓
appearanceID + sourceID

source ownership:
    GetAppearanceSourceInfo(sourceID).isCollected

appearance ownership:
    GetAllAppearanceSources(appearanceID)
    ↓
    any source has isCollected == true
```

Do not rely solely on `GetAppearanceInfoBySource().appearanceIsCollected`; it was proven unreliable for some multi-source appearances.

### ATT and CanIMogIt

These integrations provide familiar presentation icons only.

Priority:

1. ATT icon if ATT is installed;
2. CanIMogIt icon if only CanIMogIt is installed;
3. WQA/Blizzard fallback icon.

Installing either addon must not alter WQA's collection-state decision.

## 9. Reputation

Reputation can be detected dynamically for explicitly enabled factions.

Direct quest checks use Blizzard reputation APIs rather than relying solely on old hardcoded reward-token tables.

Major Faction/Renown reward information is used when available.

### Hide maxed reputation setting

The "Hide Exalted / max Renown reputations" behavior handles:

1. classic reputation — Exalted;
2. Major Factions — maximum Renown;
3. friendship reputations — maximum friendship rank.

World Quest and Mission Table reputation pages both expose the same profile
setting so every reputation list can be restored when all entries are hidden.
The setting applies consistently to direct reputation rewards, reputation
tokens and reputation currencies.

Friendship factions such as Captain Tokka must not be treated as ordinary classic reputation.

## 10. Currency

Configured currencies are detected from quest reward currency data.

Expansion settings determine which currency IDs are enabled.

## 11. Professions and recipes

Profession World Quests may be detected via `tradeskillLineID`.

Recipe classification uses the authoritative quest reward item ID.

A known tooltip issue is specifically defended against:

- some recipe reward tooltips contain a hyperlink to the item created by the recipe;
- tooltip scanning can return that embedded crafted-item link;
- WQA compares the scanned item ID with `GetQuestLogRewardInfo()`'s reward item ID;
- if they differ, the canonical reward item link wins.

## 12. Gear

Supported gear-related behavior includes:

- Pawn upgrade detection;
- StatWeightScore integration;
- direct item-level upgrade detection;
- Azerite Armor Cache;
- a per-character Azerite Armor Cache override;
- Armor Cache;
- Weapon Cache;
- unknown transmog appearance/source;
- Azerite traits;
- conduits where supported.

### 1.1.0 cache semantic change

Before 1.1.0, some cache toggles effectively acted as "show only if this old cache is an item-level upgrade."

That was misleading, especially on modern characters doing old content.

For 1.1.0:

- enabling Azerite Armor Cache tracks the cache itself;
- its per-character override can exclude characters whose armor type is complete;
- enabling recognized Armor/Weapon cache categories tracks the cache itself;
- legacy upgrade calculation remains supplemental display metadata.

Zandalari Empire Equipment Cache is hidden after its verified shared cloak and
current armor-type appearance pool is complete. Tortollan Trader's Stock is not
an appearance cache and is therefore excluded.

## 13. Benthic gear — 1.1.0

Nazjatar Benthic slot tokens are recognized by the existing Armor Cache setting.

Tracked IDs:

```text
169477 Benthic Girdle
169478 Benthic Bracers
169479 Benthic Helm
169480 Benthic Chestguard
169481 Benthic Cloak
169482 Benthic Leggings
169483 Benthic Treads
169484 Benthic Spaulders
169485 Benthic Gauntlets
```

They are slot-specific container/token rewards rather than generic random-slot caches, so they are tracked directly through Armor Cache without pretending their usefulness depends on the character's modern item level.

Each token is checked against the fixed appearance pool for the active
character's armor type because generated armor follows the active loot
specialization. The token stops making the World Quest relevant when that pool
is complete. Cloak tokens use their shared four-appearance pool. If Blizzard
has not made a relevant source available to the transmog API yet, the token
stays visible and the scanner retries.

## 14. Dragonflight racing reward containers — 1.1.0

Settings path:

```text
Rewards
└─ Dragonflight
   └─ World Quests
      └─ Containers
         └─ Racing reward containers
```

Recognized purse IDs:

```text
199192 Dragon Racer's Purse
204359 Reach Racer's Purse
205226 Cavern Racer's Purse
210549 Dream Racer's Purse
```

The addon tracks the purse while at least one Drakewatcher's Manuscript from
that purse remains uncollected. Each purse has its own fixed pool, so completing
Reach Racer's Purse does not hide Dragon Racer's Purse, Cavern Racer's Purse or
Dream Racer's Purse. Collection state comes from the account-wide hidden quest
flag recorded when each customization is learned.

Azerite Armor Cache remains category tracked because its possible gear varies
with the reward link's modifier, faction, zone and character. It has a
per-character override instead of an unsafe combined completion pool.

## 15. Gold

Gold WQs are controlled by:

- enable/disable setting;
- minimum gold threshold.

## 16. Custom tracking

Custom configuration can track:

- World Quest IDs;
- quest pins with map ID;
- quest flags;
- custom reward item IDs;
- missions.

Custom entries are stored separately from built-in data and can be profile-enabled/disabled.

## 17. Mission tables

Mission-table settings are shown only for expansions that actually use them in WQA:

- Warlords of Draenor
- Legion
- Battle for Azeroth
- Shadowlands

Do not add Mission Table pages for:

- Dragonflight
- The War Within
- Midnight

unless the game's content model changes and real functionality is implemented.

## 18. Minimap button

### Hover

Small hint tooltip only.

It must not show the entire World Quest result list.

### Left-click

Open persistent cached World Quest popup.

### Right-click

Open WQA Turbo Settings using the numeric AceConfig/Blizzard Settings category ID.

Do not call `Settings.OpenToCategory("WQATurbo")`.

### Shift+Left-click — 1.1.0

Behavior:

```text
open cached popup immediately
+
start silent full refresh
```

The popup then updates through the existing progressive enrichment path.

The hover hint reflects this behavior.

## 19. Persistent popup

Features:

- task-name hover appends a localized explanation of the cached reward
  categories that caused the task to match;

- cached immediate open;
- scrollable;
- approximate 60% UI-height cap;
- collapsible expansion sections;
- collapse state stored per profile;
- progressive updates;
- optional remembered position.

Minimap click instructions are not included inside the persistent popup.

## 20. Chat/output behavior

Tasks can be announced in chat based on mode/settings.

Settings-triggered refresh is intentionally silent.

A refresh caused by a setting toggle should not spam chat.

## 21. Migration from WQAchievements

Migration supports:

- optional dependency on `WQAchievements`;
- copying raw `WQADB` before AceDB opens `WQATurboDB`;
- `/wqat import`;
- temporary enabling of the original addon when required;
- reload-assisted import;
- deep-copy of the old AceDB structure;
- namespace collision handling.

Migration should be treated as compatibility-critical.

## 22. Mechagon

Mechagon is already represented by the existing data architecture.

For example, the BfA `Outside Influences` achievement uses `QUEST_PIN` data with map ID 1462.

Do not build a second Mechagon discovery subsystem without first proving an actual coverage gap.

## 23. What the addon intentionally does not do

- It does not scan continuously every frame.
- It does not open a full result popup on minimap hover.
- It does not treat ATT/CanIMogIt as collection-state authorities.
- It does not infer all historical daily/weekly quest rotations from reward data.
- It does not currently persist a dynamic reward cache across explicit refreshes.

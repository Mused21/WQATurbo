# Settings Reference

## 1. Settings architecture

WQA Turbo uses AceConfig/AceDB.

Top-level Settings tabs:

```text
Tracking
Rewards
Custom
Options
```

Settings are built dynamically in `UI/Options.lua`.

Stable currency, reputation, emissary and World Quest type lookup metadata is
owned by `Data/RuntimeData.lua`. `UI/Options.lua` reads those tables while building
the UI; loading Settings is not required to initialize runtime metadata.

Most setters call a debounced refresh scheduler so that configuration changes become visible without requiring `/reload`.

## 2. Tracking

The Tracking tree is organized by expansion and collectible category.

Typical structure:

```text
Tracking
├─ Search
├─ Midnight
│  ├─ Achievements
│  ├─ Mounts
│  ├─ Pets
│  └─ Toys
├─ The War Within
├─ Dragonflight
└─ ...
```

Expansions are displayed newest-to-oldest.

### Search

Search accepts:

- names;
- partial names;
- IDs;
- case-insensitive text.

Search covers achievements, mounts, pets and toys.

Search is transient and does not need to persist.

### Individual tracking modes

Ordinary values:

- Don't track
- Default
- Always track

Character-specific/exclusive modes can also exist on individual entries.

In 1.2 Step 3, mode keys come from `WQA.Constants.TrackingMode` and common rules
live in `Tracking/TrackingPolicy.lua`. `GetState` returns enabled, always and character-only
flags; `IsBulkMode` accepts only disabled/default/always; `SetValue` updates the
mode and exclusive owner together. `UI/Options.lua` still schedules refreshes.

Existing behavior is preserved: only achievements consume the character-only
flag, and their inherited `forcedByMe` reset remains a separate correctness issue.
A missing exclusive owner still displays the original mode in Settings, while
runtime eligibility rejects it for a named character.

### Category bulk tracking

Example:

```text
Legion > Achievements > set all to Default
```

### Expansion bulk tracking

Applies ordinary tracking mode to supported collectible categories in that expansion.

Bulk operations:

- include completed entries;
- clear incompatible exclusive ownership state when switching to ordinary modes;
- schedule one debounced refresh.

Do not expose exclusive/character-only modes as bulk values.

### Completed entries and tooltips

Completed entries remain hoverable.

Mount and pet completion grouping uses the shared `Tracking/CollectionCache.lua`
ownership indexes. Building the Settings tree does not perform one complete
journal walk per collectible row.

Achievement tooltips use achievement hyperlinks.

Mount/pet/toy tooltips use item/spell links as available.

Do not disable a completed InteractiveLabel when a tooltip hyperlink is available.

Correct completed logic:

```lua
disabled = completed and not tooltipHyperlink
```

Avoid Lua pseudo-ternary patterns such as:

```lua
a and false or completed
```

because they fall through when the middle value is false.

## 3. Rewards

Broad structure:

```text
Rewards
├─ General
├─ Gear
├─ Midnight
│  └─ World Quests
├─ The War Within
├─ Dragonflight
├─ Shadowlands
├─ Battle for Azeroth
└─ ...
```

Expansion World Quest groups can contain:

- Zones
- Currencies
- Reputation
- Professions
- expansion-specific categories

### Mission Table

Show only for:

- Warlords of Draenor
- Legion
- Battle for Azeroth
- Shadowlands

Do not show for Dragonflight, The War Within or Midnight.

## 4. General

General behavior includes concepts such as:

- gold tracking;
- minimum gold;
- World Quest type filtering.

The actual Settings label structure should be verified in `UI/Options.lua`.

## 5. World Quest types

Type settings are used by the final eligibility gate.

A false value must prevent publication even when static data made the quest relevant.

## 6. Gear

Gear settings include:

- item-level upgrade;
- minimum item-level upgrade;
- Pawn upgrade;
- minimum percentage;
- StatWeightScore;
- Azerite Armor Cache;
- Armor Cache;
- Weapon Cache;
- Jewelry Cache;
- Unknown appearance;
- Unknown source;
- Azerite traits;
- Conduit.

Not all legacy integrations are relevant to all modern content, but compatibility behavior is retained.

### 1.1.0 cache semantics

A cache option means:

> track this cache category

It no longer means:

> track this cache only if the old contents are an upgrade for my current gear

Upgrade calculations remain supplemental metadata.

## 7. Dragonflight Containers — 1.1.0

New path:

```text
Rewards
└─ Dragonflight
   └─ World Quests
      └─ Containers
         └─ Racing reward containers
```

Storage:

```lua
db.profile.options.reward[10].racingRewardContainers
```

Recognized items:

- Dragon Racer's Purse
- Reach Racer's Purse
- Cavern Racer's Purse
- Dream Racer's Purse

Changing the toggle schedules the standard debounced settings refresh.

## 8. Benthic gear — 1.1.0

No new Benthic-specific option is introduced.

Benthic tokens use:

```text
Rewards > Gear > Armor Cache
```

This keeps the user model simple: these are equipment-container/token rewards.

## 9. Reputation

Reputation pages are expansion-aware.

A faction can be explicitly enabled for tracking.

Optional behavior:

> Hide Exalted / max Renown reputations

When enabled, maxed factions should disappear from settings and be ignored for dynamic matching.

Max-state detection must cover classic, Renown and friendship systems.

## 10. Zones

Each supported map can be enabled/disabled.

Zone state is used by:

- scan map selection;
- final WQ eligibility.

The final gate is essential. Never rely only on "we skipped scanning this map" because static mappings can already have added the quest.

## 11. Professions

Profession settings are generated using profession/tradeskill data.

Each character can have profession max-level state in character-scoped DB data.

Profession WQs can be recognized through `tradeskillLineID`.

## 12. Custom

Custom settings support user-provided task/reward mappings.

Possible task forms include:

- World Quest;
- quest pin + map;
- quest flag;
- mission.

Custom reward item IDs can also be tracked.

## 13. Options

General UI/output options include behavior such as:

- chat output;
- popup enablement;
- popup remember position;
- sorting;
- expansion/zone labels;
- minimap icon;
- refresh controls;
- War Mode behavior;
- hide-maxed reputation behavior.

### Refresh now

There is an explicit Settings refresh action.

It performs the same type of silent full rebuild used by settings refresh behavior.

## 14. Automatic debounced refresh

Settings that materially affect results should call:

```lua
WQA:ScheduleOptionsRefresh()
```

rather than directly starting multiple full scans.

The debouncer is intended to collapse rapid changes into one refresh.

## 15. Blizzard Settings category

`AceConfigDialog:AddToBlizOptions()` returns values including the category ID.

Store the numeric category ID and use it for:

```lua
Settings.OpenToCategory(categoryID)
```

Do not pass the string `"WQATurbo"` to `Settings.OpenToCategory()`.

## 16. Adding a setting

When adding a new option:

1. decide correct AceDB scope;
2. verify wildcard defaults before adding an explicit default;
3. add it to the correct Settings tree;
4. use a short label;
5. use a full-width description row/description where necessary;
6. wire setter to debounced refresh if it affects results;
7. document the path and semantics here;
8. add functional tests to the PR.

Long inline labels should be avoided because Blizzard Settings has constrained width.

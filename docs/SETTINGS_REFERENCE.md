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

Settings are built dynamically by `UI/Options.lua` and the feature builders in
`UI/Options/` (Custom, Tracking and Rewards), sharing one ordering counter.

Stable currency, reputation, emissary and World Quest type lookup metadata is
owned by `Data/RuntimeData.lua`. `UI/Options/Rewards.lua` reads those tables
while building the UI; loading Settings is not required to initialize runtime metadata.

Most setters call a debounced refresh scheduler so that configuration changes become visible without requiring `/reload`.

Settings page names, labels, descriptions, validation messages, bulk controls
and search output use the shared `WQA.L` locale table. English remains the
fallback for untranslated keys. The 1.4.0 localization expansion adds
Traditional Chinese and extends translated coverage for the reorganized UI.

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

Only achievements consume the character-only flag. Nested achievement
registration preserves an inherited character-only force so completed child
achievements are still evaluated for the selected character.
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
journal walk per collectible row. For pets, any positive species count means
collected; owning three copies is not required.

Tracking search accepts the displayed collectible name or primary ID and also
matches related source item IDs, mapped World Quest IDs, tracking quest IDs,
and nested achievement criterion names or IDs. The query remains temporary and
is not saved to the profile.

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

The actual Settings label structure should be verified in `UI/Options.lua`
and its feature builders under `UI/Options/`.

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
- Azerite Armor Cache on this character;
- Armor Cache;
- Weapon Cache;
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

`Azerite Armor Cache` is the profile-wide master setting. Its adjacent
`Azerite Armor Cache on this character` toggle is stored per character and is
enabled by default. Disable the character toggle when that character's armor
type is complete while leaving the master setting enabled for another armor
type. Both settings must be enabled for the cache to match.

Tortollan Trader's Stock is not tracked as a cache because its ring and trinket
outcomes do not provide collectible appearances.

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

An enabled purse is shown only while its own fixed manuscript pool contains an
uncollected customization. This completion filtering is automatic and does not
add another profile option.

## 8. Benthic gear — 1.1.0

No new Benthic-specific option is introduced.

Benthic tokens use:

```text
Rewards > Gear > Armor Cache
```

This keeps the user model simple: these are equipment-container/token rewards.

A Benthic token is automatically hidden when the appearances it can produce
for the active character's armor type are collected. A missing appearance for
another armor type does not keep the token visible because generated armor
follows the active loot specialization. A missing transmog API result for the
relevant pool keeps the token visible.

## 9. Reputation

Reputation pages are expansion-aware.

A faction can be explicitly enabled for tracking.

Optional behavior:

> Hide Exalted / max Renown reputations

The same control appears on World Quest and Mission Table reputation pages and
updates one shared profile setting. When enabled, maxed factions should
disappear from settings and be ignored for direct reputation, reputation-item
and reputation-currency matching in both World Quests and missions.

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

Since the 1.3.0 hardening change, saved editor values must be
positive integer IDs. Blank mission reward IDs remain optional; other invalid
values are rejected without changing the saved entry. Duplicate adds report an
error and preserve the existing entry, including its tracking toggle.

Supplied map IDs are stored as numbers and must resolve through
`C_Map.GetMapInfo()`. Quest Pin requires a map: set a valid map before changing
an existing entry to Quest Pin. Other quest types may leave the map blank.
Invalid edits report an error in chat and retain the previous saved value.

Successful adds, edits, toggles and deletes use the existing 0.30-second silent
Settings refresh debouncer. Rapid changes coalesce into one runtime rebuild;
an open popup updates as results become ready. Opening the editor does not
refresh runtime state. Deleting a quest removes its type and map controls too.
Existing SavedVariables are not migrated by this editor fix.

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

### Profile changes

Since 1.3.0, changing, copying or resetting an AceDB profile immediately
rebuilds results silently, clears old watched state and refreshes the minimap's
visibility and position from the new profile. An open popup is rebuilt; a closed
popup stays closed. The profile action supersedes queued Settings refreshes and
combat-deferred refreshes. Unlike automatic settings refreshes, this explicit
profile action rebuilds even in combat so the previous profile is not displayed.

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

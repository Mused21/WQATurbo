# File Map

This document explains the responsibility of each significant repository file/directory.

The source tree is grouped by responsibility while the compatibility core and
cross-cutting support modules remain at the repository root:

```text
Core.lua, Constants.lua, WQATurbo.lua
Data/                  stable lookup and expansion content
Tracking/              policy, achievements and collection state
Scanning/              dynamic reward discovery
Runtime/               orchestration, display and task publication
UI/                    tooltip and Settings UI
Criterias/, Rewards/, Items/
Migration.lua, Database.lua, Performance.lua, Utilities.lua, Locales.lua
```

The detailed entries below follow approximate TOC load order.

## Core and feature modules

### `Core.lua`

Creates the `WQATurbo` AceAddon object and foundational tables/namespaces.

Change when:

- adding a truly global namespace/state primitive;
- changing addon construction.

Avoid putting feature-specific logic here.

### `Constants.lua`

Canonical reward, criteria, task and tracking-mode strings under `WQA.Constants`.
Loaded immediately after `Core.lua`; content and SavedVariables values stay stable.

### `Tracking/TrackingPolicy.lua`

Shared tracking-mode flags, bulk-mode eligibility and exclusive-owner updates.
No collection API calls, scanning or refresh scheduling.

### `Tracking/ContainerCompletion.lua`

Evaluates fixed container pools through Blizzard quest and transmog collection
APIs. Unknown containers and unavailable collection data remain visible.

### `WQATurbo.lua`

Large compatibility/core implementation.

Contains important shared logic such as:

- AceDB defaults/initialization;
- reward-link acquisition/retry orchestration and focused reward classifiers;
- transmog state helpers;
- reputation item/currency lookup;
- mission logic;
- minimap data object;
- custom tracking draft defaults;
- the canonical `CreateQuestList()` rebuild and its collection-cache
  invalidation call.

### `Tracking/CollectionCache.lua`

Optimized mount/pet collection snapshot and ownership lookup logic shared by
runtime registration and Settings completion grouping. The module owns the
canonical `AddMounts()`, `AddPets()` and `AddToys()` implementations and
provides the ephemeral snapshot invalidation helper used by
`CreateQuestList()`.

Change when:

- optimizing collection journal access;
- adding supported collection cache dimensions.

Do not turn it into persistent SavedVariables.

### `Tracking/Custom.lua`

Runtime registration for enabled user-defined World Quests, Quest Flags,
Quest Pins and missions. Owns the canonical `AddCustom()` implementation.

Change when custom saved entries need different runtime registration behavior.
Editor validation and option-tree changes belong in `UI/Options/Custom.lua`.

### `Tracking/QuestAvailability.lua`

Quest Pin map readiness, request throttling and Quest Flag completion checks.
Owns `RefreshQuestPins()`, `isQuestPinActive()` and
`IsQuestFlaggedCompleted()`.

Change when custom Quest Pin or Quest Flag runtime availability changes.

### `Scanning/RewardScanner.lua`

Incremental frame-budgeted dynamic reward scanner.
Owns the canonical `Reward()` implementation.

Change only for scanner/discovery/readiness behavior.

Do not add ordinary item-ID classification rules here.

### `Scanning/EmissaryScanner.lua`

Emissary bounty discovery, reward-data retries and quest-log activity checks.
Owns the canonical `EmissaryReward()` and `EmissaryIsActive()` methods.

Change only for emissary discovery, readiness or active-state behavior.

### `Runtime/Runtime.lua`

Runtime/startup orchestration and modern command handling.

Responsibilities include:

- sole ownership of the optimized `OnEnable()`;
- startup scheduling;
- event orchestration;
- `/wqat` command dispatch;
- avoiding legacy broad preload behavior;
- leaving `Blizzard_GarrisonUI` load-on-demand while mission scans use the
  global `C_Garrison` API.

### `Runtime/Display.lua`

Cache-first display behavior and explicit refresh separation.

Responsibilities include:

- sole ownership of `Show()`;
- the canonical data refresh sequence used by `Refresh()`;
- cached display;
- explicit refresh;
- progressive open-popup rebuild;
- enrichment publication hooks.

### `Runtime/TaskResolver.lua`

Final task eligibility/readiness/publication.
Owns the canonical `CheckWQ()` implementation.

Responsibilities include:

- active checks;
- final WQ filtering;
- task link readiness;
- `activeTasks`;
- `newTasks`;
- display-mode publication;
- coalesced retries.

### `UI/Tooltip.lua`

LibQTip popup rendering and lifecycle.

Responsibilities include:

- create/update tooltip;
- scroll cap;
- expansion collapse;
- popup position;
- sort/display helpers;
- exact-object, idempotent release through `ReleaseQTip()`;
- canonical popup/LDB replacement through `RebuildQTip()`.

### `UI/Options.lua`

AceConfig tree orchestration, general Options pages, tab organization and
coalesced runtime refresh scheduling.

Feature owners under `UI/Options/`:

- `Shared.lua`: shared ordering counter and expansion sorting.
- `Tracking.lua`: tracking tree, search, bulk tracking and label retry timer.
- `Rewards.lua`: general and expansion reward builders.
- `Custom.lua`: custom editors, validation and mutations.

`tools/load_options.lua` loads these files in TOC order for Lua tests.
`tools/test_options_structure.lua` covers complete tree construction, search,
scoped writes and cross-feature coalescing, with optional baseline comparison.

### `Migration.lua`

Original WQAchievements migration.

Responsibilities include:

- raw SavedVariables capture;
- pre-AceDB migration;
- deep-copy;
- temporary original-addon enable/reload flow;
- migration prompt/state.

### `Database.lua`

Owns the active `WQATurboDB` schema version and ordered, idempotent migrations
that run after AceDB initialization. It currently normalizes the legacy custom
quest and custom reward table shapes while preserving canonical entries on ID
collisions.

### `Tracking/Achievements.lua`

Interprets declarative achievement data and registers relevant quest/POI/mission rewards.

### `Utilities.lua`

Shared utility functions and some quest-to-zone fallback mappings.

Includes mapping support such as Mechagon quest-zone cases and the cached,
fail-open Val/Naigtal availability resolution used by scanning and publication.

### `Locales.lua`

User-visible localization strings.

When adding/changing a UI label that uses locale lookup, update this file.

### `Performance.lua`

Performance instrumentation and diagnostics.

### `README.md`

Public project overview.

Keep concise; detailed maintainer documentation belongs under `docs/`.

### `CHANGELOG.md`

Release-facing change history consumed by packaging.

### `CREDITS.md`

Project/upstream credits.

Preserve WQAchievements/Urtgard attribution.

### `LICENSE.md`

Licensing information.

## Data

### `Data/Expansions/Legion.lua`
### `Data/Expansions/BattleForAzeroth.lua`
### `Data/Expansions/Shadowlands.lua`
### `Data/Expansions/Dragonflight.lua`
### `Data/Expansions/WarWithin.lua`
### `Data/Expansions/Midnight.lua`

Expansion-specific declarative content mappings.

Data can include:

- achievements;
- nested criteria;
- mount/pet/toy sources;
- faction restrictions;
- POI/pin metadata.

Do not put scanner loops or UI architecture here.

### `Data/Expansions.lua`

Expansion-index/name map.

### `Data/Zones.lua`

Expansion-index/map-ID scan list.

Adding a zone affects standard scanner coverage and Settings zone pages.

### `Data/RuntimeData.lua`

Stable shared lookup tables for currency IDs, reputation faction IDs,
emissary quest IDs, localized World Quest type labels and the Val/Naigtal
rotation anchor. Loaded before all runtime and Settings consumers. Preserves
`WQA.EmissaryQuestIDList` as an alias to the canonical emissary table.

### `Data/ContainerCollectibles.lua`

Fixed collectible pools for racing purses, Benthic armor tokens and verified
equipment caches. Stores account-wide manuscript quest IDs and item-modified
appearance source IDs; it contains no collection API calls.

## Criterias

### `Criterias/CriteriaType.lua`

Compatibility alias to `WQA.Constants.CriteriaType`; preserves `WQA.Criterias`.

### `Criterias/AreaPoi.lua`

Area POI reward registration/checking.

Maintains active/new/watched POI state and retry behavior.

## Rewards

### `Rewards/RewardType.lua`

Compatibility alias to `WQA.Constants.RewardType`; preserves `WQA.Rewards`.

### `Rewards/Reward.lua`

Canonical reward merge semantics.

### `Rewards/MatchReason.lua`

Formats the cached reward model into stable reason categories used by popup
task-name hover. Keep API queries and reward classification out of this file.

If new classification can fit an existing reward type, prefer doing so rather than inventing a parallel structure.

## Items

### `Items/Miscellaneous.lua`

Miscellaneous item/criteria registration helpers, currently focused on Area POI mappings.

## Packaging / libraries

### `WQATurbo.toc`

Addon manifest and load order.

Important rules:

- namespace/addon folder is `WQATurbo`;
- SavedVariables is `WQATurboDB`;
- version remains `@project-version@`;
- release automation owns actual version substitution.

Do not manually bump version.

### `embeds.xml`

Loads embedded library XML/Lua components.

### `.pkgmeta`

BigWigs/WowAce packager configuration.

Defines:

- package name;
- changelog source;
- externals;
- ignored development files.

### `Libs/`

Embedded third-party libraries populated by packager/externals.

Do not edit vendored library code for ordinary addon features.

## GitHub automation

### `.github/workflows/validate.yml`

PR validation:

- Lua syntax;
- BigWigs package build;
- embedded library validation;
- PR ZIP artifact.

### `.github/workflows/release.yml`

Automatic semantic version/release path.

See [RELEASE_AND_CI.md](RELEASE_AND_CI.md).

## Development/support

### `tools/`

Development tooling/scripts. Excluded from release package.

`validate_project.py` checks structure, startup load order and package hygiene.
`test_tracking_policy.lua` exercises tracking behavior and Val/Naigtal
availability with stubbed Blizzard APIs and runs under Lua 5.1 in the validation
workflow. `test_reward_classifier.lua`
checks representative reward categories, link fallbacks and retry propagation.
`test_reward_scanner.lua` checks coalesced publication after initial reward
inspection and completed item retries, including silent Settings publication
and inactive rotating-map exclusion.
`test_runtime_lifecycle.lua` checks Settings registration, startup timing,
event dispatch, combat recovery, War Mode refresh and mission updates.
`test_task_resolver.lua` checks progressive readiness, retry ownership, final
filtering and display-mode routing.
`test_tooltip_lifecycle.lua` checks exact ownership, stale callbacks,
idempotent cleanup and popup/LDB rebuild ordering, including POI hover metadata
loss and recovery. The core/classifier suite also covers Quest Pin readiness,
map-name fallback recovery and emissary/mission timeout IDs. Lifecycle tests
cover profile callbacks and minimap rebinding.
`test_custom_options.lua` checks input validation, duplicate protection,
control deletion and debounced refreshes through actual editor callbacks.

### `.gitignore`

Repository ignore rules.

### `.travis.yml`

Removed in 1.2 Step 2. GitHub Actions own validation and release; the project
validator rejects reintroducing this obsolete configuration.

## File ownership rule of thumb

```text
stable game-ID mapping          → Data/Expansions, Data/Zones, Data/RuntimeData
reward meaning/classification   → WQATurbo shared classifier / Rewards
scanner timing/readiness        → RewardScanner
task publication/readiness      → TaskResolver
display/cache opening           → Display
popup layout/lifecycle          → Tooltip
settings                         → Options
runtime scheduling/commands     → Runtime
collection API optimization     → CollectionCache
```

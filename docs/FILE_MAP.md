# File Map

This document explains the responsibility of each significant repository file/directory.

## Root runtime files

### `Core.lua`

Creates the `WQATurbo` AceAddon object and foundational tables/namespaces.

Change when:

- adding a truly global namespace/state primitive;
- changing addon construction.

Avoid putting feature-specific logic here.

### `Constants.lua`

Canonical reward, criteria, task and tracking-mode strings under `WQA.Constants`.
Loaded immediately after `Core.lua`; content and SavedVariables values stay stable.

### `TrackingPolicy.lua`

Shared tracking-mode flags, bulk-mode eligibility and exclusive-owner updates.
No collection API calls, scanning or refresh scheduling.

### `WQATurbo.lua`

Large compatibility/core implementation.

Contains important shared logic such as:

- AceDB defaults/initialization;
- reward classification;
- transmog state helpers;
- reputation item/currency lookup;
- mission logic;
- minimap data object;
- custom tracking helpers;
- compatibility implementations of runtime methods.

Important: several methods are overridden by later Turbo modules.

Always search the repo before assuming the definition here is active.

### `CollectionCache.lua`

Optimized mount/pet collection snapshot and ownership lookup logic shared by
runtime registration and Settings completion grouping.

Change when:

- optimizing collection journal access;
- adding supported collection cache dimensions.

Do not turn it into persistent SavedVariables.

### `RewardScanner.lua`

Incremental frame-budgeted dynamic reward scanner.

Change only for scanner/discovery/readiness behavior.

Do not add ordinary item-ID classification rules here.

### `TurboRuntime.lua`

Runtime/startup orchestration and modern command handling.

Responsibilities include:

- optimized `OnEnable`;
- startup scheduling;
- event orchestration;
- `/wqat` command dispatch;
- avoiding legacy broad preload behavior.

### `TurboDisplay.lua`

Cache-first display behavior and explicit refresh separation.

Responsibilities include:

- cached display;
- explicit refresh;
- progressive open-popup rebuild;
- enrichment publication hooks.

### `TurboCheck.lua`

Final task eligibility/readiness/publication.

Responsibilities include:

- active checks;
- final WQ filtering;
- task link readiness;
- `activeTasks`;
- `newTasks`;
- display-mode publication;
- coalesced retries.

### `Tooltip.lua`

LibQTip popup rendering and lifecycle.

Responsibilities include:

- create/update tooltip;
- scroll cap;
- expansion collapse;
- popup position;
- sort/display helpers;
- safe release/rebuild.

### `Options.lua`

AceConfig settings UI.

Responsibilities include:

- Tracking tree;
- search;
- bulk tracking;
- Rewards tree;
- Custom tree;
- Options tree;
- refresh scheduling in setters.

### `Migration.lua`

Original WQAchievements migration.

Responsibilities include:

- raw SavedVariables capture;
- pre-AceDB migration;
- deep-copy;
- temporary original-addon enable/reload flow;
- migration prompt/state.

### `Achievements.lua`

Interprets declarative achievement data and registers relevant quest/POI/mission rewards.

### `Utilities.lua`

Shared utility functions and some quest-to-zone fallback mappings.

Includes mapping support such as Mechagon quest-zone cases.

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

## DB

### `DB/Data/Legion.lua`
### `DB/Data/BattleForAzeroth.lua`
### `DB/Data/Shadowlands.lua`
### `DB/Data/Dragonflight.lua`
### `DB/Data/WarWithin.lua`
### `DB/Data/Midnight.lua`

Expansion-specific declarative content mappings.

Data can include:

- achievements;
- nested criteria;
- mount/pet/toy sources;
- faction restrictions;
- POI/pin metadata.

Do not put scanner loops or UI architecture here.

### `DB/Expansions.lua`

Expansion-index/name map.

### `DB/Zones.lua`

Expansion-index/map-ID scan list.

Adding a zone affects standard scanner coverage and Settings zone pages.

### `DB/RuntimeData.lua`

Stable shared lookup tables for currency IDs, reputation faction IDs,
emissary quest IDs and localized World Quest type labels. Loaded before all
runtime and Settings consumers. Preserves `WQA.EmissaryQuestIDList` as an alias
to the canonical emissary table.

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
`test_tracking_policy.lua` exercises tracking behavior with stubbed Blizzard APIs
and runs under Lua 5.1 in the validation workflow.

### `.gitignore`

Repository ignore rules.

### `.travis.yml`

Removed in 1.2 Step 2. GitHub Actions own validation and release; the project
validator rejects reintroducing this obsolete configuration.

## File ownership rule of thumb

```text
stable game-ID mapping          → DB/Data, DB/Zones, DB/RuntimeData
reward meaning/classification   → WQATurbo shared classifier / Rewards
scanner timing/readiness        → RewardScanner
task publication/readiness      → TurboCheck
display/cache opening           → TurboDisplay
popup layout/lifecycle          → Tooltip
settings                         → Options
runtime scheduling/commands     → TurboRuntime
collection API optimization     → CollectionCache
```

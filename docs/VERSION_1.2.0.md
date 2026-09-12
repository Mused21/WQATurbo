# WQA Turbo 1.2.0 Refactor

## Goal

Make the codebase easier to understand, test and maintain while preserving
the functionality and performance characteristics of 1.1.0.

Avoid large rewrites. Refactor incrementally with validation after each step.

## Current Branch

`refactor/1.2.0`

## Baseline

1.1.0 functionality has been merged to master.

## Completed

### Step 1 — Refactor guardrails

Completed and CI passed.

Added:

- `tools/validate_project.py`
- project structure validation
- TOC validation
- package-content validation
- known criteria/faction validation
- backup/temp artifact validation
- `docs/` package exclusion

Commit at the start of Step 2:

`b6899c1`

### Step 2 — Safe cleanup

Status: IMPLEMENTED; local checks pass and in-game smoke testing reports no errors so far.

Two generated patch scripts were reported to have failed because their remote
source matching was too strict and to have restored their backups. Before the
direct edits, all tracked Step 2 source files matched `b6899c1`. The remaining
local changes were an `AGENTS.md` exclusion in `.pkgmeta` and untracked
`AGENTS.md` and `docs/VERSION_1.2.0.md`; `AGENTS.override.md` was ignored.
This supports code rollback, but does not prove restoration of every pre-run
local change without the scripts' original snapshots.

Do not use those patch installers again.

Step 2 was applied directly to the local files through Codex.

Applied behavior-preserving cleanup:

- removed obsolete `.travis.yml`;
- changed enum initialization to `WQA.Criterias.CriteriaType` and
  `WQA.Rewards.RewardType` field assignments, preserving the namespaces
  already initialized by `Core.lua`;
- made the Utilities-only `ExpansionByZoneID` table local;
- removed commented caching/control-flow fragments in `GetQuestZoneID`,
  `GetExpansionByQuestID` and `GetTaskLink`;
- removed obsolete commented `customReward`, `CheckWQ`, `AddMiscellaneous`,
  recipe debug-print and sorting-return statements in `WQATurbo.lua`, including
  the empty `data.miscellaneous` conditional around the disabled call;
- removed the unused `upgradeSum` accumulator declaration and all three
  accumulation statements, preserving cache eligibility and upgrade metadata;
- removed the unreferenced `CraftingReagentIDList` table in `UI/Options.lua` and
  disabled crafting-reagent classifier block in `WQATurbo.lua`, retaining the
  `craftingreagent` SavedVariables default;
- promoted enum namespace-replacement warnings to validation errors, rejected
  obsolete Travis configuration, and enforced the existing `AGENTS.md`
  package exclusion, including checks for leaked files in packaged ZIPs.

Correctness fixes and inherited runtime implementation consolidation remain
outside this step. `CheckReward` remains owned by `WQATurbo.lua`; scanner
architecture, tracking semantics and SavedVariables schema are unchanged.

Local validation:

- `python tools/validate_project.py`: passed, zero errors and warnings;
- `git diff --check`: passed; actual Git diff reviewed;
- validator negative checks passed for namespace replacement, missing
  `AGENTS.md` exclusion, restored Travis configuration and both forbidden
  package files, using temporary fixtures;
- Lua 5.1.5 syntax checks passed for all 27 tracked Lua files. The compiler was
  built from the official Lua source archive after SHA-256 verification and
  installed at `%LOCALAPPDATA%\Programs\Lua\5.1.5\luac5.1.exe`;
- In-game smoke test reported working without errors so far; full regression
  coverage and GitHub Actions remain pending.

Repeat the local syntax check from PowerShell at the repository root:

```powershell
$luaCompiler = Join-Path $env:LOCALAPPDATA 'Programs/Lua/5.1.5/luac5.1.exe'
foreach ($luaFile in (rg --files --hidden -g '*.lua' -g '!Libs/**' -g '!.git/**' -g '!.release/**')) {
    & $luaCompiler -p $luaFile
    if ($LASTEXITCODE -ne 0) { throw "Lua syntax check failed: $luaFile" }
}
```

### Step 3 — Constants and tracking policy

Status: IMPLEMENTED; local checks pass and in-game smoke testing reports no errors so far.

- Added `Constants.lua` after `Core.lua`, defining RewardType, all eight
  CriteriaType values, TaskType and TrackingMode under `WQA.Constants`.
- Retained existing reward/criteria enum modules as namespace-preserving aliases.
  SavedVariables values and declarative data strings remain unchanged.
- Added `Tracking/TrackingPolicy.lua` for mode eligibility/force flags, bulk eligibility
  and exclusive-owner writes. Registration paths and Settings share these rules;
  completion checks and refresh scheduling remain in their existing owners.
- Replaced runtime reward/task/criteria/mode literals with constants. Scanner,
  publication, tooltip and utility changes are equivalent constant substitutions.
- Preserved special quest-count achievement behavior (disabled-only mode gate),
  the existing inherited `forcedByMe` reset and collectible character-only-mode
  behavior during Step 3. The inherited reset was corrected in the later
  pre-release cleanup.
- Added `tools/test_tracking_policy.lua` and wired it into validation CI.
  Added validator guards for startup order and required new package modules.

Validation: Lua 5.1 syntax checks and local project validation pass. Tracking
regression checks pass against both the saved Step 2 registration/Settings source
and Step 3. The developer reports Step 3 working without bugs so far in game.
Full in-game regression coverage and remote CI remain pending.

### Step 4 — Move runtime data out of UI/Options.lua

Status: IMPLEMENTED; local checks pass and in-game smoke testing reports no
bugs so far.

- Added `Data/RuntimeData.lua` as the source of truth for stable currency,
  reputation, emissary and World Quest type lookup metadata.
- Loaded the module before `Utilities.lua`, `WQATurbo.lua` and `UI/Options.lua`.
  These consumers no longer depend on `UI/Options.lua` creating runtime data.
- Preserved `WQA.EmissaryQuestIDList` as an alias to the canonical emissary
  table for compatibility.
- Kept Settings-only hierarchy, ordering and bulk-label metadata in
  `UI/Options.lua`.
- Added validator guards for the required module, package content and load
  order, plus Lua regression assertions for the new namespace and alias.
- Updated architecture, file ownership, data-model, Settings and development
  documentation.

Validation: project validation passes with zero errors and warnings; the Lua
5.1 regression test passes; Lua 5.1 syntax checks pass for all 31 project Lua
files; `git diff --check` passes. A recursive table comparison confirmed that
all moved runtime metadata exactly matches its `HEAD` definitions in
`UI/Options.lua`. The developer reports Step 4 working without bugs so far in
game. Broader in-game regression coverage and remote CI remain pending.

### Step 5 — Settings collection performance

Status: IMPLEMENTED; local checks pass and in-game testing reports no bugs so
far.

- Added cache-backed mount and pet ownership query helpers to
  `Tracking/CollectionCache.lua`.
- Replaced the full Mount Journal and Pet Journal loops in
  `IsTrackedObjectCompleted()` with constant-time shared-cache lookups.
- Preserved the existing cache lifecycle: snapshots remain ephemeral and are
  rebuilt on a `CreateQuestList()` refresh.
- Added regression coverage proving repeated Settings ownership checks build
  each journal snapshot only once.
- Updated architecture, performance, data-model, Settings, file-map and test
  documentation.

Validation: project validation passes with zero errors and warnings; the Lua
5.1 regression test confirms Settings ownership queries reuse one snapshot per
journal; Lua 5.1 syntax checks pass for all 31 project Lua files; and
`git diff --check` passes. The developer reports Step 5 working without bugs
so far in game. Remote CI and broader regression coverage remain pending.

### Step 6 — Reward classifier decomposition

Status: IMPLEMENTED; local checks pass and in-game testing reports the
classifier and popup-enrichment behavior working correctly.

- Kept `CheckReward()` as the single active owner in `WQATurbo.lua` and reduced
  it to authoritative item-link acquisition plus retry orchestration.
- Extracted focused local classifiers for containers, gear upgrades, equipment
  caches, transmog, reputation items, recipes, known/custom items and legacy
  Azerite/conduit behavior.
- Preserved classifier order, cache eligibility, reward merge calls and retry
  aggregation. The documented StatWeightScore expression remained unchanged
  during Step 6 and was corrected in the later pre-release cleanup.
- Preserved `Scanning/RewardScanner.lua`'s frame budget and per-quest pending model.
  In-game verification exposed that its initial item/currency/profession pass
  did not dirty the publication batch, leaving an open popup at its static
  achievement-only state until reopen. Initial reward inspection and completed
  item retries now request one coalesced publication at the end of their batch,
  retaining silent publication mode for Settings-triggered scans.
- Added `tools/test_reward_classifier.lua` and `tools/test_reward_scanner.lua`,
  wired them into validation CI and required them in project validation.
- Updated architecture, performance, development, testing, file-map, CI and
  version documentation.

Validation: project validation passes with zero errors and warnings; tracking,
reward-classifier and reward-scanner regression suites pass; the reward suite
also passes against the committed Step 5 `WQATurbo.lua` baseline; Lua 5.1
syntax checks pass for all 33 project Lua files; and `git diff --check` passes.
Remote CI remains pending.

### Step 7 — Tooltip lifecycle centralization

Status: IMPLEMENTED; local checks pass and in-game testing reports the popup
lifecycle working correctly.

- Added `ReleaseQTip()` in `UI/Tooltip.lua` as the only direct LibQTip release and
  `WQA.tooltip` detachment owner.
- Required exact tooltip identity, detached shared state before release,
  cleared attached quests/missions/POIs and made repeated/stale release calls
  safe.
- Added `RebuildQTip()` for popup and LDB replacement. Expansion collapse,
  progressive popup refresh and transient LDB rebuilding now share it.
- Routed popup `OnHide` and delayed LDB auto-hide through `ReleaseQTip()`.
  Tooltip `OnHide` ignores stale instances before hiding the popup.
- Stored the popup's exact tooltip reference so a delayed hide cannot release a
  newer instance.
- Added `tools/test_tooltip_lifecycle.lua`, validation guards enforcing the
  canonical owner, CI coverage and lifecycle documentation.

Validation: project validation passes with zero errors and warnings; tracking,
reward-classifier, reward-scanner and tooltip-lifecycle regression suites pass;
Lua 5.1 syntax checks pass for all 34 project Lua files; and `git diff --check`
passes. The developer reports Step 7 working in game. Remote CI remains
pending.

### Repository organization before Step 8

Status: IMPLEMENTED; local checks pass and in-game smoke testing reports the
reorganized addon working correctly.

- Grouped stable lookup and expansion content under `Data/`, tracking policy
  and collection/achievement registration under `Tracking/`, reward discovery
  under `Scanning/`, runtime overrides under `Runtime/`, and user-interface
  modules under `UI/`.
- Renamed the three specialized runtime-module filenames to their actual
  responsibilities:
  `Runtime/Runtime.lua`, `Runtime/Display.lua` and
  `Runtime/TaskResolver.lua`.
- Preserved every Lua implementation and retained the exact TOC load order;
  the only source edits remove three pre-existing trailing-whitespace fragments.
- Updated the TOC, local tests, structural/package validation and maintainer
  documentation for the new paths.
- Removed the unused hard-coded `0.1.0-beta` conversion builder; current CI and
  releases already use the BigWigs packager.

Validation: project validation, all four Lua regression suites, Lua 5.1 syntax
checks for all 34 project Lua files and `git diff --check` pass. The developer
reports the reorganized addon working nicely in game. Remote CI remains
pending.

## Final Refactor Step

### Step 8 — Runtime override consolidation

Status: COMPLETED; the runtime consolidations, Mission Table reputation
control, and direct `CreateQuestList()` cache invalidation passed focused
in-game smoke testing.

- Moved the established data-refresh sequence from the compatibility-core
  `Show()` into a private helper in `Runtime/Display.lua`.
- Kept cache-first popup/LDB display, first-access fallback, combat deferral,
  refresh-mode propagation and performance wrapping unchanged.
- Removed the earlier `WQATurbo.lua` definition. `Runtime/Display.lua` is now
  the only `Show()` owner.
- Expanded the reward-scanner/display regression test and added a validator
  guard that rejects zero or multiple `Show()` owners.
- Removed the compatibility-core `OnEnable()` implementation, including its
  obsolete global reward preload and whole-scan retry branches.
- Kept `Runtime/Runtime.lua` as the sole lifecycle owner and preserved Settings
  registration, migration scheduling, startup timing, combat recovery, quest
  completion, War Mode refresh, mission updates and the `/wqa` compatibility
  registration.
- Added `tools/test_runtime_lifecycle.lua`, CI coverage and a validator guard
  enforcing the single `OnEnable()` owner.
- Removed the compatibility-core `AddMounts()` implementation.
  `Tracking/CollectionCache.lua` is now the sole owner and retains the existing
  one-snapshot-per-refresh optimization and tracking semantics.
- Kept optional comparisons with older checkout baselines in the tracking test
  while making current-source coverage independent of the removed method.
- Added a validator guard enforcing the single `AddMounts()` owner.
- Removed the compatibility-core `AddPets()` implementation.
  `Tracking/CollectionCache.lua` is now the sole owner and retains the existing
  one-snapshot-per-refresh optimization, duplicate companion handling and
  tracking semantics.
- Added a current-source regression assertion and validator guard enforcing the
  single `AddPets()` owner.
- Removed the compatibility-core `CheckWQ()` implementation and its now-unused
  cached `C_TaskQuest.IsActive` reference. `Runtime/TaskResolver.lua` is now the
  sole owner; its progressive per-task readiness and coalesced retry behavior
  remain unchanged.
- Added `tools/test_task_resolver.lua`, CI coverage, a current-source assertion
  and a validator guard enforcing the single `CheckWQ()` owner.
- Separately fixed the confirmed empty Mission Table reputation-page case by
  exposing the existing shared hide-maxed control there. World Quest and
  Mission Table reputation pages now update the same profile setting.
- Removed the compatibility-core `Reward()` implementation, its unused cached
  quest-tag API reference, the duplicate preload-skip table and legacy broad
  retry diagnostics. Shared reward classifiers and mission helpers remain in
  `WQATurbo.lua`.
- `Scanning/RewardScanner.lua` is now the sole `Reward()` owner and retains the
  existing frame-budgeted discovery, bounded retries and progressive
  publication behavior.
- Added current-source and validator guards enforcing the single `Reward()`
  owner. The reward-scanner regression suite exercises the canonical method.
- Moved collection-cache invalidation into the core `CreateQuestList()` method
  and removed the `Tracking/CollectionCache.lua` load-order wrapper.
- Added regression and validator guards enforcing `WQATurbo.lua` as the sole
  `CreateQuestList()` owner and exactly one cache invalidation per rebuild.

Validation at the completed Step 8 checkpoint: project validation, all six Lua
regression suites, Lua 5.1 syntax checks for all 36 project Lua files and
`git diff --check` pass. The developer reports the complete Step 8 path working
in game. Remote CI remains pending.

Step 8 now has one source owner for every consolidated runtime method; no
load-order method wrapper remains.

## Refactor Completion

The planned 1.2.0 refactor steps are complete. Remaining work is release
preparation: run remote CI and its executable Lua suites, complete a broad
in-game regression pass, and verify the packaged ZIP.

## Pre-release Correctness Cleanup

Status: COMPLETED; focused local regression checks and in-game testing pass.

- Corrected StatWeightScore's dual-slot comparison so it uses the lower
  equipped score when calculating a reward's percentage upgrade.
- Preserved inherited character-only forcing while registering nested
  achievement criteria.
- Changed `QUEST_PIN` registration to skip a criterion with no quest ID while
  continuing through valid later criteria.
- Stored the numeric Blizzard Settings category ID returned by
  `AceConfigDialog:AddToBlizOptions()` so minimap right-click uses the intended
  `Settings.OpenToCategory()` path.
- Expanded the tracking, reward-classifier and runtime-lifecycle regression
  suites for these cases.
- Built the Lua 5.1.5 interpreter from the official source archive after
  verifying SHA-256
  `2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333`,
  and installed it beside the existing compiler under
  `%LOCALAPPDATA%\Programs\Lua\5.1.5`.

Validation: project validation, all six Lua regression suites, Lua 5.1 syntax
checks for all 36 project Lua files and `git diff --check` pass. The tracking
and reward-classifier suites also pass in comparison mode against the
pre-cleanup `bb51a8c` source, confirming the intended behavior differences.
The developer reports all four corrections working in game.

## Non-goals for 1.2 Refactor

Unless separately requested:

- do not redesign RewardScanner;
- do not redesign SavedVariables;
- do not implement dynamic reward stale-while-revalidate cache;
- do not revisit Abomination Stitchyard experiments;
- do not change normal tracking semantics;
- do not add major new user-facing features.

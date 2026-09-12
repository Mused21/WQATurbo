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
- removed the unreferenced `CraftingReagentIDList` table in `Options.lua` and
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

## Current Step

### Step 3 — Constants and tracking policy

Status: IMPLEMENTED; local checks pass and in-game smoke testing reports no errors so far.

- Added `Constants.lua` after `Core.lua`, defining RewardType, all eight
  CriteriaType values, TaskType and TrackingMode under `WQA.Constants`.
- Retained existing reward/criteria enum modules as namespace-preserving aliases.
  SavedVariables values and declarative data strings remain unchanged.
- Added `TrackingPolicy.lua` for mode eligibility/force flags, bulk eligibility
  and exclusive-owner writes. Registration paths and Settings share these rules;
  completion checks and refresh scheduling remain in their existing owners.
- Replaced runtime reward/task/criteria/mode literals with constants. Scanner,
  publication, tooltip and utility changes are equivalent constant substitutions.
- Preserved special quest-count achievement behavior (disabled-only mode gate),
  the existing inherited `forcedByMe` reset and collectible character-only-mode
  behavior. Correctness changes remain deferred.
- Added `tools/test_tracking_policy.lua` and wired it into validation CI.
  Added validator guards for startup order and required new package modules.

Validation: Lua 5.1 syntax checks and local project validation pass. Tracking
regression checks pass against both the saved Step 2 registration/Settings source
and Step 3. The developer reports Step 3 working without bugs so far in game.
Full in-game regression coverage and remote CI remain pending.

## Planned Next Steps

### Step 4 — Move runtime data out of Options.lua

Separate stable content/runtime metadata from Settings UI construction.

Likely candidates:

- emissary data
- reputation data
- reward/category metadata

### Step 5 — Settings collection performance

Replace repeated mount/pet journal scans from Settings construction with
shared indexed collection state.

### Step 6 — Reward classifier decomposition

Keep RewardScanner architecture unchanged.

Split the large CheckReward path into focused classifiers such as:

- gear upgrades
- equipment caches
- containers
- transmog
- reputation items
- recipes
- known/custom items
- legacy Azerite/conduit behavior

### Step 7 — Tooltip lifecycle centralization

Create one canonical safe QTip release/rebuild path.

### Step 8 — Runtime override consolidation

Gradually remove inherited/overridden duplicate implementations.

Target: one authoritative implementation of major runtime methods.

Do this one function at a time with behavior checks.

## Separate Correctness Issues

Do not silently fix these during refactoring.

Investigate separately with dedicated reproduction/tests:

- StatWeightScore operator-precedence behavior;
- achievement `forcedByMe` propagation;
- `QUEST_PIN` early return on missing criterion quest ID;
- any remaining numeric Blizzard Settings category ID issue needs a specific
  reproduction: minimap right-click already calls
  `Settings.OpenToCategory(WQA.optionsCategoryID)` in the local baseline.

## Non-goals for 1.2 Refactor

Unless separately requested:

- do not redesign RewardScanner;
- do not redesign SavedVariables;
- do not implement dynamic reward stale-while-revalidate cache;
- do not revisit Abomination Stitchyard experiments;
- do not change normal tracking semantics;
- do not add major new user-facing features.

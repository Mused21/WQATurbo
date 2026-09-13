# WQA Turbo — Agent Instructions

## Project

WQA Turbo is a performance-focused continuation of WQAchievements for
World of Warcraft Retail.

Repository:
https://github.com/Mused21/WQATurbo

The addon is Lua 5.1 / World of Warcraft Retail.

Before modifying code, read:

- `docs/README.md`
- `docs/ARCHITECTURE.md`
- `docs/INVARIANTS_AND_REGRESSION_GUARDS.md`
- `docs/SCANNING_AND_PERFORMANCE.md`
- `docs/ROADMAP.md`
- `docs/VERSION_1.2.0.md`

Read additional files under `docs/` when relevant to the task.

The repository documentation is the project system of record.
If implementation and documentation diverge, identify the discrepancy and
update the appropriate documentation as part of the change.

## Current Development

Current development target: WQA Turbo 1.3.0.

1.1.0 functionality is the behavioral baseline.

1.3.0 combines the tested post-release hardening with maintainability,
performance, feature and data work from the roadmap. Preserve existing
behavior except for explicitly planned fixes and features.

The active work queue, current milestone, and completion criteria are
documented in:

`docs/ROADMAP.md`

Always inspect that file before planning or starting follow-up work, and
update its status when a roadmap item is completed or reprioritized.

The completed 1.2.0 plan and release preparation remain documented in:

`docs/VERSION_1.2.0.md`

## Critical Architecture Rule

Step 8 consolidated the major runtime entry points so each has one source
owner. Specialized modules still depend on the exact TOC load order, and
`Performance.lua` instruments selected methods after their owners load.

Before modifying any WQA method:

1. Search the entire repository for every definition/assignment.
2. Inspect `WQATurbo.toc` load order.
3. Confirm the single runtime owner and its dependencies.
4. Modify that owner and preserve any later performance instrumentation.

Never assume the first definition found is authoritative.

## Performance Invariants

Do not regress the optimized runtime architecture.

In particular:

- Do not replace the frame-budgeted incremental reward scanner.
- Do not globally rescan all maps because one quest/reward/item is pending.
- Pending reward retries must remain per quest.
- Static relevance must become usable without waiting for dynamic rewards.
- Collection journals should be indexed once per refresh rather than
  repeatedly scanned.
- `/wqat` and normal minimap left-click are cache-first.
- Settings bulk changes should coalesce into one debounced refresh.
- Do not redesign `Scanning/RewardScanner.lua` unless a demonstrated bug requires it.

## Popup / Tooltip Invariants

LibQTip lifecycle handling is safety-critical.

A stale callback must never release a newer tooltip.

When releasing/rebuilding a tooltip:

- verify ownership of the exact tooltip object;
- clear the global reference before release;
- clear attached quests/missions/POIs;
- make cleanup idempotent.

Do not reintroduce the historical tooltip race.

## Transmog Invariants

Blizzard transmog APIs are authoritative.

AllTheThings and CanIMogIt may provide display icons only.

Preserve the semantic distinction between:

- Unknown appearance
- Unknown source

Overall appearance ownership must be determined by checking all appearance
sources, not only `appearanceIsCollected` from one source.

## Reward Classification

Prefer:

`RewardScanner = when/how to inspect`
`reward classifier = what a reward means`

Do not put ordinary item-ID/category special cases into `Scanning/RewardScanner.lua`.

Use `AddRewardToQuest()` / canonical reward merge behavior instead of
manually constructing parallel quest reward structures.

## 1.1.0 Behavior That Must Remain

- Shift+Left-click minimap:
  1. open cached popup;
  2. start silent refresh;
  3. progressively update the open popup.

- Dragonflight racing reward containers are supported.

- Nazjatar Benthic tokens are handled by Armor Cache tracking.

- Azerite Armor Cache and recognized Armor/Weapon/Jewelry caches are tracked
  when their category is enabled, regardless of whether their obsolete item
  level is an upgrade.

Upgrade calculations are supplemental metadata, not cache eligibility.

## SavedVariables / Release

SavedVariables:
`WQATurboDB`

Original migration source:
`WQADB`

Do not manually change the TOC version.

Keep:

`## Version: @project-version@`

Release automation owns semantic version substitution and tagging.

Do not enable another CurseForge webhook/release path without reviewing
`docs/RELEASE_AND_CI.md`.

## Editing Workflow

Work directly on the local repository files.

Do not generate patch ZIPs/installers unless explicitly requested.

Before modifying files:

- inspect `git status`;
- inspect current branch;
- inspect relevant source and docs;
- explain the intended change briefly if it has architectural impact.

Prefer small, reviewable changes.

Do not combine unrelated correctness fixes with behavior-preserving refactors.

Do not automatically commit, push, merge, tag, or create releases unless the
user explicitly asks.

## Validation

After code changes run:

```powershell
python .\tools\validate_project.py
git diff --check
git diff
git status

Run Lua syntax validation when available.

For performance-sensitive changes also inspect in game:

/wqat scan
/wqat perf

Before commit, review:

```powershell
git diff --cached --check
git diff --cached
git status

## Documentation

Architecture, behavior, settings, data-model, release, or invariant changes
must update the corresponding file under docs/.

Update docs/ROADMAP.md as roadmap items are completed or reprioritized.
Treat released version plans such as docs/VERSION_1.2.0.md as historical
records rather than active checklists.

Do not put transient experiments into the architecture docs as shipped
functionality. Clearly mark research-only or unshipped behavior.

## External Research

For WoW API behavior that may have changed:

- use internet research when available;
- prefer current Blizzard documentation and Warcraft Wiki;
- use Wowhead for item/quest/content IDs and reward/source verification;
- use GitHub/current addon sources when verifying real-world API usage;
- distinguish documented API behavior from inference;
- verify Retail/current-patch relevance before modifying code;
- do not copy implementation patterns blindly from outdated addons.

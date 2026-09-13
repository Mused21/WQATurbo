# WQA Turbo Development Roadmap

> **Current release target:** 1.3.0
>
> **Released baseline:** 1.2.0
>
> **Current milestone:** 1.3.0 consolidated release
>
> **Current item:** Split the options implementation by feature area (Next)
>
> **Last reviewed:** 2026-09-13

This is the active work queue for WQA Turbo. Read it before planning or
starting follow-up work. Update the current item and status in the same change
that completes or reprioritizes roadmap work. Released version documents are
historical records and must not be reused as active checklists.

## Status definitions

- **Next**: the next item to implement.
- **In progress**: implementation or required verification is underway.
- **Queued**: accepted work with lower priority or a dependency on earlier work.
- **Research**: requires current API or game-data evidence before implementation.
- **Done**: implemented, locally validated, and tested in game where applicable.

## 1.3.0: completed correctness and runtime hardening

There will be no separate 1.2.1 release. Version 1.3.0 includes the tested
hardening below plus every maintainability, performance, feature and data item
listed in this roadmap. The developer approved this consolidated scope and
reported the hardening batch working in game on 2026-09-13.

Work in reviewable increments, with related changes bundled for in-game testing
when useful. Run local validation and inspect each diff before presenting it.
Research items are part of the 1.3.0 work queue, but their implementation remains
conditional on current API/content evidence; record findings and any explicit
scope decision rather than promising unsupported behavior.

Implementation order: finish the options split, then reduce the compatibility
core and strengthen migration/tests/tooling; proceed through performance work,
then feature and data work. Evidence-gated items retain their research status
until the necessary API, content or profiling evidence is available.

| Status | Priority | Work item | Completion criteria |
|---|---:|---|---|
| **Done** | P0 | Custom editor validation and refresh correctness | Custom quest, reward, mission, and mission-reward IDs accept only positive integers; Quest Pin map IDs are normalized and required; invalid input cannot cause a nil-key error or silently overwrite an entry; successful add, edit, toggle, and delete operations schedule one runtime refresh; focused automated and in-game checks pass. |
| **Done** | P0 | Quest Pin asynchronous readiness | Quest-line API results are handled when data is temporarily unavailable; no nil iteration is possible; pending maps retry with a bounded policy; ready maps continue without being blocked by unrelated pending maps. |
| **Done** | P0 | Transient map and POI metadata safety | Missing `C_Map.GetMapInfo()` and `C_AreaPoiInfo.GetAreaPOIInfo()` results cannot cause errors; affected entries remain retryable or degrade to safe fallback text. |
| **Done** | P1 | AceDB profile lifecycle refresh | Profile changed, copied, and reset callbacks rebuild runtime state, refresh the minimap/display state, and cannot leave options or the popup showing the previous profile. |
| **Done** | P1 | Task and emissary timeout diagnostics | Readiness timeouts identify the unresolved task class and IDs through existing diagnostics without adding normal-play chat noise. |

### Item 1 verification

Custom editor validation and refresh correctness is implemented locally.
Project validation (zero errors/warnings), all seven Lua regression suites,
Lua 5.1 syntax checks and diff whitespace checks pass. The developer reported
the in-game result as good on 2026-09-13; this item is **Done**.
This tested checkpoint is approved for a local commit; push/release is not authorized.

Focused in-game checks:

- Try blank, text, zero, negative and fractional IDs in all four editors;
  rejected adds must not create entries or alter existing ones.
- Re-add an existing ID, including leading zeros; its settings must survive.
- Add/edit Quest Pin maps; reject blank or unknown maps and require a valid
  map before switching an existing quest to Quest Pin.
- Add/edit a mission with a blank optional reward, then a positive reward ID;
  invalid reward edits must retain the previous saved value.
- Add, toggle and delete each entry kind; edit quest types/maps and mission
  rewards/types. An open popup must update silently after the debounce;
  a closed popup must stay closed. Repeat rapid changes and combat deferral.
- Delete a quest and verify its map/type controls disappear; reopen Settings
  and reload the UI to verify saved valid values persist.
- Check `/wqat scan` and `/wqat perf` for unexpected repeated scans; ordinary
  popup opening and Settings navigation must remain cache-first/lightweight.

### Remaining hardening verification

Implementation is local. Project validation passes with zero errors/warnings;
all seven Lua suites, syntax checks for 39 Lua files and diff whitespace checks
pass. The complete combined diff has been reviewed. The developer confirmed
the combined in-game test works on 2026-09-13; all five hardening items are
**Done**. The regression checklist remains below for the final 1.3.0 pass:

- Quest Pin: open a tracked pin area after login/refresh. Available pins should
  appear without waiting for other maps; rapid refreshes must not cause errors.
- Metadata: hover POIs and show zone names immediately after login, zoning and
  refresh. Missing names may show an ID fallback; later hovers/renders recover.
- Profiles: prepare two profiles with different tracked tasks, minimap visibility
  and minimap position. Change profiles, copy one into the current profile and
  reset it. Confirm options, minimap and an already-open popup use the new values.
- Repeat profile changes with the popup closed, during pending enrichment and
  in combat with automatic combat deferral enabled. No previous-profile rows or
  delayed chat announcements should return; a closed popup must stay closed.
- Diagnostics: inspect `/wqat scan` and `/wqat perf`, including after waiting
  over 30 seconds for unavailable data. Pending/timeout records identify task
  classes and IDs, with no automatic chat noise. Refresh clears old snapshots.
- Regression: repeat custom editor checks, normal minimap opening, Shift-click
  refresh, mission-table updates and representative achievement/reward tracking.

### 1.3.0 release gate

- Every included roadmap item is marked **Done** or explicitly moved to a later
  milestone with an explicit scope decision and reason.
- Research/profiling conclusions are recorded, including unsupported proposals.
- The release PR uses `release:minor` to advance the released 1.2.0 to 1.3.0;
  leave the TOC version placeholder and release automation unchanged.
- `python .\tools\validate_project.py` passes.
- All standalone Lua test suites pass with the supported local interpreter.
- `git diff --check` passes and the final diff is reviewed.
- The focused in-game checklist for every changed runtime path passes.
- Version, changelog, packaging, and release documentation are consistent.

## 1.3.0: maintainability and test coverage

| Status | Priority | Work item | Completion criteria |
|---|---:|---|---|
| **Next** | P1 | Split the options implementation by feature area | Custom, tracking, and reward option builders have clear owners and preserve AceConfig paths, labels, ordering, and refresh behavior. |
| Queued | P1 | Reduce the compatibility core | Move cohesive remaining responsibilities out of `WQATurbo.lua` only when ownership and TOC ordering are explicit; retain one source owner for every consolidated runtime method. |
| Queued | P1 | SavedVariables schema and migration tests | Document a schema version, make migrations idempotent, and cover fresh installs plus representative legacy databases with automated fixtures. |
| Queued | P2 | Utilities and options tests | Add focused tests for map fallbacks, custom data validation, profile changes, and refresh coalescing without mirroring implementation details. |
| Queued | P2 | Remove obsolete compatibility debris | Audit commented-out code, unused stubs, duplicate locale keys, and stale migration scaffolding; remove only after proving no runtime or upgrade dependency remains. |
| Queued | P2 | Pin packaged dependency revisions | Replace floating external-library revisions in `.pkgmeta` with reviewed stable revisions and validate packaged addon startup. |
| Queued | P2 | Add a consistent Lua lint/format check | Select Lua 5.1-compatible tooling, document exceptions for WoW globals, and add a deterministic CI check. |

## 1.3.0: performance work

| Status | Priority | Work item | Completion criteria |
|---|---:|---|---|
| Queued | P1 | Lazy-load Blizzard Garrison UI | Mission UI code loads only when mission-table functionality needs it; startup, login, and mission scanning remain reliable across supported expansions. |
| Queued | P2 | Precompute task and expansion lookup indexes | Replace repeated linear lookups only where `/wqat perf` or profiling shows useful savings; rebuild indexes when their source data changes. |
| Queued | P2 | Preserve useful dynamic cache results during refresh | Explore stale-while-revalidate behavior so cached dynamic rewards remain visible while fresh data is pending, without publishing invalid or cross-profile state. |

## 1.3.0: feature and data work

| Status | Priority | Work item | Completion criteria |
|---|---:|---|---|
| Research | P1 | Current-patch content audit | Verify Midnight and subsequent Retail maps, factions, emissaries, reward types, currencies, and profession data against current authoritative sources before adding mappings. |
| Queued | P2 | Command and diagnostics audit | Make `/wqat` help and diagnostic output concise, complete, and consistent with the documented command surface. |
| Queued | P2 | Expand settings search coverage | Index dynamic expansion, reputation, mission-table, and custom-option labels while preserving responsive option construction. |
| Queued | P2 | Explain why a task matched | Add an optional concise tooltip explanation using canonical classification results, with no extra reward scans. |
| Research | P2 | Remaining container completion rules | Add hide-when-complete rules only for containers with a verified finite collectible pool and authoritative collection-state checks. |
| Queued | P3 | Localization coverage | Consolidate duplicate keys, expose remaining hard-coded user-facing text, and update supported locale tables without changing fallback behavior. |

## Research constraints

The following ideas must remain research-only until evidence supports a safe,
current-Retail implementation:

- Stitchyard or other content whose availability/completion APIs are unclear.
- Dynamic completion rules for Azerite or generic equipment caches without a
  verified finite loot pool.
- A generic legacy-daily abstraction that could change existing task semantics.

For WoW API and game-data research, prefer current Blizzard documentation and
Warcraft Wiki, then verify IDs and loot pools through Wowhead or current addon
sources. Record uncertainty and distinguish sourced behavior from inference.

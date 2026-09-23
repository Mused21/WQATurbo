# WQA Turbo Development Roadmap

> **Current release target:** 1.5.2
>
> **Released baseline:** 1.5.1
>
> **Current milestone:** 1.5.2 correctness patch
>
> **Current item:** Scaled World Quest transmog sources (In progress)
>
> **Last reviewed:** 2026-09-23

This is the active work queue for WQA Turbo. Read it before planning or
starting follow-up work. Update the current item and status in the same change
that completes or reprioritizes roadmap work. Released version documents are
historical records and must not be reused as active checklists.

## 1.5.2: transmog source correctness

| Status | Priority | Work item | Completion criteria |
|---|---:|---|---|
| **In progress** | P0 | Scaled World Quest transmog sources | Exact scaled-link appearances retain precedence; a missing link record falls back to the authoritative quest reward item ID; exact and overall ownership use Blizzard's direct source API without requiring richer source metadata; unavailable ownership remains pending; focused automated and in-game checks pass. |

The reported K'aresh item `243534` and Undermine item `233534` are
known-appearance/missing-source cases: each shares a collected visual with
another weapon, but its exact source is uncollected. The Ringing Deeps item
`224710` is an entirely uncollected appearance. Undermine (2346) and Ringing
Deeps (2214) are already in the scan map list, and the reports show other
quests being discovered, so these cases exercise reward classification rather
than map discovery. They must remain relevant when Blizzard's direct source
ownership result is available but richer `GetAppearanceSourceInfo()` metadata
is omitted.

Focused 1.5.2 in-game checks:

- With **Unknown source** enabled, refresh while either reported World Quest
  rewards K'aresh item `243534` or Undermine item `233534`. Confirm it appears
  and its match reason is transmog.
- Disable only **Unknown source** while leaving **Unknown appearance** enabled.
  Confirm this known-appearance reward disappears.
- With **Unknown appearance** enabled, check Ringing Deeps item `224710` and
  confirm its entirely uncollected appearance appears.
- Check a collected exact scaled-link appearance and confirm the base-item
  fallback does not expose a different bonus variant.

## Status definitions

- **Next**: the next item to implement.
- **In progress**: implementation or required verification is underway.
- **Queued**: accepted work with lower priority or a dependency on earlier work.
- **Research**: requires current API or game-data evidence before implementation.
- **Done**: implemented, locally validated, and tested in game where applicable.

## 1.5.1: covenant Calling selection

| Status | Priority | Work item | Completion criteria |
|---|---:|---|---|
| **Done** | P1 | Per-covenant Shadowlands Callings | The existing opt-in Calling tracker can include any selected covenant; the active covenant's live payload determines the shared daily rotations; covenant-specific quest variants are labeled, grouped under their sanctuary and independently filtered; completed variants stay hidden until that rotation expires; unknown future IDs remain limited to the active covenant; focused automated and in-game checks pass. |

Implementation and local verification are complete. The verified data table
contains 24 daily Calling families and all 96 covenant-specific quest IDs.
Blizzard's active-covenant event remains the rotation authority, so this does
not add a broad map scan or poll inactive covenant quest logs. The developer
verified the combined behavior, sanctuary grouping and unclipped Settings rows
in game on 2026-09-22, so the item is **Done**. PR #19's Simplified and
Traditional Chinese Calling translations are incorporated with its description
updated for the selected-covenant behavior.

Focused 1.5.1 in-game checks:

- Enable **Track Shadowlands Callings** and select all four covenants. Confirm
  that each live objective appears once per selected covenant and each row's
  reward label names Kyrian, Venthyr, Night Fae or Necrolord. Confirm their
  zone groups are Elysian Hold, Sinfall, Heart of the Forest and Seat of the
  Primus, with no Calling under Unknown. Each covenant selector must occupy a
  separate Settings row without clipping its name.
- Disable one covenant and refresh. Only that covenant's variants disappear;
  manually configured custom quests and ordinary Shadowlands World Quests do
  not change.
- Turn in a Calling for the active covenant. Its row disappears immediately,
  the corresponding rows for other selected covenants remain, and the turned-in
  variant does not return after refresh or `/reload` during the same rotation.
- Switch covenants and wait for Blizzard's Calling update. The daily objective
  families and expiration times remain consistent, completed variants stay
  hidden, and no stale or duplicate Calling rows appear.
- Disable the master toggle. All automatic Calling rows disappear while custom
  entries remain. Re-enable it and confirm the selected covenant checkboxes are
  preserved.

## 1.5.0: user experience

| Status | Priority | Work item | Completion criteria |
|---|---:|---|---|
| **Done** | P1 | Automatic popup empty-result behavior | An automatic refresh with no interesting tasks keeps a closed popup closed; a newly interesting task may open it; manual popup opening and refresh of an already-open popup preserve their current behavior; focused automated and in-game checks pass. |
| **Done** | P1 | K'aresh transmog discovery | Include the Tazavesh open-world map (2472) in The War Within scan, without changing reward eligibility or disabled-zone rules. Verify a missing appearance World Quest there in game; investigate any remaining named omissions separately. |
| **Done** | P1 | Blanket Shadowlands Callings | A full-width opt-in Settings control follows Blizzard's live Calling quest IDs for the active covenant, refreshes on turn-in/switch, hides unavailable callings, and groups active rows under Shadowlands. Focused automated and in-game checks pass. |
| **Done** | P3 | Locale-family organization and Chinese search help | PR #17's locale-family alphabetization and new Simplified/Traditional Chinese search-help translations are integrated without dropping the existing French or Russian translations; all locale blocks expose missing keys as commented English fallbacks, and focused validation passes. |

The K'aresh map entry is a discovery correction. The base K'aresh map (2371)
was already present; no specific missing quest or item ID was supplied, so this
does not establish that every reported transmog omission has the same cause.
Callings use the live `COVENANT_CALLINGS_UPDATED` payload instead of maintaining
a covenant quest-ID table. The full local gate passes, and the developer
reported the combined 1.5.0 behavior working in game on 2026-09-21. All three
items are **Done** and approved for a `release:minor` pull request.

PR #17 was not merged verbatim: its submitted rewrite removed one French and
29 Russian translations and contained trailing whitespace. The 1.5.0
integration preserves every existing translation and English fallback, applies
the requested alphabetical organization, and retains the four new Chinese
search-help translations.

Focused 1.5.0 in-game checks:

- With automatic popup output enabled, close the popup and let an empty
  automatic refresh run. It stays closed; manual opening still shows the
  empty state, and a newly interesting task can open it again.
- With K'aresh and Tazavesh enabled under The War Within zones, check a known
  Tazavesh World Quest that rewards an uncollected appearance. Disable only
  Tazavesh and verify that quest is excluded. Capture a quest and item ID for
  any remaining missing transmog on K'aresh or another TWW map.
- Enable **Track Shadowlands Callings** on a character with a covenant. Check
  that each available Calling appears, a turned-in Calling disappears, and a
  covenant switch replaces the old set after the update arrives. The full
  Settings label must be visible and popup rows must use the Shadowlands
  heading rather than Unknown. Disable the toggle and confirm the automatic
  Calling rows disappear without affecting manually configured custom quests
  or ordinary Shadowlands World Quests.

## 1.4.1: post-release correctness

| Status | Priority | Work item | Completion criteria |
|---|---:|---|---|
| **Done** | P0 | Azerite Armor Cache completion | Ordinary item `163857` cache rewards use the verified 73-source BfA zone pool, scoped to the active character's armor type; a complete pool hides the cache, another armor type cannot keep it visible, and unsupported item contexts and unavailable Blizzard collection data fail open. Focused automated checks and the CI package passed; the developer reported the in-game result working on 2026-09-15. |

The developer approved the tested PR #16 package for the 1.4.1 patch release on
2026-09-15.

## 1.3.0: completed correctness and runtime hardening

There will be no separate 1.2.1 release. Version 1.3.0 includes the tested
hardening below, the release-blocking reward corrections, SavedVariables
schema protection, the current-patch data correction, and the safe startup
performance fix. The developer approved this consolidated scope and reported
the first two in-game batches working on 2026-09-13 and 2026-09-14. The final
release-candidate batch passed in-game verification on 2026-09-14.

Work in reviewable increments, with related changes bundled for in-game testing
when useful. Run local validation and inspect each diff before presenting it.
Research items are part of the 1.3.0 work queue, but their implementation remains
conditional on current API/content evidence; record findings and any explicit
scope decision rather than promising unsupported behavior.

Broader core refactors, speculative performance changes, new feature work, and
dependency-source changes move to 1.4.0. Keeping them out of the release
candidate avoids expanding runtime and packaging risk after release bugs have
been fixed and tested.

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
This tested checkpoint was committed as part of the consolidated 1.3.0 branch.

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

A local full-library `1.3.0-local` preview package passes package validation,
including version substitution and development-file exclusions. The automated
BigWigs external checkout remains part of the final release workflow after the
release candidate is approved, merged, and tagged.

The final local gate passes all nine Lua regression suites, Lua 5.1 syntax
checks for 47 Lua files, the project and preview-package validators, and
`git diff --check`. The developer reported the complete release candidate
working in game on 2026-09-14 and approved it for commit, push, and a release PR.

## 1.3.0: release-blocking reward corrections

| Status | Priority | Work item | Completion criteria |
|---|---:|---|---|
| **Done** | P0 | Benthic active armor-type eligibility | Benthic armor tokens consider only appearances obtainable for the active character's armor type; shared cloaks remain shared; focused automated and in-game checks pass. |
| **Done** | P0 | Reward and pet eligibility fixes | Legacy caches and Benthic tokens use the corrected appearance rules without interrupting startup; Azerite Armor Cache has a readable per-character override; any positive Pet Journal species count suppresses ordinary pet tracking; automated and in-game checks pass. |

Implementation and focused automated coverage are committed in `6c5c379`. The
developer reported the combined in-game checks working on 2026-09-14; this item
is **Done**.

The follow-up active armor-type correction passed focused automated coverage
and developer in-game verification on 2026-09-14; it is **Done**.

Focused release checks:

- Reload and confirm initialization reaches Settings without Lua errors.
- Confirm the per-character Azerite toggle and its description use the full row.
- With pet tracking set to Default, confirm 1/3, 2/3 and 3/3 mapped pets do not
  keep their World Quests relevant; zero-copy pets should remain relevant.
- Confirm `Always track` still shows an owned mapped pet when explicitly selected.

## 1.3.0: maintainability and test coverage

The tested hardening and consolidated release plan were committed as `01e10e3`
on `feature/1.3.0` before the later release-candidate work.

The options split is committed and verified in game.
`UI/Options/` owns shared ordering, custom editors, tracking/search and rewards;
`UI/Options.lua` retains tree orchestration, general settings and the single
runtime refresh debouncer. Existing callbacks and construction order are preserved.
Before the reward corrections, the full-tree regression fixture matched the
committed monolithic implementation across 6,351 metadata values. It continues
to compare the split against that baseline while excluding the two intentional
Gear-setting changes and generated order numbers. Relative ordering, dynamic
pages, search, scoped writes and coalesced refresh remain covered directly.
Project validation, all eight Lua suites, Lua syntax checks and diff whitespace
checks passed before commit. The developer reported the combined Settings and
reward batch working on 2026-09-14; the item is **Done**.

Focused in-game checks for this increment:

- Open every Settings tab; confirm labels, ordering and expansion/category trees.
- Search by name and ID; change individual and bulk tracking modes.
- Change World Quest and Mission Table currencies/reputations, zones, emissaries,
  profession settings and Dragonflight racing-container tracking.
- Repeat custom quest, reward, mission and mission-reward add/edit/delete checks.
- Make rapid changes across tabs with the popup open and closed; verify a silent
  coalesced update. Reopen Settings, change profiles and reload to check persistence.

| Status | Priority | Work item | Completion criteria |
|---|---:|---|---|
| **Done** | P1 | Split the options implementation by feature area | Custom, tracking, and reward option builders have clear owners and preserve AceConfig paths, labels, ordering, and refresh behavior. |
| **Done** | P1 | SavedVariables schema and migration tests | Schema version 1 and idempotent migrations cover fresh installs, representative legacy databases, collisions, malformed containers, and future schema protection; automated and in-game checks pass. |

## 1.3.0: performance work

| Status | Priority | Work item | Completion criteria |
|---|---:|---|---|
| **Done** | P1 | Lazy-load Blizzard Garrison UI | The eager startup load is removed; lifecycle coverage preserves mission-update scheduling; login and mission-table behavior pass in-game verification. |

## 1.3.0: feature and data work

| Status | Priority | Work item | Completion criteria |
|---|---:|---|---|
| **Done** | P1 | Current-patch content audit | Source review is recorded in `CURRENT_PATCH_AUDIT_1.3.0.md`; the incorrect Midnight quest ID is corrected; the affected achievement and representative 12.1 behavior pass in-game verification. |

## 1.4.0 backlog

Version 1.3.0 was released from merge commit `6ffb13f` on 2026-09-14. The
following active item was accepted after release; the remaining entries were
moved out of 1.3.0 and retain their previous priority.

| Status | Priority | Work item | Scope decision |
|---|---:|---|---|
| **Done** | P1 | Val/Naigtal active-zone filtering | The live portal Area POI is preferred, with the regional weekly-reset clock as fallback, so only the accessible destination is scanned and published. Automated coverage passes and the developer reported the in-game result working on 2026-09-14. |
| **Done** | P1 | Reduce the compatibility core | Static toy registration now shares the collectible owner; custom task registration, Quest Pin/Flag availability and emissary scanning have focused owners with regression coverage. The full local gate passes and the developer reported the bundled in-game check working on 2026-09-15. |
| **Done** | P2 | Utilities and options tests | Existing option-tree coverage protects TOC loading, organization, search, scoped setters and shared refresh scheduling. A dedicated utility-routing suite covers task-type dispatch, zone/expansion resolution, time/link routing and metadata fallback; all focused suites and the full local gate pass. |
| **Done** | P2 | Remove obsolete compatibility debris | The audit retained active migration, command, display-state, fallback-classifier and enum compatibility paths. It removed only the unreferenced pre-options-split ordering counter, legacy `link()` helper and aliases left unused by the module moves; the full local gate passes. |
| **Done** | P2 | Pin packaged dependency revisions | Every external uses the packager's structured URL/tag form with an exact stable release tag, and the validator rejects missing or moving tags. The generated CI package passed validation and the developer reported the packaged in-game load working on 2026-09-15. |
| Queued | P2 | Add a consistent Lua lint/format check | The audit found no configured local formatter or linter and mixed indentation across the existing tree. Establishing a WoW-global policy and formatting baseline remains an isolated change so this bundle does not rewrite unrelated files or add an untested CI-only gate. |
| Research | P2 | Precompute task and expansion lookup indexes | `/wqat perf` has not shown a release-relevant saving that justifies new invalidation paths. |
| Research | P2 | Preserve useful dynamic cache results during refresh | Stale-while-revalidate semantics can expose invalid cross-profile data unless designed and tested separately. |
| **Done** | P2 | Command and diagnostics audit | Added focused `/wqat readiness`, corrected leading-whitespace parsing and documented the direct diagnostic aliases. Runtime command-routing coverage and the full local gate pass succeed; the developer reported the bundled in-game check working on 2026-09-15. |
| **Done** | P2 | Expand settings search coverage | The existing static traversal now indexes related source items, mapped quests, tracking quests and nested criteria without adding another data pass. Focused option-tree assertions and the full local gate pass succeed; the developer reported the bundled in-game check working on 2026-09-15. |
| **Done** | P2 | Explain why a task matched | Popup task-name hover now appends stable categories derived only from the cached reward model, with no new Blizzard API calls. Focused reason-format coverage and the full local gate pass succeed; the developer reported the bundled in-game check working on 2026-09-15. |
| Research | P2 | Remaining container completion rules | No additional finite loot pools have enough authoritative evidence for safe completion rules. |
| **Done** | P3 | Localization coverage | The validator rejects missing English fallbacks, duplicate base declarations, overrides of undeclared keys and translated format-placeholder mismatches. One ineffective duplicate base assignment was removed; the full local gate passes. |
| **Done** | P2 | Community Settings localization | PR #14 routes the reorganized Settings labels and descriptions through locale keys and adds Traditional Chinese translations. Its original, maintainer-corrected and integrated branches passed local and GitHub validation; the developer reported the integrated package working in game on 2026-09-15. |
| **Done** | P3 | Chinese match-reason translations | The PR #15 follow-up contribution translates every cached task match-reason category for Simplified and Traditional Chinese and preserves the required `%s` argument. The refreshed CI package passed its in-game tooltip smoke test and the developer approved it for release on 2026-09-15. |

The current local gate passes project validation with zero errors or warnings,
all 13 Lua regression suites, Lua 5.1 syntax checks for 55 first-party files and
`git diff --check`. The complete working-tree diff has been reviewed. The
developer reported the bundled source checkout working in game on 2026-09-15.
The developer reported the CI-generated package, pinned libraries, community
Settings localization and follow-up Chinese match-reason translations working
in game on 2026-09-15, and approved PR #15 for a `release:minor` release.

Focused in-game checks for Val/Naigtal active-zone filtering:

- During the current rotation week, refresh WQA Turbo with both Val and Naigtal
  enabled. Quests from the accessible portal destination should appear when
  relevant; quests from the inaccessible destination should not appear.
- Enable the unfinished **Showdown Success** achievement for the inaccessible
  destination and verify its criteria cannot reintroduce those World Quests.
- Confirm `/wqat scan` reports one fewer scanned map than 1.3.0 with the same
  zone settings.
- After the next regional weekly reset, refresh and verify the allowed and
  suppressed destinations swap.

Focused in-game checks for the current compatibility-core increments:

- With collectible tracking at its defaults, confirm an unowned mapped toy can
  still make its World Quest appear while an owned mapped toy stays hidden.
- Set an owned mapped toy to **Always track** and confirm its World Quest can
  appear again.
- Enable and disable one custom World Quest, Quest Flag, Quest Pin and mission;
  confirm each enabled entry appears when active and each disabled entry stays
  hidden.
- Confirm a custom Quest Pin still loads from its configured map after a reload
  and that ordinary refresh and popup behavior is unchanged.
- Enable one current emissary and confirm its configured or relevant reward
  appears; then refresh during reward-data loading and confirm it fills in once
  without duplicate output.
- Run `/wqat readiness` after an emissary data timeout and confirm its pending
  map or quest ID remains visible for diagnosis.
- With two Quest Pins on the same map, confirm both resolve after the map data
  becomes ready and that reload/refresh does not spam requests or duplicate
  results.
- Open Settings and hover/click representative item, currency and achievement
  rewards; confirm labels, links and tooltips still render normally after the
  dead-code cleanup.
- Run `/wqat`, `/wqat   scan`, `/wqat readiness`, `/wqat import` and an unknown
  subcommand. Confirm leading spaces are accepted, each known command reaches
  the documented action and the unknown command prints help.
- In Settings search, find representative entries by source item ID, mapped
  World Quest ID, tracking quest ID, and a nested achievement criterion name
  and ID. Confirm the expected expansion/category result opens normally.
- Hover popup task names for an achievement, collectible, custom task, gear or
  transmog reward, currency/reputation reward and a task matching more than one
  category. Confirm the added **Matched because** line is accurate and does not
  change the normal Blizzard tooltip details.
- On a Simplified or Traditional Chinese client, hover the same popup entries
  and confirm the **Matched because** label and every displayed reason use the
  selected Chinese locale rather than the English fallback.
- Download the CI-generated package, install it over a clean addon folder and
  reload. Confirm there are no missing-library errors and that Settings, the
  minimap icon, popup, profiles and the commands above load normally.

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

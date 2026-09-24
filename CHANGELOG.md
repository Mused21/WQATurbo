# WQA Turbo Changelog

## 1.6.0

### Added
- Pause automatic scans and notifications in grouped instances, then resume the latest deferred refresh after returning to the open world while keeping manual popup and refresh commands available.
- Add one-click enable/disable controls for World Quest types, zones, currencies, reputations, emissaries, and mission currency/reputation lists.

## 1.5.2

### Fixed
- Show uncollected transmog appearances and missing exact sources when Blizzard resolves ownership through the direct source API but omits richer source metadata for a scaled World Quest reward.

## 1.5.1

### Improved
- Let Shadowlands Calling tracking include any selected covenants, show unclipped selectors, label and group each covenant-specific row by its sanctuary, and keep completed variants hidden until the shared Calling rotation expires.
- Add Simplified and Traditional Chinese translations for the Calling interface and related tracking labels from PR #19.

## 1.5.0

### Improved
- Keep a closed World Quest popup closed when an automatic refresh finds no interesting tasks, then open it when a new interesting task appears.
- Add one optional Shadowlands Callings setting that follows the active covenant's live Calling quest IDs across covenant switches.
- Sort every locale family alphabetically and add Simplified and Traditional Chinese translations for the expanded collectible search help.

### Fixed
- Scan the Tazavesh open-world map in K'aresh for relevant The War Within World Quest rewards.
- Show Callings under Shadowlands instead of Unknown and give their Settings toggle enough room for its full label.

## 1.4.1

### Fixed
- Hide ordinary Azerite Armor Cache rewards when every appearance for the active character's armor type is collected.

## 1.4.0

### Improved
- Scan and display only the currently accessible Val or Naigtal World Quests for the weekly portal rotation.
- Move static collectible and custom-task registration, quest availability and emissary scanning out of the compatibility core into focused modules with enforced single ownership.
- Add focused utility-routing and custom runtime registration regression coverage.
- Remove the unused pre-options-split ordering counter and unreferenced legacy reward-link helper.
- Pin every packaged library external to an exact stable release tag.
- Add a focused `/wqat readiness` command and accept leading whitespace in `/wqat` subcommands.
- Search tracked collectibles by source item, mapped quest, tracking quest and nested criterion names or IDs.
- Explain why each task matched when its name is hovered in the popup.
- Validate that every localized UI key has one English fallback and that locale overrides cannot introduce undeclared keys.
- Make the reorganized Settings interface localizable and expand Simplified and Traditional Chinese coverage, including task match explanations.

## 1.3.0

### Improved
- Split Settings builders into custom, tracking and reward modules while preserving paths, ordering and shared refresh scheduling.
- Added an explicit SavedVariables schema version with ordered, repeatable migrations and focused legacy-database tests.
- Let Blizzard load its Garrison UI on demand instead of forcing the full mission-table interface to load at addon startup.

### Fixed
- Corrected the Midnight Precision Excision World Quest ID used by the Lysikas Would Be Proud achievement tracker.
- Excluded local agent override instructions from release packages.
- Hide Zandalari Empire Equipment Cache when its verified appearance pool is complete for the current armor type.
- Stop treating Tortollan Trader's Stock as an appearance-bearing jewelry cache.
- Evaluate Benthic tokens for the active character's armor type so completed slot appearances are not shown because another armor type is missing.
- Allow Azerite Armor Cache tracking to be disabled per character while retaining the profile-wide master setting.
- Show the full per-character Azerite setting label and description instead of trimming them in the Gear layout.
- Treat any positive Pet Journal species count as owned even if its journal row temporarily reports otherwise.
- Preserve scalar container metadata during faction pruning so addon initialization reaches AceDB setup.
- Reject invalid custom IDs and duplicate additions without overwriting saved entries.
- Store custom map IDs numerically and require a valid map for Quest Pin entries.
- Refresh runtime results after custom adds, edits, toggles and deletes through the silent Settings debouncer.
- Remove leftover quest type and map controls when deleting a custom quest.
- Retry unavailable Quest Pin map data without blocking ready tasks or repeatedly querying every map for each quest.
- Tolerate disappearing map and Area POI metadata; temporary fallback names recover when data becomes available.
- Rebuild results and update the minimap immediately after changing, copying or resetting a profile, with silent background publication.
- Include unresolved task and emissary IDs in on-demand scan/performance diagnostics after readiness timeouts.

## 1.2.0

### Improved
- Racing reward purses and Benthic armor tokens now stop making a World Quest relevant after every collectible outcome available from that specific container is owned.
- Reorganized internal modules by data, tracking, scanning, runtime, and UI responsibility to make future changes safer.
- Consolidated runtime entry points so each behavior has one authoritative implementation.
- Reused mount and pet journal snapshots in Settings instead of rescanning an entire journal for every tracked entry.
- Split reward classification into focused helpers while preserving incremental, frame-budgeted scanning.
- Centralized popup tooltip cleanup and rebuilding to prevent stale callbacks from releasing a newer tooltip.
- Made World Quest, Area POI, Mission Table, and emissary readiness progressive so available entries can appear while unrelated Blizzard data is still loading.
- Bounded task and emissary readiness retries and cancelled callbacks belonging to superseded refreshes.
- Added Lua regression suites and stronger project validation for runtime ownership, lifecycle, tracking, scanning, and tooltip behavior.

### Fixed
- Fixed an open World Quest popup sometimes remaining at achievement-only results after settings-triggered reward filtering completed.
- Added the shared Hide Exalted/maximum Renown control to Mission Table reputation settings.
- Fixed character-only tracking on a parent achievement failing to propagate to nested achievement criteria.
- Fixed one missing `QUEST_PIN` criterion quest ID preventing valid later criteria from being registered.
- Fixed StatWeightScore dual-slot comparisons selecting the second slot instead of the lower equipped score.
- Fixed minimap right-click navigation failing to retain the numeric Blizzard Settings category ID returned by AceConfigDialog.
- Fixed stale collectible source items remaining tracked after their setting or collection state changed.
- Applied Hide Exalted/maximum Renown consistently to direct, item, and currency reputation rewards across World Quests and missions.
- Preserved silent Settings refresh behavior when a refresh is deferred by combat.
- Fixed sorting when Blizzard temporarily has no task, mission, or Area POI name available.
- Fixed reputation-currency-only missions being omitted and allowed ready missions to appear while another mission is still loading.
- Kept enabled equipment caches visible while supplemental item-level data is pending.
- Fixed Area POIs being omitted when their metadata or one of their reward links was temporarily unavailable.
- Fixed an open popup failing to republish after Mission Table or emissary data became available.

## 1.1.0

### Added
- Added tracking for Dragonflight racing reward containers, including Dragon Racer's Purse, Reach Racer's Purse, Cavern Racer's Purse, and Dream Racer's Purse.
- Added a new Dragonflight `World Quests > Containers > Racing reward containers` setting.
- Added Armor Cache support for Nazjatar Benthic gear tokens.

### Fixed
- Fixed Azerite Armor Cache tracking so enabled caches are shown even when their contents are not an item-level upgrade for the current character.
- Fixed older Armor, Weapon, and Jewelry Cache tracking so the corresponding filter tracks the cache itself instead of only showing it when it is considered an upgrade.
- Shift+Left-clicking the minimap button now opens the World Quest popup while performing the silent refresh.
- Updated the minimap tooltip to reflect the new Shift+Left-click behavior.

## 1.0.1

### Improvements
- Added Shift-left-click on the minimap button to refresh World Quest data immediately.
- Improved transmog tracking by using Blizzard's appearance/source collection APIs directly.

### Fixes
- Fixed transmog rewards sometimes being classified as an unknown appearance when the appearance was already collected from another item.
- Fixed `Unknown appearance` and `Unknown source` filtering being reversed or incorrect for some multi-source appearances.
- Fixed multi-source appearances where Blizzard's per-source `appearanceIsCollected` value did not reflect ownership of another source belonging to the same appearance.
- WQA Turbo now considers an appearance collected when any Blizzard source for that appearance is collected, while still tracking exact-source ownership separately.

## 1.0.0

### New features
- Redesigned the addon settings with tree-based navigation for easier browsing across Tracking, Rewards, Custom, and Options.
- Added collection search across achievements, mounts, pets, and toys, including name and ID lookup.
- Added category-level and expansion-level bulk tracking controls for Default, Always Track, and Don't Track.
- Added native hover tooltips in Settings for achievements and supported collectibles, including Blizzard achievement criteria/progress.
- Added minimap button shortcuts: left-click opens the World Quest list and right-click opens WQA Turbo settings.
- Added automatic refresh after tracking and reward-filter changes, plus a manual Refresh page.
- Added an option to hide Exalted reputations and Major Factions already at maximum Renown from reputation filters.
- Added Midnight reward-filter support, including current currencies and reputation factions.
- Added direct Blizzard API-based reputation reward detection for modern World Quests.

### Improvements
- Reordered expansions newest-to-oldest throughout the redesigned settings.
- Split long option pages into clearer sections with readable, full-width explanations.
- Simplified the minimap hover to show only left/right-click instructions; the full World Quest list now opens only on left-click.
- Limited Mission Table settings to expansions that actually use mission tables.
- Kept completed collection entries hoverable in Settings.
- Added scanner diagnostics for reputation checks and matches.

### Fixes
- Fixed achievement search in the new Tracking search page.
- Fixed completed achievements, mounts, pets, and toys not showing hover tooltips.
- Fixed right-clicking the minimap button failing to open Blizzard Settings on Midnight.
- Fixed disabled zones still showing achievement-backed World Quests.
- Fixed Midnight reputation filters not detecting World Quests that directly award reputation.
- Fixed several Settings labels/descriptions overflowing the Blizzard Settings pane.

## 0.2.0

### Improvements
- Added scrolling for long World Quest lists so tooltips no longer extend excessively off-screen.
- Reduced the maximum World Quest tooltip height so scrolling starts earlier.
- Added collapsible expansion sections to World Quest tooltips.
- Applied scrolling and collapsible expansion behavior to both the persistent `/wqat popup` and the minimap tooltip.
- Collapsed expansion state is remembered per profile.

## 0.1.4

### Fixes
- Fixed World Quest type filtering so achievement-related Pet Battle World Quests correctly respect the Pet Battle filter.
- Improved Profession World Quest classification using trade skill information.
- Fixed Profession recipe reward detection when tooltip scanning returned an embedded crafted-item link instead of the actual recipe reward.

## 0.1.3

### Improvements
- Added additional Midnight achievement and World Quest mappings.
- Added an option to show PvP World Quests while War Mode is disabled.

## 0.1.2

### Fixes and compatibility
- Added missing Midnight zone support.
- Fixed compatibility with All The Things.

## 0.1.1

### Improvements
- Added migration support from the original WQAchievements SavedVariables and profiles.
- Added `/wqat import` for importing settings from WQAchievements.
- Added collision-safe names for migrated profile and tooltip state.

## 0.1.0

### Initial release
- Initial WQA Turbo release.
- Introduced the incremental, frame-budgeted reward scanner.
- Added cached collection state and progressively enriched World Quest results.
- Added cached `/wqat` and minimap display paths focused on reducing frame spikes compared with the original WQAchievements behavior.

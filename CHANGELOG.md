# WQA Turbo Changelog

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

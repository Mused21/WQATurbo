# WQA Turbo Changelog

## 1.0.0

### New features
- Added minimap button shortcuts:
  - Left-click opens the World Quest list.
  - Right-click opens the WQA Turbo settings directly.
- Added minimap tooltip hints so the available mouse actions are easy to discover.

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

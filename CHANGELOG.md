# Changelog
## 0.1.4
- Fixed World Quest Type filters not always applying to the intended quest type.
- Fixed achievement-related Pet Battle World Quests ignoring the Pet Battle filter.
- Improved Profession World Quest classification.
- Fixed Profession recipe World Quests being missed when tooltip scanning returned the crafted item instead of the actual recipe reward.
- World Quest Type changes now refresh the displayed results immediately.

## 0.1.3
- PvP World Quests are hidden while War Mode is off by default; a new option allows achievement hunters to keep tracking them anyway.
- Added Midnight World Quest achievement tracking for **No Time to Paws**, **Lysikas Would Be Proud**, and **A Stack of Snacks**.
- Added tracking for the Midnight PvP World Quest achievements **Investigating the Rise** and **Uprising**.
- Added tracking for **Showdown Success: Val** and **Showdown Success: Naigtal**, using Blizzard's live achievement criteria so rotating Showdown World Quests stay current.
- Fixed Midnight static achievement data not being registered because `CreateQuestList()` still stopped at The War Within.
- Made automatic achievement-criteria registration safely ignore non-quest criteria instead of attempting to register a nil quest ID.

## 0.1.2
- Updated Midnight zone coverage with Atal'Aman, The Den, Val, Naigtal, and The Coiled Isle.
- Fixed a startup race with AllTheThings where `SearchForLink` could be called before ATT finished initializing its search module.
- Added guarded ATT lookups with a short retry cooldown to prevent repeated Lua errors during startup.
- Fixed settings migration attempting a protected UI reload from a timer; the cleanup reload is now explicitly user-triggered.

## 0.1.1
- Added automatic settings migration from WQAchievements.
- Existing profiles, filters, popup settings, minimap settings, and other configuration can now be imported.
- Added `/wqat import` to manually start the migration.
- WQAchievements is temporarily loaded only when required for migration and disabled again automatically.
- Fixed namespace collisions when WQAchievements and WQA Turbo are loaded together.
- Prevented the original WQAchievements scanner and popup from starting during migration.

## 0.1.0
Initial WQA Turbo beta.

### Performance architecture
- Replaced repeated synchronous full-map reward scans with a frame-budgeted
  incremental scanner.
- Missing reward data no longer restarts the entire global scan.
- Dynamic item/currency/profession rewards load in the background.
- Changed task readiness from global to per-World-Quest, so one unresolved WQ
  no longer delays other ready results.
- Added progressive publication of newly available relevant WQs.
- Reduced repeated Mount Journal and Pet Journal scans with indexed snapshots.

### User interface
- Minimap popup reads the current cache and does not trigger a full refresh.
- Open popup refreshes when background enrichment discovers new useful WQs.
- `/wqat` shows current results immediately.
- Added explicit `/wqat refresh`.
- Added `/wqat perf`, `/wqat scan`, and `/wqat cache` diagnostics.

### Project cleanup
- Rebranded as WQA Turbo.
- Uses independent `WQATurbo` addon namespace.
- Uses independent `WQATurboDB` SavedVariables database.
- Removed original CurseForge/Wago/WoWI project IDs.
- Updated Retail interface metadata for 12.1.

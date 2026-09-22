# Invariants and Regression Guards

These are project-level rules. A change that violates one should be treated as an architectural decision requiring explicit review, not an incidental implementation detail.

## Scanner/performance

### 1. Never retry the whole world because one reward is pending

Pending reward/item state is per quest.

### 2. Keep scans frame-budgeted

Do not replace the incremental scanner with a large synchronous loop.

### 3. Static relevance should not wait for dynamic reward data

Achievement/static collectible results should become usable immediately.

### 4. Collection journals are indexed once per refresh

Do not repeatedly walk the full mount/pet journal for every expansion/item.
`WQATurbo.lua` owns `CreateQuestList()` and calls the invalidation helper once
before rebuilding; `Tracking/CollectionCache.lua` must not wrap that method.

### 5. Settings bulk operations coalesce refreshes

One bulk operation → one debounced refresh.

## Display/cache

### 6. `/wqat` is cache-first

It should show current results rather than implicitly trigger a new broad scan.

### 7. Normal minimap left-click is cache-first

Open persistent popup immediately.

### 8. Shift+Left-click in 1.1.0 opens + refreshes

Order:

```text
open cached popup
then silent refresh
```

### 9. Minimap hover stays lightweight

Never show the full WQ list merely because the user hovers the icon.

### Automatic empty results keep a closed popup closed

An automatic refresh may open a closed popup only when it publishes an
interesting task. Manual popup requests must still be able to show the empty
state, and an already-open popup must continue to refresh in place.

## Tooltip safety

### 10. Stale delayed callback may not release a new tooltip

Required pattern:

```text
capture tooltip
verify global reference is still same object
clear global reference
clear attached task references
release
```

All addon-owned release paths must call `WQA:ReleaseQTip(capturedTooltip)`.
Direct `LibQTip:Release()` and direct `WQA.tooltip = nil` ownership remain in
that canonical helper only.

### 11. Cleanup must be idempotent

Multiple hide/rebuild paths must not crash when state was already cleared.

Use `WQA:RebuildQTip()` for popup or LDB replacement rather than duplicating
release/acquire sequences.

## World Quest eligibility

### 12. Disabled zones are a final publication gate

Static achievement matches may not bypass zone settings.

### 13. World Quest type filtering is final too

Relevance does not override disabled type settings.

### 14. War Mode behavior is centralized

PvP WQ inclusion while War Mode is off must honor:

```lua
showWarModeQuestsWithoutWarMode
```

## Transmog

### 15. Blizzard APIs are collection-state authority

ATT/CanIMogIt are presentation-only.

### 16. Do not trust `appearanceIsCollected` alone

Overall appearance ownership must enumerate all appearance sources.

### 17. Preserve Unknown Appearance versus Unknown Source semantics

They are separate user choices.

## Reward item identity

### 18. Authoritative quest reward item ID wins

Tooltip embedded links may refer to a crafted result or other nested item.

Compare scanned item ID with `GetQuestLogRewardInfo()` item ID.

## Settings

### 19. Do not bulk-apply exclusive/character-only tracking modes

Bulk values are ordinary modes only.

### 20. Completed entries with tooltips remain hoverable

Do not disable a completed InteractiveLabel if it has a tooltip hyperlink.

### 21. Avoid Lua pseudo-ternary false-value bugs

Do not write:

```lua
condition and false or fallback
```

when false is a meaningful result.

## Blizzard Settings integration

### 22. Use numeric category ID

Use the category ID returned by AceConfigDialog for:

```lua
Settings.OpenToCategory(categoryID)
```

not `"WQATurbo"`.

## Packaging/release

### 23. Do not manually bump TOC version

Keep:

```text
## Version: @project-version@
```

### 24. Package before remote tag push

Preserve the fixed BigWigs packager workflow order.

### 25. Do not reintroduce `WorldQuestFilters.lua`

Filtering belongs in current centralized helpers/settings architecture.

## Architecture

### 26. Patch the active implementation

Search all definitions and respect TOC load order.

### 27. Do not put expansion hacks in RewardScanner

Stable data/classification belongs in data/classification layers.

### 28. Prove Blizzard data before designing a legacy/special source

Different historical content systems expose availability differently.

## 1.1.0 cache/container semantics

### 29. Cache category means track the cache

Azerite/equipment cache eligibility must not silently depend on modern-character upgrade value.

Upgrade calculations are display metadata.

Verified finite appearance pools may hide a direct equipment cache after the
shared and current armor-type sources are complete. Ordinary Azerite Armor
Cache links use their verified BfA zone-reward pool and the active character's
armor type; Dungeon and Warfront item contexts must fail open rather than use
that different pool. Its profile master setting and explicit per-character
override remain independent of completion. Armor tokens that follow loot
specialization check the active character's armor type. Faction pruning must
preserve scalar metadata alongside faction-tagged record tables.

Pet ownership is complete after one collected copy. The Pet Journal row flag
may be cross-checked with the species count, but the per-species copy limit must
never become a completion target. `Always track` remains the explicit override.

### 30. Racing purse completion is purse-specific

Each purse must be hidden only after every account-wide manuscript quest flag
in that purse's fixed pool is complete. Completion of one purse must not affect
another purse.

### 31. Consolidated runtime methods have one owner

Once Step 8 consolidates a method, do not restore a compatibility copy earlier
in the TOC. `Show()` is owned only by `Runtime/Display.lua`, and `OnEnable()`
is owned only by `Runtime/Runtime.lua`. `AddMounts()`, `AddPets()` and
`AddToys()` are owned only by `Tracking/CollectionCache.lua`; `AddCustom()` is
owned only by `Tracking/Custom.lua`; and `CheckWQ()` is owned only by
`Runtime/TaskResolver.lua`. `Reward()` is owned only by
`Scanning/RewardScanner.lua`. `EmissaryReward()` and `EmissaryIsActive()` are
owned only by `Scanning/EmissaryScanner.lua`. `RefreshQuestPins()`,
`isQuestPinActive()` and `IsQuestFlaggedCompleted()` are owned only by
`Tracking/QuestAvailability.lua`. `CreateQuestList()` is owned only by
`WQATurbo.lua`. The validator enforces this ownership.

### 32. Container completion fails open

Unknown containers, unknown character armor types and unavailable Blizzard
collection data must keep a container visible. Do not infer completion from a
partial or combined loot pool.

### 33. Profile transitions cannot retain another profile's runtime cache

Changed, copied and reset profiles must supersede old asynchronous work,
rebind minimap settings, rebuild options and publish new-profile results silently.

### 34. Transient metadata is not a permanent negative result

Missing map names and POI hover metadata must not crash. Do not cache fallback
zone names as resolved metadata. Missing Quest Pin results use bounded retries;
ready maps and tasks continue independently.

### 35. Localized strings preserve safe fallbacks and format arguments

Every first-party `L["..."]` use must have one English declaration. Locale
overrides may use only declared keys and must preserve the English value's
ordered `string.format` placeholders so translated UI cannot pass missing or
mis-typed arguments at runtime. The project validator enforces these rules.

### 36. Calling variants follow one observed daily family rotation

Use Blizzard's active-covenant Calling payload to identify live daily families.
Only expand IDs present in the verified covenant-family table; an unknown ID
must remain limited to the active covenant. Keep observed family expiration
account-wide, completion suppression character-specific, and both bounded by
the same expiration. Calling tracking must not introduce another map scan or
poll inactive covenant quest logs.

## Review technique

For every significant PR, ask:

```text
Does this block ready results?
Does this rescan too broadly?
Does this bypass final eligibility?
Does this rely on stale external-addon state?
Does this change a setting's semantic meaning?
Does this add a second source of truth?
Does this edit a function that is later overridden?
```

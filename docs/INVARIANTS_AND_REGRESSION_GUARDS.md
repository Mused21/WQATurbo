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

### 30. Racing purse completion is purse-specific

Each purse must be hidden only after every account-wide manuscript quest flag
in that purse's fixed pool is complete. Completion of one purse must not affect
another purse.

### 31. Consolidated runtime methods have one owner

Once Step 8 consolidates a method, do not restore a compatibility copy earlier
in the TOC. `Show()` is owned only by `Runtime/Display.lua`, and `OnEnable()`
is owned only by `Runtime/Runtime.lua`. `AddMounts()` and `AddPets()` are owned
only by `Tracking/CollectionCache.lua`, and `CheckWQ()` is owned only by
`Runtime/TaskResolver.lua`. `Reward()` is owned only by
`Scanning/RewardScanner.lua`. `CreateQuestList()` is owned only by
`WQATurbo.lua`. The validator enforces this ownership.

### 32. Container completion fails open

Unknown containers, unknown character armor types and unavailable Blizzard
collection data must keep a container visible. Do not infer completion from a
partial or combined loot pool.

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

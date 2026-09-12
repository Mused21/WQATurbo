# WQA Turbo 1.1.0

> Target branch: `feature/popupandcontainers`  
> Target version: **1.1.0**  
> Previous public release: **1.0.1**

This document captures the intended functional delta for 1.1.0.

## Added: Dragonflight racing reward containers

New Settings path:

```text
Rewards
└─ Dragonflight
   └─ World Quests
      └─ Containers
         └─ Racing reward containers
```

Recognized item IDs:

```text
199192 Dragon Racer's Purse
204359 Reach Racer's Purse
205226 Cavern Racer's Purse
210549 Dream Racer's Purse
```

Purpose:

Racing World Quests can reward these containers, which can contain Drakewatcher's Manuscripts/customizations.

The option tracks the container itself.

It does not attempt to determine whether all possible manuscript outcomes inside that container are already collected.

### Architecture impact

Classification/settings only.

No RewardScanner architecture change.

## Added: Benthic gear under Armor Cache

Nazjatar Benthic slot-token IDs:

```text
169477 Benthic Girdle
169478 Benthic Bracers
169479 Benthic Helm
169480 Benthic Chestguard
169481 Benthic Cloak
169482 Benthic Leggings
169483 Benthic Treads
169484 Benthic Spaulders
169485 Benthic Gauntlets
```

These are controlled by the existing Armor Cache setting.

### Architecture impact

Reward-classification lookup only.

## Fixed: Azerite Armor Cache semantics

Old behavior:

```text
Azerite Armor Cache enabled
AND calculated cache contents are an item-level upgrade
→ show
```

New behavior:

```text
Azerite Armor Cache enabled
→ show cache

if upgrade metadata can also be calculated
→ attach it as supplemental display information
```

This makes the setting semantic consistent with its label.

## Fixed: generic equipment-cache semantics

Applies to recognized:

- Armor Cache;
- Weapon Cache;
- Jewelry Cache.

The selected category tracks the cache itself regardless of whether an old-expansion item-level calculation considers it useful to the modern character.

Upgrade calculation remains optional metadata.

## Changed: Shift+Left-click minimap behavior

1.0.1 behavior:

```text
Shift+Left-click
→ silent refresh
```

1.1.0 behavior:

```text
Shift+Left-click
→ open cached popup immediately
→ start silent refresh
→ popup progressively updates
```

The minimap hover hint is updated to explain this.

### Why

A user requesting a manual refresh generally wants to see the result. Requiring a second click to open the popup added unnecessary friction.

Opening cached content first preserves the performance-first behavior.

## Validation performed during development

Confirmed in game:

- Dragonflight racing reward container tracking works and respects its toggle.
- Azerite Armor Cache appears when the option is enabled.
- Shift+Left-click popup behavior works.

Benthic token classification uses the same tested `CheckReward`/Armor Cache path but should still be opportunistically validated against an active Nazjatar example before release if available.

## Changelog text

Suggested release changelog:

```markdown
### Added
- Added tracking for Dragonflight racing reward containers, including Dragon Racer's Purse, Reach Racer's Purse, Cavern Racer's Purse, and Dream Racer's Purse.
- Added a new Dragonflight `World Quests > Containers > Racing reward containers` setting.
- Added Armor Cache support for Nazjatar Benthic gear tokens.

### Fixed
- Fixed Azerite Armor Cache tracking so enabled caches are shown even when their contents are not an item-level upgrade for the current character.
- Fixed older Armor, Weapon, and Jewelry Cache tracking so the corresponding filter tracks the cache itself instead of only showing it when it is considered an upgrade.
- Shift+Left-clicking the minimap button now opens the World Quest popup while performing the silent refresh.
- Updated the minimap tooltip to reflect the new Shift+Left-click behavior.
```

## Release label

Because this moves 1.0.x to 1.1.0:

```text
release:minor
```

Do not manually edit the TOC version.

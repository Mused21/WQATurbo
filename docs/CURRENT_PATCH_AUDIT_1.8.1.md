# Retail 12.1.5 Compatibility Audit for 1.8.1

Audit date: 2026-10-13

## Scope and sources

This audit prepares WQA Turbo for the Retail 12.1.5 client update. It covers
the addon interface number, removed addon APIs, and new content that may affect
World Quest discovery.

The 12.1.5 interface number and API removals were checked against the current
[12.1.5 API changes](https://warcraft.wiki.gg/wiki/Patch_12.1.5/API_changes)
and Blizzard's supported
[`C_Item.GetDetailedItemLevelInfo`](https://warcraft.wiki.gg/wiki/API_C_Item.GetDetailedItemLevelInfo)
documentation. New content was checked against Blizzard's
[12.1.5 PTR development notes](https://us.forums.blizzard.com/en/wow/t/midnight-1215-ptr-development-notes/2344395/1).

## Findings and decisions

### Addon interface

Retail 12.1.5 uses interface `120105`. `WQATurbo.toc` now declares that
interface while release automation continues to own semantic version
substitution.

### Removed APIs

Patch 12.1.5 removes the deprecated global item API fallbacks. WQA Turbo still
used `GetItemInfo()` in reward and Settings paths and
`GetDetailedItemLevelInfo()` while classifying ordinary equipment, Azerite
armor caches, and recognized armor or weapon caches. Those calls now use the
supported `C_Item` namespace APIs.

The documented removals were reviewed against the loaded project source; the
two item globals above were the affected calls. Validator guards and focused
test stubs now prevent those obsolete calls from returning unnoticed.

### New content

Aqir Invasions occur in Eversong Woods and Zul'Aman, which are already in the
Midnight map scan list. Blizzard describes them as zone-wide public events,
not ordinary World Quests. No speculative quest, Area POI, reward, faction or
currency IDs are added before the live client establishes a stable API shape.

The continuing campaign uses Zul'Aman and the Coiled Isle, which WQA Turbo
already scans. The Labyrinth of Kindo'jan and the Unbinding of Kith'ix are
instanced content and do not expand the open-world scan list.

## Live verification required

This audit remains in progress until the Retail 12.1.5 client is available and
the following checks pass in game:

- WQA Turbo loads without the out-of-date-addon override and produces no Lua
  error during login, reload, or a manual refresh.
- An ordinary equipment reward and a recognized equipment cache can be
  evaluated with item-level upgrade tracking enabled.
- Existing World Quests in Eversong Woods, Zul'Aman, and the Coiled Isle are
  discovered without duplicate rows.
- Automatic and manual scans remain stable during an Aqir Invasion. Any task
  or reward that should be tracked is inspected through the live APIs before
  adding static IDs.

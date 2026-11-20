# Retail 12.1.7 Compatibility Audit for 1.8.4

Audit date: 2026-11-20

## Scope and sources

This audit prepares WQA Turbo for Retail 12.1.7, **Echoes of the Worldcore**.
It covers the addon interface number, the published addon-facing changes, the
generated API definitions used by WQA Turbo, and new content that could affect
World Quest discovery.

Sources:

- Blizzard's [Echoes of the Worldcore overview](https://worldofwarcraft.blizzard.com/en-us/news/24310659/midnight-echoes-of-the-worldcore-overview)
- Blizzard's [December 1 release announcement](https://worldofwarcraft.blizzard.com/en-us/news/24317679/midnight-echoes-of-the-worldcore-arrives-on-december-1)
- Blizzard's [12.1.7 PTR development notes](https://us.forums.blizzard.com/en/wow/t/midnight-echoes-of-the-worldcore-ptr-development-notes/2383391/1)
- The extracted Blizzard [12.1.7 PTR UI source](https://github.com/Gethe/wow-ui-source/commit/ptr)
- The [12.1.7 addon API change summary](https://warcraft.wiki.gg/wiki/Patch_12.1.7/API_changes)

## Findings and decisions

### Addon interface

Retail 12.1.7 uses interface `120107`. `WQATurbo.toc` declares both `120105`
and `120107` so the same package loads on the current 12.1.5 client and after
the update. Release automation continues to own semantic version substitution.

Blizzard announced that the update launches on 2026-12-01. Live verification
therefore remains pending until that client is available.

### API compatibility

The published addon-facing changes obfuscate server and spawn portions of some
GUIDs and stop expanding variables such as `[Game]` or `[Family]` in TOC
directives. WQA Turbo neither parses or persists GUID components nor uses TOC
metadata variables, so those changes require no runtime migration.

The generated live and PTR documentation was compared for every changed API
surface that WQA Turbo calls. The called `C_AddOns`, `C_AreaPoiInfo`,
`C_CurrencyInfo`, `C_DateAndTime`, `C_Item`, `C_MajorFactions`,
`C_MountJournal`, `C_QuestLog`, and `C_TransmogCollection` functions retain
their live signatures. Other namespaces called by the addon have unchanged
documentation files. No compatibility wrapper or scanner change is justified
by the current PTR definitions.

### New content

Blizzard's announced 12.1.7 content consists of the Return to Dornogal story
campaign, Lorewalking stories, Talebound, Turbulent Timeways, and two additional
Omnium Folio runes. The notes do not identify new ordinary World Quest zones or
stable World Quest reward mappings that WQA Turbo should add before launch.

No speculative map, quest, reward, faction, or currency IDs are added. If live
12.1.7 exposes new trackable World Quests, they should be captured and added
from their verified API data after launch.

## Live verification required

- WQA Turbo loads without the out-of-date-addon override and produces no Lua
  error during login, reload, automatic refresh, or `/wqat scan`.
- Existing BFA and Midnight World Quests remain discoverable without duplicate
  rows.
- Ordinary equipment and transmog rewards classify correctly.
- The popup, minimap button, Settings, and instance scan policy retain their
  1.8.3 behavior.
- Any new open-world task that appears relevant is recorded with its live map,
  quest/POI, reward, and completion behavior before static data is added.

# Current-patch Content Audit for 1.3.0

Audit date: 2026-09-14

## Scope and source policy

This audit covers the static Retail data that can affect WQA Turbo's World
Quest discovery and reward settings: map IDs, factions, legacy emissary quest
IDs, selectable currencies, profession handling, and achievement-to-quest
mappings.

Blizzard's current [12.1 hotfixes](https://worldofwarcraft.blizzard.com/en-us/news/24296142)
and [Midnight content update notes](https://worldofwarcraft.blizzard.com/en-us/news/24244646)
establish the live release scope. Blizzard's
[12.1.5 preview](https://worldofwarcraft.blizzard.com/en-us/news/24295093)
describes upcoming content; this audit does not add speculative IDs for it.
Exact game IDs were cross-checked through current Wowhead records and a current
All The Things source checkout where applicable.

## Findings and decisions

### Maps

The four base Midnight zones and their current submaps in `Data/Zones.lua`
match the live UI map IDs. The 12.0.7 invasion maps are Val `2599` and Naigtal
`2600`, and the 12.1 zone is The Coiled Isle `2512`. Wowhead's current
[Midnight map-ID list](https://www.wowhead.com/guide/list-of-zone-map-id-number-for-navigation-in-wow-and-tomtom-19501)
and [invasion-zone guide](https://www.wowhead.com/guide/midnight/naigtal-val-zones-heroic-world-tier)
support those values.

No aggregate Quel'Thalas map is added. WQA scans the concrete zone and
microzone maps where tasks are returned; adding the parent map would duplicate
requests without adding a verified task source. The misspelled Harandar source
comment is corrected.

### Factions

All eight Midnight faction IDs in `Data/RuntimeData.lua` resolve to their
expected live factions: the four launch Renown factions, Slayer's Duellum,
Zul'jarra's Forces, Captain Tokka, and Ritual Sites. The 12.1 addition is
Zul'jarra's Forces `2772`, confirmed by the current
[Renown guide](https://www.wowhead.com/guide/midnight/zuljarras-forces-renown-reputation-farming-rewards).
No faction changes are required.

### Emissaries

Midnight weekly activities do not use the Legion/Battle for Azeroth legacy
emissary quest model represented by `EmissaryQuestIDsByExpansion`. No Midnight
emissary IDs are added.

### Currencies and reward types

Voidlight Marl `3316` remains the verified general Midnight currency exposed
as a selectable World Quest reward. Field Accolade `3405` is used by Ritual
Sites and Void Invasion activities, but current sources do not establish it as
a direct standard World Quest reward. It is therefore not added to the static
World Quest currency list. The scanner will continue to classify any enabled
currency ID returned by Blizzard's reward API.

No new reward category is required for 12.1. Existing item, currency,
reputation, gold, recipe, profession, and collectible paths cover the current
reward shapes.

### Professions

Profession World Quest eligibility is built at runtime from
`GetProfessions()` and `GetProfessionInfo()`. It does not depend on a static
Midnight profession-ID list, so no data mapping is required.

### Achievement mappings

The one-off mappings for No Time to Paws and A Stack of Snacks point at the
correct World Quests. The Precision Excision mapping was stale: current quest
`94743` satisfies Lysikas Would Be Proud, while the local table used `93438`.
The mapping is corrected to `94743`, supported by the current
[quest record](https://www.wowhead.com/quest=94743/special-assignment-precision-excision)
and [achievement record](https://www.wowhead.com/achievement=62105/lysikas-would-be-proud).

Investigating the Rise, Uprising, and the Val/Naigtal Showdown achievements
continue to read their incomplete World Quest IDs from Blizzard's achievement
criteria API. Static duplication would become stale as criteria change.

## In-game verification

The developer reported this release-candidate checklist working in game on
2026-09-14:

- On a character missing **Lysikas Would Be Proud**, verify that **Special
  Assignment: Precision Excision** is shown when quest `94743` is active.
- Complete it without missing and verify the task disappears after the
  achievement state refreshes.
- Open the World Quest list in each base Midnight zone, Val or Naigtal, and The
  Coiled Isle; verify tasks are discovered without duplicate output.
- Verify Voidlight Marl and the eight Midnight reputation filters appear with
  their localized names and match representative rewards.
- Verify a current Midnight profession World Quest follows the active
  character's profession and skill settings.

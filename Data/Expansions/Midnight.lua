local WQA = WQATurbo

-- Midnight
local data = {
    name = _G.EXPANSION_NAME11
}

WQA.data[12] = data

-- World Quest achievements
--
-- For achievements whose criteria expose quest IDs through
-- GetAchievementCriteriaInfo(), no explicit criteriaType is needed. The
-- achievement registrar will map only unfinished criteria to their WQs.
--
-- Some one-off challenge achievements expose a spell/internal credit rather
-- than the WQ quest ID, so those use QUEST_SINGLE explicitly.
data.achievements = {
    {
        name = "No Time to Paws",
        id = 61219,
        criteriaType = "QUEST_SINGLE",
        criteria = 92085 -- Claw Enforcement
    },
    {
        name = "Lysikas Would Be Proud",
        id = 62105,
        criteriaType = "QUEST_SINGLE",
        criteria = 93438 -- Special Assignment: Precision Excision
    },
    {
        name = "A Stack of Snacks",
        id = 63633,
        criteriaType = "QUEST_SINGLE",
        criteria = 94967 -- Ki'clak Snack Attack
    },

    -- Slayer's Rise PvP World Quests.
    -- Blizzard exposes the individual WQ IDs as achievement criteria.
    {
        name = "Investigating the Rise",
        id = 61225
    },
    {
        name = "Uprising",
        id = 61226
    },

    -- Val / Naigtal Showdown World Quests.
    -- These rotate quickly, so use Blizzard's live achievement criteria
    -- instead of duplicating a brittle static quest-ID list here.
    {
        name = "Showdown Success: Val",
        id = 62880
    },
    {
        name = "Showdown Success: Naigtal",
        id = 62882
    }
}

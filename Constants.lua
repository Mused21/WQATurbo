local WQA = WQATurbo

-- Keep these string values stable: content data and SavedVariables use them.
---@enum RewardType
local RewardType = {
    Achievement = "ACHIEVEMENT",
    AzeriteTrait = "AZERITE_TRAIT",
    Chance = "CHANCE",
    Currency = "CURRENCY",
    Custom = "CUSTOM",
    CustomItem = "CUSTOM_ITEM",
    Gold = "GOLD",
    Item = "ITEM",
    Miscellaneous = "MISCELLANEOUS",
    ProfessionSkillup = "PROFESSION_SKILLUP",
    Recipe = "RECIPE",
    Reputation = "REPUTATION"
}

---@enum CriteriaType
local CriteriaType = {
    Achievement = "ACHIEVEMENT",
    AreaPoi = "AREA_POI",
    MissionTable = "MISSION_TABLE",
    QuestFlag = "QUEST_FLAG",
    QuestPin = "QUEST_PIN",
    QuestSingle = "QUEST_SINGLE",
    Quests = "QUESTS",
    Special = "SPECIAL"
}

---@enum TaskType
local TaskType = {
    WorldQuest = "WORLD_QUEST",
    Mission = "MISSION",
    AreaPoi = "AREA_POI"
}

---@enum TrackingMode
local TrackingMode = {
    Default = "default",
    Disabled = "disabled",
    Always = "always",
    Exclusive = "exclusive",
    WasEarnedByMe = "wasEarnedByMe"
}

WQA.Constants = {
    RewardType = RewardType,
    CriteriaType = CriteriaType,
    TaskType = TaskType,
    TrackingMode = TrackingMode
}

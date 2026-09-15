-- Run from the repository root: lua5.1 tools/test_match_reason.lua
WQATurbo = {
    Constants = {},
    L = setmetatable({}, { __index = function(_, key) return key end }),
    questList = {}, missionList = {}, Criterias = { AreaPoi = { list = {} } }
}
local WQA = WQATurbo
dofile("Constants.lua")
dofile("Rewards/MatchReason.lua")

local TaskType = WQA.Constants.TaskType
local RewardType = WQA.Constants.RewardType
WQA.questList[101] = { reward = {
    achievement = { { id = 1 } },
    chance = { { id = 2 } },
    custom = true,
    item = { itemLink = "item:3", transmog = "icon", itemLevelUpgrade = 10 },
    reputation = { factionID = 4 }, recipe = "item:5", customItem = "item:6",
    currency = { currencyID = 7 }, professionSkillup = 8, gold = 9,
    azeriteTraits = { { spellID = 10 } },
    [RewardType.Miscellaneous] = { "misc" }
} }
local reasons = WQA:GetTaskMatchReasons({ id = 101, type = TaskType.WorldQuest })
assert(table.concat(reasons, "|") == table.concat({
    "Match: achievement", "Match: collectible", "Match: custom task",
    "Match: transmog", "Match: gear upgrade", "Match: reputation",
    "Match: recipe", "Match: custom reward", "Match: currency",
    "Match: profession skill-up", "Match: gold", "Match: Azerite trait",
    "Match: miscellaneous reward"
}, "|"))
assert(not table.concat(reasons, "|"):find("item reward", 1, true),
    "Specific item reasons must suppress the generic item label")
assert(WQA:GetTaskMatchReasonText({ id = 101, type = TaskType.WorldQuest }):find(
    "Matched because: Match: achievement", 1, true))

WQA.missionList[201] = { reward = { item = { itemLink = "item:11" } } }
assert(WQA:GetTaskMatchReasonText({ id = 201, type = TaskType.Mission }) ==
    "Matched because: Match: item reward")
WQA.Criterias.AreaPoi.list[301] = { [2405] = { reward = { custom = true } } }
assert(WQA:GetTaskMatchReasonText({ id = 301, mapId = 2405, type = TaskType.AreaPoi }) ==
    "Matched because: Match: custom task")
assert(WQA:GetTaskMatchReasonText({ id = 999, type = TaskType.WorldQuest }) == nil)

print("match reason tests passed")

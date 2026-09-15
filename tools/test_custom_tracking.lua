-- Run from the repository root: lua5.1 tools/test_custom_tracking.lua
WQATurbo = { Constants = {} }
local WQA = WQATurbo
dofile("Constants.lua")

local requestedMaps = {}
C_QuestLine = {
    RequestQuestLinesForMap = function(mapID)
        requestedMaps[#requestedMaps + 1] = mapID
    end
}

dofile("Tracking/Custom.lua")

local questRewards, missionRewards = {}, {}
function WQA:AddRewardToQuest(questID, rewardType)
    assert(rewardType == self.Constants.RewardType.Custom)
    questRewards[questID] = true
end
function WQA:AddRewardToMission(missionID, rewardType)
    assert(rewardType == self.Constants.RewardType.Custom)
    missionRewards[missionID] = true
end

WQA.db = {
    global = { custom = {
        worldQuest = {
            [101] = { questType = WQA.Constants.CriteriaType.QuestFlag },
            [102] = { questType = WQA.Constants.CriteriaType.QuestPin, mapID = 84 },
            [103] = { questType = WQA.Constants.TaskType.WorldQuest },
            [104] = { questType = WQA.Constants.CriteriaType.QuestPin, mapID = 85 }
        },
        mission = { [201] = {}, [202] = {} }
    } },
    profile = { custom = {
        worldQuest = { [101] = true, [102] = true, [103] = true, [104] = false },
        mission = { [201] = true, [202] = false }
    } }
}
WQA.questFlagList = {}
WQA.questPinList = {}
WQA.questPinMapList = {}

WQA:AddCustom()

assert(questRewards[101] and questRewards[102] and questRewards[103])
assert(not questRewards[104], "Disabled custom quests must stay excluded")
assert(WQA.questFlagList[101] == true)
assert(WQA.questPinList[102] == true and WQA.questPinMapList[84] == true)
assert(WQA.questPinList[104] == nil and WQA.questPinMapList[85] == nil)
assert(#requestedMaps == 1 and requestedMaps[1] == 84)
assert(missionRewards[201] and not missionRewards[202])

print("custom tracking tests passed")

-- Run from the repository root: lua5.1 tools/test_custom_options.lua
local noop = function() end
WQATurbo = { Constants = {}, RuntimeData = {}, L = setmetatable({}, {
    __index = function(_, key) return key end
}), Print = noop }
local WQA = WQATurbo
dofile("Constants.lua")
C_CurrencyInfo = {}
C_QuestLog = { GetTitleForQuestID = noop }
C_Map = { GetMapInfo = function(id) if id == 84 then return {} end end }
C_Garrison = { GetMissionLink = noop }
GetQuestLink, GetItemInfo = noop, noop
GameTooltip = { Hide = noop }
dofile("tools/load_options.lua")()
local timers, scheduled, refreshed = {}, 0, 0
function WQA:ScheduleTimer(callback, delay)
    assert(delay == 0.30)
    scheduled = scheduled + 1
    timers[scheduled] = callback
    return scheduled
end
function WQA:CancelTimer(id) timers[id] = nil end
function WQA:Refresh(mode, force)
    assert(mode == "settings" and force == true)
    refreshed = refreshed + 1
end
local function flush()
    local count = 0
    for id, callback in pairs(timers) do
        timers[id] = nil
        callback()
        count = count + 1
    end
    return count
end
WQA.db = { global = { custom = {} }, profile = { custom = {} } }
WQA.options = { args = { custom = { args = {} } } }
WQA.data = { custom = { questType = WQA.Constants.TaskType.WorldQuest,
    mission = { rewardType = "none", rewardID = "" } } }
local specs = {
    { "worldQuest", "quest", "CreateCustomQuest", "wqID" },
    { "worldQuestReward", "reward", "CreateCustomReward", "worldQuestReward" },
    { "mission", "mission", "CreateCustomMission", "missionID" },
    { "missionReward", "missionReward", "CreateCustomMissionReward", "missionReward" }
}
local invalid = { "", "  ", "abc", "0", "-1", "1.5", "1e999", math.huge, 0/0, false }
for _, spec in ipairs(specs) do
    local group, page, method, field = unpack(spec)
    WQA.db.profile.custom[group] = {}
    WQA.options.args.custom.args[page] = { args = {} }
    local draft = group == "mission" and WQA.data.custom.mission or WQA.data.custom
    local before = scheduled
    for _, value in ipairs(invalid) do
        draft[field] = value
        assert(WQA[method](WQA) == false, group)
        assert(WQA.db.global.custom[group] == nil)
    end
    draft[field] = nil
    assert(WQA[method](WQA) == false)
    assert(scheduled == before)
    draft[field] = " 101 "
    assert(WQA[method](WQA) == true)
    assert(scheduled == before + 1)
    local entry = WQA.db.global.custom[group][101]
    draft[field] = "00101"
    assert(WQA[method](WQA) == false)
    assert(WQA.db.global.custom[group][101] == entry)
    assert(scheduled == before + 1)
    local args = WQA.options.args.custom.args[page].args
    args["101"].set(nil, true)
    assert(WQA.db.profile.custom[group][101] == true)
    args["101"].set(nil, false)
    assert(WQA.db.profile.custom[group][101] == false)
    assert(scheduled == before + 3)
end
assert(flush() == 1 and refreshed == 1, "rapid mutations must coalesce")
local quest = WQA.options.args.custom.args.quest.args
local entry = WQA.db.global.custom.worldQuest[101]
local before = scheduled
quest["101questType"].set(nil, WQA.Constants.CriteriaType.QuestPin)
assert(entry.questType == WQA.Constants.TaskType.WorldQuest and scheduled == before)
for _, value in ipairs(invalid) do
    if value ~= "" and value ~= "  " then quest["101mapID"].set(nil, value) end
end
quest["101mapID"].set(nil, "999999")
assert(entry.mapID == nil and scheduled == before)
quest["101mapID"].set(nil, " 84 ")
assert(entry.mapID == 84 and scheduled == before + 1)
quest["101questType"].set(nil, WQA.Constants.CriteriaType.QuestPin)
assert(entry.questType == WQA.Constants.CriteriaType.QuestPin and scheduled == before + 2)
quest["101mapID"].set(nil, "")
assert(entry.mapID == 84 and scheduled == before + 2)
WQA.data.custom.wqID = "102"
WQA.data.custom.questType = WQA.Constants.CriteriaType.QuestPin
WQA.data.custom.mapID = ""
assert(WQA:CreateCustomQuest() == false)
WQA.data.custom.mapID = "84"
assert(WQA:CreateCustomQuest() == true)
assert(WQA.db.global.custom.worldQuest[102].mapID == 84)
local mission = WQA.options.args.custom.args.mission.args
before = scheduled
for _, value in ipairs(invalid) do
    if value ~= "" and value ~= "  " then mission["101Reward"].set(nil, value) end
end
assert(scheduled == before and WQA.db.global.custom.mission[101].rewardID == nil)
mission["101Reward"].set(nil, "42")
assert(WQA.db.global.custom.mission[101].rewardID == 42)
mission["101RewardType"].set(nil, "item")
mission["101Reward"].set(nil, "")
assert(WQA.db.global.custom.mission[101].rewardID == nil and scheduled == before + 3)
WQA.data.custom.mission.missionID = "102"
WQA.data.custom.mission.rewardID = "bad"
assert(WQA:CreateCustomMission() == false and WQA.db.global.custom.mission[102] == nil)
for _, spec in ipairs(specs) do
    local group, page = spec[1], spec[2]
    local args = WQA.options.args.custom.args[page].args
    before = scheduled
    args["101Delete"].func()
    assert(WQA.db.global.custom[group][101] == nil)
    assert(scheduled == before + 1)
    for key in pairs(args) do assert(not key:match("^101"), "stale deleted control: " .. key) end
end
assert(flush() == 1 and refreshed == 2)
before = scheduled
WQA:UpdateCustom()
assert(scheduled == before, "building options must not refresh")
print("Custom editor validation and refresh tests passed")

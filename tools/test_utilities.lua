-- Run from the repository root: lua5.1 tools/test_utilities.lua
WQATurbo = {
    Constants = {},
    RuntimeData = {
        EmissaryQuestIDsByExpansion = { [8] = { 9001 } },
        ValNaigtalRotation = {
            portalMapID = 2405,
            valMapID = 2599,
            naigtalMapID = 2600,
            naigtalReferenceResetWeek = 2947
        }
    },
    ExpansionList = { [8] = "Battle for Azeroth", [12] = "Midnight" },
    ZoneIDList = { [8] = { 80 }, [12] = { 2405 } },
    questList = {},
    missionList = {}
}
local WQA = WQATurbo
dofile("Constants.lua")

local mapInfo = {}
C_Map = { GetMapInfo = function(mapID) return mapInfo[mapID] end }
C_QuestLog = { GetTitleForQuestID = function(questID) return "Quest " .. questID end }
C_TaskQuest = {
    GetQuestZoneID = function(questID) return questID == 100 and 80 or nil end,
    GetQuestTimeLeftMinutes = function(questID) return questID + 10 end
}
C_AreaPoiInfo = {
    GetAreaPOISecondsLeft = function() return 180 end,
    GetAreaPOIInfo = function(mapID, poiID)
        return mapID == 2405 and poiID == 300 and { name = "Portal event" } or nil
    end
}
C_Garrison = { GetMissionLink = function(id) return "mission:" .. id end }
GetQuestLink = function(id) return id == 100 and "quest:" .. id or nil end
GetTime = function() return 1000 end

dofile("Utilities.lua")

WQA.questList[100] = {}
WQA.questList[9001] = { isEmissary = true }
WQA.missionList[200] = { expansion = 8, offerEndTime = 1600 }
WQA.missionList[201] = { expansion = 8, shipyard = true }

assert(WQA:GetQuestZoneID(100) == 80)
assert(WQA:GetQuestZoneID(55463) == 1462, "Static zone overrides must survive")
assert(WQA:GetQuestZoneID(9001) == "Emissary")
assert(WQA:GetMissionZoneID(200) == -8 and WQA:GetMissionZoneID(201) == -8.5)

local TaskType = WQA.Constants.TaskType
local worldQuest = { id = 100, type = TaskType.WorldQuest }
local mission = { id = 200, type = TaskType.Mission }
local areaPoi = { id = 300, mapId = 2405, type = TaskType.AreaPoi }
local calling = { id = 101, type = TaskType.WorldQuest, expansion = 9 }
assert(WQA:GetTaskZoneID(worldQuest) == 80)
assert(WQA:GetTaskZoneID(mission) == -8)
assert(WQA:GetTaskZoneID(areaPoi) == 2405)

assert(WQA:GetMapInfo(80).name == "Map 80")
mapInfo[80] = { name = "Test Zone" }
assert(WQA:GetQuestZoneName(100) == "Test Zone")
mapInfo[80] = { name = "Changed Zone" }
assert(WQA:GetQuestZoneName(100) == "Test Zone", "Resolved zone names should cache")
assert(WQA:GetTaskZoneName(mission) == "Mission Table")
assert(WQA:GetMissionZoneName(201) == "Shipyard")

assert(WQA:GetExpansionByMapId(80) == 8)
assert(WQA:GetExpansionByMapId(1169) == 8)
assert(WQA:GetExpansionByMapId(9999) == -1)
assert(WQA:GetExpansionByQuestID(100) == 8)
assert(WQA:GetExpansionByQuestID(9001) == 8)
assert(WQA:GetExpansion(worldQuest) == 8)
assert(WQA:GetExpansion(mission) == 8)
assert(WQA:GetExpansion(areaPoi) == 12)
assert(WQA:GetExpansion(calling) == 9)
assert(WQA:GetExpansionName(99) == "Unknown")

assert(WQA:GetMissionTimeLeftMinutes(200) == 10)
assert(WQA:GetMissionTimeLeftMinutes(201) == 0)
assert(WQA:GetTaskTime(worldQuest) == 110)
assert(WQA:GetTaskTime(mission) == 10)
assert(WQA:GetTaskTime(areaPoi) == 3)
assert(WQA:GetTaskLink(worldQuest) == "quest:100")
assert(WQA:GetTaskLink({ id = 101, type = TaskType.WorldQuest }) == "Quest 101")
assert(WQA:GetTaskLink(mission) == "mission:200")
assert(WQA:GetTaskLink(areaPoi) == "Portal event")

print("utility routing tests passed")

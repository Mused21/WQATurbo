---@class WQATurbo
local WQA = WQATurbo
local TaskType = WQA.Constants.TaskType
local EmissaryQuestIDList = WQA.RuntimeData.EmissaryQuestIDsByExpansion

local GetTitleForQuestID = C_QuestLog.GetTitleForQuestID
local SECONDS_PER_WEEK = 7 * 24 * 60 * 60
local MAP_AVAILABILITY_CACHE_SECONDS = 60


function WQA:GetExpansionByMissionID(missionID)
    return WQA.missionList[missionID].expansion
end

local questZoneIDList = {
    -- Outside Influences
    [55463] = 1462,
    [55658] = 1462,
    [55688] = 1462,
    [55718] = 1462,
    [55765] = 1462,
    [55885] = 1462,
    [56053] = 1462,
    [55813] = 1462,
    [56301] = 1462,
    [56142] = 1462,
    [55528] = 1462,
    [56365] = 1462,
    [56572] = 1462,
    [56501] = 1462,
    [56493] = 1462,
    [56552] = 1462,
    [56558] = 1462,
    [55575] = 1462,
    [55672] = 1462,
    [55717] = 1462,
    [56049] = 1462,
    [56469] = 1462,
    [55816] = 1462,
    [55905] = 1462,
    [56184] = 1462,
    [56306] = 1462,
    [54090] = 1462,
    [56355] = 1462,
    [56523] = 1462,
    [56410] = 1462,
    [56508] = 1462,
    [56471] = 1462,
    [56405] = 1462,
    -- Periodic Destruction
    [55121] = 1355
}

function WQA:GetQuestZoneID(questID)
    if WQA.questList[questID] and WQA.questList[questID].isEmissary then
        return "Emissary"
    end
    return questZoneIDList[questID] or C_TaskQuest.GetQuestZoneID(questID)
end

function WQA:GetMissionZoneID(missionID)
    if WQA.missionList[missionID].shipyard == true then
        return -self:GetExpansionByMissionID(missionID) - .5
    else
        return -self:GetExpansionByMissionID(missionID)
    end
end

function WQA:GetTaskZoneID(task)
    if task.type == TaskType.Mission then
        return self:GetMissionZoneID(task.id)
    elseif task.type == TaskType.WorldQuest then
        return self:GetQuestZoneID(task.id)
    elseif task.type == TaskType.AreaPoi then
        return task.mapId
    end
end

function WQA:GetMapInfo(mapID)
    local info = mapID and C_Map.GetMapInfo(mapID)
    if info and info.name then return info end
    -- Do not cache this fallback: metadata can become available later.
    return { name = mapID and ("Map " .. tostring(mapID)) or "Unknown", pending = true }
end

function WQA:GetQuestZoneName(questID)
    if WQA.questList[questID].isEmissary then
        return "Emissary"
    end
    if not WQA.questList[questID].info then
        WQA.questList[questID].info = {}
    end
    local info = WQA.questList[questID].info
    if info.zoneName then return info.zoneName end
    local mapInfo = self:GetMapInfo(self:GetQuestZoneID(questID))
    if not mapInfo.pending then info.zoneName = mapInfo.name end
    return mapInfo.name
end

function WQA:GetMissionZoneName(missionID)
    if WQA.missionList[missionID].shipyard == true then
        return "Shipyard"
    else
        return "Mission Table"
    end
end

function WQA:GetTaskZoneName(task)
    if task.type == TaskType.Mission then
        return self:GetMissionZoneName(task.id)
    end

    if task.type == TaskType.AreaPoi then
        return self:GetMapInfo(task.mapId).name
    end

    return self:GetQuestZoneName(task.id)
end

local ExpansionByZoneID = {
    -- BfA
    [1169] = 8 -- Tol Dagor
}

function WQA:GetExpansionByMapId(mapId)
    if ExpansionByZoneID[mapId] then
        return ExpansionByZoneID[mapId]
    end

    for expansion, zones in pairs(WQA.ZoneIDList) do
        for _, v in pairs(zones) do
            if mapId == v then
                return expansion
            end
        end
    end

    return -1
end

function WQA:GetExpansionByQuestID(questID)
    local zoneID = self:GetQuestZoneID(questID)

    local expansionId = self:GetExpansionByMapId(zoneID)

    if (expansionId > 0) then
        return expansionId
    end

    for expansion, v in pairs(EmissaryQuestIDList) do
        for _, id in pairs(v) do
            if type(id) == "table" then
                id = id.id
            end
            if id == questID then
                return expansion
            end
        end
    end
    return -1
end

function WQA:GetExpansion(task)
	if task.expansion then
		return task.expansion
	end

	if task.type == TaskType.Mission then
        return self:GetExpansionByMissionID(task.id)
    end

    if task.type == TaskType.AreaPoi then
        return self:GetExpansionByMapId(task.mapId)
    end

    return self:GetExpansionByQuestID(task.id)
end

function WQA:GetExpansionName(id)
    return WQA.ExpansionList[id] or "Unknown"
end

function WQA:GetMissionTimeLeftMinutes(id)
    if not WQA.missionList[id].offerEndTime then
        return 0
    else
        return (WQA.missionList[id].offerEndTime - GetTime()) / 60
    end
end

function WQA:GetTaskTime(task)
    if task.type == TaskType.WorldQuest then
        return C_TaskQuest.GetQuestTimeLeftMinutes(task.id)
    elseif task.type == TaskType.Mission then
        return self:GetMissionTimeLeftMinutes(task.id)
    elseif task.type == TaskType.AreaPoi then
        local seconds = C_AreaPoiInfo.GetAreaPOISecondsLeft(task.id)
        if seconds then
            return seconds / 60
        end
    end
end

function WQA:GetTaskLink(task)
    if task.type == TaskType.WorldQuest then
        return GetQuestLink(task.id) or GetTitleForQuestID(task.id)
    elseif task.type == TaskType.Mission then
        return C_Garrison.GetMissionLink(task.id)
    elseif task.type == TaskType.AreaPoi then
        local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(task.mapId, task.id)
        return poiInfo and poiInfo.name
    end
end

local function getActiveValNaigtalMapFromAreaPOI(rotation)
    if not C_AreaPoiInfo
        or type(C_AreaPoiInfo.GetAreaPOIForMap) ~= "function"
        or type(C_AreaPoiInfo.GetAreaPOIInfo) ~= "function"
        or not C_Map or type(C_Map.GetMapInfo) ~= "function"
    then
        return nil
    end

    local mapIDByName = {}
    for _, mapID in ipairs({ rotation.valMapID, rotation.naigtalMapID }) do
        local ok, mapInfo = pcall(C_Map.GetMapInfo, mapID)
        if ok and mapInfo and type(mapInfo.name) == "string" then
            mapIDByName[mapInfo.name] = mapID
        end
    end

    local ok, areaPoiIDs = pcall(
        C_AreaPoiInfo.GetAreaPOIForMap,
        rotation.portalMapID
    )
    if not ok or type(areaPoiIDs) ~= "table" then
        return nil
    end

    for _, areaPoiID in ipairs(areaPoiIDs) do
        local infoOk, areaPoiInfo = pcall(
            C_AreaPoiInfo.GetAreaPOIInfo,
            rotation.portalMapID,
            areaPoiID
        )
        local areaPoiName = infoOk and areaPoiInfo and areaPoiInfo.name

        if type(areaPoiName) == "string" then
            for zoneName, mapID in pairs(mapIDByName) do
                if areaPoiName:find(zoneName, 1, true) then
                    return mapID
                end
            end
        end
    end

    return nil
end

local function getActiveValNaigtalMapFromReset(rotation)
    local getSecondsUntilWeeklyReset = C_DateAndTime
        and C_DateAndTime.GetSecondsUntilWeeklyReset

    if type(GetServerTime) ~= "function"
        or type(getSecondsUntilWeeklyReset) ~= "function"
    then
        return nil
    end

    local okServerTime, serverTime = pcall(GetServerTime)
    local okReset, secondsUntilReset = pcall(getSecondsUntilWeeklyReset)

    if not okServerTime or not okReset
        or type(serverTime) ~= "number" or serverTime <= 0
        or type(secondsUntilReset) ~= "number" or secondsUntilReset < 0
        or secondsUntilReset > SECONDS_PER_WEEK + 24 * 60 * 60
    then
        return nil
    end

    -- Regional resets occur between Tuesday and Thursday. Nearest-week
    -- rounding maps every region's next reset to the same Unix week number.
    local nextResetWeek = math.floor(
        (serverTime + secondsUntilReset) / SECONDS_PER_WEEK + 0.5
    )

    if (nextResetWeek - rotation.naigtalReferenceResetWeek) % 2 == 0 then
        return rotation.naigtalMapID
    end

    return rotation.valMapID
end

-- Prefer the live portal Area POI so a Blizzard schedule change is followed
-- automatically. The reset parity remains a region-independent fallback for
-- login periods when POI metadata has not arrived yet. If both signals are
-- unavailable, return nil so callers keep both maps rather than hiding a task.
function WQA:GetActiveValNaigtalMapID()
    local now = type(GetTime) == "function" and GetTime() or nil
    local cached = self._valNaigtalAvailabilityCache

    if cached and now and cached.expiresAt > now then
        return cached.mapID
    end

    local rotation = WQA.RuntimeData.ValNaigtalRotation
    local activeMapID = getActiveValNaigtalMapFromAreaPOI(rotation)
        or getActiveValNaigtalMapFromReset(rotation)

    if now then
        self._valNaigtalAvailabilityCache = {
            mapID = activeMapID,
            expiresAt = now + MAP_AVAILABILITY_CACHE_SECONDS
        }
    end

    return activeMapID
end

function WQA:IsMapCurrentlyAvailable(mapID)
    local rotation = WQA.RuntimeData.ValNaigtalRotation

    if mapID ~= rotation.valMapID and mapID ~= rotation.naigtalMapID then
        return true
    end

    local activeMapID = self:GetActiveValNaigtalMapID()
    return activeMapID == nil or activeMapID == mapID
end

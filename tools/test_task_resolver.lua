-- Run from the repository root with Lua 5.1:
-- lua5.1 tools/test_task_resolver.lua
local function noop() end

local activeQuests = {}
local timers = {}
local poiInfoByKey = {}
local currentTime = 0

GetTime = function() return currentTime end

C_TaskQuest = {
	IsActive = function(questID)
		return activeQuests[questID] == true
	end
}

C_Timer = {
	NewTimer = function(delay, callback)
		local timer = {
			delay = delay,
			callback = callback,
			cancelled = false
		}

		function timer:Cancel()
			self.cancelled = true
		end

		timers[#timers + 1] = timer
		return timer
	end
}

C_AreaPoiInfo = {
	GetAreaPOIInfo = function(mapID, poiID)
		return poiInfoByKey[tostring(mapID) .. ":" .. tostring(poiID)]
	end
}

WQATurbo = {
	Criterias = {},
	Constants = {
		TaskType = {
			WorldQuest = "WORLD_QUEST",
			Mission = "MISSION",
			AreaPoi = "AREA_POI"
		}
	}
}

local WQA = WQATurbo
dofile("Criterias/AreaPoi.lua")
local AreaPoiCriteria = WQA.Criterias.AreaPoi
dofile("Runtime/TaskResolver.lua")

local rewardLinksReady = false
local missionDataPending = true
local chatPublications = {}
local popupPublications = {}
local ldbPublications = {}
local openPopupRefreshes = 0
local ldbUpdates = 0

WQA.db = {
	profile = {
		options = {
			PopUp = false
		}
	}
}
WQA.first = false
WQA.rewards = false
WQA.emissaryRewards = true
WQA.questList = {
	[101] = { reward = { gold = 100 } },
	[102] = { reward = { item = {} } },
	[103] = { reward = { gold = 100 } },
	[104] = { reward = { gold = 100 } }
}
WQA.missionList = {
	[201] = { reward = { gold = 100 } },
	[202] = { reward = { item = {} } }
}
WQA.watched = {}
WQA.watchedMissions = {}
WQA.Criterias = {
	AreaPoi = {
		watched = {},
		Check = function()
			local new = {}

			if not (WQA.Criterias.AreaPoi.watched[301] or {})[401] then
				new[301] = { [401] = true }
			end

			return {
				active = { [301] = { [401] = true } },
				new = new,
				retry = false
			}
		end
	}
}

activeQuests[101] = true
activeQuests[102] = true
activeQuests[103] = true

WQA.Debug = noop
WQA.ShouldIncludeWorldQuestForCurrentMode = function(_, questID)
	return questID ~= 103
end
WQA.EmissaryIsActive = function() return false end
WQA.isQuestPinActive = function() return false end
WQA.IsQuestFlaggedCompleted = function() return false end
WQA.GetTaskLink = function() return "quest-link" end
WQA.GetRewardLinkByID = function(_, questID)
	if questID == 102 and not rewardLinksReady then
		return nil
	end

	return "quest-reward-link"
end
WQA.SetRewardLinkByID = noop
WQA.CheckMissions = function()
    return { [201] = true, [202] = true }, missionDataPending
end
WQA.GetRewardLinkByMissionID = function(_, missionID)
	if missionID == 202 and not rewardLinksReady then
		return nil
	end

	return "mission-reward-link"
end
WQA.SetRewardLinkByMissionID = noop
WQA.SortQuestList = function(_, tasks) return tasks end
WQA.AnnounceChat = function(_, tasks)
	chatPublications[#chatPublications + 1] = tasks
end
WQA.AnnouncePopUp = function(_, tasks)
	popupPublications[#popupPublications + 1] = tasks
end
WQA.AnnounceLDB = function(_, tasks)
	ldbPublications[#ldbPublications + 1] = tasks
end
WQA.UpdateLDBText = function()
	ldbUpdates = ldbUpdates + 1
end
WQA.TurboRefreshOpenPopup = function()
	openPopupRefreshes = openPopupRefreshes + 1
end

local function taskKeys(tasks)
	local keys = {}

	for _, task in ipairs(tasks) do
		keys[task.type .. ":" .. tostring(task.id)] = true
	end

	return keys
end

-- Ready quests, missions and POIs publish even while unrelated reward links
-- remain pending. A Settings refresh stays silent and creates one retry timer.
WQA:CheckWQ("settings")
local active = taskKeys(WQA.activeTasks)
assert(active["WORLD_QUEST:101"])
assert(active["MISSION:201"])
assert(active["AREA_POI:301"])
assert(not active["WORLD_QUEST:102"])
assert(not active["WORLD_QUEST:103"])
assert(not active["WORLD_QUEST:104"])
assert(not active["MISSION:202"])
assert(#WQA.newTasks == 3)
assert(#chatPublications == 0 and #popupPublications == 0 and #ldbPublications == 0)
assert(#timers == 1 and timers[1].delay == 0.50)
assert(ldbUpdates == 1 and openPopupRefreshes == 1)

-- Repeated unresolved publication coalesces behind the existing timer.
WQA:CheckWQ("settings")
assert(#timers == 1)

-- A normal successful pass cancels an outstanding retry.
rewardLinksReady = true
missionDataPending = false
WQA:CheckWQ("settings")
assert(timers[1].cancelled == true)
assert(WQA._wqaTurboCheckRetryTimer == nil)

-- The retry callback uses new-task mode, so a newly ready quest and mission
-- are announced once without re-announcing already watched tasks.
rewardLinksReady = false
WQA.watched[102] = nil
WQA.watchedMissions[202] = nil
WQA:CheckWQ("settings")
assert(#timers == 2)
rewardLinksReady = true
timers[2].callback()
assert(WQA._wqaTurboCheckRetryTimer == nil)
assert(#chatPublications == 1)
local announced = taskKeys(chatPublications[1])
assert(announced["WORLD_QUEST:102"])
assert(announced["MISSION:202"])
assert(not announced["WORLD_QUEST:101"])
assert(not announced["MISSION:201"])
assert(not announced["AREA_POI:301"])

-- Explicit popup and LDB display modes route the complete ready-task set to
-- the requested output without recursively refreshing an already-open popup.
local refreshesBeforePopup = openPopupRefreshes
WQA:CheckWQ("popup")
assert(#popupPublications == 1)
assert(openPopupRefreshes == refreshesBeforePopup)
WQA:CheckWQ("LDB")
assert(#ldbPublications == 1)

-- A live calling is a quest task, but not a World Quest and must not be
-- rejected by World Quest type or zone filtering.
local callingActive = true
WQA.questList[105] = { reward = { custom = true }, isCalling = true }
WQA.IsCallingActive = function(_, questID)
	assert(questID == 105)
	return callingActive
end
local originalEligibility = WQA.ShouldIncludeWorldQuestForCurrentMode
WQA.ShouldIncludeWorldQuestForCurrentMode = function(self, questID)
	if questID == 105 then error("Calling must bypass World Quest filters") end
	return originalEligibility(self, questID)
end
WQA:CheckWQ("settings")
assert(taskKeys(WQA.activeTasks)["WORLD_QUEST:105"])
local callingTask
for _, task in ipairs(WQA.activeTasks) do
	if task.id == 105 then callingTask = task end
end
assert(callingTask and callingTask.expansion == 9,
	"Live Callings must render under the Shadowlands expansion")
callingActive = false
WQA:CheckWQ("settings")
assert(not taskKeys(WQA.activeTasks)["WORLD_QUEST:105"])
WQA.questList[105].hasOtherSource = true
WQA.ShouldIncludeWorldQuestForCurrentMode = originalEligibility
activeQuests[105] = true
WQA:CheckWQ("settings")
assert(taskKeys(WQA.activeTasks)["WORLD_QUEST:105"],
	"A custom entry for a rotated-out Calling keeps its original behavior")
activeQuests[105] = nil
WQA.questList[105] = nil

-- Automatic publication must not reopen a closed popup for an empty result.
-- Manual publication still exposes the empty state, and automatic publication
-- resumes as soon as an interesting task exists.
local savedCheckMissions = WQA.CheckMissions
local savedAreaPoiCheck = WQA.Criterias.AreaPoi.Check
local savedActiveQuests = activeQuests
activeQuests = {}
WQA.CheckMissions = function() return {}, false end
WQA.Criterias.AreaPoi.Check = function()
	return { active = {}, new = {}, retry = false }
end
WQA.db.profile.options.PopUp = true
local popupCount = #popupPublications
WQA:CheckWQ(nil, nil, true)
assert(#popupPublications == popupCount, "Empty automatic refresh must keep a closed popup closed")
WQA:CheckWQ()
assert(#popupPublications == popupCount + 1, "Manual output must still show the empty popup state")
activeQuests[101] = true
WQA:CheckWQ(nil, nil, true)
assert(#popupPublications == popupCount + 2, "Automatic refresh must open for an interesting task")
WQA.db.profile.options.PopUp = false
activeQuests = savedActiveQuests
WQA.CheckMissions = savedCheckMissions
WQA.Criterias.AreaPoi.Check = savedAreaPoiCheck

-- Area POI readiness is isolated per POI. One missing reward link or missing
-- POI payload must not publish that POI or block a separate ready POI.
local allPoiRewardsReady = false
local cachedPoiLinks = {}
AreaPoiCriteria.list = {
	[301] = { [401] = { reward = { chance = { { id = 1 }, { id = 2 } } } } },
	[302] = { [402] = { reward = { gold = 100 } } },
	[303] = { [403] = { reward = { custom = true } } }
}
AreaPoiCriteria.watched = {}
poiInfoByKey = {
	["401:301"] = { name = "Pending rewards" },
	["403:303"] = { name = "Ready POI" }
}
WQA.GetRewardLinkByID = function(_, poiID, _, _, index)
	if poiID == 301 and index == 1 and not allPoiRewardsReady then
		return nil
	end
	return "poi-reward-link"
end
WQA.SetRewardLinkByID = function(_, poiID, _, _, index)
	cachedPoiLinks[tostring(poiID) .. ":" .. tostring(index)] = true
end

local poiResult = AreaPoiCriteria:Check()
assert(poiResult.retry == true)
assert(poiResult.active[301] == nil, "A partly ready POI must remain pending")
assert(poiResult.active[302] == nil, "Missing POI information must remain pending")
assert(poiResult.pending["poi:301@map:401"] and poiResult.pending["poi:302@map:402"])
assert(poiResult.active[303][403] == true, "A ready POI must publish independently")
assert(cachedPoiLinks["301:2"] == true, "Ready links should be cached during a partial pass")

allPoiRewardsReady = true
poiInfoByKey["402:302"] = { name = "POI metadata ready" }
poiResult = AreaPoiCriteria:Check()
assert(poiResult.retry == false)
assert(poiResult.active[301][401] and poiResult.active[302][402] and poiResult.active[303][403])
assert(poiResult.new[301][401] and poiResult.new[302][402] and poiResult.new[303][403])

-- Readiness retries stop after 30 seconds, and callbacks from an older refresh
-- generation cannot run against the new task lists.
rewardLinksReady = false
missionDataPending = false
currentTime = 0
WQA:ResetTaskResolverRetry()
local boundedGeneration = WQA._wqaTurboTaskGeneration
WQA:CheckWQ("settings")
local boundedTimer = timers[#timers]
assert(boundedTimer and boundedTimer.delay == 0.50)

currentTime = 31
boundedTimer.callback()
assert(WQA._wqaTurboCheckRetryTimer == nil)
assert(WQA._wqaTurboCheckRetryTimedOut == true)
assert(WQA._wqaTaskTimeout["mission:202"])
local timerCountAfterTimeout = #timers
WQA:ScheduleTaskResolverCheck()
assert(#timers == timerCountAfterTimeout, "Timed-out readiness must not keep scheduling")

WQA:ScheduleTaskResolverCheck(true)
local eventTimer = timers[#timers]
assert(#timers == timerCountAfterTimeout + 1)
assert(WQA._wqaTurboCheckRetryTimedOut == nil)
WQA:ResetTaskResolverRetry()
assert(eventTimer.cancelled == true)
assert(WQA._wqaTurboTaskGeneration == boundedGeneration + 1)
eventTimer.callback()
assert(WQA._wqaTurboCheckRetryTimer == nil, "A stale generation callback must be inert")

print("Task resolver regression checks passed (progressive readiness, bounded generation retries, filtering and display modes).")

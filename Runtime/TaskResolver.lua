---@class WQATurbo
local WQA = WQATurbo
local TaskType = WQA.Constants.TaskType

--[[
WQA Turbo progressive CheckWQ
==============================

Upstream CheckWQ has an all-or-nothing retry rule:

  if ANY active quest/reward link is unavailable:
      schedule CheckWQ again
      return without publishing ANY active quests

That defeats Turbo's non-blocking reward scanner. Two completely ready quests
can be held back for many seconds by one unrelated quest whose item/quest link
has not entered Blizzard's local cache yet.

Turbo changes readiness from GLOBAL to PER-TASK:

  ready WQ  -> publish now
  ready WQ  -> publish now
  pending WQ -> omit only this WQ and retry it later

A retry uses mode="new", so quests that become ready later are announced once
instead of re-printing all already-known quests.

The same principle is applied to missions/POIs: unavailable auxiliary data may
schedule a later retry but does not block ready world quests.
]]

function WQA:PrintReadinessStatus()
	local function show(label, entries)
		local ids = {}
		for id in pairs(entries or {}) do ids[#ids + 1] = id end
		table.sort(ids)
		print("|cff00ccffWQA TURBO READINESS|r " .. label .. ": " .. (#ids > 0 and table.concat(ids, ", ") or "none"))
	end
	show("task pending", self._wqaTaskPending)
	show("task last timeout", self._wqaTaskTimeout)
	show("emissary pending", self._wqaEmissaryScan and self._wqaEmissaryScan.pending)
	show("emissary last timeout", self._wqaEmissaryTimeout)
end

local IsActive = C_TaskQuest.IsActive

local CHECK_RETRY_DELAY_SECONDS = 0.50
local CHECK_RETRY_MAX_AGE_SECONDS = 30.0
local SHADOWLANDS_EXPANSION_ID = 9

local function cancelCheckRetry(self)
	local timer = self._wqaTurboCheckRetryTimer

	if timer and timer.Cancel then
		timer:Cancel()
	end

	self._wqaTurboCheckRetryTimer = nil
end

---Cancel pending readiness work and begin ownership for a new full refresh.
function WQA:ResetTaskResolverRetry()
	cancelCheckRetry(self)
	self._wqaTurboTaskGeneration = (self._wqaTurboTaskGeneration or 0) + 1
	self._wqaTurboCheckRetryStartedAt = nil
	self._wqaTurboCheckRetryTimedOut = nil
	self._wqaTaskPending = nil
	self._wqaTaskTimeout = nil
	self._wqaTaskRetryMode = self._wqaTurboRefreshMode == "settings" and "settings" or "new"
end

---Schedule one generation-owned readiness pass.
---@param restartWindow boolean? Start a new retry window after an external event.
---@return boolean scheduled
function WQA:ScheduleTaskResolverCheck(restartWindow)
	-- Coalesce all unresolved task/link retries into one timer.
	if self._wqaTurboCheckRetryTimer then
		return true
	end

	local now = GetTime()
	if restartWindow or not self._wqaTurboCheckRetryStartedAt then
		self._wqaTurboCheckRetryStartedAt = now
		self._wqaTurboCheckRetryTimedOut = nil
	end

	if now - self._wqaTurboCheckRetryStartedAt >= CHECK_RETRY_MAX_AGE_SECONDS then
		self._wqaTurboCheckRetryTimedOut = true
		self._wqaTaskTimeout = self._wqaTaskPending
		return false
	end

	local generation = self._wqaTurboTaskGeneration or 0
	local timer
	timer = C_Timer.NewTimer(
		CHECK_RETRY_DELAY_SECONDS,
		function()
			if
				self._wqaTurboCheckRetryTimer ~= timer
				or (self._wqaTurboTaskGeneration or 0) ~= generation
			then
				return
			end

			self._wqaTurboCheckRetryTimer = nil

			-- Keep Settings/profile generations silent; ordinary retries use "new".
			self:CheckWQ(self._wqaTaskRetryMode or "new", true)
		end
	)
	self._wqaTurboCheckRetryTimer = timer
	return true
end

local function isQuestActive(self, questID)
	if self.questList[questID] and self.questList[questID].isCalling then
		if self:IsCallingActive(questID) then return true end
		if not self.questList[questID].hasOtherSource then return false end
	end

	if not self:ShouldIncludeWorldQuestForCurrentMode(questID) then
		return false
	end

	return
		IsActive(questID)
		or self:EmissaryIsActive(questID)
		or self:isQuestPinActive(questID)
		or self:IsQuestFlaggedCompleted(questID)
end

local function worldQuestTask(self, questID)
	local task = {
		id = questID,
		type = TaskType.WorldQuest
	}

	if self.questList[questID].isCalling and self:IsCallingActive(questID) then
		task.expansion = SHADOWLANDS_EXPANSION_ID
	end

	return task
end

---Resolve/cache all currently required links for one active world quest.
---@return boolean ready
function WQA:TurboPrepareWorldQuest(questID)
	local quest = self.questList[questID]

	if not quest or not quest.reward then
		return false
	end

	local questLink = self:GetTaskLink({
		id = questID,
		type = TaskType.WorldQuest
	})

	if not questLink then
		return false
	end

	local sawReward = false

	for rewardType, rewardData in pairs(quest.reward) do
		sawReward = true

		if
			rewardType ~= "custom"
			and rewardType ~= "professionSkillup"
			and rewardType ~= "gold"
		then
			local link =
				self:GetRewardLinkByID(
					questID,
					rewardType,
					rewardData,
					1
				)

			if not link then
				return false
			end

			self:SetRewardLinkByID(
				questID,
				rewardType,
				rewardData,
				1,
				link
			)

			if
				rewardType == "achievement"
				or rewardType == "chance"
				or rewardType == "azeriteTraits"
			then
				for i = 2, #rewardData do
					link =
						self:GetRewardLinkByID(
							questID,
							rewardType,
							rewardData,
							i
						)

					if not link then
						return false
					end

					self:SetRewardLinkByID(
						questID,
						rewardType,
						rewardData,
						i,
						link
					)
				end
			end
		end
	end

	-- A questList entry is expected to contain at least one reward. Preserve
	-- the upstream conservative behaviour for malformed/half-built entries:
	-- wait for the next pass rather than exposing a row the rendering code
	-- cannot describe.
	return sawReward
end

---Resolve/cache links for one mission.
---@return boolean ready
function WQA:TurboPrepareMission(missionID)
	local mission = self.missionList[missionID]

	if not mission or not mission.reward then
		return false
	end

	local sawReward = false

	for rewardType, rewardData in pairs(mission.reward) do
		sawReward = true

		if
			rewardType ~= "custom"
			and rewardType ~= "professionSkillup"
			and rewardType ~= "gold"
		then
			local link =
				self:GetRewardLinkByMissionID(
					missionID,
					rewardType,
					rewardData,
					1
				)

			if not link then
				return false
			end

			self:SetRewardLinkByMissionID(
				missionID,
				rewardType,
				rewardData,
				1,
				link
			)
		end
	end

	return sawReward
end

---Turbo replacement for upstream CheckWQ().
---
---The optional second argument is internal and only indicates that this call
---came from Turbo's coalesced retry timer. The third preserves automatic
---refresh intent so an empty result cannot reopen a popup the user closed.
function WQA:CheckWQ(mode, fromRetry, automatic)
	self:Debug("CheckWQ (WQA Turbo progressive)", mode)

	local activeQuests = {}
	local newQuests = {}
	local retryStarted = self._wqaTurboCheckRetryStartedAt
	local requestPins = not retryStarted or GetTime() - retryStarted < CHECK_RETRY_MAX_AGE_SECONDS
	local pending = self.RefreshQuestPins and self:RefreshQuestPins(requestPins) or {}
	self._wqaTaskPending = pending
	local needsRetry = next(pending) ~= nil

	for questID in pairs(self.questList or {}) do
		if isQuestActive(self, questID) then
			if self:TurboPrepareWorldQuest(questID) then
				activeQuests[questID] = true

				if not self.watched[questID] then
					newQuests[questID] = true
				end
			else
				-- Only this quest waits. Ready quests continue to publication.
				pending["world-quest:" .. tostring(questID)] = true
				needsRetry = true
			end
		end
	end

	local activeMissions, missionsNeedRetry = self:CheckMissions()
	local readyMissions = {}
	local newMissions = {}

	if type(activeMissions) == "table" then
		for missionID in pairs(activeMissions) do
			if self:TurboPrepareMission(missionID) then
				readyMissions[missionID] = true

				if not self.watchedMissions[missionID] then
					newMissions[missionID] = true
				end
			else
				pending["mission:" .. tostring(missionID)] = true
				needsRetry = true
			end
		end
	else
		activeMissions = {}
		needsRetry = true
	end

	if missionsNeedRetry then
		needsRetry = true
	end
	for key in pairs(self._wqaMissionPending or {}) do pending[key] = true end

	local pois = self.Criterias.AreaPoi:Check()

	if not pois then
		pois = {
			active = {},
			new = {},
			retry = true
		}
	end

	if pois.retry then
		needsRetry = true
	end
	for key in pairs(pois.pending or {}) do pending[key] = true end

	-- Publish all READY tasks now. This is the crucial difference from
	-- upstream, which returned before reaching this block if anything needed
	-- a retry.
	self.activeTasks = {}

	for id in pairs(activeQuests) do
		table.insert(self.activeTasks, worldQuestTask(self, id))
	end

	for id in pairs(readyMissions) do
		table.insert(
			self.activeTasks,
			{
				id = id,
				type = TaskType.Mission
			}
		)
	end

	for poiId, mapIds in pairs(pois.active or {}) do
		for mapId in pairs(mapIds) do
			table.insert(
				self.activeTasks,
				{
					id = poiId,
					mapId = mapId,
					type = TaskType.AreaPoi
				}
			)
		end
	end

	self.activeTasks = self:SortQuestList(self.activeTasks)

	self.newTasks = {}

	for id in pairs(newQuests) do
		self.watched[id] = true
		table.insert(self.newTasks, worldQuestTask(self, id))
	end

	for id in pairs(newMissions) do
		self.watchedMissions[id] = true

		table.insert(
			self.newTasks,
			{
				id = id,
				type = TaskType.Mission
			}
		)
	end

	for poiId, mapIds in pairs(pois.new or {}) do
		for mapId in pairs(mapIds) do
			if not self.Criterias.AreaPoi.watched[poiId] then
				self.Criterias.AreaPoi.watched[poiId] = {}
			end

			self.Criterias.AreaPoi.watched[poiId][mapId] = true

			table.insert(
				self.newTasks,
				{
					id = poiId,
					mapId = mapId,
					type = TaskType.AreaPoi
				}
			)
		end
	end

	if mode == "settings" then
		-- Settings-triggered refreshes update the cache (and any already-open
		-- popup below) without spamming chat or opening a new popup.
	elseif mode == "new" then
		self:AnnounceChat(self.newTasks, self.first)

		if
			self.db.profile.options.PopUp == true
			and (automatic ~= true or next(self.newTasks) ~= nil)
		then
			self:AnnouncePopUp(self.newTasks, self.first)
		end
	elseif mode == "popup" then
		self:AnnouncePopUp(self.activeTasks)
	elseif mode == "LDB" then
		self:AnnounceLDB(self.activeTasks)
	else
		self:AnnounceChat(self.activeTasks)

		if
			self.db.profile.options.PopUp == true
			and (automatic ~= true or next(self.activeTasks) ~= nil)
		then
			self:AnnouncePopUp(self.activeTasks)
		end
	end

	self:UpdateLDBText(next(self.activeTasks), next(self.newTasks))

	if needsRetry then
		self:ScheduleTaskResolverCheck()
	else
		cancelCheckRetry(self)
		self._wqaTurboCheckRetryStartedAt = nil
		self._wqaTurboCheckRetryTimedOut = nil
	end

	-- A retry or background enrichment may have changed activeTasks while the
	-- user has the minimap popup open. Rebuild that popup from the current
	-- ready-task set without starting another data scan.
	if mode ~= "popup" and self.TurboRefreshOpenPopup then
		self:TurboRefreshOpenPopup()
	end
end

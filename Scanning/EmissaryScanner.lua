---@class WQATurbo
local WQA = WQATurbo
local RewardType = WQA.Constants.RewardType
local EmissaryQuestIDList = WQA.RuntimeData.EmissaryQuestIDsByExpansion

local GetBountiesForMapID = C_QuestLog.GetBountiesForMapID
local EMISSARY_MAP_IDS = { 627, 875 }
local EMISSARY_RETRY_INTERVAL_SECONDS = 1.5
local EMISSARY_MAX_PENDING_AGE_SECONDS = 30.0

local function CancelEmissaryRetry(state)
	if state and state.retryTimer and state.retryTimer.Cancel then
		state.retryTimer:Cancel()
	end

	if state then
		state.retryTimer = nil
	end
end

---Scan emissary rewards, retrying only while Blizzard data is pending.
---@param state table?
function WQA:EmissaryReward(state)
	if not state then
		CancelEmissaryRetry(self._wqaEmissaryScan)
		self._wqaEmissaryGeneration = (self._wqaEmissaryGeneration or 0) + 1
		state = {
			generation = self._wqaEmissaryGeneration,
			startedAt = GetTime(),
			retryTimer = nil
		}
		self._wqaEmissaryScan = state
		self._wqaEmissaryTimeout = nil
	elseif
		self._wqaEmissaryScan ~= state
		or self._wqaEmissaryGeneration ~= state.generation
	then
		return
	end

	self.emissaryRewards = false
	local retry = false
	local relevanceMayHaveChanged = false
	local pending = {}
	state.pending = pending

	for _, mapID in ipairs(EMISSARY_MAP_IDS) do
		local bounties = GetBountiesForMapID(mapID)
		if not bounties then
			pending["emissary-map:" .. tostring(mapID)] = true
			retry = true
		else
			for _, emissary in ipairs(bounties) do
				relevanceMayHaveChanged = true
				local questID = emissary.questID
				if self.db.profile.options.emissary[questID] == true then
					self:AddEmissaryReward(questID, RewardType.Custom, nil, true)
				end
				if HaveQuestData(questID) and HaveQuestRewardData(questID) then
					local itemsPending = self:CheckItems(questID, true)
					if itemsPending then pending["emissary:" .. tostring(questID)] = true end
					retry = itemsPending or retry
					self:CheckCurrencies(questID, true)
				else
					pending["emissary:" .. tostring(questID)] = true
					retry = true
				end
			end
		end
	end

	if retry and GetTime() - state.startedAt < EMISSARY_MAX_PENDING_AGE_SECONDS then
		if relevanceMayHaveChanged and self.ScheduleTaskResolverCheck then
			self:ScheduleTaskResolverCheck()
		end

		local timer
		timer = C_Timer.NewTimer(EMISSARY_RETRY_INTERVAL_SECONDS, function()
			if
				self._wqaEmissaryScan ~= state
				or self._wqaEmissaryGeneration ~= state.generation
				or state.retryTimer ~= timer
			then
				return
			end

			state.retryTimer = nil
			self:EmissaryReward(state)
		end)
		state.retryTimer = timer
		return
	end

	CancelEmissaryRetry(state)
	if retry then self._wqaEmissaryTimeout = pending end
	if self._wqaEmissaryScan == state then
		self._wqaEmissaryScan = nil
		self.emissaryRewards = true
		if self.ScheduleTaskResolverCheck then
			self:ScheduleTaskResolverCheck(true)
		end
	end
end

---Return whether a configured emissary quest is active in the quest log.
---@param questID number
---@return boolean
function WQA:EmissaryIsActive(questID)
	local emissary = {}
	for _, expansion in pairs(EmissaryQuestIDList) do
		for _, id in pairs(expansion) do
			if type(id) == "table" then
				id = id.id
			end
			if id == questID then
				emissary[id] = true
			end
		end
	end

	if emissary[questID] ~= true then
		return false
	end

	local index = 1
	while C_QuestLog.GetInfo(index) do
		local questLogQuestID = C_QuestLog.GetInfo(index).questID
		if questLogQuestID == questID then
			return true
		end
		index = index + 1
	end
	return false
end

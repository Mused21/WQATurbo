---@class WQATurbo
local WQA = WQATurbo
local RewardType = WQA.Constants.RewardType
local CallingData = WQA.ShadowlandsCallingData

local MAX_CALLING_DURATION_SECONDS = 3 * 24 * 60 * 60

local function activeCovenantID()
	return C_Covenants and C_Covenants.GetActiveCovenantID
		and C_Covenants.GetActiveCovenantID() or 0
end

local function serverTime()
	if GetServerTime then return GetServerTime() end
	return time()
end

local function callingOptions(self)
	local options = self.db.profile.options.shadowlandsCallingsByCovenant
	return type(options) == "table" and options or {}
end

local function isCovenantTracked(self, covenantID)
	return callingOptions(self)[covenantID] == true
end

local function hasTrackedCovenant(self)
	for _, covenantID in ipairs(CallingData.CovenantIDs) do
		if isCovenantTracked(self, covenantID) then return true end
	end
	return false
end

local function callingRotations(self)
	local rotations = self.db.global.shadowlandsCallingRotations
	if type(rotations) ~= "table" then
		rotations = {}
		self.db.global.shadowlandsCallingRotations = rotations
	end
	return rotations
end

local function callingCompletions(self)
	local completions = self.db.char.shadowlandsCallingCompletions
	if type(completions) ~= "table" then
		completions = {}
		self.db.char.shadowlandsCallingCompletions = completions
	end
	return completions
end

local function pruneExpiredCallingState(self, now)
	for familyID, expiresAt in pairs(callingRotations(self)) do
		if type(expiresAt) ~= "number" or expiresAt <= now then
			self.db.global.shadowlandsCallingRotations[familyID] = nil
		end
	end

	for questID, expiresAt in pairs(callingCompletions(self)) do
		if type(expiresAt) ~= "number" or expiresAt <= now then
			self.db.char.shadowlandsCallingCompletions[questID] = nil
		end
	end
end

local function isCallingCompleted(self, questID, now)
	local expiresAt = callingCompletions(self)[questID]
	if type(expiresAt) == "number" and expiresAt > now then return true end
	return C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
		and C_QuestLog.IsQuestFlaggedCompleted(questID) == true
end

local function addCalling(active, questID, familyID, covenantID, expiresAt)
	active[questID] = {
		familyID = familyID,
		covenantID = covenantID,
		expiresAt = expiresAt,
	}
end

local function rebuildActiveCallings(self)
	local active = {}
	self._wqaCallingQuestIDs = active

	if self.db.profile.options.trackShadowlandsCallings ~= true then return end
	if self._wqaCallingCovenantID ~= activeCovenantID() then return end

	local now = serverTime()
	pruneExpiredCallingState(self, now)

	for familyID, expiresAt in pairs(callingRotations(self)) do
		local family = CallingData.QuestFamilies[familyID]
		if family then
			for _, covenantID in ipairs(CallingData.CovenantIDs) do
				local questID = family[covenantID]
				if isCovenantTracked(self, covenantID)
					and not isCallingCompleted(self, questID, now)
				then
					addCalling(active, questID, familyID, covenantID, expiresAt)
				end
			end
		end
	end

	if isCovenantTracked(self, self._wqaCallingCovenantID) then
		for questID, expiresAt in pairs(self._wqaUnmappedCallingQuestIDs or {}) do
			if expiresAt > now and not isCallingCompleted(self, questID, now) then
				addCalling(active, questID, nil, self._wqaCallingCovenantID, expiresAt)
			end
		end
	end
end

function WQA:RequestCallings()
	if
		self.db.profile.options.trackShadowlandsCallings == true
		and hasTrackedCovenant(self)
		and activeCovenantID() > 0
		and C_CovenantCallings
		and C_CovenantCallings.RequestCallings
	then
		C_CovenantCallings.RequestCallings()
	end
end

---Register the selected covenants' live Calling variants in the task model.
function WQA:RegisterCallings()
	if not self.questList then return end
	rebuildActiveCallings(self)

	for questID, calling in pairs(self._wqaCallingQuestIDs) do
		local existing = self.questList[questID]
		local hasOtherSource = existing and
			(existing.isCalling and existing.hasOtherSource or not existing.isCalling)
		self:AddRewardToQuest(questID, RewardType.Custom)
		self.questList[questID].isCalling = true
		self.questList[questID].hasOtherSource = hasOtherSource or false
		self.questList[questID].callingCovenantID = calling.covenantID
		self.questList[questID].callingExpiresAt = calling.expiresAt
		self.questList[questID].callingZoneID = CallingData.SanctumMapIDs[calling.covenantID]

		if C_QuestLog and C_QuestLog.RequestLoadQuestByID then
			C_QuestLog.RequestLoadQuestByID(questID)
		end
	end
end

---A full refresh reuses known unexpired rotations, then requests fresh data.
function WQA:AddCallings()
	self._wqaCallingCovenantID = activeCovenantID()
	self:RegisterCallings()
	self:RequestCallings()
end

---Merge the active covenant payload into the shared Calling rotation cache.
function WQA:UpdateCallings(callings)
	if self.db.profile.options.trackShadowlandsCallings ~= true then return end

	local covenantID = activeCovenantID()
	local now = serverTime()
	local rotations = callingRotations(self)
	local completions = callingCompletions(self)
	local unmapped = {}

	pruneExpiredCallingState(self, now)

	if type(callings) == "table" then
		for _, calling in ipairs(callings) do
			local questID = type(calling) == "table" and calling.questID
			if type(questID) == "number" and questID > 0 then
				local secondsLeft = C_TaskQuest.GetQuestTimeLeftSeconds(questID)
				local expiresAt = now +
					(type(secondsLeft) == "number" and secondsLeft > 0
						and secondsLeft or MAX_CALLING_DURATION_SECONDS)
				local mapping = CallingData.ByQuestID[questID]

				if mapping and mapping.covenantID == covenantID then
					rotations[mapping.familyID] = expiresAt
					completions[questID] = nil
				elseif not mapping then
					unmapped[questID] = expiresAt
				end
			end
		end
	end

	self._wqaCallingCovenantID = covenantID
	self._wqaUnmappedCallingQuestIDs = unmapped
	self:RegisterCallings()
	if self.questList then self:ScheduleTaskResolverCheck(true) end
end

function WQA:CompleteCalling(questID)
	local calling = self._wqaCallingQuestIDs and self._wqaCallingQuestIDs[questID]
	if not calling then return end

	callingCompletions(self)[questID] = calling.expiresAt

	self._wqaCallingQuestIDs[questID] = nil
	if self.questList then self:ScheduleTaskResolverCheck(true) end
	self:RequestCallings()
end

function WQA:ClearCallings()
	local hadCallings = self._wqaCallingQuestIDs and next(self._wqaCallingQuestIDs) ~= nil
	self._wqaCallingCovenantID = nil
	self._wqaCallingQuestIDs = nil
	self._wqaUnmappedCallingQuestIDs = nil
	if hadCallings and self.questList then self:ScheduleTaskResolverCheck(true) end
end

function WQA:IsCallingActive(questID)
	return self.db.profile.options.trackShadowlandsCallings == true
		and self._wqaCallingCovenantID == activeCovenantID()
		and self._wqaCallingQuestIDs
		and self._wqaCallingQuestIDs[questID] ~= nil
end

function WQA:GetCallingCovenantName(questID)
	local calling = self._wqaCallingQuestIDs and self._wqaCallingQuestIDs[questID]
	local covenantID = calling and calling.covenantID
	local covenantData = covenantID and C_Covenants and C_Covenants.GetCovenantData
		and C_Covenants.GetCovenantData(covenantID)
	return covenantData and covenantData.name
end

function WQA:GetCallingTimeLeftMinutes(questID)
	local calling = self._wqaCallingQuestIDs and self._wqaCallingQuestIDs[questID]
	if not calling or type(calling.expiresAt) ~= "number" then return 0 end
	return math.max(0, (calling.expiresAt - serverTime()) / 60)
end

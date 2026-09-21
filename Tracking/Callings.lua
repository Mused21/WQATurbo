---@class WQATurbo
local WQA = WQATurbo
local RewardType = WQA.Constants.RewardType

local function activeCovenantID()
	return C_Covenants and C_Covenants.GetActiveCovenantID
		and C_Covenants.GetActiveCovenantID() or 0
end

function WQA:RequestCallings()
	if
		self.db.profile.options.trackShadowlandsCallings == true
		and activeCovenantID() > 0
		and C_CovenantCallings
		and C_CovenantCallings.RequestCallings
	then
		C_CovenantCallings.RequestCallings()
	end
end

---Register the current covenant's live calling IDs in the normal task model.
function WQA:RegisterCallings()
	if
		self.db.profile.options.trackShadowlandsCallings ~= true
		or self._wqaCallingCovenantID ~= activeCovenantID()
		or not self.questList
	then
		return
	end

	for questID in pairs(self._wqaCallingQuestIDs or {}) do
		local existing = self.questList[questID]
		local hasOtherSource = existing and
			(existing.isCalling and existing.hasOtherSource or not existing.isCalling)
		self:AddRewardToQuest(questID, RewardType.Custom)
		self.questList[questID].isCalling = true
		self.questList[questID].hasOtherSource = hasOtherSource or false
	end
end

---A full refresh reuses the last event result, then requests fresh callings.
function WQA:AddCallings()
	self:RegisterCallings()
	self:RequestCallings()
end

---The event payload contains only currently available/accepted callings.
function WQA:UpdateCallings(callings)
	if self.db.profile.options.trackShadowlandsCallings ~= true then return end

	local questIDs = {}
	if type(callings) == "table" then
		for _, calling in ipairs(callings) do
			local questID = type(calling) == "table" and calling.questID
			if type(questID) == "number" and questID > 0 then
				questIDs[questID] = true
			end
		end
	end

	self._wqaCallingCovenantID = activeCovenantID()
	self._wqaCallingQuestIDs = questIDs
	self:RegisterCallings()
	if self.questList then self:ScheduleTaskResolverCheck(true) end
end

function WQA:ClearCallings()
	local hadCallings = self._wqaCallingQuestIDs and next(self._wqaCallingQuestIDs) ~= nil
	self._wqaCallingCovenantID = nil
	self._wqaCallingQuestIDs = nil
	if hadCallings and self.questList then self:ScheduleTaskResolverCheck(true) end
end

function WQA:IsCallingActive(questID)
	return self.db.profile.options.trackShadowlandsCallings == true
		and self._wqaCallingCovenantID == activeCovenantID()
		and self._wqaCallingQuestIDs
		and self._wqaCallingQuestIDs[questID] == true
end

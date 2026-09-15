---@class WQATurbo
local WQA = WQATurbo

local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted

---Refresh the available Quest Pin index with at most one query per map.
---@param requestPending boolean?
---@return table pending
function WQA:RefreshQuestPins(requestPending)
	local active, pending = {}, {}
	local now = GetTime()
	self._wqaQuestPinRequests = self._wqaQuestPinRequests or {}
	local requests = self._wqaQuestPinRequests
	for mapID in pairs(self.questPinMapList or {}) do
		local pins = C_QuestLine.GetAvailableQuestLines(mapID)
		if type(pins) ~= "table" then
			pending["quest-pin-map:" .. tostring(mapID)] = true
			if requestPending ~= false and (not requests[mapID] or now - requests[mapID] >= 1.5) then
				requests[mapID] = now
				C_QuestLine.RequestQuestLinesForMap(mapID)
			end
		else
			for _, pin in pairs(pins) do
				if pin.questID then active[pin.questID] = true end
			end
		end
	end
	self._wqaQuestPinsActive = active
	return pending
end

---Return whether a configured Quest Pin is currently available.
---@param questID number
---@return boolean
function WQA:isQuestPinActive(questID)
	if not self._wqaQuestPinsActive then self:RefreshQuestPins() end
	return self._wqaQuestPinsActive[questID] == true
end

---Return whether a configured Quest Flag should currently be shown.
---@param questID number
---@return boolean
function WQA:IsQuestFlaggedCompleted(questID)
	if self.questFlagList[questID] then
		return not IsQuestFlaggedCompleted(questID)
	else
		return false
	end
end

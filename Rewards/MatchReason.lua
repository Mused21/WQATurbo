---@class WQATurbo
local WQA = WQATurbo
local TaskType = WQA.Constants.TaskType
local RewardType = WQA.Constants.RewardType
local L = WQA.L

local function AddReason(reasons, seen, reason)
	if not seen[reason] then
		seen[reason] = true
		reasons[#reasons + 1] = reason
	end
end

---Return stable, localized categories explaining why a task matched.
---@param task table
---@return table reasons
function WQA:GetTaskMatchReasons(task)
	local entry
	if task.type == TaskType.WorldQuest then
		entry = self.questList[task.id]
	elseif task.type == TaskType.Mission then
		entry = self.missionList[task.id]
	elseif task.type == TaskType.AreaPoi then
		entry = self.Criterias.AreaPoi.list[task.id]
		entry = entry and entry[task.mapId]
	end

	local reward = entry and entry.reward
	if type(reward) ~= "table" then return {} end

	local reasons, seen = {}, {}
	if reward.achievement then AddReason(reasons, seen, L["Match: achievement"]) end
	if reward.chance then AddReason(reasons, seen, L["Match: collectible"]) end
	if reward.custom then AddReason(reasons, seen, L["Match: custom task"]) end

	if reward.item then
		local item = reward.item
		local specific = false
		if item.transmog then
			AddReason(reasons, seen, L["Match: transmog"])
			specific = true
		end
		if item.itemLevelUpgrade or item.itemPercentUpgrade or item.AzeriteArmorCache or item.cache then
			AddReason(reasons, seen, L["Match: gear upgrade"])
			specific = true
		end
		if not specific then AddReason(reasons, seen, L["Match: item reward"]) end
	end

	if reward.reputation then AddReason(reasons, seen, L["Match: reputation"]) end
	if reward.recipe then AddReason(reasons, seen, L["Match: recipe"]) end
	if reward.customItem then AddReason(reasons, seen, L["Match: custom reward"]) end
	if reward.currency then AddReason(reasons, seen, L["Match: currency"]) end
	if reward.professionSkillup then AddReason(reasons, seen, L["Match: profession skill-up"]) end
	if reward.gold then AddReason(reasons, seen, L["Match: gold"]) end
	if reward.azeriteTraits then AddReason(reasons, seen, L["Match: Azerite trait"]) end
	if reward[RewardType.Miscellaneous] then AddReason(reasons, seen, L["Match: miscellaneous reward"]) end

	return reasons
end

---Return one tooltip-ready explanation line for a task.
---@param task table
---@return string?
function WQA:GetTaskMatchReasonText(task)
	local reasons = self:GetTaskMatchReasons(task)
	if #reasons == 0 then return nil end
	return string.format(L["Matched because: %s"], table.concat(reasons, ", "))
end

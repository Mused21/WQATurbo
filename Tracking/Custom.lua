---@class WQATurbo
local WQA = WQATurbo
local RewardType = WQA.Constants.RewardType
local CriteriaType = WQA.Constants.CriteriaType

---Register enabled user-defined World Quests and missions for this refresh.
function WQA:AddCustom()
	-- Custom World Quests
	if type(self.db.global.custom.worldQuest) == "table" then
		for questID, v in pairs(self.db.global.custom.worldQuest) do
			if self.db.profile.custom.worldQuest[questID] == true then
				self:AddRewardToQuest(questID, RewardType.Custom)
				if v.questType == CriteriaType.QuestFlag then
					self.questFlagList[questID] = true
				elseif v.questType == CriteriaType.QuestPin and v.mapID then
					C_QuestLine.RequestQuestLinesForMap(v.mapID)
					self.questPinMapList[v.mapID] = true
					self.questPinList[questID] = true
				end
			end
		end
	end

	-- Custom Missions
	if type(self.db.global.custom.mission) == "table" then
		for missionID in pairs(self.db.global.custom.mission) do
			if self.db.profile.custom.mission[missionID] == true then
				self:AddRewardToMission(missionID, RewardType.Custom)
			end
		end
	end
end

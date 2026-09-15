---@class WQATurbo
local WQA = WQATurbo

local armorTypeByClassID = {
	[1] = "plate", -- Warrior
	[2] = "plate", -- Paladin
	[3] = "mail", -- Hunter
	[4] = "leather", -- Rogue
	[5] = "cloth", -- Priest
	[6] = "plate", -- Death Knight
	[7] = "mail", -- Shaman
	[8] = "cloth", -- Mage
	[9] = "cloth", -- Warlock
	[10] = "leather", -- Monk
	[11] = "leather", -- Druid
	[12] = "leather", -- Demon Hunter
	[13] = "mail" -- Evoker
}

local armorTypes = { "cloth", "leather", "mail", "plate" }

local function GetItemLinkField(itemLink, wantedField)
	if type(itemLink) ~= "string" then
		return nil
	end

	local itemString = string.match(itemLink, "item:([^|]+)")
	if not itemString then
		return nil
	end

	local fieldStart = 1
	for fieldIndex = 1, wantedField do
		local separator = string.find(itemString, ":", fieldStart, true)
		local fieldValue
		if separator then
			fieldValue = string.sub(itemString, fieldStart, separator - 1)
		else
			fieldValue = string.sub(itemString, fieldStart)
		end

		if fieldIndex == wantedField then
			return tonumber(fieldValue)
		end
		if not separator then
			return nil
		end
		fieldStart = separator + 1
	end

	return nil
end

---Return whether every known collectible outcome from a fixed-pool container
---is already owned. Missing data always keeps the container visible.
---@param itemID number
---@param itemLink string|nil
---@return boolean complete
---@return boolean retry
function WQA:IsContainerCollectibleComplete(itemID, itemLink)
	local containers = self.data and self.data.containerCollectibles
	local container = containers and containers[itemID]
	if not container then
		return false, false
	end

	if container.unsupportedItemContexts then
		-- Item context is field 12 in a Retail item hyperlink. Some historical
		-- Azerite cache contexts resolve to different finite pools; do not apply
		-- the ordinary zone-reward pool to those links.
		local itemContext = GetItemLinkField(itemLink, 12)
		if itemContext and container.unsupportedItemContexts[itemContext] then
			return false, false
		end
	end

	if container.questIDs then
		if not C_QuestLog.IsQuestFlaggedCompleted
			and not C_QuestLog.IsQuestFlaggedCompletedOnAccount
		then
			return false, false
		end

		for _, questID in ipairs(container.questIDs) do
			local completed = C_QuestLog.IsQuestFlaggedCompleted
				and C_QuestLog.IsQuestFlaggedCompleted(questID)
			if not completed and C_QuestLog.IsQuestFlaggedCompletedOnAccount then
				completed = C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID)
			end
			if not completed then
				return false, false
			end
		end
	end

	if container.transmogSources then
		local transmog = C_TransmogCollection
		local getAppearanceInfo = transmog and transmog.GetAppearanceInfoBySource
		local getAllAppearanceSources = transmog and transmog.GetAllAppearanceSources
		local getAppearanceSourceInfo = transmog and transmog.GetAppearanceSourceInfo
		if not getAppearanceInfo or not getAllAppearanceSources or not getAppearanceSourceInfo then
			return false, false
		end

		local _, _, classID = UnitClass("player")
		local armorType = armorTypeByClassID[classID]
		local sourceGroups = {}
		if container.transmogSources.all then
			table.insert(sourceGroups, container.transmogSources.all)
		end
		if container.allArmorTypes then
			for _, candidateArmorType in ipairs(armorTypes) do
				local sources = container.transmogSources[candidateArmorType]
				if sources then
					table.insert(sourceGroups, sources)
				end
			end
		elseif armorType and container.transmogSources[armorType] then
			table.insert(sourceGroups, container.transmogSources[armorType])
		end
		local checkedSource = false

		for _, sourceIDs in ipairs(sourceGroups) do
			checkedSource = true
			for _, sourceID in ipairs(sourceIDs) do
				local appearanceInfo = getAppearanceInfo(sourceID)
				if not appearanceInfo or not appearanceInfo.appearanceID then
					return false, true
				end

				local appearanceSources = getAllAppearanceSources(appearanceInfo.appearanceID)
				if not appearanceSources then
					return false, true
				end

				local appearanceIsCollected = false
				local sourceDataUnavailable = false
				for _, appearanceSourceID in ipairs(appearanceSources) do
					local sourceInfo = getAppearanceSourceInfo(appearanceSourceID)
					if sourceInfo and sourceInfo.isCollected then
						appearanceIsCollected = true
						break
					end
					if not sourceInfo then
						sourceDataUnavailable = true
					end
				end

				if not appearanceIsCollected and sourceDataUnavailable then
					return false, true
				end
				if not appearanceIsCollected then
					return false, false
				end
			end
		end

		if not checkedSource then
			return false, false
		end
	end

	return true, false
end

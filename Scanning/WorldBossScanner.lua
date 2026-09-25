---@class WQATurbo
local WQA = WQATurbo
local RewardType = WQA.Constants.RewardType

local MAX_COORDINATE_DISTANCE_SQUARED = 0.0025
local AMBIGUOUS_DISTANCE_DELTA_SQUARED = 0.000025
local requestedItemData = {}
local encounterIndexByTier = {}

---Return whether Blizzard's quest metadata can represent a World Boss. Modern
---quests have the dedicated type/tag. Legacy bosses often report Normal and
---use the broader Epic Elite World Quest classification; those remain only
---candidates until ResolveWorldBossEncounter confirms a unique journal boss.
---@param questTagInfo table?
---@return boolean
function WQA:IsWorldBossQuestCandidate(questTagInfo)
	if type(questTagInfo) ~= "table" then
		return false
	end

	if
		questTagInfo.worldQuestType == Enum.QuestTagType.WorldBoss
		or questTagInfo.tagID == 289
	then
		return true
	end

	return questTagInfo.worldQuestType == Enum.QuestTagType.Normal
		and questTagInfo.quality == Enum.WorldQuestQuality.Epic
		and questTagInfo.isElite == true
end

local function requestItemData(itemID)
	if
		type(itemID) == "number"
		and not requestedItemData[itemID]
		and C_Item
		and type(C_Item.RequestLoadItemDataByID) == "function"
	then
		requestedItemData[itemID] = true
		C_Item.RequestLoadItemDataByID(itemID)
	end
end

local function normalizedName(value)
	if type(value) ~= "string" then
		return nil
	end

	return string.lower((string.gsub(value, "^%s*(.-)%s*$", "%1")))
end

local function getEncounterIdentity(encounterID)
	if type(EJ_GetEncounterInfo) ~= "function" then
		return nil
	end

	local encounterName, _, _, _, _, instanceID = EJ_GetEncounterInfo(encounterID)
	if type(instanceID) ~= "number" then
		return nil
	end

	return encounterID, instanceID, encounterName
end

local function getTierForWork(self, work)
	if type(work.expansion) == "number" then
		return work.expansion
	end

	for expansion, mapIDs in pairs(self.ZoneIDList or {}) do
		for _, mapID in ipairs(mapIDs) do
			if mapID == work.mapID then
				return expansion
			end
		end
	end

	return nil
end

local function buildEncounterIndexForTier(tier)
	if encounterIndexByTier[tier] then
		return encounterIndexByTier[tier]
	end
	if
		type(EJ_GetCurrentTier) ~= "function"
		or type(EJ_SelectTier) ~= "function"
		or type(EJ_SelectInstance) ~= "function"
		or type(EJ_GetInstanceByIndex) ~= "function"
		or type(EJ_GetEncounterInfoByIndex) ~= "function"
	then
		return nil
	end

	local savedTier = EJ_GetCurrentTier()
	local frame = _G.EncounterJournal
	local savedInstanceID = frame and frame.instanceID
	local savedEncounterID = frame and frame.encounterID
	local savedDifficultyID = type(EJ_GetDifficulty) == "function" and EJ_GetDifficulty() or nil
	local index = { byName = {}, entries = {} }
	local ok = pcall(function()
		EJ_SelectTier(tier)
		local instanceIndex = 1
		while true do
			local instanceID = EJ_GetInstanceByIndex(instanceIndex, true)
			if not instanceID then
				break
			end

			-- EJ_GetEncounterInfoByIndex can return no data for an explicit
			-- journalInstanceID until any instance has first been selected.
			EJ_SelectInstance(instanceID)
			local encounterIndex = 1
			while true do
				local encounterName, _, encounterID =
					EJ_GetEncounterInfoByIndex(encounterIndex, instanceID)
				if not encounterName or not encounterID then
					break
				end

				local name = normalizedName(encounterName)
				local entry = {
					encounterID = encounterID,
					instanceID = instanceID,
					encounterName = encounterName,
					name = name
				}
				index.entries[#index.entries + 1] = entry
				if name then
					if index.byName[name] ~= nil then
						index.byName[name] = false
					else
						index.byName[name] = entry
					end
				end
				encounterIndex = encounterIndex + 1
			end
			instanceIndex = instanceIndex + 1
		end
	end)

	if type(savedTier) == "number" then
		pcall(EJ_SelectTier, savedTier)
	end
	if savedInstanceID then
		pcall(EJ_SelectInstance, savedInstanceID)
		if savedDifficultyID and type(EJ_SetDifficulty) == "function" then
			pcall(EJ_SetDifficulty, savedDifficultyID)
		end
		if savedEncounterID then
			pcall(EJ_SelectEncounter, savedEncounterID)
		end
	end
	if not ok then
		return nil
	end

	encounterIndexByTier[tier] = index
	return index
end

local function resolveEncounterWithoutMapPin(self, work, questName)
	local tier = getTierForWork(self, work)
	if not tier then
		return nil
	end

	local index = buildEncounterIndexForTier(tier)
	if not index then
		return nil
	end

	local exact = index.byName[questName]
	if exact then
		return exact.encounterID, exact.instanceID, exact.encounterName
	end
	if exact == false then
		return nil
	end

	local objectives = C_QuestLog
		and C_QuestLog.GetQuestObjectives
		and C_QuestLog.GetQuestObjectives(work.questID)
		or {}
	local match
	for _, objective in ipairs(objectives) do
		local objectiveText = normalizedName(objective.text)
		if objectiveText then
			for _, entry in ipairs(index.entries) do
				if
					entry.name
					and string.find(objectiveText, entry.name, 1, true)
				then
					if match and match.encounterID ~= entry.encounterID then
						return nil
					end
					match = entry
				end
			end
		end
	end

	if match then
		return match.encounterID, match.instanceID, match.encounterName
	end
	return nil
end

---Resolve a World Boss quest to an Encounter Journal encounter. Same-map pin
---coordinates are preferred. Some bosses expose no EJ map pins; for those,
---fall back to a unique localized quest-name or objective-name match within
---that expansion's raid journal tier.
---@param work table
---@return number? encounterID
---@return number? instanceID
---@return string? encounterName
function WQA:ResolveWorldBossEncounter(work)
	if
		type(work) ~= "table"
		or type(work.mapID) ~= "number"
		or not C_EncounterJournal
		or type(C_EncounterJournal.GetEncountersOnMap) ~= "function"
	then
		return nil
	end

	local encounters = C_EncounterJournal.GetEncountersOnMap(work.mapID) or {}

	if type(work.x) == "number" and type(work.y) == "number" then
		local closest, closestDistance, secondDistance

		for _, encounter in ipairs(encounters) do
			if
				type(encounter.encounterID) == "number"
				and type(encounter.mapX) == "number"
				and type(encounter.mapY) == "number"
			then
				local dx = work.x - encounter.mapX
				local dy = work.y - encounter.mapY
				local distance = dx * dx + dy * dy

				if not closestDistance or distance < closestDistance then
					secondDistance = closestDistance
					closestDistance = distance
					closest = encounter
				elseif not secondDistance or distance < secondDistance then
					secondDistance = distance
				end
			end
		end

		if
			closest
			and closestDistance <= MAX_COORDINATE_DISTANCE_SQUARED
			and (
				not secondDistance
				or secondDistance - closestDistance >= AMBIGUOUS_DISTANCE_DELTA_SQUARED
			)
		then
			return getEncounterIdentity(closest.encounterID)
		end
	end

	local questName = normalizedName(
		C_TaskQuest
		and C_TaskQuest.GetQuestInfoByQuestID
		and C_TaskQuest.GetQuestInfoByQuestID(work.questID)
	)
	if not questName then
		return nil
	end

	local match
	for _, encounter in ipairs(encounters) do
		local encounterName = encounter.encounterID and EJ_GetEncounterInfo(encounter.encounterID)
		if normalizedName(encounterName) == questName then
			if match then
				return nil
			end
			match = encounter
		end
	end

	if match then
		return getEncounterIdentity(match.encounterID)
	end

	return resolveEncounterWithoutMapPin(self, work, questName)
end

local function getSavedJournalState()
	local frame = _G.EncounterJournal
	return {
		frame = frame,
		instanceID = frame and frame.instanceID,
		encounterID = frame and frame.encounterID,
		difficultyID = type(EJ_GetDifficulty) == "function" and EJ_GetDifficulty() or nil,
		filterClassID = type(EJ_GetLootFilter) == "function" and select(1, EJ_GetLootFilter()) or nil,
		filterSpecID = type(EJ_GetLootFilter) == "function" and select(2, EJ_GetLootFilter()) or nil,
		slotFilter = C_EncounterJournal.GetSlotFilter()
	}
end

local function restoreJournalState(saved)
	if saved.instanceID then
		EJ_SelectInstance(saved.instanceID)
		if saved.difficultyID and type(EJ_SetDifficulty) == "function" then
			EJ_SetDifficulty(saved.difficultyID)
		end
		if saved.encounterID then
			EJ_SelectEncounter(saved.encounterID)
		end
	end

	if saved.filterClassID ~= nil and saved.filterSpecID ~= nil then
		EJ_SetLootFilter(saved.filterClassID, saved.filterSpecID)
	end
	C_EncounterJournal.SetSlotFilter(saved.slotFilter)
end

local function inspectSelectedEncounter(self, encounterID)
	local missingItems = {}
	local retry = false
	local seenLinks = {}
	local numLoot = EJ_GetNumLoot()

	if type(numLoot) ~= "number" or numLoot == 0 then
		return missingItems, true
	end

	for index = 1, numLoot do
		local itemInfo = C_EncounterJournal.GetLootInfoByIndex(index)
		if not itemInfo or not itemInfo.link or not itemInfo.itemID then
			requestItemData(itemInfo and itemInfo.itemID)
			retry = true
		elseif
			(not itemInfo.encounterID or itemInfo.encounterID == encounterID)
			and not seenLinks[itemInfo.link]
		then
			seenLinks[itemInfo.link] = true
			local itemClassID = select(6, C_Item.GetItemInfoInstant(itemInfo.link))
			if not itemClassID then
				requestItemData(itemInfo.itemID)
				retry = true
			elseif itemClassID == Enum.ItemClass.Weapon or itemClassID == Enum.ItemClass.Armor then
				local transmogable = self:IsTransmogable(itemInfo.link)
				if transmogable == nil then
					requestItemData(itemInfo.itemID)
					retry = true
				elseif transmogable then
					local transmog, transmogRetry = self:GetTrackedTransmogIcon(itemInfo.link, itemInfo.itemID)
					if transmogRetry then
						requestItemData(itemInfo.itemID)
						retry = true
					elseif transmog then
						missingItems[#missingItems + 1] = {
							itemID = itemInfo.itemID,
							itemLink = itemInfo.link,
							transmog = transmog
						}
					end
				end
			end
		end
	end

	return missingItems, retry
end

---Inspect one active World Boss without loading or manipulating the visible
---Adventure Guide. Returns whether it matched and whether its data needs retry.
---@param work table
---@return boolean matched
---@return boolean retry
function WQA:InspectWorldBossTransmog(work)
	local gear = self.db.profile.options.reward.gear
	if
		not gear.worldBossTransmog
		or (not gear.unknownAppearance and not gear.unknownSource)
	then
		return false, false
	end

	if
		type(EJ_SelectInstance) ~= "function"
		or type(EJ_SelectEncounter) ~= "function"
		or type(EJ_GetNumLoot) ~= "function"
		or type(EJ_GetLootFilter) ~= "function"
		or type(EJ_SetLootFilter) ~= "function"
		or not C_EncounterJournal
		or type(C_EncounterJournal.GetLootInfoByIndex) ~= "function"
		or type(C_EncounterJournal.GetSlotFilter) ~= "function"
		or type(C_EncounterJournal.SetSlotFilter) ~= "function"
		or type(C_EncounterJournal.ResetSlotFilter) ~= "function"
	then
		return false, false
	end

	local journal = _G.EncounterJournal
	if journal and journal.IsShown and journal:IsShown() then
		return false, true
	end

	local encounterID, instanceID, encounterName = self:ResolveWorldBossEncounter(work)
	if not encounterID then
		return false, false
	end

	if
		type(C_EncounterJournal.IsEncounterComplete) == "function"
		and C_EncounterJournal.IsEncounterComplete(encounterID)
	then
		return false, false
	end

	local _, _, classID = UnitClass("player")
	if type(classID) ~= "number" then
		return false, true
	end

	local saved = getSavedJournalState()
	local ok, missingItems, retry = pcall(function()
		EJ_SetLootFilter(classID, 0)
		C_EncounterJournal.ResetSlotFilter()
		EJ_SelectInstance(instanceID)
		EJ_SelectEncounter(encounterID)
		return inspectSelectedEncounter(self, encounterID)
	end)

	local restored = pcall(restoreJournalState, saved)
	if not ok or not restored then
		self:Debug("World Boss Encounter Journal inspection failed", encounterID)
		return false, true
	end

	if #missingItems > 0 then
		self:AddRewardToQuest(work.questID, RewardType.WorldBossTransmog, {
			encounterID = encounterID,
			encounterName = encounterName,
			missingCount = #missingItems,
			items = missingItems
		})
		-- A single confirmed missing source is sufficient to surface the boss.
		-- Continue the bounded retry when other EJ rows are unresolved so the
		-- displayed item list can become complete without withholding the match.
		return true, retry
	end

	return false, retry
end

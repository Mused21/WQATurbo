-- Run from the repository root with Lua 5.1:
-- lua5.1 tools/test_world_boss_scanner.lua

local selectedInstance = 900
local selectedEncounter = 901
local lootClass, lootSpec = 7, 264
local slotFilter = 4
local encounterComplete = false
local journalShown = false
local transmogableByLink = {}
local requestedItemData = {}
local selectedTier = 9
local lootByEncounter = {
	[101] = {
		{ itemID = 1001, link = "item:1001", encounterID = 101 },
		{ itemID = 1002, link = "item:1002", encounterID = 101 }
	}
}
local encountersByMap = {
	[10] = {
		{ encounterID = 101, mapX = 0.50, mapY = 0.50 },
		{ encounterID = 102, mapX = 0.80, mapY = 0.80 }
	},
	[20] = {
		{ encounterID = 101, mapX = 0.50, mapY = 0.50 },
		{ encounterID = 102, mapX = 0.501, mapY = 0.501 }
	}
}
local encounterData = {
	[101] = { name = "The Missing One", instanceID = 201 },
	[102] = { name = "The Other One", instanceID = 202 },
	[103] = { name = "Predaxas", instanceID = 203 },
	[104] = { name = "Nithogg", instanceID = 204 },
	[901] = { name = "Previously Selected", instanceID = 900 }
}
local instancesByTier = {
	[7] = { 204 },
	[12] = { 203 }
}
local encountersByInstance = {
	[203] = { 103 },
	[204] = { 104 }
}

Enum = {
	ItemClass = { Weapon = 2, Armor = 4 },
	QuestTagType = { Normal = 2, WorldBoss = 18 },
	WorldQuestQuality = { Common = 0, Rare = 1, Epic = 2 }
}
C_TaskQuest = {
	GetQuestInfoByQuestID = function(questID)
		if questID == 5002 then return "The Other One" end
		if questID == 5003 then return "Predaxas" end
		if questID == 5004 then return "Scourge of the Skies" end
		return "Unrelated Quest"
	end
}
C_QuestLog = {
	GetQuestObjectives = function(questID)
		if questID == 5004 then return { { text = "Nithogg slain" } } end
		return {}
	end
}
C_Item = {
	GetItemInfoInstant = function(link)
		if link == "item:1001" then return 1001, nil, nil, nil, nil, 4 end
		if link == "item:1002" then return 1002, nil, nil, nil, nil, 2 end
	end,
	RequestLoadItemDataByID = function(itemID) requestedItemData[itemID] = true end
}
C_EncounterJournal = {
	GetEncountersOnMap = function(mapID) return encountersByMap[mapID] or {} end,
	IsEncounterComplete = function() return encounterComplete end,
	GetLootInfoByIndex = function(index)
		local loot = lootByEncounter[selectedEncounter] or {}
		return loot[index]
	end,
	GetSlotFilter = function() return slotFilter end,
	SetSlotFilter = function(value) slotFilter = value end,
	ResetSlotFilter = function() slotFilter = 0 end
}

function EJ_GetEncounterInfo(encounterID)
	local data = encounterData[encounterID]
	return data and data.name, nil, nil, nil, nil, data and data.instanceID
end
function EJ_GetCurrentTier() return selectedTier end
function EJ_SelectTier(tier) selectedTier = tier end
function EJ_GetInstanceByIndex(index)
	return (instancesByTier[selectedTier] or {})[index]
end
function EJ_GetEncounterInfoByIndex(index, instanceID)
	if selectedInstance ~= instanceID then return nil end
	local encounterID = (encountersByInstance[instanceID] or {})[index]
	local data = encounterID and encounterData[encounterID]
	return data and data.name, nil, encounterID
end
function EJ_SelectInstance(instanceID) selectedInstance = instanceID end
function EJ_SelectEncounter(encounterID) selectedEncounter = encounterID end
function EJ_GetNumLoot() return #(lootByEncounter[selectedEncounter] or {}) end
function EJ_GetLootFilter() return lootClass, lootSpec end
function EJ_SetLootFilter(classID, specID) lootClass, lootSpec = classID, specID end
function EJ_GetDifficulty() return 15 end
function EJ_SetDifficulty() end
function UnitClass() return "Shaman", "SHAMAN", 7 end

EncounterJournal = {
	instanceID = 900,
	encounterID = 901,
	IsShown = function() return journalShown end
}

WQATurbo = {
	Constants = { RewardType = { WorldBossTransmog = "WORLD_BOSS_TRANSMOG" } },
	db = { profile = { options = { reward = { gear = {
		worldBossTransmog = true,
		unknownAppearance = true,
		unknownSource = true
	} } } } },
	IsTransmogable = function(_, link)
		if transmogableByLink[link] == false then return nil end
		return true
	end,
	GetTrackedTransmogIcon = function(_, _, itemID)
		return itemID == 1001 and "missing" or nil, false
	end,
	Debug = function() end
}
local WQA = WQATurbo
local added
function WQA:AddRewardToQuest(questID, rewardType, reward)
	added = { questID = questID, rewardType = rewardType, reward = reward }
end

dofile("Scanning/WorldBossScanner.lua")

assert(WQA:IsWorldBossQuestCandidate({ worldQuestType = 18 }))
assert(WQA:IsWorldBossQuestCandidate({ tagID = 289, worldQuestType = 2 }))
assert(WQA:IsWorldBossQuestCandidate({
	worldQuestType = 2, quality = 2, isElite = true
}), "Legacy Epic Elite World Quests must reach encounter confirmation")
assert(not WQA:IsWorldBossQuestCandidate({
	worldQuestType = 2, quality = 2, isElite = false
}), "Ordinary Epic World Quests must not enter World Boss resolution")

local encounterID, instanceID = WQA:ResolveWorldBossEncounter({
	questID = 5001, mapID = 10, x = 0.505, y = 0.505
})
assert(encounterID == 101 and instanceID == 201, "Nearest map pin should resolve the encounter")

encounterID = WQA:ResolveWorldBossEncounter({
	questID = 5001, mapID = 20, x = 0.5005, y = 0.5005
})
assert(encounterID == nil, "Nearly equidistant encounter pins must fail closed")

encounterID, instanceID = WQA:ResolveWorldBossEncounter({ questID = 5002, mapID = 10 })
assert(encounterID == 102 and instanceID == 202, "Exact localized name should be the coordinate fallback")

encounterID, instanceID = WQA:ResolveWorldBossEncounter({
	questID = 5003, mapID = 30, expansion = 12
})
assert(encounterID == 103 and instanceID == 203,
	"Exact quest names should resolve bosses without EJ map pins")
assert(selectedTier == 9, "Journal tier must be restored after fallback indexing")
assert(selectedInstance == 900 and selectedEncounter == 901,
	"Journal selection must be restored after fallback indexing")

encounterID, instanceID = WQA:ResolveWorldBossEncounter({
	questID = 5004, mapID = 40, expansion = 7
})
assert(encounterID == 104 and instanceID == 204,
	"Localized objective text should resolve legacy quest names to their boss")
assert(selectedTier == 9, "Journal tier must remain unchanged after cached lookup")

local matched, retry = WQA:InspectWorldBossTransmog({
	questID = 5001, mapID = 10, x = 0.50, y = 0.50
})
assert(matched and not retry, "A missing class-eligible appearance should match")
assert(added and added.questID == 5001)
assert(added.rewardType == "WORLD_BOSS_TRANSMOG" and added.reward.missingCount == 1)
assert(added.reward.items[1].itemID == 1001)
assert(added.reward.items[1].itemLink == "item:1001")
assert(added.reward.items[1].transmog == "missing")
assert(selectedInstance == 900 and selectedEncounter == 901, "Encounter selection must be restored")
assert(lootClass == 7 and lootSpec == 264 and slotFilter == 4, "Loot filters must be restored")

-- EJ item links can precede full item-cache data. A known missing appearance
-- must publish immediately while unresolved rows remain on the bounded retry.
added = nil
transmogableByLink["item:1002"] = false
matched, retry = WQA:InspectWorldBossTransmog({
	questID = 5001, mapID = 10, x = 0.50, y = 0.50
})
assert(matched and retry, "Resolved missing loot must not wait for every EJ row")
assert(added and added.reward.missingCount == 1)
assert(#added.reward.items == 1 and added.reward.items[1].itemLink == "item:1001")
assert(requestedItemData[1002], "Cold EJ item data should be requested")

-- If every eligible row is still cold, retain the boss as pending rather than
-- silently treating unavailable item metadata as ineligible.
added = nil
transmogableByLink["item:1001"] = false
matched, retry = WQA:InspectWorldBossTransmog({
	questID = 5001, mapID = 10, x = 0.50, y = 0.50
})
assert(not matched and retry and not added)
assert(requestedItemData[1001])
transmogableByLink["item:1001"] = nil
transmogableByLink["item:1002"] = nil

added = nil
encounterComplete = true
matched, retry = WQA:InspectWorldBossTransmog({
	questID = 5001, mapID = 10, x = 0.50, y = 0.50
})
assert(not matched and not retry and not added, "A defeated boss must be suppressed")
encounterComplete = false

journalShown = true
matched, retry = WQA:InspectWorldBossTransmog({
	questID = 5001, mapID = 10, x = 0.50, y = 0.50
})
assert(not matched and retry, "A visible Adventure Guide must be left untouched and retried")
journalShown = false

WQA.db.profile.options.reward.gear.worldBossTransmog = false
matched, retry = WQA:InspectWorldBossTransmog({
	questID = 5001, mapID = 10, x = 0.50, y = 0.50
})
assert(not matched and not retry, "Disabled tracking must avoid Encounter Journal work")

print("World Boss scanner tests passed (matching, completion, collection and journal restoration).")

-- Run from the repository root with Lua 5.1:
-- lua5.1 tools/test_reward_classifier.lua
-- An optional WQATurbo.lua path runs the same cases against a prior baseline.
local function noop() end

local rewardItemID
local scannedItemID
local scannedItemLink
local fallbackItemLink
local itemClassID
local itemEquipLoc
local rewardItemLevel
local inventoryLevels = {}
local installedAddons = {}
local factionReaction = 4
local questRewardCurrencies = {}
local taskNames = {}
local areaPoiNames = {}
local availableMissions = {}

C_QuestLog = {
    IsQuestFlaggedCompleted = noop,
    GetTitleForQuestID = function(questID) return taskNames[questID] end,
    GetQuestRewardCurrencies = function() return questRewardCurrencies end
}
C_QuestLog.IsQuestFlaggedCompletedOnAccount = function() return false end
C_TaskQuest = {
    GetQuestInfoByQuestID = function(questID) return taskNames[questID] end
}
C_CurrencyInfo = {}
C_Reputation = {
    GetFactionDataByID = function()
        return { reaction = factionReaction }
    end,
    IsMajorFaction = function() return false end
}
C_AreaPoiInfo = {
    GetAreaPOIInfo = function(_, poiID)
        local name = areaPoiNames[poiID]
        return name and { name = name } or nil
    end
}
C_Garrison = {
    GetMissionName = function(missionID) return taskNames[missionID] end,
    HasGarrison = function(garrisonType) return availableMissions[garrisonType] ~= nil end,
    GetAvailableMissions = function(followerType) return availableMissions[followerType] end,
    HasShipyard = function() return false end
}
C_Item = {
    GetItemInfoInstant = function() return scannedItemID end,
    GetItemInfo = function() return "Item", fallbackItemLink end
}
C_AzeriteEmpoweredItem = {
    IsAzeriteEmpoweredItemByID = function() return false end
}
C_Soulbinds = {
    IsItemConduitByItemInfo = function() return false end
}
local transmogAppearances = {}
local transmogAppearanceSources = {}
local transmogSourceInfo = {}
C_TransmogCollection = {
    GetAppearanceInfoBySource = function(sourceID)
        return transmogAppearances[sourceID]
    end,
    GetAllAppearanceSources = function(appearanceID)
        return transmogAppearanceSources[appearanceID]
    end,
    GetAppearanceSourceInfo = function(sourceID)
        return transmogSourceInfo[sourceID]
    end
}
Enum = {
    QuestTagType = {},
    GarrisonType = {
        Type_6_0_Garrison = 6,
        Type_7_0_Garrison = 7,
        Type_8_0_Garrison = 8,
        Type_9_0_Garrison = 9
    },
    GarrisonFollowerType = { FollowerType_6_0_Boat = 60 }
}
UnitFullName = function() return "Tester", "Realm" end
UnitClass = function() return "Mage", "MAGE", 8 end
PlayerHasToy = function() return false end
wipe = function(target) for key in pairs(target) do target[key] = nil end end
GetPrimaryGarrisonFollowerType = function(garrisonType) return garrisonType end
GetQuestLink = function(questID)
    local name = taskNames[questID]
    return name and ("[" .. name .. "]") or nil
end
GetQuestLogRewardMoney = function() return 0 end

local scanTooltip = {
    SetOwner = noop,
    SetQuestLogItem = noop,
    GetItem = function() return nil, scannedItemLink end
}
CreateFrame = function() return scanTooltip end

local broker = { NewDataObject = function() return {} end }
local aceAddon = {
    GetAddon = function(_, name)
        return installedAddons[name]
    end
}
LibStub = setmetatable({ GetLibrary = function() return broker end }, {
    __call = function(_, name)
        if name == "AceAddon-3.0" then return aceAddon end
        return {}
    end
})

GetQuestLogRewardInfo = function()
    return "Item", nil, 1, nil, nil, rewardItemID
end
GetItemInfo = function(link)
    return "Item", link, nil, nil, nil, nil, nil, nil, itemEquipLoc, nil, nil, itemClassID, nil
end
GetInventoryItemID = function(_, slotID)
    return inventoryLevels[slotID] and slotID or nil
end
GetInventoryItemLink = function(_, slotID)
    return inventoryLevels[slotID] and ("equipped:" .. slotID) or nil
end
GetDetailedItemLevelInfo = function(link)
    local slotID = string.match(link or "", "^equipped:(%d+)$")
    return slotID and inventoryLevels[tonumber(slotID)] or rewardItemLevel
end

WQATurbo = {
    data = {},
    Criterias = {},
    Rewards = {},
    L = setmetatable({}, { __index = function(_, key) return key end }),
    RegisterChatCommand = noop
}
local WQA = WQATurbo
dofile("Constants.lua")
dofile("Tracking/TrackingPolicy.lua")
dofile("Data/RuntimeData.lua")
dofile("Data/ContainerCollectibles.lua")
dofile("Tracking/ContainerCompletion.lua")
dofile(arg[1] or "WQATurbo.lua")

assert(#WQA.data.containerCollectibles[199192].questIDs == 10)
assert(#WQA.data.containerCollectibles[204359].questIDs == 4)
assert(#WQA.data.containerCollectibles[205226].questIDs == 8)
assert(#WQA.data.containerCollectibles[210549].questIDs == 8)
assert(#WQA.data.containerCollectibles[169478].transmogSources.cloth == 6)
assert(#WQA.data.containerCollectibles[169485].transmogSources.plate == 5)

local function NewOptions()
    return {
        hideExaltedReputations = false,
        sortByName = false,
        sortByZoneName = false,
        reward = {
            gear = {
                armorCache = false,
                weaponCache = false,
                jewelryCache = false,
                AzeriteArmorCache = false,
                PawnUpgrade = false,
                StatWeightScore = false,
                itemLevelUpgrade = false,
                itemLevelUpgradeMin = 5,
                PercentUpgradeMin = 5,
                unknownAppearance = false,
                unknownSource = false,
                azeriteTraits = "",
                conduit = false
            },
            reputation = {},
            currency = {},
            recipe = {},
            [10] = { racingRewardContainers = false }
        },
        missionTable = {
            reward = {
                reputation = {},
                currency = {},
                gold = false,
                goldMin = 0
            }
        }
    }
end

local rewards = {}
WQA.GetExpansionByQuestID = function() return 10 end
WQA.AddRewardToQuest = function(_, questID, rewardType, value, isEmissary)
    table.insert(rewards, {
        questID = questID,
        rewardType = rewardType,
        value = value,
        isEmissary = isEmissary
    })
end

local function Reset(itemID)
    rewardItemID = itemID
    scannedItemID = itemID
    scannedItemLink = itemID and ("item:" .. itemID) or nil
    fallbackItemLink = nil
    itemClassID = 0
    itemEquipLoc = nil
    rewardItemLevel = 120
    inventoryLevels = {}
    installedAddons = {}
    factionReaction = 4
    questRewardCurrencies = {}
    taskNames = {}
    areaPoiNames = {}
    availableMissions = {}
    PawnIsItemAnUpgrade = nil
    PawnGetItemData = nil
    C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID = function() return false end
    C_Soulbinds.IsItemConduitByItemInfo = function() return false end
    C_QuestLog.IsQuestFlaggedCompleted = noop
    C_QuestLog.IsQuestFlaggedCompletedOnAccount = function() return false end
    transmogAppearances = {}
    transmogAppearanceSources = {}
    transmogSourceInfo = {}
    WQA.db = {
        profile = { options = NewOptions(), custom = { worldQuestReward = {} } },
        global = { custom = { worldQuestReward = {} } }
    }
    WQA.itemList = {}
    WQA.azeriteTraitsList = {}
    rewards = {}
end

local function AssertReward(index, rewardType)
    assert(rewards[index], "Missing reward " .. index)
    assert(rewards[index].rewardType == rewardType, "Unexpected reward type at " .. index)
    assert(rewards[index].questID == 1000)
    assert(rewards[index].isEmissary == false)
    return rewards[index].value
end

Reset(nil)
assert(WQA:CheckReward(1000, false, 1) == true)
assert(#rewards == 0)

Reset(200000)
scannedItemLink = nil
assert(WQA:CheckReward(1000, false, 1) == true)
assert(#rewards == 0)

Reset(200000)
scannedItemID = 300000
assert(WQA:CheckReward(1000, false, 1) == true)
fallbackItemLink = "item:200000"
WQA.itemList[200000] = true
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Item).itemLink == fallbackItemLink)

Reset(169477)
WQA.db.profile.options.reward.gear.armorCache = true
transmogAppearances[104107] = { appearanceID = 5001 }
transmogAppearanceSources[5001] = { 104107 }
transmogSourceInfo[104107] = { isCollected = false }
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Item).itemLink == scannedItemLink)

Reset(169479)
WQA.db.profile.options.reward.gear.armorCache = true
transmogAppearances[104104] = { appearanceID = 5002 }
transmogAppearanceSources[5002] = { 104104, 999999 }
transmogSourceInfo[104104] = { isCollected = false }
transmogSourceInfo[999999] = { isCollected = true }
assert(WQA:CheckReward(1000, false, 1) == false)
assert(#rewards == 0)

Reset(169479)
WQA.db.profile.options.reward.gear.armorCache = true
assert(WQA:CheckReward(1000, false, 1) == true)
assert(AssertReward(1, WQA.Constants.RewardType.Item).itemLink == scannedItemLink)

Reset(169479)
WQA.db.profile.options.reward.gear.armorCache = true
C_TransmogCollection.GetAppearanceInfoBySource = nil
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Item).itemLink == scannedItemLink)
C_TransmogCollection.GetAppearanceInfoBySource = function(sourceID)
    return transmogAppearances[sourceID]
end

Reset(199192)
WQA.db.profile.options.reward[10].racingRewardContainers = true
assert(WQA:CheckReward(1000, false, 1) == false)
AssertReward(1, WQA.Constants.RewardType.Item)

Reset(204359)
WQA.db.profile.options.reward[10].racingRewardContainers = true
local reachQuestIDs = WQA.data.containerCollectibles[204359].questIDs
local completedReachQuests = {
    [reachQuestIDs[1]] = true,
    [reachQuestIDs[2]] = true,
    [reachQuestIDs[3]] = true
}
C_QuestLog.IsQuestFlaggedCompleted = function(questID)
    return completedReachQuests[questID] == true
end
assert(WQA:CheckReward(1000, false, 1) == false)
AssertReward(1, WQA.Constants.RewardType.Item)
C_QuestLog.IsQuestFlaggedCompletedOnAccount = function(questID)
    return questID == reachQuestIDs[4]
end
rewards = {}
assert(WQA:CheckReward(1000, false, 1) == false)
assert(#rewards == 0)

Reset(152957)
WQA.db.profile.options.reward.reputation[2165] = true
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Reputation).factionID == 2165)

Reset(152957)
WQA.db.profile.options.reward.reputation[2165] = true
WQA.db.profile.options.hideExaltedReputations = true
factionReaction = 8
assert(WQA:CheckReward(1000, false, 1) == false)
assert(#rewards == 0, "Maxed reputation item rewards must be hidden")

Reset(200000)
WQA.db.profile.options.reward.reputation[2164] = true
questRewardCurrencies = { { currencyID = 1579, totalRewardAmount = 75, name = "Reputation" } }
WQA:CheckCurrencies(1000, false)
assert(AssertReward(1, WQA.Constants.RewardType.Reputation).factionID == 2164)

Reset(200000)
WQA.db.profile.options.reward.reputation[2164] = true
WQA.db.profile.options.hideExaltedReputations = true
factionReaction = 8
questRewardCurrencies = { { currencyID = 1579, totalRewardAmount = 75, name = "Reputation" } }
WQA:CheckCurrencies(1000, false)
assert(#rewards == 0, "Maxed reputation currency rewards must be hidden")

Reset(200000)
itemClassID = 9
WQA.db.profile.options.reward.recipe[10] = true
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Recipe) == scannedItemLink)

Reset(200000)
WQA.db.global.custom.worldQuestReward[200000] = true
WQA.db.profile.custom.worldQuestReward[200000] = true
WQA.itemList[200000] = true
assert(WQA:CheckReward(1000, false, 1) == false)
AssertReward(1, WQA.Constants.RewardType.CustomItem)
AssertReward(2, WQA.Constants.RewardType.Item)

Reset(200000)
itemClassID = 4
WQA.db.profile.options.reward.gear.unknownAppearance = true
WQA.IsTransmogable = function() return true end
WQA.GetTrackedTransmogIcon = function() return "transmog-icon", false end
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Item).transmog == "transmog-icon")
rewards = {}
WQA.GetTrackedTransmogIcon = function() return nil, true end
assert(WQA:CheckReward(1000, false, 1) == true)
assert(#rewards == 0)

Reset(200000)
itemEquipLoc = "INVTYPE_HEAD"
inventoryLevels[1] = 100
WQA.db.profile.options.reward.gear.itemLevelUpgrade = true
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Item).itemLevelUpgrade == 20)

Reset(200000)
WQA.db.profile.options.reward.gear.PawnUpgrade = true
PawnGetItemData = function() return {} end
PawnIsItemAnUpgrade = function() return { { PercentUpgrade = 0.10 } } end
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Item).itemPercentUpgrade == 10)

Reset(200000)
itemEquipLoc = "INVTYPE_FINGER"
inventoryLevels[11] = 80
inventoryLevels[12] = 100
WQA.db.profile.options.reward.gear.StatWeightScore = true
local statWeightScores = {
    ["item:200000"] = 120,
    ["equipped:11"] = 80,
    ["equipped:12"] = 100
}
local statWeightModules = {
    StatWeightScoreScore = {
        CalculateItemScore = function(_, link)
            return { Score = assert(statWeightScores[link]) }
        end
    },
    StatWeightScoreSpec = {
        GetSpecs = function()
            return { { Enabled = true } }
        end
    },
    StatWeightScoreScanningTooltip = {
        ScanTooltip = function() return {} end
    }
}
installedAddons.StatWeightScore = {
    GetModule = function(_, name)
        return assert(statWeightModules[name])
    end
}
assert(WQA:CheckReward(1000, false, 1) == false)
local expectedStatWeightUpgrade = arg[1] and 20 or 50
assert(AssertReward(1, WQA.Constants.RewardType.Item).itemPercentUpgrade == expectedStatWeightUpgrade)

Reset(163857)
WQA.db.profile.options.reward.gear.AzeriteArmorCache = true
assert(WQA:CheckReward(1000, false, 1) == false)
AssertReward(1, WQA.Constants.RewardType.Item)
assert(AssertReward(2, WQA.Constants.RewardType.Item).AzeriteArmorCache[1] == 120)

Reset(163857)
WQA.db.profile.options.reward.gear.AzeriteArmorCache = true
rewardItemLevel = nil
inventoryLevels[1] = 100
assert(WQA:CheckReward(1000, false, 1) == true)
assert(#rewards == 1, "An uncached Azerite cache must retain its base reward")

Reset(165872)
WQA.db.profile.options.reward.gear.weaponCache = true
assert(WQA:CheckReward(1000, false, 1) == false)
AssertReward(1, WQA.Constants.RewardType.Item)

Reset(165872)
WQA.db.profile.options.reward.gear.weaponCache = true
rewardItemLevel = nil
inventoryLevels[16] = 100
assert(WQA:CheckReward(1000, false, 1) == true)
assert(#rewards == 1, "An uncached equipment cache must retain its base reward")

Reset(200000)
WQA.db.profile.options.reward.gear.conduit = true
C_Soulbinds.IsItemConduitByItemInfo = function() return true end
assert(WQA:CheckReward(1000, false, 1) == false)
AssertReward(1, WQA.Constants.RewardType.Item)

Reset(200000)
WQA.db.profile.options.reward.gear.azeriteTraits = "123"
WQA.azeriteTraitsList[123] = true
C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID = function() return true end
C_AzeriteEmpoweredItem.GetAllTierInfoByItemID = function()
    return { { azeritePowerIDs = { 55 } } }
end
C_AzeriteEmpoweredItem.GetPowerInfo = function() return { spellID = 123 } end
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.AzeriteTrait) == 123)
AssertReward(2, WQA.Constants.RewardType.Item)

-- Name sorting must handle all task types and temporarily unavailable names.
Reset(200000)
taskNames[100] = "Bravo Quest"
taskNames[200] = "Zulu Mission"
areaPoiNames[300] = "Alpha POI"
WQA.db.profile.options.sortByName = true
WQA.SortByExpansion = function() return false end
local sortedTasks = WQA:SortQuestList({
    { id = 200, type = WQA.Constants.TaskType.Mission },
    { id = 100, type = WQA.Constants.TaskType.WorldQuest },
    { id = 400, type = WQA.Constants.TaskType.Mission },
    { id = 300, mapId = 500, type = WQA.Constants.TaskType.AreaPoi }
})
assert(sortedTasks[2].id == 300 and sortedTasks[3].id == 100 and sortedTasks[4].id == 200)

-- Reputation-only mission currencies must activate the mission and honor the
-- shared maxed-reputation policy.
Reset(200000)
WQA.ExpansionList = { [8] = "Battle for Azeroth" }
WQA.missionList = {}
WQA.db.profile.options.missionTable.reward.reputation[2164] = true
availableMissions[8] = {
    {
        missionID = 500,
        rewards = { { currencyID = 1579, quantity = 75 } },
        offerEndTime = 200,
        offerTimeRemaining = "2 hr"
    }
}
WQA.AddRewardToMission = function(self, missionID, rewardType, value)
    self.missionList[missionID] = self.missionList[missionID] or { reward = {} }
    self.missionList[missionID].reward[rewardType] = value
end
local activeMissions = WQA:CheckMissions()
assert(activeMissions[500] == true, "A reputation-currency-only mission must be active")

WQA.missionList = {}
WQA.db.profile.options.hideExaltedReputations = true
factionReaction = 8
activeMissions = WQA:CheckMissions()
assert(activeMissions[500] == nil, "A maxed reputation mission must be hidden")

print("Reward classifier regression checks passed (links, retries, containers, caches, sorting, reputation, missions, recipes, custom and legacy rewards).")

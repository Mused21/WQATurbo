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
local activeGarrisons = {}
local currentTime = 0
local mapBounties = {}
local emissaryTimers = {}
local questDataReady = true
local questRewardDataReady = true
local playerClassID = 8

C_QuestLog = {
    IsQuestFlaggedCompleted = noop,
    GetTitleForQuestID = function(questID) return taskNames[questID] end,
    GetQuestRewardCurrencies = function() return questRewardCurrencies end,
    GetBountiesForMapID = function(mapID) return mapBounties[mapID] end
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
    HasGarrison = function(garrisonType) return activeGarrisons[garrisonType] == true end,
    GetAvailableMissions = function(followerType) return availableMissions[followerType] end,
    HasShipyard = function() return false end
}
C_Timer = {
    NewTimer = function(delay, callback)
        local timer = { delay = delay, callback = callback, cancelled = false }
        function timer:Cancel() self.cancelled = true end
        emissaryTimers[#emissaryTimers + 1] = timer
        return timer
    end
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
local transmogItemInfo = {}
local transmogSourceOwned = {}
C_TransmogCollection = {
    GetItemInfo = function(itemInfo)
        local info = transmogItemInfo[itemInfo]
        if info then
            return info.appearanceID, info.sourceID
        end
    end,
    PlayerHasTransmogItemModifiedAppearance = function(sourceID)
        return transmogSourceOwned[sourceID]
    end,
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
UnitClass = function() return "Test", "TEST", playerClassID end
PlayerHasToy = function() return false end
wipe = function(target) for key in pairs(target) do target[key] = nil end end
GetPrimaryGarrisonFollowerType = function(garrisonType) return garrisonType end
GetQuestLink = function(questID)
    local name = taskNames[questID]
    return name and ("[" .. name .. "]") or nil
end
GetQuestLogRewardMoney = function() return 0 end
GetTime = function() return currentTime end
HaveQuestData = function() return questDataReady end
HaveQuestRewardData = function() return questRewardDataReady end

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
if not arg[1] then
    assert(WQA.EmissaryReward == nil and WQA.EmissaryIsActive == nil,
        "The compatibility core must not define emissary scanner methods")
    dofile("Scanning/EmissaryScanner.lua")
    assert(WQA.RefreshQuestPins == nil and WQA.isQuestPinActive == nil
        and WQA.IsQuestFlaggedCompleted == nil,
        "The compatibility core must not define quest availability methods")
    dofile("Tracking/QuestAvailability.lua")
end

assert(#WQA.data.containerCollectibles[199192].questIDs == 10)
assert(#WQA.data.containerCollectibles[204359].questIDs == 4)
assert(#WQA.data.containerCollectibles[205226].questIDs == 8)
assert(#WQA.data.containerCollectibles[210549].questIDs == 8)
assert(#WQA.data.containerCollectibles[169478].transmogSources.cloth == 6)
assert(#WQA.data.containerCollectibles[169485].transmogSources.plate == 5)
assert(#WQA.data.containerCollectibles[163857].transmogSources.cloth == 18)
assert(#WQA.data.containerCollectibles[163857].transmogSources.leather == 19)
assert(#WQA.data.containerCollectibles[163857].transmogSources.mail == 18)
assert(#WQA.data.containerCollectibles[163857].transmogSources.plate == 18)
assert(WQA.data.containerCollectibles[163857].unsupportedItemContexts[1])
assert(WQA.data.containerCollectibles[163857].unsupportedItemContexts[2])
assert(WQA.data.containerCollectibles[163857].unsupportedItemContexts[5])
for itemID = 169477, 169485 do
    assert(not WQA.data.containerCollectibles[itemID].allArmorTypes)
end

WQA.data.factionPruneFixture = {
    records = {
        metadata = true,
        sameFaction = { faction = "Alliance" },
        otherFaction = { faction = "Horde" }
    }
}
WQA:PruneOtherFactionData("Alliance")
assert(WQA.data.factionPruneFixture.records.metadata == true)
assert(WQA.data.factionPruneFixture.records.sameFaction)
assert(WQA.data.factionPruneFixture.records.otherFaction == nil)
assert(WQA.data.containerCollectibles[169477].transmogSources.plate)
WQA.data.factionPruneFixture = nil

local function NewOptions()
    return {
        hideExaltedReputations = false,
        sortByName = false,
        sortByZoneName = false,
        emissary = {},
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
    activeGarrisons = {}
    currentTime = 0
    mapBounties = {}
    emissaryTimers = {}
    questDataReady = true
    questRewardDataReady = true
    playerClassID = 8
    PawnIsItemAnUpgrade = nil
    PawnGetItemData = nil
    C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID = function() return false end
    C_Soulbinds.IsItemConduitByItemInfo = function() return false end
    C_QuestLog.IsQuestFlaggedCompleted = noop
    C_QuestLog.IsQuestFlaggedCompletedOnAccount = function() return false end
    transmogAppearances = {}
    transmogAppearanceSources = {}
    transmogSourceInfo = {}
    transmogItemInfo = {}
    transmogSourceOwned = {}
    WQA.db = {
        profile = { options = NewOptions(), custom = { worldQuestReward = {} } },
        char = { options = { reward = { gear = { AzeriteArmorCache = true } } } },
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

local function SetContainerSourcesCollected(itemID, collected)
    local nextAppearanceID = 6000
    for _, sourceIDs in pairs(WQA.data.containerCollectibles[itemID].transmogSources) do
        for _, sourceID in ipairs(sourceIDs) do
            nextAppearanceID = nextAppearanceID + 1
            transmogAppearances[sourceID] = { appearanceID = nextAppearanceID }
            transmogAppearanceSources[nextAppearanceID] = { sourceID }
            transmogSourceInfo[sourceID] = { isCollected = collected }
        end
    end
end

-- Benthic tokens produce gear for the active loot specialization. Reproduce
-- the reported plate-wearer case: a missing mail source must not keep the helm
-- visible when its plate appearance is complete.
Reset(169479)
WQA.db.profile.options.reward.gear.armorCache = true
playerClassID = 6
SetContainerSourcesCollected(169479, true)
transmogSourceInfo[104120].isCollected = false
assert(WQA:CheckReward(1000, false, 1) == false)
assert(#rewards == 0)

-- A missing source for the current armor type keeps the token relevant.
Reset(169479)
WQA.db.profile.options.reward.gear.armorCache = true
playerClassID = 6
SetContainerSourcesCollected(169479, true)
transmogSourceInfo[104128].isCollected = false
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Item).itemLink == scannedItemLink)

-- Cloaks retain the shared source pool for every class.
Reset(169481)
WQA.db.profile.options.reward.gear.armorCache = true
playerClassID = 6
SetContainerSourcesCollected(169481, true)
transmogSourceInfo[105150].isCollected = false
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Item).itemLink == scannedItemLink)

-- A direct equipment cache only considers the active character's armor type.
Reset(165866)
WQA.db.profile.options.reward.gear.armorCache = true
SetContainerSourcesCollected(165866, true)
transmogSourceInfo[94018].isCollected = false
assert(WQA:CheckReward(1000, false, 1) == false)
assert(#rewards == 0, "A missing mail source must not keep the cache visible on a cloth wearer")

Reset(165866)
WQA.db.profile.options.reward.gear.armorCache = true
SetContainerSourcesCollected(165866, true)
transmogSourceInfo[94002].isCollected = false
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Item).itemLink == scannedItemLink)

-- Tortollan Trader's Stock only contains rings/trinkets, not appearances.
Reset(165785)
WQA.db.profile.options.reward.gear.jewelryCache = true
assert(WQA:CheckReward(1000, false, 1) == false)
assert(#rewards == 0)

Reset(169479)
WQA.db.profile.options.reward.gear.armorCache = true
SetContainerSourcesCollected(169479, true)
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

-- Exact link data remains authoritative when the base item has a different
-- appearance context.
transmogItemInfo[scannedItemLink] = { appearanceID = 5000, sourceID = 6000 }
transmogItemInfo[200000] = { appearanceID = 5001, sourceID = 6001 }
transmogAppearanceSources[5000] = { 6000 }
transmogAppearanceSources[5001] = { 6001 }
transmogSourceOwned[6000] = true
transmogSourceOwned[6001] = false
local transmogIcon, transmogRetry = WQA:GetTrackedTransmogIcon(scannedItemLink, rewardItemID)
assert(transmogIcon == nil and transmogRetry == false,
    "Exact reward-link transmog context must take precedence over the base item")

-- Reproduce the reported K'aresh and Undermine reward state: the visual is
-- known through another item but the exact source is missing. The scaled link
-- has no collection record and richer source metadata is unavailable; direct
-- source ownership is enough.
transmogItemInfo[scannedItemLink] = nil
transmogAppearanceSources[5001] = { 6001, 6002 }
transmogSourceOwned[6002] = true
WQA.db.profile.options.reward.gear.unknownSource = true
transmogIcon, transmogRetry = WQA:GetTrackedTransmogIcon(scannedItemLink, rewardItemID)
assert(transmogIcon and transmogRetry == false,
    "A known appearance with an uncollected exact source must match Unknown source")

WQA.db.profile.options.reward.gear.unknownSource = false
transmogIcon, transmogRetry = WQA:GetTrackedTransmogIcon(scannedItemLink, rewardItemID)
assert(transmogIcon == nil and transmogRetry == false,
    "A known appearance must still respect the Unknown source setting")

transmogSourceOwned[6002] = false
transmogIcon, transmogRetry = WQA:GetTrackedTransmogIcon(scannedItemLink, rewardItemID)
assert(transmogIcon and transmogRetry == false,
    "An entirely uncollected appearance must still match Unknown appearance")

transmogSourceOwned[6001] = nil
transmogIcon, transmogRetry = WQA:GetTrackedTransmogIcon(scannedItemLink, rewardItemID)
assert(transmogIcon == nil and transmogRetry == true,
    "Unavailable source ownership must remain pending instead of guessing")

WQA.IsTransmogable = function() return true end
WQA.GetTrackedTransmogIcon = function(_, itemLink, itemID)
    assert(itemLink == scannedItemLink and itemID == rewardItemID,
        "Transmog classification must retain the authoritative quest reward item ID")
    return "transmog-icon", false
end
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
SetContainerSourcesCollected(163857, true)
transmogSourceInfo[93966].isCollected = false
assert(WQA:CheckReward(1000, false, 1) == false)
AssertReward(1, WQA.Constants.RewardType.Item)
assert(AssertReward(2, WQA.Constants.RewardType.Item).AzeriteArmorCache[1] == 120)

-- A complete pool for the active armor type suppresses the cache.
Reset(163857)
WQA.db.profile.options.reward.gear.AzeriteArmorCache = true
SetContainerSourcesCollected(163857, true)
assert(WQA:CheckReward(1000, false, 1) == false)
assert(#rewards == 0)

-- Missing appearances for another armor type do not make the cache relevant.
Reset(163857)
WQA.db.profile.options.reward.gear.AzeriteArmorCache = true
SetContainerSourcesCollected(163857, true)
transmogSourceInfo[93979].isCollected = false
assert(WQA:CheckReward(1000, false, 1) == false)
assert(#rewards == 0)

-- Dungeon/Warfront item contexts use different pools and must fail open.
for _, itemContext in ipairs({ 1, 2, 5 }) do
    Reset(163857)
    WQA.db.profile.options.reward.gear.AzeriteArmorCache = true
    SetContainerSourcesCollected(163857, true)
    scannedItemLink = "item:163857:::::::::::" .. itemContext
    assert(WQA:CheckReward(1000, false, 1) == false)
    AssertReward(1, WQA.Constants.RewardType.Item)
end

-- Temporarily unavailable appearance data keeps the cache visible and retries.
Reset(163857)
WQA.db.profile.options.reward.gear.AzeriteArmorCache = true
SetContainerSourcesCollected(163857, true)
transmogAppearances[93966] = nil
assert(WQA:CheckReward(1000, false, 1) == true)
AssertReward(1, WQA.Constants.RewardType.Item)

Reset(163857)
WQA.db.profile.options.reward.gear.AzeriteArmorCache = true
SetContainerSourcesCollected(163857, true)
transmogSourceInfo[93966].isCollected = false
rewardItemLevel = nil
inventoryLevels[1] = 100
assert(WQA:CheckReward(1000, false, 1) == true)
assert(#rewards == 1, "An uncached Azerite cache must retain its base reward")

Reset(163857)
WQA.db.profile.options.reward.gear.AzeriteArmorCache = true
WQA.db.char.options.reward.gear.AzeriteArmorCache = false
assert(WQA:CheckReward(1000, false, 1) == false)
assert(#rewards == 0, "Azerite cache tracking must support a per-character override")

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
activeGarrisons[8] = true
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
local activeMissions, missionRetry = WQA:CheckMissions()
assert(activeMissions[500] == true, "A reputation-currency-only mission must be active")
assert(missionRetry == false)

WQA.missionList = {}
WQA.db.profile.options.hideExaltedReputations = true
factionReaction = 8
activeMissions = WQA:CheckMissions()
assert(activeMissions[500] == nil, "A maxed reputation mission must be hidden")

-- Pending mission payloads and items request another pass without suppressing
-- an unrelated ready mission.
Reset(200000)
WQA.ExpansionList = { [8] = "Battle for Azeroth" }
WQA.missionList = {}
WQA.db.profile.options.missionTable.reward.gold = true
activeGarrisons[8] = true
availableMissions[8] = {
    { missionID = 501, rewards = { { currencyID = 0, quantity = 10000 } } },
    { missionID = 502, rewards = { { itemID = 999 } } }
}
local getItemInfo = GetItemInfo
GetItemInfo = function(item)
    if item == 999 then
        return nil
    end
    return getItemInfo(item)
end
activeMissions, missionRetry = WQA:CheckMissions()
assert(activeMissions[501] == true, "A ready mission must survive another mission's pending item")
assert(activeMissions[502] == nil and missionRetry == true)
assert(WQA._wqaMissionPending["mission:502@item:999"])

availableMissions[8] = nil
activeMissions, missionRetry = WQA:CheckMissions()
assert(next(activeMissions) == nil and missionRetry == true, "A missing mission payload must request retry")
assert(WQA._wqaMissionPending["mission-list:8"])

-- Emissary retries are generation-owned, bounded, and avoid a forced retry
-- when both bounty maps and their rewards are already available.
Reset(200000)
local emissaryCurrencyChecks = 0
local emissaryTaskChecks = 0
WQA.CheckItems = function() return false end
WQA.CheckCurrencies = function()
    emissaryCurrencyChecks = emissaryCurrencyChecks + 1
end
WQA.ScheduleTaskResolverCheck = function(_, restartWindow)
    assert(restartWindow == true)
    emissaryTaskChecks = emissaryTaskChecks + 1
end
WQA.db.profile.options.emissary[700] = true
mapBounties[627] = { { questID = 700 } }
mapBounties[875] = {}
WQA:EmissaryReward()
assert(WQA.emissaryRewards == true and WQA._wqaEmissaryScan == nil)
assert(#emissaryTimers == 0 and emissaryCurrencyChecks == 1)
assert(emissaryTaskChecks == 1)

Reset(200000)
emissaryTaskChecks = 0
WQA.ScheduleTaskResolverCheck = function(_, restartWindow)
	if restartWindow then
		emissaryTaskChecks = emissaryTaskChecks + 10
	else
		emissaryTaskChecks = emissaryTaskChecks + 1
	end
end
questDataReady = false
mapBounties[627] = { { questID = 701 } }
mapBounties[875] = {}
WQA:EmissaryReward()
local staleEmissaryTimer = emissaryTimers[1]
local staleEmissaryState = WQA._wqaEmissaryScan
WQA:EmissaryReward()
local currentEmissaryTimer = emissaryTimers[2]
assert(staleEmissaryTimer.cancelled == true)
assert(WQA._wqaEmissaryScan ~= staleEmissaryState)
staleEmissaryTimer.callback()
assert(#emissaryTimers == 2 and WQA._wqaEmissaryScan ~= nil)

currentTime = 31
currentEmissaryTimer.callback()
assert(WQA.emissaryRewards == true and WQA._wqaEmissaryScan == nil)
assert(#emissaryTimers == 2, "Timed-out emissary data must stop scheduling")
assert(WQA._wqaEmissaryTimeout["emissary:701"])
assert(emissaryTaskChecks == 12, "Ready emissary data must publish during retries and once at completion")

-- Missing bounty maps have an ID even when no quest ID is available.
currentTime = 0
mapBounties = {}
WQA:EmissaryReward()
assert(WQA._wqaEmissaryTimeout == nil)
currentTime = 31
emissaryTimers[#emissaryTimers].callback()
assert(WQA._wqaEmissaryTimeout["emissary-map:627"])
assert(WQA._wqaEmissaryTimeout["emissary-map:875"])

-- Exercise core Quest Pin lookup with the real progressive TaskResolver.
local pins = { [84] = { { questID = 101 }, {} }, [86] = {} }
local pinCalls, pinRequests = {}, {}
C_QuestLine = {
    GetAvailableQuestLines = function(mapID)
        pinCalls[mapID] = (pinCalls[mapID] or 0) + 1
        return pins[mapID]
    end,
    RequestQuestLinesForMap = function(mapID)
        pinRequests[mapID] = (pinRequests[mapID] or 0) + 1
    end
}
C_TaskQuest.IsActive = function() return false end
dofile("Runtime/TaskResolver.lua")
WQA.Debug = noop
WQA.ShouldIncludeWorldQuestForCurrentMode = function() return true end
WQA.EmissaryIsActive = function() return false end
WQA.IsQuestFlaggedCompleted = function() return false end
WQA.CheckMissions = function(self) self._wqaMissionPending = {}; return {}, false end
WQA.Criterias.AreaPoi = { watched = {}, Check = function() return { active = {}, new = {} } end }
WQA.GetTaskLink = function() return "quest" end
WQA.SortQuestList = function(_, tasks) return tasks end
local chatCalls = 0
WQA.AnnounceChat = function() chatCalls = chatCalls + 1 end
WQA.AnnouncePopUp = function() error("unexpected popup") end
WQA.UpdateLDBText, WQA.TurboRefreshOpenPopup = noop, noop
WQA.questList = { [101] = { reward = { custom = true } }, [102] = { reward = { custom = true } } }
WQA.questPinMapList = { [84] = true, [85] = true, [86] = true }
WQA.watched, WQA.watchedMissions = {}, {}
WQA._wqaTurboRefreshMode = "settings"
currentTime = 0
WQA:ResetTaskResolverRetry()
WQA:CheckWQ("settings")
assert(#WQA.activeTasks == 1 and WQA.activeTasks[1].id == 101)
assert(pinCalls[84] == 1 and pinCalls[85] == 1 and pinCalls[86] == 1)
assert(pinRequests[85] == 1 and pinRequests[84] == nil and pinRequests[86] == nil)
local pinTimer = WQA._wqaTurboCheckRetryTimer
assert(pinTimer and WQA._wqaTaskPending["quest-pin-map:85"])
WQA:CheckWQ("settings")
assert(pinRequests[85] == 1, "coalesced publications must not spam map requests")
assert(WQA._wqaTurboCheckRetryTimer == pinTimer)
pins[85] = { { questID = 102 } }
currentTime = 0.5
pinTimer.callback()
assert(#WQA.activeTasks == 2 and WQA._wqaTurboCheckRetryTimer == nil)
assert(chatCalls == 0, "Settings/profile retry must remain silent")
pins[85] = nil
WQA:CheckWQ("settings")
pinTimer = WQA._wqaTurboCheckRetryTimer
local requestsBeforeExpiry = pinRequests[85]
currentTime = 32
pinTimer.callback()
assert(pinRequests[85] == requestsBeforeExpiry, "deadline pass must not re-request")
assert(WQA._wqaTurboCheckRetryTimer == nil and WQA._wqaTaskTimeout["quest-pin-map:85"])
assert(#WQA.activeTasks == 1)
local timedOutRequests = pinRequests[85]
WQA:CheckWQ("settings")
assert(pinRequests[85] == timedOutRequests, "expired maps must not re-request")
local diagnosticPrint = print
local diagnostics = {}
print = function(line) diagnostics[#diagnostics + 1] = line end
WQA:PrintReadinessStatus()
print = diagnosticPrint
assert(table.concat(diagnostics, "\n"):find("quest%-pin%-map:85"))
assert(table.concat(diagnostics, "\n"):find("emissary%-map:627"))

-- Fallback map names are safe but must not poison the later metadata cache.
local mapInfo
C_Map = { GetMapInfo = function() return mapInfo end }
C_TaskQuest.GetQuestZoneID = function() return 84 end
dofile("Utilities.lua")
assert(WQA:GetMapInfo(nil).name == "Unknown")
assert(WQA:GetQuestZoneName(101) == "Map 84")
assert(WQA.questList[101].info.zoneName == nil)
mapInfo = { name = "Stormwind" }
assert(WQA:GetQuestZoneName(101) == "Stormwind")
assert(WQA:GetTaskZoneName({ type = WQA.Constants.TaskType.AreaPoi, mapId = 84 }) == "Stormwind")
local worldBossReward = {
    items = {
        { itemLink = "|cff0070dd|Hitem:1001|h[Boss Helm]|h|r", transmog = " X" },
        { itemLink = "|cff0070dd|Hitem:1002|h[Boss Sword]|h|r", transmog = " Y" }
    }
}
assert(WQA:GetRewardTextByID(101, "worldBossTransmog", worldBossReward, 1) ==
    "|cff0070dd|Hitem:1001|h[Boss Helm]|h|r X")
assert(WQA:GetRewardTextByID(101, "worldBossTransmog", worldBossReward, 2) ==
    "|cff0070dd|Hitem:1002|h[Boss Sword]|h|r Y")
assert(WQA:GetRewardTextByID(101, "worldBossTransmog", worldBossReward, 3) == nil)
assert(WQA:GetRewardLinkByID(101, "worldBossTransmog", worldBossReward, 2) ==
    "|cff0070dd|Hitem:1002|h[Boss Sword]|h|r")
print("Reward/core regression checks passed (classification, missions, emissaries, Quest Pin readiness and metadata recovery).")

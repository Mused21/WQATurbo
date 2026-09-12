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

C_QuestLog = { IsQuestFlaggedCompleted = noop }
C_TaskQuest = {}
C_CurrencyInfo = {}
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
Enum = { QuestTagType = {}, GarrisonType = {} }
UnitFullName = function() return "Tester", "Realm" end
PlayerHasToy = function() return false end
wipe = function(target) for key in pairs(target) do target[key] = nil end end

local scanTooltip = {
    SetOwner = noop,
    SetQuestLogItem = noop,
    GetItem = function() return nil, scannedItemLink end
}
CreateFrame = function() return scanTooltip end

local broker = { NewDataObject = function() return {} end }
local aceAddon = { GetAddon = function() return nil end }
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
dofile(arg[1] or "WQATurbo.lua")

local function NewOptions()
    return {
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
            recipe = {},
            [10] = { racingRewardContainers = false }
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
    PawnIsItemAnUpgrade = nil
    PawnGetItemData = nil
    C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID = function() return false end
    C_Soulbinds.IsItemConduitByItemInfo = function() return false end
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
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Item).itemLink == scannedItemLink)

Reset(199192)
WQA.db.profile.options.reward[10].racingRewardContainers = true
assert(WQA:CheckReward(1000, false, 1) == false)
AssertReward(1, WQA.Constants.RewardType.Item)

Reset(152957)
WQA.db.profile.options.reward.reputation[2165] = true
assert(WQA:CheckReward(1000, false, 1) == false)
assert(AssertReward(1, WQA.Constants.RewardType.Reputation).factionID == 2165)

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

Reset(163857)
WQA.db.profile.options.reward.gear.AzeriteArmorCache = true
assert(WQA:CheckReward(1000, false, 1) == false)
AssertReward(1, WQA.Constants.RewardType.Item)
assert(AssertReward(2, WQA.Constants.RewardType.Item).AzeriteArmorCache[1] == 120)

Reset(165872)
WQA.db.profile.options.reward.gear.weaponCache = true
assert(WQA:CheckReward(1000, false, 1) == false)
AssertReward(1, WQA.Constants.RewardType.Item)

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

print("Reward classifier regression checks passed (links, retries, containers, upgrades, transmog, reputation, recipes, custom and legacy rewards).")

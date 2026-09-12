-- Run from the repository root with Lua 5.1:
-- lua5.1 tools/test_tracking_policy.lua
-- An optional source directory allows the same cases to check a prior baseline.
local sourceRoot = arg[1] or "."
local legacyPaths = {
    ["Tracking/TrackingPolicy.lua"] = "TrackingPolicy.lua",
    ["Data/RuntimeData.lua"] = "DB/RuntimeData.lua",
    ["Tracking/CollectionCache.lua"] = "CollectionCache.lua",
    ["Tracking/Achievements.lua"] = "Achievements.lua",
    ["UI/Options.lua"] = "Options.lua"
}
local function loadSource(name)
    local path = sourceRoot .. "/" .. name
    local file = io.open(path, "r")
    if file then
        file:close()
    elseif legacyPaths[name] then
        path = sourceRoot .. "/" .. legacyPaths[name]
    end
    dofile(path)
end

local function noop() end
local owned, blocked = false, {}
C_QuestLog = { IsQuestFlaggedCompleted = function(id) return blocked[id] end }
C_TaskQuest = {}
C_CurrencyInfo = {}
Enum = {
    QuestTagType = { PvP = 1, PetBattle = 2, Profession = 3, Dungeon = 4 },
    GarrisonType = {}
}
CreateFrame = function() return { SetOwner = noop } end
UnitFullName = function() return "Tester", "Realm" end
PlayerHasToy = function() return owned end
local broker = { NewDataObject = function() return {} end }
LibStub = setmetatable({ GetLibrary = function() return broker end }, {
    __call = function() return {} end
})
wipe = function(t) for key in pairs(t) do t[key] = nil end end
C_MountJournal = {
    GetMountIDs = function() return { 1 } end,
    GetMountInfoByID = function()
        return nil, 100, nil, nil, nil, nil, nil, nil, nil, nil, owned
    end
}
C_PetJournal = {
    GetNumPets = function() return 1 end,
    GetPetInfoByIndex = function()
        return nil, nil, owned, nil, nil, nil, nil, nil, nil, nil, 100
    end
}

WQATurbo = {
    data = {}, Criterias = {}, Rewards = {},
    L = setmetatable({}, { __index = function(_, key) return key end }),
    RegisterChatCommand = noop,
    playerName = "Tester-Realm",
    db = { profile = {} }
}
local WQA = WQATurbo
loadSource("Constants.lua")
loadSource("Tracking/TrackingPolicy.lua")
loadSource("Data/RuntimeData.lua")
assert(WQA.EmissaryQuestIDList == WQA.RuntimeData.EmissaryQuestIDsByExpansion)
assert(WQA.RuntimeData.CurrencyIDsByExpansion[12][1] == 3316)
assert(WQA.RuntimeData.WorldQuestTypesByLabel.LE_QUEST_TAG_TYPE_PVP == 1)
local criteriaNamespace, rewardsNamespace = WQA.Criterias, WQA.Rewards
WQA.Criterias.sentinel, WQA.Rewards.sentinel = true, true
loadSource("Criterias/CriteriaType.lua")
loadSource("Rewards/RewardType.lua")
assert(WQA.Criterias == criteriaNamespace and WQA.Criterias.sentinel)
assert(WQA.Rewards == rewardsNamespace and WQA.Rewards.sentinel)
loadSource("WQATurbo.lua")
local coreCreateQuestList = WQA.CreateQuestList
local legacyMounts, legacyPets, legacyCheckWQ, legacyReward =
    WQA.AddMounts, WQA.AddPets, WQA.CheckWQ, WQA.Reward
if not arg[1] then
    assert(legacyMounts == nil, "The compatibility core must not define AddMounts")
    assert(legacyPets == nil, "The compatibility core must not define AddPets")
    assert(legacyCheckWQ == nil, "The compatibility core must not define CheckWQ")
    assert(legacyReward == nil, "The compatibility core must not define Reward")
end
loadSource("Tracking/CollectionCache.lua")
if not arg[1] then
    assert(WQA.CreateQuestList == coreCreateQuestList,
        "CollectionCache must not replace the core CreateQuestList owner")
end
loadSource("Tracking/Achievements.lua")
loadSource("UI/Options.lua")

local publications, refreshes = 0, 0
WQA.AddRewardToQuest = function(_, _, kind)
    assert(kind == "CHANCE" or kind == "ACHIEVEMENT")
    publications = publications + 1
end
WQA.ScheduleOptionsRefresh = function() refreshes = refreshes + 1 end

local modes = {
    { value = "default", unowned = true, owned = false, bulk = true },
    { value = "disabled", unowned = false, owned = false, bulk = true },
    { value = "always", unowned = true, owned = true, bulk = true },
    { value = "exclusive", owner = "Tester-Realm", unowned = true, owned = false },
    { value = "exclusive", owner = "Other-Realm", unowned = false, owned = false },
    { value = "exclusive", unowned = false, owned = false },
    -- Collectibles historically treat this achievement mode like Default.
    { value = "wasEarnedByMe", unowned = true, owned = false },
    { value = "unknown", unowned = true, owned = false },
    { unowned = true, owned = false }
}
local function settings(case)
    return { [100] = case.value, exclusive = { [100] = case.owner } }
end
local function reset(group, case)
    WQA.db.profile[group] = settings(case)
    publications, refreshes = 0, 0
    WQA.itemList = {}
    blocked = {}
end

local collectors = {
    { group = "mounts", run = WQA.AddMounts, data = { { spellID = 100, itemID = 200, quest = { { wqID = 300, trackingID = 400 } } } } },
    { group = "pets", run = WQA.AddPets, data = { { creatureID = 100, itemID = 200, quest = { { wqID = 300, trackingID = 400 } } } } },
    { group = "toys", run = WQA.AddToys, data = { { itemID = 100, quest = { { wqID = 300, trackingID = 400 } } } } }
}
if legacyMounts then
    collectors[#collectors + 1] = { group = "mounts", run = legacyMounts, data = { { spellID = 100, itemID = 200, quest = { { wqID = 300, trackingID = 400 } } } } }
end
if legacyPets then
    collectors[#collectors + 1] = { group = "pets", run = legacyPets, data = { { creatureID = 100, itemID = 200, quest = { { wqID = 300, trackingID = 400 } } } } }
end
for _, collector in ipairs(collectors) do
    for _, case in ipairs(modes) do
        for _, isOwned in ipairs({ false, true }) do
            reset(collector.group, case)
            owned = isOwned
            WQA:InvalidateCollectionCache()
            collector.run(WQA, collector.data)
            local expected = case.unowned
            if isOwned then expected = case.owned end
            assert(publications == (expected and 1 or 0), collector.group .. ": " .. tostring(case.value))
            publications = 0
            blocked[400] = true
            collector.run(WQA, collector.data)
            assert(publications == 0, "Always must not bypass a completed tracking quest")
        end
    end
end

-- Repeated expansion registration still builds each journal snapshot once.
owned = false
reset("mounts", modes[1])
reset("pets", modes[1])
WQA:InvalidateCollectionCache()
local mountsBefore, petsBefore = WQA.collectionCache.mountBuilds, WQA.collectionCache.petBuilds
for i = 1, 3 do
    WQA:AddMounts(collectors[1].data)
    WQA:AddPets(collectors[2].data)
end
assert(WQA.collectionCache.mountBuilds == mountsBefore + 1)
assert(WQA.collectionCache.petBuilds == petsBefore + 1)
publications = 0
WQA:AddMounts({ { spellID = 999, quest = { { wqID = 300 } } } })
WQA:AddPets({ { creatureID = 999, questID = 300 } })
assert(publications == 0, "Missing journal entries must not become unowned matches")

-- Settings completion checks reuse the same snapshots instead of scanning a
-- whole journal for every tracked mount or pet.
owned = true
WQA:InvalidateCollectionCache()
mountsBefore, petsBefore = WQA.collectionCache.mountBuilds, WQA.collectionCache.petBuilds
assert(WQA:IsTrackedObjectCompleted("mounts", 100) == true)
assert(WQA:IsTrackedObjectCompleted("mounts", 100) == true)
assert(WQA:IsTrackedObjectCompleted("mounts", 999) == false)
assert(WQA:IsTrackedObjectCompleted("pets", 100) == true)
assert(WQA:IsTrackedObjectCompleted("pets", 100) == true)
assert(WQA:IsTrackedObjectCompleted("pets", 999) == false)
assert(WQA.collectionCache.mountBuilds == mountsBefore + 1)
assert(WQA.collectionCache.petBuilds == petsBefore + 1)

local completed, earned = false, false
GetAchievementInfo = function()
    return nil, nil, nil, completed, nil, nil, nil, nil, nil, nil, nil, nil, earned
end
for _, case in ipairs(modes) do
    for _, isCompleted in ipairs({ false, true }) do
        for _, isEarned in ipairs({ false, true }) do
            for _, notAccountwide in ipairs({ false, true }) do
                reset("achievements", case)
                completed, earned = isCompleted, isEarned
                WQA.Achievements:Register({ id = 100, criteriaType = "QUEST_SINGLE", criteria = 300, notAccountwide = notAccountwide })
                local expected = case.unowned and (not completed or (notAccountwide and not earned)
                    or case.value == "always" or case.value == "wasEarnedByMe")
                assert(publications == (expected and 1 or 0), "Achievement mode: " .. tostring(case.value))
            end
        end
    end
end

-- Lock the known inherited-force behavior without silently correcting it.
reset("achievements", modes[1])
completed, earned = true, true
local parent = { id = 101, criteriaType = "ACHIEVEMENT", criteria = {
    { id = 100, criteriaType = "QUEST_SINGLE", criteria = 300 }
} }
WQA.db.profile.achievements[101] = "wasEarnedByMe"
WQA.Achievements:Register(parent)
assert(publications == 0, "Character-only forcing must still reset at the child")
WQA.db.profile.achievements[101] = "always"
WQA.Achievements:Register(parent)
assert(publications == 1, "Always forcing must propagate to the child")

local groups = { "achievements", "mounts", "pets", "toys" }
for _, group in ipairs(groups) do
    for _, case in ipairs(modes) do
        reset(group, { value = "exclusive", owner = "Other-Realm" })
        WQA:SetTrackingForCategory({ { id = 100 } }, group, case.value)
        if case.bulk then
            assert(WQA.db.profile[group][100] == case.value)
            assert(WQA.db.profile[group].exclusive[100] == nil)
            assert(refreshes == 1)
            assert(WQA:GetBulkTrackingState({ { id = 100 } }, group) == case.value)
        else
            assert(WQA.db.profile[group][100] == "exclusive")
            assert(WQA.db.profile[group].exclusive[100] == "Other-Realm")
            assert(refreshes == 0)
            assert(WQA:GetBulkTrackingState({ { id = 100 } }, group) == "mixed")
        end
    end
end
local expansion = {}
for _, group in ipairs(groups) do
    reset(group, { value = "exclusive", owner = "Other-Realm" })
    expansion[group] = { { id = 100 } }
end
WQA:SetTrackingForExpansion(expansion, "always")
assert(refreshes == 1, "Expansion bulk changes must schedule exactly one refresh")
assert(WQA:GetExpansionBulkTrackingState(expansion) == "always")
WQA:SetTrackingValue("toys", 100, "exclusive")
assert(WQA.db.profile.toys.exclusive[100] == "Tester-Realm")
assert(WQA:GetExpansionBulkTrackingState(expansion) == "mixed")
local rows = {}
WQA.GetTrackedObjectDisplayName = function() return "Toy" end
WQA:AddTrackedObjectRow(rows, "toys", { itemID = 100 }, "", 1)
WQA.db.profile.toys.exclusive[100] = "Other-Realm"
assert(rows["100"].get() == "other")
WQA.db.profile.toys.exclusive[100] = nil
assert(rows["100"].get() == "exclusive", "A missing owner keeps the existing UI value")

-- The core rebuild owns cache invalidation, so one rebuild invalidates both
-- snapshots exactly once without a load-order wrapper.
if not arg[1] then
    local invalidations = 0
    local invalidateCollectionCache = WQA.InvalidateCollectionCache
    WQA.InvalidateCollectionCache = function(self)
        invalidations = invalidations + 1
        return invalidateCollectionCache(self)
    end
    WQA.data = {}
    for expansionID = 7, 12 do
        WQA.data[expansionID] = {}
    end
    WQA.Criterias.AreaPoi = { list = { stale = true } }
    WQA.collectionCache.mountValid = true
    WQA.collectionCache.petValid = true
    WQA.AddCustom = noop
    WQA.Special = noop
    WQA.Reward = noop
    WQA.EmissaryReward = noop
    WQA:CreateQuestList()
    assert(invalidations == 1, "CreateQuestList must invalidate collection snapshots once")
    assert(WQA.collectionCache.mountValid == false)
    assert(WQA.collectionCache.petValid == false)
end

print("Tracking regression checks passed (collectibles, achievements, ownership, bulk refreshes, rebuild invalidation, journal caching, Settings cache reuse).")

-- Run from the repository root with Lua 5.1.
-- Optional argument: pre-split Options.lua, for full tree metadata parity.
local noop = function() end
local function named(prefix) return function(id) return { name = prefix .. id } end end
C_CurrencyInfo = { GetCurrencyInfo = named("Currency") }
C_QuestLog = { GetTitleForQuestID = function(id) return "Quest" .. id end }
C_Covenants = { GetCovenantData = function(id) return { name = "Covenant" .. id } end }
C_Map = { GetMapInfo = named("Map") }
C_Reputation = { GetFactionDataByID = named("Faction") }
C_Garrison = { GetMissionLink = noop }
GetQuestLink = C_QuestLog.GetTitleForQuestID
GetItemInfo = function(id) return "Item" .. id, "item:" .. id end
GetAchievementInfo = function(id) return id, "Achievement" .. id, nil, id == 2 end
GetAchievementLink = function(id) return "achievement:" .. id end
UnitFactionGroup = function() return "Alliance" end
UnitFullName = function() return "Tester", "Realm" end
GetProfessions = function() return 1 end
GetProfessionInfo = function() return "Alchemy", nil, nil, nil, nil, nil, 171 end
PlayerHasToy = function() return false end
LibStub = function() return { NotifyChange = noop } end
GameTooltip = { Hide = noop }

local function build(baseline)
    local WQA = {
        Constants = {}, L = setmetatable({}, { __index = function(_, k) return k end }),
        faction = "Alliance", data = { custom = {} }, ExpansionList = {}, ZoneIDList = {},
		ShadowlandsCallingData = { CovenantIDs = { 1, 2, 3, 4 } },
        RuntimeData = { CurrencyIDsByExpansion = {}, FactionIDsByExpansion = {},
            EmissaryQuestIDsByExpansion = {}, WorldQuestTypesByLabel = { PVP = 1 } },
        db = { global = { custom = { worldQuest = {}, reward = {}, mission = {}, missionReward = {} } },
            profile = { custom = { worldQuest = {}, reward = {}, mission = {}, missionReward = {} },
                achievements = { exclusive = {} }, mounts = { exclusive = {} },
                pets = { exclusive = {} }, toys = { exclusive = {} },
                options = { reward = { general = { worldQuestType = {} }, currency = {},
                    reputation = {}, recipe = {}, gear = {} }, zone = {}, emissary = {},
					pauseAutomaticRefreshInInstances = true,
					trackShadowlandsCallings = false,
					shadowlandsCallingsByCovenant = { [1] = true, [2] = true, [3] = true, [4] = true },
                    missionTable = { reward = { currency = {}, reputation = {} } } } },
            char = { options = { reward = { gear = { AzeriteArmorCache = true } } } } },
        IsMountCollectedBySpellID = function() return false end,
        IsPetOwnedByCreatureID = function() return false end, Print = noop,
    }
    WQATurbo = WQA
    dofile("Constants.lua")
    dofile("Tracking/TrackingPolicy.lua")
    for i = 6, 12 do
        WQA.ExpansionList[i] = "Expansion" .. i
        WQA.data[i] = { name = "Expansion" .. i, achievements = {
            { id = 1, criteria = { 70000 + i, { id = 71000 + i, name = "Nested Tracker " .. i } } },
            { id = 2 }
        },
            mounts = {{ spellID = 3, itemID = 72000 + i, name = "Mount",
                quest = {{ trackingID = 73000 + i, wqID = 74000 + i }} }},
            pets = {{ creatureID = 4, name = "Pet" }},
            toys = {{ itemID = 5 }} }
        WQA.ZoneIDList[i] = { i }
        WQA.RuntimeData.CurrencyIDsByExpansion[i] = { i, { id = 100 + i, faction = "Horde" } }
        WQA.RuntimeData.FactionIDsByExpansion[i] = { Neutral = { i }, Alliance = { i + 10 } }
        WQA.RuntimeData.EmissaryQuestIDsByExpansion[i] = { i }
        WQA.db.profile.options.reward[i] = { profession = { [171] = {} } }
        WQA.db.char[i] = { profession = { [171] = {} } }
    end
    if baseline then dofile(baseline) else dofile("tools/load_options.lua")() end
    local timers, nextID, refreshes = {}, 0, 0
    function WQA:ScheduleTimer(callback, delay)
        assert(delay == 0.30, "Tree construction must not request a runtime refresh")
        nextID = nextID + 1; timers[nextID] = callback; return nextID
    end
    function WQA:CancelTimer(id) timers[id] = nil end
    function WQA:Refresh(mode, force)
        assert(mode == "settings" and force == true); refreshes = refreshes + 1
    end
    local tree = WQA:GetOptions()
    assert(nextID == 0)
    assert(tree.args.general.name == "Tracking" and tree.args.custom.args.quest)
    local gear = tree.args.reward.args.gear.args
    assert(gear.AzeriteArmorCacheCharacter.order() > gear.AzeriteArmorCache.order)
    assert(gear.AzeriteArmorCacheCharacter.order() < gear.itemLevelUpgradeMin.order)
    assert(gear.AzeriteArmorCacheCharacter.width == "full")
    assert(gear.jewelryCache == nil)
	assert(gear.worldBossTransmog.width == "full")
    local reward = tree.args.reward.args
    assert(reward.Expansion12.order < reward.Expansion6.order)
	local shadowlandsWQ = reward.Expansion9.args.Expansion9WorldQuests.args
	assert(shadowlandsWQ.callings.width == "full")
	for covenantID = 1, 4 do
		local option = shadowlandsWQ["callingCovenant" .. covenantID]
		assert(option.name == "Covenant" .. covenantID and option.width == "full")
		assert(option.disabled())
	end
    assert(reward.Expansion6.args.Expansion6WorldQuests == nil)
    assert(reward.Expansion12.args.Expansion12MissionTable == nil)
    local wq = reward.Expansion10.args.Expansion10WorldQuests.args
    assert(wq.currency.args.Currency110110 == nil, "Hide opposite-faction currencies")
	local bulkOptions = {
		tree.args.reward.args.general.args.worldQuestTypes.args.enableAll,
		wq.zone.args.enableAll,
		wq.currency.args.enableAll,
		wq.reputation.args.enableAll,
		wq.emissary.args.enableAll,
		reward.Expansion8.args.Expansion8MissionTable.args.currency.args.enableAll,
		reward.Expansion8.args.Expansion8MissionTable.args.reputation.args.enableAll
	}
	for _, option in ipairs(bulkOptions) do
		assert(option.name == "Enable all in this list" and option.width == "full")
		option.set(nil, false)
		assert(option.get() == false)
		option.set(nil, true)
		assert(option.get() == true)
	end
	assert(WQA.db.profile.options.reward.currency[110] == nil,
		"Bulk currency changes must not include opposite-faction entries")
	local gameplay = tree.args.options.args.gameplay.args
	assert(gameplay.pauseAutomaticRefreshInInstances.width == "full")
	assert(gameplay.pauseAutomaticRefreshInInstances.get() == true)
	gameplay.pauseAutomaticRefreshInInstances.set(nil, false)
	assert(WQA.db.profile.options.pauseAutomaticRefreshInInstances == false)
    wq.currency.args.Currency1010.set(nil, true)
    wq.zone.args.Map1010.set(nil, true)
    wq.reputation.args.Faction1010.set(nil, true)
    wq.emissary.args.Quest1010.set(nil, true)
    wq.profession.args["171MaxLevel"].set(nil, true)
    wq.profession.args["171Skillup"].set(nil, true)
    wq.containers.args.racingRewardContainers.set(nil, true)
	shadowlandsWQ.callings.set(nil, true)
	assert(not shadowlandsWQ.callingCovenant4.disabled())
	shadowlandsWQ.callingCovenant4.set(nil, false)
    tree.args.reward.args.gear.args.AzeriteArmorCacheCharacter.set(nil, false)
	tree.args.reward.args.gear.args.worldBossTransmog.set(nil, true)
    reward.Expansion8.args.Expansion8MissionTable.args.currency.args.Currency88.set(nil, true)
    tree.args.general.args.Expansion10.args.bulkTracking.set(nil, WQA.Constants.TrackingMode.Always)
    assert(WQA.db.profile.options.reward.currency[10] == true)
    assert(WQA.db.profile.options.zone[10] == true and WQA.db.profile.options.emissary[10] == true)
    assert(WQA.db.profile.options.reward.reputation[10] == true)
    assert(WQA.db.char[10].profession[171].isMaxLevel == true)
    assert(WQA.db.profile.options.reward[10].profession[171].skillup == true)
    assert(WQA.db.profile.options.missionTable.reward.currency[8] == true)
    assert(WQA.db.char.options.reward.gear.AzeriteArmorCache == false)
	assert(WQA.db.profile.options.reward.gear.worldBossTransmog == true)
	assert(WQA.db.profile.options.trackShadowlandsCallings == true)
	assert(WQA.db.profile.options.shadowlandsCallingsByCovenant[4] == false)
    local pending = 0
    for _, callback in pairs(timers) do pending = pending + 1; callback() end
    assert(pending == 1 and refreshes == 1, "Cross-feature changes must share one debouncer")
    tree.args.general.args.search.args.query.set(nil, "achievement")
    local searched = WQA:GetOptions()
    assert(searched.args.general.args.search.args.result_10_achievements)
    if not baseline then
        for _, query in ipairs({ "70010", "nested tracker 10", "72010", "73010", "74010" }) do
            tree.args.general.args.search.args.query.set(nil, query)
            local related = WQA:GetOptions().args.general.args.search.args
            assert(related.result_10_achievements or related.result_10_mounts,
                "Related tracking identifier was not searchable: " .. query)
        end
    end
    return { tree, searched }
end
local current = build()
local count = 0
local function compare(a, b, path)
    assert(type(a) == type(b), path .. " type changed")
    if type(a) == "table" then
        for k, v in pairs(a) do
            if k ~= "order" then compare(v, b[k], path .. "/" .. tostring(k)) end
        end
        for k in pairs(b) do
            if k ~= "order" then assert(a[k] ~= nil, path .. "/" .. tostring(k) .. " missing") end
        end
    elseif type(a) ~= "function" then
        assert(a == b, path .. " value changed: " .. tostring(a) .. " / " .. tostring(b))
    end
    count = count + 1
end
if arg[1] then
    local baseline = build(arg[1])
    current[1].args.reward.args.gear.args.AzeriteArmorCacheCharacter = nil
    current[2].args.reward.args.gear.args.AzeriteArmorCacheCharacter = nil
	current[1].args.reward.args.gear.args.worldBossTransmog = nil
	current[2].args.reward.args.gear.args.worldBossTransmog = nil
    baseline[1].args.reward.args.gear.args.jewelryCache = nil
    baseline[2].args.reward.args.gear.args.jewelryCache = nil
    compare(current, baseline, "options")
    print("Options baseline metadata parity passed (" .. count .. " values)")
end
print("Options structure tests passed (TOC loading, dynamic trees, search, scoped setters and shared refresh)")

-- Run from the repository root with Lua 5.1:
-- lua5.1 tools/test_reward_scanner.lua
local function noop() end

local workerFrame = {}
function workerFrame:Hide() end
function workerFrame:Show() end
function workerFrame:SetScript(_, callback) self.onUpdate = callback end

CreateFrame = function() return workerFrame end
GetTime = function() return 100 end
debugprofilestop = function() return 0 end

C_QuestLog = {
    GetQuestTagInfo = function() return nil end,
    DoesQuestAwardReputationWithFaction = function() return false end,
    GetQuestLogMajorFactionReputationRewards = function() return {} end
}
C_TaskQuest = {
    GetQuestZoneID = function() return 1 end,
    GetQuestsOnMap = function() return {} end,
    RequestPreloadRewardData = noop
}
C_Reputation = { GetFactionDataByID = function() return nil end }
C_Timer = { NewTimer = function() return { Cancel = noop } end }

WQATurbo = {
    Constants = {
        RewardType = { Reputation = "REPUTATION" },
        TrackingMode = { Disabled = "disabled" }
    },
    RegisterChatCommand = noop,
    ShouldTrackReputation = function(self, factionID)
        return self.db.profile.options.reward.reputation[factionID] == true
    end
}
local WQA = WQATurbo
dofile("Scanning/RewardScanner.lua")
assert(type(WQA.Reward) == "function", "RewardScanner must own Reward")

local publications = 0
local publishedMode
WQA.CheckItems = function() return false end
WQA.CheckCurrencies = noop
WQA.RewardScannerProcessProfession = noop
WQA.TurboPublishEnrichment = function(_, mode)
    publications = publications + 1
    publishedMode = mode
end

local function NewState(phase)
    return {
        phase = phase,
        pending = {},
        enabledReputationFactionIDs = {},
        enrichmentDirty = false,
        stats = {
            enrichedQuests = 0,
            itemPending = 0,
            pendingPeak = 0,
            publishCount = 0,
            retryChecks = 0,
            timedOut = 0
        }
    }
end

-- Initial reward details can add item/currency/profession matches. They must
-- dirty the batch even when no direct-reputation match did so.
local state = NewState("initial")
state.publishMode = "settings"
WQA:RewardScannerProcessRewardDetails(state, { questID = 1000 }, nil, 1)
assert(state.enrichmentDirty == true)
assert(state.stats.enrichedQuests == 1)
WQA:RewardScannerPublishPendingChanges(state)
assert(publications == 1)
assert(state.stats.publishCount == 1)
assert(state.enrichmentDirty == false)
assert(publishedMode == "settings")

-- Publication is coalesced: another flush without new inspection is silent.
WQA:RewardScannerPublishPendingChanges(state)
assert(publications == 1)

-- An unresolved item retry remains pending without forcing a redundant popup
-- rebuild. Its completed retry dirties the batch for one final publication.
state = NewState("background-retry")
local itemReady = false
WQA.CheckItems = function() return not itemReady end
local entry = {
    kind = "item",
    work = { questID = 1000 },
    firstSeen = GetTime(),
    attempts = 1,
    reissues = 0
}
WQA:RewardScannerRetryEntry(state, entry)
assert(#state.pending == 1)
assert(state.enrichmentDirty == false)

state.pending = {}
itemReady = true
WQA:RewardScannerRetryEntry(state, entry)
assert(#state.pending == 0)
assert(state.enrichmentDirty == true)
WQA:RewardScannerPublishPendingChanges(state)
assert(publications == 2)
assert(state.stats.publishCount == 1)

-- A scanner created by a Settings refresh retains silent publication mode;
-- ordinary scans continue to use new-task publication.
WQA.Debug = noop
WQA.ZoneIDList = { [12] = { 2599, 2600, 2405 } }
WQA.db = {
    profile = {
        options = {
            zone = { [2599] = true, [2600] = true, [2405] = true },
            reward = { gear = { azeriteTraits = "" }, reputation = {} }
        }
    }
}
WQA.IsMapCurrentlyAvailable = function(_, mapID) return mapID ~= 2599 end
WQA._wqaTurboRefreshMode = "settings"
WQA:Reward()
assert(WQA._wqaRewardScan.publishMode == "settings")
assert(#WQA._wqaRewardScan.maps == 2)
local scannedMaps = {}
for _, mapID in ipairs(WQA._wqaRewardScan.maps) do scannedMaps[mapID] = true end
assert(scannedMaps[2600] and scannedMaps[2405])
assert(not scannedMaps[2599], "The inactive rotating map must not be scanned")
WQA._wqaRewardScan = nil
WQA._wqaTurboRefreshMode = nil
WQA:Reward()
assert(WQA._wqaRewardScan.publishMode == "new")
WQA._wqaRewardScan = nil

-- Refresh exposes its mode while CreateQuestList starts the scanner, and the
-- display publisher passes the retained mode back to CheckWQ. Cached display
-- modes do not rebuild once startup has supplied usable task state.
local refreshModeDuringCreate
local createCount = 0
local checkMode
WQA.CreateQuestList = function(self)
	createCount = createCount + 1
	refreshModeDuringCreate = self._wqaTurboRefreshMode
end
WQA.CheckWQ = function(_, mode) checkMode = mode end
local deferredEvent
local inCombat = false
WQA.event = {
	RegisterEvent = function(_, event) deferredEvent = event end
}
UnitAffectingCombat = function() return inCombat end
LibStub = function() return { Release = noop } end
dofile("Runtime/Display.lua")
WQA:Refresh("settings", true)
assert(refreshModeDuringCreate == "settings")
assert(WQA._wqaTurboRefreshMode == nil)
assert(createCount == 1 and checkMode == "settings")

WQA.questList = nil
WQA.activeTasks = nil
refreshModeDuringCreate = "not-called"
WQA:ShowCached("popup")
assert(createCount == 2 and checkMode == "popup")
assert(refreshModeDuringCreate == nil)

WQA.questList = {}
WQA.activeTasks = {}
WQA:Show("popup")
assert(createCount == 2 and checkMode == "popup")

WQA:Show("new", true)
assert(createCount == 3 and checkMode == "new")
assert(refreshModeDuringCreate == "new")
assert(WQA._wqaTurboRefreshMode == nil)

inCombat = true
WQA.db.profile.options.delayCombat = true
WQA:Refresh("settings", true)
assert(createCount == 3 and deferredEvent == "PLAYER_REGEN_ENABLED")
assert(WQA._wqaTurboRefreshMode == nil)
assert(WQA._wqaTurboPendingRefresh.mode == "settings")
inCombat = false
WQA:ResumeDeferredRefresh()
assert(createCount == 4 and checkMode == "settings")
assert(refreshModeDuringCreate == "settings")
assert(WQA._wqaTurboPendingRefresh == nil)

WQA:TurboPublishEnrichment("settings")
assert(checkMode == "settings")

print("Reward scanner regression checks passed (publication, retries, Settings mode and display routing).")

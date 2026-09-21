-- Run from the repository root with Lua 5.1:
-- lua5.1 tools/test_runtime_lifecycle.lua
local function noop() end

local callbacks = {}
local commands = {}
local optionTables = {}
local settingsPages = {}
local scheduled = {}
local repeating = {}
local shown = {}
local loadedAddons = {}
local taskResolverSchedules = 0
local deferredRefreshes = 0
local taskResolverRestartWindow
local commandCalls = {}
local function commandCall(name)
	return function(_, ...)
		commandCalls[#commandCalls + 1] = { name = name, ... }
	end
end

local eventFrame = {
	registered = {},
	unregistered = {}
}

function eventFrame:RegisterEvent(event)
	self.registered[event] = true
end

function eventFrame:UnregisterEvent(event)
	self.unregistered[event] = true
end

function eventFrame:SetScript(script, callback)
	assert(script == "OnEvent")
	self.onEvent = callback
end

CreateFrame = function(frameType)
	assert(frameType == "Frame")
	return eventFrame
end

UnitFullName = function(unit)
	assert(unit == "player")
	return "Tester", "Realm"
end

date = function(format)
	assert(format == "%M")
	return "0"
end

C_AddOns = {
	LoadAddOn = function(name)
		loadedAddons[#loadedAddons + 1] = name
	end
}

local libraries = {
	["AceConfig-3.0"] = {
		RegisterOptionsTable = function(_, name, options)
			optionTables[#optionTables + 1] = { name = name, options = options }
		end
	},
	["AceConfigDialog-3.0"] = {
		AddToBlizOptions = function(_, name, title, parent)
			local page = { name = name, title = title, parent = parent }
			settingsPages[#settingsPages + 1] = page
			return page, 1000 + #settingsPages
		end
	},
	["AceDBOptions-3.0"] = {
		GetOptionsTable = function(_, db)
			return { database = db }
		end
	}
}

LibStub = function(name)
	return assert(libraries[name], "unexpected library: " .. tostring(name))
end

WQATurbo = {
	db = {
		RegisterCallback = function(owner, event, method)
			callbacks[event] = function() owner[method](owner) end
		end,
		profile = { options = { delay = 5 } },
		global = { completed = {} }
	},
	GetOptions = function() return { tracking = true } end,
	RegisterChatCommand = function(_, command, handler)
		commands[command] = handler
	end,
	ScheduleTimer = function(_, callback, delay, ...)
		local args = { n = select("#", ...), ... }
		scheduled[#scheduled + 1] = {
			callback = callback,
			delay = delay,
			args = args
		}
		return #scheduled
	end,
	ScheduleRepeatingTimer = function(_, callback, delay, ...)
		repeating[#repeating + 1] = {
			callback = callback,
			delay = delay,
			args = { ... }
		}
	end,
	Show = function(_, mode, auto)
		shown[#shown + 1] = { mode = mode, auto = auto }
	end,
	ScheduleTaskResolverCheck = function(_, restartWindow)
		taskResolverSchedules = taskResolverSchedules + 1
		taskResolverRestartWindow = restartWindow
	end,
	ResumeDeferredRefresh = function()
		deferredRefreshes = deferredRefreshes + 1
	end,
	UpdateCallings = function(self, callings) self.lastCallings = callings end,
	ClearCallings = function(self) self.lastCallings = nil end,
	RequestCallings = function(self) self.callingRequests = (self.callingRequests or 0) + 1 end,
	ShowCached = commandCall("cached"),
	Refresh = commandCall("refresh"),
	ShowWQAMigrationPrompt = commandCall("import"),
	PrintPerfSummary = commandCall("perf"),
	ResetPerf = commandCall("reset"),
	PrintRewardScannerStatus = commandCall("scan"),
	PrintReadinessStatus = commandCall("readiness"),
	CollectionCacheSlash = commandCall("cache")
}

local WQA = WQATurbo
dofile("Runtime/Runtime.lua")

assert(commands.wqat == "TurboSlash")

for _, command in ipairs({
	"", "   refresh", "new", "popup", "import", "perf", "reset", "scan",
	"readiness", "cache"
}) do
	WQA:TurboSlash(command)
end
local commandNames = {}
for _, call in ipairs(commandCalls) do commandNames[#commandNames + 1] = call.name end
assert(table.concat(commandNames, ",") ==
	"cached,refresh,refresh,cached,import,perf,reset,scan,readiness,readiness,cache")
assert(commandCalls[2][1] == nil and commandCalls[3][1] == "new")
assert(commandCalls[4][1] == "popup" and commandCalls[5][1] == true)

WQA:OnEnable()

assert(WQA.playerName == "Tester-Realm")
assert(#optionTables == 2)
assert(optionTables[1].name == "WQATurbo")
assert(type(optionTables[1].options) == "function")
assert(optionTables[2].name == "WQATurboProfiles")
assert(#settingsPages == 2)
assert(WQA.optionsFrame == settingsPages[1])
assert(WQA.optionsCategoryID == 1001)
assert(WQA.optionsFrame.Profiles == settingsPages[2])
assert(eventFrame.registered.PLAYER_ENTERING_WORLD)
assert(eventFrame.registered.GARRISON_MISSION_LIST_UPDATE)
assert(eventFrame.registered.WAR_MODE_STATUS_UPDATE)
assert(eventFrame.registered.COVENANT_CALLINGS_UPDATED)
assert(eventFrame.registered.COVENANT_CHOSEN)
assert(eventFrame.registered.QUEST_TURNED_IN)
assert(#scheduled == 1)
assert(scheduled[1].callback == "MaybeOfferWQAMigration")
assert(scheduled[1].delay == 2)
assert(#loadedAddons == 0, "startup must not eagerly load Blizzard_GarrisonUI")

eventFrame.onEvent(eventFrame, "PLAYER_ENTERING_WORLD")
assert(eventFrame.unregistered.PLAYER_ENTERING_WORLD)
assert(#scheduled == 3)
assert(scheduled[2].callback == "Show")
assert(scheduled[2].delay == 1)
assert(scheduled[2].args.n == 2)
assert(scheduled[2].args[1] == nil and scheduled[2].args[2] == true)
assert(type(scheduled[3].callback) == "function")
assert(scheduled[3].delay == 32 * 60)

scheduled[3].callback()
assert(#shown == 1)
assert(shown[1].mode == "new" and shown[1].auto == true)
assert(#repeating == 1)
assert(repeating[1].callback == "Show")
assert(repeating[1].delay == 30 * 60)
assert(repeating[1].args[1] == "new" and repeating[1].args[2] == true)

eventFrame.onEvent(eventFrame, "PLAYER_REGEN_ENABLED")
assert(eventFrame.unregistered.PLAYER_REGEN_ENABLED)
assert(deferredRefreshes == 1)

eventFrame.onEvent(eventFrame, "QUEST_TURNED_IN", 12345)
assert(WQA.db.global.completed[12345] == true)
local callings = { { questID = 60001 } }
eventFrame.onEvent(eventFrame, "COVENANT_CALLINGS_UPDATED", callings)
assert(WQA.lastCallings == callings)
WQA._wqaCallingQuestIDs = { [60001] = true }
eventFrame.onEvent(eventFrame, "QUEST_TURNED_IN", 60001)
assert(WQA._wqaCallingQuestIDs[60001] == nil)
assert(WQA.callingRequests == 1 and taskResolverSchedules == 1)
eventFrame.onEvent(eventFrame, "COVENANT_CHOSEN", 2)
assert(WQA.lastCallings == nil and WQA.callingRequests == 2)

eventFrame.onEvent(eventFrame, "WAR_MODE_STATUS_UPDATE")
assert(#shown == 2 and shown[2].mode == "new" and shown[2].auto == true)

eventFrame.onEvent(eventFrame, "GARRISON_MISSION_LIST_UPDATE")
assert(taskResolverSchedules == 2)
assert(#loadedAddons == 0, "mission updates use C_Garrison without loading its UI")
assert(taskResolverRestartWindow == true)

-- Execute all three profile events through real Options/Display refresh methods.
dofile("Constants.lua")
WQA.RuntimeData = {}
WQA.L = setmetatable({}, { __index = function(_, key) return key end })
C_CurrencyInfo, C_QuestLog = {}, {}
dofile("tools/load_options.lua")()
dofile("Runtime/Display.lua")
UnitAffectingCombat = function() return true end
local minimapDB, notified, rebuilds, cancelled = nil, 0, 0, {}
libraries["LibDBIcon-1.0"] = { Refresh = function(_, name, db)
    assert(name == "WQATurbo")
    minimapDB = db
end }
libraries["AceConfigRegistry-3.0"] = { NotifyChange = function(_, name)
    assert(name == "WQATurbo" and WQA.options == nil)
    notified = notified + 1
end }
WQA.Criterias = { AreaPoi = {} }
WQA.Debug = noop
WQA.CancelTimer = function(_, id) cancelled[id] = true end
WQA.UpdateMinimapIcon = function(self)
    assert(minimapDB == self.db.profile.options.LibDBIcon)
end
WQA.ReleaseQTip = function(self, tooltip)
    assert(tooltip == self.tooltip)
    self.tooltip = nil
end
WQA.CreateQuestList = function(self)
    assert(self._wqaTurboRefreshMode == "settings")
    assert(self.tooltip == nil)
    assert(next(self.watched) == nil and next(self.watchedMissions) == nil)
    assert(next(self.Criterias.AreaPoi.watched) == nil)
    self.questList = { [self.db.profile.testID] = true }
    rebuilds = rebuilds + 1
end
WQA.CheckWQ = function(self, mode)
    assert(mode == "settings")
    self.activeTasks = { self.db.profile.testID }
end
for index, event in ipairs({ "OnProfileChanged", "OnProfileCopied", "OnProfileReset" }) do
    WQA.options = { old = true }
    WQA.tooltip = {}
    WQA.watched, WQA.watchedMissions = { old = true }, { old = true }
    WQA.Criterias.AreaPoi.watched = { old = true }
    WQA:ScheduleOptionsRefresh()
    local timerID = #scheduled
    WQA.db.profile = { testID = index, options = {
        delayCombat = true, LibDBIcon = { hide = index == 2, minimapPos = index * 45 }
    } }
    WQA._wqaTurboPendingRefresh = { mode = "new", auto = true }
    assert(callbacks[event], "missing callback: " .. event)()
    assert(cancelled[timerID], "old settings timer must be cancelled")
    assert(WQA.activeTasks[1] == index and WQA.questList[index])
    assert(WQA._wqaTurboPendingRefresh == nil, "profile rebuild supersedes combat deferral")
    assert(minimapDB == WQA.db.profile.options.LibDBIcon)
end
assert(rebuilds == 3 and notified == 3)
print("Runtime lifecycle regression checks passed (startup, events, profile callbacks, immediate silent rebuild and minimap rebinding).")

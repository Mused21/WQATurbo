-- Run from the repository root with Lua 5.1:
-- lua5.1 tools/test_runtime_lifecycle.lua
local function noop() end

local commands = {}
local optionTables = {}
local settingsPages = {}
local scheduled = {}
local repeating = {}
local shown = {}
local loadedAddons = {}
local missionChecks = 0

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
			return page
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
	CheckMissions = function()
		missionChecks = missionChecks + 1
	end,
	ShowCached = noop,
	Refresh = noop,
	ShowWQAMigrationPrompt = noop,
	PrintPerfSummary = noop,
	ResetPerf = noop,
	PrintRewardScannerStatus = noop,
	CollectionCacheSlash = noop
}

local WQA = WQATurbo
dofile("Runtime/Runtime.lua")

assert(commands.wqat == "TurboSlash")

WQA:OnEnable()

assert(WQA.playerName == "Tester-Realm")
assert(#optionTables == 2)
assert(optionTables[1].name == "WQATurbo")
assert(type(optionTables[1].options) == "function")
assert(optionTables[2].name == "WQATurboProfiles")
assert(#settingsPages == 2)
assert(WQA.optionsFrame == settingsPages[1])
assert(WQA.optionsFrame.Profiles == settingsPages[2])
assert(eventFrame.registered.PLAYER_ENTERING_WORLD)
assert(eventFrame.registered.GARRISON_MISSION_LIST_UPDATE)
assert(eventFrame.registered.WAR_MODE_STATUS_UPDATE)
assert(#scheduled == 1)
assert(scheduled[1].callback == "MaybeOfferWQAMigration")
assert(scheduled[1].delay == 2)
assert(loadedAddons[1] == "Blizzard_GarrisonUI")

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
assert(#shown == 2 and shown[2].mode == "new" and shown[2].auto == true)

eventFrame.onEvent(eventFrame, "QUEST_TURNED_IN", 12345)
assert(WQA.db.global.completed[12345] == true)

eventFrame.onEvent(eventFrame, "WAR_MODE_STATUS_UPDATE")
assert(#shown == 3 and shown[3].mode == "new" and shown[3].auto == true)

eventFrame.onEvent(eventFrame, "GARRISON_MISSION_LIST_UPDATE")
assert(missionChecks == 1)

print("Runtime lifecycle regression checks passed (options, events, startup scheduling, combat, War Mode and missions).")

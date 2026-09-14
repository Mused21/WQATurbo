-- Run from the repository root with Lua 5.1:
-- lua5.1 tools/test_database_schema.lua
WQATurbo = {}
dofile("Database.lua")

local WQA = WQATurbo
assert(WQA.DatabaseSchemaVersion == 1)

local function Apply(database)
	WQA.db = database
	return WQA:ApplyDatabaseSchemaMigrations()
end

-- A fresh database receives canonical tables and the current version.
local fresh = {}
assert(Apply(fresh) == true)
assert(fresh.global.schemaVersion == 1)
assert(type(fresh.global.custom.worldQuest) == "table")
assert(type(fresh.global.custom.worldQuestReward) == "table")

-- Representative legacy custom shapes migrate without replacing canonical
-- entries that already exist.
local canonicalQuest = { enabled = false, mapID = 84 }
local legacyQuest = { enabled = true, mapID = 85 }
local legacy = {
	global = {
		custom = {
			[100] = legacyQuest,
			[200] = { enabled = true },
			worldQuest = { [100] = canonicalQuest },
			worldQuestReward = { [400] = true }
		},
		customReward = { [300] = false, [400] = false }
	}
}
assert(Apply(legacy) == true)
assert(legacy.global.schemaVersion == 1)
assert(legacy.global.custom[100] == nil and legacy.global.custom[200] == nil)
assert(legacy.global.custom.worldQuest[100] == canonicalQuest)
assert(legacy.global.custom.worldQuest[200].enabled == true)
assert(legacy.global.custom.worldQuestReward[300] == true)
assert(legacy.global.custom.worldQuestReward[400] == true)
assert(legacy.global.customReward == nil)

-- Reapplying the migration is a no-op and preserves table identity.
local custom = legacy.global.custom
local quests = custom.worldQuest
local rewards = custom.worldQuestReward
assert(Apply(legacy) == false)
assert(legacy.global.custom == custom)
assert(custom.worldQuest == quests and custom.worldQuestReward == rewards)
assert(legacy.global.schemaVersion == 1)

-- Malformed legacy containers recover to the canonical shape.
local malformed = { global = { custom = "invalid", customReward = "invalid" } }
assert(Apply(malformed) == true)
assert(malformed.global.schemaVersion == 1)
assert(type(malformed.global.custom.worldQuest) == "table")
assert(type(malformed.global.custom.worldQuestReward) == "table")
assert(malformed.global.customReward == nil)

local malformedVersion = { global = { schemaVersion = 0.5 } }
assert(Apply(malformedVersion) == true)
assert(malformedVersion.global.schemaVersion == 1)

-- A database from a newer addon version must never be downgraded or mutated.
local futureCustom = {}
local future = { global = { schemaVersion = 99, custom = futureCustom } }
assert(Apply(future) == false)
assert(future.global.schemaVersion == 99 and future.global.custom == futureCustom)

WQA.db = nil
assert(WQA:ApplyDatabaseSchemaMigrations() == false)

print("Database schema regression checks passed (fresh, legacy, malformed, idempotent and future databases).")

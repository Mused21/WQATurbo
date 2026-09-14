---@class WQATurbo
local WQA = WQATurbo

local CURRENT_SCHEMA_VERSION = 1

WQA.DatabaseSchemaVersion = CURRENT_SCHEMA_VERSION

local function EnsureTable(parent, key)
	if type(parent[key]) ~= "table" then
		parent[key] = {}
	end

	return parent[key]
end

local migrations = {
	[1] = function(database)
		local global = EnsureTable(database, "global")
		local custom = EnsureTable(global, "custom")
		local worldQuests = EnsureTable(custom, "worldQuest")
		local worldQuestRewards = EnsureTable(custom, "worldQuestReward")

		-- Early WQA Turbo builds stored custom World Quests directly under
		-- global.custom. Prefer an existing canonical entry if both shapes exist.
		for key, value in pairs(custom) do
			if type(key) == "number" then
				if worldQuests[key] == nil then
					worldQuests[key] = value
				end
				custom[key] = nil
			end
		end

		-- The old reward table represented membership by key. Preserve that
		-- behavior while moving the keys into the canonical custom namespace.
		if type(global.customReward) == "table" then
			for itemID in pairs(global.customReward) do
				worldQuestRewards[itemID] = true
			end
		end
		global.customReward = nil
	end
}

---Apply each missing WQA Turbo SavedVariables migration exactly once.
---@return boolean changed
function WQA:ApplyDatabaseSchemaMigrations()
	if type(self.db) ~= "table" then
		return false
	end

	local global = EnsureTable(self.db, "global")
	local version = tonumber(global.schemaVersion) or 0
	if version < 0 or version % 1 ~= 0 then
		version = 0
	end
	if version >= CURRENT_SCHEMA_VERSION then
		return false
	end

	for nextVersion = version + 1, CURRENT_SCHEMA_VERSION do
		local migrate = migrations[nextVersion]
		if migrate then
			migrate(self.db)
		end
		global.schemaVersion = nextVersion
	end

	return true
end

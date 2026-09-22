-- Run from the repository root with Lua 5.1:
-- lua5.1 tools/test_callings.lua
local covenantID = 1
local now = 1000000
local requests, resolverChecks = 0, 0
local timeLeft = {}
local completed = {}
local requestedQuestData = {}

GetServerTime = function() return now end
C_Covenants = {
	GetActiveCovenantID = function() return covenantID end,
	GetCovenantData = function(id)
		return { name = ({ "Kyrian", "Venthyr", "Night Fae", "Necrolord" })[id] }
	end,
}
C_CovenantCallings = {
	AreCallingsUnlocked = function() return true end,
	RequestCallings = function() requests = requests + 1 end,
}
C_TaskQuest = {
	GetQuestTimeLeftSeconds = function(questID) return timeLeft[questID] end,
}
C_QuestLog = {
	IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end,
	RequestLoadQuestByID = function(questID) requestedQuestData[questID] = true end,
}
WQATurbo = {
	Constants = { RewardType = { Custom = "CUSTOM" } },
	db = {
		profile = { options = {
			trackShadowlandsCallings = false,
			shadowlandsCallingsByCovenant = { [1] = true, [2] = true, [3] = true, [4] = true },
		} },
		global = { shadowlandsCallingRotations = {} },
		char = { shadowlandsCallingCompletions = {} },
	},
	questList = {},
	AddRewardToQuest = function(self, questID, rewardType)
		assert(rewardType == "CUSTOM")
		self.questList[questID] = self.questList[questID] or {}
		self.questList[questID].reward = { custom = true }
	end,
	ScheduleTaskResolverCheck = function(_, restart)
		assert(restart == true)
		resolverChecks = resolverChecks + 1
	end,
}
local WQA = WQATurbo
dofile("Data/ShadowlandsCallings.lua")
dofile("Tracking/Callings.lua")

assert(#WQA.ShadowlandsCallingData.QuestFamilies == 24)
local mappedCount = 0
for _ in pairs(WQA.ShadowlandsCallingData.ByQuestID) do mappedCount = mappedCount + 1 end
assert(mappedCount == 96, "Every Calling family must contain four unique quest IDs")
assert(WQA.ShadowlandsCallingData.SanctumMapIDs[1] == 1707)
assert(WQA.ShadowlandsCallingData.SanctumMapIDs[2] == 1699)
assert(WQA.ShadowlandsCallingData.SanctumMapIDs[3] == 1701)
assert(WQA.ShadowlandsCallingData.SanctumMapIDs[4] == 1698)

WQA:AddCallings()
assert(requests == 0 and next(WQA.questList) == nil)

WQA.db.profile.options.trackShadowlandsCallings = true
WQA:AddCallings()
assert(requests == 1)

-- Two known Kyrian rotations expand to all four covenant variants. A future
-- unknown Calling remains limited to the active covenant.
timeLeft[60358] = 3600
timeLeft[60391] = 7200
timeLeft[69999] = 1800
WQA:UpdateCallings({ { questID = 60358 }, { questID = 60391 }, { questID = 69999 }, {}, { questID = 0 } })
for _, questID in ipairs({ 60358, 60365, 60364, 60363, 60391, 60389, 60381, 60390, 69999 }) do
	assert(WQA:IsCallingActive(questID), "Expected active Calling " .. questID)
	assert(WQA.questList[questID].isCalling)
	assert(WQA.questList[questID].callingZoneID)
	assert(requestedQuestData[questID])
end
assert(WQA.questList[60358].callingZoneID == 1707)
assert(WQA.questList[60365].callingZoneID == 1699)
assert(WQA.questList[60364].callingZoneID == 1701)
assert(WQA.questList[60363].callingZoneID == 1698)
assert(WQA:GetCallingCovenantName(60363) == "Necrolord")
assert(WQA:GetCallingTimeLeftMinutes(60363) == 60)
assert(WQA:GetCallingTimeLeftMinutes(60390) == 120)
assert(not WQA:IsCallingActive(0))

-- Covenant selectors independently hide inferred variants.
WQA.db.profile.options.shadowlandsCallingsByCovenant[2] = false
WQA:RegisterCallings()
assert(not WQA:IsCallingActive(60365) and not WQA:IsCallingActive(60389))
assert(WQA:IsCallingActive(60363) and WQA:IsCallingActive(60390))

-- Turning in one covenant's quest hides only that variant until the shared
-- rotation expires. Other selected covenant variants remain available.
WQA:CompleteCalling(60358)
assert(not WQA:IsCallingActive(60358))
assert(WQA:IsCallingActive(60364) and WQA:IsCallingActive(60363))
assert(WQA.db.char.shadowlandsCallingCompletions[60358] == now + 3600)
assert(requests == 2)

-- Future active-covenant IDs get the same turn-in suppression even though
-- their family cannot safely be inferred for other covenants.
WQA:CompleteCalling(69999)
assert(not WQA:IsCallingActive(69999))
assert(WQA.db.char.shadowlandsCallingCompletions[69999] == now + 1800)
assert(requests == 3)

-- A payload with the completed slot absent must retain the observed rotation.
WQA:UpdateCallings({ { questID = 60391 }, { questID = 69999 } })
assert(not WQA:IsCallingActive(60358) and WQA:IsCallingActive(60363))
assert(not WQA:IsCallingActive(69999))

-- A covenant switch rejects old-covenant IDs and accepts the new variants.
covenantID = 4
WQA:ClearCallings()
WQA:RequestCallings()
assert(requests == 4 and not WQA:IsCallingActive(60363))
timeLeft[60363] = 3500
timeLeft[60390] = 7100
WQA:UpdateCallings({ { questID = 60358 }, { questID = 60363 }, { questID = 60390 } })
assert(WQA:IsCallingActive(60363) and WQA:IsCallingActive(60390))
assert(not WQA:IsCallingActive(60358), "Recorded Kyrian completion must survive a switch")

-- Blizzard completion flags also suppress inactive-covenant variants.
completed[60364] = true
WQA:RegisterCallings()
assert(not WQA:IsCallingActive(60364))
completed[60364] = nil

-- Expiration prunes both the rotation and its per-character completion lock.
now = now + 7201
WQA:RegisterCallings()
assert(not WQA:IsCallingActive(60358) and not WQA:IsCallingActive(60363))
assert(next(WQA.db.global.shadowlandsCallingRotations) == nil)
assert(next(WQA.db.char.shadowlandsCallingCompletions) == nil)

-- With every covenant disabled, no refresh request or row is produced.
for id = 1, 4 do WQA.db.profile.options.shadowlandsCallingsByCovenant[id] = false end
WQA:ClearCallings()
WQA:RequestCallings()
assert(requests == 4)
WQA:UpdateCallings({ { questID = 60455 } })
assert(next(WQA._wqaCallingQuestIDs) == nil)

WQA.db.profile.options.trackShadowlandsCallings = false
WQA:ClearCallings()
WQA:AddCallings()
assert(requests == 4 and not WQA:IsCallingActive(60455))
WQA:UpdateCallings({ { questID = 60455 } })
assert(not WQA:IsCallingActive(60455))
assert(resolverChecks >= 5)

print("Covenant Calling family, selection, completion and expiration tests passed")

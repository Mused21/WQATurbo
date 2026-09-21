-- Run from the repository root with Lua 5.1:
-- lua5.1 tools/test_callings.lua
local covenantID = 1
local requests, resolverChecks = 0, 0

C_Covenants = { GetActiveCovenantID = function() return covenantID end }
C_CovenantCallings = {
	AreCallingsUnlocked = function() return true end,
	RequestCallings = function() requests = requests + 1 end
}
WQATurbo = {
	Constants = { RewardType = { Custom = "CUSTOM" } },
	db = { profile = { options = { trackShadowlandsCallings = false } } },
	questList = {},
	AddRewardToQuest = function(self, questID, rewardType)
		assert(rewardType == "CUSTOM")
		self.questList[questID] = { reward = { custom = true } }
	end,
	ScheduleTaskResolverCheck = function(_, restart)
		assert(restart == true)
		resolverChecks = resolverChecks + 1
	end
}
local WQA = WQATurbo
dofile("Tracking/Callings.lua")

WQA:AddCallings()
assert(requests == 0 and next(WQA.questList) == nil)
WQA.db.profile.options.trackShadowlandsCallings = true
WQA:AddCallings()
assert(requests == 1)
WQA:UpdateCallings({ { questID = 60001 }, { questID = 60002 }, {}, { questID = 0 } })
assert(WQA:IsCallingActive(60001) and WQA:IsCallingActive(60002))
assert(not WQA:IsCallingActive(0))
assert(WQA.questList[60001].isCalling and WQA.questList[60002].isCalling)
assert(resolverChecks == 1)

-- The current event replaces the previous covenant's available IDs.
WQA:UpdateCallings({ { questID = 60002 } })
assert(not WQA:IsCallingActive(60001) and WQA:IsCallingActive(60002))
WQA.questList[60003] = { reward = { custom = true } }
WQA:UpdateCallings({ { questID = 60002 }, { questID = 60003 } })
assert(WQA.questList[60003].hasOtherSource)
WQA:RegisterCallings()
assert(WQA.questList[60003].hasOtherSource, "Repeat events must not invent or lose another source")
covenantID = 2
assert(not WQA:IsCallingActive(60002), "Old covenant data must not survive a switch")
WQA:ClearCallings()
WQA:RequestCallings()
assert(requests == 2)
WQA:UpdateCallings({ { questID = 61001 } })
assert(WQA:IsCallingActive(61001) and not WQA:IsCallingActive(60002))
assert(WQA.questList[61001].isCalling)

-- Empty data and an off switch both leave callings hidden.
WQA:UpdateCallings({})
assert(not WQA:IsCallingActive(61001))
WQA.db.profile.options.trackShadowlandsCallings = false
WQA:AddCallings()
assert(requests == 2 and not WQA:IsCallingActive(61001))
WQA:UpdateCallings({ { questID = 62001 } })
assert(not WQA:IsCallingActive(62001))
assert(resolverChecks == 6)
print("Covenant calling tracking tests passed")

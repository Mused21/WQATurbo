---@class WQATurbo
local WQA = WQATurbo

-- Covenant IDs are stable Blizzard identifiers:
-- 1 Kyrian, 2 Venthyr, 3 Night Fae, 4 Necrolord.
local covenantIDs = { 1, 2, 3, 4 }

-- Primary covenant-sanctum UiMapIDs used only when Blizzard does not expose
-- zone metadata for an inactive covenant's inferred Calling quest.
local sanctumMapIDs = {
	[1] = 1707, -- Elysian Hold
	[2] = 1699, -- Sinfall
	[3] = 1701, -- Heart of the Forest
	[4] = 1698, -- Seat of the Primus
}

-- Every row is one Calling rotation shared by all covenants. Each value is
-- the covenant-specific quest ID for the same objective and expiration.
local questFamilies = {
	{ [1] = 60358, [2] = 60365, [3] = 60364, [4] = 60363 }, -- Gildenite Grab
	{ [1] = 60372, [2] = 60370, [3] = 60369, [4] = 60371 }, -- A Wealth of Wealdwood
	{ [1] = 60380, [2] = 60378, [3] = 60373, [4] = 60379 }, -- A Source of Sorrowvine
	{ [1] = 60377, [2] = 60375, [3] = 60374, [4] = 60376 }, -- Bonemetal Bonanza
	{ [1] = 60391, [2] = 60389, [3] = 60381, [4] = 60390 }, -- Aiding Ardenweald
	{ [1] = 60392, [2] = 60394, [3] = 60384, [4] = 60393 }, -- Aiding Bastion
	{ [1] = 60395, [2] = 60397, [3] = 60383, [4] = 60396 }, -- Aiding Maldraxxus
	{ [1] = 60400, [2] = 60399, [3] = 60382, [4] = 60398 }, -- Aiding Revendreth
	{ [1] = 60403, [2] = 60401, [3] = 60388, [4] = 60402 }, -- Training in Ardenweald
	{ [1] = 60404, [2] = 60406, [3] = 60387, [4] = 60405 }, -- Training in Bastion
	{ [1] = 60407, [2] = 60409, [3] = 60386, [4] = 60408 }, -- Training in Maldraxxus
	{ [1] = 60412, [2] = 60410, [3] = 60385, [4] = 60411 }, -- Training in Revendreth
	{ [1] = 60415, [2] = 60417, [3] = 60414, [4] = 60416 }, -- Rare Resources
	{ [1] = 60424, [2] = 60422, [3] = 60419, [4] = 60423 }, -- A Call to Ardenweald
	{ [1] = 60425, [2] = 60427, [3] = 60418, [4] = 60426 }, -- A Call to Bastion
	{ [1] = 60430, [2] = 60431, [3] = 60420, [4] = 60429 }, -- A Call to Maldraxxus
	{ [1] = 60434, [2] = 60432, [3] = 60421, [4] = 60433 }, -- A Call to Revendreth
	{ [1] = 60439, [2] = 60441, [3] = 60438, [4] = 60440 }, -- Challenges in Ardenweald
	{ [1] = 60442, [2] = 60444, [3] = 60437, [4] = 60443 }, -- Challenges in Bastion
	{ [1] = 60447, [2] = 60446, [3] = 60436, [4] = 60445 }, -- Challenges in Maldraxxus
	{ [1] = 60450, [2] = 60448, [3] = 60435, [4] = 60449 }, -- Challenges in Revendreth
	{ [1] = 60454, [2] = 60456, [3] = 60452, [4] = 60455 }, -- Storm the Maw
	{ [1] = 60458, [2] = 60460, [3] = 60457, [4] = 60459 }, -- Anima Salvage
	{ [1] = 60465, [2] = 60463, [3] = 60462, [4] = 60464 }, -- Anima Appeal
}

local byQuestID = {}
for familyID, family in ipairs(questFamilies) do
	for _, covenantID in ipairs(covenantIDs) do
		local questID = family[covenantID]
		byQuestID[questID] = {
			familyID = familyID,
			covenantID = covenantID,
		}
	end
end

WQA.ShadowlandsCallingData = {
	CovenantIDs = covenantIDs,
	SanctumMapIDs = sanctumMapIDs,
	QuestFamilies = questFamilies,
	ByQuestID = byQuestID,
}

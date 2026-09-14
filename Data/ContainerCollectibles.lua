---@class WQATurbo
local WQA = WQATurbo

-- Collectible outcomes for containers whose loot pool is fixed.
--
-- Dragonriding customization ownership is recorded through account-wide
-- hidden quests. Benthic tokens use item-modified appearance source IDs so
-- the scanner can ask Blizzard whether the visual appearance is collected.
WQA.data.containerCollectibles = {
	-- Zandalari Empire Equipment Cache. Unlike Benthic tokens, this cache
	-- resolves directly to armor for the current loot specialization, so only
	-- the active character's armor type is relevant.
	[165866] = {
		transmogSources = {
			all = { 94217 }, -- Loa-Pledged Drape
			cloth = { 94002, 93997, 94001, 93999, 93996 },
			leather = { 94010, 94005, 94009, 94007, 94004 },
			mail = { 94018, 94013, 94017, 94015, 94012 },
			plate = { 94027, 94021, 94026, 94024, 94020 }
		}
	},

	-- Dragon Racer's Purse
	[199192] = {
		questIDs = {
			69171, 69179, 69217, 69314, 69329,
			69353, 69567, 69588, 69809, 69823
		}
	},
	-- Reach Racer's Purse
	[204359] = {
		questIDs = { 69202, 69325, 69798, 73055 }
	},
	-- Cavern Racer's Purse
	[205226] = {
		questIDs = {
			69178, 69197, 69305, 73060,
			73805, 73833, 73839, 73853
		}
	},
	-- Dream Racer's Purse
	[210549] = {
		questIDs = {
			73822, 73827, 73834, 73852,
			77129, 77136, 77139, 77149
		}
	},

	-- Benthic Girdle. Each armor token resolves for the active loot
	-- specialization, so only the current character's armor type is relevant.
	[169477] = {
		transmogSources = {
			cloth = { 104107, 105514 },
			leather = { 104115, 105515 },
			mail = { 104123, 105516 },
			plate = { 104132, 105517 }
		}
	},
	-- Benthic Bracers
	[169478] = {
		transmogSources = {
			cloth = { 104108, 105247, 105359, 105379, 105457, 105478 },
			leather = { 104116, 105248, 105360, 105378, 105456, 105477 },
			mail = { 104124, 105249, 105361, 105377, 105455, 105476 },
			plate = { 104133, 105250, 105362, 105367, 105454, 105475 }
		}
	},
	-- Benthic Helm
	[169479] = {
		transmogSources = {
			cloth = { 104104 },
			leather = { 104112 },
			mail = { 104120 },
			plate = { 104128 }
		}
	},
	-- Benthic Chestguard
	[169480] = {
		transmogSources = {
			cloth = { 104129 },
			leather = { 104109 },
			mail = { 104117 },
			plate = { 104125 }
		}
	},
	-- Benthic Cloak
	[169481] = {
		transmogSources = {
			all = { 105150, 105151, 105152, 105153 }
		}
	},
	-- Benthic Leggings
	[169482] = {
		transmogSources = {
			cloth = { 104105, 105243, 105363 },
			leather = { 104113, 105244, 105364 },
			mail = { 104121, 105245, 105365 },
			plate = { 104130, 105246, 105366 }
		}
	},
	-- Benthic Treads
	[169483] = {
		transmogSources = {
			cloth = { 104102, 105263, 105395, 105518 },
			leather = { 104110, 105262, 105396, 105519 },
			mail = { 104118, 105261, 105397, 105520 },
			plate = { 104126, 105260, 105398, 105521 }
		}
	},
	-- Benthic Spaulders
	[169484] = {
		transmogSources = {
			cloth = { 104106 },
			leather = { 104114 },
			mail = { 104122 },
			plate = { 104131 }
		}
	},
	-- Benthic Gauntlets
	[169485] = {
		transmogSources = {
			cloth = { 104103, 105232, 105389, 105480, 105522 },
			leather = { 104111, 105233, 105390, 105481, 105523 },
			mail = { 104119, 105234, 105391, 105482, 105524 },
			plate = { 104127, 105235, 105392, 105483, 105525 }
		}
	}
}

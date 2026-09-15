---@class WQATurbo
local WQA = WQATurbo

-- Collectible outcomes for containers whose loot pool is fixed.
--
-- Dragonriding customization ownership is recorded through account-wide
-- hidden quests. Benthic tokens use item-modified appearance source IDs so
-- the scanner can ask Blizzard whether the visual appearance is collected.
WQA.data.containerCollectibles = {
	-- Azerite Armor Cache. The ordinary cache resolves to head, shoulder and
	-- chest rewards from the six Battle for Azeroth leveling zones. Keep the
	-- pool split by armor type because the generated item follows the active
	-- character's loot specialization. Dungeon (contexts 1/2) and Warfront
	-- (context 5) cache links resolve different pools and therefore fail open.
	-- Verified against ATT source 74e370f and Retail 12.1.0.69382
	-- Item/ItemModifiedAppearance data on 2026-09-15.
	[163857] = {
		unsupportedItemContexts = {
			[1] = true,
			[2] = true,
			[5] = true
		},
		transmogSources = {
			cloth = {
				93966, 93968, 93991, 93998, 94000, 94023,
				94030, 94032, 94055, 94062, 94064, 94087,
				94094, 94096, 94119, 94126, 94128, 94151
			},
			leather = {
				93971, 93974, 93976, 94003, 94006, 94008,
				94035, 94038, 94040, 94067, 94070, 94072,
				94099, 94102, 94104, 94131, 94134, 94136,
				98582
			},
			mail = {
				93979, 93982, 93984, 94011, 94014, 94016,
				94043, 94046, 94048, 94075, 94078, 94080,
				94107, 94110, 94112, 94139, 94142, 94144
			},
			plate = {
				93987, 93990, 93993, 94019, 94022, 94025,
				94051, 94054, 94057, 94083, 94086, 94089,
				94115, 94118, 94121, 94147, 94150, 94153
			}
		}
	},

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

local WQA = WQATurbo

local RuntimeData = {
	CurrencyIDsByExpansion = {
		[6] = {
			823, -- Apexis Crystal
			824 -- Garrison Resources
		},
		[7] = {
			1220, -- Order Resources
			1226, -- Nethershard
			1342, -- Legionfall War Supplies
			1508, -- Veiled Argunite
			1533 -- Wakening Essence
		},
		[8] = {
			1553, -- Azerite
			1560, -- War Ressource
			{ id = 1716, faction = "Horde" }, -- Honorbound Service Medal
			{ id = 1717, faction = "Alliance" }, -- 7th Legion Service Medal
			1721, -- Prismatic Manapearl
			1602, -- Conquest
			1166 -- Timewarped Badge
		},
		[9] = {
			1819, -- Medallion of Service (Kyrian covenant)
			1889 -- Adventure Campaign Progress
		},
		[10] = {
			2003, -- Dragon Isles Supplies
			2123, -- Bloody Tokens
			2657, -- Mysterious Fragment
			2245, -- Flightstones
		},
		[11] = {
			3008, -- Valorstones
			3056, -- Kej
			2815, -- Resonance Crystals
		},
		[12] = {
			3316 -- Voidlight Marl
		}
	},
	WorldQuestTypesByLabel = {
		["LE_QUEST_TAG_TYPE_PVP"] = Enum.QuestTagType.PvP,
		["LE_QUEST_TAG_TYPE_PET_BATTLE"] = Enum.QuestTagType.PetBattle,
		["LE_QUEST_TAG_TYPE_PROFESSION"] = Enum.QuestTagType.Profession,
		["LE_QUEST_TAG_TYPE_DUNGEON"] = Enum.QuestTagType.Dungeon
	},
	ValNaigtalRotation = {
		portalMapID = 2405,
		valMapID = 2599,
		naigtalMapID = 2600,
		-- The first live Naigtal week ended at the June 23-25 regional
		-- resets. Rounding those reset timestamps to Unix week 2947 gives
		-- one region-independent parity anchor.
		naigtalReferenceResetWeek = 2947
	},
	EmissaryQuestIDsByExpansion = {
		[7] = {
			42233, -- Highmountain Tribes
			42420, -- Court of Farondis
			42170, -- The Dreamweavers
			42422, -- The Wardens
			42421, -- The Nightfallen
			42234, -- Valarjar
			48639, -- Army of the Light
			48642, -- Argussian Reach
			48641, -- Armies of Legionfall
			43179 -- Kirin Tor
		},
		[8] = {
			50604, -- Tortollan Seekers
			50562, -- Champions of Azeroth
			{ id = 50599, faction = "Alliance" }, -- Proudmoore Admiralty
			{ id = 50600, faction = "Alliance" }, -- Order of Embers
			{ id = 50601, faction = "Alliance" }, -- Storm's Wake
			{ id = 50605, faction = "Alliance" }, -- 7th Legion
			{ id = 50598, faction = "Horde" }, -- Zandalari Empire
			{ id = 50603, faction = "Horde" }, -- Voldunai
			{ id = 50602, faction = "Horde" }, -- Talanji's Expedition
			{ id = 50606, faction = "Horde" }, -- The Honorbound
			-- 8.2
			-- 2391, -- Rustbolt Resistance
			{ id = 56119, faction = "Alliance" }, -- Waveblade Ankoan
			{ id = 56120, faction = "Horde" } -- The Unshackled
		}
	},
	FactionIDsByExpansion = {
		[7] = {
			Neutral = {
				2165,
				2170,
				1894, -- The Wardens
				1900, -- Court of Farondis
				1883, -- Dreamweavers
				1828, -- Highmountain Tribe
				1948, -- Valarjar
				1859 -- The Nightfallen
			}
		},
		[8] = {
			Neutral = {
				2164, -- Champions of Azeroth
				2163, -- Tortollan Seekers
				2391, -- Rustbolt Resistance
				2417, -- Uldum Accord
				2415 -- Rajani
			},
			Alliance = {
				2160, -- Proudmoore Admiralty
				2161, -- Order of Embers
				2162, -- Storm's Wake
				2159, -- 7th Legion
				2400 -- Waveblade Ankoan
			},
			Horde = {
				2103, -- Zandalari Empire
				2156, -- Talanji's Expedition
				2158, -- Voldunai
				2157, -- The Honorbound
				2373 -- The Unshackled
			}
		},
		[9] = {
			Neutral = {
				2413, -- Court of Harvesters
				2470, -- Death's Advance
				2407, -- The Ascended
				2478, -- The Enlightened
				2410, -- The Undying Army
				2465, -- The Wild Hunt
				2432 -- Ve'nari
			}
		},
		[10] = {
			Neutral = {
				2615, -- Azerothian Archives
				2507, -- Dragonscale Expedition
				2574, -- Dream Wardens
				2511, -- Iskaara Tuskarr
				2564, -- Loamm Niffen
				2503, -- Maruuk Centaur
				2510 -- Valdrakken Accord
			}
		},
		[11] = {
			Neutral = {
				2594, -- The Assembly of the Deeps
				2570, -- Hallowfall Arathi
				2600, -- The Severed Threads
				2590 -- Council of Dornogal
			}
		},
		[12] = {
			Neutral = {
				2710, -- Silvermoon Court
				2696, -- Amani Tribe
				2704, -- Hara'ti
				2699, -- The Singularity
				2770, -- Slayer's Duellum
				2772, -- Zul'jarra's Forces
				2773, -- Captain Tokka
				2792 -- Ritual Sites
			}
		}
	}
}

WQA.RuntimeData = RuntimeData

-- Preserve the existing public table while runtime consumers move to the
-- canonical RuntimeData namespace.
WQA.EmissaryQuestIDList = RuntimeData.EmissaryQuestIDsByExpansion

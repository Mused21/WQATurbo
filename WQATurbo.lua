---@class WQATurbo
local WQA = WQATurbo
local RewardType = WQA.Constants.RewardType
local CriteriaType = WQA.Constants.CriteriaType
local TaskType = WQA.Constants.TaskType
local TrackingMode = WQA.Constants.TrackingMode
local TrackingPolicy = WQA.TrackingPolicy
local EmissaryQuestIDList = WQA.RuntimeData.EmissaryQuestIDsByExpansion

-- AllTheThings exposes SearchForLink before its search module has necessarily
-- finished OnLoad initialization. Protect the integration from that startup
-- race and avoid hammering ATT repeatedly while it is still becoming ready.
local ATT_SEARCH_RETRY_DELAY = 1

function WQA:SafeATTSearchForLink(itemLink)
	local att = _G.AllTheThings

	if type(att) ~= "table" or type(att.SearchForLink) ~= "function" then
		return nil, false
	end

	local now = GetTime()
	if self._attSearchRetryAfter and now < self._attSearchRetryAfter then
		return nil, false
	end

	local ok, result = pcall(att.SearchForLink, itemLink)

	if not ok then
		self._attSearchRetryAfter = now + ATT_SEARCH_RETRY_DELAY
		self:Debug("AllTheThings SearchForLink not ready", result)
		return nil, false
	end

	self._attSearchRetryAfter = nil
	return result, true
end

-- Blizzard
-- Return the quest type used by WQA Turbo filters.
--
-- Preserve explicit special types. For older profession WQs, Blizzard may
-- expose a tradeskillLineID even when worldQuestType is missing/inconsistent.
function WQA:GetEffectiveWorldQuestType(questID, questTagInfo)
	questTagInfo = questTagInfo or C_QuestLog.GetQuestTagInfo(questID)

	if not questTagInfo then
		return 0
	end

	local worldQuestType = questTagInfo.worldQuestType

	if
		worldQuestType == Enum.QuestTagType.PvP
		or worldQuestType == Enum.QuestTagType.PetBattle
		or worldQuestType == Enum.QuestTagType.Dungeon
		or worldQuestType == Enum.QuestTagType.Profession
	then
		return worldQuestType
	end

	if questTagInfo.tradeskillLineID then
		return Enum.QuestTagType.Profession
	end

	return worldQuestType or 0
end

-- Final eligibility gate for every World Quest, including achievement-backed
-- quests that are available before background reward enrichment finishes.
function WQA:ShouldIncludeWorldQuestForCurrentMode(questID, questTagInfo)
	questTagInfo = questTagInfo or C_QuestLog.GetQuestTagInfo(questID)
	local worldQuestType = self:GetEffectiveWorldQuestType(questID, questTagInfo)
	local typeOptions = self.db.profile.options.reward.general.worldQuestType

	if typeOptions[worldQuestType] == false then
		return false
	end

	if
		worldQuestType == Enum.QuestTagType.PvP
		and not C_PvP.IsWarModeDesired()
		and not self.db.profile.options.showWarModeQuestsWithoutWarMode
	then
		return false
	end

	-- Zone filtering is a final publication gate too, not only a scanner
	-- optimization. Static achievement/mount/pet/toy mappings can put a World
	-- Quest into questList before RewardScanner sees it; without this check a
	-- disabled zone could therefore still appear in the popup. AceDB defaults
	-- zone entries to true, so only an explicit false excludes a quest.
	if self.GetQuestZoneID then
		local zoneID = self:GetQuestZoneID(questID)
		if type(zoneID) == "number" and self.db.profile.options.zone[zoneID] == false then
			return false
		end
	end

	return true
end

-- Treat both classic Exalted reputations and modern Major Factions at maximum
-- Renown as finished for the optional "hide maxed reputations" setting.
function WQA:IsReputationMaxed(factionID)
	if type(factionID) ~= "number" then
		return false
	end

	-- Friendship reputations (for example Captain Tokka) do not use the
	-- classic Hated -> Exalted reaction scale and are not Major Factions.
	-- Query their dedicated API first and treat standing >= maxRep, or a
	-- missing next threshold at a valid friendship rank, as fully completed.
	if C_GossipInfo and type(C_GossipInfo.GetFriendshipReputation) == "function" then
		local ok, friendship = pcall(C_GossipInfo.GetFriendshipReputation, factionID)
		if
			ok
			and type(friendship) == "table"
			and type(friendship.friendshipFactionID) == "number"
			and friendship.friendshipFactionID ~= 0
		then
			if
				type(friendship.standing) == "number"
				and type(friendship.maxRep) == "number"
				and friendship.maxRep > 0
				and friendship.standing >= friendship.maxRep
			then
				return true
			end

			if friendship.nextThreshold == nil and type(friendship.standing) == "number" and friendship.standing > 0 then
				return true
			end
		end
	end

	if
		C_Reputation
		and type(C_Reputation.IsMajorFaction) == "function"
		and C_Reputation.IsMajorFaction(factionID)
		and C_MajorFactions
		and type(C_MajorFactions.HasMaximumRenown) == "function"
	then
		local ok, hasMaximumRenown = pcall(C_MajorFactions.HasMaximumRenown, factionID)
		if ok and hasMaximumRenown then
			return true
		end
	end

	local factionData = C_Reputation and C_Reputation.GetFactionDataByID
		and C_Reputation.GetFactionDataByID(factionID)
	return factionData and type(factionData.reaction) == "number" and factionData.reaction >= 8 or false
end

---Return whether an enabled reputation should contribute a tracked reward.
---@param factionID number
---@param missionTable boolean?
---@return boolean
function WQA:ShouldTrackReputation(factionID, missionTable)
	local options = self.db.profile.options
	local configuredReputations

	if missionTable then
		configuredReputations = options.missionTable.reward.reputation
	else
		configuredReputations = options.reward.reputation
	end

	if not configuredReputations or configuredReputations[factionID] ~= true then
		return false
	end

	return not (options.hideExaltedReputations and self:IsReputationMaxed(factionID))
end

local GetBountiesForMapID = C_QuestLog.GetBountiesForMapID
local GetTitleForQuestID = C_QuestLog.GetTitleForQuestID
local GetCurrencyLink = C_CurrencyInfo.GetCurrencyLink
local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local L = WQA.L

local newOrder
do
	local current = 0
	function newOrder()
		current = current + 1
		return current
	end
end

WQA.data.custom = { wqID = "", rewardID = "", rewardType = "none", questType = TaskType.WorldQuest }
WQA.data.custom.mission = { missionID = "", rewardID = "", rewardType = "none" }

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj =
	ldb:NewDataObject(
		"WQATurbo",
		{
			type = "data source",
			text = "WQA",
			icon = "Interface\\Icons\\INV_Misc_Map06"
		}
	)

local icon = LibStub("LibDBIcon-1.0")

function WQA:PruneOtherFactionData(faction)
	for k, v in pairs(self.data) do
		for kk, vv in pairs(v) do
			if type(vv) == "table" then
				for kkk, vvv in pairs(vv) do
					if type(vvv) == "table" and vvv.faction and vvv.faction ~= faction then
						self.data[k][kk][kkk] = nil
					end
				end
			end
		end
	end
end

function WQA:OnInitialize()
	-- Remove data for the other faction
	local faction = UnitFactionGroup("player")
	self:PruneOtherFactionData(faction)
	self.faction = faction

	-- Defaults
	local defaults = {
		char = {
			options = {
				reward = {
					gear = {
						AzeriteArmorCache = true
					}
				}
			},
			["*"] = {
				["profession"] = {
					["*"] = {
						isMaxLevel = true
					}
				}
			}
		},
		profile = {
			options = {
				["*"] = true,
				chat = true,
				PopUp = false,
				popupRememberPosition = false,
				popupCollapsedExpansions = {},
				showWarModeQuestsWithoutWarMode = false,
				hideExaltedReputations = false,
				popupX = 600,
				popupY = 800,
				zone = { ["*"] = true },
				reward = {
					gear = {
						["*"] = true,
						itemLevelUpgradeMin = 1,
						PercentUpgradeMin = 1,
						unknownSource = false,
						azeriteTraits = "",
						conduit = false
					},
					general = {
						gold = false,
						goldMin = 0,
						worldQuestType = {
							["*"] = true
						}
					},
					reputation = { ["*"] = false },
					currency = {},
					craftingreagent = { ["*"] = false },
					["*"] = {
						["*"] = true,
						profession = {
							["*"] = {
								skillup = true
							}
						}
					}
				},
				emissary = { ["*"] = false },
				missionTable = {
					reward = {
						gold = false,
						goldMin = 0,
						["*"] = {
							["*"] = false
						}
					}
				},
				delay = 5,
				LibDBIcon = { hide = false }
			},
			["achievements"] = { exclusive = {}, ["*"] = TrackingMode.Default },
			["mounts"] = { exclusive = {}, ["*"] = TrackingMode.Default },
			["pets"] = { exclusive = {}, ["*"] = TrackingMode.Default },
			["toys"] = { exclusive = {}, ["*"] = TrackingMode.Default },
			custom = {
				["*"] = { ["*"] = true }
			},
			["*"] = { ["*"] = true }
		},
		global = {
			completed = { ["*"] = false },
			custom = {
				["*"] = { ["*"] = false }
			}
		}
	}
	self:ApplyPendingWQAMigrationBeforeAceDB()

self.db = LibStub("AceDB-3.0"):New("WQATurboDB", defaults, true)

	-- copy old data
	if type(self.db.global.custom) == "table" then
		for k, v in pairs(self.db.global.custom) do
			if type(k) == "number" then
				self.db.global.custom.worldQuest[k] = v
				self.db.global.custom[k] = nil
			end
		end
	end
	if type(self.db.global.customReward) == "table" then
		for k, v in pairs(self.db.global.customReward) do
			self.db.global.custom.worldQuestReward[k] = true
		end
		self.db.global.customReward = nil
	end

	-- Minimap Icon
	icon:Register("WQATurbo", dataobj, self.db.profile.options.LibDBIcon)
end

WQA:RegisterChatCommand("wqa", "slash")

function WQA:slash(input)
	local arg1 = string.lower(input)

	if arg1 == "" then
		self:Show()
	elseif arg1 == "new" then
		self:Show("new")
	elseif arg1 == "popup" then
		self:Show("popup")
	end
end

function WQA:CreateQuestList()
	self:Debug("CreateQuestList")
	if self.ResetTaskResolverRetry then
		self:ResetTaskResolverRetry()
	end
	if self.InvalidateCollectionCache then
		self:InvalidateCollectionCache()
	end
	self.questList = {}
	self.questPinList = {}
	self.questPinMapList = {}
	self._wqaQuestPinsActive = nil
	self._wqaQuestPinRequests = {}
	self.missionList = {}
	wipe(self.itemList)
	self.questFlagList = {}
	self.Criterias.AreaPoi.list = {}

	for expansionID = 7, 12 do
		local data = self.data[expansionID]

		if (data.achievements) then
			for _, v in pairs(data.achievements) do
				self.Achievements:Register(v)
			end
		end

		if (data.mounts) then
			self:AddMounts(data.mounts)
		end

		if (data.pets) then
			self:AddPets(data.pets)
		end

		if (data.toys) then
			self:AddToys(data.toys)
		end
	end


	self:AddCustom()
	self:Special()
	self:Reward()
	self:EmissaryReward()
end

function WQA:AddToys(toys)
	for _, toy in pairs(toys) do
		local itemID = toy.itemID
		local enabled, forced = TrackingPolicy.GetState(
			self.db.profile.toys, itemID, self.playerName)

		if enabled then
			if not PlayerHasToy(toy.itemID) or forced then
				if toy.source and toy.source.type == "ITEM" then
					self.itemList[toy.source.itemID] = true
				else
					if toy.questID then
						self:AddRewardToQuest(toy.questID, RewardType.Chance, toy.itemID)
					else
						for _, v in pairs(toy.quest) do
							if not IsQuestFlaggedCompleted(v.trackingID) then
								self:AddRewardToQuest(v.wqID, RewardType.Chance, toy.itemID)
							end
						end
					end
				end
			end
		end
	end
end

function WQA:AddCustom()
	-- Custom World Quests
	if type(self.db.global.custom.worldQuest) == "table" then
		for questID, v in pairs(self.db.global.custom.worldQuest) do
			if self.db.profile.custom.worldQuest[questID] == true then
				self:AddRewardToQuest(questID, RewardType.Custom)
				if v.questType == CriteriaType.QuestFlag then
					self.questFlagList[questID] = true
				elseif v.questType == CriteriaType.QuestPin and v.mapID then
					C_QuestLine.RequestQuestLinesForMap(v.mapID)
					self.questPinMapList[v.mapID] = true
					self.questPinList[questID] = true
				end
			end
		end
	end

	-- Custom Missions
	if type(self.db.global.custom.mission) == "table" then
		for k, v in pairs(self.db.global.custom.mission) do
			if self.db.profile.custom.mission[k] == true then
				self:AddRewardToMission(k, RewardType.Custom)
			end
		end
	end
end

function WQA:AddRewardToMission(missionID, rewardType, reward)
	if not self.missionList[missionID] then
		self.missionList[missionID] = {}
	end
	local l = self.missionList[missionID]

	self:AddReward(l, rewardType, reward)
end

function WQA:AddRewardToQuest(questID, rewardType, reward, emissary)
	if not self.questList[questID] then
		self.questList[questID] = {}
	end
	local l = self.questList[questID]

	self:AddReward(l, rewardType, reward, emissary)
end

function WQA:AddEmissaryReward(questID, rewardType, reward)
	self:AddRewardToQuest(questID, rewardType, reward, true)
end

WQA.first = false

function WQA:link(x)
	if not x then
		return ""
	end
	local t = string.upper(x.type)
	if t == "ACHIEVEMENT" then
		return GetAchievementLink(x.id)
	elseif t == "ITEM" then
		return select(2, GetItemInfo(x.id))
	else
		return ""
	end
end

function WQA:GetRewardForID(questID, key, type)
	local l
	if type == TaskType.Mission then
		l = self.missionList[questID].reward
	else
		l = self.questList[questID].reward
	end

	local r = ""
	if l then
		if l.item then
			if l.item then
				if l.item.transmog then
					r = r .. l.item.transmog
				end
				if l.item.itemLevelUpgrade then
					if r ~= "" then
						r = r .. " "
					end
					r = r .. "|cFF00FF00+" .. l.item.itemLevelUpgrade .. " iLvl|r"
				end
				if l.item.itemPercentUpgrade then
					if r ~= "" then
						r = r .. ", "
					end
					r = r .. "|cFF00FF00+" .. l.item.itemPercentUpgrade .. "%|r"
				end
				if l.item.AzeriteArmorCache then
					for i = 1, 5, 2 do
						local upgrade = l.item.AzeriteArmorCache[i]
						if upgrade > 0 then
							r = r .. "|cFF00FF00+" .. upgrade .. " iLvl|r"
						elseif upgrade < 0 then
							r = r .. "|cFFFF0000" .. upgrade .. " iLvl|r"
						else
							r = r .. "±" .. upgrade
						end
						if i ~= 5 then
							r = r .. " / "
						end
					end
				end
				if l.item.cache then
					local cache = l.item.cache
					local upgradeChance = cache.upgradeNum / cache.n
					upgradeChance = 1 / 2 * upgradeChance + .5
					upgradeChance = string.format("%X", (1 - upgradeChance) * 255)
					if string.len(upgradeChance) == 1 then
						upgradeChance = "0" .. upgradeChance
					end
					r =
						r ..
						"|cFF" ..
						upgradeChance ..
						"FF" ..
						upgradeChance .. cache.upgradeNum .. "/" .. cache.n .. " max +" .. cache.upgradeMax .. "|r"
					local item = {
						itemLink = itemLink,
						cache = { upgradeNum = upgradeNum, n = n, upgradeMax = upgradeMax }
					}
				end
			end
			r = l.item.itemLink .. " " .. r
		end
		if l.currency and key ~= "item" then
			r = r .. l.currency.amount .. " " .. l.currency.name
		end
	end
	return r
end

function WQA:AnnounceChat(tasks, silent)
	if self.db.profile.options.chat == false then
		return
	end
	if next(tasks) == nil then
		if silent ~= true then
			print(L["NO_QUESTS"])
		end
		return
	end

	local output = L["WQChat"]
	print(output)
	local expansion, zoneID
	for _, task in ipairs(tasks) do
		local text, i = "", 0

		if self.db.profile.options.chatShowExpansion == true then
			if self:GetExpansion(task) ~= expansion then
				expansion = self:GetExpansion(task)
				print(self:GetExpansionName(expansion))
			end
		end

		if self.db.profile.options.chatShowZone == true then
			if self:GetTaskZoneID(task) ~= zoneID then
				zoneID = self:GetTaskZoneID(task)
				print(self:GetTaskZoneName(task))
			end
		end

		local l
		if task.type == TaskType.WorldQuest then
			l = self.questList[task.id]
		elseif task.type == TaskType.Mission then
			l = self.missionList[task.id]
		elseif task.type == TaskType.AreaPoi then
			l = self.Criterias.AreaPoi.list[task.id][task.mapId]
		end

		local rewards = l.reward

		local more
		for k, v in pairs(rewards) do
			local rewardText = self:GetRewardTextByID(task.id, k, v, 1, task.type)
			if k == "achievement" or k == "chance" or k == "azeriteTraits" then
				for j = 2, 3 do
					local t = self:GetRewardTextByID(task.id, k, v, j, task.type)
					if t then
						rewardText = rewardText .. " & " .. t
					end
				end
				if self:GetRewardTextByID(task.id, k, v, 4, task.type) then
					more = true
				end
			end

			i = i + 1
			if i > 1 then
				text = text .. " & " .. rewardText
			else
				text = rewardText
			end
		end
		if more == true then
			text = text .. " & ..."
		end

		if self.db.profile.options.chatShowTime then
			output = "   " ..
				string.format(L["WQforAchTime"], self:GetTaskLink(task), self:formatTime(self:GetTaskTime(task)), text)
		else
			output = "   " .. string.format(L["WQforAch"], self:GetTaskLink(task), text)
		end

		print(output)
	end
end

local inspectScantip = CreateFrame("GameTooltip", "WQATurboInspectScanningTooltip", nil, "GameTooltipTemplate")
inspectScantip:SetOwner(UIParent, "ANCHOR_NONE")

local EquipLocToSlot1 = {
	INVTYPE_HEAD = 1,
	INVTYPE_NECK = 2,
	INVTYPE_SHOULDER = 3,
	INVTYPE_BODY = 4,
	INVTYPE_CHEST = 5,
	INVTYPE_ROBE = 5,
	INVTYPE_WAIST = 6,
	INVTYPE_LEGS = 7,
	INVTYPE_FEET = 8,
	INVTYPE_WRIST = 9,
	INVTYPE_HAND = 10,
	INVTYPE_FINGER = 11,
	INVTYPE_TRINKET = 13,
	INVTYPE_CLOAK = 15,
	INVTYPE_WEAPON = 16,
	INVTYPE_SHIELD = 17,
	INVTYPE_2HWEAPON = 16,
	INVTYPE_WEAPONMAINHAND = 16,
	INVTYPE_RANGED = 16,
	INVTYPE_RANGEDRIGHT = 16,
	INVTYPE_WEAPONOFFHAND = 17,
	INVTYPE_HOLDABLE = 17,
	INVTYPE_TABARD = 19
}
local EquipLocToSlot2 = {
	INVTYPE_FINGER = 12,
	INVTYPE_TRINKET = 14,
	INVTYPE_WEAPON = 17
}

local ReputationItemList = {
	-- Army of the Light Insignia
	[152957] = 2165,
	[152955] = 2165,
	[152956] = 2165,
	[152958] = 2165,
	[152960] = 2170,
	-- Argussian Reach Insignia
	[152954] = 2170,
	[152959] = 2170,
	[152961] = 2170,
	[141342] = 1894,
	-- The Wardens
	[139025] = 1894,
	[141991] = 1894,
	[147415] = 1894,
	[150929] = 1894,
	[146945] = 1894,
	[146939] = 1894,
	[141340] = 1900,
	-- Court of Farondis
	[139023] = 1900,
	[147410] = 1900,
	[141989] = 1900,
	[150927] = 1900,
	[146937] = 1900,
	[146943] = 1900,
	[139021] = 1883,
	-- Dreamweavers
	[141988] = 1883,
	[147411] = 1883,
	[141339] = 1883,
	[150926] = 1883,
	[146942] = 1883,
	[146936] = 1883,
	-- Highmountain Tribe
	[141341] = 1828,
	[139024] = 1828,
	[141990] = 1828,
	[147412] = 1828,
	[150928] = 1828,
	[146944] = 1828,
	[146938] = 1828,
	-- Valarjar
	[139020] = 1948,
	[141338] = 1948,
	[141987] = 1948,
	[147414] = 1948,
	[146935] = 1948,
	[146941] = 1948,
	[150925] = 1948,
	-- The Nightfallen
	[141343] = 1859,
	[141992] = 1859,
	[139026] = 1859,
	[147413] = 1859,
	[150930] = 1859,
	[146940] = 1859,
	[146946] = 1859
}

local ReputationCurrencyList = {
	[1579] = 2164, -- Champions of Azeroth
	[1598] = 2163, -- Tortollan Seekers
	[1593] = 2160, -- Proudmoore Admiralty
	[1592] = 2161, -- Order of Embers
	[1594] = 2162, -- Storm's Wake
	[1599] = 2159, -- 7th Legion
	[1597] = 2103, -- Zandalari Empire
	[1595] = 2156, -- Talanji's Expedition
	[1596] = 2158, -- Voldunai
	[1600] = 2157, -- The Honorbound
	[1742] = 2391, -- Rustbolt Resistance
	[1739] = 2400, -- Waveblade Ankoan
	[1757] = 2417, -- Uldum Accord
	[1758] = 2415, -- Rajani
	[1738] = 2373, -- The Unshackled
	[1807] = 2413, -- Court of Harvesters
	[1907] = 2470, -- Death's Advance
	[1804] = 2407, -- The Ascended
	[1982] = 2478, -- The Enlightened
	[1805] = 2410, -- The Undying Army
	[1806] = 2465, -- The Wild Hunt
	[1880] = 2432, -- Ve'nari
	[2819] = 2615, -- Azerothian Archives
	[2031] = 2507, -- Dragonscale Expedition
	[2652] = 2574, -- Dream Wardens
	[2109] = 2511, -- Iskaara Tuskarr
	[2420] = 2564, -- Loamm Niffen
	[2108] = 2503, -- Maruuk Centaur
	[2106] = 2510, -- Valdrakken Accord
	[2902] = 2594, -- The Assembly of the Deeps
	[2899] = 2570, -- Hallowfall Arathi
	[2903] = 2600, -- The Severed Threads
	[2897] = 2590 -- Council of Dornogal
}

local weaponCache = {
	[165872] = true, -- 7th Legion Equipment Cache
	[165867] = true, -- Kul Tiran Weapons Cache
	[165871] = true, -- Honorbound Equipment Cache
	[165863] = true -- Zandalari Weapons Cache
}
local armorCache = {
	[165872] = true, -- 7th Legion Equipment Cache
	[165870] = true, -- Order of Embers Equipment Cache
	[165868] = true, -- Storm's Wake Equipment Cache
	[165869] = true, -- Proudmoore Admiralty Equipment Cache
	[165871] = true, -- Honorbound Equipment Cache
	[165865] = true, -- Nazmir Expeditionary Equipment Cache
	[165864] = true, -- Voldunai Equipment Cache
	[165866] = true -- Zandalari Empire Equipment Cache
}

local benthicArmorToken = {
	[169477] = true, -- Benthic Girdle
	[169478] = true, -- Benthic Bracers
	[169479] = true, -- Benthic Helm
	[169480] = true, -- Benthic Chestguard
	[169481] = true, -- Benthic Cloak
	[169482] = true, -- Benthic Leggings
	[169483] = true, -- Benthic Treads
	[169484] = true, -- Benthic Spaulders
	[169485] = true -- Benthic Gauntlets
}

local racingRewardContainer = {
	[199192] = true, -- Dragon Racer's Purse
	[204359] = true, -- Reach Racer's Purse
	[205226] = true, -- Cavern Racer's Purse
	[210549] = true -- Dream Racer's Purse
}

-- Transmog tracking.
--
-- Blizzard exposes both the account-wide appearance state and the exact item
-- source state. Use those APIs as the source of truth; ATT/CanIMogIt are only
-- used for their familiar display icons. This avoids treating "appearance
-- collected from another item" as a completely unknown appearance.
function WQA:IsTransmogable(itemLink)
	-- White/poor items are not useful transmog rewards.
	local quality = select(3, C_Item.GetItemInfo(itemLink))
	if quality == nil then
		return
	end
	if quality <= 1 then
		return false
	end

	local _, _, _, slotName = C_Item.GetItemInfoInstant(itemLink)

	-- See if the item is in a valid transmoggable slot.
	local slot = EquipLocToSlot1[slotName]
	if slot == nil or slot == 11 or slot == 13 or slot == 2 then
		return false
	end

	return true
end

local function GetUnknownAppearanceIcon()
	if _G.AllTheThings then
		return "|TInterface\\Addons\\AllTheThings\\assets\\unknown:0|t"
	end
	if _G.CanIMogIt then
		return "|TInterface\\AddOns\\CanIMogIt\\Icons\\UNKNOWN:0|t"
	end

	-- Standalone fallback when neither collection addon is installed.
	return "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t"
end

local function GetUnknownSourceIcon()
	if _G.AllTheThings then
		return "|TInterface\\Addons\\AllTheThings\\assets\\known_circle:0|t"
	end
	if _G.CanIMogIt then
		return "|TInterface\\AddOns\\CanIMogIt\\Icons\\KNOWN_circle:0|t"
	end

	-- Standalone fallback: appearance is known, but this exact source is not.
	return "|TInterface\\RaidFrame\\ReadyCheck-Waiting:0|t"
end

---Return the icon WQA Turbo should show for a transmog reward.
---
---The first state is account-wide appearance ownership. The second is exact
---source ownership (the specific item). They intentionally map to the two
---separate settings "Unknown appearance" and "Unknown source".
---@param itemLink string
---@return string? icon
---@return boolean retry
function WQA:GetTrackedTransmogIcon(itemLink)
	local appearanceID, sourceID = C_TransmogCollection.GetItemInfo(itemLink)
	if not appearanceID or not sourceID then
		return nil, true
	end

	-- `appearanceIsCollected` from GetAppearanceInfoBySource() is not reliable
	-- for every multi-source appearance. Determine both states from the actual
	-- sources instead: exact-source ownership comes from this source, while
	-- appearance ownership is true when ANY source for the appearance is owned.
	local sourceInfo = C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
	if not sourceInfo then
		return nil, true
	end

	local sourceIsCollected = sourceInfo.isCollected == true
	local appearanceIsCollected = sourceIsCollected

	if not appearanceIsCollected then
		local appearanceSources = C_TransmogCollection.GetAllAppearanceSources(appearanceID)
		if not appearanceSources then
			return nil, true
		end

		for _, appearanceSourceID in ipairs(appearanceSources) do
			local appearanceSourceInfo = C_TransmogCollection.GetAppearanceSourceInfo(appearanceSourceID)
			if appearanceSourceInfo and appearanceSourceInfo.isCollected then
				appearanceIsCollected = true
				break
			end
		end
	end

	if not appearanceIsCollected then
		if self.db.profile.options.reward.gear.unknownAppearance then
			return GetUnknownAppearanceIcon(), false
		end
		return nil, false
	end

	if not sourceIsCollected and self.db.profile.options.reward.gear.unknownSource then
		return GetUnknownSourceIcon(), false
	end

	return nil, false
end

function WQA:CheckItems(questID, isEmissary)
	local numQuestRewards = GetNumQuestLogRewards(questID)

	if numQuestRewards == 0 then
		return false
	end

	local retryArray = {}

	for rewardIndex = 1, numQuestRewards do
		retryArray[rewardIndex] = self:CheckReward(questID, isEmissary, rewardIndex)
	end

	for _, retry in pairs(retryArray) do
		if retry then return true end
	end

	return false
end

local function ClassifyContainerReward(self, questID, isEmissary, itemID, itemLink)
	local retry = false

	-- Benthic armor tokens
	if benthicArmorToken[itemID] and self.db.profile.options.reward.gear.armorCache then
		local complete
		complete, retry = self:IsContainerCollectibleComplete(itemID)
		if not complete then
			self:AddRewardToQuest(questID, RewardType.Item, { itemLink = itemLink }, isEmissary)
		end
	end

	-- Dragonflight racing reward containers
	if
		racingRewardContainer[itemID]
		and self.db.profile.options.reward[10].racingRewardContainers
	then
		local complete
		complete, retry = self:IsContainerCollectibleComplete(itemID)
		if not complete then
			self:AddRewardToQuest(questID, RewardType.Item, { itemLink = itemLink }, isEmissary)
		end
	end

	return retry
end

local function ClassifyGearUpgradeReward(self, questID, isEmissary, itemLink, itemEquipLoc)
	local retry = false

	-- Ask Pawn if this is an Upgrade
	if PawnIsItemAnUpgrade and self.db.profile.options.reward.gear.PawnUpgrade then
		local Item = PawnGetItemData(itemLink)
		if Item then
			local UpgradeInfo, BestItemFor, SecondBestItemFor, NeedsEnhancements = PawnIsItemAnUpgrade(Item)
			if
				UpgradeInfo and UpgradeInfo[1].PercentUpgrade * 100 >= self.db.profile.options.reward.gear.PercentUpgradeMin and
				UpgradeInfo[1].PercentUpgrade < 10
			then
				local item = {
					itemLink = itemLink,
					itemPercentUpgrade = math.floor(UpgradeInfo[1].PercentUpgrade * 100 + .5)
				}
				self:AddRewardToQuest(questID, RewardType.Item, item, isEmissary)
			end
		end
	end

	-- StatWeightScore
	local StatWeightScore = LibStub("AceAddon-3.0"):GetAddon("StatWeightScore", true)
	if StatWeightScore and self.db.profile.options.reward.gear.StatWeightScore then
		local slotID = EquipLocToSlot1[itemEquipLoc]
		if slotID then
			local itemPercentUpgrade = 0
			local ScoreModule = StatWeightScore:GetModule("StatWeightScoreScore")
			local SpecModule = StatWeightScore:GetModule("StatWeightScoreSpec")
			local ScanningTooltipModule = StatWeightScore:GetModule("StatWeightScoreScanningTooltip")
			local specs = SpecModule:GetSpecs()
			for _, spec in pairs(specs) do
				if spec.Enabled then
					local score =
						ScoreModule:CalculateItemScore(
							itemLink,
							slotID,
							ScanningTooltipModule:ScanTooltip(itemLink),
							spec,
							equippedItemHasUniqueGem
						).Score
					local equippedScore
					local equippedLink = GetInventoryItemLink("player", slotID)
					if equippedLink then
						equippedScore =
							ScoreModule:CalculateItemScore(
								equippedLink,
								slotID,
								ScanningTooltipModule:ScanTooltip(equippedLink),
								spec,
								equippedItemHasUniqueGem
							).Score
					else
						retry = true
					end

					local slotID2 = EquipLocToSlot2[itemEquipLoc]
					if slotID2 then
						equippedLink = GetInventoryItemLink("player", slotID2)
						if equippedLink then
							local equippedScore2 =
								ScoreModule:CalculateItemScore(
									equippedLink,
									slotID2,
									ScanningTooltipModule:ScanTooltip(equippedLink),
									spec,
									equippedItemHasUniqueGem
								).Score
							if (equippedScore or 0) > equippedScore2 then
								equippedScore = equippedScore2
							end
						else
							retry = true
						end
					end

					if equippedScore then
						if (score - equippedScore) / equippedScore * 100 > itemPercentUpgrade then
							itemPercentUpgrade = (score - equippedScore) / equippedScore * 100
						end
					end
				end
			end
			if itemPercentUpgrade >= self.db.profile.options.reward.gear.PercentUpgradeMin then
				local item = { itemLink = itemLink, itemPercentUpgrade = math.floor(itemPercentUpgrade + .5) }
				self:AddRewardToQuest(questID, RewardType.Item, item, isEmissary)
			end
		end
	end

	-- Upgrade by itemLevel
	if self.db.profile.options.reward.gear.itemLevelUpgrade then
		local itemLevel1, itemLevel2
		local slotID = EquipLocToSlot1[itemEquipLoc]
		if slotID then
			if GetInventoryItemID("player", slotID) then
				local itemLink1 = GetInventoryItemLink("player", slotID)
				if itemLink1 then
					itemLevel1 = GetDetailedItemLevelInfo(itemLink1)
					if not itemLevel1 then
						retry = true
					end
				else
					retry = true
				end
			end
		end
		if EquipLocToSlot2[itemEquipLoc] then
			slotID = EquipLocToSlot2[itemEquipLoc]
			if GetInventoryItemID("player", slotID) then
				local itemLink2 = GetInventoryItemLink("player", slotID)
				if itemLink2 then
					itemLevel2 = GetDetailedItemLevelInfo(itemLink2)
					if not itemLevel2 then
						retry = true
					end
				else
					retry = true
				end
			end
		end

		local itemLevel = GetDetailedItemLevelInfo(itemLink)
		if not itemLevel then
			retry = true
		else
			local itemLevelEquipped = math.min(itemLevel1 or 1000, itemLevel2 or 1000)
			if itemLevel - itemLevelEquipped >= self.db.profile.options.reward.gear.itemLevelUpgradeMin then
				local item = { itemLink = itemLink, itemLevelUpgrade = itemLevel - itemLevelEquipped }
				self:AddRewardToQuest(questID, RewardType.Item, item, isEmissary)
			end
		end
	end

	return retry
end

local function ClassifyEquipmentCacheReward(self, questID, isEmissary, itemID, itemLink)
	local retry = false

	-- Azerite Armor Cache
	if
		itemID == 163857
		and self.db.profile.options.reward.gear.AzeriteArmorCache
		and self.db.char.options.reward.gear.AzeriteArmorCache
	then
		-- Enabling the option tracks the cache itself.
		-- Upgrade calculations below are only supplemental metadata.
		self:AddRewardToQuest(questID, RewardType.Item, { itemLink = itemLink }, isEmissary)
		local itemLevel = GetDetailedItemLevelInfo(itemLink)
		if not itemLevel then
			return true
		end
		local AzeriteArmorCacheIsUpgrade = false
		local AzeriteArmorCache = {}
		for i = 1, 5, 2 do
			if GetInventoryItemID("player", i) then
				local itemLink1 = GetInventoryItemLink("player", i)
				if itemLink1 then
					local itemLevel1 = GetDetailedItemLevelInfo(itemLink1)
					if itemLevel1 then
						AzeriteArmorCache[i] = itemLevel - itemLevel1
						if itemLevel > itemLevel1 and itemLevel - itemLevel1 >= self.db.profile.options.reward.gear.itemLevelUpgradeMin then
							AzeriteArmorCacheIsUpgrade = true
						end
					else
						retry = true
					end
				else
					retry = true
				end
			else
				AzeriteArmorCache[i] = itemLevel
				if itemLevel and itemLevel >= self.db.profile.options.reward.gear.itemLevelUpgradeMin then
					AzeriteArmorCacheIsUpgrade = true
				end
			end
		end
		if AzeriteArmorCacheIsUpgrade == true then
			local item = { itemLink = itemLink, AzeriteArmorCache = AzeriteArmorCache }
			self:AddRewardToQuest(questID, RewardType.Item, item, isEmissary)
		end
	end

	-- Equipment Cache
	if
		(weaponCache[itemID] and self.db.profile.options.reward.gear.weaponCache) or
		(armorCache[itemID] and self.db.profile.options.reward.gear.armorCache)
	then
		local complete, completionRetry = self:IsContainerCollectibleComplete(itemID)
		if complete then
			return false
		end
		retry = completionRetry or retry

		-- Enabling a cache category tracks the cache itself.
		-- Upgrade calculations below are only supplemental metadata.
		self:AddRewardToQuest(questID, RewardType.Item, { itemLink = itemLink }, isEmissary)
		local itemLevel = GetDetailedItemLevelInfo(itemLink)
		if not itemLevel then
			return true
		end
		local n = 0
		local upgrade
		local upgradeMax = 0
		local upgradeNum = 0

		if weaponCache[itemID] then
			for i = 16, 17 do
				if GetInventoryItemID("player", i) then
					local itemLink1 = GetInventoryItemLink("player", i)
					if itemLink1 then
						local itemLevel1 = GetDetailedItemLevelInfo(itemLink1)
						if itemLevel1 then
							n = n + 1
							upgrade = itemLevel - itemLevel1
							if upgrade >= self.db.profile.options.reward.gear.itemLevelUpgradeMin then
								upgradeNum = upgradeNum + 1
								if upgrade > upgradeMax then
									upgradeMax = upgrade
								end
							end
						else
							retry = true
						end
					else
						retry = true
					end
				end
			end
		end

		if armorCache[itemID] then
			for i = 1, 10 do
				if i == 4 then
					i = 15
				end
				if i ~= 2 then
					if GetInventoryItemID("player", i) then
						local itemLink1 = GetInventoryItemLink("player", i)
						if itemLink1 then
							local itemLevel1 = GetDetailedItemLevelInfo(itemLink1)
							if itemLevel1 then
								n = n + 1
								upgrade = itemLevel - itemLevel1
								if upgrade >= self.db.profile.options.reward.gear.itemLevelUpgradeMin then
									upgradeNum = upgradeNum + 1
									if upgrade > upgradeMax then
										upgradeMax = upgrade
									end
								end
							else
								retry = true
							end
						else
							retry = true
						end
					end
				end
			end
		end

		if upgradeNum > 0 then
			local item = {
				itemLink = itemLink,
				cache = { upgradeNum = upgradeNum, n = n, upgradeMax = upgradeMax }
			}
			self:AddRewardToQuest(questID, RewardType.Item, item, isEmissary)
		end
	end

	return retry
end

local function ClassifyTransmogReward(self, questID, isEmissary, itemLink, itemClassID)
	if
		(self.db.profile.options.reward.gear.unknownAppearance or self.db.profile.options.reward.gear.unknownSource)
		and self:IsTransmogable(itemLink)
		and (itemClassID == 2 or itemClassID == 4)
	then
		local transmog, retry = self:GetTrackedTransmogIcon(itemLink)
		if retry then
			return true
		end
		if transmog then
			local item = { itemLink = itemLink, transmog = transmog }
			self:AddRewardToQuest(questID, RewardType.Item, item, isEmissary)
		end
	end

	return false
end

local function ClassifyReputationItemReward(self, questID, isEmissary, itemID, itemLink)
	local factionID = ReputationItemList[itemID] or nil
	if factionID and self:ShouldTrackReputation(factionID) then
		local reputation = { itemLink = itemLink, factionID = factionID }
		self:AddRewardToQuest(questID, RewardType.Reputation, reputation, isEmissary)
	end
end

local function ClassifyRecipeReward(self, questID, isEmissary, itemLink, itemClassID, expacID)
	if itemClassID == 9 and self.db.profile.options.reward.recipe[expacID] == true then
		self:AddRewardToQuest(questID, RewardType.Recipe, itemLink, isEmissary)
	end
end

local function ClassifyKnownItemReward(self, questID, isEmissary, itemID, itemLink)
	if
		self.db.global.custom.worldQuestReward[itemID] == true
		and self.db.profile.custom.worldQuestReward[itemID] == true
	then
		self:AddRewardToQuest(questID, RewardType.CustomItem, itemLink, isEmissary)
	end

	if self.itemList[itemID] == true then
		local item = { itemLink = itemLink }
		self:AddRewardToQuest(questID, RewardType.Item, item, isEmissary)
	end
end

local function ClassifyLegacyGearReward(self, questID, isEmissary, itemLink)
	-- Azerite Traits
	if
		self.db.profile.options.reward.gear.azeriteTraits ~= ""
		and C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(itemLink)
	then
		for _, ring in pairs(C_AzeriteEmpoweredItem.GetAllTierInfoByItemID(itemLink)) do
			for _, azeritePowerID in pairs(ring.azeritePowerIDs) do
				local spellID = C_AzeriteEmpoweredItem.GetPowerInfo(azeritePowerID).spellID
				if self.azeriteTraitsList[spellID] then
					self:AddRewardToQuest(questID, RewardType.AzeriteTrait, spellID, isEmissary)
					self:AddRewardToQuest(questID, RewardType.Item, { itemLink = itemLink }, isEmissary)
				end
			end
		end
	end

	-- Conduit
	if self.db.profile.options.reward.gear.conduit and C_Soulbinds.IsItemConduitByItemInfo(itemLink) then
		self:AddRewardToQuest(questID, RewardType.Item, { itemLink = itemLink }, isEmissary)
	end
end

function WQA:CheckReward(questID, isEmissary, rewardIndex)
	local _, _, _, _, _, itemID = GetQuestLogRewardInfo(rewardIndex, questID)
	if not itemID then
		return true
	end

	inspectScantip:SetQuestLogItem("reward", rewardIndex, questID)
	local itemLink = select(2, inspectScantip:GetItem())
	if not itemLink or string.find(itemLink, "%[]") then
		return true
	end

	-- Some reward tooltips (notably profession recipes) contain a link to
	-- the item the recipe creates. Tooltip scanning can return that embedded
	-- link instead of the actual quest reward.
	--
	-- GetQuestLogRewardInfo() already gave us the authoritative reward itemID.
	-- Keep the richer scanned link when it refers to that same item (important
	-- for scaled/bonus gear), otherwise fall back to the actual reward link.
	local scannedItemID = C_Item.GetItemInfoInstant(itemLink)
	if scannedItemID ~= itemID then
		local _, rewardItemLink = C_Item.GetItemInfo(itemID)
		if not rewardItemLink then
			return true
		end
		itemLink = rewardItemLink
	end

	local _, _, _, _, _, _, _, _, itemEquipLoc, _, _, itemClassID = GetItemInfo(itemLink)
	local expacID = self:GetExpansionByQuestID(questID)
	local retry = false

	retry = ClassifyContainerReward(self, questID, isEmissary, itemID, itemLink) or retry
	retry = ClassifyGearUpgradeReward(self, questID, isEmissary, itemLink, itemEquipLoc) or retry
	retry = ClassifyEquipmentCacheReward(self, questID, isEmissary, itemID, itemLink) or retry
	retry = ClassifyTransmogReward(self, questID, isEmissary, itemLink, itemClassID) or retry
	ClassifyReputationItemReward(self, questID, isEmissary, itemID, itemLink)
	ClassifyRecipeReward(self, questID, isEmissary, itemLink, itemClassID, expacID)
	ClassifyKnownItemReward(self, questID, isEmissary, itemID, itemLink)
	ClassifyLegacyGearReward(self, questID, isEmissary, itemLink)

	return retry
end

function WQA:CheckCurrencies(questID, isEmissary)
	local questRewardCurrencies = C_QuestLog.GetQuestRewardCurrencies(questID)

	for _, currencyInfo in ipairs(questRewardCurrencies) do
		local currencyID = currencyInfo.currencyID
		local amount = currencyInfo.totalRewardAmount

		if self.db.profile.options.reward.currency[currencyID] then
			local currency = { currencyID = currencyID, amount = amount }
			self:AddRewardToQuest(questID, RewardType.Currency, currency, isEmissary)
		end

		-- Reputation Currency
		local factionID = ReputationCurrencyList[currencyID] or nil
		if factionID then
			if self:ShouldTrackReputation(factionID) then
				local reputation = {
					name = currencyInfo.name,
					currencyID = currencyID,
					amount = amount,
					factionID = factionID
				}
				self:AddRewardToQuest(questID, RewardType.Reputation, reputation, isEmissary)
			end
		end
	end

	local gold = math.floor(GetQuestLogRewardMoney(questID) / 10000) or 0
	if gold > 0 then
		if self.db.profile.options.reward.general.gold and gold >= self.db.profile.options.reward.general.goldMin then
			self:AddRewardToQuest(questID, RewardType.Gold, gold, isEmissary)
		end
	end
end

WQA.debug = false
function WQA:Debug(...)
	if self.debug == true then
		print(GetTime(), GetFramerate(), ...)
	end
end

function WQA:GetRewardTextByID(questID, key, value, i, type)
	local k, v = key, value
	local text
	if k == "custom" then
		text = "Custom"
	elseif k == "item" then
		text = self:GetRewardForID(questID, k, type)
	elseif k == "reputation" then
		if v.direct then
			local reputationText = self:GetRewardLinkByID(questID, k, v, i)
			if v.amount then
				text = v.amount .. " " .. reputationText
			else
				text = reputationText
			end
		elseif v.itemLink then
			text = self:GetRewardLinkByID(questID, k, v, i)
		else
			text = v.amount .. " " .. self:GetRewardLinkByID(questID, k, v, i)
		end
	elseif k == "currency" then
		text = v.amount .. " " .. GetCurrencyLink(v.currencyID, v.amount)
	elseif k == "professionSkillup" then
		text = v
	elseif k == "gold" then
		text = GOLD_AMOUNT_TEXTURE_STRING:format(v, 0, 0)
	else
		text = self:GetRewardLinkByID(questID, k, v, i)
	end
	return text
end

function WQA:GetRewardLinkByMissionID(missionID, key, value, i)
	return self:GetRewardLinkByID(missionID, key, value, i)
end

function WQA:GetRewardLinkByID(questID, key, value, i)
	local k, v = key, value
	local link = nil
	if k == "achievement" then
		if not v[i] then
			return nil
		end
		link = v[i].achievementLink or GetAchievementLink(v[i].id)
	elseif k == "chance" then
		if not v[i] then
			return nil
		end
		link = v[i].itemLink or select(2, GetItemInfo(v[i].id))
	elseif k == "custom" then
		return nil
	elseif k == "item" then
		link = v.itemLink
	elseif k == "reputation" then
		if v.direct then
			local factionData = C_Reputation.GetFactionDataByID(v.factionID)
			local factionName = v.name or (factionData and factionData.name) or tostring(v.factionID)
			link = v.reputationText or ("|cff00ff00[" .. factionName .. "]|r")
		elseif v.itemLink then
			link = v.itemLink
		else
			link = v.currencyLink or GetCurrencyLink(v.currencyID, v.amount)
		end
	elseif k == "recipe" then
		link = v
	elseif k == "customItem" then
		link = v
	elseif k == "currency" then
		link = v.currencyLink or GetCurrencyLink(v.currencyID, v.amount)
	elseif k == "professionSkillup" then
		return nil
	elseif k == "gold" then
		return nil
	elseif k == "azeriteTraits" then
		if not v[i] then
			return nil
		end
		link = GetSpellLink(v[i].spellID)
	elseif k == WQA.Rewards.RewardType.Miscellaneous then
		link = table.concat(v, ", ")
	end
	return link
end

function WQA:SetRewardLinkByMissionID(missionID, key, value, i, link)
	self:SetRewardLinkByID(missionID, key, value, i, link)
end

function WQA:SetRewardLinkByID(questID, key, value, i, link)
	local k, v = key, value
	if k == "achievement" then
		v[i].achievementLink = link
	elseif k == "chance" then
		v[i].itemLink = link
	elseif k == "reputation" then
		if v.direct then
			v.reputationText = link
		elseif not v.itemLink then
			v.currencyLink = link
		end
	elseif k == "currency" then
		v.currencyLink = link
	end
end

local function GetQuestName(questID)
	return C_TaskQuest.GetQuestInfoByQuestID(questID) or GetTitleForQuestID(questID) or
		select(3, string.find(GetQuestLink(questID) or "[unknown]", "%[(.+)%]"))
end

local function GetMissionName(missionID)
	return C_Garrison.GetMissionName(missionID)
end

local function GetTaskName(task)
	local name

	if task.type == TaskType.WorldQuest then
		name = GetQuestName(task.id)
	elseif task.type == TaskType.Mission then
		name = GetMissionName(task.id)
	elseif task.type == TaskType.AreaPoi then
		local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(task.mapId, task.id)
		name = poiInfo and poiInfo.name
	end

	return name or tostring(task.id or "")
end

local function SortByName(a, b)
	return GetTaskName(a) < GetTaskName(b)
end

function WQA:InsertionSort(A, compareFunction)
	for i, v in ipairs(A) do
		local j = i
		while j > 1 and compareFunction(A[j], A[j - 1]) do
			local temp = A[j]
			A[j] = A[j - 1]
			A[j - 1] = temp
			j = j - 1
		end
	end
	return A
end

function WQA:SortQuestList(list)
	if self.db.profile.options.sortByName == true then
		list = self:InsertionSort(list, SortByName)
	end

	if self.db.profile.options.sortByZoneName == true then
		list = self:InsertionSort(list, function(a, b) return self:SortByZoneName(a, b) end)
	end

	list = self:InsertionSort(list, function(a, b) return self:SortByExpansion(a, b) end)
	return list
end

local EMISSARY_MAP_IDS = { 627, 875 }
local EMISSARY_RETRY_INTERVAL_SECONDS = 1.5
local EMISSARY_MAX_PENDING_AGE_SECONDS = 30.0

local function CancelEmissaryRetry(state)
	if state and state.retryTimer and state.retryTimer.Cancel then
		state.retryTimer:Cancel()
	end

	if state then
		state.retryTimer = nil
	end
end

function WQA:EmissaryReward(state)
	if not state then
		CancelEmissaryRetry(self._wqaEmissaryScan)
		self._wqaEmissaryGeneration = (self._wqaEmissaryGeneration or 0) + 1
		state = {
			generation = self._wqaEmissaryGeneration,
			startedAt = GetTime(),
			retryTimer = nil
		}
		self._wqaEmissaryScan = state
		self._wqaEmissaryTimeout = nil
	elseif
		self._wqaEmissaryScan ~= state
		or self._wqaEmissaryGeneration ~= state.generation
	then
		return
	end

	self.emissaryRewards = false
	local retry = false
	local relevanceMayHaveChanged = false
	local pending = {}
	state.pending = pending

	for _, mapID in ipairs(EMISSARY_MAP_IDS) do
		local bounties = GetBountiesForMapID(mapID)
		if not bounties then
			pending["emissary-map:" .. tostring(mapID)] = true
			retry = true
		else
			for _, emissary in ipairs(bounties) do
				relevanceMayHaveChanged = true
				local questID = emissary.questID
				if self.db.profile.options.emissary[questID] == true then
					self:AddEmissaryReward(questID, RewardType.Custom, nil, true)
				end
				if HaveQuestData(questID) and HaveQuestRewardData(questID) then
					local itemsPending = self:CheckItems(questID, true)
					if itemsPending then pending["emissary:" .. tostring(questID)] = true end
					retry = itemsPending or retry
					self:CheckCurrencies(questID, true)
				else
					pending["emissary:" .. tostring(questID)] = true
					retry = true
				end
			end
		end
	end

	if retry and GetTime() - state.startedAt < EMISSARY_MAX_PENDING_AGE_SECONDS then
		if relevanceMayHaveChanged and self.ScheduleTaskResolverCheck then
			self:ScheduleTaskResolverCheck()
		end

		local timer
		timer = C_Timer.NewTimer(EMISSARY_RETRY_INTERVAL_SECONDS, function()
			if
				self._wqaEmissaryScan ~= state
				or self._wqaEmissaryGeneration ~= state.generation
				or state.retryTimer ~= timer
			then
				return
			end

			state.retryTimer = nil
			self:EmissaryReward(state)
		end)
		state.retryTimer = timer
		return
	end

	CancelEmissaryRetry(state)
	if retry then self._wqaEmissaryTimeout = pending end
	if self._wqaEmissaryScan == state then
		self._wqaEmissaryScan = nil
		self.emissaryRewards = true
		if self.ScheduleTaskResolverCheck then
			self:ScheduleTaskResolverCheck(true)
		end
	end
end

function WQA:EmissaryIsActive(questID)
	local emissary = {}
	for _, v in pairs(EmissaryQuestIDList) do
		for _, id in pairs(v) do
			if type(id) == "table" then
				id = id.id
			end
			if id == questID then
				emissary[id] = true
			end
		end
	end

	if emissary[questID] ~= true then
		return false
	end

	local i = 1
	while C_QuestLog.GetInfo(i) do
		local questLogQuestID = C_QuestLog.GetInfo(i).questID
		if questLogQuestID == questID then
			return true
		end
		i = i + 1
	end
	return false
end

function WQA:Special()
	if
		(self.db.profile.achievements[11189] ~= TrackingMode.Disabled and not select(4, GetAchievementInfo(11189)) == true) or
		(self.db.profile.achievements[13144] ~= TrackingMode.Disabled and not select(4, GetAchievementInfo(13144)) == true) or
		(self.db.profile.achievements[14758] ~= TrackingMode.Disabled and not select(4, GetAchievementInfo(14758)))
	then
		self.event:RegisterEvent("QUEST_TURNED_IN")
	end
end

local function PopUpIsShown()
	if WQA.PopUp then
		return WQA.PopUp.shown
	else
		return false
	end
end

local anchor
function dataobj:OnEnter()
	anchor = self

	-- Keep the minimap hover intentionally lightweight. The full World Quest
	-- list belongs to the persistent left-click popup; hover only documents the
	-- available mouse actions.
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine("WQA Turbo")
	GameTooltip:AddLine(L["MINIMAP_LEFT_CLICK"], 0.75, 0.75, 0.75)
	GameTooltip:AddLine(L["MINIMAP_RIGHT_CLICK"], 0.75, 0.75, 0.75)
	GameTooltip:AddLine(L["MINIMAP_SHIFT_LEFT_CLICK"], 0.75, 0.75, 0.75)
	GameTooltip:Show()
end

function dataobj:OnLeave()
	GameTooltip:Hide()
end

function dataobj:OnClick(button)
	GameTooltip:Hide()

	if button == "LeftButton" and IsShiftKeyDown() then
		-- Open the cached popup immediately, then start the silent full refresh.
		-- Because the popup is already open, the existing progressive refresh
		-- path rebuilds it as fresh scan results arrive.
		WQA:Show("popup")
		WQA:Refresh("settings", true)
	elseif button == "LeftButton" then
		WQA:Show("popup")
	elseif button == "RightButton" then
		if type(WQA.optionsCategoryID) == "number" then
			Settings.OpenToCategory(WQA.optionsCategoryID)
		else
			-- Defensive fallback if AceConfigDialog does not expose a
			-- numeric Blizzard Settings category ID for some reason.
			LibStub("AceConfigDialog-3.0"):Open("WQATurbo")
		end
	end
end

function WQA:AnnounceLDB(quests)
	-- Hide LDB tooltip while the persistent popup is open.
	if PopUpIsShown() then
		return
	end

	self:CreateQTip()

	-- Capture the exact tooltip instance owned by this hover. A delayed
	-- auto-hide callback must not release a tooltip that Turbo created later.
	local tooltip = self.tooltip
	if not tooltip then
		return
	end

	tooltip:SetAutoHideDelay(
		.25,
		anchor,
		function()
			-- Ignore stale callbacks. The global reference may now belong to
			-- another popup/hover tooltip, or may already have been cleared.
			if PopUpIsShown() or WQA.tooltip ~= tooltip then
				return
			end

			WQA:ReleaseQTip(tooltip)
		end
	)

	tooltip:SmartAnchorTo(anchor)
	-- Minimap click hints. Keep these on the transient LDB tooltip only;
	-- the persistent /wqat popup does not need minimap-button instructions.
	local leftClickLine = tooltip:AddLine()
	tooltip:SetCell(
		leftClickLine,
		1,
		"|cffaaaaaa" .. L["MINIMAP_LEFT_CLICK"] .. "|r",
		nil,
		"LEFT",
		tooltip:GetColumnCount()
	)

	local rightClickLine = tooltip:AddLine()
	tooltip:SetCell(
		rightClickLine,
		1,
		"|cffaaaaaa" .. L["MINIMAP_RIGHT_CLICK"] .. "|r",
		nil,
		"LEFT",
		tooltip:GetColumnCount()
	)
	tooltip:AddSeparator()
	self:UpdateQTip(quests)
	self:ApplyQTipScrolling(tooltip)
end
function WQA:UpdateLDBText(activeTasks, newTasks)
	if newTasks ~= nil then
		dataobj.text = "New World Quests active"
	elseif activeTasks ~= nil then
		dataobj.text = "World Quests active"
	else
		dataobj.text = "No World Quests active"
	end
end

function WQA:formatTime(t)
	local t = math.floor(t or 0)
	local d, h, m, timeString
	d = math.floor(t / 60 / 24)
	h = math.floor(t / 60 % 24)
	m = t % 60
	if d > 0 then
		if h > 0 then
			timeString = string.format("%dd %dh", d, h)
		else
			timeString = string.format("%dd", d)
		end
	elseif h > 0 then
		if m > 0 then
			timeString = string.format("%dh %dm", h, m)
		else
			timeString = string.format("%dh", h)
		end
	else
		timeString = string.format("%dm", m)
	end

	if t > 0 then
		if t <= 180 then
			if t <= 30 then
				timeString = string.format("|cffff3333%s|r", timeString)
			else
				timeString = string.format("|cffffff00%s|r", timeString)
			end
		end
	end

	return timeString
end

local LE_GARRISON_TYPE = {
	[6] = Enum.GarrisonType.Type_6_0_Garrison,
	[7] = Enum.GarrisonType.Type_7_0_Garrison,
	[8] = Enum.GarrisonType.Type_8_0_Garrison,
	[9] = Enum.GarrisonType.Type_9_0_Garrison
}

function WQA:CheckMissions()
	local activeMissions = {}
	local retry = false
	local pending = {}
	self._wqaMissionPending = pending
	for i in pairs(WQA.ExpansionList) do
		local type = LE_GARRISON_TYPE[i]
		if type and C_Garrison.HasGarrison(type) then
			local followerType = GetPrimaryGarrisonFollowerType(type)
			local missions = C_Garrison.GetAvailableMissions(followerType)
			if not missions then
				pending["mission-list:" .. tostring(followerType)] = true
				retry = true
				missions = {}
			end

			-- Add Shipyard Missions
			if i == 6 and C_Garrison.HasShipyard() then
				local shipyardMissions = C_Garrison.GetAvailableMissions(Enum.GarrisonFollowerType.FollowerType_6_0_Boat)
				if shipyardMissions then
					for _, mission in ipairs(shipyardMissions) do
						mission.followerType = Enum.GarrisonFollowerType.FollowerType_6_0_Boat
						missions[#missions + 1] = mission
					end
				else
					pending["mission-list:" .. tostring(Enum.GarrisonFollowerType.FollowerType_6_0_Boat)] = true
					retry = true
				end
			end

			if #missions > 0 then
				for _, mission in ipairs(missions) do
					local missionID = mission.missionID
					local addMission = false
					if self.missionList[missionID] then
						addMission = true
					end
					for _, reward in ipairs(mission.rewards or {}) do
						if reward.currencyID then
							if reward.currencyID ~= 0 then
								local currencyID = reward.currencyID
								local amount = reward.quantity
								if self.db.profile.options.missionTable.reward.currency[currencyID] then
									local currency = { currencyID = currencyID, amount = amount }
									self:AddRewardToMission(missionID, RewardType.Currency, currency)
									addMission = true
								else
									local factionID = ReputationCurrencyList[currencyID] or nil
									if factionID then
										if self:ShouldTrackReputation(factionID, true) then
											local reputation = {
												currencyID = currencyID,
												amount = amount,
												factionID = factionID
											}
											self:AddRewardToMission(missionID, RewardType.Reputation, reputation)
											addMission = true
										end
									end
								end
							else
								local gold = math.floor(reward.quantity / 10000)
								if
									self.db.profile.options.missionTable.reward.gold and
									gold >= self.db.profile.options.missionTable.reward.goldMin
								then
									self:AddRewardToMission(missionID, RewardType.Gold, gold)
									addMission = true
								end
							end
						end

						if reward.itemID then
							local itemID = reward.itemID
							local itemName,
							itemLink,
							itemRarity,
							itemLevel,
							itemMinLevel,
							itemType,
							itemSubType,
							itemStackCount,
							itemEquipLoc,
							itemTexture,
							itemSellPrice,
							itemClassID,
							itemSubClassID = GetItemInfo(itemID)

							if not itemLink then
								pending["mission:" .. tostring(missionID) .. "@item:" .. tostring(itemID)] = true
								retry = true
							else
								-- Custom Mission Reward
								if self.db.global.custom.missionReward[itemID] and self.db.profile.custom.missionReward[itemID] then
									local item = { itemLink = itemLink }
									self:AddRewardToMission(missionID, RewardType.Item, item)
									addMission = true
								end

								-- Reputation Token
								local factionID = ReputationItemList[itemID] or nil
								if factionID then
									if self:ShouldTrackReputation(factionID, true) then
										local reputation = { itemLink = itemLink, factionID = factionID }
										self:AddRewardToMission(missionID, RewardType.Reputation, reputation)
										addMission = true
									end
								end

								-- Transmog
								if
									(self.db.profile.options.reward.gear.unknownAppearance or self.db.profile.options.reward.gear.unknownSource)
									and self:IsTransmogable(itemLink)
								then
									if itemClassID == 2 or itemClassID == 4 then
										local transmog, transmogRetry = self:GetTrackedTransmogIcon(itemLink)
										if transmogRetry then
											pending["mission:" .. tostring(missionID) .. "@item:" .. tostring(itemID)] = true
											retry = true
										elseif transmog then
											local item = { itemLink = itemLink, transmog = transmog }
											self:AddRewardToMission(missionID, RewardType.Item, item)
											addMission = true
										end
									end
								end
								-- Conduit
								if self.db.profile.options.reward.gear.conduit and C_Soulbinds.IsItemConduitByItemInfo(itemLink) then
									self:AddRewardToMission(missionID, RewardType.Item, { itemLink = itemLink })
									addMission = true
								end
							end
						end
						if addMission == true then
							self.missionList[missionID].offerEndTime = mission.offerEndTime or nil
							self.missionList[missionID].offerTimeRemaining = mission.offerTimeRemaining or nil
							self.missionList[missionID].expansion = i
							self.missionList[missionID].followerType = mission.followerType or followerType
							activeMissions[missionID] = true
						end
					end
				end
			end
		end
	end

	return activeMissions, retry
end

-- One map query per readiness pass, rather than per candidate quest.
function WQA:RefreshQuestPins(requestPending)
	local active, pending = {}, {}
	local now = GetTime()
	self._wqaQuestPinRequests = self._wqaQuestPinRequests or {}
	local requests = self._wqaQuestPinRequests
	for mapID in pairs(self.questPinMapList or {}) do
		local pins = C_QuestLine.GetAvailableQuestLines(mapID)
		if type(pins) ~= "table" then
			pending["quest-pin-map:" .. tostring(mapID)] = true
			if requestPending ~= false and (not requests[mapID] or now - requests[mapID] >= 1.5) then
				requests[mapID] = now
				C_QuestLine.RequestQuestLinesForMap(mapID)
			end
		else
			for _, pin in pairs(pins) do
				if pin.questID then active[pin.questID] = true end
			end
		end
	end
	self._wqaQuestPinsActive = active
	return pending
end

function WQA:isQuestPinActive(questID)
	if not self._wqaQuestPinsActive then self:RefreshQuestPins() end
	return self._wqaQuestPinsActive[questID] == true
end

function WQA:IsQuestFlaggedCompleted(questID)
	if self.questFlagList[questID] then
		return not IsQuestFlaggedCompleted(questID)
	else
		return false
	end
end

function WQA:UpdateMinimapIcon()
	if self.db.profile.options.LibDBIcon.hide then
		icon:Hide("WQATurbo")
	else
		icon:Show("WQATurbo")
	end
end

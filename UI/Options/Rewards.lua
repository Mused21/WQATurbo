local WQA = WQATurbo
local L = WQA.L
local newOrder = WQA.OptionsUI.NewOrder
local GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local GetTitleForQuestID = C_QuestLog.GetTitleForQuestID
local RuntimeData = WQA.RuntimeData
local CurrencyIDList = RuntimeData.CurrencyIDsByExpansion
local worldQuestType = RuntimeData.WorldQuestTypesByLabel
local EmissaryQuestIDList = RuntimeData.EmissaryQuestIDsByExpansion
local FactionIDList = RuntimeData.FactionIDsByExpansion
local GetSortedExpansionIDs = WQA.OptionsUI.GetSortedExpansionIDs

local function CreateHideMaxedReputationsOption()
	return {
		order = 1,
		type = "toggle",
		name = L["Hide Exalted / max Renown reputations"],
		desc = L["Hide finished reputations from these lists and ignore them when matching reputation rewards. This includes classic Exalted reputations and Major Factions at maximum Renown."],
		width = "full",
		get = function()
			return WQA.db.profile.options.hideExaltedReputations
		end,
		set = function(_, value)
			WQA.db.profile.options.hideExaltedReputations = value
			LibStub("AceConfigRegistry-3.0"):NotifyChange("WQATurbo")
			WQA:ScheduleOptionsRefresh()
		end
	}
end

function WQA:CreateRewardOptions()
	return {
		order = newOrder(),
		type = "group",
		childGroups = "tree",
		name = L["Rewards"],
		args = {
			general = {
				order = newOrder(),
				name = L["General"],
				type = "group",
				-- inline = true,
				args = {
					gold = {
						type = "toggle",
						name = L["Gold"],
						set = function(info, val)
							WQA.db.profile.options.reward.general.gold = val
							WQA:ScheduleOptionsRefresh()
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.reward.general.gold
						end,
						order = newOrder()
					},
					goldMin = {
						name = L["minimum Gold"],
						type = "input",
						order = newOrder(),
						set = function(info, val)
							WQA.db.profile.options.reward.general.goldMin = tonumber(val)
							WQA:ScheduleOptionsRefresh()
						end,
						get = function()
							return tostring(WQA.db.profile.options.reward.general.goldMin)
						end
					}
				}
			},
			gear = {
				order = newOrder(),
				name = L["Gear"],
				type = "group",
				-- inline = true,
				args = {
					itemLevelUpgrade = {
						type = "toggle",
						name = L["ItemLevel Upgrade"],
						set = function(info, val)
							WQA.db.profile.options.reward.gear.itemLevelUpgrade = val
							WQA:ScheduleOptionsRefresh()
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.reward.gear.itemLevelUpgrade
						end,
						order = newOrder()
					},
					AzeriteArmorCache = {
						type = "toggle",
						name = L["Azerite Armor Cache"],
						set = function(info, val)
							WQA.db.profile.options.reward.gear.AzeriteArmorCache = val
							WQA:ScheduleOptionsRefresh()
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.reward.gear.AzeriteArmorCache
						end,
						order = newOrder()
					},
					AzeriteArmorCacheCharacter = {
						type = "toggle",
						name = L["Azerite Armor Cache on this character"],
						desc = L["Keep the profile-wide cache setting enabled, then disable this on characters whose armor appearances are complete."],
						width = "full",
						set = function(info, val)
							WQA.db.char.options.reward.gear.AzeriteArmorCache = val
							WQA:ScheduleOptionsRefresh()
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.char.options.reward.gear.AzeriteArmorCache
						end,
						disabled = function()
							return not WQA.db.profile.options.reward.gear.AzeriteArmorCache
						end,
						order = function()
							return WQA.options.args.reward.args.gear.args.AzeriteArmorCache.order + 0.1
						end
					},
					itemLevelUpgradeMin = {
						name = L["minimum ItemLevel Upgrade"],
						type = "input",
						order = newOrder(),
						set = function(info, val)
							WQA.db.profile.options.reward.gear.itemLevelUpgradeMin = tonumber(val)
							WQA:ScheduleOptionsRefresh()
						end,
						get = function()
							return tostring(WQA.db.profile.options.reward.gear.itemLevelUpgradeMin)
						end
					},
					armorCache = {
						type = "toggle",
						name = L["Armor Cache"],
						set = function(info, val)
							WQA.db.profile.options.reward.gear.armorCache = val
							WQA:ScheduleOptionsRefresh()
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.reward.gear.armorCache
						end,
						order = newOrder()
					},
					weaponCache = {
						type = "toggle",
						name = L["Weapon Cache"],
						set = function(info, val)
							WQA.db.profile.options.reward.gear.weaponCache = val
							WQA:ScheduleOptionsRefresh()
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.reward.gear.weaponCache
						end,
						order = newOrder()
					},
					desc1 = {
						type = "description",
						fontSize = "small",
						name = " ",
						order = newOrder()
					},
					PawnUpgrade = {
						type = "toggle",
						name = L["% Upgrade (Pawn)"],
						set = function(info, val)
							WQA.db.profile.options.reward.gear.PawnUpgrade = val
							WQA:ScheduleOptionsRefresh()
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.reward.gear.PawnUpgrade
						end,
						order = newOrder()
					},
					StatWeightScore = {
						type = "toggle",
						name = L["% Upgrade (Stat Weight Score)"],
						set = function(info, val)
							WQA.db.profile.options.reward.gear.StatWeightScore = val
							WQA:ScheduleOptionsRefresh()
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.reward.gear.StatWeightScore
						end,
						order = newOrder()
					},
					PercentUpgradeMin = {
						name = L["minimum % Upgrade"],
						type = "input",
						order = newOrder(),
						set = function(info, val)
							WQA.db.profile.options.reward.gear.PercentUpgradeMin = tonumber(val)
							WQA:ScheduleOptionsRefresh()
						end,
						get = function()
							return tostring(WQA.db.profile.options.reward.gear.PercentUpgradeMin)
						end
					},
					desc2 = {
						type = "description",
						fontSize = "small",
						name = " ",
						order = newOrder()
					},
					unknownAppearance = {
						type = "toggle",
						name = L["Unknown appearance"],
						set = function(info, val)
							WQA.db.profile.options.reward.gear.unknownAppearance = val
							WQA:ScheduleOptionsRefresh()
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.reward.gear.unknownAppearance
						end,
						order = newOrder()
					},
					unknownSource = {
						type = "toggle",
						name = L["Unknown source"],
						set = function(info, val)
							WQA.db.profile.options.reward.gear.unknownSource = val
							WQA:ScheduleOptionsRefresh()
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.reward.gear.unknownSource
						end,
						order = newOrder()
					},
					azeriteTraits = {
						name = L["Azerite Traits"],
						desc = L["Comma separated spellIDs"],
						type = "input",
						order = newOrder(),
						set = function(info, val)
							WQA.db.profile.options.reward.gear.azeriteTraits = val
							WQA:ScheduleOptionsRefresh()
						end,
						get = function()
							return WQA.db.profile.options.reward.gear.azeriteTraits
						end
					},
					conduit = {
						name = L["Conduit"],
						desc = L["Track conduit"],
						type = "toggle",
						order = newOrder(),
						set = function(info, val)
							WQA.db.profile.options.reward.gear.conduit = val
							WQA:ScheduleOptionsRefresh()
						end,
						get = function()
							return WQA.db.profile.options.reward.gear.conduit
						end
					}
				}
			}
		}
	}
end

function WQA:PopulateWorldQuestTypeOptions()
	-- Rewards / General / World Quest Types
	local args = self.options.args.reward.args.general.args
	args.worldQuestTypes = {
		type = "group",
		name = L["World Quest Type"],
		order = 20,
		args = {}
	}
	local worldQuestTypeArgs = args.worldQuestTypes.args
	for k, v in pairs(worldQuestType) do
		local optionKey = k
		local worldQuestTypeID = v

		worldQuestTypeArgs[optionKey] = {
			type = "toggle",
			name = L[optionKey],
			set = function(info, val)
				WQA.db.profile.options.reward.general.worldQuestType[worldQuestTypeID] = val
				WQA:ScheduleOptionsRefresh()
			end,
			descStyle = "inline",
			get = function()
				return WQA.db.profile.options.reward.general.worldQuestType[worldQuestTypeID] or false
			end,
			order = newOrder()
		}
	end

end

function WQA:PopulateRewardOptions()
	local rewardExpansionOrder = 100
	for _, i in ipairs(GetSortedExpansionIDs(self.ExpansionList, 6, 12)) do
		local expansionName = self.ExpansionList[i]
		if expansionName then
			self.options.args.reward.args[expansionName] = {
				order = rewardExpansionOrder,
				name = expansionName,
				type = "group",
				childGroups = "tree",
				args = {}
			}
			rewardExpansionOrder = rewardExpansionOrder + 1

			-- World Quests
			if i > 6 then
				local worldQuestGroup = {
					order = 10,
					name = L["World Quests"],
					type = "group",
					childGroups = "tree",
					args = {}
				}
				self.options.args.reward.args[expansionName].args[expansionName .. "WorldQuests"] = worldQuestGroup
				local rewardArgs = worldQuestGroup.args

				-- Zones
				if WQA.ZoneIDList[i] then
					rewardArgs.zone = {
						order = 10,
						name = L["Zones"],
						type = "group",
						args = {}
					}
					for _, zoneID in pairs(WQA.ZoneIDList[i]) do
						local mapInfo = C_Map.GetMapInfo(zoneID)
						local zoneName = mapInfo and mapInfo.name or tostring(zoneID)
						local capturedZoneID = zoneID
						rewardArgs.zone.args[zoneName .. tostring(capturedZoneID)] = {
							type = "toggle",
							name = zoneName,
							set = function(_, value)
								WQA.db.profile.options.zone[capturedZoneID] = value
								WQA:ScheduleOptionsRefresh()
							end,
							descStyle = "inline",
							get = function()
								return WQA.db.profile.options.zone[capturedZoneID] or false
							end,
							order = newOrder()
						}
					end
				end

				-- Currencies
				if CurrencyIDList[i] then
					rewardArgs.currency = {
						order = 20,
						name = L["Currencies"],
						type = "group",
						args = {}
					}
					for _, currencyEntry in ipairs(CurrencyIDList[i]) do
						if not (type(currencyEntry) == "table" and currencyEntry.faction ~= self.faction) then
							local currencyID = type(currencyEntry) == "table" and currencyEntry.id or currencyEntry
							local currencyInfo = currencyID and GetCurrencyInfo(currencyID)
							if currencyInfo and currencyInfo.name then
								local capturedCurrencyID = currencyID
								rewardArgs.currency.args[currencyInfo.name .. tostring(capturedCurrencyID)] = {
									type = "toggle",
									name = currencyInfo.name,
									set = function(_, value)
										WQA.db.profile.options.reward.currency[capturedCurrencyID] = value
										WQA:ScheduleOptionsRefresh()
									end,
									descStyle = "inline",
									get = function()
										return WQA.db.profile.options.reward.currency[capturedCurrencyID]
									end,
									order = newOrder()
								}
							end
						end
					end
				end

				-- Reputation
				if FactionIDList[i] then
					rewardArgs.reputation = {
						order = 30,
						name = L["Reputation"],
						desc = L["Track World Quests that award reputation with the selected factions."],
						type = "group",
						args = {
							hideMaxed = CreateHideMaxedReputationsOption()
						}
					}
					for _, factionGroup in ipairs({ "Neutral", UnitFactionGroup("player") }) do
						if FactionIDList[i][factionGroup] then
							for _, factionID in ipairs(FactionIDList[i][factionGroup]) do
								local factionData = C_Reputation.GetFactionDataByID(factionID)
								if factionData and factionData.name then
									local capturedFactionID = factionID
									rewardArgs.reputation.args[factionData.name .. tostring(capturedFactionID)] = {
										type = "toggle",
										name = factionData.name,
										set = function(_, value)
											WQA.db.profile.options.reward.reputation[capturedFactionID] = value
											WQA:ScheduleOptionsRefresh()
										end,
										descStyle = "inline",
										get = function()
											return WQA.db.profile.options.reward.reputation[capturedFactionID]
										end,
										hidden = function()
											return WQA.db.profile.options.hideExaltedReputations
												and WQA:IsReputationMaxed(capturedFactionID)
										end,
										order = newOrder()
									}
								end
							end
						end
					end
				end

				-- Dragonflight racing reward containers
				if i == 10 then
					rewardArgs.containers = {
						order = 35,
						name = L["Containers"],
						type = "group",
						args = {
							racingRewardContainers = {
								type = "toggle",
								name = L["Racing reward containers"],
								desc = L["Track Dragonflight racing World Quests that reward Dragon Racer's Purse, Reach Racer's Purse, Cavern Racer's Purse, or Dream Racer's Purse. A purse is hidden after all of its possible Drakewatcher's Manuscripts are collected."],
								width = "full",
								get = function()
									return WQA.db.profile.options.reward[10].racingRewardContainers
								end,
								set = function(_, value)
									WQA.db.profile.options.reward[10].racingRewardContainers = value
									WQA:ScheduleOptionsRefresh()
								end,
								order = 1
							}
						}
					}
				end

				-- This blanket toggle uses Blizzard's live covenant-specific IDs.
				if i == 9 then
					rewardArgs.callings = {
						order = 35,
						type = "toggle",
						name = L["Track Shadowlands Callings"],
						desc = L["Track available Callings for the selected covenants without entering quest IDs."],
						width = "full",
						set = function(_, value)
							WQA.db.profile.options.trackShadowlandsCallings = value
							if not value then WQA:ClearCallings() end
							WQA:ScheduleOptionsRefresh()
						end,
						get = function()
							return WQA.db.profile.options.trackShadowlandsCallings
						end
					}

					for order, covenantID in ipairs(WQA.ShadowlandsCallingData.CovenantIDs) do
						local capturedCovenantID = covenantID
						local covenantData = C_Covenants and C_Covenants.GetCovenantData
							and C_Covenants.GetCovenantData(capturedCovenantID)
						rewardArgs["callingCovenant" .. capturedCovenantID] = {
							order = 35 + order / 10,
							type = "toggle",
							name = covenantData and covenantData.name or tostring(capturedCovenantID),
							width = "full",
							disabled = function()
								return WQA.db.profile.options.trackShadowlandsCallings ~= true
							end,
							set = function(_, value)
								WQA.db.profile.options.shadowlandsCallingsByCovenant[capturedCovenantID] = value
								WQA:ScheduleOptionsRefresh()
							end,
							get = function()
								return WQA.db.profile.options.shadowlandsCallingsByCovenant[capturedCovenantID] == true
							end,
						}
					end
				end

				-- Emissary
				if EmissaryQuestIDList[i] then
					rewardArgs.emissary = {
						order = 40,
						name = L["Emissary Quests"],
						type = "group",
						args = {}
					}
					for _, questEntry in ipairs(EmissaryQuestIDList[i]) do
						if not (type(questEntry) == "table" and questEntry.faction ~= self.faction) then
							local questID = type(questEntry) == "table" and questEntry.id or questEntry
							local capturedQuestID = questID
							local questName = GetTitleForQuestID(capturedQuestID) or tostring(capturedQuestID)
							rewardArgs.emissary.args[questName .. tostring(capturedQuestID)] = {
								type = "toggle",
								name = questName,
								set = function(_, value)
									WQA.db.profile.options.emissary[capturedQuestID] = value
									WQA:ScheduleOptionsRefresh()
								end,
								descStyle = "inline",
								get = function()
									return WQA.db.profile.options.emissary[capturedQuestID]
								end,
								order = newOrder()
							}
						end
					end
				end

				-- Professions
				rewardArgs.profession = {
					order = 50,
					name = L["Professions"],
					type = "group",
					args = {}
				}

				rewardArgs.profession.args.Recipes = {
					type = "toggle",
					name = L["Recipes"],
					set = function(_, value)
						WQA.db.profile.options.reward.recipe[i] = value
						WQA:ScheduleOptionsRefresh()
					end,
					descStyle = "inline",
					get = function()
						return WQA.db.profile.options.reward.recipe[i]
					end,
					order = 1
				}

				for _, tradeskillLineIndex in pairs({ GetProfessions() }) do
				local professionName, _, _, _, _, _, tradeskillLineID = GetProfessionInfo(tradeskillLineIndex)
				if tradeskillLineID then
					local capturedTradeskillLineID = tradeskillLineID
					rewardArgs.profession.args[capturedTradeskillLineID .. "Header"] = {
							type = "header",
							name = professionName,
							order = newOrder()
						}
						rewardArgs.profession.args[capturedTradeskillLineID .. "Skillup"] = {
							type = "toggle",
							name = L["Skillup"],
							desc = L["Track every World Quest until skill level is maxed out"],
							set = function(_, value)
								WQA.db.profile.options.reward[i].profession[capturedTradeskillLineID].skillup = value
								WQA:ScheduleOptionsRefresh()
							end,
							get = function()
								return WQA.db.profile.options.reward[i].profession[capturedTradeskillLineID].skillup
							end,
							order = newOrder()
						}
						rewardArgs.profession.args[capturedTradeskillLineID .. "MaxLevel"] = {
							type = "toggle",
							name = L["Skill level is maxed out*"],
							desc = L["Setting is per character"],
							set = function(_, value)
								WQA.db.char[i].profession[capturedTradeskillLineID].isMaxLevel = value
								WQA:ScheduleOptionsRefresh()
							end,
							get = function()
								return WQA.db.char[i].profession[capturedTradeskillLineID].isMaxLevel
							end,
							order = newOrder()
						}
					end
				end
			end

			-- Mission Tables only existed for WoD through Shadowlands.
			if i >= 6 and i <= 9 then
				local missionGroup = {
					order = 20,
					name = (i ~= 6 and L["Mission Table"] or L["Mission Table & Shipyard"]),
					type = "group",
					childGroups = "tree",
					args = {}
				}
				self.options.args.reward.args[expansionName].args[expansionName .. "MissionTable"] = missionGroup
				local missionArgs = missionGroup.args

				if CurrencyIDList[i] then
					missionArgs.currency = {
						order = 10,
						name = L["Currencies"],
						type = "group",
						args = {}
					}

					if i == 8 then
						missionArgs.currency.args.gold = {
							type = "toggle",
							name = L["Gold"],
							set = function(_, value)
								WQA.db.profile.options.missionTable.reward.gold = value
								WQA:ScheduleOptionsRefresh()
							end,
							descStyle = "inline",
							get = function()
								return WQA.db.profile.options.missionTable.reward.gold
							end,
							order = 1
						}
						missionArgs.currency.args.goldMin = {
							name = L["minimum Gold"],
							type = "input",
							order = 2,
							set = function(_, value)
								WQA.db.profile.options.missionTable.reward.goldMin = tonumber(value)
								WQA:ScheduleOptionsRefresh()
							end,
							get = function()
								return tostring(WQA.db.profile.options.missionTable.reward.goldMin)
							end
						}
					end

					for _, currencyEntry in ipairs(CurrencyIDList[i]) do
						if not (type(currencyEntry) == "table" and currencyEntry.faction ~= self.faction) then
							local currencyID = type(currencyEntry) == "table" and currencyEntry.id or currencyEntry
							local currencyInfo = currencyID and GetCurrencyInfo(currencyID)
							if currencyInfo and currencyInfo.name then
								local capturedCurrencyID = currencyID
								missionArgs.currency.args[currencyInfo.name .. tostring(capturedCurrencyID)] = {
									type = "toggle",
									name = currencyInfo.name,
									set = function(_, value)
										WQA.db.profile.options.missionTable.reward.currency[capturedCurrencyID] = value
										WQA:ScheduleOptionsRefresh()
									end,
									descStyle = "inline",
									get = function()
										return WQA.db.profile.options.missionTable.reward.currency[capturedCurrencyID]
									end,
									order = newOrder()
								}
							end
						end
					end
				end

				if FactionIDList[i] then
					missionArgs.reputation = {
						order = 20,
						name = L["Reputation"],
						type = "group",
						args = {
							hideMaxed = CreateHideMaxedReputationsOption()
						}
					}
					for _, factionGroup in ipairs({ "Neutral", UnitFactionGroup("player") }) do
						if FactionIDList[i][factionGroup] then
							for _, factionID in ipairs(FactionIDList[i][factionGroup]) do
								local factionData = C_Reputation.GetFactionDataByID(factionID)
								if factionData and factionData.name then
									local capturedFactionID = factionID
									missionArgs.reputation.args[factionData.name .. tostring(capturedFactionID)] = {
										type = "toggle",
										name = factionData.name,
										set = function(_, value)
											WQA.db.profile.options.missionTable.reward.reputation[capturedFactionID] = value
											WQA:ScheduleOptionsRefresh()
										end,
										descStyle = "inline",
										get = function()
											return WQA.db.profile.options.missionTable.reward.reputation[capturedFactionID]
										end,
										hidden = function()
											return WQA.db.profile.options.hideExaltedReputations
												and WQA:IsReputationMaxed(capturedFactionID)
										end,
										order = newOrder()
									}
								end
							end
						end
					end
				end
			end
		end
	end
end

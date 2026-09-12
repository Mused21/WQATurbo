local WQA = WQATurbo
local TrackingMode = WQA.Constants.TrackingMode
local TrackingPolicy = WQA.TrackingPolicy
local CriteriaType = WQA.Constants.CriteriaType
local TaskType = WQA.Constants.TaskType
local L = WQA.L

-- Blizzard
local GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local GetTitleForQuestID = C_QuestLog.GetTitleForQuestID

local optionsTimer
local optionsRefreshTimer

local RuntimeData = WQA.RuntimeData
local CurrencyIDList = RuntimeData.CurrencyIDsByExpansion
local worldQuestType = RuntimeData.WorldQuestTypesByLabel
local EmissaryQuestIDList = RuntimeData.EmissaryQuestIDsByExpansion
local FactionIDList = RuntimeData.FactionIDsByExpansion

local newOrder
do
	local current = 0
	function newOrder()
		current = current + 1
		return current
	end
end

local TRACKING_GROUPS = { "achievements", "mounts", "pets", "toys" }
local TRACKING_GROUP_ORDER = {
	achievements = 10,
	mounts = 20,
	pets = 30,
	toys = 40
}

local BULK_TRACKING_VALUES = {
	mixed = "Mixed / choose setting",
	[TrackingMode.Disabled] = L["tracking_disabled"],
	[TrackingMode.Default] = L["tracking_default"],
	[TrackingMode.Always] = L["tracking_always"]
}

local function GetSortedExpansionIDs(expansionList, minID, maxID)
	local ids = {}
	for id, name in pairs(expansionList or {}) do
		if type(id) == "number" and name and (not minID or id >= minID) and (not maxID or id <= maxID) then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		return a > b
	end)
	return ids
end

function WQA:UpdateOptions()
	------------------
	-- 	Options Table
	------------------
	self.options = {
		type = "group",
		childGroups = "tab",
		args = {
			general = {
				order = newOrder(),
				type = "group",
				childGroups = "tree",
				name = "Tracking",
				args = {}
			},
			reward = {
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
							jewelryCache = {
								type = "toggle",
								name = L["Jewelry Cache"],
								set = function(info, val)
									WQA.db.profile.options.reward.gear.jewelryCache = val
									WQA:ScheduleOptionsRefresh()
								end,
								descStyle = "inline",
								get = function()
									return WQA.db.profile.options.reward.gear.jewelryCache
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
			},
			custom = {
				order = newOrder(),
				type = "group",
				childGroups = "tree",
				name = L["Custom"],
				args = {
					quest = {
						order = newOrder(),
						name = L["World Quest"],
						type = "group",
						inline = true,
						args = {
							-- Add WQ
							header1 = {
								type = "header",
								name = L["Add a Quest you want to track"],
								order = newOrder()
							},
							addWQ = {
								name = L["QuestID"],
								-- desc = "To add a worldquest, enter a unique name for the worldquest, and click Okay",
								type = "input",
								order = newOrder(),
								width = .6,
								set = function(info, val)
									WQA.data.custom.wqID = val
								end,
								get = function()
									return tostring(WQA.data.custom.wqID)
								end
							},
							questType = {
								name = L["Quest type"],
								order = newOrder(),
								desc =
								L["IsActive:\nUse this as a last resort. Works for some daily quests.\n\nIsQuestFlaggedCompleted:\nUse this for quests, that are always active.\n\nQuest Pin:\nUse this, if the daily is marked with a quest pin on the world map.\n\nWorld Quest:\nUse this, if you want to track a world quest."],
								type = "select",
								values = {
									[TaskType.WorldQuest] = L["World Quest"],
									[CriteriaType.QuestPin] = L["Quest Pin"],
									[CriteriaType.QuestFlag] = L["IsQuestFlaggedCompleted"],
									IsActive = L["IsActive"]
								},
								set = function(info, val)
									WQA.data.custom.questType = val
								end,
								get = function()
									return WQA.data.custom.questType
								end
							},
							mapID = {
								name = L["mapID"],
								desc =
								L["Quest pin tracking needs a mapID.\nSee https://wow.gamepedia.com/UiMapID for help."],
								type = "input",
								width = .5,
								order = newOrder(),
								set = function(info, val)
									WQA.data.custom.mapID = val
								end,
								get = function()
									return tostring(WQA.data.custom.mapID or "")
								end
							},
							--[[
							rewardID = {
							name = L["Reward (optional)"],
							desc = "Enter an achievementID or itemID",
							type = "input",
							width = .6,
							order = newOrder(),
							set = function(info,val)
							WQA.data.custom.rewardID = val
							end,
							get = function() return tostring(WQA.data.custom.rewardID )  end
							},
							rewardType = {
							name = L["Reward type"],
							order = newOrder(),
							type = "select",
							values = {item = "Item", achievement = "Achievement", none = "none"},
							width = .6,
							set = function(info,val)
							WQA.data.custom.rewardType = val
							end,
							get = function() return WQA.data.custom.rewardType end
							},--]]
							button = {
								order = newOrder(),
								type = "execute",
								name = L["Add"],
								width = .3,
								func = function()
									WQA:CreateCustomQuest()
								end,
								disabled = function()
									local mapId = self.data.custom.mapID
									local questID = self.data.custom.wqID
									return (questID == nil or questID == "") or
										(self.data.custom.questType == CriteriaType.QuestPin and (mapId == nil or mapId == ""))
								end
							},
							-- Configure
							header2 = {
								type = "header",
								name = L["Configure custom World Quests"],
								order = newOrder()
							}
						}
					},
					reward = {
						order = newOrder(),
						name = L["Reward"],
						type = "group",
						inline = true,
						args = {
							-- Add item
							header1 = {
								type = "header",
								name = L["Add a World Quest Reward you want to track"],
								order = newOrder()
							},
							itemID = {
								name = L["itemID"],
								-- desc = "To add a worldquest, enter a unique name for the worldquest, and click Okay",
								type = "input",
								order = newOrder(),
								width = .6,
								set = function(info, val)
									WQA.data.custom.worldQuestReward = val
								end,
								get = function()
									return tostring(WQA.data.custom.worldQuestReward or 0)
								end
							},
							button = {
								order = newOrder(),
								type = "execute",
								name = L["Add"],
								width = .3,
								func = function()
									WQA:CreateCustomReward()
								end
							},
							-- Configure
							header2 = {
								type = "header",
								name = L["Configure custom World Quest Rewards"],
								order = newOrder()
							}
						}
					},
					mission = {
						order = newOrder(),
						name = L["Mission"],
						type = "group",
						inline = true,
						args = {
							-- Add WQ
							header1 = {
								type = "header",
								name = L["Add a Mission you want to track"],
								order = newOrder()
							},
							missionID = {
								name = L["MissionID"],
								type = "input",
								order = newOrder(),
								width = .6,
								set = function(info, val)
									WQA.data.custom.mission.missionID = val
								end,
								get = function()
									return tostring(WQA.data.custom.mission.missionID)
								end
							},
							rewardID = {
								name = L["Reward (optional)"],
								desc = L["Enter an achievementID or itemID"],
								type = "input",
								width = .6,
								order = newOrder(),
								set = function(info, val)
									WQA.data.custom.mission.rewardID = val
								end,
								get = function()
									return tostring(WQA.data.custom.mission.rewardID)
								end
							},
							rewardType = {
								name = L["Reward type"],
								order = newOrder(),
								type = "select",
								values = {
									item = L["Item"],
									achievement = L["Achievement"],
									none = L["none"]
								},
								width = .6,
								set = function(info, val)
									WQA.data.custom.mission.rewardType = val
								end,
								get = function()
									return WQA.data.custom.mission.rewardType
								end
							},
							button = {
								order = newOrder(),
								type = "execute",
								name = L["Add"],
								width = .3,
								func = function()
									WQA:CreateCustomMission()
								end
							},
							-- Configure
							header2 = {
								type = "header",
								name = L["Configure custom Missions"],
								order = newOrder()
							}
						}
					},
					missionReward = {
						order = newOrder(),
						name = L["Reward"],
						type = "group",
						inline = true,
						args = {
							-- Add item
							header1 = {
								type = "header",
								name = L["Add a Mission Reward you want to track"],
								order = newOrder()
							},
							itemID = {
								name = L["itemID"],
								type = "input",
								order = newOrder(),
								width = .6,
								set = function(info, val)
									WQA.data.custom.missionReward = val
								end,
								get = function()
									return tostring(WQA.data.custom.missionReward or 0)
								end
							},
							button = {
								order = newOrder(),
								type = "execute",
								name = L["Add"],
								width = .3,
								func = function()
									WQA:CreateCustomMissionReward()
								end
							},
							-- Configure
							header2 = {
								type = "header",
								name = L["Configure custom Mission Rewards"],
								order = newOrder()
							}
						}
					}
				}
			},
			options = {
				order = newOrder(),
				type = "group",
				name = L["Options"],
				args = {
					desc1 = {
						type = "description",
						fontSize = "medium",
						name = L["Select where WQA is allowed to post"],
						order = newOrder()
					},
					chat = {
						type = "toggle",
						name = L["Chat"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.chat = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.chat
						end,
						order = newOrder()
					},
					PopUp = {
						type = "toggle",
						name = L["PopUp"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.PopUp = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.PopUp
						end,
						order = newOrder()
					},
					popupRememberPosition = {
						type = "toggle",
						name = L["Remember PopUp position"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.popupRememberPosition = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.popupRememberPosition
						end,
						order = newOrder()
					},
					sortByName = {
						type = "toggle",
						name = L["Sort quests by name"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.sortByName = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.sortByName
						end,
						order = newOrder()
					},
					sortByZoneName = {
						type = "toggle",
						name = L["Sort quests by zone name"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.sortByZoneName = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.sortByZoneName
						end,
						order = newOrder()
					},
					chatShowExpansion = {
						type = "toggle",
						name = L["Show expansion in chat"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.chatShowExpansion = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.chatShowExpansion
						end,
						order = newOrder()
					},
					chatShowZone = {
						type = "toggle",
						name = L["Show zone in chat"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.chatShowZone = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.chatShowZone
						end,
						order = newOrder()
					},
					chatShowTime = {
						type = "toggle",
						name = L["Show time left in chat"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.chatShowTime = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.chatShowTime
						end,
						order = newOrder()
					},
					popupShowExpansion = {
						type = "toggle",
						name = L["Show expansion in popup"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.popupShowExpansion = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.popupShowExpansion
						end,
						order = newOrder()
					},
					popupShowZone = {
						type = "toggle",
						name = L["Show zone in popup"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.popupShowZone = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.popupShowZone
						end,
						order = newOrder()
					},
					popupShowTime = {
						type = "toggle",
						name = L["Show time left in popup"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.popupShowTime = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.popupShowTime
						end,
						order = newOrder()
					},
					delay = {
						name = L["Delay on login in s"],
						type = "input",
						order = newOrder(),
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.delay = tonumber(val)
						end,
						get = function()
							return tostring(WQA.db.profile.options.delay)
						end
					},
					delayCombat = {
						name = L["Delay output while in combat"],
						type = "toggle",
						order = newOrder(),
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.delayCombat = val
						end,
						get = function()
							return WQA.db.profile.options.delayCombat
						end
					},
					showWarModeQuestsWithoutWarMode = {
						type = "toggle",
						name = "Show PvP World Quests while War Mode is disabled",
						desc = "Shows PvP World Quests even when War Mode is off. These quests may not count toward their associated achievements until War Mode is enabled.",
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.showWarModeQuestsWithoutWarMode = val
							WQA:ScheduleOptionsRefresh()
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.showWarModeQuestsWithoutWarMode
						end,
						order = newOrder()
					},
					
WorldQuestTracker = {
						type = "toggle",
						name = L["Use World Quest Tracker"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.WorldQuestTracker = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.WorldQuestTracker
						end,
						order = newOrder()
					},
					esc = {
						type = "toggle",
						name = L["Close PopUp with ESC"],
						desc = L["Requires a reload"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.esc = val
						end,
						descStyle = "inline",
						get = function()
							return WQA.db.profile.options.esc
						end,
						order = newOrder()
					},
					LibDBIcon = {
						type = "toggle",
						name = L["Show Minimap Icon"],
						width = "double",
						set = function(info, val)
							WQA.db.profile.options.LibDBIcon.hide = not val
							WQA:UpdateMinimapIcon()
						end,
						descStyle = "inline",
						get = function()
							return not WQA.db.profile.options.LibDBIcon.hide
						end,
						order = newOrder()
					}
				}
			}
		}
	}

	self:OrganizeSettingsTabs()

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

	self:CreateTrackingSearch(self.options.args.general.args)

	local trackingExpansionOrder = 10
	for _, i in ipairs(GetSortedExpansionIDs(self.ExpansionList)) do
		local expansionData = self.data[i]
		if expansionData and expansionData.name then
			local expansionName = expansionData.name
			local expansionOptions = {
				order = trackingExpansionOrder,
				name = expansionName,
				type = "group",
				childGroups = "tree",
				args = {}
			}
			trackingExpansionOrder = trackingExpansionOrder + 1
			self.options.args.general.args[expansionName] = expansionOptions

			expansionOptions.args.bulkTracking = {
				order = 1,
				type = "select",
				name = "Set all tracking in " .. expansionName,
				desc = "Applies Don't track, Default, or Always track to every achievement, mount, pet, and toy in this expansion.",
				values = BULK_TRACKING_VALUES,
				width = "double",
				get = function()
					return WQA:GetExpansionBulkTrackingState(expansionData)
				end,
				set = function(_, value)
					if value ~= "mixed" then
						WQA:SetTrackingForExpansion(expansionData, value)
						LibStub("AceConfigRegistry-3.0"):NotifyChange("WQATurbo")
					end
				end
			}

			expansionOptions.args.bulkHint = {
				order = 2,
				type = "description",
				name = "Choose a category from the tree for individual settings, or use the selector above to update the whole expansion."
			}

			for _, groupName in ipairs(TRACKING_GROUPS) do
				self:CreateGroup(expansionOptions.args, expansionData, groupName)
			end
		end
	end

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
						desc = "Track World Quests that award reputation with the selected factions.",
						type = "group",
						args = {
							hideMaxed = {
								order = 1,
								type = "toggle",
								name = "Hide Exalted / max Renown reputations",
								desc = "Hide finished reputations from these lists and ignore them when matching reputation rewards. This includes classic Exalted reputations and Major Factions at maximum Renown.",
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
						name = "Containers",
						type = "group",
						args = {
							racingRewardContainers = {
								type = "toggle",
								name = "Racing reward containers",
								desc = "Track Dragonflight racing World Quests that reward Dragon Racer's Purse, Reach Racer's Purse, Cavern Racer's Purse, or Dream Racer's Purse. These containers can contain Drakewatcher's Manuscripts.",
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
						args = {}
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
	self:UpdateCustom()
end

function WQA:GetOptions()
	self:UpdateOptions()
	self:SortOptions()
	return self.options
end

function WQA:OrganizeSettingsTabs()
	-- Rewards: use the tree for navigation instead of one long page.
	local rewardTab = self.options.args.reward
	rewardTab.childGroups = "tree"

	-- Custom: each editor gets its own tree page.
	local customTab = self.options.args.custom
	customTab.childGroups = "tree"
	if customTab.args.quest then
		customTab.args.quest.inline = nil
		customTab.args.quest.name = "World Quests"
	end
	if customTab.args.reward then
		customTab.args.reward.inline = nil
		customTab.args.reward.name = "World Quest Rewards"
	end
	if customTab.args.mission then
		customTab.args.mission.inline = nil
		customTab.args.mission.name = "Missions"
	end
	if customTab.args.missionReward then
		customTab.args.missionReward.inline = nil
		customTab.args.missionReward.name = "Mission Rewards"
	end

	-- Options: split the old flat list into focused pages.
	local optionsTab = self.options.args.options
	local old = optionsTab.args
	optionsTab.childGroups = "tree"

	if old.showWarModeQuestsWithoutWarMode then
		old.showWarModeQuestsWithoutWarMode.name = "Show PvP WQs while War Mode is disabled"
	end

	-- AceConfig's inline descriptions can become cramped inside Blizzard's
	-- Settings tree pane. Keep the setting itself full-width and render its
	-- explanation as a separate full-width row underneath.
	local function BuildOptionPage(order, name, entries)
		local args = {}

		for index, entry in ipairs(entries) do
			if entry.option then
				local optionOrder = index * 10
				entry.option.order = optionOrder
				entry.option.width = "full"
				entry.option.desc = entry.description
				entry.option.descStyle = nil
				args[entry.key] = entry.option
				args[entry.key .. "Help"] = {
					order = optionOrder + 1,
					type = "description",
					fontSize = "small",
					width = "full",
					name = "|cffaaaaaa" .. entry.description .. "|r"
				}
			end
		end

		return {
			order = order,
			type = "group",
			name = name,
			args = args
		}
	end

	optionsTab.args = {
		refresh = {
			order = 5,
			type = "group",
			name = "Refresh",
			args = {
				help = {
					order = 1,
					type = "description",
					width = "full",
					name = "Tracking and reward filters refresh automatically after changes. Use this button to force an immediate rebuild when you want to verify the current World Quest state."
				},
				now = {
					order = 2,
					type = "execute",
					name = "Refresh now",
					width = 1.0,
					desc = "Immediately rebuild WQA Turbo's current World Quest data.",
					func = function()
						WQA:RefreshFromOptions()
					end
				}
			}
		},
		output = BuildOptionPage(10, "Output", {
			{
				key = "chat",
				option = old.chat,
				description = "Print matching World Quests to the chat frame when WQA Turbo reports results."
			},
			{
				key = "PopUp",
				option = old.PopUp,
				description = "Automatically show the WQA Turbo popup when new matching World Quests are found."
			}
		}),
		popup = BuildOptionPage(20, "Popup", {
			{
				key = "popupRememberPosition",
				option = old.popupRememberPosition,
				description = "Remember the popup's last dragged position between openings."
			},
			{
				key = "popupShowExpansion",
				option = old.popupShowExpansion,
				description = "Show expansion headings in the World Quest popup."
			},
			{
				key = "popupShowZone",
				option = old.popupShowZone,
				description = "Show zone headings in the World Quest popup."
			},
			{
				key = "popupShowTime",
				option = old.popupShowTime,
				description = "Show the remaining time for each World Quest in the popup."
			},
			{
				key = "esc",
				option = old.esc,
				description = "Allow Escape to close the popup. Changing this option requires a UI reload."
			}
		}),
		chat = BuildOptionPage(30, "Chat", {
			{
				key = "chatShowExpansion",
				option = old.chatShowExpansion,
				description = "Print expansion headings when WQA Turbo writes World Quest results to chat."
			},
			{
				key = "chatShowZone",
				option = old.chatShowZone,
				description = "Print zone headings when WQA Turbo writes World Quest results to chat."
			},
			{
				key = "chatShowTime",
				option = old.chatShowTime,
				description = "Include each World Quest's remaining time in chat output."
			}
		}),
		sorting = BuildOptionPage(40, "Sorting", {
			{
				key = "sortByName",
				option = old.sortByName,
				description = "Sort matching World Quests alphabetically by quest name."
			},
			{
				key = "sortByZoneName",
				option = old.sortByZoneName,
				description = "Sort matching World Quests by zone name."
			}
		}),
		gameplay = BuildOptionPage(50, "Gameplay", {
			{
				key = "delay",
				option = old.delay,
				description = "Seconds to wait after login before WQA Turbo starts its initial scan."
			},
			{
				key = "delayCombat",
				option = old.delayCombat,
				description = "Delay automatic WQA Turbo output while you are in combat and resume it afterward."
			},
			{
				key = "showWarModeQuestsWithoutWarMode",
				option = old.showWarModeQuestsWithoutWarMode,
				description = "Show PvP World Quests even while War Mode is off. Some associated achievements may still require War Mode to be enabled."
			}
		}),
		integrations = BuildOptionPage(60, "Integrations", {
			{
				key = "WorldQuestTracker",
				option = old.WorldQuestTracker,
				description = "Use World Quest Tracker integration when that addon is installed."
			}
		}),
		interface = BuildOptionPage(70, "Interface", {
			{
				key = "LibDBIcon",
				option = old.LibDBIcon,
				description = "Show or hide the WQA Turbo minimap button."
			}
		})
	}
end

function WQA:ScheduleOptionsRefresh(delay)
	delay = delay or 0.30

	if optionsRefreshTimer then
		self:CancelTimer(optionsRefreshTimer)
		optionsRefreshTimer = nil
	end

	optionsRefreshTimer = self:ScheduleTimer(function()
		optionsRefreshTimer = nil
		WQA:Refresh("settings", true)
	end, delay)
end

function WQA:RefreshFromOptions()
	if optionsRefreshTimer then
		self:CancelTimer(optionsRefreshTimer)
		optionsRefreshTimer = nil
	end

	self:Refresh("settings", true)
end

function WQA:SetTrackingValue(groupName, id, value, suppressRefresh)
	if not groupName or not id or not WQA.db.profile[groupName] then
		return
	end

	local currentCharacter
	if value == TrackingMode.Exclusive then
		local name, server = UnitFullName("player")
		currentCharacter = name .. "-" .. server
	end
	TrackingPolicy.SetValue(WQA.db.profile[groupName], id, value, currentCharacter)

	if not suppressRefresh then
		self:ScheduleOptionsRefresh()
	end
end

function WQA:ToggleSet(info, val, ...)
	local category = info[#info - 1]
	local option = tonumber(info[#info])
	self:SetTrackingValue(category, option, val)
end

function WQA:ToggleGet()
end

function WQA:GetTrackedObjectID(object)
	return object and (object.id or object.spellID or object.creatureID or object.itemID)
end

function WQA:GetTrackedObjectTooltipHyperlink(groupName, object)
	if groupName == "achievements" and object.id then
		return GetAchievementLink(object.id)
	end

	if object.itemID then
		return "item:" .. tostring(object.itemID)
	end

	if groupName == "mounts" and object.spellID then
		return "spell:" .. tostring(object.spellID)
	end

	return nil
end

function WQA:GetTrackedObjectDisplayName(groupName, object)
	local id = self:GetTrackedObjectID(object)
	if not id then
		return object.name or "Unknown"
	end

	if groupName == "achievements" and object.id then
		local achievementName = select(2, GetAchievementInfo(object.id))
		return GetAchievementLink(object.id) or achievementName or object.name or tostring(id)
	end

	if object.itemID then
		local itemName, itemLink = GetItemInfo(object.itemID)
		if not itemLink then
			if optionsTimer then
				self:CancelTimer(optionsTimer)
			end
			optionsTimer = self:ScheduleTimer(function()
				LibStub("AceConfigRegistry-3.0"):NotifyChange("WQATurbo")
			end, 2)
		end
		return itemLink or itemName or object.name or tostring(id)
	end

	return object.name or tostring(id)
end

function WQA:GetTrackedObjectSearchText(groupName, object)
	local id = self:GetTrackedObjectID(object)
	local name = object.name

	if groupName == "achievements" and object.id then
		name = select(2, GetAchievementInfo(object.id)) or name
		if not name then
			local achievementLink = GetAchievementLink(object.id)
			name = achievementLink and string.match(achievementLink, "%[(.-)%]") or nil
		end
	elseif object.itemID then
		name = GetItemInfo(object.itemID) or name
	end

	return string.lower((name or "") .. " " .. tostring(id or ""))
end

function WQA:IsTrackedObjectCompleted(groupName, id)
	if groupName == "achievements" then
		return select(4, GetAchievementInfo(id)) or false
	elseif groupName == "mounts" then
		for _, mountID in pairs(C_MountJournal.GetMountIDs()) do
			local _, spellID, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
			if spellID == id then
				return isCollected or false
			end
		end
	elseif groupName == "pets" then
		local total = C_PetJournal.GetNumPets()
		for i = 1, total do
			local _, _, owned, _, _, _, _, _, _, _, companionID = C_PetJournal.GetPetInfoByIndex(i)
			if companionID == id then
				return owned or false
			end
		end
	elseif groupName == "toys" then
		return PlayerHasToy(id) or false
	end

	return false
end

function WQA:AddTrackedObjectRow(args, groupName, object, keyPrefix, order)
	local id = self:GetTrackedObjectID(object)
	if not id then
		return order
	end

	local idString = tostring(id)
	local optionKey = (keyPrefix or "") .. idString
	local tooltipHyperlink = self:GetTrackedObjectTooltipHyperlink(groupName, object)

	args[optionKey .. "Name"] = {
		type = "description",
		name = self:GetTrackedObjectDisplayName(groupName, object),
		fontSize = "medium",
		order = order,
		width = 1.5,
		dialogControl = tooltipHyperlink and "InteractiveLabel" or nil,
		tooltipHyperlink = tooltipHyperlink
	}

	local trackingValues = {
		[TrackingMode.Disabled] = L["tracking_disabled"],
		[TrackingMode.Default] = L["tracking_default"],
		[TrackingMode.Always] = L["tracking_always"],
		[TrackingMode.WasEarnedByMe] = L["tracking_wasEarnedByMe"],
		[TrackingMode.Exclusive] = L["tracking_exclusive"]
	}

	args[optionKey] = {
		type = "select",
		values = trackingValues,
		width = 1.4,
		name = "",
		set = function(_, value)
			WQA:SetTrackingValue(groupName, id, value)
		end,
		get = function()
			trackingValues.other = nil
			local value = WQA.db.profile[groupName][id]
			if value == TrackingMode.Exclusive then
				local name, server = UnitFullName("player")
				local currentCharacter = name .. "-" .. server
				local owner = WQA.db.profile[groupName].exclusive[id]
				if owner and owner ~= currentCharacter then
					trackingValues.other = string.format(L["tracking_other"], owner)
					return "other"
				end
			end
			return value
		end,
		order = order + 1
	}

	return order + 2
end

function WQA:GetBulkTrackingState(objects, groupName)
	local commonValue
	local found = false

	for _, object in pairs(objects or {}) do
		local id = self:GetTrackedObjectID(object)
		if id then
			local value = WQA.db.profile[groupName][id]
			if not TrackingPolicy.IsBulkMode(value) then
				return "mixed"
			end
			if not found then
				commonValue = value
				found = true
			elseif commonValue ~= value then
				return "mixed"
			end
		end
	end

	return found and commonValue or "mixed"
end

function WQA:SetTrackingForCategory(objects, groupName, value, suppressRefresh)
	if not TrackingPolicy.IsBulkMode(value) then
		return
	end

	for _, object in pairs(objects or {}) do
		local id = self:GetTrackedObjectID(object)
		if id then
			self:SetTrackingValue(groupName, id, value, true)
		end
	end

	if not suppressRefresh then
		self:ScheduleOptionsRefresh()
	end
end

function WQA:GetExpansionBulkTrackingState(expansionData)
	local commonValue
	local found = false

	for _, groupName in ipairs(TRACKING_GROUPS) do
		for _, object in pairs(expansionData[groupName] or {}) do
			local id = self:GetTrackedObjectID(object)
			if id then
				local value = WQA.db.profile[groupName][id]
				if not TrackingPolicy.IsBulkMode(value) then
					return "mixed"
				end
				if not found then
					commonValue = value
					found = true
				elseif commonValue ~= value then
					return "mixed"
				end
			end
		end
	end

	return found and commonValue or "mixed"
end

function WQA:SetTrackingForExpansion(expansionData, value)
	for _, groupName in ipairs(TRACKING_GROUPS) do
		self:SetTrackingForCategory(expansionData[groupName], groupName, value, true)
	end
	self:ScheduleOptionsRefresh()
end

function WQA:CreateGroup(options, data, groupName)
	local objects = data[groupName]
	if not objects then
		return
	end

	options[groupName] = {
		order = TRACKING_GROUP_ORDER[groupName] or 100,
		name = L[groupName],
		type = "group",
		args = {}
	}

	local args = options[groupName].args
	args.bulkTracking = {
		type = "select",
		name = "Set all " .. string.lower(L[groupName] or groupName),
		desc = "Change every entry in this category at once. Character-specific tracking modes remain available on individual entries.",
		values = BULK_TRACKING_VALUES,
		width = "double",
		order = 1,
		get = function()
			return WQA:GetBulkTrackingState(objects, groupName)
		end,
		set = function(_, value)
			if value ~= "mixed" then
				WQA:SetTrackingForCategory(objects, groupName, value)
				LibStub("AceConfigRegistry-3.0"):NotifyChange("WQATurbo")
			end
		end
	}

	local incomplete = {}
	local completed = {}
	for _, object in pairs(objects) do
		local id = self:GetTrackedObjectID(object)
		if id then
			local entry = {
				object = object,
				name = self:GetTrackedObjectSearchText(groupName, object)
			}
			if self:IsTrackedObjectCompleted(groupName, id) then
				table.insert(completed, entry)
			else
				table.insert(incomplete, entry)
			end
		end
	end

	local function sortEntries(a, b)
		return a.name < b.name
	end
	table.sort(incomplete, sortEntries)
	table.sort(completed, sortEntries)

	local order = 10
	if #incomplete > 0 then
		args.notCompleted = {
			type = "header",
			name = L["notCompleted"],
			order = order
		}
		order = order + 1
		for _, entry in ipairs(incomplete) do
			order = self:AddTrackedObjectRow(args, groupName, entry.object, nil, order)
		end
	end

	if #completed > 0 then
		args.completed = {
			type = "header",
			name = L["completed"],
			order = order
		}
		order = order + 1
		for _, entry in ipairs(completed) do
			order = self:AddTrackedObjectRow(args, groupName, entry.object, nil, order)
		end
	end
end

function WQA:CreateTrackingSearch(options)
	local searchGroup = {
		order = 1,
		name = "Search",
		type = "group",
		args = {}
	}
	options.search = searchGroup

	searchGroup.args.query = {
		order = 1,
		type = "input",
		name = "Search achievements, mounts, pets, and toys",
		desc = "Searches all supported expansions by name or ID. The search text is temporary and is not saved to your profile.",
		width = "full",
		get = function()
			return WQA.optionsSearchText or ""
		end,
		set = function(_, value)
			WQA.optionsSearchText = value or ""
			LibStub("AceConfigRegistry-3.0"):NotifyChange("WQATurbo")
		end
	}

	local query = string.lower(WQA.optionsSearchText or "")
	query = string.match(query, "^%s*(.-)%s*$") or ""

	if query == "" then
		searchGroup.args.help = {
			order = 2,
			type = "description",
			name = "Type part of a collectible name or an ID to find it across every expansion."
		}
		return
	end

	local resultOrder = 10
	local resultCount = 0

	for _, expansionID in ipairs(GetSortedExpansionIDs(self.ExpansionList)) do
		local expansionData = self.data[expansionID]
		if expansionData and expansionData.name then
			for _, groupName in ipairs(TRACKING_GROUPS) do
				local matches = {}
				for _, object in pairs(expansionData[groupName] or {}) do
					if string.find(self:GetTrackedObjectSearchText(groupName, object), query, 1, true) then
						table.insert(matches, object)
					end
				end

				if #matches > 0 then
					table.sort(matches, function(a, b)
						return self:GetTrackedObjectSearchText(groupName, a) <
							self:GetTrackedObjectSearchText(groupName, b)
					end)

					local groupKey = "result_" .. tostring(expansionID) .. "_" .. groupName
					searchGroup.args[groupKey] = {
						order = resultOrder,
						type = "group",
						inline = true,
						name = expansionData.name .. " — " .. (L[groupName] or groupName),
						args = {}
					}
					resultOrder = resultOrder + 1

					local rowOrder = 1
					for _, object in ipairs(matches) do
						local prefix = tostring(expansionID) .. "_" .. groupName .. "_"
						rowOrder = self:AddTrackedObjectRow(
							searchGroup.args[groupKey].args,
							groupName,
							object,
							prefix,
							rowOrder
						)
						resultCount = resultCount + 1
					end
				end
			end
		end
	end

	searchGroup.args.resultCount = {
		order = 3,
		type = "description",
		name = string.format("%d result%s", resultCount, resultCount == 1 and "" or "s")
	}

	if resultCount == 0 then
		searchGroup.args.noResults = {
			order = 4,
			type = "description",
			name = "No matching tracked collectibles were found."
		}
	end
end

function WQA:CreateCustomQuest()
	if not self.db.global.custom then
		self.db.global.custom = {}
	end
	if not self.db.global.custom.worldQuest then
		self.db.global.custom.worldQuest = {}
	end
	self.db.global.custom.worldQuest[tonumber(self.data.custom.wqID)] = {
		questType = self.data.custom.questType,
		mapID = self.data.custom.mapID
	} -- {rewardID = tonumber(self.data.custom.rewardID), rewardType = self.data.custom.rewardType}
	self:UpdateCustomQuests()
end

function WQA:UpdateCustomQuests()
	local data = self.db.global.custom.worldQuest
	if type(data) ~= "table" then
		return false
	end
	local args = self.options.args.custom.args.quest.args
	for id, object in pairs(data) do
		args[tostring(id)] = {
			type = "toggle",
			name = GetQuestLink(id) or GetTitleForQuestID(id) or tostring(id),
			set = function(info, val)
				WQA.db.profile.custom.worldQuest[id] = val
			end,
			descStyle = "inline",
			get = function()
				return WQA.db.profile.custom.worldQuest[id]
			end,
			order = newOrder(),
			width = 1.2
		}

		args[id .. "questType"] = {
			name = L["Quest type"],
			order = newOrder(),
			desc =
			L["IsActive:\nUse this as a last resort. Works for some daily quests.\n\nIsQuestFlaggedCompleted:\nUse this for quests, that are always active.\n\nQuest Pin:\nUse this, if the daily is marked with a quest pin on the world map.\n\nWorld Quest:\nUse this, if you want to track a world quest."],
			type = "select",
			values = {
				[TaskType.WorldQuest] = L["World Quest"],
				[CriteriaType.QuestPin] = L["Quest Pin"],
				[CriteriaType.QuestFlag] = L["IsQuestFlaggedCompleted"],
				IsActive = L["IsActive"]
			},
			width = .8,
			set = function(info, val)
				self.db.global.custom.worldQuest[id].questType = val
			end,
			get = function()
				return tostring(self.db.global.custom.worldQuest[id].questType or "")
			end
		}
		args[id .. "mapID"] = {
			name = L["mapID"],
			desc = L["Quest pin tracking needs a mapID.\nSee https://wow.gamepedia.com/UiMapID for help."],
			type = "input",
			width = .4,
			order = newOrder(),
			set = function(info, val)
				self.db.global.custom.worldQuest[id].mapID = val
			end,
			get = function()
				return tostring(self.db.global.custom.worldQuest[id].mapID or "")
			end
		}

		--[[
		args[id.."Reward"] = {
		name = L["Reward (optional)"],
		desc = "Enter an achievementID or itemID",
		type = "input",
		width = .6,
		order = newOrder(),
		set = function(info,val)
		self.db.global.custom.worldQuest[id].rewardID = tonumber(val)
		end,
		get = function() return
		tostring(self.db.global.custom.worldQuest[id].rewardID or "")
		end
		}
		args[id.."RewardType"] = {
		name = L["Reward type"],
		order = newOrder(),
		type = "select",
		values = {item = "Item", achievement = "Achievement", none = "none"},
		width = .6,
		set = function(info,val)
		self.db.global.custom.worldQuest[id].rewardType = val
		end,
		get = function() return self.db.global.custom.worldQuest[id].rewardType or nil end
		}--]]
		args[id .. "Delete"] = {
			order = newOrder(),
			type = "execute",
			name = L["Delete"],
			width = .5,
			func = function()
				args[tostring(id)] = nil
				args[id .. "Reward"] = nil
				args[id .. "RewardType"] = nil
				args[id .. "Delete"] = nil
				args[id .. "space"] = nil
				self.db.global.custom.worldQuest[id] = nil
				self:UpdateCustomQuests()
				GameTooltip:Hide()
			end
		}
		args[id .. "space"] = {
			name = " ",
			width = .25,
			order = newOrder(),
			type = "description"
		}
	end
end

function WQA:CreateCustomReward()
	if not self.db.global.custom then
		self.db.global.custom = {}
	end
	if not self.db.global.custom.worldQuestReward then
		self.db.global.custom.worldQuestReward = {}
	end
	self.db.global.custom.worldQuestReward[tonumber(self.data.custom.worldQuestReward)] = true
	self:UpdateCustomRewards()
end

function WQA:UpdateCustomRewards()
	local data = self.db.global.custom.worldQuestReward
	if type(data) ~= "table" then
		return false
	end
	local args = self.options.args.custom.args.reward.args
	for id, _ in pairs(data) do
		local _, itemLink = GetItemInfo(id)
		args[tostring(id)] = {
			type = "toggle",
			name = itemLink or tostring(id),
			--width = "double",
			set = function(info, val)
				WQA.db.profile.custom.worldQuestReward[id] = val
			end,
			descStyle = "inline",
			get = function()
				return WQA.db.profile.custom.worldQuestReward[id]
			end,
			order = newOrder(),
			width = 1.2
		}
		args[id .. "Delete"] = {
			order = newOrder(),
			type = "execute",
			name = L["Delete"],
			width = .5,
			func = function()
				args[tostring(id)] = nil
				args[id .. "Delete"] = nil
				args[id .. "space"] = nil
				self.db.global.custom.worldQuestReward[id] = nil
				self:UpdateCustomRewards()
				GameTooltip:Hide()
			end
		}
		args[id .. "space"] = {
			name = " ",
			width = 1,
			order = newOrder(),
			type = "description"
		}
	end
end

function WQA:CreateCustomMission()
	if not self.db.global.custom then
		self.db.global.custom = {}
	end
	if not self.db.global.custom.mission then
		self.db.global.custom.mission = {}
	end
	self.db.global.custom.mission[tonumber(self.data.custom.mission.missionID)] = {
		rewardID = tonumber(self.data.custom.mission.rewardID),
		rewardType = self.data.custom.mission.rewardType
	}
	self:UpdateCustomMissions()
end

function WQA:UpdateCustomMissions()
	local data = self.db.global.custom.mission
	if type(data) ~= "table" then
		return false
	end
	local args = self.options.args.custom.args.mission.args
	for id, object in pairs(data) do
		args[tostring(id)] = {
			type = "toggle",
			name = C_Garrison.GetMissionLink(id) or tostring(id),
			set = function(info, val)
				WQA.db.profile.custom.mission[id] = val
			end,
			descStyle = "inline",
			get = function()
				return WQA.db.profile.custom.mission[id]
			end,
			order = newOrder(),
			width = 1.2
		}
		args[id .. "Reward"] = {
			name = L["Reward (optional)"],
			desc = L["Enter an achievementID or itemID"],
			type = "input",
			width = .6,
			order = newOrder(),
			set = function(info, val)
				self.db.global.custom.mission[id].rewardID = tonumber(val)
			end,
			get = function()
				return tostring(self.db.global.custom.mission[id].rewardID or "")
			end
		}
		args[id .. "RewardType"] = {
			name = L["Reward type"],
			order = newOrder(),
			type = "select",
			values = { item = "Item", achievement = "Achievement", none = "none" },
			width = .6,
			set = function(info, val)
				self.db.global.custom.mission[id].rewardType = val
			end,
			get = function()
				return self.db.global.custom.mission[id].rewardType or nil
			end
		}
		args[id .. "Delete"] = {
			order = newOrder(),
			type = "execute",
			name = L["Delete"],
			width = .5,
			func = function()
				args[tostring(id)] = nil
				args[id .. "Reward"] = nil
				args[id .. "RewardType"] = nil
				args[id .. "Delete"] = nil
				args[id .. "space"] = nil
				self.db.global.custom.mission[id] = nil
				self:UpdateCustomMissions()
				GameTooltip:Hide()
			end
		}
		args[id .. "space"] = {
			name = " ",
			width = .25,
			order = newOrder(),
			type = "description"
		}
	end
end

function WQA:CreateCustomMissionReward()
	if not self.db.global.custom then
		self.db.global.custom = {}
	end
	if not self.db.global.custom.missionReward then
		self.db.global.custom.missionReward = {}
	end
	self.db.global.custom.missionReward[tonumber(self.data.custom.missionReward)] = true
	self:UpdateCustomMissionRewards()
end

function WQA:UpdateCustomMissionRewards()
	local data = self.db.global.custom.missionReward
	if type(data) ~= "table" then
		return false
	end
	local args = self.options.args.custom.args.missionReward.args
	for id, _ in pairs(data) do
		local _, itemLink = GetItemInfo(id)
		args[tostring(id)] = {
			type = "toggle",
			name = itemLink or tostring(id),
			set = function(info, val)
				WQA.db.profile.custom.missionReward[id] = val
			end,
			descStyle = "inline",
			get = function()
				return WQA.db.profile.custom.missionReward[id]
			end,
			order = newOrder(),
			width = 1.2
		}
		args[id .. "Delete"] = {
			order = newOrder(),
			type = "execute",
			name = L["Delete"],
			width = .5,
			func = function()
				args[tostring(id)] = nil
				args[id .. "Delete"] = nil
				args[id .. "space"] = nil
				self.db.global.custom.missionReward[id] = nil
				self:UpdateCustomMissionRewards()
				GameTooltip:Hide()
			end
		}
		args[id .. "space"] = {
			name = " ",
			width = 1,
			order = newOrder(),
			type = "description"
		}
	end
end

function WQA:UpdateCustom()
	self:UpdateCustomQuests()
	self:UpdateCustomRewards()
	self:UpdateCustomMissions()
	self:UpdateCustomMissionRewards()
end

function WQA:SortOptions()
	-- Tracking rows are now sorted while the Settings tree is built.
end

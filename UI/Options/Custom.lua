local WQA = WQATurbo
local L = WQA.L
local newOrder = WQA.OptionsUI.NewOrder
local TaskType = WQA.Constants.TaskType
local CriteriaType = WQA.Constants.CriteriaType
local GetTitleForQuestID = C_QuestLog.GetTitleForQuestID

function WQA:CreateCustomOptions()
	return {
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
	}
end

-- Validate again at each write boundary; Add can also be called directly.
local function CustomID(value)
	if type(value) ~= "string" and type(value) ~= "number" then return nil end
	local id = tonumber(value)
	if id and id > 0 and id < math.huge and id % 1 == 0 then return id end
end

local function CustomBlank(value)
	return value == nil or (type(value) == "string" and value:match("^%s*$") ~= nil)
end

local function CustomError(message)
	WQA:Print(message)
	return false
end

local function CustomMap(value, questType)
	if CustomBlank(value) and questType ~= CriteriaType.QuestPin then return true, nil end
	local id = CustomID(value)
	if not id or not C_Map.GetMapInfo(id) then return false end
	return true, id
end

local function NewCustomID(group, value)
	local id = CustomID(value)
	if not id then return nil, "Enter a positive integer ID." end
	local entries = WQA.db.global.custom and WQA.db.global.custom[group]
	if entries and (entries[id] ~= nil or entries[tostring(id)] ~= nil) then
		return nil, "This ID already exists. Edit the existing entry."
	end
	return id
end

function WQA:CreateCustomQuest()
	local id, err = NewCustomID("worldQuest", self.data.custom.wqID)
	if not id then return CustomError(err) end
	local valid, mapID = CustomMap(self.data.custom.mapID, self.data.custom.questType)
	if not valid then return CustomError("Enter a valid map ID; Quest Pin requires a map.") end
	if not self.db.global.custom then
		self.db.global.custom = {}
	end
	if not self.db.global.custom.worldQuest then
		self.db.global.custom.worldQuest = {}
	end
	self.db.global.custom.worldQuest[id] = {
		questType = self.data.custom.questType,
		mapID = mapID
	}
	self:UpdateCustomQuests()
	self:ScheduleOptionsRefresh()
	return true
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
				WQA:ScheduleOptionsRefresh()
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
				local entry = self.db.global.custom.worldQuest[id]
				local valid, mapID = CustomMap(entry.mapID, val)
				if not valid then return CustomError("Enter a valid map ID before selecting Quest Pin.") end
				entry.questType = val
				entry.mapID = mapID
				self:ScheduleOptionsRefresh()
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
				local entry = self.db.global.custom.worldQuest[id]
				local valid, mapID = CustomMap(val, entry.questType)
				if not valid then return CustomError("Enter a valid map ID; Quest Pin requires a map.") end
				entry.mapID = mapID
				self:ScheduleOptionsRefresh()
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
				args[id .. "questType"] = nil
				args[id .. "mapID"] = nil
				self.db.global.custom.worldQuest[id] = nil
				self:ScheduleOptionsRefresh()
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
	local id, err = NewCustomID("worldQuestReward", self.data.custom.worldQuestReward)
	if not id then return CustomError(err) end
	if not self.db.global.custom then
		self.db.global.custom = {}
	end
	if not self.db.global.custom.worldQuestReward then
		self.db.global.custom.worldQuestReward = {}
	end
	self.db.global.custom.worldQuestReward[id] = true
	self:UpdateCustomRewards()
	self:ScheduleOptionsRefresh()
	return true
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
				WQA:ScheduleOptionsRefresh()
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
				self:ScheduleOptionsRefresh()
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
	local id, err = NewCustomID("mission", self.data.custom.mission.missionID)
	if not id then return CustomError(err) end
	local rewardID = CustomID(self.data.custom.mission.rewardID)
	if not CustomBlank(self.data.custom.mission.rewardID) and not rewardID then
		return CustomError("Enter a positive integer reward ID, or leave it blank.")
	end
	if not self.db.global.custom then
		self.db.global.custom = {}
	end
	if not self.db.global.custom.mission then
		self.db.global.custom.mission = {}
	end
	self.db.global.custom.mission[id] = {
		rewardID = rewardID,
		rewardType = self.data.custom.mission.rewardType
	}
	self:UpdateCustomMissions()
	self:ScheduleOptionsRefresh()
	return true
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
				WQA:ScheduleOptionsRefresh()
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
				local rewardID = CustomID(val)
				if not CustomBlank(val) and not rewardID then
					return CustomError("Enter a positive integer reward ID, or leave it blank.")
				end
				self.db.global.custom.mission[id].rewardID = rewardID
				self:ScheduleOptionsRefresh()
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
				self:ScheduleOptionsRefresh()
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
				self:ScheduleOptionsRefresh()
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
	local id, err = NewCustomID("missionReward", self.data.custom.missionReward)
	if not id then return CustomError(err) end
	if not self.db.global.custom then
		self.db.global.custom = {}
	end
	if not self.db.global.custom.missionReward then
		self.db.global.custom.missionReward = {}
	end
	self.db.global.custom.missionReward[id] = true
	self:UpdateCustomMissionRewards()
	self:ScheduleOptionsRefresh()
	return true
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
				WQA:ScheduleOptionsRefresh()
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
				self:ScheduleOptionsRefresh()
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

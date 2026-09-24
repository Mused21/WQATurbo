local WQA = WQATurbo
local L = WQA.L
local newOrder = WQA.OptionsUI.NewOrder
local optionsRefreshTimer

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
				name = L["Tracking"],
				args = {}
			},
			reward = self:CreateRewardOptions(),
			custom = self:CreateCustomOptions(),
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
					pauseAutomaticRefreshInInstances = {
						type = "toggle",
						name = L["Pause automatic scans in instances"],
						order = newOrder(),
						width = "double",
						set = function(_, value)
							WQA.db.profile.options.pauseAutomaticRefreshInInstances = value
							WQA:ScheduleOptionsRefresh()
						end,
						get = function()
							return WQA.db.profile.options.pauseAutomaticRefreshInInstances
						end
					},
					showWarModeQuestsWithoutWarMode = {
						type = "toggle",
						name = L["Show PvP World Quests while War Mode is disabled"],
						desc = L["Shows PvP World Quests even when War Mode is off. These quests may not count toward their associated achievements until War Mode is enabled."],
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

	self:PopulateWorldQuestTypeOptions()
	self:PopulateTrackingOptions()
	self:PopulateRewardOptions()
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
		customTab.args.quest.name = L["World Quests"]
	end
	if customTab.args.reward then
		customTab.args.reward.inline = nil
		customTab.args.reward.name = L["World Quest Rewards"]
	end
	if customTab.args.mission then
		customTab.args.mission.inline = nil
		customTab.args.mission.name = L["Missions"]
	end
	if customTab.args.missionReward then
		customTab.args.missionReward.inline = nil
		customTab.args.missionReward.name = L["Mission Rewards"]
	end

	-- Options: split the old flat list into focused pages.
	local optionsTab = self.options.args.options
	local old = optionsTab.args
	optionsTab.childGroups = "tree"

	if old.showWarModeQuestsWithoutWarMode then
		old.showWarModeQuestsWithoutWarMode.name = L["Show PvP WQs while War Mode is disabled"]
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
			name = L["Refresh"],
			args = {
				help = {
					order = 1,
					type = "description",
					width = "full",
					name = L["Tracking and reward filters refresh automatically after changes. Use this button to force an immediate rebuild when you want to verify the current World Quest state."]
				},
				now = {
					order = 2,
					type = "execute",
					name = L["Refresh now"],
					width = 1.0,
					desc = L["Immediately rebuild WQA Turbo's current World Quest data."],
					func = function()
						WQA:RefreshFromOptions()
					end
				}
			}
		},
		output = BuildOptionPage(10, L["Output"], {
			{
				key = "chat",
				option = old.chat,
				description = L["Print matching World Quests to the chat frame when WQA Turbo reports results."]
			},
			{
				key = "PopUp",
				option = old.PopUp,
				description = L["Automatically show the WQA Turbo popup when new matching World Quests are found."]
			}
		}),
		popup = BuildOptionPage(20, L["Popup"], {
			{
				key = "popupRememberPosition",
				option = old.popupRememberPosition,
				description = L["Remember the popup's last dragged position between openings."]
			},
			{
				key = "popupShowExpansion",
				option = old.popupShowExpansion,
				description = L["Show expansion headings in the World Quest popup."]
			},
			{
				key = "popupShowZone",
				option = old.popupShowZone,
				description = L["Show zone headings in the World Quest popup."]
			},
			{
				key = "popupShowTime",
				option = old.popupShowTime,
				description = L["Show the remaining time for each World Quest in the popup."]
			},
			{
				key = "esc",
				option = old.esc,
				description = L["Allow Escape to close the popup. Changing this option requires a UI reload."]
			}
		}),
		chat = BuildOptionPage(30, L["Chat"], {
			{
				key = "chatShowExpansion",
				option = old.chatShowExpansion,
				description = L["Print expansion headings when WQA Turbo writes World Quest results to chat."]
			},
			{
				key = "chatShowZone",
				option = old.chatShowZone,
				description = L["Print zone headings when WQA Turbo writes World Quest results to chat."]
			},
			{
				key = "chatShowTime",
				option = old.chatShowTime,
				description = L["Include each World Quest's remaining time in chat output."]
			}
		}),
		sorting = BuildOptionPage(40, L["Sorting"], {
			{
				key = "sortByName",
				option = old.sortByName,
				description = L["Sort matching World Quests alphabetically by quest name."]
			},
			{
				key = "sortByZoneName",
				option = old.sortByZoneName,
				description = L["Sort matching World Quests by zone name."]
			}
		}),
		gameplay = BuildOptionPage(50, L["Gameplay"], {
			{
				key = "delay",
				option = old.delay,
				description = L["Seconds to wait after login before WQA Turbo starts its initial scan."]
			},
			{
				key = "delayCombat",
				option = old.delayCombat,
				description = L["Delay automatic WQA Turbo output while you are in combat and resume it afterward."]
			},
			{
				key = "pauseAutomaticRefreshInInstances",
				option = old.pauseAutomaticRefreshInInstances,
				description = L["Skip automatic scans and notifications in dungeons, raids, scenarios, battlegrounds, and arenas. The latest deferred refresh resumes after you return to the open world; manual popup and refresh commands remain available."]
			},
			{
				key = "showWarModeQuestsWithoutWarMode",
				option = old.showWarModeQuestsWithoutWarMode,
				description = L["Show PvP World Quests even while War Mode is off. Some associated achievements may still require War Mode to be enabled."]
			}
		}),
		integrations = BuildOptionPage(60, L["Integrations"], {
			{
				key = "WorldQuestTracker",
				option = old.WorldQuestTracker,
				description = L["Use World Quest Tracker integration when that addon is installed."]
			}
		}),
		interface = BuildOptionPage(70, L["Interface"], {
			{
				key = "LibDBIcon",
				option = old.LibDBIcon,
				description = L["Show or hide the WQA Turbo minimap button."]
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

function WQA:RefreshFromOptions(immediate)
	if optionsRefreshTimer then
		self:CancelTimer(optionsRefreshTimer)
		optionsRefreshTimer = nil
	end

	self:Refresh("settings", not immediate)
end

function WQA:SortOptions()
	-- Tracking rows are now sorted while the Settings tree is built.
end

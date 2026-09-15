local WQA = WQATurbo
local L = WQA.L
local newOrder = WQA.OptionsUI.NewOrder
local TrackingMode = WQA.Constants.TrackingMode
local TrackingPolicy = WQA.TrackingPolicy
local CriteriaType = WQA.Constants.CriteriaType
local optionsTimer
local GetSortedExpansionIDs = WQA.OptionsUI.GetSortedExpansionIDs

local TRACKING_GROUPS = { "achievements", "mounts", "pets", "toys" }
local TRACKING_GROUP_ORDER = {
	achievements = 10,
	mounts = 20,
	pets = 30,
	toys = 40
}

local BULK_TRACKING_VALUES = {
	mixed = L["Mixed / choose setting"],
	[TrackingMode.Disabled] = L["tracking_disabled"],
	[TrackingMode.Default] = L["tracking_default"],
	[TrackingMode.Always] = L["tracking_always"]
}

function WQA:PopulateTrackingOptions()
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
				name = string.format(L["Set all tracking in %s"], expansionName),
				desc = L["Applies Don't track, Default, or Always track to every achievement, mount, pet, and toy in this expansion."],
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
				name = L["Choose a category from the tree for individual settings, or use the selector above to update the whole expansion."]
			}

			for _, groupName in ipairs(TRACKING_GROUPS) do
				self:CreateGroup(expansionOptions.args, expansionData, groupName)
			end
		end
	end

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
		return object.name or L["Unknown"]
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

local function AppendSearchValues(value, output, visited)
	local valueType = type(value)
	if valueType == "number" or valueType == "string" then
		output[#output + 1] = tostring(value)
	elseif valueType == "table" and not visited[value] then
		visited[value] = true
		for _, child in pairs(value) do
			AppendSearchValues(child, output, visited)
		end
	end
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

	local values = { name or "", id or "" }
	AppendSearchValues(object, values, {})
	return string.lower(table.concat(values, " "))
end

function WQA:IsTrackedObjectCompleted(groupName, id)
	if groupName == "achievements" then
		return select(4, GetAchievementInfo(id)) or false
	elseif groupName == "mounts" then
		return self:IsMountCollectedBySpellID(id)
	elseif groupName == "pets" then
		return self:IsPetOwnedByCreatureID(id)
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
		name = string.format(L["Set all %s"], string.lower(L[groupName] or groupName)),
		desc = L["Change every entry in this category at once. Character-specific tracking modes remain available on individual entries."],
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
		name = L["Search"],
		type = "group",
		args = {}
	}
	options.search = searchGroup

	searchGroup.args.query = {
		order = 1,
		type = "input",
		name = L["Search achievements, mounts, pets, and toys"],
		desc = L["Searches all supported expansions by collectible name, primary ID, source item ID, mapped quest ID, tracking quest ID, or nested criterion. The search text is temporary and is not saved to your profile."],
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
			name = L["Search by collectible name or any related achievement, item, quest, tracking, or criterion ID."]
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
		name = string.format(L["%d result(s)"], resultCount)
	}

	if resultCount == 0 then
		searchGroup.args.noResults = {
			order = 4,
			type = "description",
			name = L["No matching tracked collectibles were found."]
		}
	end
end

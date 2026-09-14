local WQA = WQATurbo

local newOrder
do
	local current = 0
	function newOrder()
		current = current + 1
		return current
	end
end

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

WQA.OptionsUI = { NewOrder = newOrder, GetSortedExpansionIDs = GetSortedExpansionIDs }

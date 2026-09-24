---@class WQATurbo
local WQA = WQATurbo

--[[
WQA Turbo cached UI
===================

The compatibility core used WQA:Show() for two different jobs:

  1. rebuild/refresh the entire data model;
  2. display that model in chat, the minimap popup, or the LDB tooltip.

That means even clicking the minimap icon calls CreateQuestList() again.

Turbo separates those concerns:

  * popup/LDB requests render the current cache immediately;
  * /wqat renders the current cache immediately;
  * /wqat refresh explicitly starts a new data refresh;
  * automatic scheduled Show("new", true) still performs a real refresh.

This also provides progressive background publishing. When dynamic reward
enrichment discovers new information, CheckWQ updates active/new task state
once using the originating publication mode, and an already-open popup is
rebuilt from that fresh state.
]]

local function hasUsableCache(self)
	return type(self.questList) == "table"
		and type(self.activeTasks) == "table"
end

local restrictedInstanceTypes = {
	party = true,
	raid = true,
	scenario = true,
	pvp = true,
	arena = true
}

---Return whether the player is inside grouped instanced content.
---Housing neighborhoods/interiors are intentionally not treated as restricted.
function WQA:IsRestrictedGroupInstance()
	local inInstance, instanceType = IsInInstance()
	return inInstance == true and restrictedInstanceTypes[instanceType] == true
end

---Return whether automatic refresh/output should pause in the current instance.
function WQA:ShouldPauseAutomaticRefreshInInstance()
	return self.db.profile.options.pauseAutomaticRefreshInInstances ~= false
		and self:IsRestrictedGroupInstance()
end

---Rebuild the data model using the established refresh sequence.
---@param self WQATurbo
---@param mode string?
---@param auto boolean?
local function refreshData(self, mode, auto)
	self:Debug("Show", mode)
	local previousAutomatic = self._wqaTurboRefreshAutomatic
	self._wqaTurboRefreshAutomatic = auto == true
	self:CreateQuestList()
	self:CheckWQ(mode, nil, auto == true)
	self._wqaTurboRefreshAutomatic = previousAutomatic
	self.first = true
end

---Render the currently available cache without rebuilding questList.
---@param mode string?
function WQA:ShowCached(mode)
	if not hasUsableCache(self) then
		-- First-ever access before startup initialization completed.
		return refreshData(self, mode)
	end

	self:Debug("ShowCached", mode)
	self:CheckWQ(mode)
	self.first = true
end

---Explicitly rebuild the data model and start a fresh background enrichment.
---@param mode string?
---@param auto boolean?
function WQA:Refresh(mode, auto)
	if auto and self:ShouldPauseAutomaticRefreshInInstance() then
		self._wqaTurboPendingInstanceRefresh = {
			mode = mode,
			auto = auto
		}
		return
	end

	-- Any refresh that is allowed to run satisfies the deferred instance work.
	self._wqaTurboPendingInstanceRefresh = nil

	if auto and self.db.profile.options.delayCombat == true and UnitAffectingCombat("player") then
		self._wqaTurboPendingRefresh = {
			mode = mode,
			auto = auto
		}
		self.event:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	if self._wqaTurboPendingRefresh then
		self._wqaTurboPendingRefresh = nil
		self.event:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end

	local previousMode = self._wqaTurboRefreshMode
	self._wqaTurboRefreshMode = mode
	refreshData(self, mode, auto)
	self._wqaTurboRefreshMode = previousMode
end

---Resume the most recent automatic refresh after returning to the open world.
function WQA:ResumeInstanceDeferredRefresh()
	local pending = self._wqaTurboPendingInstanceRefresh
	if pending and not self:ShouldPauseAutomaticRefreshInInstance() then
		self._wqaTurboPendingInstanceRefresh = nil
		self:Refresh(pending.mode, pending.auto)
	end
end

---Resume the most recent automatic refresh that combat deferred.
function WQA:ResumeDeferredRefresh()
	local pending = self._wqaTurboPendingRefresh
	self._wqaTurboPendingRefresh = nil

	if pending then
		self:Refresh(pending.mode, pending.auto)
	else
		self:Refresh("new", true)
	end
end

---Compatibility entry point used by the original minimap/LDB callbacks.
---
---The original file's data broker object is local, so the cleanest way to
---make minimap interaction instant is to make display-only modes cache-only.
---All other Show() calls preserve upstream refresh semantics.
function WQA:Show(mode, auto)
	if mode == "popup" or mode == "LDB" then
		return self:ShowCached(mode)
	end

	return self:Refresh(mode, auto)
end

---Fully rebuild an already-open popup from current activeTasks.
---
---UpdateQTip() intentionally de-duplicates quest rows and therefore cannot
---update reward columns for an existing row. Releasing/reacquiring the QTip
---gives us a true in-place refresh of the popup's contents.
function WQA:TurboRefreshOpenPopup()
	if not (self.PopUp and self.PopUp.shown) then
		return
	end

	self:RebuildQTip("popup", self.activeTasks or {})
end
function WQA:TurboPublishEnrichment(mode, automatic)
	if not self.questList then
		return
	end

	self:CheckWQ(mode or "new", nil, automatic == true)
end

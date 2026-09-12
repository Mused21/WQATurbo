---@class WQATurbo
local WQA = WQATurbo

--[[
WQA Turbo cached UI
===================

Upstream WQATurbo uses WQA:Show() for two different jobs:

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

local OriginalShow = WQA.Show

local function hasUsableCache(self)
	return type(self.questList) == "table"
		and type(self.activeTasks) == "table"
end

---Render the currently available cache without rebuilding questList.
---@param mode string?
function WQA:ShowCached(mode)
	if not hasUsableCache(self) then
		-- First-ever access before startup initialization completed.
		return OriginalShow(self, mode)
	end

	self:Debug("ShowCached", mode)
	self:CheckWQ(mode)
	self.first = true
end

---Explicitly rebuild the data model and start a fresh background enrichment.
---@param mode string?
---@param auto boolean?
function WQA:Refresh(mode, auto)
	local previousMode = self._wqaTurboRefreshMode
	self._wqaTurboRefreshMode = mode
	OriginalShow(self, mode, auto)
	self._wqaTurboRefreshMode = previousMode
end

---Compatibility override used by the original minimap/LDB callbacks.
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
function WQA:TurboPublishEnrichment(mode)
	if not self.questList then
		return
	end

	self:CheckWQ(mode or "new")
end

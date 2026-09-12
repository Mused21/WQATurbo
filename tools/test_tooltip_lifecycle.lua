-- Run from the repository root with Lua 5.1:
-- lua5.1 tools/test_tooltip_lifecycle.lua
local function noop() end

local acquiredByName = {}
local releaseCount = 0

local function NewQTip(name)
    local tooltip = {
        name = name,
        scripts = {},
        columns = 2,
        released = false
    }

    function tooltip:SetScript(event, callback) self.scripts[event] = callback end
    function tooltip:AddColumn() self.columns = self.columns + 1 end
    function tooltip:GetColumnCount() return self.columns end
    function tooltip:AddHeader() return 1 end
    function tooltip:SetCell() end
    function tooltip:SetFrameStrata() end
    function tooltip:SetFrameLevel() end
    function tooltip:AddSeparator() end

    return tooltip
end

local LibQTip = {}
function LibQTip:IsAcquired(name)
    return acquiredByName[name] ~= nil
end
function LibQTip:Acquire(name)
    local tooltip = NewQTip(name)
    acquiredByName[name] = tooltip
    return tooltip
end
function LibQTip:Release(tooltip)
    releaseCount = releaseCount + 1
    tooltip.released = true

    if acquiredByName[tooltip.name] == tooltip then
        acquiredByName[tooltip.name] = nil
    end

    if tooltip.scripts.OnHide then
        tooltip.scripts.OnHide()
    end
end

LibStub = function(name)
    assert(name == "LibQTip-1.0")
    return LibQTip
end

WQATurbo = {
    Constants = { TaskType = {} },
    L = setmetatable({}, { __index = function(_, key) return key end }),
    db = {
        profile = {
            options = {
                popupShowExpansion = false,
                popupShowZone = false,
                popupShowTime = false
            }
        }
    }
}
local WQA = WQATurbo
dofile("UI/Tooltip.lua")

local popupHideCount = 0
WQA.PopUp = {
    Hide = function() popupHideCount = popupHideCount + 1 end
}

WQA:CreateQTip()
local first = WQA.tooltip
assert(first and acquiredByName.WQATurbo == first)
WQA.PopUp.tooltip = first
first.quests = { [1] = true }
first.missions = { [2] = true }
first.pois = { [3] = true }

-- A stale caller cannot release or detach the currently owned tooltip.
local foreign = NewQTip("foreign")
assert(WQA:ReleaseQTip(foreign) == false)
assert(WQA.tooltip == first)
assert(releaseCount == 0)

-- A stale tooltip OnHide callback cannot hide a popup backed by a newer QTip.
WQA.tooltip = foreign
first.scripts.OnHide()
assert(popupHideCount == 0)
WQA.tooltip = first

-- The current tooltip can still hide its popup through its normal callback.
first.scripts.OnHide()
assert(popupHideCount == 1)

-- Release detaches first, clears all attached task state and is idempotent.
assert(WQA:ReleaseQTip(first) == true)
assert(WQA.tooltip == nil)
assert(WQA.PopUp.tooltip == nil)
assert(first.quests == nil and first.missions == nil and first.pois == nil)
assert(releaseCount == 1)
assert(popupHideCount == 1)
assert(WQA:ReleaseQTip(first) == false)
assert(releaseCount == 1)

-- Popup and LDB rebuilds both release the old exact object before rendering.
WQA:CreateQTip()
local second = WQA.tooltip
local popupTasks = { { id = 1000 } }
WQA.AnnouncePopUp = function(self, tasks)
    assert(self.tooltip == nil)
    assert(tasks == popupTasks)
    self:CreateQTip()
end
assert(WQA:RebuildQTip("popup", popupTasks) == true)
local third = WQA.tooltip
assert(second.released == true and third ~= second)

local shownMode
WQA.Show = function(self, mode)
    assert(self.tooltip == nil)
    shownMode = mode
    self:CreateQTip()
end
assert(WQA:RebuildQTip("LDB") == true)
local fourth = WQA.tooltip
assert(third.released == true and fourth ~= third)
assert(shownMode == "LDB")

-- Invalid rebuild requests leave the current tooltip untouched.
assert(WQA:RebuildQTip("invalid") == false)
assert(WQA.tooltip == fourth and fourth.released == false)

print("Tooltip lifecycle regression checks passed (ownership, stale callbacks, idempotent release and rebuilds).")

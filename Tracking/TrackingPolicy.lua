local WQA = WQATurbo
local TrackingMode = WQA.Constants.TrackingMode

local TrackingPolicy = {}
WQA.TrackingPolicy = TrackingPolicy

---Resolve mode flags without querying collection state or allocating tables.
---Callers retain their existing completion, criterion and tracking-quest gates.
---@return boolean enabled
---@return boolean always
---@return boolean characterOnly
function TrackingPolicy.GetState(settings, id, playerName)
    local mode = settings[id]
    local enabled = mode ~= TrackingMode.Disabled
        and (mode ~= TrackingMode.Exclusive or settings.exclusive[id] == playerName)
    return enabled, mode == TrackingMode.Always, mode == TrackingMode.WasEarnedByMe
end

---Only ordinary modes can be applied to a whole category or expansion.
function TrackingPolicy.IsBulkMode(mode)
    return mode == TrackingMode.Disabled
        or mode == TrackingMode.Default
        or mode == TrackingMode.Always
end

---Update mode and ownership together; the Settings caller schedules refreshes.
function TrackingPolicy.SetValue(settings, id, mode, playerName)
    settings[id] = mode
    if mode == TrackingMode.Exclusive then
        settings.exclusive[id] = playerName
    elseif settings.exclusive[id] then
        settings.exclusive[id] = nil
    end
end

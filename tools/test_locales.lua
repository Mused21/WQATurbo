-- Run from the repository root: lua5.1 tools/test_locales.lua
local matchKeys = {
    "Match: achievement",
    "Match: collectible",
    "Match: custom task",
    "Match: transmog",
    "Match: gear upgrade",
    "Match: item reward",
    "Match: reputation",
    "Match: recipe",
    "Match: custom reward",
    "Match: currency",
    "Match: profession skill-up",
    "Match: gold",
    "Match: Azerite trait",
    "Match: miscellaneous reward"
}

local function LoadLocale(locale)
    WQATurbo = {}
    GetLocale = function() return locale end
    dofile("Locales.lua")
    return WQATurbo.L
end

local english = LoadLocale("enUS")
for _, locale in ipairs({ "zhCN", "zhTW" }) do
    local localized = LoadLocale(locale)
    assert(localized["Matched because: %s"] ~= english["Matched because: %s"],
        locale .. " must translate the match-reason format")

    for _, key in ipairs(matchKeys) do
        assert(localized[key] and localized[key] ~= english[key],
            locale .. " must translate " .. key)
    end

    local explanation = string.format(
        localized["Matched because: %s"], localized["Match: achievement"])
    assert(explanation:find(localized["Match: achievement"], 1, true),
        locale .. " match-reason format must retain its argument")
end

print("locale coverage tests passed (zhCN and zhTW match reasons)")

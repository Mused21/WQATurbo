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

local searchKeys = {
    "Search by collectible name or any related achievement, item, quest, tracking, or criterion ID.",
    "Searches all supported expansions by collectible name, primary ID, source item ID, mapped quest ID, tracking quest ID, or nested criterion. The search text is temporary and is not saved to your profile."
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

    for _, key in ipairs(searchKeys) do
        assert(localized[key] and localized[key] ~= english[key],
            locale .. " must translate " .. key)
    end

    local explanation = string.format(
        localized["Matched because: %s"], localized["Match: achievement"])
    assert(explanation:find(localized["Match: achievement"], 1, true),
        locale .. " match-reason format must retain its argument")
end

print("locale coverage tests passed (zhCN and zhTW match reasons)")

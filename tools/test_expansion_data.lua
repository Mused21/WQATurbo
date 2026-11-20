_G.EXPANSION_NAME7 = "Battle for Azeroth"

WQATurbo = {
    data = {}
}

dofile("Data/Expansions/BattleForAzeroth.lua")

local bfa = assert(WQATurbo.data[8], "Battle for Azeroth data was not registered")
local hungryRanishu

for _, achievement in ipairs(bfa.achievements or {}) do
    if achievement.id == 13041 then
        hungryRanishu = achievement
        break
    end
end

assert(hungryRanishu, "Hungry, Hungry Ranishu mapping is missing")
assert(hungryRanishu.name == "Hungry, Hungry Ranishu")
assert(hungryRanishu.criteriaType == "QUEST_SINGLE")
assert(hungryRanishu.criteria == 52798)
assert(hungryRanishu.faction == "Horde")

print("Expansion data regression checks passed (Hungry, Hungry Ranishu).")

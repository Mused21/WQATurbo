---@class WQATurbo
local WQA = WQATurbo

---@alias AreaPoiCriteria
---| { AreaPoiId: integer, MapId: integer}

local criteria = {}
criteria.list = {}
criteria.watched = {}

---@param poi AreaPoiCriteria
---@param rewardType RewardType
---@param emissary boolean?
function criteria:AddReward(poi, rewardType, reward, emissary)
    local poiId = poi.AreaPoiId
    local mapId = poi.MapId

    if not self.list[poiId] then
        self.list[poiId] = {}
    end
    if not self.list[poiId][mapId] then
        self.list[poiId][mapId] = {}
    end

    local l = self.list[poiId][mapId]

    WQA:AddReward(l, rewardType, reward, emissary)
end

function criteria:Check()
    local active = {}
    local new = {}
    local retry = false
    local pending = {}

    for poiId, mapIds in pairs(self.list) do
        for mapId, poi in pairs(mapIds) do
            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapId, poiId)

            if not poiInfo then
                WQA:Debug(poiId, mapId, "Area POI info pending")
                retry = true
            else
                local ready = true
                local sawReward = false

                for k, v in pairs(poi.reward or {}) do
                    sawReward = true

                    if k == "custom" or k == "professionSkillup" or k == "gold" then
                        -- These reward types render without a link.
                    else
                        local rewardCount = 1
                        if k == "achievement" or k == "chance" or k == "azeriteTraits" then
                            rewardCount = math.max(1, #v)
                        end

                        for i = 1, rewardCount do
                            local link = WQA:GetRewardLinkByID(poiId, k, v, i)

                            if not link then
                                WQA:Debug(poiId, k, v, i)
                                ready = false
                                retry = true
                            else
                                WQA:SetRewardLinkByID(poiId, k, v, i, link)
                            end
                        end
                    end
                end

                if not sawReward then
                    WQA:Debug(poiId, poiInfo.name, "Area POI reward pending")
                    ready = false
                    retry = true
                end

                if ready then
                    if not active[poiId] then
                        active[poiId] = {}
                    end
                    active[poiId][mapId] = true

                    if not self.watched[poiId] or not self.watched[poiId][mapId] then
                        if not new[poiId] then
                            new[poiId] = {}
                        end
                        new[poiId][mapId] = true
                    end
                end
            end
            if not (active[poiId] and active[poiId][mapId]) then
                pending["poi:" .. tostring(poiId) .. "@map:" .. tostring(mapId)] = true
            end
        end
    end

    return {
        active = active,
        new = new,
        retry = retry,
        pending = pending
    }
end

WQA.Criterias.AreaPoi = criteria

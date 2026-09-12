local WQA = WQATurbo
local CriteriaType = WQA.Constants.CriteriaType
local RewardType = WQA.Constants.RewardType
local TrackingPolicy = WQA.TrackingPolicy

WQA.Achievements = {}

function WQA.Achievements:Register(achievement, forced, forcedByMe)
    if achievement.criteriaType == CriteriaType.Special then
        return
    end

    local id = achievement.id
    local enabled, always, characterOnly = TrackingPolicy.GetState(
        WQA.db.profile.achievements, id, WQA.playerName)
    if not enabled then
        return
    end
    forced = forced or false
    if always then
        forced = true
    end
    forcedByMe = forcedByMe or characterOnly

    local _, _, _, completed, _, _, _, _, _, _, _, _, wasEarnedByMe = GetAchievementInfo(id)
    if (achievement.notAccountwide and not wasEarnedByMe) or not completed or forced or forcedByMe then
        if achievement.criteriaType == CriteriaType.Achievement then
            self:Register_ACHIEVEMENT(achievement, forced, forcedByMe)
        elseif achievement.criteriaType == CriteriaType.QuestSingle then
            self:Register_QUEST_SINGLE(achievement)
        elseif achievement.criteriaType == CriteriaType.QuestPin then
            self:Register_QUEST_PIN(achievement, forced)
        elseif achievement.criteriaType == CriteriaType.QuestFlag then
            self:Register_QUEST_FLAG(achievement)
        else
            local achievementNumCriteria = GetAchievementNumCriteria(id)

            if achievementNumCriteria > 0 then
                for i = 1, achievementNumCriteria do
                    local _, _, criteriaCompleted, _, _, _, _, questID = GetAchievementCriteriaInfo(id, i)

                    if not criteriaCompleted or forced then
                        if achievement.criteriaType == CriteriaType.Quests then
                            self:Register_QUESTS(achievement, i)
                        elseif achievement.criteriaType == CriteriaType.MissionTable then
                            self:Register_MISSION_TABLE(achievement, i, questID)
                        elseif achievement.criteriaType == CriteriaType.AreaPoi then
                            self:Register_AREA_POI(achievement, i)
                        else
                            if questID then
                                WQA:AddRewardToQuest(questID, RewardType.Achievement, id)
                            else
                                WQA:Debug("Achievement criterion has no questID", id, i)
                            end
                        end
                    end
                end
            else
                if achievement.criteriaType == CriteriaType.Quests then
                    self:Register_QUESTS(achievement, 1)
                end
            end
        end
    end
end

function WQA.Achievements:Register_ACHIEVEMENT(achievement, forced, forcedByMe)
    for _, criteriaAchievement in pairs(achievement.criteria) do
        self:Register(criteriaAchievement, forced, forcedByMe)
    end
end

function WQA.Achievements:Register_QUEST_SINGLE(achievement)
    local id = achievement.id

    if type(achievement.criteria) == "table" then
        for _, questID in pairs(achievement.criteria) do
            WQA:AddRewardToQuest(questID, RewardType.Achievement, id)
        end
    else
        WQA:AddRewardToQuest(achievement.criteria, RewardType.Achievement, id)
    end
end

function WQA.Achievements:Register_QUEST_PIN(achievement, forced)
    local id = achievement.id

    C_QuestLine.RequestQuestLinesForMap(achievement.mapID)
    for i = 1, GetAchievementNumCriteria(id) do
        local _, _, completed, _, _, _, _, questID = GetAchievementCriteriaInfo(id, i)

        if questID and (not completed or forced) then
            if achievement.criteriaInfo[i] then
                for _, questID in pairs(achievement.criteriaInfo[i]) do
                    WQA:AddRewardToQuest(questID, RewardType.Achievement, id)
                    WQA.questPinMapList[achievement.mapID] = true
                    WQA.questPinList[questID] = true
                end
            else
                WQA:AddRewardToQuest(questID, RewardType.Achievement, id)
                WQA.questPinMapList[achievement.mapID] = true
                WQA.questPinList[questID] = true
            end
        end
    end
end

function WQA.Achievements:Register_QUEST_FLAG(achievement)
    WQA:AddRewardToQuest(achievement.criteria, RewardType.Achievement, achievement.id)
    WQA.questFlagList[achievement.criteria] = true
end

function WQA.Achievements:Register_QUESTS(achievement, index)
    local id = achievement.id

    if type(achievement.criteria[index]) == "table" then
        for _, questID in pairs(achievement.criteria[index]) do
            WQA:AddRewardToQuest(questID, RewardType.Achievement, id)
        end
    else
        local questID = achievement.criteria[index]
        if questID then
            WQA:AddRewardToQuest(questID, RewardType.Achievement, id)
        end
    end
end

function WQA.Achievements:Register_MISSION_TABLE(achievement, index, criteriaQuestId)
    local id = achievement.id

    if achievement.criteria and achievement.criteria[index] then
        if type(achievement.criteria[index]) == "table" then
            for _, questID in pairs(achievement.criteria[index]) do
                WQA:AddRewardToMission(questID, RewardType.Achievement, id)
            end
        else
            local questID = achievement.criteria[index]
            if questID then
                WQA:AddRewardToMission(questID, RewardType.Achievement, id)
            end
        end
    else
        WQA:AddRewardToMission(criteriaQuestId, RewardType.Achievement, id)
    end
end

function WQA.Achievements:Register_AREA_POI(achievement, index)
    local id = achievement.id

    if not achievement.criteria[index].AreaPoiId then
        for _, areaPoi in pairs(achievement.criteria[index]) do
            WQA.Criterias.AreaPoi:AddReward(areaPoi, RewardType.Achievement, id)
        end
    else
        local areaPoi = achievement.criteria[index]
        if areaPoi then
            WQA.Criterias.AreaPoi:AddReward(areaPoi, RewardType.Achievement, id)
        end
    end
end

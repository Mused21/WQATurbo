---@class WQATurbo
local WQA = WQATurbo
local TaskType = WQA.Constants.TaskType

local L = WQA.L
local LibQTip = LibStub("LibQTip-1.0")

---Release the exact LibQTip instance currently owned by WQA.
---@param tooltip table?
---@return boolean released
function WQA:ReleaseQTip(tooltip)
    if not tooltip or self.tooltip ~= tooltip then
        return false
    end

    -- Detach shared references before Release(), which may synchronously run
    -- the tooltip's OnHide script or other UI callbacks.
    self.tooltip = nil

    if self.PopUp and self.PopUp.tooltip == tooltip then
        self.PopUp.tooltip = nil
    end

    tooltip.quests = nil
    tooltip.missions = nil
    tooltip.pois = nil
    LibQTip:Release(tooltip)
    return true
end

---Release the current owned QTip and rebuild the requested display.
---@param mode string
---@param tasks table?
---@return boolean rebuilt
function WQA:RebuildQTip(mode, tasks)
    if mode ~= "popup" and mode ~= "LDB" then
        return false
    end

    local tooltip = self.tooltip

    if tooltip and not self:ReleaseQTip(tooltip) then
        return false
    end

    if mode == "popup" then
        self:AnnouncePopUp(tasks or self.activeTasks or {})
    else
        self:Show("LDB")
    end

    return true
end


function WQA:CreateQTip()
    if not LibQTip:IsAcquired("WQATurbo") and not self.tooltip then
        local tooltip = LibQTip:Acquire("WQATurbo", 2, "LEFT", "LEFT")
        self.tooltip = tooltip

        tooltip:SetScript("OnHide", function()
            if WQA.tooltip ~= tooltip then
                return
            end

            if WQA.PopUp then
                WQA.PopUp:Hide()
            end
        end)

        if self.db.profile.options.popupShowExpansion or self.db.profile.options.popupShowZone then
            tooltip:AddColumn()
        end
        if self.db.profile.options.popupShowTime then
            tooltip:AddColumn()
        end

        tooltip:AddHeader(_G.WORLD_QUEST_BANNER)
        tooltip:SetCell(1, tooltip:GetColumnCount(), _G.REWARDS)
        tooltip:SetFrameStrata("MEDIUM")
        tooltip:SetFrameLevel(100)
        tooltip:AddSeparator()
    end
end

---@param questID number
local function GetIconTexture(questID)
    local texture = select(2, GetQuestLogRewardInfo(1, questID))
    if texture then
        return texture
    end

    local currencyInfo = C_QuestLog.GetQuestRewardCurrencyInfo(questID, 1, false)
    if currencyInfo then
        return currencyInfo.texture
    end

    return [[Interface\GossipFrame\auctioneerGossipIcon]]
end

-- Keep both the persistent popup and the minimap hover tooltip at a
-- comfortable maximum height. LibQTip only enables scrolling when needed.
function WQA:ApplyQTipScrolling(tooltip)
    if not tooltip then
        return
    end

    local maxTooltipHeight = math.max(240, UIParent:GetHeight() * 0.60)
    tooltip:UpdateScrolling(maxTooltipHeight)
end

-- Rebuild whichever WQA display the user is currently interacting with.
-- Expansion headers use this after changing their collapsed state.
function WQA:RefreshVisibleQTip()
    if self.PopUp and self.PopUp.shown then
        return self:RebuildQTip("popup", self.activeTasks or {})
    end

    return self:RebuildQTip("LDB")
end

local function IsTaskAttached(tooltip, task)
    if task.type == TaskType.WorldQuest then
        return tooltip.quests[task.id] == true
    elseif task.type == TaskType.Mission then
        return tooltip.missions[task.id] == true
    elseif task.type == TaskType.AreaPoi then
        local maps = tooltip.pois[task.id]
        return type(maps) == "table" and maps[task.mapId] == true
    end

    return false
end

local function AttachTask(tooltip, task)
    if task.type == TaskType.WorldQuest then
        tooltip.quests[task.id] = true
    elseif task.type == TaskType.Mission then
        tooltip.missions[task.id] = true
    elseif task.type == TaskType.AreaPoi then
        if type(tooltip.pois[task.id]) ~= "table" then
            tooltip.pois[task.id] = {}
        end
        tooltip.pois[task.id][task.mapId] = true
    end
end

function WQA:UpdateQTip(tasks)
    local tooltip = self.tooltip
    if next(tasks) == nil then
        tooltip:AddLine(L["NO_QUESTS"])
    else
        tooltip.quests = tooltip.quests or {}
        tooltip.missions = tooltip.missions or {}
        tooltip.pois = tooltip.pois or {}

        local i = tooltip:GetLineCount()
        local expansion, zoneID
        for _, task in ipairs(tasks) do
            local id = task.id
            if not IsTaskAttached(tooltip, task) then
                local j = 1

                local expansionCollapsed = false

                if self.db.profile.options.popupShowExpansion then
                    j = 2
                    local taskExpansion = self:GetExpansion(task)

                    if taskExpansion ~= expansion then
                        expansion = taskExpansion
                        expansionCollapsed =
                            self.db.profile.options.popupCollapsedExpansions[expansion] == true

                        local collapseMarker = expansionCollapsed and "[+] " or "[-] "
                        local headerLine = tooltip:AddLine()
                        i = i + 1

                        tooltip:SetCell(
                            headerLine,
                            1,
                            string.format(
                                "|cff33ff33%s%s|r",
                                collapseMarker,
                                self:GetExpansionName(expansion)
                            ),
                            nil,
                            "LEFT",
                            tooltip:GetColumnCount()
                        )

                        local headerExpansion = expansion

                        tooltip:SetLineScript(
                            headerLine,
                            "OnMouseDown",
                            function()
                                local collapsed =
                                    WQA.db.profile.options.popupCollapsedExpansions

                                collapsed[headerExpansion] =
                                    not collapsed[headerExpansion]

                                -- Do not release/reacquire LibQTip inside its own
                                -- click callback. Rebuild on the next frame.
                                C_Timer.After(
                                    0,
                                    function()
                                        if WQA.RefreshVisibleQTip then
                                            WQA:RefreshVisibleQTip()
                                        end
                                    end
                                )
                            end
                        )

                        zoneID = nil
                    else
                        expansionCollapsed =
                            self.db.profile.options.popupCollapsedExpansions[expansion] == true
                    end
                end

                if not expansionCollapsed then
                    tooltip:AddLine()
                i = i + 1

                if self.db.profile.options.popupShowZone then
                    j = 2
                    if self:GetTaskZoneID(task) ~= zoneID then
                        zoneID = self:GetTaskZoneID(task)
                        tooltip:SetCell(i, 1, "     " .. self:GetTaskZoneName(task))
                    end
                end

                if self.db.profile.options.popupShowTime then
                    tooltip:SetCell(i, j, self:formatTime(self:GetTaskTime(task)))
                    j = j + 1
                end

                AttachTask(tooltip, task)

                local link = self:GetTaskLink(task)
                tooltip:SetCell(i, j, link)

                tooltip:SetCellScript(
                    i,
                    j,
                    "OnEnter",
                    function(self)
                        GameTooltip_SetDefaultAnchor(GameTooltip, self)
                        GameTooltip:ClearLines()
                        GameTooltip:ClearAllPoints()
                        GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 0)
                        if task.type == TaskType.WorldQuest then
                            if string.find(link, "|Hquest:") then
                                GameTooltip:SetHyperlink(link)
                            end
                        elseif task.type == TaskType.Mission then
                            GameTooltip:SetText(C_Garrison.GetMissionName(id))
                            GameTooltip:AddLine(
                                string.format(GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS,
                                    C_Garrison.GetMissionMaxFollowers(id)),
                                1,
                                1,
                                1
                            )
                            GarrisonMissionButton_AddThreatsToTooltip(
                                id,
                                WQA.missionList[task.id].followerType,
                                false,
                                C_Garrison.GetFollowerAbilityCountersForMechanicTypes(WQA.missionList[task.id]
                                    .followerType)
                            )
                            GameTooltip:AddLine(GARRISON_MISSION_AVAILABILITY)
                            GameTooltip:AddLine(WQA.missionList[task.id].offerTimeRemaining, 1, 1, 1)
                            if not C_Garrison.IsPlayerInGarrison(WQA.missionList[task.id].followerType) then
                                GameTooltip:AddLine(" ")
                                GameTooltip:AddLine(
                                    GarrisonFollowerOptions[WQA.missionList[task.id].followerType].strings
                                    .RETURN_TO_START,
                                    nil,
                                    nil,
                                    nil,
                                    1
                                )
                            end
                        elseif task.type == TaskType.AreaPoi then
                            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(task.mapId, task.id)
                                or { name = "POI " .. tostring(task.id), areaPoiID = task.id }

                            GameTooltip_SetTitle(GameTooltip, poiInfo.name, HIGHLIGHT_FONT_COLOR)

                            if poiInfo.description then
                                GameTooltip_AddNormalLine(GameTooltip, poiInfo.description)
                            end

                            if C_AreaPoiInfo.IsAreaPOITimed(poiInfo.areaPoiID) then
                                local secondsLeft = C_AreaPoiInfo.GetAreaPOISecondsLeft(poiInfo.areaPoiID)
                                if secondsLeft and secondsLeft > 0 then
                                    local timeString = SecondsToTime(secondsLeft)
                                    GameTooltip_AddNormalLine(GameTooltip, BONUS_OBJECTIVE_TIME_LEFT:format(timeString))
                                end
                            end

                            if poiInfo.textureKit == "OribosGreatVault" then
                                GameTooltip_AddBlankLineToTooltip(GameTooltip)
                                GameTooltip_AddInstructionLine(GameTooltip, ORIBOS_GREAT_VAULT_POI_TOOLTIP_INSTRUCTIONS)
                            end

                            if poiInfo.widgetSetID then
                                GameTooltip_AddWidgetSet(GameTooltip, poiInfo.widgetSetID, 10)
                            end

                            if poiInfo.textureKit then
                                local backdropStyle = GAME_TOOLTIP_TEXTUREKIT_BACKDROP_STYLES[poiInfo.textureKit]
                                if (backdropStyle) then
                                    SharedTooltip_SetBackdropStyle(GameTooltip, backdropStyle)
                                end
                            end
                        end
                        local matchReason = WQA:GetTaskMatchReasonText(task)
                        if matchReason then
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddLine(matchReason, 0.35, 0.8, 1, true)
                        end
                        GameTooltip:Show()
                    end
                )
                tooltip:SetCellScript(
                    i,
                    j,
                    "OnLeave",
                    function()
                        GameTooltip:Hide()
                    end
                )
                tooltip:SetCellScript(
                    i,
                    j,
                    "OnMouseDown",
                    function()
                        if ChatEdit_TryInsertChatLink(link) ~= true then
                            if
                                task.type == TaskType.WorldQuest and not WQA.questList[id].isEmissary and
                                not (WQA.questList[id].isCalling and WQA:IsCallingActive(id)) and
                                not (self.questPinList[id] or self.questFlagList[id])
                            then
                                if WorldQuestTrackerAddon and self.db.profile.options.WorldQuestTracker then
                                    if WorldQuestTrackerAddon.IsQuestBeingTracked(id) then
                                        WorldQuestTrackerAddon.RemoveQuestFromTracker(id)
                                        WQA:ScheduleTimer(
                                            function()
                                                WorldQuestTrackerAddon:FullTrackerUpdate()
                                            end,
                                            .5
                                        )
                                    else
                                        local _, _, numObjectives = GetTaskInfo(id)
                                        local widget = {
                                            questID = id,
                                            mapID = self:GetQuestZoneID(id),
                                            numObjectives = numObjectives
                                        }
                                        zoneID = self:GetQuestZoneID(id)
                                        local x, y = C_TaskQuest.GetQuestLocation(id, zoneID)
                                        widget.questX, widget.questY = x or 0, y or 0
                                        widget.IconTexture = GetIconTexture(id)
                                        local function f(widget)
                                            if not widget.IconTexture then
                                                WQA:ScheduleTimer(
                                                    function()
                                                        widget.IconTexture = GetIconTexture(id)
                                                        f(widget)
                                                    end,
                                                    1.5
                                                )
                                            else
                                                WorldQuestTrackerAddon.AddQuestToTracker(widget)
                                                WQA:ScheduleTimer(
                                                    function()
                                                        WorldQuestTrackerAddon:FullTrackerUpdate()
                                                    end,
                                                    .5
                                                )
                                            end
                                        end
                                        f(widget)
                                    end
                                else
                                    if not C_QuestLog.AddWorldQuestWatch(id, 1) then
                                        C_QuestLog.RemoveWorldQuestWatch(id)
                                    end
                                end
                            end
                        end
                    end
                )

                local list
                if task.type == TaskType.WorldQuest then
                    list = WQA.questList[id].reward
                elseif task.type == TaskType.Mission then
                    list = WQA.missionList[id].reward
                elseif task.type == TaskType.AreaPoi then
                    list = WQA.Criterias.AreaPoi.list[task.id][task.mapId].reward
                end

                local more = false
                for k, v in pairs(list) do
                    for n = 1, 3 do
                        if n == 1 or (n > 1 and (
                            k == "achievement"
                            or k == "chance"
                            or k == "azeriteTraits"
                            or k == "worldBossTransmog"
                        )) then
                            local text = self:GetRewardTextByID(id, k, v, n, task.type)
                            if text then
                                j = j + 1

                                if j > tooltip:GetColumnCount() then
                                    tooltip:AddColumn()
                                end
                                tooltip:SetCell(i, j, text)

                                tooltip:SetCellScript(
                                    i,
                                    j,
                                    "OnEnter",
                                    function(self)
                                        GameTooltip:SetOwner(self, "ANCHOR_NONE")
                                        GameTooltip:ClearLines()
                                        ContainerFrameItemButton_CalculateItemTooltipAnchors(self, GameTooltip)

                                        if WQA:GetRewardLinkByID(id, k, v, n) then
                                            GameTooltip:SetHyperlink(WQA:GetRewardLinkByID(id, k, v, n))
                                        else
                                            GameTooltip:SetText(WQA:GetRewardTextByID(id, k, v, n, task.type))
                                        end
                                        GameTooltip:Show()
                                        if (IsModifiedClick("COMPAREITEMS") or GetCVarBool("alwaysCompareItems"))
                                            and (k == "item" or k == "worldBossTransmog")
                                        then
                                            GameTooltip_ShowCompareItem()
                                        else
                                            GameTooltip_HideShoppingTooltips(GameTooltip)
                                        end
                                    end
                                )
                                tooltip:SetCellScript(
                                    i,
                                    j,
                                    "OnLeave",
                                    function()
                                        GameTooltip_HideResetCursor()
                                    end
                                )
                                tooltip:SetCellScript(
                                    i,
                                    j,
                                    "OnMouseDown",
                                    function()
                                        HandleModifiedItemClick(WQA:GetRewardLinkByID(id, k, v, n))
                                    end
                                )
                                if n == 3 then
                                    local m = 4
                                    if self:GetRewardTextByID(id, k, v, m, task.type) then
                                        j = j + 1
                                        if j > tooltip:GetColumnCount() then
                                            tooltip:AddColumn()
                                        end
                                        tooltip:SetCell(i, j, "...")
                                        local moreTooltipText = ""
                                        while self:GetRewardTextByID(id, k, v, m, task.type) do
                                            if m == 4 then
                                                moreTooltipText = moreTooltipText ..
                                                    self:GetRewardTextByID(id, k, v, m, task.type)
                                            else
                                                moreTooltipText = moreTooltipText ..
                                                    "\n" .. self:GetRewardTextByID(id, k, v, m, task.type)
                                            end
                                            m = m + 1
                                        end

                                        tooltip:SetCellScript(
                                            i,
                                            j,
                                            "OnEnter",
                                            function(self)
                                                GameTooltip_SetDefaultAnchor(GameTooltip, self)
                                                GameTooltip:ClearLines()
                                                GameTooltip:ClearAllPoints()
                                                GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 0)
                                                GameTooltip:SetText(moreTooltipText)
                                                GameTooltip:Show()
                                            end
                                        )
                                        tooltip:SetCellScript(
                                            i,
                                            j,
                                            "OnLeave",
                                            function()
                                                GameTooltip:Hide()
                                            end
                                        )
                                    end
                                end
                            end
                        end
                    end
                end
                end -- if not expansionCollapsed
            end
        end
    end
    tooltip:Show()
end

function WQA:AnnouncePopUp(quests, silent)
    if not self.PopUp then
        local PopUp = CreateFrame("Frame", "WQAchievementsPopUp", UIParent, "UIPanelDialogTemplate")
        if self.db.profile.options.esc then
            tinsert(UISpecialFrames, "WQAchievementsPopUp")
        end
        self.PopUp = PopUp
        PopUp:SetMovable(true)
        PopUp:SetClampedToScreen(true)
        PopUp:EnableMouse(true)
        PopUp:RegisterForDrag("LeftButton")
        PopUp:SetScript(
            "OnDragStart",
            function(self)
                self.moving = true
                self:StartMoving()
            end
        )
        PopUp:SetScript(
            "OnDragStop",
            function(self)
                self.moving = nil
                self:StopMovingOrSizing()
                if WQA.db.profile.options.popupRememberPosition then
                    WQA.db.profile.options.popupX = self:GetLeft()
                    WQA.db.profile.options.popupY = self:GetTop()
                end
            end
        )
        PopUp:SetWidth(300)
        PopUp:SetHeight(100)
        PopUp:SetPoint("CENTER") --, self.db.profile.options.popupX, self.db.profile.options.popupY)
        --PopUp:SetPoint("TOPLEFT", self.db.profile.options.popupX, self.db.profile.options.popupY)
        PopUp:Hide()

        PopUp:SetScript(
            "OnHide",
            function()
                local tooltip = PopUp.tooltip
                PopUp.tooltip = nil
                WQA:ReleaseQTip(tooltip)

                PopUp.shown = false
            end
        )
    end
    if next(quests) == nil and silent == true then
        return
    end
    local PopUp = self.PopUp
    PopUp:Show()
    PopUp.shown = true
    self:CreateQTip()
    local tooltip = self.tooltip
    PopUp.tooltip = tooltip
    tooltip:SetAutoHideDelay()
    tooltip:ClearAllPoints()
    tooltip:SetPoint("TOP", PopUp, "TOP", 2, -27)
    self:UpdateQTip(quests)

    self:ApplyQTipScrolling(tooltip)

    PopUp:SetWidth(tooltip:GetWidth() + 8.5)
    PopUp:SetHeight(tooltip:GetHeight() + 32)
    PopUp:SetScale(tooltip:GetScale())
    if (PopUp:GetEffectiveScale() ~= tooltip:GetEffectiveScale()) then
        PopUp:SetScale(PopUp:GetScale() * tooltip:GetEffectiveScale() / PopUp:GetEffectiveScale())
    end
    PopUp:SetFrameLevel(tooltip:GetFrameLevel())

    if self.db.profile.options.popupRememberPosition then
        PopUp:ClearAllPoints()
        PopUp:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.options.popupX, self.db.profile.options.popupY)
    end
end

function WQA:SortByZoneName(a, b)
    if a.type == TaskType.Mission and b.type ~= TaskType.Mission then
        return false
    elseif b.type == TaskType.Mission and a.type ~= TaskType.Mission then
        return true
    elseif a.type == TaskType.Mission and b.type == TaskType.Mission then
        return self:GetTaskZoneName(a) < self:GetTaskZoneName(b)
    end

    if a.type == TaskType.WorldQuest and WQA.questList[a.id].isEmissary ~= nil then
        if b.type == TaskType.WorldQuest and WQA.questList[b.id].isEmissary ~= nil then
            return false
        else
            return true
        end
    elseif b.type == TaskType.WorldQuest and WQA.questList[b.id].isEmissary ~= nil then
        return false
    end

    return self:GetTaskZoneName(a) < self:GetTaskZoneName(b)
end

function WQA:SortByExpansion(a, b)
    a = self:GetExpansion(a)

    b = self:GetExpansion(b)
    --returnself:GetExpansion(a) >self:GetExpansion(b)
    return a > b
end

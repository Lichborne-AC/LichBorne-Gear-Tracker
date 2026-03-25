-- ============================================================
--  Helpers.lua  |  Shared row, tab, and UI helper functions
-- ============================================================

classSortMode = nil
allSortMenus = {}
activeInviteFrame = nil

function MigrateGearField()
    if not LichborneTrackerDB or not LichborneTrackerDB.rows then return end
    for _, row in ipairs(LichborneTrackerDB.rows) do
        if row.gear and not row.ilvl then
            row.ilvl = row.gear
            row.gear = nil
        end
        if not row.ilvl then
            local gearLevels = {}
            for i = 1, 17 do gearLevels[i] = 0 end
            row.ilvl = gearLevels
        end
        if not row.ilvlLink then
            local itemLinks = {}
            for i = 1, 17 do itemLinks[i] = "" end
            row.ilvlLink = itemLinks
        end
        if row.realGs == nil then row.realGs = 0 end
    end
end

function DefaultRow(cls)
    local gearLevels = {}
    for i = 1, GEAR_SLOTS do gearLevels[i] = 0 end
    local itemLinks = {}
    for i = 1, GEAR_SLOTS do itemLinks[i] = "" end
    return {cls = cls or "", name = "", ilvl = gearLevels, ilvlLink = itemLinks, gs = 0, realGs = 0, spec = ""}
end

function FindTrackedRowIndexByName(charName)
    if not charName or charName == "" then return nil end
    local needle = charName:lower()
    for i, row in ipairs(LichborneTrackerDB.rows or {}) do
        if row.name and row.name ~= "" and row.name:lower() == needle then
            return i, row
        end
    end
    return nil
end

function RemoveCharacterReferences(charName)
    if not charName or charName == "" then return false end

    local removed = false
    local rowIndex, rowData = FindTrackedRowIndexByName(charName)
    if rowIndex and rowData then
        LichborneTrackerDB.rows[rowIndex] = DefaultRow(rowData.cls)
        removed = true
    end

    if LichborneTrackerDB.needs then
        LichborneTrackerDB.needs[charName:lower()] = nil
    end

    if LichborneTrackerDB.raidRosters then
        for _, roster in pairs(LichborneTrackerDB.raidRosters) do
            if type(roster) == "table" then
                for i, slot in ipairs(roster) do
                    if slot and slot.name and slot.name ~= "" and slot.name:lower() == charName:lower() then
                        roster[i] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""}
                    end
                end
            end
        end
    end

    return removed
end

function EnsureClass(cls)
    if cls == "Raid" or cls == "All" then return end
    local count = 0
    for _, row in ipairs(LichborneTrackerDB.rows) do
        if row.cls == cls then count = count + 1 end
    end
    while count < MAX_ROWS * MAX_PAGES do
        table.insert(LichborneTrackerDB.rows, DefaultRow(cls))
        count = count + 1
    end
end

function GetAllClassRows(cls)
    local out = {}
    if cls == "Raid" or cls == "All" then return out end
    for i, row in ipairs(LichborneTrackerDB.rows) do
        if row.cls == cls then out[#out + 1] = i end
    end
    return out
end

function GetClassRows(cls)
    local out = {}
    if cls == "Raid" or cls == "All" then return out end

    local page = classPage[cls] or 1
    local startIdx = (page - 1) * ROWS_PER_PAGE + 1
    local endIdx = page * ROWS_PER_PAGE
    local count = 0
    local allIdx = {}

    for i, row in ipairs(LichborneTrackerDB.rows) do
        if row.cls == cls then
            allIdx[#allIdx + 1] = i
        end
    end

    if classSortMode == "name" then
        table.sort(allIdx, function(a, b)
            local rowA, rowB = LichborneTrackerDB.rows[a], LichborneTrackerDB.rows[b]
            local nameA, nameB = rowA.name or "", rowB.name or ""
            if (nameA == "") ~= (nameB == "") then return nameA ~= "" end
            return nameA < nameB
        end)
    elseif classSortMode == "classspec" then
        table.sort(allIdx, function(a, b)
            local rowA, rowB = LichborneTrackerDB.rows[a], LichborneTrackerDB.rows[b]
            local nameA, nameB = rowA.name or "", rowB.name or ""
            if (nameA == "") ~= (nameB == "") then return nameA ~= "" end
            local specA, specB = rowA.spec or "", rowB.spec or ""
            if specA ~= specB then return specA < specB end
            return nameA < nameB
        end)
    elseif classSortMode == "gs" then
        table.sort(allIdx, function(a, b)
            local rowA, rowB = LichborneTrackerDB.rows[a], LichborneTrackerDB.rows[b]
            local nameA, nameB = rowA.name or "", rowB.name or ""
            if (nameA == "") ~= (nameB == "") then return nameA ~= "" end
            local gsA, gsB = rowA.realGs or 0, rowB.realGs or 0
            if gsA ~= gsB then return gsA > gsB end
            return nameA < nameB
        end)
    end

    for _, i in ipairs(allIdx) do
        count = count + 1
        if count >= startIdx and count <= endIdx then
            out[#out + 1] = i
        end
    end

    return out
end

function ApplyTierColor(gb, val)
    local n = tonumber(val) or 0
    local c = TIER_COLORS[n]
    if c then
        gb:SetBackdropColor(c.r, c.g, c.b, 1)
        gb:SetBackdropBorderColor(math.min(c.r * 1.5, 1), math.min(c.g * 1.5, 1), math.min(c.b * 1.5, 1), 1)
        if (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) > 0.45 then
            gb:SetTextColor(0.05, 0.05, 0.05)
        else
            gb:SetTextColor(1, 1, 1)
        end
    else
        gb:SetBackdropColor(0.05, 0.07, 0.14, 1)
        gb:SetBackdropBorderColor(0.12, 0.18, 0.30, 0.8)
        gb:SetTextColor(1, 1, 1)
    end
end

function CloseAllSortMenus()
    for _, menu in ipairs(allSortMenus) do menu:Hide() end
end

function UpdateInviteButtons()
    local tier = (LichborneTrackerDB and LichborneTrackerDB.raidTier) or 0

    if LichborneInviteRaidBtn then
        if tier ~= 0 then LichborneInviteRaidBtn:Show() else LichborneInviteRaidBtn:Hide() end
    end
    if _G["LichborneInviteGroupBtn"] then
        if tier == 0 then _G["LichborneInviteGroupBtn"]:Show() else _G["LichborneInviteGroupBtn"]:Hide() end
    end
    if _G["LichborneStopInviteBtn"] then
        if activeInviteFrame then _G["LichborneStopInviteBtn"]:Show() else _G["LichborneStopInviteBtn"]:Hide() end
    end
end

function UpdateTabs()
    if LichborneSpecMenu then LichborneSpecMenu:Hide() end
    if _G["LichbornePageDDMenu"] then _G["LichbornePageDDMenu"]:Hide() end
    CloseAllSortMenus()
    if _G["LichborneAllGroupMenu"] then _G["LichborneAllGroupMenu"]:Hide() end
    if _G["LichborneRaidTierMenu"] then _G["LichborneRaidTierMenu"]:Hide() end
    if _G["LichborneRaidRaidMenu"] then _G["LichborneRaidRaidMenu"]:Hide() end
    if _G["LichborneRaidGroupMenu"] then _G["LichborneRaidGroupMenu"]:Hide() end

    for cls, btn in pairs(tabButtons) do
        local c = CLASS_COLORS[cls]
        if cls == activeTab then
            btn:SetAlpha(1.0)
            if c then
                btn.bg:SetTexture(c.r * 0.45, c.g * 0.45, c.b * 0.45, 1)
                btn.bottomLine:SetTexture(c.r, c.g, c.b, 1)
            elseif cls == "Raid" then
                btn.bg:SetTexture(0.55, 0.40, 0.05, 1)
                btn.bottomLine:SetTexture(0.78, 0.61, 0.23, 1)
            elseif cls == "All" then
                btn.bg:SetTexture(0.20, 0.45, 0.20, 1)
                btn.bottomLine:SetTexture(0.40, 0.90, 0.40, 1)
            end
        else
            btn:SetAlpha(0.5)
            btn.bg:SetTexture(0.05, 0.07, 0.12, 1)
            btn.bottomLine:SetTexture(0, 0, 0, 0)
        end
    end

    if LichborneRaidFrame then
        local isRaid = activeTab == "Raid"
        local isAll = activeTab == "All"
        if isAll then
            if LichborneAllFrame then LichborneAllFrame:Show() end
            if LichborneRaidFrame then LichborneRaidFrame:Hide() end
            if LichborneHeaderBar then LichborneHeaderBar:Hide() end
            if LichborneAvgBar then LichborneAvgBar:Hide() end
            if LichborneCountBar then LichborneCountBar:Hide() end
            if _G["LichborneRaidCountBar"] then _G["LichborneRaidCountBar"]:Hide() end
            for _, rf in ipairs(rowFrames) do rf:Hide() end
            UpdateInviteButtons()
        elseif isRaid then
            LichborneRaidFrame:Show()
            if LichborneAllFrame then LichborneAllFrame:Hide() end
            if LichborneHeaderBar then LichborneHeaderBar:Hide() end
            if LichborneAvgBar then LichborneAvgBar:Hide() end
            if LichborneCountBar then LichborneCountBar:Hide() end
            for _, rf in ipairs(rowFrames) do rf:Hide() end
            if _G["LichborneRaidCountBar"] then _G["LichborneRaidCountBar"]:Show() end
            UpdateInviteButtons()
        elseif not isAll then
            LichborneRaidFrame:Hide()
            if LichborneAllFrame then LichborneAllFrame:Hide() end
            if LichborneHeaderBar then LichborneHeaderBar:Show() end
            if LichborneAvgBar then LichborneAvgBar:Show() end
            if LichborneCountBar then LichborneCountBar:Show() end
            if _G["LichborneRaidCountBar"] then _G["LichborneRaidCountBar"]:Hide() end
            UpdateInviteButtons()
        end
    end
end

function HookRowHighlight(child, row, hovTex)
    local origEnter = child:GetScript("OnEnter")
    local origLeave = child:GetScript("OnLeave")
    child:SetScript("OnEnter", function()
        hovTex:SetTexture(0.78, 0.61, 0.23, 0.12)
        if origEnter then origEnter() end
    end)
    child:SetScript("OnLeave", function()
        local focus = GetMouseFocus()
        if focus ~= row then
            hovTex:SetTexture(0, 0, 0, 0)
        end
        if origLeave then origLeave() end
    end)
end
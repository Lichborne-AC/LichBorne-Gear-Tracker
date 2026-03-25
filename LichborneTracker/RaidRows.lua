-- ============================================================
--  RaidRows.lua  |  Raid roster sorting and refresh helpers
-- ============================================================

raidSortMode = nil

local function SortRaidRows()
    if not raidSortMode then return end

    local roster = GetCurrentRoster()
    local filled, empty = {}, {}
    for i = 1, MAX_RAID_SLOTS do
        local row = roster[i]
        if row and row.name and row.name ~= "" then
            filled[#filled + 1] = row
        else
            empty[#empty + 1] = {name="", cls="", spec="", gs=0, realGs=0}
        end
    end

    if raidSortMode == "name" then
        table.sort(filled, function(a, b)
            return (a.name or "") < (b.name or "")
        end)
    elseif raidSortMode == "classspec" then
        table.sort(filled, function(a, b)
            if (a.cls or "") ~= (b.cls or "") then return (a.cls or "") < (b.cls or "") end
            if (a.spec or "") ~= (b.spec or "") then return (a.spec or "") < (b.spec or "") end
            return (a.name or "") < (b.name or "")
        end)
    elseif raidSortMode == "gs" then
        table.sort(filled, function(a, b)
            local gearScoreA, gearScoreB = a.realGs or 0, b.realGs or 0
            if gearScoreA ~= gearScoreB then return gearScoreA > gearScoreB end
            return (a.name or "") < (b.name or "")
        end)
    end

    local idx = 1
    for _, row in ipairs(filled) do roster[idx] = row; idx = idx + 1 end
    for _, row in ipairs(empty) do roster[idx] = row; idx = idx + 1 end
end

function RefreshRaidRows()
    if not raidRowFrames or #raidRowFrames == 0 then return end

    raidDragSource = nil

    local classTabNames = {}
    if LichborneTrackerDB.rows then
        for _, classRow in ipairs(LichborneTrackerDB.rows) do
            if classRow.name and classRow.name ~= "" then
                classTabNames[classRow.name:lower()] = true
            end
        end
    end

    local roster = GetCurrentRoster()
    for i = 1, 40 do
        if roster[i] and roster[i].name and roster[i].name ~= "" then
            if not classTabNames[roster[i].name:lower()] then
                roster[i] = {name="", cls="", spec="", gs=0}
            end
        end
    end

    SortRaidRows()

    local rows, raidSize = GetCurrentRoster()
    for i = 1, MAX_RAID_SLOTS do
        local rf = raidRowFrames[i]
        if not rf then break end

        if i > raidSize then rf:Hide() else rf:Show() end
        local data = rows[i] or {name="", cls="", spec="", gs=0, role="", notes=""}

        local classIcon = CLASS_ICONS[data.cls]
        if rf.classIcon then
            if classIcon then rf.classIcon:SetTexture(classIcon); rf.classIcon:SetAlpha(1)
            else rf.classIcon:SetTexture(0,0,0,0) end
        end

        if data.name and data.name ~= "" then
            for _, classRow in ipairs(LichborneTrackerDB.rows) do
                if classRow.name and classRow.name:lower() == data.name:lower() then
                    if classRow.spec and classRow.spec ~= "" then
                        data.spec = classRow.spec
                    end
                    data.realGs = classRow.realGs or 0
                    break
                end
            end
        end

        local specIcon = data.spec and data.spec ~= "" and SPEC_ICONS[data.spec]
        if rf.specIcon then
            if specIcon then
                rf.specIcon:SetTexture(specIcon); rf.specIcon:SetAlpha(1)
            elseif data.name and data.name ~= "" then
                rf.specIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); rf.specIcon:SetAlpha(0.2)
            else
                rf.specIcon:SetTexture(0,0,0,0)
            end
        end

        if rf.needsCell then
            RefreshNeedsCell(rf.needsCell, data.name or "")
        end

        if rf.roleBtn and rf.roleLbl then
            if not data.role then data.role = "" end
            local roleDef = ROLE_BY_KEY[data.role]
            if roleDef then
                rf.roleLbl:SetText("")
                rf.roleBtn:SetBackdropBorderColor(roleDef.color.r, roleDef.color.g, roleDef.color.b, 0.9)
                if rf.roleIcon then rf.roleIcon:SetTexture(roleDef.icon); rf.roleIcon:SetAlpha(1.0) end
            else
                rf.roleLbl:SetText("")
                rf.roleBtn:SetBackdropBorderColor(0.20,0.30,0.50,0.3)
                if rf.roleIcon then rf.roleIcon:SetTexture(0,0,0,0) end
            end
            local idx = i
            rf.roleBtn:SetScript("OnEnter", function()
                local roster2 = GetCurrentRoster()
                local d2 = roster2[idx]
                GameTooltip:SetOwner(rf.roleBtn, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Assign Role  (click to cycle)",1,1,1)
                for _, rdef in ipairs(ROLE_DEFS) do
                    local cur = (d2 and d2.role == rdef.key) and " ◄" or ""
                    GameTooltip:AddLine("|T"..rdef.icon..":14:14|t  "..rdef.key.."  "..rdef.label..cur, rdef.color.r, rdef.color.g, rdef.color.b)
                end
                GameTooltip:AddLine("--  None (clear)", 0.5,0.6,0.7)
                GameTooltip:Show()
            end)
            rf.roleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            rf.roleBtn:SetScript("OnClick", function()
                local roster2 = GetCurrentRoster()
                local d2 = roster2[idx]
                if not d2 or not d2.name or d2.name == "" then return end
                local cur = d2.role or ""
                if cur == "" or cur == nil then
                    d2.role = "TNK"
                elseif cur == "TNK" then
                    d2.role = "HLR"
                elseif cur == "HLR" then
                    d2.role = "DPS"
                else
                    d2.role = ""
                end
                RefreshRaidRows()
            end)
        end

        if rf.notesBox then
            rf.notesBox:SetScript("OnTextChanged", nil)
            rf.notesBox:SetText(data.notes or "")
            local idx = i
            rf.notesBox:SetScript("OnTextChanged", function()
                local roster2 = GetCurrentRoster()
                if roster2[idx] then roster2[idx].notes = rf.notesBox:GetText() end
            end)
        end

        if rf.nameBox then
            rf.nameBox:SetScript("OnTextChanged", nil)
            rf.nameBox:SetText(data.name or "")
            local c = CLASS_COLORS[data.cls]
            if c then rf.nameBox:SetTextColor(c.r, c.g, c.b)
            else rf.nameBox:SetTextColor(0.9, 0.95, 1.0) end
            local idx = i
            rf.nameBox:SetScript("OnTextChanged", function()
                local roster2 = GetCurrentRoster()
                roster2[idx].name = rf.nameBox:GetText()
            end)
        end

        if rf.gsBox then
            rf.gsBox:SetScript("OnTextChanged", nil)
            rf.gsBox:SetText(data.gs and data.gs > 0 and tostring(data.gs) or "")
            local idx = i
            rf.gsBox:SetScript("OnTextChanged", function()
                local raw = rf.gsBox:GetText()
                local clean = raw:gsub("%D", "")
                if clean ~= raw then rf.gsBox:SetText(clean); return end
                local roster2 = GetCurrentRoster()
                roster2[idx].gs = tonumber(clean) or 0
            end)
        end

        if rf.realGsBox then
            rf.realGsBox:SetScript("OnTextChanged", nil)
            rf.realGsBox:SetText(data.realGs and data.realGs > 0 and tostring(data.realGs) or "")
            local idx = i
            rf.realGsBox:SetScript("OnTextChanged", function()
                local raw = rf.realGsBox:GetText()
                local clean = raw:gsub("%D", "")
                if clean ~= raw then rf.realGsBox:SetText(clean); return end
                local roster2 = GetCurrentRoster()
                roster2[idx].realGs = tonumber(clean) or 0
            end)
        end

        if rf.specBtn then
            local rowIdx = i
            rf.specBtn:SetScript("OnEnter", function()
                local roster2 = GetCurrentRoster()
                local d2 = roster2[rowIdx]
                local spec = d2 and d2.spec or ""
                local cls = d2 and d2.cls or ""
                local c = cls ~= "" and CLASS_COLORS[cls]
                GameTooltip:SetOwner(rf.specBtn, "ANCHOR_RIGHT")
                if spec ~= "" then GameTooltip:AddLine(spec, 1, 1, 1) end
                if cls ~= "" then
                    if c then GameTooltip:AddLine(cls, c.r, c.g, c.b)
                    else GameTooltip:AddLine(cls, 0.8, 0.8, 0.9) end
                end
                if spec == "" and cls == "" then GameTooltip:AddLine("Empty", 0.4, 0.4, 0.4) end
                GameTooltip:Show()
            end)
            rf.specBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end

        if rf.delBtn then
            local idx = i
            rf.delBtn:SetScript("OnClick", function()
                local roster2 = GetCurrentRoster()
                roster2[idx] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""}
                RefreshRaidRows()
            end)
        end
    end

    if LichborneRaidCountLabels then
        local raidCounts = {}
        for _, cls in ipairs(CLASS_TABS) do if cls ~= "Raid" then raidCounts[cls] = 0 end end
        local roster2, size2 = GetCurrentRoster()
        for i = 1, size2 do
            local row = roster2[i]
            if row and row.name and row.name ~= "" and raidCounts[row.cls] then
                raidCounts[row.cls] = raidCounts[row.cls] + 1
            end
        end
        for cls, lbl in pairs(LichborneRaidCountLabels) do
            local c = CLASS_COLORS[cls]
            if c then
                local hex = string.format("|cff%02x%02x%02x", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
                local n = raidCounts[cls] or 0
                lbl:SetText(hex .. (TAB_LABELS[cls]) .. ": |cffd4af37" .. n .. "|r")
                local sw = lbl:GetParent()
                if sw and sw.bg then
                    if n > 0 then sw.bg:SetTexture(c.r * 0.25, c.g * 0.25, c.b * 0.30, 1)
                    else sw.bg:SetTexture(0.08, 0.10, 0.18, 1) end
                end
            end
        end
    end
end
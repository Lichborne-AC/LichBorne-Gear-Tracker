-- ============================================================
--  NeedsUI.lua  |  Needs picker and cell UI helpers
-- ============================================================

needsPicker = nil
needsPickerOwner = nil
needsCellFrames = {}
MAX_NEEDS_DISPLAY = MAX_NEEDS

function RefreshNeedsCell(cf, charName)
    if not cf or not cf.icons then return end
    local needs = GetNeeds(charName)
    local active = {}
    for _, slot in ipairs(NEEDS_SLOTS) do
        if needs[slot.key] then active[#active + 1] = slot end
    end
    local show = math.min(#active, MAX_NEEDS_DISPLAY)
    for idx = 1, show do
        local icon = cf.icons[idx]
        if icon then icon:SetTexture(active[idx].icon); icon:SetAlpha(1); icon:Show() end
    end
    for idx = show + 1, MAX_NEEDS_DISPLAY do
        if cf.icons[idx] then cf.icons[idx]:Hide() end
    end
end

function RefreshAllNeedsCells()
    for _, entry in ipairs(needsCellFrames) do
        if entry.frame and entry.getCharName then
            RefreshNeedsCell(entry.frame, entry.getCharName())
        end
    end
end

function ClosePicker()
    if needsPicker then needsPicker:Hide() end
    needsPickerOwner = nil
end

function BuildPickerIfNeeded()
    if needsPicker then return end

    local cols, buttonSize, pad = 5, 26, 4
    local rows = math.ceil(#NEEDS_SLOTS / cols)
    local width = cols * (buttonSize + pad) + pad
    local height = rows * (buttonSize + pad) + pad + 20
    local picker = CreateFrame("Frame", "LichborneNeedsPicker", UIParent)

    picker:SetFrameStrata("TOOLTIP")
    picker:SetFrameLevel(200)
    picker:SetSize(width, height)
    picker:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    picker:SetBackdropColor(0.04,0.06,0.12,0.98)
    picker:SetBackdropBorderColor(0.78,0.61,0.23,1)

    local title = picker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", picker, "TOPLEFT", 6, -5)
    picker.title = title
    picker.slotBtns = {}

    for slotIndex, slot in ipairs(NEEDS_SLOTS) do
        local col = (slotIndex - 1) % cols
        local row = math.floor((slotIndex - 1) / cols)
        local btn = CreateFrame("Button", nil, picker)
        btn:SetSize(buttonSize, buttonSize)
        btn:SetPoint("TOPLEFT", picker, "TOPLEFT", pad + col * (buttonSize + pad), -20 - pad - row * (buttonSize + pad))
        btn:SetFrameLevel(picker:GetFrameLevel() + 1)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(btn)
        bg:SetTexture(0.08,0.10,0.18,1)

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("CENTER", btn, "CENTER", 0, 0)
        tex:SetSize(buttonSize - 4, buttonSize - 4)
        tex:SetTexture(slot.icon)
        btn.tex = tex

        local hi = btn:CreateTexture(nil, "OVERLAY")
        hi:SetAllPoints(btn)
        hi:SetTexture(0.3,0.8,0.3,0.35)
        hi:Hide()
        btn.hi = hi

        btn:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=6,insets={left=1,right=1,top=1,bottom=1}})
        btn:SetBackdropColor(0.08,0.10,0.18,1)
        btn:SetBackdropBorderColor(0.25,0.35,0.55,0.8)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        btn.slotKey = slot.key
        btn.slotLabel = slot.label
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        btn:SetScript("OnEnter", function()
            if picker.title then
                local owned = needsPickerOwner and GetNeeds(needsPickerOwner)[slot.key]
                local hint = owned and "|cffff6666  (right-click to remove)|r" or "|cff66ff66  click to mark|r"
                picker.title:SetText("|cffC69B3A" .. slot.label .. "|r" .. hint)
            end
        end)

        btn:SetScript("OnLeave", function()
            if picker.title and needsPickerOwner then
                picker.title:SetText("|cffC69B3ANeeds: |r|cffffff00" .. needsPickerOwner .. "|r")
            end
        end)

        btn:SetScript("OnClick", function()
            if not needsPickerOwner or needsPickerOwner == "" then return end
            local current = GetNeeds(needsPickerOwner)[slot.key]
            if arg1 == "RightButton" then
                SetNeed(needsPickerOwner, slot.key, false)
            else
                SetNeed(needsPickerOwner, slot.key, not current)
            end

            local needs = GetNeeds(needsPickerOwner)
            local count = 0
            for _ in pairs(needs) do count = count + 1 end

            for _, slotBtn in ipairs(picker.slotBtns) do
                if needs[slotBtn.slotKey] then
                    slotBtn.hi:Show()
                    slotBtn:SetBackdropBorderColor(0.3,0.8,0.3,0.9)
                    slotBtn.tex:SetAlpha(1)
                elseif count >= MAX_NEEDS then
                    slotBtn.hi:Hide()
                    slotBtn:SetBackdropBorderColor(0.15,0.15,0.15,0.5)
                    slotBtn.tex:SetAlpha(0.35)
                else
                    slotBtn.hi:Hide()
                    slotBtn:SetBackdropBorderColor(0.25,0.35,0.55,0.8)
                    slotBtn.tex:SetAlpha(1)
                end
            end

            RefreshAllNeedsCells()
        end)

        picker.slotBtns[slotIndex] = btn
    end

    picker.closeTimer = 0
    picker:SetScript("OnUpdate", function()
        if not picker:IsShown() then return end
        if not MouseIsOver(picker) then
            picker.closeTimer = (picker.closeTimer or 0) + arg1
            if picker.closeTimer > 0.3 then
                ClosePicker()
            end
        else
            picker.closeTimer = 0
        end
    end)

    picker:SetScript("OnKeyDown", function()
        if arg1 == "ESCAPE" then ClosePicker() end
    end)
    picker:EnableKeyboard(true)

    needsPicker = picker
end

function OpenNeedsPicker(anchorFrame, charName)
    if not charName or charName == "" then return end
    BuildPickerIfNeeded()
    needsPickerOwner = charName
    needsPicker.title:SetText("|cffC69B3ANeeds: |r|cffffff00" .. charName .. "|r")

    local needs = GetNeeds(charName)
    local count = 0
    for _ in pairs(needs) do count = count + 1 end

    for _, slotBtn in ipairs(needsPicker.slotBtns) do
        if needs[slotBtn.slotKey] then
            slotBtn.hi:Show()
            slotBtn:SetBackdropBorderColor(0.3,0.8,0.3,0.9)
            slotBtn.tex:SetAlpha(1)
        elseif count >= MAX_NEEDS then
            slotBtn.hi:Hide()
            slotBtn:SetBackdropBorderColor(0.15,0.15,0.15,0.5)
            slotBtn.tex:SetAlpha(0.35)
        else
            slotBtn.hi:Hide()
            slotBtn:SetBackdropBorderColor(0.25,0.35,0.55,0.8)
            slotBtn.tex:SetAlpha(1)
        end
    end

    needsPicker:ClearAllPoints()
    needsPicker:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -2)
    needsPicker.closeTimer = 0
    needsPicker:Show()
    needsPicker:Raise()
end

function MakeNeedsCell(parent, xOff, rowH, getCharName, hovTex, overrideW)
    local cellW = overrideW or 80
    local cell = CreateFrame("Button", nil, parent)
    cell:SetPoint("LEFT", parent, "LEFT", xOff, 0)
    cell:SetSize(cellW, rowH - 2)
    cell:SetFrameLevel(parent:GetFrameLevel() + 4)
    cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    cell:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
    cell:SetBackdropColor(0.04,0.06,0.12,0.9)
    cell:SetBackdropBorderColor(0.15,0.22,0.38,0.6)
    cell.icons = {}

    for iconIndex = 1, MAX_NEEDS_DISPLAY do
        local icon = cell:CreateTexture(nil, "ARTWORK")
        icon:SetSize(NEEDS_ICON_SIZE, NEEDS_ICON_SIZE)
        icon:SetPoint("LEFT", cell, "LEFT", 2 + (iconIndex - 1) * (NEEDS_ICON_SIZE + 2), 0)
        icon:Hide()
        cell.icons[iconIndex] = icon
    end

    cell:SetScript("OnClick", function()
        local charName = getCharName()
        if not charName or charName == "" then return end
        if arg1 == "RightButton" then
            if LichborneTrackerDB.needs then LichborneTrackerDB.needs[charName:lower()] = {} end
            RefreshAllNeedsCells()
            ClosePicker()
            return
        end
        if needsPicker and needsPicker:IsShown() and needsPickerOwner == charName then
            ClosePicker()
        else
            ClosePicker()
            OpenNeedsPicker(cell, charName)
        end
    end)

    cell:SetScript("OnEnter", function()
        if hovTex then hovTex:SetTexture(0.78,0.61,0.23,0.12) end
        cell:SetBackdropBorderColor(0.78,0.61,0.23,0.9)
        local charName = getCharName()
        if charName and charName ~= "" then
            GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
            GameTooltip:AddLine("|cffC69B3ANeeds:|r " .. charName, 1, 1, 1)
            local needs = GetNeeds(charName)
            local any = false
            for _, slot in ipairs(NEEDS_SLOTS) do
                if needs[slot.key] then
                    GameTooltip:AddLine("  " .. slot.label, 1, 0.6, 0.2)
                    any = true
                end
            end
            if not any then GameTooltip:AddLine("  Nothing marked", 0.5, 0.5, 0.5) end
            GameTooltip:AddLine("|cff888888Click to edit  (max 2)  Right-click clears all|r", 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end
    end)

    cell:SetScript("OnLeave", function()
        if hovTex then hovTex:SetTexture(0,0,0,0) end
        cell:SetBackdropBorderColor(0.15,0.22,0.38,0.6)
        GameTooltip:Hide()
    end)

    needsCellFrames[#needsCellFrames + 1] = {frame = cell, getCharName = getCharName}
    return cell
end
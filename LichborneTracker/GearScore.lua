-- ============================================================
--  GearScore.lua  |  GearScore calculation helpers
-- ============================================================

local GS_SCALE = 1.8618
local GS_ITEM_TYPES = {
    ["INVTYPE_RELIC"] = { slotMod = 0.3164 },
    ["INVTYPE_TRINKET"] = { slotMod = 0.5625 },
    ["INVTYPE_2HWEAPON"] = { slotMod = 2.0000 },
    ["INVTYPE_WEAPONMAINHAND"] = { slotMod = 1.0000 },
    ["INVTYPE_WEAPONOFFHAND"] = { slotMod = 1.0000 },
    ["INVTYPE_RANGED"] = { slotMod = 0.3164 },
    ["INVTYPE_THROWN"] = { slotMod = 0.3164 },
    ["INVTYPE_RANGEDRIGHT"] = { slotMod = 0.3164 },
    ["INVTYPE_SHIELD"] = { slotMod = 1.0000 },
    ["INVTYPE_WEAPON"] = { slotMod = 1.0000 },
    ["INVTYPE_HOLDABLE"] = { slotMod = 1.0000 },
    ["INVTYPE_HEAD"] = { slotMod = 1.0000 },
    ["INVTYPE_NECK"] = { slotMod = 0.5625 },
    ["INVTYPE_SHOULDER"] = { slotMod = 0.7500 },
    ["INVTYPE_CHEST"] = { slotMod = 1.0000 },
    ["INVTYPE_ROBE"] = { slotMod = 1.0000 },
    ["INVTYPE_WAIST"] = { slotMod = 0.7500 },
    ["INVTYPE_LEGS"] = { slotMod = 1.0000 },
    ["INVTYPE_FEET"] = { slotMod = 0.7500 },
    ["INVTYPE_WRIST"] = { slotMod = 0.5625 },
    ["INVTYPE_HAND"] = { slotMod = 0.7500 },
    ["INVTYPE_FINGER"] = { slotMod = 0.5625 },
    ["INVTYPE_CLOAK"] = { slotMod = 0.5625 },
    ["INVTYPE_BODY"] = { slotMod = 0.0000 },
}

local GS_FORMULA = {
    A = {
        [4] = { A = 91.4500, B = 0.6500 },
        [3] = { A = 81.3750, B = 0.8125 },
        [2] = { A = 73.0000, B = 1.0000 },
    },
    B = {
        [4] = { A = 26.0000, B = 1.2000 },
        [3] = { A = 0.7500, B = 1.8000 },
        [2] = { A = 8.0000, B = 2.0000 },
        [1] = { A = 0.0000, B = 2.2500 },
    },
}

function CalculateGearScoreForItemLink(itemLink)
    if not itemLink then return 0, 0, nil end

    local _, _, itemRarity, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    local itemType = itemEquipLoc and GS_ITEM_TYPES[itemEquipLoc]
    if not itemType or not itemRarity or not itemLevel then return 0, itemLevel or 0, itemEquipLoc end

    local qualityScale = 1
    if itemRarity == 5 then
        qualityScale = 1.3
        itemRarity = 4
    elseif itemRarity == 1 or itemRarity == 0 then
        qualityScale = 0.005
        itemRarity = 2
    end

    if itemRarity == 7 then
        itemRarity = 3
        itemLevel = 187.05
    end

    if itemRarity < 2 or itemRarity > 4 then return 0, itemLevel, itemEquipLoc end

    local formulaSet = itemLevel > 120 and GS_FORMULA.A or GS_FORMULA.B
    local formula = formulaSet[itemRarity]
    if not formula then return 0, itemLevel, itemEquipLoc end

    local score = ((itemLevel - formula.A) / formula.B) * itemType.slotMod * GS_SCALE * qualityScale
    if score < 0 then score = 0 end

    return math.floor(score), itemLevel, itemEquipLoc
end

function CalculateUnitGearScore(unitToken)
    if not unitToken or not UnitExists(unitToken) then return 0 end

    local _, classToken = UnitClass(unitToken)
    local titanGripScale = 1
    local mainHandLink = GetInventoryItemLink(unitToken, 16)
    local offHandLink = GetInventoryItemLink(unitToken, 17)

    if mainHandLink and offHandLink then
        local _, _, _, _, _, _, _, _, mainEquipLoc = GetItemInfo(mainHandLink)
        local _, _, _, _, _, _, _, _, offEquipLoc = GetItemInfo(offHandLink)
        if mainEquipLoc == "INVTYPE_2HWEAPON" or offEquipLoc == "INVTYPE_2HWEAPON" then
            titanGripScale = 0.5
        end
    end

    local totalScore = 0

    if offHandLink then
        local offHandScore = select(1, CalculateGearScoreForItemLink(offHandLink))
        if classToken == "HUNTER" then offHandScore = offHandScore * 0.3164 end
        totalScore = totalScore + (offHandScore * titanGripScale)
    end

    for slot = 1, 18 do
        if slot ~= 4 and slot ~= 17 then
            local itemLink = GetInventoryItemLink(unitToken, slot)
            if itemLink then
                local itemScore = select(1, CalculateGearScoreForItemLink(itemLink))
                if classToken == "HUNTER" then
                    if slot == 16 then
                        itemScore = itemScore * 0.3164
                    elseif slot == 18 then
                        itemScore = itemScore * 5.3224
                    end
                end
                if slot == 16 then itemScore = itemScore * titanGripScale end
                totalScore = totalScore + itemScore
            end
        end
    end

    if totalScore <= 0 then return 0 end
    return math.floor(totalScore)
end
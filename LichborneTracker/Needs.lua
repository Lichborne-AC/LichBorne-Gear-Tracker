-- ============================================================
--  Needs.lua  |  Shared needs data helpers
-- ============================================================

NEEDS_SLOTS = {
    { key="head",     icon="Interface\\Icons\\INV_Helmet_03",           label="Head" },
    { key="neck",     icon="Interface\\Icons\\INV_Jewelry_Necklace_07", label="Neck" },
    { key="shoulder", icon="Interface\\Icons\\INV_Shoulder_22",         label="Shoulders" },
    { key="back",     icon="Interface\\Icons\\INV_Misc_Cape_07",        label="Back" },
    { key="chest",    icon="Interface\\Icons\\INV_Chest_Cloth_04",      label="Chest" },
    { key="wrist",    icon="Interface\\Icons\\INV_Bracer_07",           label="Wrists" },
    { key="hands",    icon="Interface\\Icons\\INV_Gauntlets_04",        label="Hands" },
    { key="waist",    icon="Interface\\Icons\\INV_Belt_13",             label="Waist" },
    { key="legs",     icon="Interface\\Icons\\INV_Pants_06",            label="Legs" },
    { key="feet",     icon="Interface\\Icons\\INV_Boots_05",            label="Feet" },
    { key="ring",     icon="Interface\\Icons\\INV_Jewelry_Ring_02",     label="Ring" },
    { key="trinket",  icon="Interface\\Icons\\INV_Misc_Rune_06",        label="Trinket" },
    { key="mh",       icon="Interface\\Icons\\INV_Sword_27",            label="Main Hand" },
    { key="oh",       icon="Interface\\Icons\\INV_Shield_06",           label="Off Hand" },
    { key="ranged",   icon="Interface\\Icons\\INV_Weapon_Bow_07",       label="Ranged" },
}

NEEDS_ICON_SIZE = 18
MAX_NEEDS = 2

function GetNeeds(charName)
    if not charName or charName == "" then return {} end

    local key = charName:lower()
    if not LichborneTrackerDB.needs then LichborneTrackerDB.needs = {} end
    if not LichborneTrackerDB.needs[key] then LichborneTrackerDB.needs[key] = {} end
    return LichborneTrackerDB.needs[key]
end

function SetNeed(charName, slotKey, val)
    if not charName or charName == "" then return end

    if not LichborneTrackerDB.needs then LichborneTrackerDB.needs = {} end

    local key = charName:lower()
    if not LichborneTrackerDB.needs[key] then LichborneTrackerDB.needs[key] = {} end

    if val then
        local count = 0
        for _ in pairs(LichborneTrackerDB.needs[key]) do count = count + 1 end
        if count < MAX_NEEDS then
            LichborneTrackerDB.needs[key][slotKey] = true
        end
    else
        LichborneTrackerDB.needs[key][slotKey] = nil
    end
end

function HasNeeds(charName)
    if not charName or charName == "" then return false end
    if not LichborneTrackerDB.needs then return false end

    local needs = LichborneTrackerDB.needs[charName:lower()]
    if not needs then return false end

    for _ in pairs(needs) do return true end
    return false
end
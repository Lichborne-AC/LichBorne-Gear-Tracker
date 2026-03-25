-- ============================================================
--  Core.lua  |  Shared addon bootstrap and roster helpers
-- ============================================================

if not LichborneTrackerDB then LichborneTrackerDB = {} end
if not LichborneTrackerDB.rows then LichborneTrackerDB.rows = {} end
if not LichborneTrackerDB.notes then LichborneTrackerDB.notes = "" end
if not LichborneTrackerDB.raid then LichborneTrackerDB.raid = "" end
if not LichborneTrackerDB.raidRows then LichborneTrackerDB.raidRows = {} end
if not LichborneTrackerDB.raidRosters then LichborneTrackerDB.raidRosters = {} end
if not LichborneTrackerDB.raidTier then LichborneTrackerDB.raidTier = 0 end
if not LichborneTrackerDB.needs then LichborneTrackerDB.needs = {} end
if not LichborneTrackerDB.raidName then LichborneTrackerDB.raidName = "Molten Core" end
if not LichborneTrackerDB.raidSize then LichborneTrackerDB.raidSize = 40 end
if not LichborneTrackerDB.raidGroup then LichborneTrackerDB.raidGroup = "A" end

MAX_RAID_SLOTS = 40

local function EnsureAllGroups()
    if LichborneTrackerDB.allGroups then return end

    LichborneTrackerDB.allGroups = {}
    for _, groupName in ipairs({"A", "B", "C"}) do
        LichborneTrackerDB.allGroups[groupName] = {}
        for i = 1, 60 do
            LichborneTrackerDB.allGroups[groupName][i] = {name="", cls="", spec="", gs=0, realGs=0}
        end
    end
end

local function MigrateLegacyAllRows()
    if not LichborneTrackerDB.allRows then return end

    EnsureAllGroups()
    for i, row in ipairs(LichborneTrackerDB.allRows) do
        if row.realGs == nil then row.realGs = 0 end
        LichborneTrackerDB.allGroups["A"][i] = row
    end
    LichborneTrackerDB.allRows = nil
end

EnsureAllGroups()
if not LichborneTrackerDB.allGroup then LichborneTrackerDB.allGroup = "A" end
MigrateLegacyAllRows()

function GetCurrentRoster()
    if not LichborneTrackerDB then LichborneTrackerDB = {} end
    if not LichborneTrackerDB.raidRosters then LichborneTrackerDB.raidRosters = {} end
    if not LichborneTrackerDB.raidName then LichborneTrackerDB.raidName = "N/A (5-Man)" end
    if not LichborneTrackerDB.raidSize then LichborneTrackerDB.raidSize = 5 end
    if not LichborneTrackerDB.raidGroup then LichborneTrackerDB.raidGroup = "A" end

    EnsureAllGroups()
    if not LichborneTrackerDB.allGroup then LichborneTrackerDB.allGroup = "A" end
    MigrateLegacyAllRows()

    local name = LichborneTrackerDB.raidName
    local size = LichborneTrackerDB.raidSize
    if type(size) ~= "number" then size = tonumber(size) or 5 end
    if size < 1 then size = 1 end
    if size > MAX_RAID_SLOTS then size = MAX_RAID_SLOTS end
    LichborneTrackerDB.raidSize = size

    local group = LichborneTrackerDB.raidGroup
    local key = name .. "_" .. group
    if not LichborneTrackerDB.raidRosters[key] then
        LichborneTrackerDB.raidRosters[key] = {}
        for i = 1, MAX_RAID_SLOTS do
            LichborneTrackerDB.raidRosters[key][i] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""}
        end
    end

    local roster = LichborneTrackerDB.raidRosters[key]
    for i = 1, MAX_RAID_SLOTS do
        if not roster[i] then
            roster[i] = {name="", cls="", spec="", gs=0, realGs=0, role="", notes=""}
        end
    end

    return roster, size
end
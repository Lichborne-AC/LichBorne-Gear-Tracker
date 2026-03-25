-- ============================================================
--  Layout.lua  |  Shared UI layout constants
-- ============================================================

ROW_HEIGHT = 24
GEAR_SLOTS = 17
MAX_ROWS = 18
ROWS_PER_PAGE = 18
MAX_PAGES = 3
SLOT_ABBR = {"Head", "Neck", "Shldr", "Back", "Chest", "Wrsts", "Hands", "Waist", "Legs", "Feet", "Ring1", "Ring2", "Trnk1", "Trnk2", "MH", "OH", "Rngd"}

COL_NAME_W = 140
COL_GS_W = 42
COL_GEAR_W = 44
COL_NEEDS_W = 46
NAME_OFF = 4
GS_OFF = NAME_OFF + COL_NAME_W + 2
REALGS_OFF = GS_OFF + COL_GS_W + 4
NEEDS_OFF = REALGS_OFF + COL_GS_W + 4
GEAR_OFF = NEEDS_OFF + COL_NEEDS_W + 4

COL_DRAG_W = 18
COL_SPEC_W = 24
DRAG_OFF = 0
SPEC_OFF = COL_DRAG_W + 2
NAME_OFF = NAME_OFF + COL_DRAG_W + 2 + COL_SPEC_W + 2
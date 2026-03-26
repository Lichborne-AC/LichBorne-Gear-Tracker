# Changelog

All notable changes to Lichborne are documented in this file.

## Unreleased

## 1.7.2 - 2026-03-26

### Added

- Added a separate `GS` column for actual GearScore alongside the existing `iLvl` column.
- Added automatic WotLK-style GearScore calculation from inspected equipment, including slot weighting, rarity scaling, and weapon handling.

### Changed

- Renamed the former `GS` display to `iLvl` everywhere it represents average equipped item level.
- Updated Class, Raid, and All tabs to show both `iLvl` and `GS` values.
- Updated sorting so Gear Score sorts now use the true `GS` value instead of average item level.
- Preserved real GearScore values across All tab groups, raid rosters, copy/paste, drag-reorder, and reset paths.
- Split shared addon code out of `LichborneTracker.lua` into dedicated modules for core state, layout constants, static data, GearScore helpers, needs handling, shared UI helpers, and raid row refresh logic.

### Fixed

- Fixed Add Group scan actions on 3.3.5a so UI handlers bind the local scan-state helper instead of calling a missing global `SetScanActive` when addon hook stacks are present.
- Fixed inspect slot mapping so equipped item levels are read from the correct gear slots.
- Fixed All tab actions so add, delete, and sync operations act on the displayed character.
- Fixed tracker deletion cleanup so removing a character also clears roster and needs references.
- Fixed raid dropdown closure scoping.
- Fixed raid size normalization and roster initialization for all raid views.
- Fixed invite button visibility so Invite Raid, Invite Group, and Stop Invite match the active state.
- Fixed raid row drag/drop so reordering no longer drops stored GearScore values.
- Fixed inspect refresh so empty slots clear stale item-level values instead of leaving old data behind.
- Fixed addon startup compatibility by loading `CallbackHandler-1.0` before `LibDataBroker-1.1`.
- Fixed multiple UI script handlers to use explicit event arguments instead of fragile implicit globals such as `this` and `arg1`.

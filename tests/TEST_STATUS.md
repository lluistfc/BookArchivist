# Test Status Summary

**Last Run:** 2024-12-XX

## Test Categories Overview

| Category | Tests | Status | Notes |
|----------|-------|--------|-------|
| **Sandbox** | 107 | ✅ **All Passing** | Pure logic, runs offline via Mechanic sandbox |
| **Desktop** | 89 | ✅ **All Passing** | Complex tests with mocking, runs via Busted CLI |
| **InGame** | 49 | ⚠️ **Need Rewriting** | Require WoW APIs (currently fail in Busted) |
| **TOTAL** | **245** | **196 passing / 49 pending** | |

## Execution Methods

### Sandbox Tests (107 tests)
```bash
# Via Mechanic Desktop (fastest - 30-50ms)
mech call sandbox.test '{"addon": "BookArchivist"}'
```

**Files:**
- `Base64_spec.lua` (39 tests) - Base64 encoding/decoding
- `BookId_spec.lua` (18 tests) - Book ID generation (v2 format)
- `CRC32_spec.lua` (10 tests) - CRC32 checksums
- `Order_spec.lua` (20 tests) - Order management (Touch/Append/Delete)
- `Serialize_spec.lua` (20 tests) - Table serialization/deserialization

### Desktop Tests (89 tests)
```bash
# From addon root
cd G:\development\WorldOfWarcraft\BookArchivist
busted

# Or via Mechanic Desktop
mech call addon.test '{"addon": "BookArchivist"}'
```

**Files:**
- `DBSafety_spec.lua` (29 tests) - Database validation/corruption detection
- `Export_spec.lua` (16 tests) - BDB1 export format encoding/decoding
- `Favorites_spec.lua` (12 tests) - Favorite book management
- `Recent_spec.lua` (11 tests) - Recently opened books (MRU list)
- `Search_spec.lua` (21 tests) - Search text normalization/matching

### InGame Tests (49 tests - Need Rewriting)
⚠️ **These tests currently fail in Busted because they require actual WoW APIs:**
- `CreateFrame()`, `FontString:SetText()`, `SimpleHTML:SetText()`
- `BookArchivist.Iterator` module (async filtering)
- `BookArchivist.UI` module initialization

**Files:**
- `Reader_spec.lua` (27 tests) - Reader UI rendering/navigation
- `Async_Filtering_Integration_spec.lua` (12 tests) - Iterator + Search integration
- `List_Reader_Integration_spec.lua` (10 tests) - List ↔ Reader interactions

**To make these work:**
1. Rewrite to use actual WoW frame APIs (not mocks)
2. Test in-game via `/run` or Mechanic UI
3. Add to `dev/BookArchivist_MechanicIntegration.lua` testCapability.getAll()

## Current Workflow

**Development (Sandbox/Desktop):**
```bash
# Quick sanity check (107 tests, ~30ms)
mech call sandbox.test '{"addon": "BookArchivist"}'

# Full test suite (196 tests, ~5s)
busted
```

**In-Game Verification:**
- Manual testing via addon UI
- Future: Rewrite InGame tests for Mechanic UI execution

## Notes

- **Mechanic UI**: Shows 0 tests (correct - no in-game tests implemented yet)
- **CI/CD**: Runs Sandbox + Desktop tests (196 tests)
- **Busted config**: Updated to search `Sandbox/`, `Desktop/`, `InGame/` folders
- **Integration**: Only in-game tests will appear in Mechanic UI when implemented

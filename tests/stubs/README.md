# BookArchivist Test Stubs

This directory contains BookArchivist-specific test stubs that are independent of the Mechanic framework.

## Purpose

These stubs allow tests to run without depending on Mechanic's generated `wow_stubs.lua` file. This means:
- ✅ Tests remain portable
- ✅ No need to modify Mechanic's generated files
- ✅ Updates to Mechanic won't break tests
- ✅ Tests can be run on different machines without Mechanic installation

## Available Stubs

### bit_library.lua

Pure-Lua implementation of the bit library (bitwise operations). Required for:
- `core/BookArchivist_CRC32.lua` (CRC32 checksum computation)
- `core/BookArchivist_Export.lua` (BDB1 format encoding/decoding)
- `core/BookArchivist_DBSafety.lua` (corruption detection)

Functions provided:
- `bit.band(a, b)` - Bitwise AND
- `bit.bor(a, b)` - Bitwise OR
- `bit.bxor(a, b)` - Bitwise XOR
- `bit.lshift(a, n)` - Left shift
- `bit.rshift(a, n)` - Right shift

## Usage

Load stubs at the top of your test file:

```lua
-- Load bit library for CRC32/Export/DBSafety tests
dofile("g:/development/WorldOfWarcraft/BookArchivist/tests/stubs/bit_library.lua")
```

## Adding New Stubs

If you need additional WoW API stubs for testing:

1. Create a new stub file in this directory (e.g., `c_map_stubs.lua`)
2. Document what WoW APIs it provides
3. Load it in your test files after `bit_library.lua`

Keep stubs minimal - only mock what's necessary for testing.

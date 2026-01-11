# BookArchivist Testing Guide

## Overview

BookArchivist has two testing approaches:

1. **Standalone Runner** (recommended) - Direct Lua execution, fast and simple
2. **Mechanic Sandbox** (WIP) - Full WoW addon environment simulation

## Standalone Testing (Current)

### Requirements
- Lua 5.1 installed
- Mechanic framework available (for test_framework.lua)

### Quick Start

**Run single test:**
```powershell
# Set Mechanic path (first time only)
$env:MECHANIC_PATH = "G:/development/_dev_/Mechanic"

# Run a test
lua.exe run_tests.lua Tests/Core/BookId_spec.lua
```

**Run all tests:**
```powershell
./run_all_tests.ps1
```

### Environment Variable

Set `MECHANIC_PATH` to your Mechanic installation:

```powershell
# Windows PowerShell
$env:MECHANIC_PATH = "G:/development/_dev_/Mechanic"

# Or set permanently:
[System.Environment]::SetEnvironmentVariable("MECHANIC_PATH", "G:/development/_dev_/Mechanic", "User")
```

```bash
# Linux/Mac
export MECHANIC_PATH="/path/to/Mechanic"
```

### Test Files Structure

```
Tests/
├── Core/               # Core business logic tests (196 tests)
│   ├── BookId_spec.lua
│   ├── CRC32_spec.lua
│   ├── Serialize_spec.lua
│   ├── Favorites_spec.lua
│   ├── Recent_spec.lua
│   ├── Search_spec.lua
│   ├── Base64_spec.lua
│   ├── Order_spec.lua
│   ├── Export_spec.lua
│   └── DBSafety_spec.lua
├── Integration/        # Integration tests (12 tests)
│   └── Async_Filtering_Integration_spec.lua
├── UI/                 # UI tests (not yet updated for standalone)
│   └── Reader_spec.lua
└── stubs/              # Test stubs (bit library, etc.)
    ├── bit_library.lua
    └── README.md
```

## Mechanic Sandbox (Work in Progress)

The Mechanic sandbox approach is currently being debugged. While it successfully:
- Finds all test files
- Loads addon modules
- Has self-healing bit library

It's not yet executing tests. Investigation ongoing.

### Attempting Mechanic Tests

```powershell
cd path/to/Mechanic/desktop
python -m mechanic.cli call sandbox.test '{"addon": "BookArchivist", "path": "Tests"}'
```

**Current Status:** 0 tests run (debugging in progress)

## Test Statistics

### Currently Working (Standalone)
- **Total:** 208/208 tests passing (100%)
- **Core:** 196 tests across 10 modules
- **Integration:** 12 tests

### Portable Features
✅ Cross-platform path resolution  
✅ Pure Lua bit operations (no C extensions)  
✅ Zero runtime dependencies (just Lua 5.1)  
✅ Self-healing addon (auto-loads test stubs)  

## Adding New Tests

1. Create test file in appropriate folder (Tests/Core/, Tests/Integration/, Tests/UI/)
2. Use test_helper.lua for portable paths:

```lua
local helper = dofile("Tests/test_helper.lua")

-- Load modules
local MyModule = helper.loadFile("core/MyModule.lua")

describe("MyModule", function()
  it("does something", function()
    assert.are.equal("expected", MyModule:DoSomething())
  end)
end)
```

3. Add to `run_all_tests.ps1` if creating new core test

## Troubleshooting

### "Cannot find test_framework.lua"
Set `MECHANIC_PATH` environment variable to your Mechanic installation directory.

### "bit library unavailable"
The addon should auto-load Tests/stubs/bit_library.lua. If it doesn't:
1. Check file exists at Tests/stubs/bit_library.lua
2. Check you're running from BookArchivist root directory

### Tests pass standalone but fail in Mechanic
This is the current known issue. Standalone testing is the recommended approach until Mechanic integration is fixed.

## CI/CD Integration

For GitHub Actions or other CI systems:

```yaml
- name: Install Lua
  run: |
    # Install Lua 5.1 for your platform
    
- name: Clone Mechanic
  run: git clone https://github.com/YOUR_ORG/Mechanic.git ../Mechanic

- name: Run tests
  env:
    MECHANIC_PATH: ../Mechanic
  run: lua run_tests.lua Tests/Core/BookId_spec.lua
```

## Performance

Typical test execution times:
- Single test file: ~100-300ms
- All 11 test files: ~2-3 seconds total
- Per-test overhead: <1ms

Fast enough for TDD workflows and pre-commit hooks.

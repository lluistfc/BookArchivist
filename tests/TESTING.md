# BookArchivist Testing Guide

## Overview

BookArchivist uses **Busted** for testing - a mature, industry-standard testing framework for Lua.

## Requirements

- **Lua 5.1.5** (64-bit) - Install via `choco install lua51`
- **LuaRocks 3.13+** - Package manager for Lua
- **Busted 2.3.0+** - Testing framework (`luarocks install busted`)
- **MinGW** (for compiling dependencies) - `choco install mingw`

All requirements are cross-platform compatible (Windows, Linux, macOS).

## Installation

### Windows (via Chocolatey)

```powershell
# Install Lua 5.1 64-bit
choco install lua51 -y

# Install MinGW for compiling native dependencies
choco install mingw -y

# Install LuaRocks (download from luarocks.org)
# Then configure it to use Lua 5.1:
luarocks config --lua-version=5.1 variables.LUA "C:\ProgramData\chocolatey\lib\lua51\tools\lua5.1.exe"

# Install Busted
luarocks install busted
```

### Verification

```powershell
lua5.1 -v        # Should show: Lua 5.1.5
luarocks --version  # Should show: 3.13.0 or higher
busted --version    # Should show: 2.3.0
```

## Running Tests

### Quick Start

```powershell
# Run all tests
busted Tests/

# Run Core tests only (196 tests, ~4 seconds)
busted Tests/Core/

# Run specific test file
busted Tests/Core/BookId_spec.lua

# Run Integration tests (some require UI modules)
busted Tests/Integration/
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
├── Integration/        # Integration tests (25 tests, 21 need UI modules)
│   ├── Async_Filtering_Integration_spec.lua
│   └── List_Reader_Integration_spec.lua
├── UI/                 # UI tests (28 tests, need frame mocks)
│   └── Reader_spec.lua
├── stubs/              # Test stubs (bit library for portability)
│   ├── bit_library.lua
│   └── README.md
└── test_helper.lua     # Cross-platform path resolution
```

## Configuration

The `.busted` file in the addon root configures Busted to find tests:

```lua
-- .busted
return {
  _all = {
    ROOT = { "Tests/" },  -- Search for tests in Tests/ folder
    verbose = false       -- Suppress debug output (cleaner JSON)
  }
}
```

## Test Statistics

### Core Tests (Business Logic)
- **Status:** ✅ 196/196 passing (~4 seconds)
- **Coverage:** All core modules fully tested
- **Modules:** BookId, CRC32, Serialize, Base64, Export, DBSafety, Favorites, Recent, Search, Order

### Integration Tests
- **Status:** ⚠️ 4/25 passing (21 need UI module loading)
- **Expected:** Iterator and filtering tests work, UI integration tests need mocks

### UI Tests  
- **Status:** ⚠️ 0/28 passing (all need frame mocks)
- **Expected:** Require WoW frame environment or proper mocking

## Busted Features Used
✅ Cross-platform path resolution  
✅ Pure Lua bit operations (no C extensions)  
✅ Zero runtime dependencies (just Lua 5.1)  
## Busted Features Used

- **BDD style:** `describe()` and `it()` blocks
- **Assertions:** `assert.are.equal()`, `assert.is_true()`, `assert.is_nil()`
- **Setup/teardown:** `before_each()` and `after_each()` hooks
- **JSON output:** `--output json` for CI/CD integration
- **Recursive search:** Automatically finds `*_spec.lua` files in Tests/ folder

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

3. Run the new test: `busted Tests/Core/MyModule_spec.lua`

## Troubleshooting

### "Busted not found"
Install Busted: `luarocks install busted`

Verify installation: `busted --version`

### "Module not found" errors
Tests use `test_helper.lua` for cross-platform path resolution. Make sure you're:
1. Running from BookArchivist root directory
2. Using `helper.loadFile()` to load modules

### Debug print statements break JSON output
Wrap debug prints in conditional checks:
```lua
local debugMode = BookArchivistDB and BookArchivistDB.options and BookArchivistDB.options.debugMode
if debugMode and type(print) == "function" then
  print("[Debug] Message")
end
```

### Integration/UI tests fail
Expected behavior - these tests need:
- **Integration:** Full addon module loading (BookArchivist.Iterator, etc.)
- **UI:** WoW frame environment or proper mocks

Core tests (196) should always pass.

## CI/CD Integration

### GitHub Actions

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Lua 5.1
        run: |
          sudo apt-get update
          sudo apt-get install -y lua5.1 luarocks
      
      - name: Install Busted
        run: sudo luarocks install busted
      
      - name: Run tests
        run: busted Tests/Core/
```

### Local Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Running tests..."
busted Tests/Core/ || exit 1
echo "✓ All tests passed"
```

## Performance

Typical execution times:
- Single test file: ~100-300ms
- All Core tests (196): ~4 seconds
- Full test suite: ~5 seconds

Fast enough for TDD workflows and pre-commit hooks.

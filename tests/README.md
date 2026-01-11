# Test Organization

BookArchivist uses **Busted** - a mature, industry-standard testing framework for Lua.

## 📋 Requirements

- **Lua 5.1.5** (64-bit) - Install via `choco install lua51`
- **LuaRocks 3.13+** - Package manager for Lua
- **Busted 2.3.0+** - Testing framework (`luarocks install busted`)
- **MinGW** (for compiling dependencies) - `choco install mingw`

All requirements are cross-platform compatible (Windows, Linux, macOS).

## � Quick Start

### First-Time Setup
If you don't have Mechanic installed:
```bash
make check-mechanic    # Verify Mechanic CLI is available
make setup-mechanic    # Clone, install, and configure Mechanic
```

**What `setup-mechanic` does:**
- Clones Mechanic repository (if not present)
- Installs Mechanic Desktop with pip (editable mode)
- Creates junction/symlink in `_dev_/` folder (if addon is outside)
- Syncs `!Mechanic` and `Mechanic` addons to WoW clients
- Makes `mech` CLI available system-wide

**Requirements:**
- Python 3.10+ (`py`, `python3`, or `python`)
- Git (for cloning Mechanic repo)

**Platform-specific scripts:**
- Windows: `scripts/setup-mechanic.ps1`
- Unix/macOS: `scripts/setup-mechanic.sh`

### Running Tests
```bash
make test              # Summary only (fast)
make test-detailed     # Show all test results
make test-errors       # With full error traces
```

## �📂 Directory Structure

```
Tests/
├── Sandbox/           # Pure logic tests (5 tests)
│   ├── Base64_spec.lua
│   ├── BookId_spec.lua
│   ├── CRC32_spec.lua
│   ├── Order_spec.lua
│   └── Serialize_spec.lua
├── Desktop/           # Complex Busted tests (5 tests)
│   ├── DBSafety_spec.lua
│   ├── Export_spec.lua
│   ├── Favorites_spec.lua
│   ├── Recent_spec.lua
│   └── Search_spec.lua
└── InGame/            # WoW API tests (3 tests - need rewriting)
    ├── Reader_spec.lua
    ├── Async_Filtering_Integration_spec.lua
    └── List_Reader_Integration_spec.lua
```

## 🎯 Test Categories

### 1. Sandbox Tests - Pure Logic (5 tests)
**Run:** `mech call sandbox.test '{"addon": "BookArchivist"}'`  
**Speed:** ~30ms  
**Tests:** Base64, BookId, CRC32, Order, Serialize

### 2. Desktop Tests - Complex Mocking (5 tests)
**Run:** `busted` from addon root  
**Speed:** ~5s  
**Tests:** DBSafety, Export, Favorites, Recent, Search

### 3. In-Game Tests - WoW Runtime (0 tests currently)
**Run:** Mechanic UI → Tests tab  
**Status:** ⚠️ Need rewriting from Busted format

---

## 🔄 Running All Tests

### Makefile (Recommended)
The Makefile provides the most convenient way to run tests:

```bash
make help              # Show all available targets
make check-mechanic    # Verify Mechanic installation
make setup-mechanic    # Setup Mechanic (first-time only)
make test              # Run all tests (summary only)
make test-detailed     # All tests with full output
make test-errors       # Show full error stack traces
make test-pattern PATTERN=Base64  # Run specific tests
```

**Prerequisites:**
- `make` (Git Bash on Windows, pre-installed on Unix/macOS)
- Mechanic CLI (`make setup-mechanic` handles this)

### Mechanic Integration
BookArchivist uses Mechanic for addon development and testing:

**Setup once:**
```bash
make setup-mechanic    # Auto-installs everything
```

**Development workflow:**
```bash
# Run offline tests (fast - 30ms)
mech call sandbox.test '{"addon": "BookArchivist"}'

# Run full test suite
mech call addon.test '{"addon": "BookArchivist"}'

# Validate addon structure
mech call addon.validate '{"addon": "BookArchivist"}'
```

**Dev folder structure:**
```
_dev_/
├── BookArchivist/     # Junction/symlink to actual addon
├── !Mechanic/         # Mechanic diagnostic hub
└── Mechanic/          # Mechanic main addon
```

### Quick Test Runner (Direct Execution)

**Windows (PowerShell):**
```powershell
cd G:\development\WorldOfWarcraft\BookArchivist
.\Tests\run-tests.ps1

# Or from Tests folder:
cd Tests
.\run-tests.ps1
```

**Unix/macOS (Bash):**
```bash
cd /path/to/BookArchivist
./Tests/run-tests.sh

# Or from Tests folder:
cd Tests
chmod +x run-tests.sh  # First time only
./run-tests.sh
```

**Features:**
- ✓ Clean, formatted output with summary
- ✓ Automatic pass/fail detection
- ✓ No JSON clutter
- ✓ Cross-platform (PowerShell + Bash)

**Options:**
```bash
# Windows PowerShell:
.\Tests\run-tests.ps1                    # Summary only (fast)
.\Tests\run-tests.ps1 -Detailed          # Show all test results (JUnit-style)
.\Tests\run-tests.ps1 -ShowErrors        # Display full error stack traces
.\Tests\run-tests.ps1 -Verbose           # Full busted output (raw)
.\Tests\run-tests.ps1 -Pattern "Base64"  # Run specific test suites

# Unix/macOS Bash:
./Tests/run-tests.sh                     # Summary only (fast)
./Tests/run-tests.sh -d                  # Show all test results (JUnit-style)
./Tests/run-tests.sh -e                  # Display full error stack traces
./Tests/run-tests.sh -v                  # Full busted output (raw)
./Tests/run-tests.sh -p "Base64"         # Run specific test suites

# Combine flags:
.\Tests\run-tests.ps1 -Detailed -ShowErrors  # Full test list + error details
./Tests/run-tests.sh -d -e                   # Full test list + error details
```

**Requirements (Unix/macOS):**
- `jq` (recommended) or `python3` for JSON parsing
- Install jq: `brew install jq` (macOS) or `apt install jq` (Linux)

### Alternative Methods

**Via Busted CLI:**
```powershell
busted
```

**Via Mechanic:**
```powershell
mech call addon.test '{"addon": "BookArchivist"}'
```

**⚠️ Prerequisites:**
- Busted must be in system PATH (e.g., `C:\Users\<user>\AppData\Roaming\luarocks\bin`)
- Verify with: `where.exe busted` (Windows) or `which busted` (Linux/Mac)
- Install if missing: `luarocks install busted`

---

## 📊 Summary

| Category | Count | Working | In Mechanic UI? |
|----------|-------|---------|-----------------|
| Sandbox | 5 | ✅ Yes | ❌ No (CLI only) |
| Desktop | 5 | ✅ Yes | ❌ No (CLI only) |
| InGame | 3 | ⚠️ Needs work | ✅ Yes (when done) |

**Total:** 200 tests passing (~4-5 seconds execution time)

---

## 🔧 Installation (Manual Setup)

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

### Unix/Linux

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y lua5.1 luarocks
sudo luarocks install busted

# Arch Linux
sudo pacman -S lua51 luarocks
sudo luarocks install busted
```

### macOS

```bash
# Using Homebrew
brew install lua@5.1 luarocks
luarocks install busted
```

### Verification

```powershell
lua5.1 -v        # Should show: Lua 5.1.5
luarocks --version  # Should show: 3.13.0 or higher
busted --version    # Should show: 2.3.0+
```

---

## 🧪 Adding New Tests

1. Create test file in appropriate folder (`Tests/Sandbox/`, `Tests/Desktop/`, `Tests/InGame/`)
2. Use `test_helper.lua` for portable paths:

```lua
local helper = dofile("tests/test_helper.lua")

-- Load modules
local MyModule = helper.loadFile("core/MyModule.lua")

describe("MyModule", function()
  it("does something", function()
    assert.are.equal("expected", MyModule:DoSomething())
  end)
end)
```

3. Run the new test:
```bash
make test-pattern PATTERN=MyModule
# or directly:
busted tests/Desktop/MyModule_spec.lua
```

---

## 🐛 Troubleshooting

### "Busted not found"
**Solution:** Install Busted: `luarocks install busted`  
**Verify:** `busted --version`

### PATH issues (Windows)
**Solution:** Add LuaRocks bin to PATH:
```
C:\Users\<username>\AppData\Roaming\luarocks\bin
```

### "Module not found" errors
**Cause:** Tests use `test_helper.lua` for cross-platform path resolution.  
**Solution:** 
1. Run from BookArchivist root directory
2. Use `helper.loadFile()` to load modules

### Debug prints break JSON output
Wrap debug prints in conditional checks:
```lua
local debugMode = BookArchivistDB and BookArchivistDB.options and BookArchivistDB.options.debugMode
if debugMode and type(print) == "function" then
  print("[Debug] Message")
end
```

### Integration/InGame tests fail
**Expected behavior** - these tests need:
- **Integration:** Full addon module loading (BookArchivist.Iterator, etc.)
- **InGame:** WoW frame environment or proper mocks

Desktop and Sandbox tests (200 total) should always pass.

---

## 🔄 CI/CD Integration

### GitHub Actions

BookArchivist uses GitHub Actions to run tests automatically on every push to `main` and every pull request.

See `.github/workflows/tests.yml` for the full configuration.

**What it does:**
- Runs on Windows, Linux, and macOS
- Installs Lua 5.1, LuaRocks, and Busted
- Executes `make test-errors` for detailed error reporting
- Reports results in GitHub Actions summary

**Manual trigger:**
```bash
gh workflow run tests.yml
```

### Local Pre-commit Hook

Create `.git/hooks/pre-commit`:
```bash
#!/bin/sh
echo "Running tests..."
make test || exit 1
echo "✓ All tests passed"
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

## ⚡ Performance

Typical execution times:
- Single test file: ~100-300ms
- Desktop tests (5): ~2 seconds
- Sandbox tests (5): ~30ms
- All tests (200): ~4-5 seconds

Fast enough for TDD workflows and pre-commit hooks.

---

## 📚 Test Configuration

The `.busted` file in the addon root configures Busted:

```lua
-- .busted
return {
  _all = {
    ROOT = { "tests/" },  -- Search for tests in tests/ folder
    verbose = false       -- Suppress debug output (cleaner JSON)
  }
}
```

---

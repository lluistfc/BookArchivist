# Test Organization

BookArchivist tests are organized into three categories based on execution environment.

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

---

For detailed documentation, see full README in this directory.

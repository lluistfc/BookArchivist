# Test Organization

BookArchivist tests are organized into three categories based on execution environment.

## 📂 Directory Structure

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

### Makefile (Cross-Platform)
```bash
make test              # Summary only
make test-detailed     # All tests (JUnit-style)
make test-errors       # With error traces
make test-pattern PATTERN=Base64  # Run specific tests
```

**Requires:** `make` (available via Git Bash on Windows, pre-installed on Unix/macOS)

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

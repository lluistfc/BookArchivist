# BookArchivist Tests

Unit tests for BookArchivist addon functionality.

## Prerequisites

To run tests, you need Lua 5.1 installed:

### Windows

**Option 1: LuaBinaries (Recommended - works around Chocolatey issues)**
1. Download Lua 5.1 from [LuaBinaries](https://sourceforge.net/projects/luabinaries/files/5.1.5/Tools%20Executables/)
2. Get `lua-5.1.5_Win64_bin.zip` or `lua-5.1.5_Win32_bin.zip`
3. Extract to `C:\lua51`
4. Add `C:\lua51` to your PATH

**Option 2: Scoop**
```powershell
scoop install lua
```

**Option 3: Chocolatey (if no dependency conflicts)**
```powershell
choco install lua
```

See [INSTALL_LUA.md](INSTALL_LUA.md) for detailed instructions.

### Linux/Mac
```bash
# Ubuntu/Debian
sudo apt-get install lua5.1

# macOS
brew install lua@5.1
```

## Running Tests

### From Command Line (Recommended)

**PowerShell (Windows):**
```powershell
cd tests
lua test_migrations.lua
```

**Bash (Linux/Mac):**
```bash
cd tests
lua test_migrations.lua
```

### From VS Code

1. Open the project in VS Code
2. Press `F5` or select **Run > Start Debugging**
3. Choose "Run Migration Tests" from the configuration dropdown
4. View results in the Debug Console

**Note:** VS Code's Lua debugger uses Lua 5.4. The test includes polyfills for Lua 5.1 compatibility (WoW's version), but for most accurate results, run from command line with Lua 5.1.

## Test Coverage

### DBSafety Tests (4 tests)
- ✓ Validates v1.0.2 legacy structure
- ✓ Validates modern structure
- ✓ Rejects invalid structures
- ✓ HealthCheck works with both structures

### Migration Tests (11 tests)
- ✓ v1 migration adds dbVersion
- ✓ v2 migration creates booksById
- ✓ v2 migration preserves all book data
- ✓ v2 migration preserves book metadata (titles, creators, etc.)
- ✓ v2 migration creates legacy snapshot
- ✓ v2 migration creates indexes
- ✓ v2 migration is idempotent (can run multiple times safely)
- ✓ v2 migration updates order array
- ✓ HealthCheck accepts legacy structure
- ✓ HealthCheck accepts modern structure

### Real-World Data Tests (1 test)
- ✓ Real v1.0.2 data from production migrates successfully
  - Uses actual SavedVariables from v1.0.2 release
  - Validates all 7 books are preserved
  - Verifies specific book titles (The New Horde, etc.)
  - Confirms indexes and legacy snapshots created

**Total: 16 comprehensive tests**

## Troubleshooting

**Error: module not found**
- Ensure you're running from the `tests/` directory
- Check that `../core/` contains the required Lua files

**Error: lua command not found**
- Install Lua 5.1 (see Prerequisites)
- Ensure Lua is in your system PATH

**Test failures**
- Check the error message for specific assertion failures
- Review the migration logic in `core/BookArchivist_Migrations.lua`
- Verify test data in `create_v102_db()` matches actual v1.0.2 structure

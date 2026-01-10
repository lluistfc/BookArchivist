# BookArchivist Tests

BookArchivist uses **Mechanic** for comprehensive offline and in-game testing.

## Testing Strategy

| Type | Tool | Speed | Use Case |
|------|------|-------|----------|
| **Sandbox** | Mechanic | ~30ms | Core logic (migrations, BookId, serialization) |
| **Integration** | Busted | ~5s | Full workflows (capture, search, DB ops) |
| **In-Game** | Mechanic | ~30s | ItemText events, tooltips, UI rendering |

## Prerequisites

### 1. Install Python 3.10+

Required for Mechanic CLI:

**Windows:**
```powershell
winget install Python.Python.3.12
```

**Linux/Mac:**
```bash
# Ubuntu/Debian
sudo apt-get install python3 python3-pip

# macOS
brew install python@3.12
```

### 2. Install LuaRocks

Required for Busted test framework:

**Windows:**
1. Download from [LuaRocks GitHub](https://github.com/luarocks/luarocks/releases)
2. Extract and add to PATH
3. Verify: `luarocks --version`

**Linux:**
```bash
sudo apt-get install luarocks
```

**macOS:**
```bash
brew install luarocks
```

### 3. Install Mechanic

#### Step 1: Clone Mechanic to _dev_ folder

```bash
# Navigate to your _dev_ folder (or create it)
cd "G:\development\_dev_"

# Clone Mechanic
git clone https://github.com/Falkicon/Mechanic.git
```

#### Step 2: Copy !Mechanic addon to WoW

```bash
# Copy the addon (not the entire repo)
Copy-Item -Recurse "G:\development\_dev_\Mechanic\!Mechanic" "D:\World of Warcraft\_retail_\Interface\AddOns\!Mechanic"
```

Or create a flat copy in _dev_ (for sandbox):
```bash
Copy-Item -Recurse "G:\development\_dev_\Mechanic\!Mechanic" "G:\development\_dev_\!Mechanic"
```

#### Step 3: Install Mechanic CLI

```bash
cd "G:\development\_dev_\Mechanic\desktop"
pip install -e .
```

Verify installation:
```bash
mech --version
# Should output: mechanic, version 0.2.1
```

#### Step 4: Configure Mechanic environment

Create `~/.mechanic/.env` (Windows: `C:\Users\YourName\.mechanic\.env`):

```ini
MECHANIC_DEV_PATH=G:\development\_dev_
```

**Important:** Use `MECHANIC_DEV_PATH`, not just `DEV_PATH`!

#### Step 5: Create junction link for your addon

Mechanic expects addons in `_dev_` folder. If your addon is elsewhere, create a junction link:

```powershell
# Windows
New-Item -ItemType Junction -Path "G:\development\_dev_\BookArchivist" -Target "G:\development\WorldOfWarcraft\BookArchivist"
```

```bash
# Linux/Mac
ln -s /path/to/actual/addon /path/to/_dev_/BookArchivist
```

#### Step 6: Generate WoW API stubs

```bash
mech call sandbox.generate
```

This creates 5600+ API stubs for offline testing (~30ms execution vs 30s in-game).

#### Step 7: Install Busted (optional, for integration tests)

```bash
luarocks install busted
```

### 2. Install Lua 5.1 (for standalone tests)

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
lua test_migrations.lua
```

## Running Tests

### Sandbox Tests (Mechanic - Offline)

Generate WoW API stubs once:
```bash
mech call sandbox.generate
```

Run sandbox tests:
```bash
# Test all BookArchivist core modules
mech call sandbox.test -i '{"addon": "BookArchivist"}'

# With verbose output
mech call sandbox.test -i '{"addon": "BookArchivist", "verbose": true}'
```

**What gets tested:**
- Core logic (migrations, BookId, CRC32, serialization)
- Database operations
- Search/filter algorithms
- Favorites/Recent tracking

### Standalone Migration Tests (Lua 5.1)

For legacy migration verification:
```bash
cd tests
lua test_migrations.lua
```

### Integration Tests (Busted)

Coming soon - full workflow testing with mocked WoW environment.

### In-Game Tests (Mechanic)

1. `/reload` in WoW
2. Open Mechanic dashboard: `mech` in terminal
3. Navigate to Tests tab
4. View BookArchivist test results

## Test Structure

```
tests/
├── README.md                  # This file
├── test_migrations.lua        # Standalone migration tests (Lua 5.1)
├── Core/                      # Sandbox tests (Mechanic)
│   ├── BookId_spec.lua
│   ├── CRC32_spec.lua
│   ├── Serialize_spec.lua
│   ├── Migrations_spec.lua
│   ├── Favorites_spec.lua
│   ├── Recent_spec.lua
│   └── Search_spec.lua
└── Integration/               # Full workflow tests (Busted)
    ├── Capture_spec.lua
    ├── UI_spec.lua
    └── Database_spec.lua
```

## Test Coverage

### Current Tests (Standalone)

#### DBSafety Tests (4 tests)
- ✓ Validates v1.0.2 legacy structure
- ✓ Validates modern structure
- ✓ Rejects invalid structures
- ✓ HealthCheck works with both structures

#### Migration Tests (11 tests)
- ✓ v1 migration adds dbVersion
- ✓ v2 migration creates booksById
- ✓ v2 migration preserves all book data
- ✓ v2 migration preserves book metadata
- ✓ v2 migration creates legacy snapshot
- ✓ v2 migration creates indexes
- ✓ v2 migration is idempotent
- ✓ v2 migration updates order array
- ✓ HealthCheck accepts legacy structure
- ✓ HealthCheck accepts modern structure

#### Real-World Data Tests (1 test)
- ✓ Real v1.0.2 data migrates successfully

**Total: 16 comprehensive tests**

### Planned Tests (Mechanic Sandbox)

- BookId generation and parsing
- CRC32 checksum calculations
- Table serialization/deserialization
- Favorites management
- Recent books tracking
- Search text processing
- Database operations

## Troubleshooting

### Mechanic Setup Issues

**"MECHANIC_NOT_FOUND: Could not find Mechanic repo folder"**
- Check `.env` file uses `MECHANIC_DEV_PATH` (not `DEV_PATH`)
- Verify path: `G:\development\_dev_\Mechanic` exists
- Ensure `Mechanic/UI/APIDefs` folder exists

**"ADDON_NOT_FOUND: Addon 'BookArchivist' not found in _dev_ folder"**
- Create junction link: `New-Item -ItemType Junction -Path "G:\development\_dev_\BookArchivist" -Target "G:\development\WorldOfWarcraft\BookArchivist"`
- Or move addon to `_dev_` folder

**"bit library unavailable for CRC32"**
- Fixed! Pure-Lua `bit` library added to `sandbox/generated/wow_stubs.lua`
- Provides: `band`, `bor`, `bxor`, `lshift`, `rshift`
- Regenerate stubs: `mech call sandbox.generate`

**"describe/it/pending not found"**
- Fixed! Test framework created at `sandbox/generated/test_framework.lua`
- Provides Busted-compatible API
- Regenerate if missing

**"mech: command not found"**
```bash
cd "G:\development\_dev_\Mechanic\desktop"
pip install -e .
```

**"Sandbox stubs not found"**
```bash
mech call sandbox.generate
```

### Standalone Test Issues

**Error: module not found**
- Ensure you're running from the `tests/` directory
- Check that `../core/` contains the required Lua files

**Error: lua command not found**
- Install Lua 5.1 (see Prerequisites)
- Ensure Lua is in your system PATH

**Test failures**
- Check error messages for specific assertion failures
- Review migration logic in `core/BookArchivist_Migrations.lua`

## Resources

- [Mechanic GitHub](https://github.com/Falkicon/Mechanic)
- [Mechanic Testing Guide](https://github.com/Falkicon/Mechanic/blob/main/docs/integration/testing.md)
- [BookArchivist AGENTS.md](../AGENTS.md) - AI agent workflow guide

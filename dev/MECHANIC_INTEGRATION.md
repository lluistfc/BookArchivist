# Mechanic Integration (Dev-Only)

## Overview

BookArchivist integrates with Mechanic's development hub through the dev-only file `dev/BookArchivist_MechanicIntegration.lua`. This integration is **excluded from production releases** via the `#@do-not-package@` section in the TOC file.

## Features

### 1. Console Logging Integration

All `BookArchivist:DebugPrint()` calls are automatically forwarded to Mechanic's console when Mechanic is loaded. Messages are categorized:

| Category | Mechanic Category | Use Case |
|----------|------------------|-----------|
| CAPTURE | EVENT | Book capture events |
| SEARCH | CORE | Search operations |
| FILTER | CORE | List filtering |
| RENDER | PERF | UI rendering |
| DB | CORE | Database operations |
| IMPORT/EXPORT | CORE | Import/export operations |
| UI | TRIGGER | UI interactions |
| PERFORMANCE | PERF | Performance metrics |
| ERROR | VALIDATION | Errors and validation |

### 2. Performance Metrics

Mechanic's Performance tab shows BookArchivist statistics:
- Total books count
- Total pages count
- Storage size (KB)
- Average pages per book

### 3. Custom Tools Panel

The Tools tab in Mechanic provides BookArchivist-specific controls:
- **Refresh Stats** - Update database statistics
- **Export All Books** - Quick export trigger
- **Clear Debug Log** - Clear stored debug messages
- **Enable Debug Mode** - Toggle debug mode checkbox

### 4. Test Integration

Test suite metadata is exposed to Mechanic (though tests still run via Busted):
- Core tests (Database, Search, Capture)
- UI tests (List, Reader)
- Integration tests

Use Mechanic CLI to run tests:
```bash
mech call addon.test --addon BookArchivist
```

## How It Works

1. **Auto-Registration**: When `!Mechanic` or `Mechanic` addon loads, BookArchivist automatically registers itself
2. **DebugPrint Hook**: Original `BookArchivist:DebugPrint()` is hooked to also call `MechanicLib:Log()`
3. **Capabilities**: BookArchivist exposes test, performance, and tools capabilities via MechanicLib
4. **Clean Unload**: On logout, BookArchivist unregisters and restores original DebugPrint

## Development Workflow

### In-Game
1. Load WoW with both BookArchivist and Mechanic installed
2. Open Mechanic UI (`/mechanic` or compartment icon)
3. Check Console tab - BookArchivist debug messages appear there
4. Check Performance tab - Database statistics are tracked
5. Check Tools tab - BookArchivist custom panel appears

### Desktop (CLI)
```bash
# Get addon output (errors, tests, console)
mech call addon.output --addon BookArchivist --agent_mode true

# Run tests
mech call addon.test --addon BookArchivist

# Lint code
mech call addon.lint --addon BookArchivist
```

### Desktop (MCP via AI Agent)
Use MCP tools directly:
- `addon.output(addon="BookArchivist", agent_mode=true)`
- `addon.test(addon="BookArchivist")`
- `addon.lint(addon="BookArchivist")`

## Production Safety

The integration file is **never shipped to users**:
- Wrapped in `#@do-not-package@` section in TOC
- Lives in `dev/` folder
- Excluded via `.pkgmeta` during CurseForge packaging
- No Mechanic dependencies in release code

## Debugging

If integration doesn't work:
1. Check Mechanic is loaded: `/run print(LibStub("MechanicLib-1.0", true) and "Yes" or "No")`
2. Check registration: `/run print(BookArchivist.MechanicIntegration:IsRegistered())`
3. Check console in Mechanic UI for registration message
4. Verify dev file is loaded: Check "Dev Tools" section in TOC is after main addon code

## Extending Integration

To add more capabilities, edit `dev/BookArchivist_MechanicIntegration.lua`:

### Add Custom Metrics
```lua
-- In performanceCapability.getSubMetrics()
table.insert(metrics, {
    name = "My Metric",
    value = calculateValue(),
    unit = "count",
    category = "Custom"
})
```

### Add Tools Panel Controls
```lua
-- In toolsCapability.createPanel()
local myButton = CreateFrame("Button", nil, toolsPanel, "UIPanelButtonTemplate")
myButton:SetPoint(...)
myButton:SetText("My Tool")
myButton:SetScript("OnClick", function()
    -- Do something
end)
```

### Add Log Categories
```lua
-- In categoryMap
["MY_CATEGORY"] = "CORE",  -- Maps to Mechanic's CORE category
```

Then use in code:
```lua
BookArchivist:DebugPrint("[MY_CATEGORY] Custom debug message")
```

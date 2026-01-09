# WoW Command Test Scripts for BookArchivist

## Production Mode Test (Dev TOC Disabled)

Copy and paste these commands one at a time into WoW chat:

```lua
/run print("=== PRODUCTION MODE TEST ===")
/ba help
/run print("--- Testing blocked commands (should show error) ---")
/ba modules
/ba pool
/ba profile
/ba iter
/ba gentest 10
/ba stats
/ba uigrid
/badev
/run print("--- Testing allowed commands (should work) ---")
/ba options
/run C_Timer.After(0.5, function() print("✓ Options should have opened") end)
/ba import
/run C_Timer.After(0.5, function() print("✓ Import/Tools window should have opened") end)
```

**Expected Results (Production):**
- Help should show ONLY: `/ba`, `/ba help`, `/ba options`, `/ba import`
- All diagnostic commands should show: "Dev commands not available in production build"
- `/badev` should show: "Unknown command"
- Options and Import should work normally

---

## Development Mode Test (Dev TOC Enabled)

First, enable dev tools:
```powershell
# In PowerShell (outside WoW):
Rename-Item -Path "BookArchivist_Dev.toc.disabled" -NewName "BookArchivist_Dev.toc"
```

Then `/reload` in WoW and paste these commands:

```lua
/run print("=== DEVELOPMENT MODE TEST ===")
/ba help
/run print("--- Testing dev commands (should work) ---")
/ba modules
/ba pool
/ba profile help
/ba iter status
/badev help
/badev chat
/badev grid
/run print("--- Testing test data commands ---")
/ba gentest 5
/run C_Timer.After(1, function() print("✓ Should have generated 5 test books") end)
/ba stats
/ba cleartest
/run print("--- Testing profiler ---")
/ba profile on
/ba profile summary
/ba profile off
```

**Expected Results (Development):**
- Help should show full command list including "Dev Tools Commands" section
- All commands should work without errors
- `/badev` commands should work
- Test books should be created and stats should show them
- Profiler commands should respond appropriately

---

## Quick One-Liner Tests

### Production Quick Test
Paste this single line:
```lua
/run local ok = BookArchivist.DevTools ~= nil; print(ok and "|cFFFF0000ERROR: Dev tools loaded in production!|r" or "|cFF00FF00✓ Production mode confirmed|r")
```

### Development Quick Test
Paste this single line:
```lua
/run local ok = BookArchivist.DevTools ~= nil; print(ok and "|cFF00FF00✓ Dev tools loaded|r" or "|cFFFF0000ERROR: Dev tools not loaded!|r")
```

---

## Full Automated Test Macro

Create a macro named "BATest" with this content (will run slowly due to delays):

```lua
/run local t=0; local function test(cmd,delay) C_Timer.After(t,function() DEFAULT_CHAT_FRAME:AddMessage(cmd) SlashCmdList["BOOKARCHIVIST"](cmd:gsub("/ba ","")) end); t=t+(delay or 1) end
/run test("/ba help",1); test("modules",1); test("pool",1); test("profile",1); test("iter",1); test("gentest 10",1); test("stats",1)
```

This will automatically run all test commands with 1-second delays between each.

---

## Debug Checkbox Test (UI)

To verify the debug checkbox is properly hidden/shown:

**Production (should be hidden):**
```lua
/ba options
-- Look at the settings panel, debug checkbox should NOT be visible
```

**Development (should be visible):**
```lua
/ba options
-- Look at the settings panel, debug checkbox should be visible
-- Click it on/off to test functionality
```

---

## Test Results Log

Use this to document your test results:

```
Production Mode:
[ ] Help shows only basic commands
[ ] /ba modules blocked
[ ] /ba pool blocked
[ ] /ba profile blocked
[ ] /ba iter blocked
[ ] /ba gentest blocked
[ ] /ba stats blocked
[ ] /ba uigrid blocked
[ ] /badev shows "Unknown command"
[ ] /ba options works
[ ] /ba import works
[ ] Debug checkbox NOT in settings

Development Mode:
[ ] Help shows dev commands section
[ ] /ba modules works
[ ] /ba pool works
[ ] /ba profile works
[ ] /ba iter works
[ ] /ba gentest works
[ ] /ba stats works
[ ] /ba uigrid works
[ ] /badev help shows commands
[ ] /badev chat toggles debug
[ ] /badev grid toggles overlay
[ ] Debug checkbox IN settings
[ ] Checkbox controls both chat & grid
```

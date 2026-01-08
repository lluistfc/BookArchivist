# BookArchivist Testing Instructions
**CRITICAL: Test these commands after /reload**

---

## ⚠️ CRITICAL: SavedVariables Persistence

**WoW ONLY saves addon data (SavedVariables) on clean logout/exit!**

- ✅ `/logout` or `/exit` → Data SAVED to disk
- ❌ `/reload` → Data LOST (not written to disk)
- ❌ Alt+F4 or crash → Data LOST

**When generating test books:**
1. Run `/ba gentest <count>`
2. Click **"Logout"** when prompted
3. Log back in
4. Books are now persisted

**If you click "Cancel" or `/reload` instead:**
- Books exist in memory this session
- But will be GONE after logout/crash

---

## 🔍 STEP 1: Verify Module Loading

After `/reload`, check if modules loaded:

```lua
/ba modules
```

**Expected Output:**
```
BookArchivist Module Status:
  BookArchivist: true
  Profiler: true
  TestDataGenerator: true
  DBSafety: true
  Core: true
```

**If ANY show `false` or `nil`:**
- Check `/console scriptErrors 1` for Lua errors
- Check the load order in BookArchivist.toc
- Report the error messages

---

## 🔍 STEP 1.5: Check Available Commands

```lua
/ba help
```

This will show all available commands and confirm the slash command system is working.

---

## 🔍 STEP 2: Enable Debug Logging

```lua
/run BookArchivistDB = BookArchivistDB or {}; BookArchivistDB.options = BookArchivistDB.options or {}; BookArchivistDB.options.debug = true
/reload
```

After reload, you should see loading messages in chat:
- `[Profiler] Module loaded`
- `[TestDataGenerator] Module loaded`
- `[DBSafety] Module loaded`

---

## 🧪 STEP 3: Test Profiler Commands

### Enable Profiler
```lua
/ba profile on
```
**Expected:** `BookArchivist Profiler: Enabled` (in green)

### View Report (will be empty until operations run)
```lua
/ba profile report
```
**Expected:** Performance report table (even if empty)

### View Summary
```lua
/ba profile summary
```
**Expected:** Summary with total operations

### Disable Profiler
```lua
/ba profile off
```
**Expected:** `BookArchivist Profiler: Disabled` (in red)

---

## 🧪 STEP 4: Test Data Generator

### Check Current Stats
```lua
/ba stats
```
**Expected:** Database statistics showing your 12 books

### Generate Test Books (START SMALL!)
```lua
/ba gentest 10
```
**Expected:**
1. Progress message: `Generating 10 test books...`
2. Generation complete message with timing
3. **Popup dialog:** "Generated 10 test books! IMPORTANT: ReloadUI will LOSE these books! You must logout and login to save them."
4. Click **"Logout"** button (NOT Cancel!)
5. Character selection screen appears
6. Log back in
7. Books are now saved to disk

### After Login, Verify
```lua
/balist
```
**Expected:** Should show 22 books (12 original + 10 test)

---

## 🧪 STEP 5: Test Larger Datasets

Once small test works:

```lua
/ba gentest 100    -- 100 books
-- Click "Logout" when prompted
-- Log back in
/ba stats          -- Verify count

/ba gentest 500    -- Add 500 more
-- Click "Logout"
-- Log back in
/ba stats          -- Should show 600+ books
```

---

## 🧪 STEP 6: Test Presets

```lua
/ba genpreset small    -- 100 books
/ba genpreset medium   -- 500 books
/ba genpreset large    -- 1000 books
```

---

## 🧪 STEP 7: Performance Testing

With 100+ books loaded:

```lua
/ba profile on
/ba profile reset      -- Clear previous data
```

Then perform operations:
1. Open main UI with `/ba`
2. Search for books
3. Apply filters
4. Scroll through list

Then check results:
```lua
/ba profile report
/ba profile slow
```

---

## 🧪 STEP 8: Clear Test Data

When done testing:

```lua
/ba cleartest
```

**Expected:**
1. First popup: "Delete all test books?" with Delete/Cancel buttons
2. Click "Delete" button
3. Count of deleted books displayed in chat
4. Second popup: "Deleted N test books! IMPORTANT: ReloadUI will NOT save deletions!"
5. Click "Logout" button
6. Log back in
7. Books are permanently deleted

After login:
```lua
/balist
```
**Expected:** Back to your original 12 books

---

## 🚨 TROUBLESHOOTING

### Problem: Nothing happens with `/ba profile`

**Diagnosis:**
```lua
/ba modules
```

If `Profiler: false`, the module didn't load.

**Fix:**
1. Check for Lua errors: `/console scriptErrors 1`
2. `/reload` and look for error messages
3. Check BookArchivist.toc has the line:
   `core/BookArchivist_Profiler.lua`

### Problem: `/ba gentest` says module not loaded

**Diagnosis:**
```lua
/ba modules
```

If `TestDataGenerator: false`, the module didn't load.

**Fix:**
1. Check BookArchivist.toc has:
   `dev/BookArchivist_TestDataGenerator.lua`
2. Check for syntax errors in the file
3. `/reload` with `/console scriptErrors 1` enabled

### Problem: Lua errors on reload

**Common causes:**
- `date()` not available → Fixed in latest version
- `time()` not available → Fixed in latest version
- Module load order issue → Check .toc file

**Get Error Details:**
```lua
/console scriptErrors 1
/reload
```

Look for red error messages mentioning BookArchivist files.

### Problem: Commands work but books don't generate

**Check:**
1. Are Core and BookId modules loaded?
   ```lua
   /ba modules
   ```

2. Is the DB accessible?
   ```lua
   /badb
   ```

3. Any errors in chat after `/ba gentest 10`?

---

## 📊 EXPECTED TIMELINE

### First Time Setup (5 minutes)
1. `/reload` - 30 seconds
2. `/ba modules` - Verify modules loaded
3. Enable debug logging - 1 minute
4. `/reload` again - 30 seconds
5. `/ba gentest 10` - 1 minute
6. `/reload` - 30 seconds
7. Verify with `/balist` - 30 seconds

### Performance Baseline (10 minutes)
1. `/ba gentest 1000` - 2 minutes
2. `/reload` - 1 minute
3. `/ba profile on` - 5 seconds
4. Perform operations - 5 minutes
5. `/ba profile report` - 1 minute
6. Document results in PERFORMANCE_BASELINE.md

---

## 🎯 SUCCESS CRITERIA

**Phase 0 Testing Complete When:**
- [✓] `/ba modules` shows all modules true
- [✓] `/ba profile on` works without errors
- [✓] `/ba gentest 10` generates 10 books successfully
- [✓] `/ba stats` shows correct book count
- [✓] `/ba profile report` shows operation data
- [✓] `/ba cleartest` removes test books
- [✓] No Lua errors during any operation

---

## 📝 REPORT TEMPLATE

If something doesn't work, provide this info:

```
## Issue Report

### Command Attempted:
/ba [command]

### Expected Result:
[what should happen]

### Actual Result:
[what actually happened]

### Module Status:
[output of /ba modules]

### Lua Errors:
[any error messages after /console scriptErrors 1]

### WoW Version:
[retail/classic/wrath]

### BookArchivist Version:
[version from .toc file]
```

---

**REMEMBER:** Start small (10 books), verify it works, then scale up.  
Don't jump straight to 1000 books if 10 doesn't work!

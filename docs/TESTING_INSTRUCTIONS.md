# BookArchivist Testing Instructions
**Last Updated:** January 8, 2026  
**Status:** Phase 1 Complete - Production Ready

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

## 🧪 Testing Workflows

### Performance Testing (Phase 1 Validated ✅)

**Test async filtering with large datasets:**

1. **Generate test data:**
   ```lua
   /ba gentest 1000
   ```
   (Remember to logout/login to persist)

2. **Open main UI:**
   ```lua
   /ba
   ```

3. **Verify no freezing:**
   - UI should open in ~1 second
   - List filtering should be instant (<16ms)
   - No UI freezes during filtering

4. **Test filtering:**
   - Use search box with various queries
   - Toggle filters (favorites, locations)
   - Verify UI remains responsive

**Expected Results:**
- ✅ No UI freezing with 1000+ books
- ✅ Filtering completes in <16ms (60 FPS maintained)
- ✅ UI open time ~1 second

---

### Database Safety Testing (Phase 1 Validated ✅)

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
### Database Safety Testing (Phase 1 Validated ✅)

**Test corruption detection (optional):**

1. **Manually corrupt database:**
   ```lua
   /run BookArchivistDB = "corrupted string"
   /reload
   ```
   **Expected:** Popup shown, backup created, fresh DB initialized

2. **Verify recovery:**
   - Check for backup global variable (BookArchivistDB_Backup_CORRUPTED_*)
   - Confirm fresh DB created
   - No data loss for future captures

---

## 🛠️ Developer Commands

### Test Data Generation

```lua
/ba gentest <count>      -- Generate N test books
/ba genpreset small      -- 100 books
/ba genpreset medium     -- 500 books
/ba genpreset large      -- 1000 books
/ba genpreset stress     -- 5000 books
/ba cleartest            -- Remove all test books
```

**Remember:** Must logout/login to persist test books!

### Profiling (Optional)

```lua
/ba profile on           -- Enable profiler
/ba profile report       -- View full report
/ba profile summary      -- Quick summary
/ba profile slow         -- Top slowest operations
/ba profile reset        -- Clear profiling data
/ba profile off          -- Disable profiler
```

### Database Info

```lua
/ba stats                -- Database statistics
/badb                    -- Database debug info
/balist                  -- List all books in chat
```

### Debugging

```lua
/console scriptErrors 1  -- Enable Lua error reporting
/ba modules              -- Check module loading status
/ba help                 -- List all commands
```

---

## 🚨 TROUBLESHOOTING

### Problem: Commands don't work

**Fix:**
1. Enable error reporting: `/console scriptErrors 1`
2. Reload: `/reload`
3. Look for red error messages

### Problem: Test books disappear after reload

**Cause:** You reloaded instead of logging out.  
**Fix:** Always `/logout` after generating test data to persist it.

### Problem: UI freezes with large datasets

**Status:** Should not happen after Phase 1 optimizations.  
**If it does:** Report with dataset size and repro steps.

---

## 📋 Quick Reference

**Most Common Commands:**
- `/ba` - Toggle main UI
- `/ba gentest 100` - Generate test books
- `/ba cleartest` - Remove test books
- `/ba stats` - Database info

**Testing Performance:**
1. Generate 1000 test books
2. Logout/login to persist
3. Open UI with `/ba`
4. Verify no freezing (<1 second open time)

**Testing Safety:**
1. Corrupt DB manually
2. Reload
3. Verify popup and recovery

---

## ✅ Phase 1 Validation Checklist

After Phase 1 implementation, verify:

- [ ] No UI freezing with 1000+ books
- [ ] List filtering completes in <16ms
- [ ] UI opens in ~1 second
- [ ] Corruption detection shows popup
- [ ] Backup created on corruption
- [ ] Fresh DB initialized after corruption
- [ ] Test data generation works
- [ ] Test data clears properly

**All items above should pass. If not, Phase 1 has regressions.**
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

---

**Last Updated:** January 8, 2026

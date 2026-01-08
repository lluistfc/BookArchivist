# Debug Logging Guidelines

## Problem: Debug Message Spam

After implementing debug mode, the chat was flooded with hundreds of repetitive messages:
- `[DBSafety] Database validation passed` (repeated constantly)
- `[BookArchivist] refreshAll: starting rebuildFiltered`
- `[BookArchivist] UpdateList: Added 10 books to data provider`

## Solution: Tiered Logging Strategy

### ✅ ALWAYS LOG (No Debug Check Required)

**Critical Issues** - Things users MUST know:
- ❌ Corruption detected
- ❌ Migration failures
- ❌ Data loss warnings
- ⚠️ Auto-repair actions
- ⚠️ Performance degradation warnings

```lua
-- No check needed - always print
print("|cFFFF0000BookArchivist: CORRUPTION DETECTED|r")
```

### 🔵 DEBUG LOG (Check `options.debug`)

**Development Info** - Useful for developers/testers:
- ℹ️ Module load confirmations
- ℹ️ Major state changes (mode switch, filter applied)
- ℹ️ User-triggered actions (delete, share, import)
- ℹ️ Database operations (save, delete, update)

```lua
if BookArchivist and BookArchivist.DebugPrint then
  BookArchivist:DebugPrint("[BookArchivist] Switched to Locations mode")
end
```

### 🔇 VERBOSE LOG (Separate Flag)

**Trace-Level** - Only for deep debugging:
- Validation checks that pass
- Every UI refresh
- Every list update
- Every render cycle

```lua
-- NOT IMPLEMENTED YET - Future verbose mode
if BookArchivist and BookArchivist.options and BookArchivist.options.verbose then
  BookArchivist:DebugPrint("[DBSafety] Database validation passed")
end
```

---

## Applied Fixes

### 1. Removed Validation Spam

**File:** [core/BookArchivist_DBSafety.lua](core/BookArchivist_DBSafety.lua#L193-L196)

**Before:**
```lua
-- Database is valid
if BookArchivist and BookArchivist.DebugPrint then
  BookArchivist:DebugPrint("[DBSafety] Database validation passed")
end
return BookArchivistDB
```

**After:**
```lua
-- Database is valid - no message needed (reduces spam)
return BookArchivistDB
```

**Why:** Validation runs on every DB:Init() call. When valid, there's nothing interesting to report. Only log corruption/problems.

### 2. Removed Fresh DB Spam

**File:** [core/BookArchivist_DBSafety.lua](core/BookArchivist_DBSafety.lua#L142-L147)

**Before:**
```lua
if not BookArchivistDB then
  if BookArchivist and BookArchivist.DebugPrint then
    BookArchivist:DebugPrint("[DBSafety] No existing DB found, initializing fresh database")
  end
  return self:InitializeFreshDB()
end
```

**After:**
```lua
if not BookArchivistDB then
  -- First-time initialization (only log if really needed)
  return self:InitializeFreshDB()
end
```

**Why:** This only happens once per character first-time, not worth spamming about.

---

## Debug Logging Best Practices

### ✅ DO Log

1. **State transitions:**
   ```lua
   BookArchivist:DebugPrint("[BookArchivist] Switched to Books mode")
   ```

2. **User actions:**
   ```lua
   BookArchivist:DebugPrint("[BookArchivist] User deleted book: " .. bookId)
   ```

3. **Error recovery:**
   ```lua
   BookArchivist:DebugPrint("[DBSafety] Auto-repaired " .. count .. " orphaned books")
   ```

4. **Performance issues:**
   ```lua
   if elapsed > 100 then
     BookArchivist:DebugPrint("[WARNING] Slow operation: " .. elapsed .. "ms")
   end
   ```

### ❌ DON'T Log

1. **Validation success:**
   ```lua
   -- BAD: Spams chat
   BookArchivist:DebugPrint("[DBSafety] Database validation passed")
   ```

2. **Every render:**
   ```lua
   -- BAD: Called 60 times per second
   BookArchivist:DebugPrint("[Reader] Rendering page " .. pageNum)
   ```

3. **Every list update:**
   ```lua
   -- BAD: Called on every scroll/filter
   BookArchivist:DebugPrint("[List] UpdateList: Added " .. count .. " books")
   ```

4. **Routine operations:**
   ```lua
   -- BAD: Too granular
   BookArchivist:DebugPrint("[Core] Checking if book exists: " .. bookId)
   ```

### 🤔 MAYBE Log (Use Judgment)

1. **One-time setup:**
   ```lua
   -- OK: Only runs once at load
   BookArchivist:DebugPrint("[Profiler] Module loaded")
   ```

2. **Major operations:**
   ```lua
   -- OK: User-initiated, infrequent
   BookArchivist:DebugPrint("[Import] Starting import of " .. count .. " books")
   ```

3. **Expensive operations:**
   ```lua
   -- OK: Helps track performance issues
   BookArchivist:DebugPrint("[BookArchivist] refreshAll: starting rebuildFiltered")
   ```

---

## Future: Verbose Mode

For deep debugging (not implemented yet):

```lua
-- In BookArchivist_Core.lua or similar
function BookArchivist:VerbosePrint(msg)
  if self.options and self.options.verbose then
    self:DebugPrint(msg)
  end
end
```

Usage:
```lua
-- Only printed if verbose mode enabled
BookArchivist:VerbosePrint("[DBSafety] Database validation passed")
BookArchivist:VerbosePrint("[List] UpdateList: Added " .. count .. " books")
```

Enable with:
```lua
/run BookArchivistDB.options.verbose = true
```

---

## Testing After Fix

### Before Fix:
```
/reload
[DBSafety] Module loaded
[DBSafety] Database validation passed
[DBSafety] Database validation passed
[DBSafety] Database validation passed
[BookArchivist] rebuildFiltered: 13 matched of 13
[DBSafety] Database validation passed
[DBSafety] Database validation passed
[DBSafety] Database validation passed
... (hundreds more)
```

### After Fix:
```
/reload
[DBSafety] Module loaded
[Profiler] Module loaded
[TestDataGenerator] Module loaded
BookArchivist UI loaded. Type /ba to open.
```

Clean! Only module load confirmations appear.

---

## Command to Test

```lua
-- Enable debug mode
/run BookArchivistDB.options.debug = true
/reload

-- You should see:
-- - Module load messages (3-4 lines)
-- - UI loaded message
-- - Nothing else unless you perform actions

-- Open main UI
/ba

-- You should see:
-- - refreshAll messages (a few lines)
-- - No spam of "validation passed"
```

---

## Summary

- ❌ Removed: "Database validation passed" spam
- ❌ Removed: "No existing DB found" message
- ✅ Kept: Module load confirmations (once only)
- ✅ Kept: Critical errors and corruption warnings
- ✅ Kept: User-triggered action logs
- 📋 Future: Separate "verbose" flag for trace-level logging

**Result:** Debug mode is now useful instead of overwhelming.

# Busted Spy Compatibility with Duck-Typed Callbacks

## Background

Originally, BookArchivist used strict `type(x) == "function"` checks for extension points, which blocked testing tools. This has been **refactored as of v2.1.0+**.

## The Problem (Historical)

Strict `type(x) == "function"` checks are **overly defensive for extension points** and actively resist testing tools. Senior Lua developers avoid this pattern for callbacks and hooks.

```lua
-- Current code (BookArchivist_Capture.lua) - ANTI-PATTERN for extension points
if BookArchivist and type(BookArchivist.RefreshUI) == "function" then
    BookArchivist.RefreshUI()
end
```

This breaks:
- Busted spies (tables with `__call` metamethods)
- Proxy objects
- Wrapped callbacks
- Test instrumentation

## What Senior Lua Devs Do (Now Implemented)

### ✅ For Extension Points / Callbacks (our current code)
```lua
-- Idiomatic: truthy check + call attempt
if BookArchivist and BookArchivist.RefreshUI then
    BookArchivist.RefreshUI()
end
```

**Why:** Lua is duck-typed. If it's callable, it works. If not, you get a clear error at the call site.

**Test compatibility:** Works seamlessly with Busted's `spy.on()` - no workarounds needed.

### For Controlled Internal APIs
```lua
-- Strict type check is appropriate here
assert(type(callback) == "function", "callback must be a function")
```

**When to use:** Performance-critical paths, closed APIs, deliberate rejection of non-functions.

## Status: ✅ REFACTORED

All BookArchivist extension points now use duck-typed callable checks. Tests use Busted's native `spy.on()` without workarounds.

**Files refactored (v2.1.0+):**
- `core/BookArchivist_Capture.lua` - RefreshUI callback
- `ui/reader/BookArchivist_UI_Reader_Share.lua` - ExportBook/Export callbacks
- `ui/reader/BookArchivist_UI_Reader_Layout.lua` - RefreshUI callback
- `ui/list/BookArchivist_UI_List_Selection.lua` - RefreshUI callback
- `ui/options/BookArchivist_UI_Options.lua` - SetTooltipEnabled, SetResumeLastPageEnabled, SetLanguage, RefreshUI callbacks
- `ui/BookArchivist_UI_Core.lua` - DebugMessage, DebugPrint, GetDebugLog, ClearDebugLog, SetDebugEnabled, RefreshUI callbacks
- `ui/BookArchivist_UI_Frame_Builder.lua` - onShow, onAfterCreate option callbacks (also fixed bug where onAfterCreate was checked but never invoked)
- `ui/BookArchivist_UI_Frame_Chrome.lua` - OpenOptionsPanel callback
- `ui/BookArchivist_UI_Frame.lua` - OpenOptionsPanel callback

## Historical: The Workaround (No Longer Needed)

Before the refactor, we used **manual call tracking** to work around the type checks:

```lua
-- Manual spy (temporary solution)
local callCount = 0
BookArchivist.RefreshUI = function()
    callCount = callCount + 1
end

local spy = {
    getCallCount = function() return callCount end,
    reset = function() callCount = 0 end
}

-- Works with type() checks (historical workaround)
assert.equals(1, spy.getCallCount())
```

This approach is **no longer necessary** - all code now uses duck-typed checks.

## Benefits Achieved

The refactoring provides:
- ✅ More testable (works with Busted spies)
- ✅ More extensible (works with proxies/wrappers)
- ✅ More idiomatic (duck-typed Lua)
- ✅ Simpler (less defensive ceremony)

**Tradeoff:** Error happens at call site instead of guard. This is acceptable for callback-style code.

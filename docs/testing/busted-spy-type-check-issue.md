# Busted Spy Incompatibility with Strict `type()` Checks

## The Real Problem

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

## What Senior Lua Devs Do

### For Extension Points / Callbacks (our case)
```lua
-- Most idiomatic: truthy check + call attempt
if BookArchivist and BookArchivist.RefreshUI then
    BookArchivist.RefreshUI()
end
```

**Why:** Lua is duck-typed. If it's callable, it works. If not, you get a clear error at the call site.

### For Controlled Internal APIs
```lua
-- Strict type check is appropriate here
assert(type(callback) == "function", "callback must be a function")
```

**When to use:** Performance-critical paths, closed APIs, deliberate rejection of non-functions.

## Our Workaround

Since we can't change production code mid-release, we use **manual call tracking**:

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

-- Works with type() checks
assert.equals(1, spy.getCallCount())
```

## The Fix (Future Refactor)

Change `BookArchivist_Capture.lua` line 226 from:
```lua
if BookArchivist and type(BookArchivist.RefreshUI) == "function" then
```

To:
```lua
if BookArchivist and BookArchivist.RefreshUI then
```

This makes the code:
- ✅ More testable (works with Busted spies)
- ✅ More extensible (works with proxies/wrappers)
- ✅ More idiomatic (duck-typed Lua)
- ✅ Simpler (less defensive ceremony)

**Tradeoff:** Error happens at call site instead of guard. This is acceptable for callback-style code.

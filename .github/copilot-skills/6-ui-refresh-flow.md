# UI Architecture & Refresh Flow

## Overview
BookArchivist UI is built with **native WoW frames** (no XML, no Ace3 GUI except for import/export). The architecture separates concerns:
- **State layer** (`BookArchivist_UI.lua`) - ViewModel, shared state
- **Core layer** (`BookArchivist_UI_Core.lua`) - Safe refresh pipeline, error handling
- **Layout layer** (`BookArchivist_UI_Frame_Layout.lua`) - Frame construction
- **Module layer** (`ui/list/*`, `ui/reader/*`) - Specific panel logic

## Main Window Structure

### Frame Hierarchy
```
BookArchivistMainFrame (backdrop + draggable)
  ├─ TitleBar (InsetFrameTemplate3)
  │   ├─ TitleText
  │   ├─ OptionsButton
  │   └─ CloseButton
  │
  ├─ Body (container)
  │   ├─ LeftPanel (InsetFrameTemplate3)
  │   │   ├─ TabContainer (Books/Locations tabs)
  │   │   ├─ SearchBox (EditBox)
  │   │   ├─ FilterButtonRow (Favorites/Recent toggles)
  │   │   ├─ ScrollFrame (book list)
  │   │   │   └─ RowContainer (pooled button rows)
  │   │   └─ FooterRow (pagination controls)
  │   │
  │   └─ RightPanel (InsetFrameTemplate3)
  │       ├─ HeaderRow (book title + metadata)
  │       ├─ ActionRow (favorite/delete/share buttons)
  │       ├─ NavRow (prev/page/next buttons)
  │       ├─ ScrollFrame (book content)
  │       │   └─ SimpleHTML (rich text renderer)
  │       └─ StatusRow (location info)
  │
  └─ (Optional) DeleteConfirmDialog (modal overlay)
```

### Frame Templates Used
- **InsetFrameTemplate3:** Panel backgrounds with borders
- **UIPanelButtonTemplate:** Standard WoW buttons
- **UIPanelScrollFrameTemplate:** Scroll areas (legacy, deprecated)
- **BackdropTemplate:** Modal dialogs with custom backdrops
- **SimpleHTML:** Rich text rendering (HTML subset)

**No XML files** - All frames created in Lua via `CreateFrame()`.

## State Management

### ViewModel (Shared State)
**File:** `ui/BookArchivist_UI.lua`

```lua
ViewModel = {
  filteredKeys = {},          -- Array of book IDs matching current filters
  selectedKey = nil,          -- Currently selected book ID
  listMode = "books",         -- "books" or "locations"
}
```

**Accessed via:**
```lua
Internal.getFilteredKeys() → ViewModel.filteredKeys
Internal.getSelectedKey() → ViewModel.selectedKey
Internal.setSelectedKey(key)
```

### Refresh Flags
```lua
refreshFlags = {
  list = true,      -- List panel needs update
  reader = true,    -- Reader panel needs update
  location = true,  -- Location breadcrumbs need update
}
```

**Set via:**
```lua
Internal.setNeedsRefresh(true)  -- All flags
Internal.requestListRefresh()   -- list flag only
Internal.requestReaderRefresh() -- reader flag only
```

### Initialization State
```lua
isInitialized = false  -- UI frames exist and content is built
needsRefresh = false   -- Refresh queued but not yet flushed
```

**State machine:**
```
Start
  ↓
setupUI() → Frames created, __contentReady = false
  ↓
Async content build (tabs, buttons, etc.)
  ↓
__contentReady = true, isInitialized = true
  ↓
Refresh flushed
```

## Refresh Pipeline (Safe Execution)

### High-Level Flow
```lua
BookArchivist.RefreshUI()
  ↓
Internal.ensureUI()
  ↓
If not initialized:
  → setupUI() (create frames)
  → Wait for __contentReady
  → Set isInitialized = true
  ↓
Internal.flushPendingRefresh()
  ↓
If refreshFlags.list:
  → ListUI:RebuildFiltered()
  → ListUI:UpdateList()
  ↓
If refreshFlags.reader:
  → ReaderUI:RefreshReader()
  ↓
If refreshFlags.location:
  → ListUI:UpdateLocationBreadcrumb()
```

### Safe Execution Wrappers
**File:** `ui/BookArchivist_UI_Core.lua`

```lua
safeStep(label, fn)
  → xpcall(fn, captureError)
  → If error:
    - Log to BugSack (re-throw error)
    - Prevents cascade failures
  → Return success boolean
```

**Used in:**
```lua
refreshAll()
  → safeStep("RefreshList", function() ... end)
  → safeStep("RefreshReader", function() ... end)
  → safeStep("RefreshLocation", function() ... end)
```

**Why safe wrappers?**
- Errors in one panel don't break other panels
- Stack traces captured for debugging
- UI remains usable even if one component fails

### Debouncing (Future Improvement)
**Not currently implemented.** Rapid refreshes (e.g., during capture) can cause:
- Multiple rebuilds per second
- UI flicker
- Wasted CPU

**Proposed solution:** Throttle `flushPendingRefresh()` to max 1 refresh per 100ms.

## Frame Creation Patterns

### safeCreateFrame() Helper
**File:** `ui/BookArchivist_UI_Core.lua`

```lua
Internal.safeCreateFrame(frameType, name, parent, ...)
  → Try CreateFrame with each template (varargs)
  → If template fails, try next
  → If all fail, try CreateFrame without template
  → If still fails, log error and return nil
  → Never throws (defensive)
```

**Why template fallback?**
- Some templates missing in older WoW builds
- Ensures addon loads even if template unavailable
- Example: `BackdropTemplate` required in 9.0+, but optional in 8.3

**Usage:**
```lua
local button = safeCreateFrame("Button", "BookArchivistButton", parent, "UIPanelButtonTemplate")
if not button then
  -- Handle failure (rare, but possible)
end
```

### Frame Pooling (List Rows)
**File:** `ui/list/BookArchivist_UI_List_Rows_Core.lua`

```lua
buttonPool = {
  free = {},    -- Available buttons
  active = {},  -- In-use buttons
}

GetPooledButton()
  → If #free > 0:
    - button = table.remove(free)
    - table.insert(active, button)
    - Return button
  → Else:
    - button = CreateFrame("Button", ...)
    - table.insert(active, button)
    - Return button

ReleasePooledButton(button)
  → Remove from active
  → button:Hide()
  → table.insert(free, button)
```

**Why pool?**
- Creating frames is expensive (~1ms per frame)
- List can have 1000+ books (creating 1000 buttons = 1 second freeze)
- Pool reuses buttons (only visible rows need buttons)

**Pool size:**
- Grows to max visible rows (~25 buttons)
- Never shrinks (buttons cached forever)

## Module Communication

### Context Injection (Dependency Injection)
**File:** `ui/BookArchivist_UI_Core.lua` → `initializeModules()`

```lua
-- Build context object with callbacks
listModuleContext = {
  getAddon = Internal.getAddon,
  getWidget = Internal.getWidget,
  setSelectedKey = Internal.setSelectedKey,
  getSelectedKey = Internal.getSelectedKey,
  getFilteredKeys = Internal.getFilteredKeys,
  -- ... many more callbacks
}

-- Inject into modules
ListUI:Init(listModuleContext)
ReaderUI:Init(readerModuleContext)
```

**Why context injection?**
- Modules are loosely coupled (no global state dependencies)
- Testable (can inject mock context)
- Load order independent (context resolved at runtime)

### Module API Pattern
Each module follows this pattern:

```lua
local ModuleUI = {}
BookArchivist.UI.Module = ModuleUI

-- Private state
local state = ModuleUI.__state or {}
ModuleUI.__state = state

-- Initialize with context
function ModuleUI:Init(context)
  self.__state.ctx = context
end

-- Access context
function ModuleUI:GetContext()
  return self.__state.ctx or {}
end

-- Use context callbacks
function ModuleUI:DoSomething()
  local ctx = self:GetContext()
  local addon = ctx.getAddon and ctx.getAddon()
  -- ...
end
```

## Async Frame Building

### Why Async?
- **Problem:** Creating 50+ frames in one go freezes UI (300ms+)
- **Solution:** Yield to game engine every 8ms (maintains 60 FPS)

### Implementation
**File:** `ui/BookArchivist_UI_Frame_Builder.lua`

```lua
BuildContent(frame, components, callback)
  → For each component (tabs, buttons, etc.):
    - Create frames
    - If elapsed > 8ms:
      → C_Timer.After(0.001, continueBuilding)
      → Yield to game engine
    - Else:
      → Continue building
  → When done:
    - frame.__contentReady = true
    - callback()
```

**Effect:**
- Window opens immediately (shell visible)
- Content fades in over 100-200ms
- Game remains responsive (no freeze)

### Content Ready State
```lua
frame.__contentReady = false  -- During build
frame.__contentReady = true   -- After build complete
```

**Checked in:**
- `onShow` handler (defers refresh until content ready)
- `ensureUI` (waits for content before flushing refresh)

## Error Handling

### Error Propagation Strategy
**File:** `ui/BookArchivist_UI_Core.lua`

```lua
logError(message)
  → Re-throw error (don't print to chat)
  → Let BugSack/Bugsack catch it
  → Stack trace preserved
```

**Why re-throw?**
- Printing to chat is user-hostile (spam)
- BugSack provides better UX (dismissible dialog)
- Stack traces help debugging

**Previous behavior (removed):**
```lua
-- OLD: Printed to chat
DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Error:|r " .. msg)

-- NEW: Re-throw for BugSack
error(message, 2)
```

### Defensive Patterns
1. **Nil checks before API calls:**
   ```lua
   if not CreateFrame then return end
   ```

2. **Fallbacks for missing functions:**
   ```lua
   local logger = ctx.debugPrint or fallbackDebugPrint
   ```

3. **Safe frame access:**
   ```lua
   local button = self:GetFrame("myButton")
   if button and button.SetText then
     button:SetText("Hello")
   end
   ```

4. **xpcall wrappers:**
   ```lua
   local ok, err = xpcall(dangerousFunction, captureError)
   if not ok then
     logError("Operation failed: " .. err)
   end
   ```

## Frame Registry (Widget Tracking)

### Widget Storage
**File:** `ui/BookArchivist_UI.lua`

```lua
Widgets = {}  -- Global widget registry

Internal.rememberWidget(name, widget)
  → Widgets[name] = widget
  → UI[name] = widget  -- Also store on main frame

Internal.getWidget(name)
  → Return Widgets[name]
```

**Why double storage?**
- `Widgets` is module-accessible
- `UI[name]` is frame-accessible (for debugging)

**Naming convention:**
```lua
rememberWidget("searchBox", editBox)
rememberWidget("listScrollFrame", scrollFrame)
rememberWidget("readerContent", htmlFrame)
```

**Usage:**
```lua
local searchBox = Internal.getWidget("searchBox")
if searchBox then
  local query = searchBox:GetText()
end
```

## Layout Utilities

### Anchor Helpers
**File:** `ui/BookArchivist_UI_Frame_Layout.lua`

```lua
-- Anchor to parent with inset
frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)

-- Full-size child
frame:SetAllPoints(parent)

-- Center in parent
frame:SetPoint("CENTER", parent, "CENTER", 0, 0)
```

**Common patterns:**
- **Inset panels:** 10px padding from parent edges
- **Rows:** Stacked with 5-10px vertical spacing

### Size Constraints
```lua
frame:SetSize(width, height)       -- Fixed size
frame:SetWidth(width)              -- Fixed width, auto height
frame:SetHeight(height)            -- Fixed height, auto width
frame:SetMinResize(minW, minH)     -- Minimum size (for draggable frames)
frame:SetMaxResize(maxW, maxH)     -- Maximum size
```

**BookArchivist constraints:**
- **Main window:** Min 800×600, max 1920×1080
- **Left panel:** Fixed width
- **Right panel:** Fills remaining space
- **List rows:** Fixed 24px height

## Performance Optimizations

### Frame Creation
- **One-time cost:** Frames created once, reused forever
- **Async build:** Yields every 8ms (no freeze)
- **Pooling:** List rows pooled (max ~25 buttons cached)

### Refresh Performance
- **Incremental updates:** Only changed panels refresh
- **Filtered array:** Pre-computed (no iteration in render loop)
- **Row virtualization:** Only visible rows rendered (not all 1000 books)

### Memory
- **Frame cache:** ~50KB (main window + widgets)
- **Button pool:** ~25 buttons × 2KB = 50KB
- **SimpleHTML buffers:** ~10KB per book (released on book change)

## Common Patterns

### Trigger full refresh
```lua
BookArchivist.RefreshUI()
  → All panels refresh
```

### Trigger list-only refresh
```lua
Internal.requestListRefresh()
Internal.flushPendingRefresh()
```

### Get currently selected book
```lua
local bookId = Internal.getSelectedKey()
if bookId then
  local db = BookArchivist.Core:GetDB()
  local book = db.booksById[bookId]
  -- ...
end
```

### Manually update reader
```lua
local ReaderUI = BookArchivist.UI.Reader
ReaderUI:ShowBook(bookId)
```

### Check if UI is initialized
```lua
if Internal.getIsInitialized() then
  -- UI exists, safe to refresh
end
```

## Important Notes

1. **Native frames only:** No XML, no Ace3 GUI (except AceGUI MultiLineEditBox for import/export)
2. **Async build:** Window shell appears immediately, content builds over 100-200ms
3. **Safe refresh:** Errors in one panel don't cascade to others
4. **No global pollution:** All state in `BookArchivist.UI.Internal` namespace
5. **Module independence:** Modules communicate via context injection (no shared globals)
6. **Frame pooling critical:** Without pooling, 1000-book list causes 1-second freeze
7. **Refresh debouncing needed:** Current implementation can refresh multiple times per second (future improvement)

## Related Files
- `ui/BookArchivist_UI.lua` - State management, ViewModel
- `ui/BookArchivist_UI_Core.lua` - Safe refresh pipeline, error handling
- `ui/BookArchivist_UI_Frame.lua` - Main window setup
- `ui/BookArchivist_UI_Frame_Layout.lua` - Frame construction
- `ui/BookArchivist_UI_Frame_Builder.lua` - Async content building
- `ui/list/BookArchivist_UI_List.lua` - List panel module
- `ui/reader/BookArchivist_UI_Reader.lua` - Reader panel module

## Future Improvements (Not Implemented)
- Refresh debouncing (throttle to 100ms)
- Virtual scrolling (only render visible rows, not all filtered)
- Progressive loading (load first 100 books, then load more on scroll)
- Frame caching (cache book content HTML to avoid re-rendering)

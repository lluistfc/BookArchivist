# BookArchivist Module Dependency Graph

This document maps the dependency relationships between BookArchivist modules based on TOC load order and runtime references.

## Load Order (TOC)

Files load in the order defined in `BookArchivist.toc`. Dependencies can only be on modules loaded **before** them.

## Dependency Layers

### Layer 0: Bootstrap (Foundation)
**Must load first** - Creates global namespace and core infrastructure.

```
┌─────────────────────────────────────┐
│   core/BookArchivist.lua            │  ← Bootstrap (creates BookArchivist global)
│   - Creates: BookArchivist table    │
│   - Provides: DebugPrint, LogError  │
│   - Provides: __createFrame shim    │
│   - Event: ADDON_LOADED handler     │
└─────────────────────────────────────┘
```

**Why first?** All other modules start with `local BA = BookArchivist` - this must exist!

---

### Layer 1: Pure Utility Modules
**No dependencies** - Can load in any order after Layer 0.

```
┌──────────────────────────────────────────────────────────────────────┐
│  core/BookArchivist_Repository.lua    │  Dependency injection for DB  │
│  core/BookArchivist_BookId.lua        │  ID generation utilities      │
│  core/BookArchivist_Book.lua          │  Book data structures         │
│  core/BookArchivist_Migrations.lua    │  DB schema migrations         │
│  core/BookArchivist_DBSafety.lua      │  DB validation                │
│  core/BookArchivist_Iterator.lua     │  Async iteration              │
│  core/BookArchivist_Serialize.lua    │  AceSerializer wrapper        │
│  core/BookArchivist_Base64.lua       │  Encoding/decoding            │
│  core/BookArchivist_CRC32.lua        │  Checksum utilities           │
│  core/BookArchivist_Profiler.lua     │  Performance profiling        │
│  core/BookArchivist_ContentSanitizer.lua │  Text sanitization        │
│  core/BookArchivist_TextureValidator.lua │  Texture validation       │
└──────────────────────────────────────────────────────────────────────┘
```

---

### Layer 2: Database & Data Access
**Depends on:** Repository, Migrations, Iterator, Serialize

```
┌────────────────────────────────────────────────┐
│  core/BookArchivist_DB.lua                     │
│  - Depends on: Repository                      │
│  - Provides: Low-level DB operations           │
└────────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────┐
│  core/BookArchivist_Core.lua                   │
│  - Depends on: Repository, Iterator, Search    │
│  - Depends on: Migrations, Serialize, Base64   │
│  - Provides: EnsureDB, PersistSession          │
│  - Provides: GetDB, Now, BuildSearchText       │
│  - Exposes: BA.Core (central API)              │
└────────────────────────────────────────────────┘
```

---

### Layer 3: Core Feature Modules
**Depends on:** Core, Repository, Iterator

```
┌──────────────────────────────────────────────────────────┐
│  core/BookArchivist_Search.lua                           │
│  - Depends on: (none, pure utility)                      │
│  - Provides: BuildSearchText, NormalizeSearchText        │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  core/BookArchivist_Favorites.lua                        │
│  - Depends on: Repository, Core (for Now)               │
│  - Provides: Set, Toggle, IsFavorite                     │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  core/BookArchivist_Recent.lua                           │
│  - Depends on: Repository, Core (for Now)               │
│  - Provides: MarkOpened, GetList (MRU tracking)          │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  core/BookArchivist_RandomBook.lua                       │
│  - Depends on: Repository                                │
│  - Provides: GetRandom, GetRandomFromZone                │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  core/BookArchivist_BookEcho.lua                         │
│  - Depends on: Repository                                │
│  - Provides: GetEchoText (memory reflections)            │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  core/BookArchivist_Order.lua                            │
│  - Depends on: (minimal)                                 │
│  - Provides: Order management utilities                  │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  core/BookArchivist_ListConfig.lua                       │
│  - Depends on: Core (for EnsureDB)                       │
│  - Provides: List configuration state                    │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  core/BookArchivist_Options.lua                          │
│  - Depends on: (minimal)                                 │
│  - Provides: Options/settings management                 │
└──────────────────────────────────────────────────────────┘
```

---

### Layer 4: Export/Import System
**Depends on:** Core, Serialize, Base64, CRC32, Iterator

```
┌────────────────────────────────────────────────┐
│  core/BookArchivist_Export.lua                 │
│  - Depends on: Serialize, Base64, CRC32        │
│  - Provides: EncodeBDB1Envelope                │
│  - Exposes: Core._DecodeBDB1Envelope           │
└────────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────┐
│  core/BookArchivist_ImportWorker.lua           │
│  - Depends on: Core, Iterator, Recent          │
│  - Provides: Async 6-phase import pipeline     │
└────────────────────────────────────────────────┘
```

---

### Layer 5: World Interaction
**Depends on:** Core, Location (for Capture)

```
┌────────────────────────────────────────────────┐
│  core/BookArchivist_Location.lua               │
│  - Depends on: (WoW APIs only)                 │
│  - Provides: BuildWorldLocation, GetLootLoc    │
└────────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────┐
│  core/BookArchivist_Capture.lua                │
│  - Depends on: Core, Location                  │
│  - Events: ITEM_TEXT_BEGIN/READY/CLOSED        │
│  - Provides: OnBegin, OnReady, OnClosed        │
└────────────────────────────────────────────────┘
```

---

### Layer 6: Integration Features
**Depends on:** Core, Repository

```
┌────────────────────────────────────────────────┐
│  core/BookArchivist_Tooltip.lua                │
│  - Depends on: Core (for GetDB)                │
│  - Hooks: GameTooltip                          │
│  - Shows: "Archived ✓" on items/objects        │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│  core/BookArchivist_ChatLinks.lua              │
│  - Depends on: Core                            │
│  - Provides: RegisterLinkedBook, chat linking  │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│  core/BookArchivist_Minimap.lua                │
│  - Depends on: LibDBIcon, Core                 │
│  - Provides: Minimap button integration        │
└────────────────────────────────────────────────┘
```

---

### Layer 7: Localization
**Depends on:** Core (for GetLanguage)

```
┌────────────────────────────────────────────────┐
│  locales/enUS.lua                              │
│  locales/esES.lua                              │
│  locales/caES.lua                              │
│  locales/deDE.lua                              │
│  locales/frFR.lua                              │
│  locales/itIT.lua                              │
│  locales/ptBR.lua                              │
└────────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────┐
│  core/BookArchivist_Locale.lua                 │
│  - Depends on: Core (for GetLanguage)          │
│  - Provides: BA.L (localized strings)          │
└────────────────────────────────────────────────┘
```

---

### Layer 8: UI System
**Depends on:** Core, Repository, Iterator, Favorites, Recent, Search, Location

```
┌────────────────────────────────────────────────┐
│  ui/BookArchivist_UI_Metrics.lua               │
│  - Provides: UI dimensions & spacing constants │
└────────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────┐
│  ui/BookArchivist_UI_FramePool.lua             │
│  - Provides: Frame pooling for row reuse       │
└────────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────┐
│  ui/list/* (List Panel Modules)                │
│  - BookArchivist_UI_List.lua                   │
│  - BookArchivist_UI_List_Sort.lua              │
│  - BookArchivist_UI_List_Categories.lua        │
│  - BookArchivist_UI_List_Header.lua            │
│  - BookArchivist_UI_List_Selection.lua         │
│  - BookArchivist_UI_List_Search.lua            │
│  - BookArchivist_UI_List_Pagination.lua        │
│  - BookArchivist_UI_List_Rows_Core.lua         │
│  - BookArchivist_UI_List_Layout.lua            │
│  - BookArchivist_UI_List_Tabs.lua              │
│  - BookArchivist_UI_List_Filter.lua            │
│  - BookArchivist_UI_List_Location.lua          │
│  - BookArchivist_UI_List_Rows.lua              │
│  Depends on: Core, Repository, Iterator        │
│  Depends on: Favorites, Recent, Search         │
└────────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────┐
│  ui/reader/* (Reader Panel Modules)            │
│  - BookArchivist_UI_Reader.lua                 │
│  - BookArchivist_UI_Reader_EditMode.lua        │
│  - BookArchivist_UI_Reader_ArtifactAtlas.lua   │
│  - BookArchivist_UI_Reader_HTML.lua            │
│  - BookArchivist_UI_Reader_Rich_Parse.lua      │
│  - BookArchivist_UI_Reader_Rich.lua            │
│  - BookArchivist_UI_Reader_Delete.lua          │
│  - BookArchivist_UI_Reader_Share.lua           │
│  - BookArchivist_UI_Reader_Layout.lua          │
│  Depends on: Core, Repository, Favorites       │
│  Depends on: BookEcho                          │
└────────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────┐
│  ui/options/* (Options Panel)                  │
│  - BookArchivist_UI_OptionsTemplates.xml       │
│  - BookArchivist_UI_Options.lua                │
│  Depends on: Core, Options module              │
│  Integration: Blizzard Settings UI             │
└────────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────┐
│  ui/BookArchivist_UI.lua                       │
│  ui/BookArchivist_UI_Core.lua                  │
│  ui/BookArchivist_UI_Frame_Shell.lua           │
│  ui/BookArchivist_UI_Frame_Layout.lua          │
│  ui/BookArchivist_UI_Frame_Chrome.lua          │
│  ui/BookArchivist_UI_Frame_Builder.lua         │
│  ui/BookArchivist_UI_Frame.lua                 │
│  ui/BookArchivist_UI_Runtime.lua               │
│  Depends on: All UI modules, Core              │
│  Provides: Main window, RefreshUI, ToggleUI    │
└────────────────────────────────────────────────┘
```

---

## Critical Dependency Rules

### 1. Bootstrap First (Layer 0)
```
BookArchivist.lua MUST load before ANY other module
Reason: Creates the BookArchivist global table
```

### 2. Repository Pattern (Layer 1)
```
Repository.lua provides dependency injection for DB access
All modules use Repository:GetDB() instead of global access
Tests inject mock DB via Repository:Init(testDB)
```

### 3. Core Before Features (Layer 2 → 3)
```
Core.lua MUST load before:
- Favorites (needs Core.Now)
- Recent (needs Core.Now)
- Capture (needs Core.PersistSession)
- ImportWorker (needs Core._DecodeBDB1Envelope)
```

### 4. Location Before Capture (Layer 5)
```
Location.lua MUST load before Capture.lua
Capture uses Location.BuildWorldLocation() during book capture
```

### 5. Localization Before UI (Layer 7 → 8)
```
Locale.lua MUST load before UI modules
All UI uses BA.L for localized strings
```

### 6. Runtime Resolution (Critical!)
```lua
-- ❌ WRONG - Captures nil at load time
local Core = BookArchivist.Core

-- ✅ CORRECT - Resolves at runtime
if BookArchivist.Core and BookArchivist.Core.Method then
    BookArchivist.Core:Method()
end
```

**Why?** TOC loads `BookArchivist.lua` before `BookArchivist_Core.lua`, so `BookArchivist.Core` is `nil` at load time. Variables assigned at load time capture `nil` permanently.

---

## Initialization Sequence (ADDON_LOADED)

```
1. WoW Engine loads SavedVariables (BookArchivistDB)
2. ADDON_LOADED event fires
3. BookArchivist.lua event handler runs:
   ├─ Set isInitializing = true (prevents circular deps)
   ├─ Repository:Init(BookArchivistDB) — inject initial DB
   ├─ Core:EnsureDB() — run migrations (may create new DB table)
   ├─ Repository:Init(BookArchivistDB) — re-inject migrated DB
   ├─ Set isInitializing = false
   ├─ Minimap:Initialize()
   ├─ Tooltip:Initialize()
   └─ ChatLinks:Init()
4. User opens UI → UI modules render using Core/Repository
```

**Key:** Repository needs TWO Init() calls:
- Before EnsureDB: So Core can access DB during migrations
- After EnsureDB: DB reference might have changed

---

## Module Communication Patterns

### Pattern 1: Direct Dependency (Load Order)
```lua
-- BookArchivist_Capture.lua depends on Location
local Location = BookArchivist.Location
if Location and Location.BuildWorldLocation then
    local loc = Location:BuildWorldLocation()
end
```

### Pattern 2: Repository Pattern (Injected DB)
```lua
-- All modules use Repository instead of global
local db = BookArchivist.Repository:GetDB()
```

### Pattern 3: Event-Driven (Loose Coupling)
```lua
-- Bootstrap calls initialization methods
if BookArchivist.Minimap and BookArchivist.Minimap.Initialize then
    BookArchivist.Minimap:Initialize()
end
```

---

## Dependency Violation Detection

**Symptoms of load order problems:**
- Module is `nil` when accessed
- "attempt to index nil value" errors
- Methods return nil unexpectedly
- UI appears empty despite data existing

**Fix:** Ensure dependency loads BEFORE dependent in TOC, or use runtime resolution.

---

## Testing Implications

### Repository Isolation Pattern
```lua
-- Tests inject mock DB
before_each(function()
    local testDB = { booksById = {}, order = {} }
    Repository:Init(testDB)  -- Inject test DB
end)

after_each(function()
    Repository:Init(BookArchivistDB)  -- Restore production DB
end)
```

**Why:** Prevents test pollution and allows isolated testing without global state.

---

## Quick Reference: "What Does X Depend On?"

| Module | Dependencies |
|--------|-------------|
| **BookArchivist.lua** | (none - bootstrap) |
| **Repository** | (none) |
| **Core** | Repository, Migrations, Iterator, Serialize |
| **Favorites** | Repository, Core (Now) |
| **Recent** | Repository, Core (Now) |
| **Capture** | Core, Location |
| **ImportWorker** | Core, Iterator, Recent |
| **Tooltip** | Core (GetDB) |
| **Minimap** | LibDBIcon, Core |
| **UI Modules** | Core, Repository, Iterator, Favorites, Recent, Search |

---

## Visual Summary

```
Bootstrap (BookArchivist.lua)
    ↓
Utilities (Repository, Iterator, Serialize, etc.)
    ↓
Core (Central API + DB Management)
    ↓
Features (Favorites, Recent, Search, etc.)
    ↓
World Interaction (Location, Capture)
    ↓
Integration (Tooltip, ChatLinks, Minimap)
    ↓
Localization (Locale.lua)
    ↓
UI System (List, Reader, Options)
```

**Rule:** Lower layers never depend on higher layers.

---

**Generated:** January 19, 2026  
**For:** BookArchivist v3.x  
**Maintained by:** Dependency analysis of TOC load order and module imports

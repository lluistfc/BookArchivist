# SavedVariables Audit Report

## Options Currently in SavedVariables

### ✅ ACTIVELY USED (Keep)

| Option | Location | Purpose | Usage |
|--------|----------|---------|-------|
| `debug` | `options.debug` | Dev mode toggle | Read by UI_Frame, UI, DevOptions, DB; controls debug features |
| `uiDebug` | `options.uiDebug` | UI debug grid | Read by UI_Frame, UI, DevOptions, Options, DB; controls debug grid overlay |
| `language` | `options.language` | Addon language | Read/written by Core, UI_Options; controls localization |
| `ui.virtualCategoriesEnabled` | `options.ui.virtualCategoriesEnabled` | Enable virtual categories | Read/written by Options, Core; controls category display |
| `ui.listWidth` | `options.ui.listWidth` | Left panel width | Read/written by UI_Frame, Options, Core; controls list panel size |
| `ui.resumeLastPage` | `options.ui.resumeLastPage` | Resume reading position | Read/written by Options, Core; controls bookmark behavior |
| `tooltip.enabled` | `options.tooltip.enabled` | Show tooltip tags | Read by Tooltip, Options, Core; controls item tooltip injection |
| `list.sortMode` | `options.list.sortMode` | List sort order | Read/written by Core, ListConfig; controls book ordering |
| `list.pageSize` | `options.list.pageSize` | Items per page | Read/written by Pagination, ListConfig, Core; controls list pagination |
| `list.filters.favoritesOnly` | `options.list.filters.favoritesOnly` | Favorites filter | Read by List_Location, List_Header, Core; filters book list |
| `list.filters.multiPage` | `options.list.filters.multiPage` | Multi-page filter | Read by List_Header; filters book list |
| `list.filters.unread` | `options.list.filters.unread` | Unread filter | Read by List_Header; filters book list |
| `list.filters.hasLocation` | `options.list.filters.hasLocation` | Has location filter | Read by List_Header; filters book list |
| `minimapButton` | `options.minimapButton` | Minimap icon state | Read/written by Core; stores minimap button position |

### ⚠️ PARTIALLY USED (Functional but legacy)

| Option | Location | Purpose | Status |
|--------|----------|---------|--------|
| `debugEnabled` | `options.debugEnabled` | Legacy debug flag | **DUPLICATE** - Options.lua reads it for migration to `debug` but then should be removed. Currently being cleaned by v2 migration. |

### 🗑️ DEAD CODE (Safe to remove via migration)

| Option | Location | First Seen | Last Used | Safe to Remove? |
|--------|----------|------------|-----------|-----------------|
| `gridMode` | `options.gridMode` | v1.0.2 | Only in DevTools | **YES** - Dev-only feature, only meaningful when DevTools loaded. Already cleaned by v2 migration. |
| `gridVisible` | `options.gridVisible` | v1.0.2 | Only in DevTools | **YES** - Dev-only feature, only meaningful when DevTools loaded. Already cleaned by v2 migration. |
| `ba_hidden_anchor` | `options.ba_hidden_anchor` | Unknown | Options UI hack | **YES** - Used only as a Settings API hack to disable defaults button. Never actually read. Already cleaned by v2 migration. |

## Analysis

### 1. `debugEnabled` - Duplicate Legacy Option
- **Issue**: Exists alongside `debug` in Options
- **Current behavior**: 
  - Options.lua migrates `debugEnabled` → `debug` on first read
  - Both exist in SavedVariables (redundant)
- **Recommendation**: **Already handled** - v2 migration removes it
- **Impact**: None - migration converts to `debug` before removal

### 2. `gridMode` & `gridVisible` - Dev-Only Features
- **Issue**: Stored in production SavedVariables but only used when dev TOC loaded
- **Current behavior**:
  - Set/read by DevTools.lua and DevOptions.lua (not loaded in production)
  - Persisted in regular users' SavedVariables (dead weight)
- **Recommendation**: **Already handled** - v2 migration removes them
- **Impact**: None - only functional when DevTools present (dev environment)

### 3. `ba_hidden_anchor` - Dead Options UI Hack
- **Issue**: Leftover from previous Options panel implementation
- **Previous purpose**: Attempted to hack Blizzard Settings API to disable "Defaults" button (UI_Options.lua:108-122)
- **Current behavior**:
  - Code registered dummy setting with overridden GetValue/SetValue
  - Never actually read or used for functionality
  - Pollutes SavedVariables
  - **User tested**: Removing from SavedVariables has no effect - defaults button still doesn't appear
- **Recommendation**: **Already handled** - v2 migration removes it, dead code removed from UI_Options.lua
- **Impact**: None - non-functional leftover code

### 4. `list.filters.hasAuthor` - Already Cleaned
- **Found in**: Core.lua:274-275 (cleanup code)
- **Status**: Already has cleanup code that removes it during addon initialization
- **Safe**: Already handled by existing cleanup

## Recommendations Summary

### Immediate Actions Taken
✅ All four legacy options (`debugEnabled`, `gridMode`, `gridVisible`, `ba_hidden_anchor`) are now cleaned by v2 migration in Migrations.lua:180-183

### Future Improvements
1. **ba_hidden_anchor alternative**: Consider removing the hack entirely and just hiding the defaults button via category API
2. **Dev options isolation**: Consider moving dev-only options to separate SavedVariable table (e.g., `BookArchivistDevDB`)

### Migration Plan Status
- [x] v2 migration cleans legacy debug options
- [x] Test suite validates cleanup (test 17)
- [ ] User in-game testing with /reload
- [ ] Verify SavedVariables no longer contains removed fields after migration

## Testing Checklist

Before committing:
- [x] Test suite passes (17/17 tests)
- [ ] In-game test: /reload with v1.0.2 SavedVariables
- [ ] Verify removed options no longer in SavedVariables after migration
- [ ] Confirm all functional options still work
- [ ] Test dev environment (dev TOC loaded) still works

## Safe to Remove?

**YES** - All identified dead code is safe to remove:
1. Only used by optional dev components
2. Never read in production code paths
3. Duplicate/legacy versions have migration paths
4. v2 migration already implements cleanup

**Impact**: Zero functional impact, reduces SavedVariables size, cleaner data model.

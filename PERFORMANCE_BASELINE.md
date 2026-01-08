# BookArchivist Performance Baselines
**Date:** January 8, 2026  
**Purpose:** Track performance metrics before and after optimizations

---

## Test Environment

- **WoW Version:** 11.0.0 (Retail)
- **Lua Version:** 5.1 (WoW embedded)
- **Hardware:** [To be filled by user]
- **AddOns Loaded:** BookArchivist only (isolated testing)

---

## Baseline Metrics (BEFORE Optimizations)

### Test Dataset: 100 Books
| Metric | Time (ms) | Memory (KB) | Notes |
|--------|-----------|-------------|-------|
| Login → ADDON_LOADED | _____ms | _____KB | Time from login to addon ready |
| Login → UI Ready | _____ms | _____KB | Time to full UI render |
| Open Main Window | _____ms | _____KB | First open after login |
| List Refresh (full) | _____ms | _____KB | Full list rebuild |
| Search (10 char query) | _____ms | _____KB | Search operation |
| Filter Toggle | _____ms | _____KB | Change filter state |
| Import 100 books | _____ms | _____KB | Import operation |

### Test Dataset: 500 Books
| Metric | Time (ms) | Memory (KB) | Notes |
|--------|-----------|-------------|-------|
| Login → ADDON_LOADED | _____ms | _____KB | |
| Login → UI Ready | _____ms | _____KB | |
| Open Main Window | _____ms | _____KB | |
| List Refresh (full) | _____ms | _____KB | |
| Search (10 char query) | _____ms | _____KB | |
| Filter Toggle | _____ms | _____KB | |
| Scroll Performance | _____fps | _____KB | Frame rate while scrolling |

### Test Dataset: 1000 Books (TARGET SCALE)
| Metric | Time (ms) | Memory (KB) | Notes |
|--------|-----------|-------------|-------|
| Login → ADDON_LOADED | _____ms | _____KB | **CRITICAL: Should be <500ms** |
| Login → UI Ready | _____ms | _____KB | |
| Open Main Window | _____ms | _____KB | |
| List Refresh (full) | _____ms | _____KB | **CRITICAL: Should be <16ms (60fps)** |
| Search (10 char query) | _____ms | _____KB | **TARGET: <50ms** |
| Filter Toggle | _____ms | _____KB | |
| Scroll Performance | _____fps | _____KB | **TARGET: 60fps sustained** |

### Test Dataset: 2500 Books (STRESS TEST)
| Metric | Time (ms) | Memory (KB) | Notes |
|--------|-----------|-------------|-------|
| Login → ADDON_LOADED | _____ms | _____KB | Should not freeze UI |
| Login → UI Ready | _____ms | _____KB | |
| Open Main Window | _____ms | _____KB | |
| List Refresh (full) | _____ms | _____KB | |
| Search (10 char query) | _____ms | _____KB | |

### Test Dataset: 5000 Books (EXTREME STRESS)
| Metric | Time (ms) | Memory (KB) | Notes |
|--------|-----------|-------------|-------|
| Login → ADDON_LOADED | _____ms | _____KB | **Acceptable limit: <2000ms** |
| Login → UI Ready | _____ms | _____KB | |
| Open Main Window | _____ms | _____KB | |
| List Refresh (full) | _____ms | _____KB | |

---

## Memory Leak Detection

### Test: Open/Close UI 100 Times (1000 Books)
| Measurement | Memory (KB) | Delta | Notes |
|-------------|-------------|-------|-------|
| Before test | _____KB | - | After collectgarbage() |
| After 25 cycles | _____KB | _____KB | |
| After 50 cycles | _____KB | _____KB | |
| After 75 cycles | _____KB | _____KB | |
| After 100 cycles | _____KB | _____KB | **Should be <100KB increase** |

---

## Critical Operations Profiling

### Database Initialization (ensureDB)
| Dataset | Time (ms) | Iterations | Notes |
|---------|-----------|------------|-------|
| 100 books | _____ms | _____ | |
| 500 books | _____ms | _____ | |
| 1000 books | _____ms | _____ | |
| 5000 books | _____ms | _____ | |

### Title Index Backfill (pairs iteration)
| Dataset | Time (ms) | Books Processed | Notes |
|---------|-----------|-----------------|-------|
| 100 books | _____ms | _____ | |
| 500 books | _____ms | _____ | |
| 1000 books | _____ms | _____ | **CRITICAL: May freeze UI** |
| 5000 books | _____ms | _____ | **CRITICAL: Will freeze UI** |

### List Filtering (GetFilteredKeys)
| Dataset | Filter | Time (ms) | Results | Notes |
|---------|--------|-----------|---------|-------|
| 1000 books | None | _____ms | _____ | |
| 1000 books | Favorites | _____ms | _____ | |
| 1000 books | Has Location | _____ms | _____ | |
| 1000 books | Search "test" | _____ms | _____ | |

### Search Text Building
| Pages per Book | Time (ms) | Notes |
|----------------|-----------|-------|
| 1 page | _____ms | |
| 10 pages | _____ms | |
| 50 pages | _____ms | **Common case** |
| 100 pages | _____ms | **Worst case** |

---

## Known Bottlenecks (BEFORE Optimizations)

### 1. Unthrottled Database Iteration
**Location:** `Core.lua:168-176` (title index backfill)  
**Impact:** CRITICAL - Freezes UI on login with 1000+ books  
**Measured:** _____ms with 1000 books  
**Expected After Fix:** <500ms (throttled)

### 2. No Frame Pooling
**Location:** `UI_List_Rows.lua`  
**Impact:** MAJOR - Memory leak, frame creation overhead  
**Measured:** _____KB increase per 100 list refreshes  
**Expected After Fix:** <10KB increase (stable pool)

### 3. String Concatenation in Loops
**Location:** `BookArchivist_Search.lua:buildSearchText`  
**Impact:** MODERATE - Repeated allocations  
**Measured:** _____ms for 50-page book  
**Expected After Fix:** <5ms (table.concat)

### 4. Redundant DB Access
**Location:** Throughout (every function calls GetDB)  
**Impact:** MODERATE - Wasted CPU cycles  
**Measured:** _____ GetDB calls per list refresh  
**Expected After Fix:** 1 call per refresh (cached)

### 5. Full List Rebuild on Filter Change
**Location:** `UI_List.lua:UpdateList`  
**Impact:** MAJOR - Unnecessary work  
**Measured:** _____ms to toggle filter (1000 books)  
**Expected After Fix:** <16ms (cached filtered lists)

---

## Target Performance Goals (AFTER Phase 1-3)

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Login with 1000 books | _____ms | <500ms | ⏳ |
| Login with 5000 books | _____ms | <2000ms | ⏳ |
| List refresh (1000 books) | _____ms | <16ms | ⏳ |
| Search (1000 books) | _____ms | <50ms | ⏳ |
| Memory stability | _____KB/hr | <100KB/hr | ⏳ |
| Cache hit rate | N/A | >80% | ⏳ |
| Frame pool reuse | N/A | >90% | ⏳ |

Legend:
- ⏳ Not started
- 🔄 In progress
- ✅ Achieved
- ❌ Failed

---

## How to Collect Baseline Metrics

### 1. Generate Test Data
```lua
/bagentest 1000  -- Generates 1000 test books
```

### 2. Enable Profiler
```lua
/ba profile on
```

### 3. Perform Test Operations
- Login (measure to UI ready)
- Open main window
- Refresh list multiple times
- Search with various queries
- Toggle filters
- Scroll through entire list

### 4. View Results
```lua
/ba profile report
/ba profile summary
```

### 5. Memory Baseline
```lua
-- Before test
/run collectgarbage("collect"); print(collectgarbage("count"))

-- Perform operations

-- After test
/run collectgarbage("collect"); print(collectgarbage("count"))
```

---

## Post-Optimization Metrics (AFTER)

### Phase 1 Complete: Critical Fixes
| Metric | Before | After | Improvement | Status |
|--------|--------|-------|-------------|--------|
| Login (1000 books) | _____ms | _____ms | ___% | ⏳ |
| Title index backfill | _____ms | _____ms | ___% | ⏳ |
| Memory leak (100 cycles) | _____KB | _____KB | ___% | ⏳ |

### Phase 2 Complete: Performance
| Metric | Before | After | Improvement | Status |
|--------|--------|-------|-------------|--------|
| List refresh | _____ms | _____ms | ___% | ⏳ |
| Search operation | _____ms | _____ms | ___% | ⏳ |
| Cache hit rate | N/A | ___% | - | ⏳ |
| String allocs | _____KB | _____KB | ___% | ⏳ |

### Phase 3 Complete: Architecture
| Metric | Impact | Status |
|--------|--------|--------|
| Error handling | Consistent | ⏳ |
| API surface | Clean | ⏳ |
| Code duplication | Eliminated | ⏳ |
| Event system | Modular | ⏳ |

---

## Notes and Observations

### Performance Characteristics
- Linear scaling: O(n) with book count
- Quadratic patterns detected: [List specific code paths]
- Memory consumption: [Observations]

### User Experience
- Perceived performance: [Fast / Acceptable / Slow / Unacceptable]
- UI responsiveness: [Smooth / Stutters / Freezes]
- Load times: [Acceptable / Long / Too long]

### Hardware Impact
- Low-end hardware: [Performance notes]
- High-end hardware: [Performance notes]

---

**REMEMBER:** These metrics are YOUR PROOF that optimizations work.  
Without baselines, you're just guessing. Measure everything.

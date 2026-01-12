# Copilot Instructions — BookArchivist

Repository-wide rules for WoW addon development. Follow unless explicitly overridden.

---

## ⛔ MANDATORY GATE: TEST-DRIVEN DEVELOPMENT

**STOP: Read this before writing ANY code.**

### Rule Zero: Tests Are NOT Optional

When the user requests code changes, you MUST:

1. **STOP** - Do not write any implementation code yet
2. **CHECK** - Run `grep_search` for existing tests in `tests/` folder
3. **VERIFY** - Understand current test structure and patterns
4. **PLAN** - Identify what tests need to be written/updated
5. **CONFIRM** - Tell the user: "I need to check/write tests first"
6. **TEST** - Run `make test-errors` to establish baseline
7. **IMPLEMENT** - Only then write the actual feature code
8. **VALIDATE** - Run `make test-errors` again, all tests must pass (257+ as of v2.1.0)
9. **COMMIT-GATE** - If tests fail, the task is NOT complete

### This Applies To

✅ **YES - Test first:**
- New features
- Bug fixes
- Refactoring
- Architecture changes
- Export/import modifications
- Database schema changes

❌ **NO - Test not required:**
- Documentation-only changes
- Comments-only changes
- Localization string additions (unless logic changes)

### Enforcement

If you write code before confirming test status:
- You have failed this directive
- The code is untrusted
- User should call you out immediately

**Remember: "Implementation complete" means tests pass, not "code written".**

---

## 📋 Make Commands Reference

### Test Commands (ALWAYS use test-errors)
```bash
make test-errors       # Full error stack traces (DEFAULT)
make test-detailed     # All test results (JUnit-style)
make test-pattern PATTERN=Module  # Run specific tests
make test-coverage     # Run tests with code coverage
make test-sandbox      # Run Sandbox tests (30ms, optional)
```

**Current test count: 406 tests (as of v2.1.0+listsort)**

**Testing Approaches:**

| Method | Speed | Best For | Command |
|--------|-------|----------|----------|
| **Desktop (Busted)** | ~4s | UI integration, complex mocking | `make test-errors` |
| **Sandbox** | ~30ms | Pure Core logic (optional) | `make test-sandbox` |

**Sandbox Benefits (Optional):**
- 30ms feedback loop (vs 4s Busted)
- No Busted dependency
- Perfect for CI/CD
- Core modules (`core/*.lua`) are already pure Lua - Sandbox-ready

**When to use Sandbox:**
- Testing pure Core logic (Repository, Iterator, Search, etc.)
- Fast TDD feedback during development
- CI/CD pipelines need speed

**Stick with Busted for:**
- UI integration tests (current approach)
- Tests requiring complex WoW API mocking
- Full system integration verification

### Verification Commands
```bash
make verify            # Full verification (validate + lint + test)
make validate          # Validate addon structure (.toc, files)
make lint              # Run Luacheck linter
make warnings          # Show detailed lint warnings
```

### Mechanic Integration
```bash
make check-mechanic    # Verify Mechanic CLI is available
make setup-mechanic    # Clone and install Mechanic
make run               # Start Mechanic dashboard
make stop              # Stop Mechanic dashboard
make output            # Get addon output (errors, tests, logs)
make test-sandbox      # Run Sandbox tests (30ms, optional)
make api-search QUERY=term  # Search WoW APIs offline
```

**Optional: Direct Mechanic Commands**
```bash
# From ../../_dev_/Mechanic directory:
mech call sandbox.generate                        # Generate WoW API stubs (one-time)
mech call sandbox.test -i '{"addon": "BookArchivist"}'  # Run Core tests in Sandbox
mech call api.search -i '{"query": "*Spell*"}'    # Search WoW APIs offline
mech call addon.lint -i '{"addon": "BookArchivist"}'    # Alternative to make lint
```

**When to use Mechanic commands:**
- Need 30ms test feedback (Sandbox)
- Researching WoW APIs offline (`api.search`)
- Structured command output for agents

**Stick with make commands for:**
- Normal development workflow
- CI/CD pipelines
- User-facing operations

### Development Commands
```bash
make sync              # Sync addon to WoW clients
make link              # Link addon to WoW (via addon.sync)
make unlink            # Unlink addon from WoW clients
```

### Release Commands
```bash
make release TAG=x.x.x # Create release tag
make alpha TAG=x.x.x   # Create alpha tag
make beta TAG=x.x.x    # Create beta tag
```

---

## 🚨 NON-NEGOTIABLE RULES

### 1. Code is the source of truth
**Never trust documentation over code.**
- When implementing features: verify EVERY claim against actual source files
- When documentation conflicts with code: THE CODE IS CORRECT
- Before referencing a function/module: `grep_search` or `read_file` to confirm it exists
- Senior developers read code first, documentation second

### 2. Verify syntax before completing tasks
**Every code change must be syntax-checked before marking complete.**

Check for:
- Unmatched `end` statements
- Mismatched quotes/brackets/parentheses  
- Typos in keywords (`functoin`, `locla`, `retrun`)
- Malformed comment blocks

If uncertain: `read_file` the modified section to verify.

### 3. Update documentation when code changes
**Code changes that affect architecture REQUIRE documentation updates.**

Must update when:
- Adding/removing modules or UI components
- Changing SavedVariables schema
- Modifying event flows or execution order
- Altering feature behavior

Files to sync:
- `.github/copilot-instructions.md` (this file)
- `README.md` (architecture overview)
- `.github/copilot-skills/*.md` (system details)

**Process:**
1. Make code changes
2. `grep_search` documentation for references to changed systems
3. Update documentation to match new code reality
4. Verify no stale references remain

### 4. Never commit without user approval
**Do NOT run `git commit` until user explicitly approves.**

Correct workflow:
1. Implement changes
2. **STOP** — user must test in-game
3. User confirms "works correctly"
4. User says "commit" or "commit this"
5. THEN run `git commit`

Committing untested code wastes user time.

### 5. One logical change per commit
**Each commit must contain a single, atomic change.**

Why this matters:
- Easy to identify what broke when errors occur
- Simple rollback: `git revert` removes one change cleanly
- Clear audit trail of what changed and when
- Easier code review and bisecting bugs

**Good examples:**
- ✅ One commit: "fix: rename duplicate Delete to IsTooltipEnabled"
- ✅ One commit: "refactor: remove CreateLegacy function from UI_Frame_Builder"
- ✅ One commit: "fix: correct locale keys for Unknown Zone/Mob"

**Bad examples:**
- ❌ Three-Layer Architecture (Mechanic Pattern)

BookArchivist follows the **Mechanic three-layer architecture** for testable, maintainable code:

```
┌─────────────────────────────────────────────────────────────┐
│                     BookArchivist                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  LAYER 1: CORE (Pure Lua 5.1)                         │ │
│  │  • core/*.lua (Repository, Iterator, Search, etc.)    │ │
│  │  • No WoW dependencies                                 │ │
│  │  ✅ Testable in Sandbox (~30ms) or Busted (~4s)       │ │
│  └───────────────────────────────────────────────────────┘ │
│                          ▲                                  │
│                          │ Pure function calls             │
│  ┌───────────────────────┴───────────────────────────────┐ │
│  │  LAYER 2: BRIDGE (WoW API Adapter)                    │ │
│  │  • Event handlers in BookArchivist_Core.lua           │ │
│  │  • Capture.lua (ITEM_TEXT_* events → Core calls)      │ │
│  │  • Location.lua (C_Map APIs → context tables)         │ │
│  │  ⚠️ Requires WoW - tested via Busted with mocks       │ │
│  └───────────────────────────────────────────────────────┘ │
│                          ▲                                  │
│                          │ Commands/Events                 │
│  ┌───────────────────────┴───────────────────────────────┐ │
│  │  LAYER 3: VIEW (UI Frames)                            │ │
│  │  • ui/*.lua (Frame creation, layout, visual updates)  │ │
│  │  • UI_Core.lua (state management, refresh pipeline)   │ │
│  │  ⚠️ Requires WoW - tested via Busted or in-game       │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Layer Responsibilities:**

| Layer | Files | Dependencies | Testable In |
|-------|-------|--------------|-------------|
| **Core** | `core/*.lua` | None (pure Lua) | Sandbox or Busted |
| **Bridge** | Event handlers, Capture, Location | WoW APIs | Busted (mocked) |
| **View** | `ui/*.lua` | WoW Frames, Core | Busted (mocked) |

**When implementing features:**
1. **Core layer first** - Pure logic, no WoW deps (fast tests)
2. **Bridge layer** - Adapt WoW APIs to Core calls
3. **View layer** - UI updates from Core results

**Reference:** See `../../_dev_/Mechanic/docs/addon-architecture.md` for full pattern details.

### One commit: "fix bugs and remove dead code" (combines 2 changes)
- ❌ One commit: "update all UI files" (too broad, no clear scope)

**When working on complex tasks:**
1. Break work into logical steps
2. Implement one step completely
3. Test that specific change
4. Commit with descriptive message
5. Move to next step

If a commit breaks something, we can:
- Quickly identify the exact change that caused it
- Revert just that commit without losing other work
- Review the specific code that changed

---

## 🎯 Architecture Overview

**For detailed system documentation, see `.github/copilot-skills/README.md`**

### Project structure
```
core/*          — Event handling, capture, persistence, DB, search, import/export
ui/*            — Main window, list panel, reader panel, frame building
ui/options/*    — Blizzard Settings integration, import UI
ui/list/*       — Books/Locations mode, filtering, pagination, rows
ui/reader/*     — Content rendering, navigation, delete/share
locales/*       — Localization (enUS, esES, caES, frFR, deDE, itIT, ptBR)
```

### Key systems (quick reference)
| System | Files | Purpose |
|--------|-------|---------|
| **Repository** | `core/BookArchivist_Repository.lua` | **Central DB access via dependency injection** |
| **Capture** | `core/BookArchivist_Capture.lua` | ItemText event → session → persistence |
| **Database** | `core/BookArchivist_DB.lua`, `core/BookArchivist_Core.lua` | v2 schema (booksById), migrations, indexes |
| **Favorites** | `core/BookArchivist_Favorites.lua` | Set/Toggle/IsFavorite bookmarks |
| **Recent** | `core/BookArchivist_Recent.lua` | MRU list (50-entry cap) |
| **Tooltip** | `core/BookArchivist_Tooltip.lua` | GameTooltip "Archived" tag via indexes |
| **Import** | `core/BookArchivist_ImportWorker.lua` | BDB1 format, async 6-phase pipeline |
| **UI State** | `ui/BookArchivist_UI_Core.lua` | Selection, mode, filters, safe refresh |
| **List** | `ui/list/BookArchivist_UI_List*.lua` | Books/Locations, async filtering, rows |
| **Reader** | `ui/reader/BookArchivist_UI_Reader*.lua` | ShowBook, SimpleHTML, navigation |

---

## 🛠️ Implementation Guidelines

### UI Framework Rules

**Native WoW frames only** (no Ace3 except MultiLineEditBox for import/debug panels):
- `CreateFrame(...)` with Blizzard templates
- `InsetFrameTemplate3` for panels
- `UIPanelButtonTemplate` for buttons
- `SimpleHTML` for rich text rendering
- `BackdropTemplate` for dialogs

**AceGUI exception:**
- `MultiLineEditBox` for Options → Import panel (large paste handling)
- If AceGUI unavailable: fallback to native `ScrollFrame+EditBox`

**Layout separation:**
- `*_Layout.lua` files: frame creation, anchoring, sizing
- `*.lua` files: behavior, event handling, state updates
- Use `safeCreateFrame` helpers (wrap CreateFrame with error handling)

**Fixed layout constraints:**
- Left panel: 360px width (hardcoded, no splitter/resize)
- Right panel: flexible, fills remaining space
- Gap between panels: 10px (Metrics.GAP_M)
- Structure: header → body → (left inset | gap | right inset)

### When working on...

#### **Database/Persistence**
**Skill:** [k-savedvariables](../.claude/skills/k-savedvariables/SKILL.md)

- **Repository Pattern**: All DB access goes through `BookArchivist.Repository:GetDB()`
- **Dependency Injection**: `Repository:Init(database)` injects the active database
- SavedVariables: `BookArchivistDB` (per-character)
- Schema version: `dbVersion = 2`
- Books stored in: `booksById[bookId]` (not `books[key]`)
- Indexes: `objectToBookId`, `itemToBookIds`, `titleToBookIds`
- Migrations: see `core/BookArchivist_Migrations.lua`

**Repository Architecture:**
- Production: `Repository:Init(BookArchivistDB)` on ADDON_LOADED
- Tests: `Repository:Init(testDB)` in setup, `Repository:Init(BookArchivistDB)` in teardown
- All modules use `Repository:GetDB()` instead of accessing global directly
- Zero test-specific code in Repository (pure dependency injection)

#### **Capture system**
**Skill:** [k-capture](../.claude/skills/k-capture/SKILL.md)

- Events: `ITEM_TEXT_BEGIN` → `ITEM_TEXT_READY` → `ITEM_TEXT_CLOSED`
- Session lifecycle: OnBegin → OnReady (per page) → OnClosed
- Persistence: incremental on READY, final on CLOSED
- Location: resolved via `BookArchivist.Location:BuildWorldLocation()`
**Skill:** [k-list-panel](../.claude/skills/k-list-panel/SKILL.md)


#### **List filtering**
- **Always use async Iterator** (prevents UI freeze)
- Budget: 16ms per iteration chunk
- See: `ui/list/BookArchivist_UI_List_Filter.lua`
- Filter state: `BookArchivist.UI.Internal.getFilterState()`
**Skill:** [k-reader-panel](../.claude/skills/k-reader-panel/SKILL.md)


#### **Reader rendering**
- Mode detection: HTML vs plain text
- HTML path: `BookArchivist_UI_Reader_Rich.lua` (custom renderer)
- Fallback: `SimpleHTML` widget or plain `FontString`
- Navigation: page array (`state.pageOrder`), index (`state.currentPageIndex`)

#### **Localization**
- Strings: `BookArchivist.L[key]` (never hardcode English)
- New keys: update ALL 7 locale files (enUS, esES, caES, frFR, deDE, itIT, ptBR)
- Format: `L["KEY_NAME"] = "Translated text"`

---

## ⚠️ Known Pitfalls (Do Not Regress)

### EditBox paste escaping
- WoW escapes `|` as `||` in pasted text
- Normalize: `text:gsub("||", "|")`
- For large paste: use AceGUI `MultiLineEditBox` (handles automatically)
- Avoid heavy work in `OnTextChanged` without throttling

### List performance
- **Never create thousands of frame rows**
- Use pooling: reuse widgets from `state.buttonPool`
- Render visible range only
- Pagination default: 25 rows/page

### Frame anchoring
- Always use explicit anchor points and offsets
- `InsetFrameTemplate3` has border thickness — account for it
- Test with `/framestack` to verify anchor hierarchy
- Clear anchors before repositioning: `frame:ClearAllPoints()`

### Combat lockdown
- Never modify protected frames during combat
- Disable sensitive actions when `InCombatLockdown()` returns true
- Queue updates until `PLAYER_REGEN_ENABLED` event

---

## ✅ Validation Checklist

Before marking work complete:

**Code quality:**
- [ ] Syntax verified (no missing `end`, unmatched quotes, typos)
- [ ] No hardcoded English strings (all from `BookArchivist.L`)
- [ ] Errors logged via `BookArchivist:LogError(...)` (never swallowed)
- [ ] No global pollution (use `local` or addon namespace)

**Functionality:**
- [ ] Main window opens without Lua errors
- [ ] Books/Locations tabs switch correctly
- [ ] List updates reflect filter/search/sort changes
- [ ] Reader shows selected book with correct pagination
- [ ] `/reload` and reopen works without errors

**Documentation:**
- [ ] If architecture changed: updated copilot-instructions.md
- [ ] If features added/removed: updated README.md
- [ ] If data structures changed: updated relevant copilot-skills/*.md

**Testing:**
- [ ] User tested in-game (NOT assumed to work)
- [ ] User confirmed functionality works
- [ ] User explicitly approved commit

---

## 📋 Code Conventions

**Style:**
- Small, single-purpose functions
- Early returns (avoid deep nesting)
- Explicit nil checks: `if not value then return end`
- Descriptive names: `getBookById` not `get`

**Error handling:**
- Always log errors: `BookArchivist:LogError(msg)`
- Use `pcall` for risky operations (frame creation, external calls)
- Provide fallbacks for missing dependencies

**State management:**
- UI state: `BookArchivist.UI.Internal` (shared context)
- Module state: local `state` tables with explicit initialization
- No side effects in constructors (defer to explicit init calls)

**Module pattern:**
```lua
local Module = {}
BookArchivist.Module = Module

local state = Module.__state or {}
Module.__state = state

function Module:Init(context)
  state.ctx = context or {}
end

function Module:DoWork()
  local ctx = state.ctx
  -- implementation
end
```

---

## 🔍 Quick Decision Tree

**Need to add a UI component?**
→ Use native `CreateFrame` + Blizzard template  
→ Exception: import/debug text areas use AceGUI MultiLineEditBox

**Need to filter/search books?**
→ Use async `BookArchivist.Iterator`  
→ Never synchronous loops over large datasets

**Need to access database?**
→ Use `BookArchivist.Repository:GetDB()` (central access point)  
→ Production code: Repository initialized on ADDON_LOADED  
→ Schema: `db.booksById[bookId]` (NOT `db.books[key]`)

**Need to show localized text?**
→ Use `BookArchivist.L["KEY"]`  
→ Update all 7 locale files if adding new keys

**Need to know what a module does?**
→ Check Claude skills (see "Knowledge Skills Reference" below)  
→ Then `read_file` the actual source to verify

**Documentation contradicts code?**
→ THE CODE IS CORRECT  
→ Update documentation to match code

---

## 📚 Knowledge Skills Reference

For deep dives into specific systems, reference these Claude skills:

| Skill | Topic | Key Content |
|-------|-------|-------------|
| [k-savedvariables](../.claude/skills/k-savedvariables/SKILL.md) | Database & Persistence | BookArchivistDB schema, Repository pattern, indexes, migrations |
| [k-capture](../.claude/skills/k-capture/SKILL.md) | Book Capture System | ItemText events, session lifecycle, incremental persistence |
| [k-favorites](../.claude/skills/k-favorites/SKILL.md) | Favorites & Recent | MRU list, favorite flags, virtual categories |
| [k-tooltip](../.claude/skills/k-tooltip/SKILL.md) | Tooltip Integration | GameTooltip hooks, index lookups, "Archived" indicator |
| [k-import-export](../.claude/skills/k-import-export/SKILL.md) | Import/Export | BDB1 format, async import worker, merge semantics |
| [k-ui-refresh](../.claude/skills/k-ui-refresh/SKILL.md) | UI Refresh Flow | ViewModel, RefreshUI pipeline, lazy initialization |
| [k-list-panel](../.claude/skills/k-list-panel/SKILL.md) | List Panel UI | Async filtering, sorting, pagination, categories |
| [k-reader-panel](../.claude/skills/k-reader-panel/SKILL.md) | Reader Panel UI | Content rendering, SimpleHTML, navigation, actions |

**Full details:** Each skill references complete documentation in `.github/copilot-skills/`

---
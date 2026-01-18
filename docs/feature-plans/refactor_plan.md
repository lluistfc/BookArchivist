# Plan: Make `Book` an Aggregate Root (WoW Addon / Lua)

## Goal
Enforce **one owner of mutations** for book state (title/pages/meta), so UI never edits DB tables directly. Enable safe evolution (pagination, drafts, export) without logic scattering.

---

## Non-Goals (avoid overengineering)
- No DDD folder explosion, factories, repositories as classes, event sourcing, etc.
- No “domain layer” ceremony.
- DB remains a dumb persistence store.

---

## Target Invariants (must hold)
1. `book.id` is stable and unique.
2. `book.sourceType ∈ {"CAPTURED","CUSTOM"}`.
3. If `CAPTURED`: content is **read-only**.
4. If `CUSTOM`: content is **mutable** via aggregate methods only.
5. `pages` is an ordered sequence:
   - `pageCount >= 1`
   - no gaps (1..N)
6. `updatedAt` changes only through aggregate writes.
7. `searchText` always reflects the current title + pages.

---

## Step 0 — Define the Aggregate API (final surface area)
Create a minimal `Book` API (10–12 methods max):

### Constructors
- `Book.CapturedFromEntry(entry) -> Book`
- `Book.NewCustom(id, title, creator) -> Book`

### Reads (pure)
- `book:GetId()`
- `book:GetTitle()`
- `book:GetPageCount()`
- `book:GetPageText(pageNum)`
- `book:IsEditable()`
- `book:GetSourceType()`

### Writes (the ONLY mutation surface)
- `book:SetTitle(title)`
- `book:SetPageText(pageNum, text)` (auto-clamp, auto-create pages if needed for CUSTOM)
- `book:AddPage(afterPageNum?)` (optional for later)
- `book:RemovePage(pageNum)` (optional for later)
- `book:TouchUpdatedAt()`

### Serialization
- `book:ToEntry() -> entry` (DB-friendly table)
- `Book.FromEntry(entry) -> Book` (single entry-point, chooses captured/custom)

---

## Step 1 — Add `core/BookArchivist_Book.lua`
Implement the aggregate as a simple Lua module:
- Holds internal state (`_id`, `_title`, `_pages`, `_sourceType`, timestamps, etc.).
- All fields private by convention (`self._pages`).
- Validate invariants in every write method.
- For CAPTURED, write methods `error()` or no-op with explicit return code.

**Deliverable**
- `Book` module with API above + invariant checks.

---

## Step 2 — Add a thin “Book Service” in Core (not a repository class)
In `core/BookArchivist_Core.lua` add functions that:
- load entry from DB → wrap as `Book`
- apply mutations through aggregate
- persist entry back to DB

### Required functions
- `Core:GetBook(bookId) -> Book|nil`
- `Core:CreateCustomBook(title, pages) -> bookId`
- `Core:SaveBook(book)` (writes `book:ToEntry()` to DB)
- `Core:UpdateBook(bookId, fn(book))` (transaction-like helper)

**Rules**
- UI calls Core functions only.
- Core is allowed to touch DB tables; UI is not.

---

## Step 3 — Refactor DB writes out of UI (strict boundary)
Search & kill any code where UI does:
- `db.booksById[id].pages[...] = ...`
- `entry.customPages = ...`
- `entry.searchText = ...`

Replace with:
- `Core:UpdateBook(id, function(book) book:SetPageText(...) end)`
- `Core:UpdateBook(id, function(book) book:SetTitle(...) end)`

**Deliverable**
- UI layer contains no direct DB mutations.

---

## Step 4 — Normalize storage model (stop having multiple page sources)
Pick ONE persisted representation:
- Recommended: `entry.pages` is always the effective pages for both CAPTURED and CUSTOM
- For CAPTURED: keep original pages in `entry.capturedPages` (optional)
- For CUSTOM: `entry.pages` is the authored content

If you must preserve original captured pages:
- `entry.capturedPages` (read-only snapshot)
- `entry.pages` (effective pages; equals capturedPages unless overridden)
- Aggregate decides which one is editable/active.

**Deliverable**
- A single “effective pages” path for rendering and searching.

---

## Step 5 — Update Reader Rendering to use Aggregate reads only
Refactor reader code to:
- get `Book` via `Core:GetBook(selectedId)`
- render via `book:GetTitle()`, `book:GetPageText(pageNum)`, `book:GetPageCount()`

No code should do `entry.pages[pageNum]` anymore.

**Deliverable**
- Reader becomes a consumer of the aggregate, not of raw tables.

---

## Step 6 — New Book flow uses Aggregate constructors only
New book UI should:
1. collect title + page text
2. call `Core:CreateCustomBook(title, pages)`
3. select the new id

Do not build entries by hand in UI.

**Deliverable**
- “New Book” creation is a single Core call.

---

## Step 7 — Centralize derived fields (searchText, pageOrder, etc.)
Inside `Book:SetTitle` and `Book:SetPageText`:
- update `self._updatedAt`
- recompute `self._searchText` (or mark dirty and compute in `ToEntry()`)

Core persists the derived fields via `book:ToEntry()`.

**Deliverable**
- No more scattered `BuildSearchText` calls from UI.

---

## Step 8 — Enforce immutability for CAPTURED books
In aggregate write methods:
- if `sourceType == "CAPTURED"` then return `false, "READ_ONLY"` (or throw)
- UI should hide editor controls for captured books

**Deliverable**
- Captured books cannot be modified even if UI bugs occur.

---

## Step 9 — Add lightweight tests (even if addon has no harness)
Create a `tests/` Lua file runnable manually (or via a simple in-game slash command) covering:
- creating custom book yields pages 1..N
- captured book rejects edits
- setting page text beyond current count auto-expands (CUSTOM)
- removal clamps to >= 1 page (if implemented)
- `ToEntry()` invariants (no gaps)

**Deliverable**
- A sanity suite that prevents regressions.

---

## Step 10 — Migration & Backwards Compatibility
If existing DB has:
- `customPages` / `pages` mixed formats
Add a migration in Core init:
- normalize into `entry.pages`
- stash original in `entry.capturedPages` if needed
- mark `db.version` and only migrate once

**Deliverable**
- No user data loss; consistent new schema.

---

## Acceptance Criteria (definition of done)
- UI never writes into `BookArchivistDB` directly.
- All book changes go through `Book` methods.
- Captured books are hard read-only.
- Rendering uses `Book` getters, not raw tables.
- DB format is consistent and single-source-of-truth for effective pages.
- Adding “multi-page overflow” later requires changes only inside the aggregate + one UI hook.

---

## Implementation Order (recommended)
1. Add `Book` module + invariants
2. Add Core wrappers (`GetBook`, `CreateCustomBook`, `UpdateBook`)
3. Refactor “New Book” to use Core
4. Refactor Reader rendering to use Book getters
5. Remove UI DB mutations + normalize storage
6. Add migration + sanity tests

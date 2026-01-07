# BookArchivist — Per-Book Sharing & Export Plan

## Goals

- Avoid WoW paste-size limits and long freezes by **not** exporting/importing the entire library as a single huge string.
- Introduce a **per-book sharing** pipeline that is safe to paste, easy to copy, and works well across clients/accounts.
- Reuse as much of the existing BDB1 export/import machinery as possible.
- Keep UX familiar by mirroring successful patterns from WeakAuras (visible string, Ctrl+C, optional chat-style sharing later).

---

## 1. Per-Book Export Payload

### 1.1 Core payload builder

Add a new helper in `core/BookArchivist_Core.lua` (or `BookArchivist_Export.lua` if we want all export-specific logic together):

- `Core:BuildExportPayloadForBook(bookId)`
  - Ensures `bookId` is a valid key in `db.booksById`.
  - Returns a table shaped like the existing full-export payload, but scoped to a single book:
    - `schemaVersion = 1`
    - `exportedAt = now()`
    - `character = { name = UnitName("player") or "?", realm = GetRealmName() or "?" }`
    - `booksById = { [bookId] = CloneTable(db.booksById[bookId]) }`
    - `order = { bookId }`
  - Does **not** change schema semantics: ImportWorker must be able to consume either a single-book or multi-book payload transparently.

### 1.2 Per-book export string API

Add a public API that parallels `Core:ExportToString`:

- `function Core:ExportBookToString(bookId)`
  - Validates `bookId` exists; returns `nil, "unknown book"` if not.
  - Calls `self:BuildExportPayloadForBook(bookId)`.
  - Serializes and wraps the payload through the existing BDB1 logic:
    - `Serialize.SerializeTable(payload)` → `serialized`.
    - `CRC32` and `Base64.Encode` as in `ExportToString`.
    - Same `CHUNK_SIZE`, header format, and footer.
  - Returns the final BDB1 export string plus optional error.

Expose a top-level convenience wrapper on the addon:

- `function BookArchivist:ExportBook(bookId)`
  - Delegates to `Core:ExportBookToString(bookId)`.
  - This is what UI modules will call.

---

## 2. ImportWorker Compatibility

The current ImportWorker already works with any `booksById` table; it does not assume a minimum book count.

### 2.1 Structural expectations

- `payload.schemaVersion == 1` remains mandatory.
- `payload.booksById` must be a table; it may hold **one or many** entries.
- `payload.order` may refer to one or many ids; empty or missing ids are still treated as an error.

No structural code changes are needed, but we can improve diagnostics:

### 2.2 Status / logging polish

- When `incomingIds` has length 1, legacy stats and chat output can say:
  - "Imported: 1 new, 0 merged (from shared book string)".
- When length > 1, keep current wording (multi-book import).

This is optional sugar; functional behavior is identical for single-book and full-library payloads.

---

## 3. Reader UI: "Share / Export this book"

We want a user to be able to stand in front of a book in the reader and click a clear action to get a shareable string.

### 3.1 Reader header button

In `ui/reader/BookArchivist_UI_Reader_Layout.lua` (or the main reader controller), add:

- A small button in the reader header row, near Delete/Next/Prev, e.g.:
  - Label: `Share`, or an icon with a tooltip `"Export this book"`.
- Disable the button when no book is selected.
- Tooltip clarifies: "Generate a string for this book that you can copy with Ctrl+C and share with others."

### 3.2 Export popup frame

Create a reusable popup, ideally in a small reader-specific module (e.g. `ui/reader/BookArchivist_UI_Reader_Export.lua`):

- A simple frame with:
  - Title: `"Book export string"`.
  - Subheading: book title + character/realm.
  - A multiline edit box:
    - Pre-filled with the BDB1 string from `BookArchivist:ExportBook(bookId)`.
    - Read-only (or at least not intended for manual editing).
    - Auto-focus and highlight all text on show.
    - User hits Ctrl+C to copy.
  - Buttons:
    - `Close`.
    - Optional: `Copy` helper that just re-focuses and re-highlights.

Behavior:

1. Reader button click → look up current `bookId`.
2. Call `BookArchivist:ExportBook(bookId)`.
3. On success → show popup with populated edit box.
4. On error (e.g. missing book) → print a concise error in chat.

Re-use the same `StylePayloadEditBox` helper (or clone its logic) to keep font/selection behavior consistent with the options export UI.

---

## 4. List UI: Context Menu "Share book…"

To make sharing reachable from the list as well:

### 4.1 List row context menu entry

In `ui/list/BookArchivist_UI_List_Selection.lua` (context menu logic):

- Add a new menu item when right-clicking a book row:
  - Label: `"Share / Export this book"`.
- Action: same as the reader button:
  - Resolve the row’s `bookId`.
  - Call `BookArchivist:ExportBook(bookId)`.
  - Show the same export popup frame.

This keeps behavior consistent whether the user is focused on the list row or already has the book open in the reader.

---

## 5. Per-Book Import UX

We want per-book strings to import cleanly using the existing pipeline and UI.

### 5.1 Reuse options panel Import

- The existing options panel import box already calls `ImportWorker:Start(rawString, callbacks)`.
- A single-book string is just a tiny BDB1 payload containing one `booksById` entry.
- No code change is needed: the worker will merge that single entry into `BookArchivistDB` and rebuild indexes.

### 5.2 Optional: Reader-side "Import book string"

To keep everything in one place, consider a later enhancement:

- Add a small `Import` icon/button next to the "Share" button in the reader header.
- On click, open a small paste-edit box (similar to WeakAuras):
  - Label: `"Paste book export string below"`.
  - On `OnTextChanged`, once text length exceeds a small threshold, call `ImportWorker`.
  - Show status and error messages inline in the popup.

This is optional and can be implemented after the options-panel import workflow is proven to work well for per-book payloads.

---

## 6. Copy / Paste Mechanics

### 6.1 Copying (export side)

- For per-book exports we do **not** need the hidden Capture Paste box.
- The popup’s visible multiline edit box behaves like WeakAuras’ import/export text box:
  - User clicks into the box → all text is highlighted.
  - User presses Ctrl+C → full string copied to OS clipboard.
- We do not attempt to read the clipboard from Lua; we only provide a convenient place for the user to paste from or copy to.

### 6.2 Pasting (import side)

- For per-book strings, size is much smaller than full-library payloads:
  - Single book text + metadata serialized, compressed, and base64-encoded.
  - This should be well under the ~50k-character range where pastes are usually safe.
- Users can:
  - Paste into the options import box (current behavior).
  - Or, in a future reader import popup, paste directly into a visible multiline box like WeakAuras does.

---

## 7. Localization & Text Updates

Add/adjust strings in `locales/BookArchivist_Locale_*.lua`:

- New keys (example English wording):
  - `READER_SHARE_BUTTON` = "Share" or "Export".
  - `READER_SHARE_TOOLTIP_TITLE` = "Export this book".
  - `READER_SHARE_TOOLTIP_BODY` = "Generate a string for this book that you can copy with Ctrl+C and share with others.".
  - `READER_SHARE_POPUP_TITLE` = "Book export string".
  - `READER_SHARE_POPUP_LABEL` = "Use Ctrl+C to copy this string, then share it with other players or paste it into another client of Book Archivist.".
- Update import-related help to mention:
  - Single-book strings are safe and recommended for cross-client sharing.
  - Full-library exports are best used locally (no-paste path) due to client paste limits.

Localize these strings to all supported locales (`esES`, `caES`, `deDE`, `frFR`, `itIT`, `ptBR`, etc.).

---

## 8. Engine Limits & Documentation

Given typical size numbers observed in testing:

- Big WeakAuras packs: ~40k–50k characters.
- 12 captured books with full text: ~137k characters.

Document and communicate:

- WoW edit boxes have a practical upper bound on how much text they will accept from a single Ctrl+V.
- Full-library BookArchivist exports can exceed that limit easily, causing:
  - Truncated pastes.
  - BDB1 decode failures ("Payload too short" / "Invalid header").
  - Very long freezes or even client crashes for extreme sizes.
- Per-book exports are:
  - Much smaller and safer to paste.
  - Easier to share via chat, paste sites, or between clients.

Recommended guidance in README and options help:

- Use **per-book sharing** when sending books to friends or between different WoW clients.
- Reserve **full-library export/import** for local backups where you can use the no-paste path (Export → Import on the same client) and avoid the clipboard entirely.

---

## 9. Future Enhancements (Optional)

These are nice-to-have ideas that build on the per-book pipeline but are not required for the initial implementation:

1. **Chat link integration**
   - Define a custom link type (e.g. `garrmission:bookarchivist`) similar to WeakAuras.
   - Encode a compact token for the book export in the link.
   - On click, show a tooltip with "Import this book?" and buttons for Import/Copy.

2. **Batch per-book export helpers**
   - UI to export all books from the current character as **individual** shareable strings (for power users / external tools).

3. **Safer large-library backups**
   - Option to write a compressed export string to SavedVariables (or a dedicated backup table) instead of the clipboard, so no pasting is required at all on that client.

The core of this plan is steps 1–4: add a per-book export payload, wire it into Core, and expose it through intuitive Share/Export actions in the reader and list.

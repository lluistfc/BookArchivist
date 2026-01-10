# Reader Panel & Navigation

## Overview
The Reader Panel displays book content with rich text rendering, page navigation, and action buttons (favorite, delete, share). It uses WoW's **SimpleHTML** frame for text formatting.

## Panel Structure

### Visual Layout
```
┌─ Right Panel ────────────────────┐
│ Book Title by Author        ← Header│
│ Material • Seen 3× • Date   ← Meta │
│ [★] [Delete] [Share]       ← Actions│
│ [<Prev] Page 1 of 3 [Next>] ← Nav│
│ ┌──────────────────────────────┐ │
│ │ This is the book content... │ │
│ │                              │ │
│ │ Page text is rendered here  │ │
│ │ with formatting support:     │ │
│ │ • Line breaks                │ │
│ │ • Color codes                │ │
│ │ • Texture icons              │ │
│ │                              │ │
│ └──────────────────────────────┘ │
│ Orgrimmar • 2024-01-10      ← Status│
└──────────────────────────────────┘
```

### Frame Hierarchy
```
RightPanel
  ├─ HeaderRow
  │   ├─ TitleLabel (FontString)
  │   └─ MetaLabel (FontString)
  ├─ ActionRow
  │   ├─ FavoriteButton (★ icon)
  │   ├─ DeleteButton (🗑️ icon)
  │   └─ ShareButton (🔗 icon)
  ├─ NavRow
  │   ├─ PrevPageButton
  │   ├─ PageLabel ("Page X of Y")
  │   └─ NextPageButton
  ├─ ContentScrollFrame
  │   └─ ContentHTML (SimpleHTML)
  └─ StatusRow
      └─ LocationLabel (FontString)
```

## Book Display Flow

### ShowBook() Entry Point
**File:** `ui/reader/BookArchivist_UI_Reader.lua`

```lua
ReaderUI:ShowBook(bookId)
  → Fetch entry: db.booksById[bookId]
  → If not entry: ShowEmptyReader(), return
  
  → Update state:
    - state.currentEntryKey = bookId
    - state.currentPageIndex = 1
    - state.pageOrder = BuildPageOrder(entry.pages)
  
  → Render components:
    - RenderHeader(entry)
    - RenderActions(entry, bookId)
    - RenderNavigation(entry)
    - RenderContent(entry, pageIndex)
    - RenderStatus(entry)
  
  → Mark as recently read:
    - Recent:MarkOpened(bookId)
```

**Triggered by:**
- User clicks book in list
- UI opens with last selected book
- Delete operation (auto-select next book)
- Import completes (refresh existing selection)

### Empty Reader State
```lua
ShowEmptyReader()
  → Hide all content
  → Show placeholder text: "Select a book to read"
  → Disable all buttons
```

**When:**
- No book selected
- Selected book deleted
- Library is empty

## Header Rendering

### Title & Metadata
**File:** `ui/reader/BookArchivist_UI_Reader.lua` → `RenderHeader()`

```lua
RenderHeader(entry)
  → titleText = entry.title or "Untitled"
  → creatorText = entry.creator or "Unknown"
  → materialText = entry.material or ""
  
  → headerLabel:SetText(titleText .. " by " .. creatorText)
  
  → Build metadata line:
    - parts = {}
    - If materialText: table.insert(parts, materialText)
    - If entry.seenCount: table.insert(parts, "Seen " .. seenCount .. "×")
    - If entry.lastSeenAt: table.insert(parts, fmtTime(lastSeenAt))
  
  → metaLabel:SetText(table.concat(parts, " • "))
```

**Example output:**
```
The Journal of Medivh by Unknown
Parchment • Seen 3× • 2024-01-10 14:32
```

**Color coding:**
- Title: White
- Creator: Gray
- Metadata: Light gray

## Action Buttons

### Favorite Button
**File:** `ui/reader/BookArchivist_UI_Reader.lua`

```lua
FavoriteButton:OnClick()
  → Favorites:Toggle(currentBookId)
  → Update button icon:
    - If favorited: Yellow star (★)
    - Else: Gray star outline (☆)
  → Refresh list (book may move in/out of Favorites category)
```

**Visual states:**
- **Favorited:** Yellow star, tooltip "Remove from Favorites"
- **Not favorited:** Gray star, tooltip "Add to Favorites"
- **Disabled:** No book selected

### Delete Button
**File:** `ui/reader/BookArchivist_UI_Reader_Delete.lua`

```lua
DeleteButton:OnClick()
  → Show confirmation dialog:
    - Title: "Delete Book?"
    - Message: "This will permanently delete [Book Title]. This cannot be undone."
    - Buttons: [Cancel] [Delete]
  
  → If confirmed:
    - Core:DeleteEntry(bookId)
      → Remove from booksById
      → Remove from order
      → Remove from recent.list
      → Remove from indexes
    - Select next book in list (or previous if last)
    - Refresh UI
```

**Confirmation dialog:**
- **Modal:** Blocks interaction with main window
- **No "Don't ask again":** Always confirms (safety feature)
- **Escape key:** Cancels delete

**Auto-selection after delete:**
```lua
SelectNextBook(deletedId)
  → Find index in filteredKeys
  → If index < #filteredKeys:
    - Select filteredKeys[index + 1] (next book)
  → Else if index > 1:
    - Select filteredKeys[index - 1] (previous book)
  → Else:
    - ShowEmptyReader() (library now empty)
```

### Share Button
**File:** `ui/reader/BookArchivist_UI_Reader_Share.lua`

```lua
ShareButton:OnClick()
  → Export:ExportLibrary() → payload
  → Show share dialog:
    - Read-only editbox (AceGUI MultiLineEditBox)
    - Auto-select all text
    - Instructions: "Copy this text and share with others"
  
  → User copies payload (Ctrl+C)
```

**Share payload:**
- BDB1 envelope (full library export)
- Includes all books, not just current book
- See `5-import-export.md` for payload format

## Page Navigation

### Page Order Building
**File:** `ui/reader/BookArchivist_UI_Reader.lua`

```lua
BuildPageOrder(pages)
  → Extract numeric page keys
  → Sort ascending: { 1, 2, 3, ... }
  → Return array
```

**Why build order array?**
- Pages stored as map: `{ [1] = "text", [5] = "text" }`
- Missing pages (2, 3, 4) skipped
- Order array ensures sequential navigation

### Navigation Controls
**File:** `ui/reader/BookArchivist_UI_Reader.lua`

```lua
PrevPageButton:OnClick()
  → state.currentPageIndex = max(1, currentPageIndex - 1)
  → RenderContent(entry, currentPageIndex)
  → UpdateNavigation()

NextPageButton:OnClick()
  → state.currentPageIndex = min(#pageOrder, currentPageIndex + 1)
  → RenderContent(entry, currentPageIndex)
  → UpdateNavigation()

UpdateNavigation()
  → totalPages = #pageOrder
  → currentPage = currentPageIndex
  
  → pageLabel:SetText("Page " .. currentPage .. " of " .. totalPages)
  
  → prevButton:SetEnabled(currentPage > 1)
  → nextButton:SetEnabled(currentPage < totalPages)
```

**Single-page books:**
- Nav row still shown
- "Page 1 of 1"
- Prev/Next buttons disabled

### Keyboard Shortcuts (Future)
**Not implemented.** Proposed:
- `Left Arrow` → Previous page
- `Right Arrow` → Next page
- `Home` → First page
- `End` → Last page

## Content Rendering (Rich Text)

### SimpleHTML Frame
**WoW API:** `CreateFrame("SimpleHTML")`

**Capabilities:**
- HTML subset (not full HTML)
- Supported tags: `<p>`, `<br>`, `<h1>`, `<h2>`, `<h3>`, `<font>`, `<img>`
- Automatic word wrap
- Scroll support (nested in ScrollFrame)

### HTML Generation
**File:** `ui/reader/BookArchivist_UI_Reader_HTML.lua`

```lua
BuildHTML(entry, pageIndex)
  → pageNum = state.pageOrder[pageIndex]
  → pageText = entry.pages[pageNum] or ""
  
  → Parse WoW markup: ParseWoWMarkup(pageText)
    → Color codes: |cFFRRGGBB text |r → <font color="#RRGGBB">text</font>
    → Textures: |T path:size |t → <img src="path" width="size" height="size"/>
    → Item links: |Hitem:12345|h[Name]|h → <font color="#FF8000">[Name]</font>
  
  → Wrap in HTML structure:
    <html>
      <body>
        <p>[parsed text]</p>
      </body>
    </html>
  
  → Return HTML string
```

**Example input (WoW markup):**
```
|cFF00FF00Green text|r followed by |TInterface\Icons\INV_Misc_Book_09:16|t icon.
```

**Example output (HTML):**
```html
<html>
  <body>
    <p>
      <font color="#00FF00">Green text</font> followed by
      <img src="Interface\Icons\INV_Misc_Book_09" width="16" height="16"/> icon.
    </p>
  </body>
</html>
```

### Rendering Process
**File:** `ui/reader/BookArchivist_UI_Reader.lua` → `RenderContent()`

```lua
RenderContent(entry, pageIndex)
  → html = BuildHTML(entry, pageIndex)
  
  → contentHTML:SetText(html)
    → SimpleHTML parses HTML
    → Measures text height
    → Adjusts child frame size
  
  → Reset scroll to top: ResetScrollToTop()
  
  → Auto-hide scrollbar if content fits:
    - If contentHeight <= frameHeight:
      scrollBar:Hide()
```

**Content sizing:**
```lua
UpdateReaderHeight(height)
  → contentChild:SetHeight(height + 20)  -- 20px padding
  → contentChild:SetWidth(hostWidth)     -- Match parent width
  → scrollFrame:Update()                  -- Notify ScrollBox
```

### Scroll Behavior

#### Modern ScrollBox API (11.0+)
```lua
ResetScrollToTop(scroll)
  → scroll:ScrollToBegin()
```

#### Legacy ScrollFrame API (Pre-11.0)
```lua
ResetScrollToTop(scroll)
  → scroll.ScrollBar:SetValue(0)
```

**Auto-hide scrollbar:**
```lua
-- If content fits without scrolling
if contentHeight <= frameHeight then
  scrollBar:Hide()
else
  scrollBar:Show()
end
```

## Status Bar (Location Display)

### Location Formatting
**File:** `ui/reader/BookArchivist_UI_Reader.lua` → `RenderStatus()`

```lua
RenderStatus(entry)
  → location = entry.location
  → If not location: Hide status bar, return
  
  → locationText = FormatLocation(location)
    → zoneText = location.zoneText or "Unknown"
    → If location.sourceName:
      zoneText = zoneText .. " (" .. sourceName .. ")"
  
  → dateText = fmtTime(entry.lastSeenAt or entry.createdAt)
  
  → statusLabel:SetText(locationText .. " • " .. dateText)
```

**Example outputs:**
```
Orgrimmar • 2024-01-10 14:32
Kalimdor > Durotar > Orgrimmar (Mysterious Crate) • 2024-01-09 12:00
Unknown Zone • 2024-01-08 10:15
```

**Color:** Light gray

## Refresh Behavior

### When Reader Refreshes
1. **Book selected from list** → `ShowBook(bookId)`
2. **Page navigation** → `RenderContent()` only
3. **Favorite toggled** → Button icon update only
4. **Book deleted** → `ShowBook(nextBookId)` or `ShowEmptyReader()`
5. **Full UI refresh** → `RefreshReader()` (re-renders current book)

### RefreshReader() Logic
**File:** `ui/reader/BookArchivist_UI_Reader.lua`

```lua
RefreshReader()
  → bookId = state.currentEntryKey
  → If bookId:
    - ShowBook(bookId)  -- Re-render
  → Else:
    - ShowEmptyReader()
```

**Triggers:**
- `BookArchivist.RefreshUI()` called
- Book metadata updated (e.g., after import merge)
- Language changed (localized strings update)

## Performance

### Content Rendering
- **HTML parsing:** ~1-2ms per page
- **SimpleHTML layout:** ~2-5ms per page (WoW engine overhead)
- **Total:** ~3-7ms per page (acceptable)

### Navigation
- **Page change:** ~5-10ms (re-parse + re-layout)
- **No caching:** HTML rebuilt every time (could be optimized)

### Memory
- **SimpleHTML buffer:** ~5-10KB per page (released on page change)
- **Parsed HTML string:** ~2-5KB per page (temporary)

## Common Patterns

### Show specific book
```lua
ReaderUI:ShowBook("b2:abc123")
```

### Get current book
```lua
local bookId = ReaderUI.__state.currentEntryKey
```

### Navigate to specific page
```lua
ReaderUI.__state.currentPageIndex = 3
ReaderUI:RenderContent(entry, 3)
ReaderUI:UpdateNavigation()
```

### Check if reader has content
```lua
local bookId = ReaderUI.__state.currentEntryKey
if bookId then
  -- Reader is showing a book
end
```

### Manually toggle favorite
```lua
local bookId = ReaderUI.__state.currentEntryKey
if bookId then
  Favorites:Toggle(bookId)
  ReaderUI:UpdateFavoriteButton()
end
```

## Edge Cases

### Book with Missing Pages
**Example:** Pages [1, 5, 10] (2-4, 6-9 missing)

**Result:**
- Navigation: Page 1 of 3 (shows 3 pages, not 10)
- Page order: [1, 5, 10]
- Content: Shows actual text from page 1, 5, or 10

### Book with No Pages
**Result:**
- ShowEmptyReader()
- Should never happen (capture always creates at least page 1)

### Book Deleted While Viewing
**Result:**
- Next refresh: entry not found → ShowEmptyReader()
- User sees "Select a book to read"

### SimpleHTML Parse Error
**Scenario:** Malformed HTML in book text

**Result:**
- SimpleHTML shows partial content or nothing
- No error message (WoW silently fails)
- Book still accessible (not corrupted)

### Very Long Pages (10,000+ characters)
**Result:**
- HTML parsing: ~10-20ms (slight delay)
- SimpleHTML layout: ~20-50ms (noticeable lag)
- Scrollbar performance: Smooth (WoW handles large content well)

## Important Notes

1. **SimpleHTML limitations:** Not full HTML (subset only)
2. **No page caching:** HTML rebuilt every time (optimization opportunity)
3. **Single-page optimization:** Nav controls always shown (even for 1-page books)
4. **Delete is permanent:** No undo, no recycle bin
5. **Share exports entire library:** Not just current book
6. **Favorite updates list:** May cause book to disappear if viewing Favorites category
7. **Recent updates on view:** Just viewing a book marks it as recently read

## Related Files
- `ui/reader/BookArchivist_UI_Reader.lua` - Main reader module
- `ui/reader/BookArchivist_UI_Reader_HTML.lua` - HTML generation
- `ui/reader/BookArchivist_UI_Reader_Rich_Parse.lua` - WoW markup parser
- `ui/reader/BookArchivist_UI_Reader_Delete.lua` - Delete confirmation dialog
- `ui/reader/BookArchivist_UI_Reader_Share.lua` - Share dialog
- `ui/reader/BookArchivist_UI_Reader_Layout.lua` - Panel layout

## Future Improvements (Not Implemented)
- Cache parsed HTML (avoid re-parsing on back/forward)
- Copy page text to clipboard (button or shortcut)
- Zoom controls (font size adjustment)
- Search within current book (Ctrl+F)
- Bookmark pages (remember last page read)
- Full-screen mode (hide list panel)
- Export single book (not entire library)

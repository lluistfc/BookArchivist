# BookArchivist

BookArchivist is a World of Warcraft addon that automatically records every “book” you read in-game (anything shown in the default ItemText frame) and lets you revisit it later in a clean, Blizzard-style library UI.

- Never lose quest texts, letters, books, or scrolls again.
- Browse all saved texts in a searchable list.
- Read them in a rich reader that preserves formatting and embedded images where possible.

## Features

- **Automatic capture**
  - Listens to the standard ItemText events and saves each page you read into a per-character SavedVariables table (`BookArchivistDB`).
  - Handles multi-page books and updates existing entries when you see them again.

- **Two-pane UI**
  - Left pane: searchable, filterable list of saved books (and a locations view).
  - Right pane: reader with metadata (creator, material, last viewed, location) and page navigation.

- **Rich HTML reader**
  - Detects when captured content is HTML and uses a custom rich renderer instead of plain text.
  - Preserves headings, paragraphs, line breaks, and embedded images.
  - Includes a local atlas for Legion artifact “book” textures so those pages render correctly without depending on other addons.
  - Falls back to Blizzard’s SimpleHTML widget or plain text when needed.
- **Book Echo system**
  - Contextual flavor text appears after reading a book with personality and charm.
  - Read count tracking shows how many times you've revisited each book.
  - 50+ unique echo templates based on content, creator, and rarity.
  - Fully localized in 7 languages (enUS, esES, caES, frFR, deDE, itIT, ptBR).
- **Search and filters**
  - Search across titles and text from the main header search box.
  - Filter and sort modes exposed via the list header and dropdowns.

- **Export and Import**
  - Export single books or entire collections to share with other characters or players.
  - Import works automatically: paste an export string and the import starts when valid data is detected.
  - Supports cross-character and cross-client transfers.

- **Quality-of-life**
  - Minimap button and slash command entry points for opening the library.
  - Optional delete button in the reader with confirmation dialog.
  - Favorites system to bookmark important books.
  - "Resume last book" feature to return to your most recent read.
  - **Random Book** button to discover forgotten books with automatic location context and pagination.

- **Accessibility**
  - Full keyboard navigation with customizable keybindings.
  - Block-based focus system (Header, List, Reader) for efficient navigation.
  - Dropdown menu keyboard navigation support.
  - Visual focus indicator panel showing current element and navigation context.
  - Screen reader-friendly text labels for all interactive elements.

## Screenshots

### Main Interface
<img src="media/bookarchivist_main.jpg" width="600" alt="BookArchivist main window with book list and reader" />

The main two-pane interface showing the searchable book list on the left and the rich text reader on the right.

### Book Reader
<img src="media/bookarchivist_book_reader.jpg" width="600" alt="Book reader with rich HTML formatting" />

The reader displays book content with proper formatting, images, and page navigation.

### Favorites
<img src="media/bookarchivist_favorite.jpg" width="600" alt="Favorites system with star icon" />

Mark important books as favorites for quick access.

### Location View
<img src="media/bookarchivist_location_list.jpg" width="600" alt="Location-based book organization" />

Browse books organized by where you found them in the world.

### Share & Export
<img src="media/bookarchivist_share_book.jpg" width="600" alt="Share book dialog" />
<img src="media/bookarchivist_share_chat.jpg" width="600" alt="Share book via chat link" />

Export individual books or your entire library to share with others or backup your collection.

### Import System
<img src="media/bookarchivist_options_import.jpg" width="600" alt="Import interface" />
<img src="media/bookarchivist_options_import_data.jpg" width="600" alt="Importing data" />
<img src="media/bookarchivist_options_import_finished.jpg" width="600" alt="Import complete" />

Easily import books shared by other players or restore from backups.

### Options & Settings
<img src="media/bookarchivist_options_resume_last_page.jpg" width="600" alt="Resume last page option" />
<img src="media/bookarchivist_options_supported_languages.jpg" width="600" alt="Language selection" />
<img src="media/bookarchivist_options_tooltip_integration.jpg" width="600" alt="Tooltip integration setting" />

Customize your experience with multiple language support, tooltip integration, and reading preferences.

## Installation

1. Download or clone this repository.
2. Ensure the folder structure looks like:
   - `World of Warcraft/_retail_/Interface/AddOns/BookArchivist/BookArchivist.toc`
   - `World of Warcraft/_retail_/Interface/AddOns/BookArchivist/core/...`
   - `World of Warcraft/_retail_/Interface/AddOns/BookArchivist/ui/...`
3. Restart WoW or reload your UI (`/reload`).
4. Enable **BookArchivist** in the in-game AddOns list.

## Usage

- Open the library:
  - Click the BookArchivist minimap button, **or**
  - Use the configured slash command (e.g. `/ba`).
- The left list shows all saved books.
  - Use the search box to find titles or text.
  - Use the tabs to switch between **Books** and **Locations** views.
- Selecting a row updates the reader on the right.
  - Use the Prev/Next buttons or page selector to navigate pages.
  - Use the Share button to export a book for sharing with others.
  - If enabled, use the Delete button to remove an entry (with confirmation).
- Export and import books:
  - Click Share in the reader or Export in Options to generate an export string.
  - Copy it with Ctrl+C and share it, or paste it into another character's Import panel (Options → Import).
  - Import happens automatically when you paste valid data.

## Security

BookArchivist implements robust security measures to protect against malicious imported content:

### Safe Book Sharing

**Imported books are automatically protected:**
- ✅ **Texture validation** - Only whitelisted game textures are allowed (prevents UI spoofing)
- ✅ **Content sanitization** - Oversized content is automatically truncated to safe limits
- ✅ **Import tracking** - All imported books are tagged with metadata for audit trail

**Safe import guidelines:**
1. **Only import from trusted sources** - Friends, guildmates, or verified communities
2. **Inspect before importing** - Paste import strings into a text editor first if unsure
3. **Enable debug logging** - Use `/ba debug on` to see what's being imported

**Content limits enforced:**
- Title: 255 characters max
- Page content: 10,000 characters max
- Total pages: 100 max

### Reporting Security Issues

If you discover a security vulnerability:
- **DO NOT** report via public GitHub issues
- **Contact:** Discord or email (see SECURITY_ARCHITECTURE.md)
- **Include:** Proof of concept, impact description, reproduction steps

### For Developers

Security-conscious developers should review:
- [SECURITY_ARCHITECTURE.md](docs/SECURITY_ARCHITECTURE.md) - Complete security design
- [SECURITY_TESTING.md](docs/SECURITY_TESTING.md) - In-game testing procedures
- [SECURITY_PLAN.md](docs/SECURITY_PLAN.md) - Implementation roadmap

**Key security features:**
- Zero-trust import validation (all imported content is validated)
- Defense-in-depth (multiple layers of protection)
- Fail-safe design (invalid content degrades gracefully)

## Accessibility

BookArchivist includes a comprehensive keyboard navigation system for users who prefer or require keyboard-only interaction.

### Focus Navigation System

The addon UI is divided into three **blocks** for efficient navigation:
- **Header** — Help, Options, Random Book, New Book buttons, search box, sort dropdown
- **List** — Books/Locations tabs, book rows, pagination controls
- **Reader** — Reader panel actions (TTS, Copy, Waypoint, Favorite, Delete)

### Keybindings

All keybindings are configurable via **Game Menu → Key Bindings → AddOns → BookArchivist**. No default keys are assigned—you must set your own bindings to avoid conflicts with your existing keybinds.

| Action | Description |
|--------|-------------|
| **Focus Next Element** | Move to the next element within the current block |
| **Focus Previous Element** | Move to the previous element within the current block |
| **Next Block** | Jump to the first element of the next block |
| **Previous Block** | Jump to the first element of the previous block |
| **Activate Element** | Click/activate the currently focused element |
| **Toggle Focus Mode** | Enable or disable focus navigation mode |

### Focus Indicator Panel

When focus mode is enabled, a floating indicator panel appears showing:
- **Current block** name (Header, List, or Reader)
- **Current element** name and position (e.g., "Help (1/6)")
- **Previous/Next block** names for orientation
- **Previous/Next element** names for context

### Dropdown Menu Navigation

When you activate a dropdown (like the Sort dropdown):
1. The dropdown opens and focus mode automatically enters **dropdown navigation**
2. Use **Focus Next/Previous** to navigate through dropdown items
3. Press **Activate** to select an item
4. Press **Toggle Focus Mode** to cancel and close the dropdown

The indicator panel shows "[ Dropdown ]" and displays dropdown item names during dropdown navigation.

### Tips for Keyboard Users

- **Set up keybindings first** — Go to Game Menu → Key Bindings → AddOns → BookArchivist and assign keys that don't conflict with your existing bindings
- **Start focus mode** by pressing your configured Toggle Focus Mode key when the BookArchivist window is open
- **Navigate quickly** using block navigation to jump between Header, List, and Reader
- **Search** by navigating to the search box and pressing Activate to focus it, then type your search
- **Read books** by navigating to list rows and pressing Activate to select a book
- **Page through books** by navigating to the Prev/Next page buttons in the Reader block

### Screen Reader Compatibility

While WoW has limited screen reader support, the focus indicator panel provides text labels for all focused elements, which can help users who rely on visual assistance or magnification tools.

## Architecture overview

### Core

- `core/BookArchivist.lua` — addon bootstrap, event wiring, high-level helpers (e.g. `RefreshUI`, `ToggleUI`).
- `core/BookArchivist_Core.lua` — SavedVariables schema, keying, ordering, and persistence helpers.
- `core/BookArchivist_Capture.lua` — ItemText capture sessions and incremental persistence.
- `core/BookArchivist_Location.lua` — provenance (zone chain, NPC names) for location breadcrumbs.
- `core/BookArchivist_Minimap.lua` — minimap button state; persistence of angle/visibility.
- `core/BookArchivist_ImportWorker.lua` — staged import pipeline (decode/parse/merge/search/titles).
- `core/BookArchivist_Favorites.lua` — favorites system for bookmarking books.
- `core/BookArchivist_Recent.lua` — recent reads tracking.
- `core/BookArchivist_RandomBook.lua` — random book selection with location navigation.
- `core/BookArchivist_Locale.lua` — localization loader and helpers.

### UI framework

- `ui/BookArchivist_UI.lua` — shared UI state and `BookArchivist.UI.Internal` helpers (selection, list mode, widget registry).
- `ui/BookArchivist_UI_Core.lua` — binds list and reader modules to injected helpers; safe wrappers and logging.
- `ui/BookArchivist_UI_Frame_Layout.lua` — main frame body layout with fixed-width left panel (360px) and flexible right panel using native frames (`CreateFrame`, `InsetFrameTemplate3`).
- `ui/BookArchivist_UI_Frame_Chrome.lua` — frame chrome (dragging, portrait, title, options button, header blocks).
- `ui/BookArchivist_UI_Frame_Builder.lua` — creates the main frame using the layout/chrome helpers.
- `ui/BookArchivist_UI_Frame.lua` — entry point that ensures the frame is built and shown/hidden; orchestrates async frame building and OnShow refresh logic.
- `ui/BookArchivist_UI_Runtime.lua` — orchestration, slash commands (`/ba`, `/bookarchivist`), and safe refresh sequencing.

### List UI

- `ui/list/BookArchivist_UI_List.lua` — list controller and mode management.
- `ui/list/BookArchivist_UI_List_Layout.lua` — list header, search box, pagination, and scroll layout.
- `ui/list/BookArchivist_UI_List_Tabs.lua` — `Books/Locations` list tabs and their parent/rail setup.
- `ui/list/BookArchivist_UI_List_Filter.lua` — filter state and filter UI.
- `ui/list/BookArchivist_UI_List_Location.lua` — locations-mode list and tree behavior.
- `ui/list/BookArchivist_UI_List_Rows.lua` — row creation, pooling, and update logic.

### Reader UI

- `ui/reader/BookArchivist_UI_Reader.lua` — reader controller: selection, metadata lines, page navigation, render path selection.
- `ui/reader/BookArchivist_UI_Reader_HTML.lua` — shared HTML detection, stripping, and normalization helpers.
- `ui/reader/BookArchivist_UI_Reader_ArtifactAtlas.lua` — local artifact-book atlas used to crop Blizzard textures.
- `ui/reader/BookArchivist_UI_Reader_Rich_Parse.lua` — HTML-to-block parser used by the rich renderer.
- `ui/reader/BookArchivist_UI_Reader_Rich.lua` — rich renderer that turns blocks into FontStrings/Textures.
- `ui/reader/BookArchivist_UI_Reader_Delete.lua` — delete-button behavior and confirmation dialog.
- `ui/reader/BookArchivist_UI_Reader_Share.lua` — share popup and book export string generation.
- `ui/reader/BookArchivist_UI_Reader_Layout.lua` — reader header, navigation row, and scroll/text layout.

### Other UI

- `ui/minimap/BookArchivist_UI_Minimap.lua` — minimap button UI (click handling, toggling the main frame).
- `ui/options/BookArchivist_UI_Options.lua` — options panel, import UI, and integration with Blizzard's Settings.

## Development notes

- The codebase is modular: UI modules register themselves under `BookArchivist.UI.*` and often receive helpers via an injected context object.
- Frame creation should go through the existing safe-create wrappers (`Internal.safeCreateFrame` or equivalent) to avoid taint and ease testing.
- Layout uses shared metrics (`BookArchivist.UI.Metrics`) to keep padding and gaps consistent across list and reader.
- Rich HTML rendering is optional; when it fails or is disabled, the reader falls back to SimpleHTML or plain text.

For more detailed contributor guidance and conventions, see `.github/copilot-instructions.md`.

## Development Setup

### External Libraries

BookArchivist uses several WoW addon libraries (Ace3, LibStub, LibDBIcon, etc.). You can either download them or junction to existing copies:

**Option 1: Download libraries**
```bash
make download-libs
```

**Option 2: Junction to existing libraries** (if you already have them elsewhere)
1. Copy `.env.dist` to `.env`
2. Edit `.env` and uncomment/set the `LIB_*` paths to point to your existing library directories
3. Run:
```bash
make junction-libs
```

This creates Windows directory junctions (no admin required) so multiple addons can share the same library folders without duplication.

### Live Testing Setup

For rapid development, create a symbolic link from your WoW AddOns folder to your development directory. This allows WoW to read directly from your dev folder—no copying or building needed. Just edit, save, and `/reload` in-game.

**Windows (PowerShell):**
```powershell
# Directory junction (no admin required)
cmd /c mklink /J "C:\World of Warcraft\_retail_\Interface\AddOns\BookArchivist" "C:\dev\BookArchivist"

# OR symbolic link (requires admin)
New-Item -ItemType SymbolicLink -Path "C:\World of Warcraft\_retail_\Interface\AddOns\BookArchivist" -Target "C:\dev\BookArchivist"
```

**Linux / macOS:**
```bash
# Symbolic link
ln -s ~/dev/BookArchivist ~/Games/World\ of\ Warcraft/_retail_/Interface/AddOns/BookArchivist

# Example paths:
# Linux:  ~/Games/World\ of\ Warcraft/_retail_/Interface/AddOns/
# macOS:  /Applications/World\ of\ Warcraft/_retail_/Interface/AddOns/
```

**Verify it worked:**
- Windows: `dir "C:\World of Warcraft\_retail_\Interface\AddOns\BookArchivist"` (should show `<JUNCTION>` or `<SYMLINK>`)
- Linux/macOS: `ls -la ~/Games/World\ of\ Warcraft/_retail_/Interface/AddOns/BookArchivist` (should show `->` arrow)

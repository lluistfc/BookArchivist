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

- **Search and filters**
  - Search across titles and text from the main header search box.
  - Filter and sort modes exposed via the list header and dropdowns.

- **Quality-of-life**
  - Minimap button and slash command entry points for opening the library.
  - Optional delete button in the reader with confirmation dialog.

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
  - If enabled, use the Delete button to remove an entry (with confirmation).

## Architecture overview

### Core

- `core/BookArchivist.lua` — addon bootstrap, event wiring, high-level helpers (e.g. `RefreshUI`, `ToggleUI`).
- `core/BookArchivist_Core.lua` — SavedVariables schema, keying, ordering, and persistence helpers.
- `core/BookArchivist_Capture.lua` — ItemText capture sessions and incremental persistence.
- `core/BookArchivist_Location.lua` — provenance (zone chain, NPC names) for location breadcrumbs.
- `core/BookArchivist_Minimap.lua` — minimap button state; persistence of angle/visibility.

### UI framework

- `ui/BookArchivist_UI.lua` — shared UI state and `BookArchivist.UI.Internal` helpers (selection, list mode, widget registry).
- `ui/BookArchivist_UI_Core.lua` — binds list and reader modules to injected helpers; safe wrappers and logging.
- `ui/BookArchivist_UI_Frame_Layout.lua` — main frame body layout and splitter between list and reader.
- `ui/BookArchivist_UI_Frame_Chrome.lua` — frame chrome (dragging, portrait, title, options button, header blocks).
- `ui/BookArchivist_UI_Frame_Builder.lua` — creates the main frame using the layout/chrome helpers.
- `ui/BookArchivist_UI_Frame.lua` — entry point that ensures the frame is built and shown/hidden.
- `ui/BookArchivist_UI_Runtime.lua` — orchestration, slash commands, and safe refresh sequencing.

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
- `ui/reader/BookArchivist_UI_Reader_Layout.lua` — reader header, navigation row, and scroll/text layout.

### Other UI

- `ui/minimap/BookArchivist_UI_Minimap.lua` — minimap button UI (click handling, toggling the main frame).
- `ui/options/BookArchivist_UI_Options.lua` — options panel and integration with Blizzard's Settings.

## Development notes

- The codebase is modular: UI modules register themselves under `BookArchivist.UI.*` and often receive helpers via an injected context object.
- Frame creation should go through the existing safe-create wrappers (`Internal.safeCreateFrame` or equivalent) to avoid taint and ease testing.
- Layout uses shared metrics (`BookArchivist.UI.Metrics`) to keep padding and gaps consistent across list and reader.
- Rich HTML rendering is optional; when it fails or is disabled, the reader falls back to SimpleHTML or plain text.

For more detailed contributor guidance and conventions, see `.github/copilot-instructions.md`.

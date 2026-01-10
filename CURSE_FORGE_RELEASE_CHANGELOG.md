# 2.0.3

**Small enhancement for chat link imports**

## Added
- When you import a book via chat link, you now see a confirmation dialog showing the book title on success or error details if something goes wrong

---

# 2.0.2

**Bug fix release addressing search, settings, and localization issues**

## Fixed
- Fixed search getting stuck showing "Filtering books..." after searches with no results
- Fixed "Show tooltip 'Archived' Tag" checkbox not remembering your choice after closing and reopening settings
- Fixed language dropdown not updating the addon when you select a different language
- Fixed settings panel text staying in the old language when you change languages (now shows a reload dialog to update the panel)
- Fixed confirmation dialog incorrectly appearing when toggling other checkboxes
- Fixed book deletion not working
- Fixed "Unknown Zone" and "Unknown Mob" showing in English instead of your language

---

# 2.0.1

**Hotfix for production mode crash**

## Fixed
- Fixed critical error preventing addon from loading in production mode (missing `IsDebugEnabled` method)
- Fixed stack overflow from circular dependency during database initialization
- Added initialization guard to safely handle debug logging during startup

---

# 2.0.0

**🚨 MAJOR UPDATE:** This version includes breaking database changes with automatic migration. Your data will be preserved, but you cannot downgrade to 1.0.2 after upgrading.

## What's New

### Database Overhaul
- Complete database restructure with migration system that automatically upgrades your saved books without data loss
- New stable book ID system (v2) ensures consistent identification across sessions
- New Favorites system:
  - Mark books as favorites and see a star icon in the list.
  - Quickly filter the list (or use the Favorites view) to focus on your must-keep texts.
- "Recently Read" view that tracks the books you opened most recently, making it easy to jump back into what you were just reading.
- "Resume last book" button in the header that re-opens the last book you were reading, including the last page where you left off when possible.
- Faster, clearer search:
  - Uses a pre-built index of your books for better performance.
  - Small badges in the list show whether a match came from the title or the book’s text.
- Tooltip integration:
  - Tooltips on readable items and world objects now indicate when their text is already archived by BookArchivist.
  - New option to toggle tooltip integration on/off
- Export/import support so you can share or back up your archived books between characters or installations.
- Options panel with essential settings:
  - Toggle tooltip "Archived" tag display
  - Resume on last page when reopening books
  - Language selector for addon localization
  - Import/Export/Debug tools for data management
- Numerous UI polish fixes to make the list and reader more consistent, readable, and reliable.

## 1.0.2

- Fixed a logout "taint" issue by avoiding unsafe Blizzard popups/settings hooks while BookArchivist is loaded.
- Improved the automatic build and upload workflow so release zips are generated more reliably on pushes and new tags.

## 1.0.1

- Added multi-language support for the main UI and messages (including Italian, French, German, and Portuguese).
- Fixed issues where some texts were not updating correctly and cleaned up release artifacts.

# 2.3.2

**New Feature: Create Your Own Books!**

This release adds the ability to create custom books in BookArchivist, along with improvements to location navigation.

## What's New

### Create Custom Books ✍️

You can now write your own books!
- **Create Books**: New "Create Book" button in the main window
- **Full Editor**: Add title, multi-page content, and location information
- **Edit Anytime**: Edit or delete your custom books later
- **Custom Icon**: See a special icon ✨ next to your custom books
- **Filter by Custom**: New "Custom Books" option in the View dropdown

### Smart Location Defaults 📍

Creating books is now easier:
- **Auto-Location**: New books automatically use your current location
- **No Empty Fields**: Location is pre-filled when you create a book
- **Update Anytime**: Change location when editing with "Use Current Location" button

### Better Location Navigation 🗺️

Finding books in nested zones is much easier:
- **See All Books**: Books in subzones now appear when viewing parent zones
- **Example**: Books captured in "Isle of Dorn > Fungal Folly" now show up when viewing "Isle of Dorn"
- **Cleaner Navigation**: Zones without books show only subzones (no empty results)
- **Smart Display**: Only zones with books directly show their descendant books

---

# 2.3.1

**Feature Release: Minimap Improvements**

This release upgrades the minimap button system for better compatibility and reliability.

## What's New

### Improved Minimap Button 📍

- **Better Integration**: Now uses LibDBIcon, the industry-standard library for minimap buttons
- **More Reliable**: Improved drag behavior and position saving
- **Better Compatibility**: Works seamlessly with other addons that use LibDBIcon
- **Automatic Compartment**: Full support for the addon compartment button

## What's Changed

- Internal code quality improvements

---

# 2.3.0

**New Feature: Book Echo System**

## What's New

### Book Echo 💬

Experience your books with personality! After reading, you'll see contextual flavor text that adds charm to your library experience:
- **Read Count Tracking**: See how many times you've revisited each book
- **Context-Aware Messages**: 50+ unique echoes based on content, creator, and rarity

Examples:
- "You've read this 3 times. A favorite, perhaps?"
- "Another tome by Khadgar. His wisdom is timeless."
- "A rare find! Only the most dedicated collectors have seen this."

### Bug Fixes

- Fixed echo display issues (race conditions, truncation, refresh problems)
- Fixed pagination sync issues in Locations tab
- Fixed orphaned books not appearing in database order after migration
- Improved page turn detection for more accurate read counts

### Behind the Scenes

- Database v3 migration for echo support and read tracking
- Enhanced export system with metadata stripping for cleaner payloads

### Feedback Welcome

The Book Echo system adds personality to your reading experience! If you have suggestions for new echo templates or encounter any issues, please share your feedback on CurseForge or GitHub.

---

# 2.2.0

**New Feature: Random Book Discovery**

## What's New

### Random Book Button 🎲

Discover books you might have forgotten! The new Random button opens a random book from your library and automatically:
- Shows the book in the Locations tab for geographic context
- Paginates to the exact page where the book appears
- Avoids showing the currently open book (unless it's your only book)

Perfect for rediscovering your collection or getting inspired by serendipitous finds!

### UI Improvements

- **Independent Pagination**: Books and Locations tabs now maintain separate page numbers (no more confusion when switching between tabs)
- **Fixed Pagination Bug**: Locations tab now properly updates content when you change pages

### Critical Bug Fix

- **Restored Location Data Capture**: Fixed a regression in v2.0.2 that broke location tracking for newly captured books. Books now correctly record where you found them again, and the Locations tab will populate properly for new captures.

### Behind the Scenes

- Added 130+ new automated tests (total: 489 passing tests)
- Integrated advanced WoW API mocking for more reliable testing
- Added code coverage tracking to ensure quality
- Implemented LibDeflate compression for 75% smaller export strings
- Enhanced location system with 603 WoW zones for accurate context

### Feedback Welcome

The Random Book feature is a fun new way to rediscover your collection! If you encounter any issues, please report them on CurseForge or GitHub.

---

# 2.1.0-beta

**Infrastructure and quality improvements (beta release for testing)**

## What's New

This is a **beta release** focused on internal improvements to how BookArchivist is developed and tested. It includes no user-facing feature changes, but represents significant work to ensure the addon remains stable and reliable.

### Behind the Scenes

- Added comprehensive automated test suite (200 tests) to catch bugs before they reach users
- Implemented professional development tooling (Makefile, CI/CD, testing infrastructure)
- Enhanced code quality with Test-Driven Development practices
- Cleaned up production packages (97 essential files instead of 200+)
- Added multi-platform GitHub Actions testing (Ubuntu, Windows, macOS)

### For Users

This beta release has **no functional changes** to the addon. Your books, settings, and addon behavior remain exactly the same. This is a quality-of-life release for developers to ensure future updates are more stable.

If you're seeing this update, you have **beta releases enabled** on CurseForge. If you prefer to only receive stable releases, you can disable beta updates in CurseForge settings.

---

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

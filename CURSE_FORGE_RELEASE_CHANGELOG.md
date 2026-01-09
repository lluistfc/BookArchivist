# 1.0.3 (unreleased)

- Safer data storage with a proper database migration system so existing saved books are upgraded without losing data.
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
- Export/import support so you can share or back up your archived books between characters or installations.
- Options panel updates with new settings for favorites, the Recent view, tooltips, search behavior, and resume-reading features.
- Numerous UI polish fixes to make the list and reader more consistent, readable, and reliable.

## 1.0.2

- Fixed a logout "taint" issue by avoiding unsafe Blizzard popups/settings hooks while BookArchivist is loaded.
- Improved the automatic build and upload workflow so release zips are generated more reliably on pushes and new tags.

## 1.0.1

- Added multi-language support for the main UI and messages (including Italian, French, German, and Portuguese).
- Fixed issues where some texts were not updating correctly and cleaned up release artifacts.

---
name: k-reader-panel
description: >
  Right panel UI: Book content display, SimpleHTML rendering, page navigation (multi-page),
  favorite button, share button, delete button, and HTML fallback detection. Use when
  working with reader UI, debugging content rendering, or implementing similar read views.
  Triggers: reader panel, ShowBook, SimpleHTML, page navigation, favorite, share, delete.
---

# Reader Panel UI (Right Side)

Knowledge for BookArchivist's right panel: book content display, navigation, actions.

## Quick Reference

| Feature | Module | Key Function |
|---------|--------|--------------|
| **Display** | `UI_Reader.lua` | `ShowBook(bookId)` (renders content) |
| **Rendering** | `UI_Reader_Rich.lua` | SimpleHTML + fallback (plain text) |
| **Navigation** | `UI_Reader_Navigation.lua` | Multi-page browsing (Prev/Next) |
| **Actions** | `UI_Reader_Actions.lua` | Favorite/Share/Delete buttons |

**Critical:** SimpleHTML requires `<html><body>` tags, falls back to plain text if missing.

## Full Documentation

See: [../../.github/copilot-skills/8-reader-panel.md](../../.github/copilot-skills/8-reader-panel.md)

Contains:
- ShowBook flow (ViewModel → render → track Recent)
- SimpleHTML rendering (HTML tags, color codes, formatting)
- Page navigation (multi-page books, Prev/Next buttons)
- Favorite button (star icon, Toggle)
- Share button (export to chat)
- Delete button (confirmation dialog, remove from DB)
- HTML detection (plain text fallback)
- Content sanitization (escape sequences)

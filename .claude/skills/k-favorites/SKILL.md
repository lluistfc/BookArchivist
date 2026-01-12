---
name: k-favorites
description: >
  Favorites and Recent systems for BookArchivist. Covers favorite flags (Set/Toggle/IsFavorite),
  MRU list management (Recent:MarkOpened/GetList), virtual categories toggle, stale entry
  cleanup, and category filtering logic. Use when working with Favorites/Recent features,
  debugging category filters, or implementing similar tracking.
  Triggers: favorites, recent, MRU, isFavorite, MarkOpened, virtual categories, lastReadAt.
---

# Favorites & Recent Systems

Knowledge for user-organized categories: Favorites and Most Recently Used (Recent).

## Quick Reference

| System | API | Purpose |
|--------|-----|---------|
| **Favorites** | `Favorites:Set/Toggle/IsFavorite` | User-marked books (star icon) |
| **Recent** | `Recent:MarkOpened/GetList` | MRU list (50-entry cap) |

Both are per-character (stored in `BookArchivistDB`).

## Full Documentation

See: [../../.github/copilot-skills/3-favorites-recent.md](../../.github/copilot-skills/3-favorites-recent.md)

Contains:
- Favorites storage (`entry.isFavorite` flag)
- Favorites API (Set/Toggle/IsFavorite)
- Recent storage (`db.recent.list` + `entry.lastReadAt`)
- Recent API (MarkOpened/GetList)
- MRU maintenance (prepend + truncate to cap)
- Stale entry cleanup (filtering deleted books)
- Virtual categories toggle
- Category filtering logic
- UI integration (list panel + reader button)

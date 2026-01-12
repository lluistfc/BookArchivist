---
name: k-list-panel
description: >
  Left panel UI: Books/Locations tabs, async filtering (Iterator), sorting (ApplySort),
  pagination (PaginateArray), category system (All Books/Favorites/Recent), search bar,
  and row pooling. Use when working with list UI, debugging filters, or implementing
  similar list views.
  Triggers: list panel, Books tab, Locations tab, filtering, sorting, pagination, search.
---

# List Panel UI (Left Side)

Knowledge for BookArchivist's left panel: Books/Locations tabs, filtering, sorting, pagination.

## Quick Reference

| Feature | Module | Key Function |
|---------|--------|--------------|
| **Filtering** | `UI_List_Filter.lua` | `RebuildFiltered()` (async Iterator) |
| **Sorting** | `UI_List_Sort.lua` | `ApplySort()` (title/zone/firstSeen/lastSeen) |
| **Pagination** | `UI_List_Pagination.lua` | `PaginateArray()` (slice + boundaries) |
| **Categories** | Filter logic | `__all__`, `__favorites__`, `__recent__` |

**Critical:** Filtering uses async Iterator (16ms budget) to prevent UI freeze.

## Full Documentation

See: [../../.github/copilot-skills/7-list-panel.md](../../.github/copilot-skills/7-list-panel.md)

Contains:
- Books vs Locations tabs
- Category system (All Books, Favorites, Recent, Locations)
- Async filtering (Iterator, chunking)
- Filter state (search text, category ID, filter flags)
- Sort modes (title, zone, firstSeen, lastSeen)
- Pagination (page size, page navigation)
- Row pooling (reuse frames, avoid creation overhead)
- Search bar (real-time filtering)

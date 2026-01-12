---
name: k-capture
description: >
  Book capture system for reading books/letters in WoW. Covers ItemText event flow
  (BEGIN→READY→CLOSED), session lifecycle, incremental persistence (per-page saves),
  location resolution (loot tracking + C_Map), and source detection (GUID parsing).
  Use when debugging capture, fixing missing data, or understanding how books are recorded.
  Triggers: capture, ItemText, ITEM_TEXT_BEGIN, ITEM_TEXT_READY, OnReady, session, location.
---

# Book Capture System (Reading Flow)

Knowledge for how BookArchivist captures book content during player reading.

## Quick Reference

| Event | Handler | Action |
|-------|---------|--------|
| `ITEM_TEXT_BEGIN` | `Capture:OnBegin()` | Create session, detect source |
| `ITEM_TEXT_READY` | `Capture:OnReady()` | Capture page text, **persist incrementally** |
| `ITEM_TEXT_CLOSED` | `Capture:OnClose()` | Final persist, refresh UI |

**Critical:** Books are saved AFTER EACH PAGE (incremental persistence).

## Full Documentation

See: [../../.github/copilot-skills/2-capture-system.md](../../.github/copilot-skills/2-capture-system.md)

Contains:
- ItemText event sequence
- Session lifecycle (begin→ready→close)
- Incremental persistence behavior (why each page saves)
- Location resolution (BuildWorldLocation + loot tracking)
- Source detection (itemID, GUID, objectID extraction)
- `Core:PersistSession()` flow
- Merge semantics (re-reading books)

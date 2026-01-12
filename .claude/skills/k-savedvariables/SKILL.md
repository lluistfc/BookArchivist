---
name: k-savedvariables
description: >
  Database schema and persistence layer for BookArchivist. Covers BookArchivistDB structure,
  book entry schema, Repository pattern for dependency injection, indexes (item/object/title),
  migrations (v1→v2), and data flow patterns. Use when working with saved data, database
  access, or understanding persistence.
  Triggers: database, BookArchivistDB, schema, booksById, indexes, Repository, persistence, migration.
---

# SavedVariables Structure & Database Layer

Core knowledge for BookArchivist's database schema, Repository pattern, and data persistence.

## Quick Reference

| Component | Purpose |
|-----------|---------|
| `BookArchivistDB` | Per-character SavedVariables (main storage) |
| `Repository:GetDB()` | Central database access (dependency injection) |
| `booksById` | v2 book storage (keyed by stable book ID) |
| `indexes` | Fast lookups (item/object/title → bookIds) |
| Migrations | v1→v2 schema evolution |

## Full Documentation

See: [../../.github/copilot-skills/1-savedvariables-structure.md](../../.github/copilot-skills/1-savedvariables-structure.md)

Contains:
- Complete `BookArchivistDB` schema
- `BookEntry` structure (all fields explained)
- Repository pattern (Init/GetDB for test isolation)
- Index structures (objectToBookId, itemToBookIds, titleToBookIds)
- Migration system (v1→v2 booksById transition)
- Read/write data flows
- Common access patterns

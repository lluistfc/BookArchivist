---
name: k-import-export
description: >
  Import/export system for sharing books between characters. Covers BDB1 envelope format,
  async import worker (6-phase pipeline), merge semantics (handling duplicates), export
  library flow, compression (LibDeflate), and conflict detection. Use when working with
  import/export features or debugging data transfer.
  Triggers: import, export, BDB1, ImportWorker, merge, compression, LibDeflate, share.
---

# Import/Export System

Knowledge for BookArchivist's data sharing system (BDB1 format, async import pipeline).

## Quick Reference

| Component | Purpose |
|-----------|---------|
| **BDB1 Format** | Envelope format (header + payload + checksum) |
| **ImportWorker** | Async 6-phase pipeline (decode→deserialize→validate→merge→index→complete) |
| **Export** | Serialize library → BDB1 envelope (with optional compression) |

**Key Feature:** Import merges books by ID (preserves existing data, avoids duplicates).

## Full Documentation

See: [../../.github/copilot-skills/5-import-export.md](../../.github/copilot-skills/5-import-export.md)

Contains:
- BDB1 envelope structure (header, CRC, schema version)
- Export flow (serialize → compress → encode → envelope)
- Import flow (6 phases: decode, deserialize, validate, merge, index, complete)
- Merge semantics (ID-based, preserves existing)
- Conflict detection (`legacy.importConflict` flag)
- Compression support (LibDeflate, v2 format)
- Error handling (CRC mismatch, schema validation)
- Async iteration (16ms budget per phase)

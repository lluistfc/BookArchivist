---
name: k-ui-refresh
description: >
  UI refresh pipeline and ViewModel state management. Covers shared UI state (ViewModel),
  safe refresh execution (guarding), lazy initialization patterns, Reader/List coordination,
  and avoiding infinite refresh loops. Use when debugging UI refresh issues, race conditions,
  or cascading updates.
  Triggers: RefreshUI, ViewModel, UI state, refresh loop, lazy init, UI coordination.
---

# UI Refresh Flow & State Management

Knowledge for BookArchivist's UI refresh pipeline and shared state (ViewModel).

## Quick Reference

| Component | Purpose |
|-----------|---------|
| **ViewModel** | Shared UI state (selection, mode, filters) |
| **RefreshUI()** | Safe refresh pipeline (guarded execution) |
| **Lazy Init** | Defer frame creation until needed |

**Critical:** RefreshUI uses guards to prevent infinite loops (common during multi-page capture).

## Full Documentation

See: [../../.github/copilot-skills/6-ui-refresh-flow.md](../../.github/copilot-skills/6-ui-refresh-flow.md)

Contains:
- ViewModel structure (selection, mode, filters, pagination)
- RefreshUI pipeline (guard → list refresh → reader refresh)
- Lazy initialization pattern (SafeCreateFrame)
- Reader/List coordination (selection sync)
- Refresh guards (preventing cascading calls)
- Capture refresh behavior (once per session, not per page)
- Common pitfalls (infinite loops, race conditions)

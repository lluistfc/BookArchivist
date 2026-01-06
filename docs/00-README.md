# BookArchivist Async Import (Detailed Implementation Plans)

This folder contains a step-by-step, file-by-file plan to implement a **non-blocking** Import flow that:
- preserves the existing behavior of `Core:ImportFromString()`
- avoids long UI hitches (paste + import)
- scales to 1000+ books by chunking merge and derived-field work across frames

## Files
1. `01-ui-fast-paste-buffer.md` — Make pasting large payloads instant (do not render megabytes in an EditBox).
2. `02-core-expose-buildsearchtext.md` — Minimal, trunk-safe Core refactor: expose BuildSearchText for reuse.
3. `03-importworker-new-file.md` — Create `BookArchivist_ImportWorker.lua` (worker skeleton + phases).
4. `04-importworker-merge-phase.md` — Implement merge semantics identical to Core’s sync import.
5. `05-importworker-finalize-phase.md` — Chunked derived fields + title indexing + recent sanitize.
6. `06-ui-wire-import-button.md` — Replace sync import call with worker start + progress UI.
7. `07-toc-and-loading-order.md` — Ensure new files load in the right order, avoid nil refs.
8. `08-test-plan.md` — Concrete in-game test plan + perf validation checks.
9. `09-failure-modes-and-guards.md` — Limits, error handling, cancellation, and edge cases.

## Scope assumptions
- Retail only (as per project).
- DB is per-character (`BookArchivistDB` SavedVariables).
- Payload schema currently: `schemaVersion=1`, `booksById`, `order` (from `Core:ExportToString()` / `ImportFromString()`).

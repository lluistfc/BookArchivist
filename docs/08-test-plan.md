# 08 — Test Plan (in-game)

## Setup
- Ensure you have a character with existing books (per-character DB).
- Use `/reload` between tests to confirm saved vars persist.

## Test 1: Small payload parity
1. Export with ~10 books.
2. Delete 2 books.
3. Import payload via async worker.
4. Verify:
   - Deleted books restored
   - seenCount increments correctly
   - favorites preserved
   - order preserved (no duplicates)
   - title search finds imported titles
   - content search finds pages

## Test 2: Paste performance
1. Generate payload.
2. Paste into import box.
Expected:
- No multi-second UI hitch.
- Placeholder appears for large payload.

## Test 3: Medium library (simulate)
- Duplicate payload entries (dev only) to create ~200+ books.
- Import.
Expected:
- UI remains responsive.
- Progress (if enabled) increments.
- No "script too long" message.

## Test 4: Conflict behavior
1. Export payload.
2. Modify one book title in DB (or export payload edit) to create a mismatch.
3. Import.
Expected:
- Does not overwrite existing title/pages.
- Sets `legacy.importConflict = true`.

## Test 5: Cancellation safety
- Start import, then close options panel or /reload.
Expected:
- No errors on reload.
- DB remains consistent (may be partially imported; acceptable if documented).

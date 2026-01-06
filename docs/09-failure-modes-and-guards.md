# 09 — Failure modes, guards, and limits

## Payload limits
- Enforce `IMPORT_MAX_PAYLOAD_CHARS` in UI (hard cap).
- If exceeded -> show error placeholder, do not start worker.

## Schema validation
- payload must be table
- schemaVersion must be supported (1)
- booksById must be table
- order if present must be table

## Error handling
- Any failure -> `onError` callback
- Always re-enable buttons on error
- Log a single concise message via print()

## Partial import behavior
- If user /reload during import:
  - Some books may already be merged into DB.
  - This is acceptable; next import can re-run idempotently.
  - Ensure merge logic is safe for repeats (it is, due to additive/min/max semantics).

## Avoid O(n^2)
- Use orderSet to avoid linear searches when appending to db.order.
- Use sorted key arrays to have deterministic progress and stable performance.

## Avoid expensive operations in merge loop
- No BuildSearchText in merge.
- No IndexTitleForBook in merge.
- No UI refresh in merge.
- Only minimal field merging + marking for finalize.

## Optional: Progress UI throttling
- Update progress label once per frame (not per book).

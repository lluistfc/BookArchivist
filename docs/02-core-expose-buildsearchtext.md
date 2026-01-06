# 02 — Core: Expose BuildSearchText (single-source derived logic)

## Why
Your synchronous import calls `ensureImportedEntryDerivedFields()` which uses a local `buildSearchText()`.
The ImportWorker must produce identical `searchText` output. Duplicating the function risks drift.

## Target file
- `BookArchivist_Core.lua`

## Step-by-step change

### Step 1: Locate the local function `buildSearchText(title, pages)`
It is currently a local helper inside Core (used by `ensureImportedEntryDerivedFields`).

### Step 2: Add a Core method that delegates to the local function
Add below the local function definition (or near other Core helpers):

```lua
function Core:BuildSearchText(title, pages)
  return buildSearchText(title, pages)
end
```

This keeps the implementation single-sourced and unit-testable.

### Step 3: (Optional) Expose normalization function too (only if worker needs it)
Most likely not needed if worker only calls `Core:BuildSearchText()`.

## Acceptance checks
- No behavior change in current addon flows.
- `Core:BuildSearchText()` returns the same value used in import/export flows.

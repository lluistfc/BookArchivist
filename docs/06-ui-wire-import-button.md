# 06 — UI: Wire Import button to ImportWorker (replace sync import)

## Goal
Stop calling synchronous `BookArchivist:ImportLibrary()` from the Options panel.
Instead, start the ImportWorker and disable buttons while it runs.

## Target file
- `BookArchivist_UI_Options.lua`

## Step-by-step changes

### Step 1: Ensure worker exists on the panel
After optionsPanel creation:
```lua
optionsPanel.importWorker = optionsPanel.importWorker or BookArchivist.ImportWorker:New(optionsPanel)
```

### Step 2: Replace Import OnClick handler
Find the existing handler that calls:
- `BookArchivist:ImportLibrary(text, { dry = false })`
Replace with:

```lua
importButton:SetScript("OnClick", function()
  local raw = trim(GetImportPayload())
  if raw == "" then
    print("[BookArchivist] Import payload missing")
    return
  end

  importButton:Disable()
  exportButton:Disable()

  optionsPanel.importWorker:Start(raw, {
    onProgress = function(label, pct)
      -- optional: update a status fontstring
      -- status:SetText(("%s: %d%%"):format(label, math.floor((pct or 0)*100)))
    end,
    onDone = function(summary)
      importButton:Enable()
      exportButton:Enable()
      print("[BookArchivist] " .. (summary or "Import complete"))

      -- Refresh UI once (do not rebuild during import)
      if BookArchivist.UI and BookArchivist.UI.Refresh then
        BookArchivist.UI:Refresh()
      elseif BookArchivist.RefreshUI then
        BookArchivist:RefreshUI()
      end
    end,
    onError = function(err)
      importButton:Enable()
      exportButton:Enable()
      print("[BookArchivist] Import failed: " .. tostring(err))
    end,
  })
end)
```

### Step 3: Add a small status label (optional but recommended)
Add under Import column:
- `GameFontHighlightSmall` fontstring
- cleared on start
- updated in onProgress

### Step 4: Export button (optional)
For huge payloads, avoid setting the full string to the export editbox.
Store in `optionsPanel.lastExportPayload` and show placeholder.

## Acceptance checks
- Import no longer freezes UI.
- Buttons disable while running and re-enable at end.
- Imported books appear after refresh.

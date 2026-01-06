# 01 — UI: Fast paste buffer (no EditBox megabytes)

## Why this is mandatory
Even if decoding/merging is fast, **rendering a huge string** in an EditBox is slow.
Your symptom (Ctrl+A shows text exists but not visible, and paste takes seconds) is classic:
- EditBox tries to layout and render the entire payload.
- ScrollFrame updates on every paste step.
- UI hitches scale roughly with payload size.

## Target file
- `BookArchivist_UI_Options.lua`

## Implementation steps

### Step 1: Add constants (top of file near helpers)
Add:
```lua
local IMPORT_PASTE_RENDER_LIMIT = 16000        -- chars kept visible in EditBox
local IMPORT_MAX_PAYLOAD_CHARS  = 5*1024*1024  -- hard cap: 5 MB
```

### Step 2: Add state fields on the optionsPanel
In `OptionsUI:Ensure()` after `optionsPanel` creation, add:
```lua
optionsPanel.pendingImportPayload = optionsPanel.pendingImportPayload or nil
optionsPanel.pendingImportVisibleIsPlaceholder = false
```

### Step 3: Hook `importBox` OnTextChanged (after importBox is created)
Add exactly once (ensure you don't overwrite other scripts you need; if you already set scripts,
incorporate this logic into your existing handler):

```lua
local function SetImportPlaceholder(box, msg)
  optionsPanel.pendingImportVisibleIsPlaceholder = true
  box:SetText(msg)
  box:HighlightText(0, 0)
  box:SetCursorPosition(0)
end

importBox:SetScript("OnTextChanged", function(self, userInput)
  if not userInput then return end
  local text = self:GetText() or ""

  if #text == 0 then
    optionsPanel.pendingImportPayload = nil
    optionsPanel.pendingImportVisibleIsPlaceholder = false
    return
  end

  if #text > IMPORT_MAX_PAYLOAD_CHARS then
    optionsPanel.pendingImportPayload = nil
    SetImportPlaceholder(self, "Payload too large. Aborting.")
    return
  end

  -- Always store the full payload out-of-band
  optionsPanel.pendingImportPayload = text
  optionsPanel.pendingImportVisibleIsPlaceholder = false

  -- If it's large, replace visible text so EditBox doesn't render megabytes
  if #text > IMPORT_PASTE_RENDER_LIMIT then
    SetImportPlaceholder(self, ("Payload received (%d chars). Click Import."):format(#text))
  end
end)
```

### Step 4: Utility function to read payload for import
Add near import button handler:
```lua
local function GetImportPayload()
  -- If UI shows placeholder, the real payload is in pendingImportPayload
  if optionsPanel.pendingImportVisibleIsPlaceholder then
    return optionsPanel.pendingImportPayload or ""
  end
  return optionsPanel.pendingImportPayload or (importBox:GetText() or "")
end
```

### Step 5: Optional: Make Export box also avoid rendering megabytes
Same approach:
- store `optionsPanel.lastExportPayload`
- show a placeholder string in the export EditBox
- add a "Copy" button (optional) that sets the real text briefly and highlights it

Minimal safe option:
```lua
if #payload > IMPORT_PASTE_RENDER_LIMIT then
  optionsPanel.lastExportPayload = payload
  exportBox:SetText(("Payload generated (%d chars). Use Copy button."):format(#payload))
else
  exportBox:SetText(payload)
end
```

## Acceptance checks
- Pasting a big payload no longer freezes the UI.
- `GetImportPayload()` returns the real string even when placeholder is displayed.

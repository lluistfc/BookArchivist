# Ace3 Library Analysis and Cleanup

## Summary

After comparing the current Ace3 usage with the last commit (34cd334), we discovered that the Ace3 event and console library embedding was unnecessary. The original code already had a simpler, working implementation using vanilla WoW APIs.

## Findings

### What Was Added (Unnecessarily)
- **AceEvent-3.0**: Event handling wrapper
- **AceConsole-3.0**: Slash command wrapper  
- **AceConfig-3.0**: Configuration system (RegisterOptions() was called but never implemented)

### What Was Already Working
1. **Event Handling**: Original code used vanilla event frame:
   ```lua
   local eventFrame = createFrameShim("Frame")
   eventFrame:RegisterEvent("ADDON_LOADED")
   eventFrame:SetScript("OnEvent", function(_, event, ...)
     if event == "ADDON_LOADED" then
       handleAddonLoaded(...)
     end
   end)
   ```

2. **Slash Commands**: Original code used native SlashCmdList in `ui/BookArchivist_UI_Runtime.lua`:
   ```lua
   SLASH_BOOKARCHIVIST1 = "/ba"
   SLASH_BOOKARCHIVIST2 = "/bookarchivist"
   SlashCmdList["BOOKARCHIVIST"] = function(msg)
     -- handler code
   end
   ```

### What We Actually Need
- **LibStub**: Dependency loader for Ace3 libraries
- **CallbackHandler-1.0**: Callback system used by AceGUI
- **AceGUI-3.0**: GUI widgets (specifically MultiLineEditBox for import/export panels)

## Changes Made

### 1. Reverted BookArchivist.lua
- Removed AceEvent:Embed() and AceConsole:Embed()
- Restored vanilla event frame with OnEvent script
- Removed AceEvent method-based handlers (ADDON_LOADED, ITEM_TEXT_BEGIN, etc.)
- Removed AceConsole RegisterChatCommand calls
- Removed RegisterOptions() call (function never existed)

### 2. Updated BookArchivist.toc
Removed unnecessary library references:
```diff
- libs\AceEvent-3.0\AceEvent-3.0.xml
- libs\AceConsole-3.0\AceConsole-3.0.xml
- libs\AceConfig-3.0\AceConfig-3.0.xml
```

### 3. Cleaned Up libs/ Folder
Deleted unnecessary folders:
- `libs/AceEvent-3.0/`
- `libs/AceConsole-3.0/`
- `libs/AceConfig-3.0/`

Kept required libraries:
- `libs/LibStub/`
- `libs/CallbackHandler-1.0/`
- `libs/AceGUI-3.0/`

## Benefits

1. **Simpler Code**: Vanilla WoW APIs are more straightforward
2. **Smaller Footprint**: Removed ~3 unnecessary library folders
3. **Fewer Dependencies**: Less code to maintain and update
4. **Better Performance**: No extra abstraction layers
5. **Original Design**: Restored the original, proven implementation

## Testing Checklist

- [ ] Slash commands still work (`/ba`, `/bookarchivist`)
- [ ] Events still fire (ADDON_LOADED, ITEM_TEXT_BEGIN, ITEM_TEXT_READY, ITEM_TEXT_CLOSED)
- [ ] Import/export UI still uses AceGUI MultiLineEditBox
- [ ] Share button exports single books correctly
- [ ] No Lua errors on addon load
- [ ] No taint warnings

## Conclusion

The Ace3 event and console libraries were added in error. The original vanilla WoW API implementation was simpler and more appropriate for this addon's needs. Only AceGUI-3.0 is required for the MultiLineEditBox widget used in import/export panels.

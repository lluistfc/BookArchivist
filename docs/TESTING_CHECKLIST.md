# Testing Checklist - Debug Code Refactoring

## Production Build Testing (Dev TOC Disabled)

To test production mode:
```powershell
Rename-Item -Path "BookArchivist_Dev.toc" -NewName "BookArchivist_Dev.toc.disabled"
```

Then `/reload` in-game.

### Expected Behavior (Production)

- [ ] Addon loads without errors
- [ ] No debug checkbox in Options panel (Settings → AddOns → BookArchivist)
- [ ] `/badev` command shows "Unknown command"
- [ ] No debug messages appear in chat when using addon
- [ ] `self:DebugPrint()` calls are silent (no errors, no output)
- [ ] All normal functionality works:
  - [ ] Capture books
  - [ ] Browse library
  - [ ] Search books
  - [ ] Share books
  - [ ] Import/Export
- [ ] No frame grid overlays visible
- [ ] No performance issues or lag

### What's Missing (Intentionally)

These should NOT exist in production:
- Debug options checkbox
- `/badev` command
- Debug chat messages
- UI frame grid overlays
- Test data generator

---

## Development Build Testing (Dev TOC Enabled)

To test dev mode:
```powershell
Rename-Item -Path "BookArchivist_Dev.toc.disabled" -NewName "BookArchivist_Dev.toc"
```

Then `/reload` in-game.

### Expected Behavior (Development)

- [ ] Addon loads without errors
- [ ] "BookArchivist Dev Tools loaded" message in chat
- [ ] Debug checkbox appears in Options panel
- [ ] `/badev help` shows available commands:
  - `/badev chat` - Toggle debug logging
  - `/badev grid` - Toggle UI frame overlays
  - `/badev help` - Show help

#### Debug Chat Logging

- [ ] `/badev chat` enables debug mode
- [ ] Green message: "[DEV] Debug chat logging enabled"
- [ ] Debug messages appear in chat when using addon:
  - Filter operations
  - List rebuilds
  - Navigation events
- [ ] `/badev chat` again disables debug mode
- [ ] Orange message: "[DEV] Debug chat logging disabled"
- [ ] Debug messages stop appearing

#### Debug Checkbox (Settings UI)

- [ ] Open Settings → AddOns → BookArchivist
- [ ] "Enable Debug Mode" checkbox is present
- [ ] Checking it enables both chat logging and grid overlays
- [ ] Unchecking it disables both
- [ ] State persists after `/reload`

#### UI Grid Overlays

- [ ] `/badev grid` enables frame overlays
- [ ] Green message: "[DEV] Frame grid overlays enabled"
- [ ] Colored overlays appear on frames (when implemented)
- [ ] `/badev grid` again disables overlays
- [ ] Orange message: "[DEV] Frame grid overlays disabled"

#### State Persistence

- [ ] Enable debug mode via checkbox
- [ ] `/reload`
- [ ] Debug mode still enabled
- [ ] Disable debug mode via `/badev chat`
- [ ] `/reload`
- [ ] Debug mode still disabled

---

## Release Package Testing

### Manual Package

1. Copy BookArchivist folder
2. Delete `dev/` folder
3. Delete `BookArchivist_Dev.toc`
4. Test as production build above

### CurseForge/Wago Package

After pushing a release tag:
1. Download packaged addon
2. Verify `dev/` folder is absent
3. Verify `BookArchivist_Dev.toc` is absent
4. Verify no debug options in UI
5. Verify all normal features work

---

## Integration Testing

### Existing Debug Calls

Test that existing `DebugPrint()` calls work correctly:

**In Production (Dev TOC disabled):**
- [ ] No errors from `self:DebugPrint()` calls
- [ ] No chat spam
- [ ] Silent no-ops

**In Development (Dev TOC enabled):**
- [ ] `self:DebugPrint()` messages appear when debug enabled
- [ ] Messages have proper format: `[DEV] <message>`
- [ ] Messages are suppressed when debug disabled

### Options Panel Integration

- [ ] Production: Options panel works, no debug checkbox
- [ ] Development: Options panel works, debug checkbox present
- [ ] No layout issues in either mode
- [ ] Other settings (language, tooltip, etc.) unaffected

---

## Regression Testing

Verify no breaking changes to existing features:

- [ ] Book capture still works
- [ ] Library browsing works
- [ ] Search functionality works
- [ ] Favorites work
- [ ] Locations mode works
- [ ] Reader navigation works
- [ ] Delete book works
- [ ] Share book works
- [ ] Import/Export works
- [ ] Minimap button works
- [ ] Tooltip integration works
- [ ] Slash commands work (`/ba`, `/bookarchivist`)

---

## Performance Testing

Compare performance before/after:

### Production Mode
- [ ] No measurable performance difference
- [ ] No increased memory usage
- [ ] Smooth UI interactions
- [ ] Fast filtering (< 50ms for 1000 books)

### Development Mode
- [ ] Minimal performance impact when debug disabled
- [ ] Some overhead when debug enabled (expected)
- [ ] UI remains responsive

---

## Edge Cases

- [ ] Load addon without BookArchivist_Dev.toc → works
- [ ] Load addon with BookArchivist_Dev.toc → works
- [ ] Enable debug, rename Dev TOC, `/reload` → no errors, debug silent
- [ ] Rename Dev TOC, rename back, `/reload` → debug works again
- [ ] Multiple `/reload` cycles → stable
- [ ] Enable debug, logout, login → state persists

---

## Documentation Review

- [ ] DEV_SETUP.md is accurate
- [ ] DEV_REFACTOR_SUMMARY.md is complete
- [ ] .pkgmeta excludes correct files
- [ ] README (if updated) mentions dev setup

---

## Final Checklist Before Commit

- [ ] All tests pass in production mode
- [ ] All tests pass in development mode
- [ ] No errors in BugSack
- [ ] No Lua errors in chat
- [ ] No taint warnings
- [ ] Performance is acceptable
- [ ] Code is properly commented
- [ ] Commit message is descriptive


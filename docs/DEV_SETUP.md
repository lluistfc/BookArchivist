# BookArchivist Development Guide

## Development Setup

### Loading Dev Tools

BookArchivist uses separate TOC files for production and development:

- **`BookArchivist.toc`** - Production build (no debug code)
- **`BookArchivist_Dev.toc`** - Development tools (loaded automatically when present)

In your local dev environment, both TOC files will be loaded by WoW, adding debug features to the addon.

### Dev Tools Features

When `BookArchivist_Dev.toc` is loaded, you get:

1. **Debug Chat Logging** - Print debug messages to chat
2. **UI Grid Overlay** - Highlight frame boundaries with colored overlays
3. **Test Data Generator** - Generate test books for stress testing

### Dev Commands

```
/badev help   - Show available commands
/badev chat   - Toggle debug chat logging
/badev grid   - Toggle UI frame grid overlay
```

### Debug Functions

When dev tools are loaded, these functions are available:

```lua
-- Debug logging (only prints if debug mode is enabled)
BookArchivist.DevTools.DebugPrint("message", value, ...)

-- Frame grid overlay
BookArchivist.DevTools.RegisterFrameForDebug(frame, "FrameName", "red")
BookArchivist.DevTools.SetGridOverlayVisible(true)

-- Debug state
BookArchivist.DevTools.IsDebugChatEnabled()
BookArchivist.DevTools.IsGridOverlayVisible()
```

Available colors for frame overlays: `red`, `green`, `blue`, `yellow`, `cyan`, `magenta`

### Test Data Generator

Generate test books for performance testing:

```lua
BookArchivist.TestDataGenerator:GenerateBooks(count)
BookArchivist.TestDataGenerator:ClearTestBooks()
```

## Release Process

### What Gets Excluded

The `.pkgmeta` file automatically excludes from releases:

- `dev/` folder (all dev tools)
- `BookArchivist_Dev.toc`
- Documentation files (AGENTS.md, implementation plans, etc.)
- Git and IDE files

### Manual Release Package

If packaging manually (not using CurseForge/Wago):

1. Copy the addon folder
2. Delete the `dev/` folder
3. Delete `BookArchivist_Dev.toc`
4. Delete documentation files (optional)

### Automated Release (CurseForge/Wago)

The `.pkgmeta` file handles everything automatically. Just push a tag:

```bash
git tag -a v1.0.3 -m "Release 1.0.3"
git push origin v1.0.3
```

The packager will automatically exclude dev files.

## Architecture Notes

### Why Separate TOCs?

This approach provides:

- **Zero runtime overhead** in production (debug code literally doesn't exist)
- **No conditional checks** scattered through code
- **Clean separation** between production and dev code
- **Standard WoW addon practice** (used by WeakAuras, DBM, etc.)

### Integration Points

Dev tools integrate with the main addon through:

1. **Function Overrides** - `BookArchivist.IsDebugEnabled()` / `SetDebugEnabled()`
2. **UI.Internal Hooks** - `debugPrint`, `setGridOverlayVisible`, etc.
3. **Independent Module** - Can be loaded/unloaded without breaking main addon

### Debug vs LogError

- **`DebugPrint()`** - Dev-only logging, requires dev TOC
- **`LogError()`** - Production error handling, always available

Use `LogError()` for real errors that users should see in BugSack.
Use `DebugPrint()` for verbose debugging during development.


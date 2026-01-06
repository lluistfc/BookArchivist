# 07 — TOC loading order (critical)

## Goal
Ensure `BookArchivist.ImportWorker` is defined before Options UI tries to use it.

## Action
Edit `BookArchivist.toc` (or equivalent) and add:

1) After Base64/Serialize/Core:
- `BookArchivist_ImportWorker.lua`

2) Before:
- `BookArchivist_UI_Options.lua`

## Example ordering (illustrative)
```
BookArchivist.lua
BookArchivist_Core.lua
BookArchivist_Base64.lua
BookArchivist_Serialize.lua
BookArchivist_ImportWorker.lua
BookArchivist_UI_Options.lua
```

Note: keep the relative order to guarantee APIs exist.

## Acceptance checks
- No nil errors for `BookArchivist.ImportWorker` at load time.

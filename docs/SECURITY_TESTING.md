# Security Testing Instructions

Quick guide for testing Phase 1 texture path validation in-game.

## Setup

1. Ensure you're on the `feature/security-hardening` branch
2. Run `make sync` to sync addon to WoW
3. Launch WoW and `/reload`

## Generate Security Test Books

```lua
/ba gentest security
```

This generates 8 test books with malicious texture paths:
- Parent Traversal Attack
- Addon Path Spoofing
- Absolute Path (Drive)
- Absolute Path (Slash)
- Double Parent Traversal
- Mixed Slash Attack
- Very Long Path
- Trailing Slash

**Optional:** Generate more test books:
```lua
/ba gentest security 16
```

## Enable Debug Logging

To see rejected texture paths in real-time:

```lua
/ba debug on
```

## Test Procedure

### 1. Open BookArchivist UI
```lua
/ba
```

### 2. Search for Test Books
In the search box, type: `SECURITY TEST`

You should see 8 books appear in the list.

### 3. View Each Book
Click on each security test book and verify:

✅ **Expected Behavior:**
- Book opens without errors
- Content displays correctly
- Texture shows **fallback book icon** (INV_Misc_Book_09)
- Debug log shows rejection message (if debug enabled)

❌ **Failure Indicators:**
- Lua errors appear
- Texture fails to load (shows ?)
- Non-book texture displays
- No debug message for rejected path

### 4. Check Debug Output

With `/ba debug on`, you should see messages like:
```
[Reader] Rejected texture path: Interface\Icons\..\...\System32\calc.exe reason: Path contains parent directory traversal (..)
```

### 5. Verify Each Attack Vector

| Book Title | Attack Vector | Expected Result |
|------------|---------------|-----------------|
| Parent Traversal Attack | `..` in path | Rejected + fallback |
| Addon Path Spoofing | Non-whitelisted addon | Rejected + fallback |
| Absolute Path (Drive) | `C:\...` | Rejected + fallback |
| Absolute Path (Slash) | `/etc/...` | Rejected + fallback |
| Double Parent Traversal | Multiple `..` | Rejected + fallback |
| Mixed Slash Attack | `/` and `\` mix | Rejected + fallback |
| Very Long Path | >500 chars | Rejected + fallback |
| Trailing Slash | Ends with `\` | Rejected + fallback |

## Cleanup

Remove test books after testing:
```lua
/ba cleartest
```

## Troubleshooting

### No debug messages appear
- Verify debug mode: `/ba debug on`
- Check console for errors: Press `ESC > System > Console`
- Verify TextureValidator loaded: `/ba modules`

### Books don't show up
- Check total book count: `/ba stats`
- Try refreshing UI: Close and reopen `/ba`
- Check if books were created: Should see "8 books created" message

### Lua errors appear
- Note the exact error message
- Check which book triggered it
- Report error with stack trace

## Success Criteria

✅ All 8 security test books display correctly  
✅ All malicious textures show fallback icon  
✅ Debug logs show rejection reasons  
✅ No Lua errors occur  
✅ UI remains responsive  

## Expected Debug Output Sample

```
[Reader] Rejected texture path: Interface\Icons\..\...\System32\calc.exe reason: Path contains parent directory traversal (..)
[Reader] Rejected texture path: Interface\AddOns\OtherAddon\logo.tga reason: Path is not in whitelist of safe directories
[Reader] Rejected texture path: C:\Windows\System32\kernel32.dll reason: Path is not in whitelist of safe directories
[Reader] Rejected texture path: /etc/passwd reason: Path is not in whitelist of safe directories
```

## Performance Check

The security validation should have minimal performance impact:
- Book rendering should feel instant
- No noticeable lag when opening books
- Frame pool should remain efficient

Check performance with:
```lua
/ba profile
```

---

**Status:** Phase 1 texture validation security testing  
**Branch:** `feature/security-hardening`  
**Tests:** 775 automated tests passing (33 security-specific)

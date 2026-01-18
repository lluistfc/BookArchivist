# BookArchivist Security Architecture

**Last Updated:** January 18, 2026  
**Security Version:** 1.0 (Post-Hardening)

## Executive Summary

BookArchivist implements defense-in-depth security for handling untrusted book content from imports. This document describes the threat model, security boundaries, and implementation details of our three-phase security hardening.

**Key Security Features:**
- ✅ Texture path validation (prevents UI spoofing)
- ✅ Import metadata tracking (audit trail)
- ✅ Content sanitization (prevents resource exhaustion)

---

## Threat Model

### Attack Surfaces

1. **Imported Libraries (BDB1 Format)**
   - Source: Untrusted players sharing book libraries
   - Vector: Paste malicious data into import UI
   - Risk: Texture path injection, oversized content

2. **Chat Links**
   - Source: Addon-to-addon communication
   - Vector: Receive malicious BookLink in chat
   - Risk: Same as imports (processed through same deserialization)

3. **SavedVariables File**
   - Source: Direct file manipulation (advanced attack)
   - Vector: Edit `BookArchivistDB.lua` while game closed
   - Risk: Bypass in-game validation (requires file system access)

### Trust Boundaries

```
┌─────────────────────────────────────────────────┐
│  WoW Lua Sandbox (Security Boundary)            │
│  ✓ Blocks file system access                    │
│  ✓ Blocks code execution via loadstring()       │
│  ✓ Blocks network access                        │
├─────────────────────────────────────────────────┤
│  BookArchivist Addon                             │
│                                                  │
│  ┌─────────────────────────────────────────┐   │
│  │ TRUSTED: Captured Books                  │   │
│  │ - Read directly from ItemTextFrame       │   │
│  │ - No validation needed                   │   │
│  └─────────────────────────────────────────┘   │
│                    ▲                             │
│                    │                             │
│  ┌─────────────────┴───────────────────────┐   │
│  │ UNTRUSTED: Imported Books               │   │
│  │ - Deserialized from paste data           │   │
│  │ - REQUIRES validation                    │   │
│  └─────────────────────────────────────────┘   │
│                    │                             │
│                    ▼                             │
│  ┌─────────────────────────────────────────┐   │
│  │ Security Filters (3 Phases)              │   │
│  │ 1. Texture Validation                    │   │
│  │ 2. Import Metadata                       │   │
│  │ 3. Content Sanitization                  │   │
│  └─────────────────────────────────────────┘   │
│                    │                             │
│                    ▼                             │
│  ┌─────────────────────────────────────────┐   │
│  │ Database (BookArchivistDB)               │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### Threats NOT In Scope

These attacks are **blocked by WoW's Lua sandbox** and do NOT require addon-level mitigation:

- ❌ **Code Execution** - `loadstring()` disabled in WoW
- ❌ **File System Access** - No file I/O APIs available
- ❌ **Network Access** - No socket/HTTP APIs available
- ❌ **OS Commands** - No `os.execute()` available

---

## Security Implementation (3 Phases)

### Phase 1: Texture Path Validation ✅

**Goal:** Prevent UI spoofing via malicious texture paths

**Module:** `core/BookArchivist_TextureValidator.lua`

**Threat Scenario:**
```lua
-- Malicious imported book with parent traversal
book.pages[1] = [[
<html><body>
<img src="Interface\Icons\..\..\..\..\..\Windows\System32\shell32.dll" />
</body></html>
]]
-- If unchecked, could attempt to load system files
-- WoW would reject it, but better to catch early
```

**Implementation:**

1. **Whitelist Validation**
   - Only allow: `Interface\Icons`, `Interface\Pictures`, `Interface\GLUES`, `WorldMap`
   - Case-insensitive matching (WoW paths are case-insensitive)
   - No exceptions for "trusted" books (all HTML content validated)

2. **Parent Traversal Detection**
   - Reject any path containing `..` (case-insensitive)
   - Example: `Interface\Icons\..\System32` → REJECTED

3. **Path Length Limits**
   - Max 500 characters (prevents buffer overflow attempts)
   - WoW likely has lower limits, but we enforce defensively

4. **Fallback Behavior**
   - Invalid textures → `Interface\Icons\INV_Misc_Book_09` (generic book icon)
   - Graceful degradation (no error messages, no UI disruption)

**Security Properties:**
- ✅ Zero trust for texture paths (validate everything)
- ✅ Fail closed (reject on doubt, use safe fallback)
- ✅ Defense in depth (complements WoW's built-in checks)

**Test Coverage:** 33 tests
- Valid paths (whitelisted directories)
- Malicious paths (parent traversal, spoofing)
- Edge cases (null bytes, length limits)
- Integration with Rich renderer

---

### Phase 2: Import Metadata Tracking ✅

**Goal:** Audit trail for imported books, foundation for trust workflow

**Module:** `core/BookArchivist_ImportWorker.lua` (4 new methods)

**Threat Scenario:**
```lua
-- User imports 1000 books from unknown source
-- Later discovers content issues
-- Question: "Which books were imported? When?"
-- Without metadata: NO WAY TO KNOW
```

**Implementation:**

1. **Metadata Structure**
   ```lua
   entry.importMetadata = {
       importedAt = 1737158400,  -- Unix timestamp
       source = "IMPORT",         -- vs "CAPTURE"
       trusted = false            -- Default: untrusted
   }
   ```

2. **Tracking Workflow**
   - `MarkAsImported(bookEntry)` - called on merge (new or existing)
   - `IsImported(bookEntry)` - check if book has import metadata
   - `MarkAsTrusted(bookEntry)` - mark as trusted (future UI feature)
   - `IsTrusted(bookEntry)` - check trust status

3. **Automatic Tracking**
   - All imported books marked automatically during merge
   - Captured books (from reading in-game) do NOT have importMetadata
   - Clear differentiation: imported vs captured

**Security Properties:**
- ✅ Audit trail (when/how book was acquired)
- ✅ Differentiation (imports vs captures)
- ✅ Foundation for future trust UI

**Future Enhancements (Deferred):**
- ⏭️ Warning banner for untrusted imports
- ⏭️ "Trust this book" button
- ⏭️ Import history UI

**Test Coverage:** 7 tests
- Metadata structure validation
- Timestamp tracking
- Source differentiation
- Trust workflow

---

### Phase 3: Content Sanitization ✅

**Goal:** Prevent resource exhaustion via oversized content

**Module:** `core/BookArchivist_ContentSanitizer.lua` (197 lines)

**Threat Scenario:**
```lua
-- Malicious import with 10MB book
book = {
    title = string.rep("A", 1000000),  -- 1MB title
    pages = {}
}
for i = 1, 10000 do
    book.pages[i] = string.rep("X", 100000)  -- 100KB per page
end
-- Result: 1GB+ memory usage, client freeze
```

**Implementation:**

1. **String Length Limits**
   ```lua
   MAX_TITLE_LENGTH = 255    -- Reasonable UI display
   MAX_PAGE_LENGTH = 10000   -- ~10 printed pages
   MAX_PAGE_COUNT = 100      -- Total pages per book
   ```

2. **Sanitization Functions**
   - `StripNullBytes(str)` - removes `%z` characters (data corruption)
   - `NormalizeLineEndings(str)` - converts CRLF to LF (consistency)
   - `StripControlChars(str)` - removes non-printable (keeps \n, \t, \r)
   - `SanitizeTitle(title)` - enforces 255 char limit
   - `SanitizePage(page)` - enforces 10K char limit
   - `SanitizePages(pages)` - enforces 100 page limit
   - `SanitizeBook(book, options)` - full sanitization with reporting

3. **Import Integration**
   ```lua
   -- ImportWorker merge phase
   local sanitized, report = ContentSanitizer.SanitizeBook(incomingBook, {
       reportChanges = true
   })
   
   if report.titleTruncated then
       BA:DebugPrint("Title truncated:", report.originalTitleLength, "→", 
                     report.sanitizedTitleLength)
   end
   ```

4. **Reporting (Debug Mode)**
   - Logs truncated content lengths
   - Reports: `titleTruncated`, `pageTruncated`, `pageCountTruncated`
   - Helps identify malicious imports vs legitimate oversized books

**Security Properties:**
- ✅ Memory limits (prevents DoS)
- ✅ Data integrity (removes corrupting characters)
- ✅ Consistency (normalizes line endings)
- ✅ Transparency (debug logging for truncations)

**Test Coverage:** 13 tests
- Length limit enforcement
- Null byte removal
- Line ending normalization
- Control character stripping
- Edge cases (nil values, empty strings)

---

## Safe Coding Practices

### 1. Never Trust Deserialized Data

```lua
-- ❌ WRONG: Direct use of imported data
local book = deserialize(importedString)
texture:SetTexture(book.texturePath)  -- UNSAFE!

-- ✅ CORRECT: Validate before use
local book = deserialize(importedString)
local safePath = TextureValidator.ValidatePath(book.texturePath)
texture:SetTexture(safePath)  -- Uses fallback if invalid
```

### 2. Sanitize Before Storage

```lua
-- ❌ WRONG: Store imported data directly
db.booksById[bookId] = importedBook

-- ✅ CORRECT: Sanitize first
local sanitized = ContentSanitizer.SanitizeBook(importedBook)
db.booksById[bookId] = sanitized
```

### 3. Validate at Boundaries

**Trust boundaries:**
- Deserialization (BDB1 → Lua table)
- Display (Lua table → UI)
- Export (Lua table → BDB1)

**Validation points:**
- ✅ After deserialization (sanitize content)
- ✅ Before display (validate texture paths)
- ⚠️ Before export (future: option to strip metadata)

### 4. Fail Safely

```lua
-- ❌ WRONG: Error on invalid input
if not isValid(path) then
    error("Invalid path: " .. path)  -- Breaks UI
end

-- ✅ CORRECT: Use safe fallback
if not isValid(path) then
    return FALLBACK_TEXTURE  -- Graceful degradation
end
```

### 5. Log Security Events

```lua
-- Debug mode logging (opt-in)
if BA.DebugPrint then
    BA:DebugPrint("[Security] Rejected texture:", path)
    BA:DebugPrint("[Security] Truncated title:", originalLength, "→", 255)
end
```

---

## Security Review Checklist

Use this checklist when reviewing PRs that handle untrusted data:

### Input Validation
- [ ] All imported data sanitized before storage?
- [ ] Texture paths validated before `SetTexture()`?
- [ ] String lengths checked against limits?
- [ ] Null bytes and control chars removed?

### Trust Boundaries
- [ ] Clear distinction between captured vs imported books?
- [ ] Import metadata tracked for audit trail?
- [ ] Validation applied at all trust boundaries?

### Error Handling
- [ ] Invalid data fails safely (no crashes)?
- [ ] Fallback textures used for invalid paths?
- [ ] Security events logged in debug mode?

### Testing
- [ ] Unit tests for validation logic?
- [ ] Edge case tests (nil, empty, oversized)?
- [ ] Integration tests with Rich renderer?
- [ ] Malicious input test cases?

### Documentation
- [ ] Security-sensitive functions have comments?
- [ ] Validation logic explained?
- [ ] Trust boundaries documented?

---

## Known Limitations

### 1. SavedVariables File Manipulation

**Risk:** Advanced users can edit `BookArchivistDB.lua` while WoW is closed, bypassing validation.

**Mitigation:** None (by design). We trust users not to attack themselves. Focus is on preventing **network-based** attacks (imports from untrusted players).

**Rationale:** If an attacker has file system access, they already have full control (can inject malicious addons). SavedVariables editing is not our threat model.

### 2. Trust Workflow Not Implemented

**Status:** Phase 2 provides **metadata foundation**, but UI is deferred.

**Future:** Add warning banner for untrusted imports, "Trust this book" button.

**Workaround:** Users can inspect books manually before importing (paste into text editor).

### 3. No Crypto Signatures

**Risk:** Cannot cryptographically verify book authenticity.

**Rationale:** 
- No shared key infrastructure in WoW
- BDB1 format is plaintext (user-editable by design)
- Focus on **damage mitigation** not **identity verification**

**Alternative:** Guild-based trust networks (future consideration).

---

## Incident Response

### Reporting Security Issues

**DO NOT** report security issues via public GitHub issues.

**Contact:** 
- Discord: Bettyboom#1234
- Email: security@bookarchivist.addon

**Include:**
1. Proof of concept (malicious import string)
2. Impact (what can an attacker achieve?)
3. Steps to reproduce

### Severity Levels

| Severity | Description | Example |
|----------|-------------|---------|
| **Critical** | Code execution, privilege escalation | None possible (blocked by sandbox) |
| **High** | UI spoofing, data exfiltration | Texture path bypass |
| **Medium** | Resource exhaustion, DoS | Oversized content (mitigated) |
| **Low** | Information disclosure | Debug logging leaks (acceptable) |

### Response Timeline

- **Critical:** 24 hours (hotfix)
- **High:** 1 week (emergency patch)
- **Medium:** 2 weeks (regular patch)
- **Low:** Next release cycle

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-18 | Initial security architecture (Phase 1-3) |
|     |            | - Texture validation |
|     |            | - Import metadata |
|     |            | - Content sanitization |

---

## References

- **SECURITY_PLAN.md** - Implementation roadmap and risk matrix
- **SECURITY_TESTING.md** - In-game testing procedures
- **TextureValidator** - `core/BookArchivist_TextureValidator.lua`
- **ContentSanitizer** - `core/BookArchivist_ContentSanitizer.lua`
- **ImportWorker** - `core/BookArchivist_ImportWorker.lua`
- **Test Suites:**
  - `Tests/Sandbox/TextureValidator_spec.lua` (33 tests)
  - `Tests/Sandbox/ImportMetadata_spec.lua` (7 tests)
  - `Tests/Sandbox/ContentSanitizer_spec.lua` (13 tests)

---

**Document Owner:** Bettyboom  
**Last Reviewed:** January 18, 2026  
**Next Review:** July 2026 (6-month cycle)

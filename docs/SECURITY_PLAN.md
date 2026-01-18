# BookArchivist Security Hardening Plan

## Executive Summary

BookArchivist's custom book feature and import/export system have been audited for security vulnerabilities. While the architecture is fundamentally secure against code execution attacks, there are low-to-medium risk vectors related to texture paths in rich content that should be addressed before public release.

## Current Security Status

### ✅ Secure Components

1. **Serialization/Deserialization**
   - Uses custom binary protocol (not `loadstring()`)
   - Type-safe: only allows `nil`, `boolean`, `number`, `string`, `table`
   - Rejects functions, userdata, threads
   - Max depth protection (20 levels)
   - No code execution possible

2. **Text Rendering**
   - Uses `SetText()` FontString method
   - Displays user input as literal text
   - Cannot execute Lua code from strings
   - No unsafe string interpolation

3. **Input Validation**
   - Title and pages stored as plain strings
   - Database schema validation
   - Book aggregate invariants checked

### ⚠️ Areas Requiring Hardening

1. **Texture Path Validation (Medium Priority)**
   - Location: `ui/reader/BookArchivist_UI_Reader_Rich.lua:274`
   - Issue: Unconstrained `SetTexture(block.src)` allows arbitrary paths
   - Risk: UI spoofing, information disclosure, resource exhaustion
   - Severity: Low-Medium (social engineering vector, not code execution)

## Implementation Plan

### Phase 1: Texture Path Security (Priority: High)

**Goal:** Prevent malicious texture references in imported books

**Files to Modify:**
- `ui/reader/BookArchivist_UI_Reader_Rich.lua`

**Implementation Steps:**

1. **Create Texture Validator Module** (`core/BookArchivist_TextureValidator.lua`)
   ```lua
   -- Whitelist-based texture path validation
   -- Checks: parent directory traversal (..), null bytes, path length
   -- WoW's sandbox already blocks: absolute paths, drive letters
   -- Allow: Interface/Icons, Interface/Pictures, Interface/GLUES, WorldMap
   ```

**Security checks:**
- Whitelist validation (only Interface\\Icons, Interface\\Pictures, Interface\\GLUES, WorldMap)
- Parent directory traversal detection (..)
- Null byte detection
- Path length limits (500 chars)
- Case-insensitive matching

**Note:** Absolute path checks (drive letters, leading slashes) are NOT implemented - WoW's Lua sandbox already prevents these at the API level (SetTexture will fail). We focus on checks that WoW doesn't enforce (whitelist, parent traversal).

2. **Add Validation to Rich Renderer**
   - Before `tex:SetTexture()`, validate path
   - On validation failure: log warning, use fallback texture
   - Fallback: Default book icon or placeholder

3. **Add User Setting**
   - Option: "Allow untrusted textures in imported books"
   - Default: `false` (safe mode)
   - Advanced users can enable if needed

4. **Testing Requirements**
   - Test valid paths (game icons, pictures)
   - Test malicious paths (parent traversal)
   - Test UI spoofing attempts
   - Test resource exhaustion (large textures)
   - Test fallback behavior

**Estimated Effort:** 4-6 hours

### Phase 2: Import Security Audit (Priority: Medium)

**Goal:** Add security metadata to imported books

**Files to Modify:**
- `core/BookArchivist_ImportWorker.lua`
- `core/BookArchivist_DB.lua` (schema update)

**Implementation Steps:**

1. **Add Import Metadata**
   ```lua
   entry.importMetadata = {
       importedAt = time(),
       importedBy = UnitName("player"),
       source = "IMPORT",  -- vs CAPTURE, CUSTOM
       trusted = false,    -- flag for review
   }
   ```

2. **Add Trust Workflow**
   - Show warning banner for untrusted imported books
   - Button: "Trust this book" (removes warning)
   - Trusted books use relaxed texture validation

3. **Audit Trail**
   - Log all imports with timestamp
   - Track which books came from external sources
   - Allow user to review import history

**Estimated Effort:** 6-8 hours

### Phase 3: Content Sanitization (Priority: Low)

**Goal:** Additional hardening for edge cases

**Implementation Steps:**

1. **String Length Limits**
   - Max title length: 255 characters
   - Max page content: 10,000 characters
   - Max total pages: 100
   - Reject oversized imports

2. **Special Character Filtering**
   - Strip null bytes (`\0`)
   - Normalize line endings
   - Remove non-printable control characters (except newlines/tabs)

3. **Memory Protection**
   - Limit simultaneous texture loads
   - Texture dimension caps (already implemented: 600px height)
   - Total memory budget tracking

**Estimated Effort:** 3-4 hours

### Phase 4: Security Documentation (Priority: High)

**Goal:** Document security architecture for maintainers and users

**Deliverables:**

1. **Developer Documentation** (`docs/SECURITY_ARCHITECTURE.md`)
   - Threat model
   - Security boundaries
   - Safe coding practices
   - Review checklist

2. **User Documentation** (README update)
   - Safe book sharing guidelines
   - Import warnings explanation
   - Reporting security issues

3. **Code Comments**
   - Mark security-sensitive functions
   - Document validation logic
   - Explain trust boundaries

**Estimated Effort:** 2-3 hours

## Risk Matrix

| Threat | Current Risk | Post-Hardening | Priority |
|--------|--------------|----------------|----------|
| **Code Execution** | None (blocked by architecture) | None | N/A |
| **UI Spoofing** | Medium | Low | High |
| **Info Disclosure** | Low | Very Low | Medium |
| **Resource Exhaustion** | Low | Very Low | Low |
| **Data Corruption** | Very Low | Very Low | Low |

## Testing Strategy

### Security Test Cases

1. **Malicious Import Test Suite**
   - Parent directory traversal attempts
   - Absolute path references
   - Oversized content (memory limits)
   - Special characters and null bytes
   - Malformed serialization data

2. **Fuzzing**
   - Random texture paths
   - Random serialization strings
   - Boundary value testing (max sizes)

3. **Regression Tests**
   - Ensure legitimate books still work
   - Performance impact measurement
   - UI responsiveness with validation

## Rollout Plan

### Pre-Release (Current Branch)
- ✅ Security audit complete
- ✅ Threat model documented
- ⏳ Phase 1 implementation (texture validation)
- ⏳ Testing and validation

### Alpha Release
- Phase 1 complete
- Documentation updated
- Security warnings in UI

### Beta Release
- Phase 2 complete (import metadata)
- User testing of trust workflow
- Performance validation

### Public Release
- Phase 3 complete (edge cases)
- Full security documentation
- Security review by community

## Timeline

| Phase | Duration | Target |
|-------|----------|--------|
| Phase 1: Texture Validation | 1 week | Feature branch |
| Phase 2: Import Security | 1-2 weeks | Alpha |
| Phase 3: Sanitization | 1 week | Beta |
| Phase 4: Documentation | Ongoing | All phases |

**Total Estimated Effort:** 15-21 hours of development + testing

## Success Criteria

- [ ] No code execution vectors
- [ ] UI spoofing prevented by default
- [ ] User-friendly trust workflow
- [ ] Minimal performance impact (<5% overhead)
- [ ] Clear security documentation
- [ ] Zero high-severity vulnerabilities
- [ ] Community security review complete

## Future Considerations

### Post-1.0 Enhancements

1. **Digital Signatures**
   - Sign exported books with creator identity
   - Verify signatures on import
   - Build reputation system

2. **Content Moderation**
   - Report inappropriate books
   - Community flagging system
   - Blocklist for known malicious exports

3. **Sandboxing**
   - Run imported content in restricted environment
   - Progressive trust levels
   - Capability-based security

4. **Security Updates**
   - Automated security patch system
   - In-game update notifications
   - CVE tracking and disclosure

## Conclusion

BookArchivist's current architecture is fundamentally secure against code execution attacks. The identified texture path issue is a low-to-medium risk social engineering vector that can be mitigated with straightforward validation logic. Implementing Phase 1 (texture validation) before public release is **strongly recommended**. Phases 2-3 are **nice-to-have** enhancements that can be rolled out incrementally.

The addon is safe for personal use in its current state. For public release with book sharing features, Phase 1 implementation is the minimum security requirement.

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-18  
**Author:** BookArchivist Security Audit  
**Status:** Plan - Awaiting Implementation

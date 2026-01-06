```md
# Plan: Pastebin-friendly Import/Export for WoW “Books Library” Addon

## Goals
- Users can upload exported data to Pastebin (or similar) and share a text blob.
- Other users can copy that text and import it via the addon UI.
- Works for hundreds/thousands of books without UI freezes or giant single-string limitations.
- Backward-compatible via versioning and safe via integrity checks.

---

## 1) Data Model + Dedup Strategy (Required)
### 1.1 Define stable identifiers
- **contentHash**: stable hash of normalized content (primary dedup key)
  - Normalize text:
    - Convert CRLF -> LF
    - Trim trailing whitespace per line
    - Collapse runs of spaces (optional)
    - Remove leading/trailing blank lines
  - Hash input: `title + "\n" + normalizedText` (optionally include author if present)
- **bookId**: internal incremental ID (optional), do not use for sharing/dedup.

### 1.2 Export payload structure (compact)
Use a compact table-like structure (not verbose JSON):
- `v`: schema version number
- `books`: array of tuples
  - Example tuple fields (minimum):
    - `h` = contentHash
    - `t` = title
    - `x` = text
    - `a` = author (optional)
  - Optional metadata (keep compact):
    - `r` = readCount
    - `s` = sources array (zone/item/object IDs) (optional)
    - `f` = firstSeen timestamp (optional)

### 1.3 Import merge rules
- For each imported book:
  - If `contentHash` exists locally:
    - Merge metadata (e.g., sum read counts; union sources; min firstSeen)
    - Do **not** duplicate text
  - Else:
    - Insert new book

---

## 2) Encoding Format (Versioned + Chunked)
### 2.1 High-level pipeline
Export:
1) Serialize -> bytes/string
2) Compress (Deflate)
3) Encode printable (chat-safe) string
4) Chunk into lines
5) Add header/footer + per-chunk indexes

Import:
1) Parse lines
2) Validate header
3) Collect chunks -> reassemble
4) Decode printable -> bytes
5) Decompress
6) Verify CRC
7) Deserialize
8) Merge

### 2.2 Add LibDeflate
- Vendor `LibDeflate` into the addon (recommended).
- Functions to use:
  - `CompressDeflate(data)`
  - `DecompressDeflate(data)`
  - `EncodeForPrint(binaryData)`
  - `DecodeForPrint(stringData)`

### 2.3 Envelope format (text-friendly, pastebin)
Use one line per chunk, easy to parse:

- Start:
  - `BDB1|S|<totalChunks>|<crc32>|<rawSize>|<schemaVersion>`
- Chunk lines:
  - `BDB1|C|<index>|<payload>`
- End:
  - `BDB1|E`

Notes:
- `BDB1` = protocol marker
- `crc32` computed on **compressed binary** (or decompressed; pick one, document it; recommend compressed)
- `rawSize` = uncompressed size for sanity checking
- `schemaVersion` = payload schema version

### 2.4 Chunk sizing
- Use fixed chunk size for payload substring.
- Start with: **16,384 chars** payload per chunk (tune later).
- Ensure each full line length stays stable and manageable.

---

## 3) Export Implementation Steps
### 3.1 Build export payload
- Gather all books from DB into export structure (compact).
- Normalize each book’s text consistently.
- Ensure `contentHash` is present and correct for every entry.

### 3.2 Serialize
- Serialize to a compact JSON string OR custom delimiter format.
  - If JSON:
    - Use minimal keys and arrays of tuples.
    - Avoid pretty printing.

### 3.3 Compress + Encode
- `compressed = LibDeflate:CompressDeflate(serialized)`
- `encoded = LibDeflate:EncodeForPrint(compressed)`

### 3.4 Integrity
- `crc32 = CRC32(compressed)` (implement CRC32 or use library if available)
- `rawSize = #serialized`

### 3.5 Chunk + Emit text
- Split `encoded` into N chunks of `CHUNK_SIZE`.
- Output lines:
  - Header line
  - `BDB1|C|1|...`
  - ...
  - Footer line

### 3.6 Export UI behavior
- Do **not** update/format export EditBox on every frame.
- Provide:
  - “Generate Export” button -> computes text once -> fills textbox
  - “Copy instructions” label: “Ctrl+A, Ctrl+C”
- For very large exports:
  - Offer “Export as chunked lines” (default)
  - Optionally provide “Export as single blob” for small sizes only

---

## 4) Import Implementation Steps (Fast + Non-blocking UI)
### 4.1 Import UI modes
Implement BOTH:
- **Single paste box** (multiline): user pastes entire pastebin content.
- **Incremental add-chunk** (optional, safer for huge payloads):
  - small input box + “Add” button
  - list of collected chunks + progress

### 4.2 Critical performance rule
- Do not parse/decode/compress in `OnTextChanged`.
- Only run heavy work when user clicks **Import**.

### 4.3 Parse lines
On Import click:
- Split by newline
- Trim empty lines
- Validate:
  - Header starts with `BDB1|S|`
  - Footer exists `BDB1|E`
  - Collect chunk lines `BDB1|C|...`

### 4.4 Reassemble
- Read `totalChunks` from header.
- Create `chunks[index] = payload`.
- Validate indexes range 1..N.
- Ensure all chunks present; if missing:
  - Show missing list: `Missing chunks: 3, 7, 12`
  - Abort import without modifying DB.

- `encoded = table.concat(chunks, "", 1, N)`

### 4.5 Decode + Decompress + Verify
- `compressed = LibDeflate:DecodeForPrint(encoded)` (handle nil/error)
- Verify `CRC32(compressed) == crc32` else show “Corrupt / incomplete data”
- `serialized = LibDeflate:DecompressDeflate(compressed)` (handle errors)
- Verify `#serialized == rawSize` (optional sanity check)

### 4.6 Deserialize
- Deserialize payload into export structure.
- Validate `schemaVersion` compatibility.

### 4.7 Merge
- For each book tuple:
  - Recompute contentHash from payload (optional but recommended for integrity)
  - Merge into local DB via dedup rules.
- Provide summary:
  - “Imported: X new books, Y merged, Z skipped, Errors: N”
- Save DB.

### 4.8 UI safety
- Wrap import logic in protected call if necessary (`pcall`) to prevent UI break.
- If import is large, process in batches using `C_Timer.After(0, ...)`:
  - e.g., merge 50 books per tick, update progress bar.

---

## 5) Backward Compatibility + Versioning
### 5.1 Protocol marker increments
- `BDB1` is protocol v1.
- If format changes, bump to `BDB2`.

### 5.2 Payload schema version
- `schemaVersion` in header
- Keep deserializers for older schema versions if needed.

---

## 6) Testing Checklist
### 6.1 Correctness tests
- Export -> Import roundtrip equals original DB (including metadata merge behavior).
- Corrupt one chunk -> CRC fails -> import aborts safely.
- Missing chunk -> import reports missing indexes.

### 6.2 Performance tests
- Import a payload with:
  - 100 books
  - 1,000 books
  - 3,000 books
- Confirm:
  - No UI freeze > ~0.5s on button click (batching used if needed)
  - Paste into UI is responsive (no parsing on OnTextChanged)

### 6.3 UX tests
- Pastebin content with extra whitespace lines still imports.
- Users can paste partial content; error messages are actionable.

---

## 7) Implementation Deliverables (What to build)
- `export.lua`
  - `BuildExportPayload()`
  - `SerializePayload(payload)`
  - `CompressEncode(serialized)`
  - `Chunkify(encoded)`
  - `BuildExportText(header, chunks, footer)`
- `import.lua`
  - `ParseImportText(text) -> header, chunks`
  - `Reassemble(chunks, totalChunks)`
  - `DecodeDecompressVerify(...)`
  - `DeserializePayload(serialized)`
  - `MergePayloadIntoDB(payload)`
- `crc32.lua` (if not available)
- UI changes:
  - Export tab: “Generate Export” button + textbox
  - Import tab: textbox + “Import” button + progress + summary
  - (Optional) incremental chunk add mode

---

## 8) Acceptance Criteria
- Export of 12 books remains small and imports instantly.
- Large libraries:
  - Export produces chunked pastebin-friendly text.
  - Import can handle thousands of books with batching without freezing UI.
- Integrity:
  - CRC catches corruption.
  - Import never partially mutates DB on failure (all-or-nothing apply).
```

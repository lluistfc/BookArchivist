---@diagnostic disable: undefined-global
-- BookArchivist_BookId.lua
-- Helpers for stable BookArchivist book IDs (v2).

BookArchivist = BookArchivist or {}

-- Bit library handling for fnv1a32 hash function:
-- In WoW: bit or bit32 is provided by the game client
-- In tests: We auto-load our own stub to avoid external dependencies
--
-- Why not require Mechanic to provide this?
-- 1. Tests become portable - work on any machine with Lua 5.1
-- 2. No need to modify Mechanic's generated files after updates
-- 3. Self-contained - addon brings everything it needs for testing
if not (bit or bit32) then
  -- Try to load test stub for sandbox/test environments
  pcall(function()
    dofile("tests/stubs/bit_library.lua")
  end)
end

local BookId = BookArchivist.BookId or {}
BookArchivist.BookId = BookId

local function trim(s)
  if not s then return "" end
  s = tostring(s)
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeWhitespace(s)
  -- Collapse all whitespace (spaces, tabs, newlines) into single spaces.
  return (s:gsub("%s+", " "))
end

local function stripMarkup(s)
  -- Strip WoW color codes and simple texture tags.
  s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  s = s:gsub("|T.-|t", "")
  return s
end

local function normalizeText(text)
  text = trim(text)
  text = stripMarkup(text)
  text = normalizeWhitespace(text)
  text = text:lower()
  return text
end

-- FNV-1a 32-bit hash, deterministic and fast in Lua.
local function fnv1a32(str)
  local hash = 2166136261
  for i = 1, #str do
    hash = bit.bxor(hash, str:byte(i))
    hash = (hash * 16777619) % 2^32
  end
  return string.format("%08x", hash)
end

---Normalize arbitrary text for ID generation.
---@param text any
---@return string
function BookId.NormalizeText(text)
  return normalizeText(text)
end

local function extractFirstPageText(book)
  local pages = type(book) == "table" and book.pages or nil
  if type(pages) ~= "table" then
    return ""
  end
  local firstIndex
  for pageNum, _ in pairs(pages) do
    if type(pageNum) == "number" then
      if not firstIndex or pageNum < firstIndex then
        firstIndex = pageNum
      end
    end
  end
  if not firstIndex then
    return ""
  end
  local raw = pages[firstIndex] or ""
  return tostring(raw or "")
end

---Compute a stable v2 book ID for a given entry.
---Uses source.objectID (if present), normalized title, and normalized
---first-page text (truncated to 512 chars after normalization).
---@param book table
---@return string|nil
function BookId.MakeBookIdV2(book)
  if type(book) ~= "table" then
    return nil
  end
  local source = book.source or {}
  local objectID = source.objectID
  if objectID ~= nil then
    objectID = tonumber(objectID) or tostring(objectID)
  end

  local titleNorm = normalizeText(book.title or "")
  local firstPageRaw = extractFirstPageText(book)
  local firstNorm = normalizeText(firstPageRaw):sub(1, 512)

  local parts = {}
  parts[#parts + 1] = objectID and tostring(objectID) or "0"
  parts[#parts + 1] = titleNorm
  parts[#parts + 1] = firstNorm

  local payload = table.concat(parts, "|")
  local hash = fnv1a32(payload)
  return "b2:" .. hash
end

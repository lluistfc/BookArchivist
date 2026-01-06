# 03 — New file: BookArchivist_ImportWorker.lua (worker skeleton)

## Goal
Add a cooperative worker that imports payload without freezing UI.

## File to create
- `BookArchivist_ImportWorker.lua`

## Loading order requirement
This file must load after:
- `BookArchivist_Base64.lua`
- `BookArchivist_Serialize.lua`
- `BookArchivist_Core.lua`
and before:
- `BookArchivist_UI_Options.lua` (so Options can reference `BookArchivist.ImportWorker`)

See `07-toc-and-loading-order.md`.

## Public API
- `BookArchivist.ImportWorker:New(parentFrame)` -> worker instance
- `worker:Start(encodedString, callbacks)`
- `worker:Cancel()`

Callbacks:
- `onProgress(label, pct01)` (optional)
- `onDone(summary)` (optional)
- `onError(errMsg)` (optional)

## State machine phases
- `idle`
- `decode`
- `deserialize`
- `prepare`
- `merge`
- `finalize_searchtext`
- `finalize_index`
- `finalize_recent`
- `done`

## Budgeting
- Each OnUpdate, run while `debugprofilestop()` delta < `budgetMs` (e.g. 8ms).
- Never do unbounded loops inside a phase without a per-slice cap.

## Skeleton (copy/paste starter)
```lua
BookArchivist = BookArchivist or {}
BookArchivist.ImportWorker = BookArchivist.ImportWorker or {}
local ImportWorker = BookArchivist.ImportWorker
ImportWorker.__index = ImportWorker

local function nowMs() return debugprofilestop() end

function ImportWorker:New(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:Hide()
  local o = setmetatable({
    frame = f,
    phase = "idle",
    budgetMs = 8,

    rawPayload = nil,
    decoded = nil,
    payload = nil,

    incomingBooks = nil,
    incomingIds = nil,
    incomingIdx = 1,

    needsSearchText = nil,  -- map[bookId]=true
    needsIndex = nil,       -- map[bookId]=true
    needsIds = nil,         -- array
    needsIdx = 1,

    orderSet = nil,

    stats = { newCount = 0, mergedCount = 0, conflictCount = 0 },

    onProgress = nil,
    onDone = nil,
    onError = nil,
  }, ImportWorker)

  f:SetScript("OnUpdate", function(_, elapsed) o:_Step(elapsed) end)
  return o
end

function ImportWorker:Start(rawPayload, cb)
  if self.phase ~= "idle" then return false end
  self.rawPayload = rawPayload
  self.decoded = nil
  self.payload = nil
  self.incomingBooks = nil
  self.incomingIds = nil
  self.incomingIdx = 1
  self.needsSearchText = {}
  self.needsIndex = {}
  self.needsIds = nil
  self.needsIdx = 1
  self.orderSet = nil
  self.stats = { newCount = 0, mergedCount = 0, conflictCount = 0 }

  self.onProgress = cb and cb.onProgress or nil
  self.onDone = cb and cb.onDone or nil
  self.onError = cb and cb.onError or nil

  self.phase = "decode"
  self.frame:Show()
  return true
end

function ImportWorker:Cancel()
  self.phase = "idle"
  self.frame:Hide()
end

function ImportWorker:_Fail(msg)
  self:Cancel()
  if self.onError then self.onError(msg) end
end

function ImportWorker:_Progress(label, pct)
  if self.onProgress then self.onProgress(label, pct) end
end

local function MakeSortedKeys(map)
  local out = {}
  for k in pairs(map) do out[#out+1] = k end
  table.sort(out)
  return out
end

function ImportWorker:_Step(_elapsed)
  local start = nowMs()
  while (nowMs() - start) < self.budgetMs do
    if self.phase == "idle" then self.frame:Hide(); return end
    -- phase handlers implemented in later plan files
    return
  end
end
```

## Acceptance checks
- File loads without errors (no missing globals).
- Start() returns false if already running.
- Cancel() stops processing and hides the frame.

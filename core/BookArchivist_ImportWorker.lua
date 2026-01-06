---@diagnostic disable: undefined-global
-- BookArchivist_ImportWorker.lua
-- Cooperative worker to import libraries without freezing the UI.

BookArchivist = BookArchivist or {}
BookArchivist.ImportWorker = BookArchivist.ImportWorker or {}
local ImportWorker = BookArchivist.ImportWorker
ImportWorker.__index = ImportWorker

local createFrame = BookArchivist.__createFrame or (type(_G) == "table" and rawget(_G, "CreateFrame")) or function()
  local dummy = {}
  function dummy:SetScript() end
  function dummy:Hide() end
  function dummy:Show() end
  return dummy
end

local function nowMs()
  if type(debugprofilestop) == "function" then
    return debugprofilestop()
  end
  return 0
end

local function MakeSortedKeys(map)
  local out = {}
  if type(map) ~= "table" then
    return out
  end
  for k in pairs(map) do
    out[#out+1] = k
  end
  table.sort(out)
  return out
end

local function CloneTable(src)
  if type(src) ~= "table" then
    return src
  end
  local dst = {}
  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = CloneTable(v)
    else
      dst[k] = v
    end
  end
  return dst
end

local function markConflict(entry, stats)
  if not entry then return end
  entry.legacy = entry.legacy or {}
  if not entry.legacy.importConflict then
    entry.legacy.importConflict = true
    if stats then
      stats.conflictCount = (stats.conflictCount or 0) + 1
    end
  else
    entry.legacy.importConflict = true
  end
end

function ImportWorker:New(parent)
  local frame = createFrame("Frame", nil, parent)
  frame:Hide()

  local o = setmetatable({
    frame = frame,
    phase = "idle",
    budgetMs = 8,

    rawPayload = nil,
    decoded = nil,
    payload = nil,

    incomingBooks = nil,
    incomingIds = nil,
    incomingIdx = 1,

    needsSearchText = nil, -- map[bookId]=true
    needsIndex = nil,      -- map[bookId]=true
    needsIds = nil,        -- array of bookIds
    needsIdx = 1,

    orderSet = nil,

    stats = { newCount = 0, mergedCount = 0, conflictCount = 0 },

    onProgress = nil,
    onDone = nil,
    onError = nil,
  }, ImportWorker)

  frame:SetScript("OnUpdate", function(_, elapsed)
    o:_Step(elapsed)
  end)

  return o
end

function ImportWorker:Start(rawPayload, cb)
  if self.phase ~= "idle" then
    return false
  end

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
  if self.frame and self.frame.Hide then
    self.frame:Hide()
  end
end

function ImportWorker:_Fail(msg)
  self:Cancel()
  if self.onError then
    self.onError(msg)
  end
end

function ImportWorker:_Progress(label, pct)
  if self.onProgress then
    self.onProgress(label, pct)
  end
end

function ImportWorker:_MergeOne(existing, incoming, bookId)
  if not existing or type(existing) ~= "table" then
    return false
  end
  if not incoming or type(incoming) ~= "table" then
    return false
  end

  if type(incoming.seenCount) == "number" then
    existing.seenCount = (existing.seenCount or 0) + incoming.seenCount
  end
  if type(incoming.firstSeenAt) == "number" then
    if not existing.firstSeenAt or incoming.firstSeenAt < existing.firstSeenAt then
      existing.firstSeenAt = incoming.firstSeenAt
    end
  end
  if type(incoming.lastSeenAt) == "number" then
    if not existing.lastSeenAt or incoming.lastSeenAt > existing.lastSeenAt then
      existing.lastSeenAt = incoming.lastSeenAt
    end
  end
  if type(incoming.lastReadAt) == "number" then
    if not existing.lastReadAt or incoming.lastReadAt > existing.lastReadAt then
      existing.lastReadAt = incoming.lastReadAt
    end
  end
  if incoming.isFavorite then
    existing.isFavorite = true
  end

  if incoming.title and incoming.title ~= "" then
    if not existing.title or existing.title == "" then
      existing.title = incoming.title
    elseif existing.title ~= incoming.title then
      markConflict(existing, self.stats)
    end
  end

  if type(incoming.pages) == "table" then
    existing.pages = existing.pages or {}
    for pageNum, text in pairs(incoming.pages) do
      if existing.pages[pageNum] == nil then
        existing.pages[pageNum] = text
      elseif text and text ~= "" and existing.pages[pageNum] ~= text then
        markConflict(existing, self.stats)
      end
    end
  end

  return true
end

function ImportWorker:_Step(_elapsed)
  local start = nowMs()
  local budget = self.budgetMs or 8

  while (nowMs() - start) < budget do
    if self.phase == "idle" then
      if self.frame and self.frame.Hide then
        self.frame:Hide()
      end
      return
    elseif self.phase == "decode" then
      local Base64 = BookArchivist and BookArchivist.Base64
      if not (Base64 and Base64.Decode) then
        return self:_Fail("Decode unavailable")
      end

      local decoded, err = Base64.Decode(self.rawPayload or "")
      if not decoded then
        return self:_Fail("Decode failed: " .. tostring(err))
      end

      self.decoded = decoded
      self.phase = "deserialize"
      self:_Progress("Decoded", 0)
      -- continue loop with new phase
    elseif self.phase == "deserialize" then
      local Serialize = BookArchivist and BookArchivist.Serialize
      if not (Serialize and Serialize.DeserializeTable) then
        return self:_Fail("Deserialize unavailable")
      end

      local payload, err = Serialize.DeserializeTable(self.decoded or "")
      if not payload then
        return self:_Fail("Deserialize failed: " .. tostring(err))
      end
      if type(payload) ~= "table" then
        return self:_Fail("Invalid payload type")
      end
      if payload.schemaVersion ~= 1 then
        return self:_Fail("Unsupported schemaVersion: " .. tostring(payload.schemaVersion))
      end
      if type(payload.booksById) ~= "table" then
        return self:_Fail("Payload missing booksById")
      end

      self.payload = payload
      self.incomingBooks = payload.booksById
      self.incomingIds = MakeSortedKeys(self.incomingBooks)
      self.incomingIdx = 1
      self.phase = "prepare"
      self:_Progress("Parsed", 0)
    elseif self.phase == "prepare" then
      if not (BookArchivist and BookArchivist.Core and BookArchivist.Core.EnsureDB) then
        return self:_Fail("Core unavailable")
      end

      BookArchivist.Core:EnsureDB()
      local db = BookArchivistDB
      db.booksById = db.booksById or {}
      db.order = db.order or {}

      self.orderSet = {}
      for _, id in ipairs(db.order) do
        self.orderSet[id] = true
      end

      self.phase = "merge"
    elseif self.phase == "merge" then
      local db = BookArchivistDB
      if not db or type(db.booksById) ~= "table" or type(self.incomingIds) ~= "table" then
        return self:_Fail("Merge state missing")
      end

      local total = #self.incomingIds
      local perSlice = 25
      local processed = 0

      while self.incomingIdx <= total and processed < perSlice do
        local bookId = self.incomingIds[self.incomingIdx]
        local inE = self.incomingBooks and self.incomingBooks[bookId]

        if type(bookId) == "string" and type(inE) == "table" then
          local existing = db.booksById[bookId]
          if not existing then
            db.booksById[bookId] = CloneTable(inE)
            self.stats.newCount = self.stats.newCount + 1
          else
            if self:_MergeOne(existing, inE, bookId) then
              self.stats.mergedCount = self.stats.mergedCount + 1
            end
          end

          if not self.orderSet[bookId] then
            db.order[#db.order+1] = bookId
            self.orderSet[bookId] = true
          end

          self.needsSearchText[bookId] = true
          self.needsIndex[bookId] = true
        end

        self.incomingIdx = self.incomingIdx + 1
        processed = processed + 1
      end

      self:_Progress("Merging", self.incomingIdx / math.max(1, total))

      if self.incomingIdx > total then
        self.needsIds = MakeSortedKeys(self.needsSearchText or {})
        self.needsIdx = 1
        self.phase = "finalize_searchtext"
      end

      return
    elseif self.phase == "finalize_searchtext" then
      local db = BookArchivistDB
      if not db or type(db.booksById) ~= "table" then
        return self:_Fail("DB unavailable for searchText")
      end

      local ids = self.needsIds or {}
      local total = #ids
      local perSlice = 15
      local processed = 0

      while self.needsIdx <= total and processed < perSlice do
        local bookId = ids[self.needsIdx]
        local e = db.booksById[bookId]
        if e then
          e.isFavorite = (e.isFavorite == true)
          e.lastReadAt = e.lastReadAt or 0
          if BookArchivist and BookArchivist.Core and BookArchivist.Core.BuildSearchText then
            e.searchText = BookArchivist.Core:BuildSearchText(e.title, e.pages)
          end
        end
        self.needsIdx = self.needsIdx + 1
        processed = processed + 1
      end

      self:_Progress("Building search", self.needsIdx / math.max(1, total))

      if self.needsIdx > total then
        self.needsIdx = 1
        self.phase = "finalize_index"
      end

      return
    elseif self.phase == "finalize_index" then
      local db = BookArchivistDB
      if not db or type(db.booksById) ~= "table" then
        return self:_Fail("DB unavailable for index")
      end

      local ids = self.needsIds or {}
      local total = #ids
      local perSlice = 40
      local processed = 0

      while self.needsIdx <= total and processed < perSlice do
        local bookId = ids[self.needsIdx]
        local e = db.booksById[bookId]
        if e and e.title and e.title ~= "" then
          if BookArchivist and BookArchivist.Core and BookArchivist.Core.IndexTitleForBook then
            BookArchivist.Core:IndexTitleForBook(e.title, bookId)
          end
        end
        self.needsIdx = self.needsIdx + 1
        processed = processed + 1
      end

      self:_Progress("Indexing titles", self.needsIdx / math.max(1, total))

      if self.needsIdx > total then
        self.phase = "finalize_recent"
      end

      return
    elseif self.phase == "finalize_recent" then
      pcall(function()
        if BookArchivist and BookArchivist.Recent and BookArchivist.Recent.GetList then
          BookArchivist.Recent:GetList()
        end
      end)

      self.phase = "done"
    elseif self.phase == "done" then
      local summary = string.format("Imported: %d new, %d merged", self.stats.newCount or 0, self.stats.mergedCount or 0)
      self:Cancel()
      if self.onDone then
        self.onDone(summary)
      end
      return
    else
      return
    end
  end
end

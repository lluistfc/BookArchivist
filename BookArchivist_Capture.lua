-- BookArchivist_Capture.lua
-- Converts ItemText events into persisted entries via the core module.

BookArchivist = BookArchivist or {}

local Core = BookArchivist.Core
local Location = BookArchivist.Location
local Capture = {}
BookArchivist.Capture = Capture

---@class BookArchivistCaptureSession
---@field title string
---@field creator string
---@field author string
---@field material string
---@field pages table<number, string>
---@field source table
---@field firstPageSeen number|nil
---@field startedAt number
---@field itemID number|nil
---@field sourceKind string|nil
---@field location table|nil
local session ---@type BookArchivistCaptureSession|nil

local function getGlobal(name)
  if type(_G) ~= "table" then return nil end
  return rawget(_G, name)
end

local function now()
  if Core and Core.Now then
    return Core:Now()
  end
  local osTime = type(os) == "table" and os.time
  return osTime and osTime() or 0
end

local function trim(s)
  if not s then return "" end
  s = tostring(s)
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end

local function currentSourceInfo()
  local src = { kind = "itemtext" }
  local frame = getGlobal("ItemTextFrame")
  if frame then
    if frame.itemID then
      src.itemID = frame.itemID
    end
    if type(frame.page) == "number" then
      src.page = frame.page
    end
  end
  return src
end

local function resolvePageNumber()
  local getPage = getGlobal("ItemTextGetPage")
  if getPage then
    local page = getPage()
    if type(page) == "number" and page >= 1 then
      return page
    end
  end
  return 1
end

local function gossipSpeakerInfo()
  local UnitGUID = getGlobal("UnitGUID")
  local UnitExists = getGlobal("UnitExists")
  local guid = UnitGUID and UnitGUID("npc") or nil
  local exists = UnitExists and UnitExists("npc") or false
  local isGameObject = guid and guid:match("^GameObject") ~= nil
  if isGameObject then
    return true, guid
  end
  if exists then
    return false, guid
  end
  return true, guid
end

local function gossipHasChoices(api)
  if not api then return false end
  local hasOptions = false
  if api.GetOptions then
    local options = api.GetOptions()
    hasOptions = type(options) == "table" and #options > 0
  end
  if hasOptions then return true end

  local active = api.GetActiveQuests and api.GetActiveQuests()
  if type(active) == "table" and #active > 0 then
    return true
  end

  local available = api.GetAvailableQuests and api.GetAvailableQuests()
  if type(available) == "table" and #available > 0 then
    return true
  end

  return false
end

local function ensureSessionLocation(target)
  if not target or target.location then
    return
  end

  if target.itemID and Location and Location.GetLootLocation then
    target.location = Location:GetLootLocation(target.itemID)
  end

  if (not target.location) and Location and Location.BuildWorldLocation then
    local loc = Location:BuildWorldLocation()
    if loc then
      if target.itemID then
        loc.context = "loot"
        loc.isFallback = true
      end
      target.location = loc
    end
  end
end

function Capture:OnBegin()
  local frame = getGlobal("ItemTextFrame")
  local itemID = frame and frame.itemID or nil
    if type(itemID) == "string" then
      itemID = tonumber(itemID)
    end
  session = {
    title = "",
    creator = "",
    author = "",
    material = "",
    pages = {},
    source = currentSourceInfo(),
    firstPageSeen = nil,
    startedAt = now(),
    itemID = itemID,
    sourceKind = itemID and "inventory" or "world",
    location = nil,
  }

  if not itemID then
    ensureSessionLocation(session)
  end
end

function Capture:OnReady()
  if not session then
    self:OnBegin()
  end

  local activeSession = session
  if not activeSession then
    return
  end

  local pageNum = resolvePageNumber()
  local ItemTextGetTitle = getGlobal("ItemTextGetTitle")
  local ItemTextGetCreator = getGlobal("ItemTextGetCreator")
  local ItemTextGetMaterial = getGlobal("ItemTextGetMaterial")
  local ItemTextGetText = getGlobal("ItemTextGetText")

  local title = ItemTextGetTitle and ItemTextGetTitle() or ""
  local creator = ItemTextGetCreator and ItemTextGetCreator() or ""
  local material = ItemTextGetMaterial and ItemTextGetMaterial() or ""
  local text = ItemTextGetText and ItemTextGetText() or ""

  activeSession.title = trim(title)
  activeSession.creator = trim(creator)
  activeSession.material = trim(material)
  activeSession.author = activeSession.author or ""

  if not activeSession.firstPageSeen then
    activeSession.firstPageSeen = pageNum
  end

  activeSession.pages = activeSession.pages or {}
  activeSession.pages[pageNum] = trim(text)

  ensureSessionLocation(activeSession)
end

function Capture:OnClosed()
  if not session then return end
  ensureSessionLocation(session)
  if Core and Core.PersistSession then
    Core:PersistSession(session)
  end
  session = nil
end

function Capture:OnGossipShow()
  local GossipAPI = getGlobal("C_GossipInfo")
  if not GossipAPI or not GossipAPI.GetText then
    return
  end

  local text = GossipAPI.GetText()
  if not text or trim(text) == "" then
    return
  end

  local isObject, guid = gossipSpeakerInfo()
  if not isObject then
    return
  end

  if gossipHasChoices(GossipAPI) then
    return
  end

  local titleWidget = getGlobal("GossipFrameNpcNameText")
  local rawTitle = titleWidget and titleWidget:GetText() or ""
  local title = trim(rawTitle)
  if title == "" and Location and Location.GetGuidName then
    title = Location:GetGuidName(guid) or ""
  end
  if title == "" then
    title = "Unmarked Relic"
  end
  if title == "" then
    title = "Unmarked Inscription"
  end

  local payload = {
    title = title,
  creator = title,
    author = "",
    material = "Carved Tablet",
    pages = {
      [1] = trim(text),
    },
    source = {
      kind = "gossip",
      guid = guid,
      title = title,
    },
    firstPageSeen = 1,
    startedAt = now(),
    location = Location and Location:BuildWorldLocation() or nil,
  }

  if Core and Core.PersistSession then
    Core:PersistSession(payload)
  end
end

function Capture:OnGossipClosed()
  -- Reserved for future state tracking if needed
end

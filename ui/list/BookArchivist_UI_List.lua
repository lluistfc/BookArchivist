---@diagnostic disable: undefined-global, undefined-field
BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local ListUI = {}
BookArchivist.UI.List = ListUI

local DEFAULT_LIST_MODES = {
  BOOKS = "books",
  LOCATIONS = "locations",
}

local state = ListUI.__state or {}
ListUI.__state = state

state.ctx = state.ctx or {}
state.frames = state.frames or {}
state.location = state.location or {}
state.location.path = state.location.path or {}
state.location.rows = state.location.rows or {}
state.location.root = state.location.root
state.location.activeNode = state.location.activeNode
state.buttonPool = state.buttonPool or { free = {}, active = {} }
state.constants = state.constants or {}
state.constants.rowHeight = state.constants.rowHeight or DEFAULT_ROW_HEIGHT
state.listModes = state.listModes or DEFAULT_LIST_MODES
state.filters = state.filters or {}
state.widgets = state.widgets or {}
state.search = state.search or { pendingToken = 0 }
state.pagination = state.pagination or { page = 1, pageSize = 25 }
state.filterButtons = state.filterButtons or {}
state.locationMenuFrame = state.locationMenuFrame or nil
state.selectedListTab = state.selectedListTab or 1

local function fallbackDebugPrint(...)
  BookArchivist:DebugPrint(...)
end
local function applyContext(ctx, overrides)
  if not overrides then
    return ctx or {}
  end
  ctx = ctx or {}
  for key, value in pairs(overrides) do
    ctx[key] = value
  end
  return ctx
end

function ListUI:Init(context)
  local ctx = context or {}
  ctx.debugPrint = ctx.debugPrint or fallbackDebugPrint
  self.__state.ctx = ctx
  if context and context.listModes then
    self.__state.listModes = context.listModes
  elseif not self.__state.listModes then
    self.__state.listModes = DEFAULT_LIST_MODES
  end
end

function ListUI:SetCallbacks(callbacks)
  local ctx = self:GetContext()
  local merged = applyContext(ctx, callbacks)
  merged.debugPrint = merged.debugPrint or fallbackDebugPrint
  self.__state.ctx = merged
end

function ListUI:GetContext()
  return self.__state.ctx or {}
end

function ListUI:GetTimeFormatter()
  local ctx = self:GetContext()
  return (ctx and ctx.fmtTime) or function(ts)
    if not ts then return "" end
    return date("%Y-%m-%d %H:%M", ts)
  end
end

function ListUI:GetLocationFormatter()
  local ctx = self:GetContext()
  return (ctx and ctx.formatLocationLine) or function()
    return nil
  end
end

function ListUI:GetListModes()
  return self.__state.listModes or DEFAULT_LIST_MODES
end

function ListUI:TabIdToMode(tabId)
  local modes = self:GetListModes()
  if tabId == 2 then
    return modes.LOCATIONS
  end
  return modes.BOOKS
end

function ListUI:ModeToTabId(mode)
  local modes = self:GetListModes()
  if mode == modes.LOCATIONS then
    return 2
  end
  return 1
end


function ListUI:GetLocationState()
  return self.__state.location
end

function ListUI:GetButtonPool()
  return self.__state.buttonPool
end

function ListUI:GetFrames()
  return self.__state.frames
end

function ListUI:SetUIFrame(frame)
  self.__state.uiFrame = frame
end

function ListUI:GetUIFrame()
  local ctx = self:GetContext()
  if ctx and ctx.getUIFrame then
    local ok, result = pcall(ctx.getUIFrame, ctx)
    if ok and result then
      return result
    end
  end
  return self.__state.uiFrame
end

function ListUI:SetFrame(name, frame)
  if not name then return end
  self.__state.frames[name] = frame
  if frame then
    self:RememberWidget(name, frame)
    local ui = self:GetUIFrame()
    if ui then
      ui[name] = frame
    end
  end
  return frame
end

function ListUI:GetFrame(name)
  return self.__state.frames[name]
end

function ListUI:SetDataProvider(dataProvider)
  self.__state.dataProvider = dataProvider
end

function ListUI:GetDataProvider()
  return self.__state.dataProvider
end

function ListUI:SetScrollView(scrollView)
  self.__state.scrollView = scrollView
end

function ListUI:GetScrollView()
  return self.__state.scrollView
end

function ListUI:RememberWidget(name, widget)
  local ctx = self:GetContext()
  if ctx and ctx.rememberWidget then
    return ctx.rememberWidget(name, widget)
  end
  return widget
end

function ListUI:SafeCreateFrame(frameType, name, parent, ...)
  local ctx = self:GetContext()
  if ctx and ctx.safeCreateFrame then
    return ctx.safeCreateFrame(frameType, name, parent, ...)
  end
  if CreateFrame then
    return CreateFrame(frameType, name, parent, ...)
  end
end

function ListUI:GetAddon()
  local ctx = self:GetContext()
  if ctx and ctx.getAddon then
    return ctx.getAddon()
  end
end

function ListUI:GetListMode()
  local ctx = self:GetContext()
  if ctx and ctx.getListMode then
    return ctx.getListMode()
  end
  return self:GetListModes().BOOKS
end

function ListUI:SetListMode(mode)
  if mode then
    self.__state.selectedListTab = self:ModeToTabId(mode)
  end
  local ctx = self:GetContext()
  if ctx and ctx.setListMode then
    ctx.setListMode(mode)
  end
end

function ListUI:GetSelectedListTab()
  local tab = tonumber(self.__state.selectedListTab) or 1
  if tab == 2 then
    return 2
  end
  return 1
end

function ListUI:SetSelectedListTab(tabId)
  self.__state.selectedListTab = (tabId == 2) and 2 or 1
end

function ListUI:SyncSelectedTabFromMode()
  local mode = self:GetListMode()
  local tabId = self:ModeToTabId(mode)
  self:SetSelectedListTab(tabId)
  return tabId
end

function ListUI:GetFilteredKeys()
  local ctx = self:GetContext()
  if ctx and ctx.getFilteredKeys then
    return ctx.getFilteredKeys()
  end
  return {}
end

function ListUI:GetWidget(name)
  local ctx = self:GetContext()
  if ctx and ctx.getWidget then
    return ctx.getWidget(name)
  end
end

function ListUI:GetInfoText()
  return self:GetFrame("infoText")
end

function ListUI:DebugPrint(...)
  local ctx = self:GetContext()
  local logger = (ctx and ctx.debugPrint) or fallbackDebugPrint
  logger(...)
end

function ListUI:LogError(message)
  local ctx = self:GetContext()
  if ctx and ctx.logError then
    ctx.logError(message)
  elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(tostring(message))
  end
end

return ListUI

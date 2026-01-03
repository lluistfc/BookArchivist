---@diagnostic disable: undefined-global, undefined-field
BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local ListUI = {}
BookArchivist.UI.List = ListUI

local DEFAULT_LIST_MODES = {
  BOOKS = "books",
  LOCATIONS = "locations",
}

local DEFAULT_ROW_HEIGHT = 44

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
  self.__state.ctx = context or {}
  if context and context.listModes then
    self.__state.listModes = context.listModes
  elseif not self.__state.listModes then
    self.__state.listModes = DEFAULT_LIST_MODES
  end
end

function ListUI:SetCallbacks(callbacks)
  local ctx = self:GetContext()
  self.__state.ctx = applyContext(ctx, callbacks)
end

function ListUI:GetContext()
  return self.__state.ctx or {}
end

function ListUI:GetListModes()
  return self.__state.listModes or DEFAULT_LIST_MODES
end

function ListUI:GetRowHeight()
  return self.__state.constants.rowHeight or DEFAULT_ROW_HEIGHT
end

function ListUI:SetRowHeight(height)
  if type(height) == "number" and height > 0 then
    self.__state.constants.rowHeight = height
  end
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
  local ctx = self:GetContext()
  if ctx and ctx.setListMode then
    ctx.setListMode(mode)
  end
end

function ListUI:GetFilteredKeys()
  local ctx = self:GetContext()
  if ctx and ctx.getFilteredKeys then
    return ctx.getFilteredKeys()
  end
  return {}
end

function ListUI:GetSelectedKey()
  local ctx = self:GetContext()
  if ctx and ctx.getSelectedKey then
    return ctx.getSelectedKey()
  end
end

function ListUI:SetSelectedKey(key)
  local ctx = self:GetContext()
  if ctx and ctx.setSelectedKey then
    ctx.setSelectedKey(key)
  end
end

function ListUI:DisableDeleteButton()
  local ctx = self:GetContext()
  if ctx and ctx.disableDeleteButton then
    ctx.disableDeleteButton()
  end
end

function ListUI:NotifySelectionChanged()
  local ctx = self:GetContext()
  if ctx and ctx.onSelectionChanged then
    ctx.onSelectionChanged()
  end
end

function ListUI:GetWidget(name)
  local ctx = self:GetContext()
  if ctx and ctx.getWidget then
    return ctx.getWidget(name)
  end
end

function ListUI:GetSearchText()
  local box = self:GetFrame("searchBox") or self:GetWidget("searchBox")
  if not box or not box.GetText then
    return ""
  end
  return box:GetText() or ""
end

function ListUI:GetInfoText()
  return self:GetFrame("infoText")
end

function ListUI:DebugPrint(...)
  local ctx = self:GetContext()
  if ctx and ctx.debugPrint then
    ctx.debugPrint(...)
  end
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

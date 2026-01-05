---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
  return (L and L[key]) or key
end

local function normalizeLocationLabel(label)
  if not label or label == "" then
    return "Unknown Location"
  end
  return label
end

local function buildLocationTreeFromDB(db)
  local root = {
    name = "__ROOT__",
    depth = 0,
    children = {},
    childNames = {},
  }

  if not db or not (db.booksById or db.books) then
    return root
  end

  local order = db.order or {}
  local books
  if db.booksById and next(db.booksById) ~= nil then
    books = db.booksById
  else
    books = db.books or {}
  end
  for _, key in ipairs(order) do
	local entry = books[key]
    if entry then
      local chain = entry.location and entry.location.zoneChain
      if not chain or #chain == 0 then
        local fallback = entry.location and entry.location.zoneText
        if fallback and fallback ~= "" then
          chain = { fallback }
        else
          chain = { "Unknown Location" }
        end
      end

      local node = root
      for _, segment in ipairs(chain) do
        local name = normalizeLocationLabel(segment)
        node.children = node.children or {}
        node.childNames = node.childNames or {}
        if not node.children[name] then
          node.children[name] = {
            name = name,
            depth = (node.depth or 0) + 1,
            parent = node,
            children = {},
            childNames = {},
            books = {},
          }
          table.insert(node.childNames, name)
        end
        node = node.children[name]
      end

      node.books = node.books or {}
      table.insert(node.books, key)
    end
  end

  local function sortNode(node)
    if not node or not node.childNames or #node.childNames == 0 then
      return
    end
    table.sort(node.childNames, function(a, b)
      return a:lower() < b:lower()
    end)
    for _, childName in ipairs(node.childNames) do
      sortNode(node.children and node.children[childName])
    end
  end

  sortNode(root)
  local function markTotals(node)
    if not node then
      return 0
    end
    local total = node.books and #node.books or 0
    if node.childNames then
      for _, childName in ipairs(node.childNames) do
        local child = node.children and node.children[childName]
        total = total + markTotals(child)
      end
    end
    node.totalBooks = total
    return total
  end

  markTotals(root)
  return root
end

local function getLocationState(self)
  local state = self:GetLocationState()
  state.path = state.path or {}
  state.rows = state.rows or {}
  return state
end

local function ensureLocationPathValid(state)
  local root = state.root
  local path = state.path
  if not path then
    path = {}
    state.path = path
  end
  if not root then
    wipe(path)
    state.activeNode = nil
    return
  end

  local node = root
  for i = 1, #path do
    local segment = path[i]
    if node.children and node.children[segment] then
      node = node.children[segment]
    else
      for j = #path, i, -1 do
        table.remove(path, j)
      end
      break
    end
  end
  state.activeNode = node
end

local function rebuildLocationRows(state)
  local rows = {}
  local node = state.activeNode or state.root
  if not node then
    state.rows = rows
    return
  end

  local path = state.path or {}
  if #path > 0 then
    table.insert(rows, { kind = "back" })
  end

  local childNames = node.childNames or {}
  if childNames and #childNames > 0 then
    for _, childName in ipairs(childNames) do
      table.insert(rows, { kind = "location", name = childName, node = node.children and node.children[childName] })
    end
  else
    local books = node.books or {}
    for _, key in ipairs(books) do
      table.insert(rows, { kind = "book", key = key })
    end
  end

  state.rows = rows
end

function ListUI:GetLocationRows()
  local state = getLocationState(self)
  return state.rows or {}
end

function ListUI:GetLocationBreadcrumbText()
  local state = getLocationState(self)
  local path = state.path or {}
  if #path == 0 then
    return t("LOCATIONS_BREADCRUMB_ROOT")
  end
  return table.concat(path, " > ")
end

function ListUI:NavigateInto(segment)
  local state = getLocationState(self)
  segment = normalizeLocationLabel(segment)
  if segment == "" then return end
  state.path[#state.path + 1] = segment
  ensureLocationPathValid(state)
  rebuildLocationRows(state)
end

function ListUI:NavigateUp()
  local state = getLocationState(self)
  local path = state.path
  if not path or #path == 0 then return end
  table.remove(path)
  ensureLocationPathValid(state)
  rebuildLocationRows(state)
end

function ListUI:RebuildLocationTree()
  local addon = self:GetAddon()
  local state = getLocationState(self)
  if not addon then
    state.root = nil
    state.rows = {}
    state.activeNode = nil
    return
  end

  local db = addon:GetDB()
  state.root = buildLocationTreeFromDB(db)
  ensureLocationPathValid(state)
  rebuildLocationRows(state)
end

local function collectBooksRecursive(node, results)
  if not node then
    return
  end
  if node.books then
    for _, key in ipairs(node.books) do
      table.insert(results, key)
    end
  end
  if node.childNames then
    for _, childName in ipairs(node.childNames) do
      collectBooksRecursive(node.children and node.children[childName], results)
    end
  end
end

function ListUI:GetBooksForNode(node)
  local results = {}
  collectBooksRecursive(node, results)
  return results
end

function ListUI:HasBooksInNode(node)
  return #self:GetBooksForNode(node or {}) > 0
end

function ListUI:GetLocationMenuFrame()
  if not self.__state.locationMenuFrame and CreateFrame then
    self.__state.locationMenuFrame = CreateFrame("Frame", "BookArchivistLocationMenu", UIParent, "UIDropDownMenuTemplate")
  end
  return self.__state.locationMenuFrame
end

function ListUI:OpenRandomFromNode(node)
  local books = self:GetBooksForNode(node)
  if #books == 0 then
    return
  end
  local choice = books[math.random(#books)]
  if not choice then
    return
  end
  self:SetSelectedKey(choice)
  self:NotifySelectionChanged()
  self:UpdateList()
end

function ListUI:OpenMostRecentFromNode(node)
  local addon = self:GetAddon()
  local db = addon and addon:GetDB()
  if not db or not (db.booksById or db.books) then
    return
  end
  local books = (db.booksById or db.books) or {}
  local latestKey
  local latestTs = -1
  for _, key in ipairs(self:GetBooksForNode(node)) do
	local entry = books[key]
    local ts = entry and entry.lastSeenAt or 0
    if ts > latestTs then
      latestTs = ts
      latestKey = key
    end
  end
  if latestKey then
    self:SetSelectedKey(latestKey)
    self:NotifySelectionChanged()
    self:UpdateList()
  end
end

function ListUI:ShowLocationContextMenu(anchorButton, node)
  if not anchorButton or not node or not EasyMenu then
    return
  end
  local menuFrame = self:GetLocationMenuFrame()
  if not menuFrame then
    return
  end
  local hasBooks = self:HasBooksInNode(node)
  local menu = {
    { text = node.name or "Location", isTitle = true, notCheckable = true },
    { text = "Open random book", notCheckable = true, disabled = not hasBooks, func = function() self:OpenRandomFromNode(node) end },
    { text = "Open most recent", notCheckable = true, disabled = not hasBooks, func = function() self:OpenMostRecentFromNode(node) end },
  }
  EasyMenu(menu, menuFrame, anchorButton, 0, 0, "MENU")
end

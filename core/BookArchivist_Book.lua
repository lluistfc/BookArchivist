---@diagnostic disable: undefined-global
-- BookArchivist_Book.lua
-- Book Aggregate Root - Single point of mutation for book state
-- Enforces invariants: sourceType, read-only captured books, page ordering, searchText sync

local BA = BookArchivist

local Book = {}
BA.Book = Book

-- Source types
local SOURCE_CAPTURED = "CAPTURED"
local SOURCE_CUSTOM = "CUSTOM"

-- Private state holder for Book instances
local BookMeta = {}
BookMeta.__index = BookMeta

-- Helper functions
local function trim(s)
	if not s then
		return ""
	end
	s = tostring(s)
	return s:gsub("^%s+", ""):gsub("%s+$", "")
end

local function safeLower(s)
	s = trim(s)
	return s:lower()
end

local function normalizeKeyPart(s)
	s = safeLower(s)
	s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	s = s:gsub("%s+", " ")
	return s
end

local function getTime()
	local globalTime = type(_G) == "table" and rawget(_G, "time") or nil
	local osTime = type(os) == "table" and os.time or nil
	local provider = globalTime or osTime or function()
		return 0
	end
	return provider()
end

local function buildSearchText(title, pages)
	local parts = {}
	if title and title ~= "" then
		table.insert(parts, normalizeKeyPart(title))
	end
	if type(pages) == "table" then
		for _, pageText in ipairs(pages) do
			if type(pageText) == "string" and pageText ~= "" then
				table.insert(parts, normalizeKeyPart(pageText))
			end
		end
	end
	return table.concat(parts, " ")
end

local function cloneTable(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = cloneTable(v)
	end
	return copy
end

---============================================================================
--- CONSTRUCTORS
---============================================================================

---Create a Book from a captured book entry (read-only)
---@param entry table The database entry
---@return table Book instance
function Book.CapturedFromEntry(entry)
	if type(entry) ~= "table" then
		error("Book.CapturedFromEntry: entry must be a table")
	end
	
	local self = setmetatable({}, BookMeta)
	
	-- Core identity
	self._id = entry.id
	self._sourceType = SOURCE_CAPTURED
	
	-- Content (immutable for captured books)
	self._title = trim(entry.title or "")
	self._creator = trim(entry.creator or "")
	self._material = trim(entry.material or "")
	self._pages = {}
	if type(entry.pages) == "table" then
		for i, page in ipairs(entry.pages) do
			self._pages[i] = tostring(page)
		end
	end
	
	-- Location metadata
	self._location = entry.location and cloneTable(entry.location) or nil
	self._itemId = entry.itemId
	self._objectId = entry.objectId
	
	-- Timestamps
	self._createdAt = entry.createdAt or getTime()
	self._updatedAt = entry.updatedAt or self._createdAt
	self._firstSeenAt = entry.firstSeenAt or self._createdAt
	self._lastSeenAt = entry.lastSeenAt or self._createdAt
	self._lastReadAt = entry.lastReadAt
	
	-- User metadata
	self._isFavorite = entry.isFavorite == true
	
	-- Derived fields
	self._searchText = entry.searchText or buildSearchText(self._title, self._pages)
	
	-- Legacy/migration flags
	self._legacy = entry.legacy and cloneTable(entry.legacy) or nil
	
	return self
end

---Create a new custom book
---@param id string Stable book ID
---@param title string Book title
---@param creator string Creator name (usually player name)
---@return table Book instance
function Book.NewCustom(id, title, creator)
	if not id or id == "" then
		error("Book.NewCustom: id is required")
	end
	if not title or title == "" then
		error("Book.NewCustom: title is required")
	end
	
	local self = setmetatable({}, BookMeta)
	
	-- Core identity
	self._id = id
	self._sourceType = SOURCE_CUSTOM
	
	-- Content (mutable for custom books)
	self._title = trim(title)
	self._creator = trim(creator or "")
	self._material = ""
	self._pages = { "" } -- Start with one empty page
	
	-- Location metadata
	self._location = nil
	self._itemId = nil
	self._objectId = nil
	
	-- Timestamps
	local now = getTime()
	self._createdAt = now
	self._updatedAt = now
	self._firstSeenAt = now
	self._lastSeenAt = now
	self._lastReadAt = nil
	
	-- User metadata
	self._isFavorite = false
	
	-- Derived fields
	self._searchText = buildSearchText(self._title, self._pages)
	
	-- Legacy/migration flags
	self._legacy = nil
	
	return self
end

---Reconstruct a Book from any database entry (auto-detects source type)
---@param entry table The database entry
---@return table Book instance
function Book.FromEntry(entry)
	if type(entry) ~= "table" then
		error("Book.FromEntry: entry must be a table")
	end
	
	-- Determine source type (future-proof for when we add the field)
	local sourceType = entry.sourceType
	if not sourceType then
		-- Legacy detection: if it has itemId or objectId, it's captured
		if entry.itemId or entry.objectId then
			sourceType = SOURCE_CAPTURED
		else
			sourceType = SOURCE_CUSTOM
		end
	end
	
	if sourceType == SOURCE_CAPTURED then
		return Book.CapturedFromEntry(entry)
	else
		-- Reconstruct custom book from existing entry
		local self = setmetatable({}, BookMeta)
		
		self._id = entry.id
		self._sourceType = SOURCE_CUSTOM
		self._title = trim(entry.title or "")
		self._creator = trim(entry.creator or "")
		self._material = trim(entry.material or "")
		self._pages = {}
		if type(entry.pages) == "table" then
			for i, page in ipairs(entry.pages) do
				self._pages[i] = tostring(page)
			end
		end
		if #self._pages == 0 then
			self._pages = { "" }
		end
		
		self._location = entry.location and cloneTable(entry.location) or nil
		self._itemId = entry.itemId
		self._objectId = entry.objectId
		
		self._createdAt = entry.createdAt or getTime()
		self._updatedAt = entry.updatedAt or self._createdAt
		self._firstSeenAt = entry.firstSeenAt or self._createdAt
		self._lastSeenAt = entry.lastSeenAt or self._createdAt
		self._lastReadAt = entry.lastReadAt
		
		self._isFavorite = entry.isFavorite == true
		self._searchText = entry.searchText or buildSearchText(self._title, self._pages)
		self._legacy = entry.legacy and cloneTable(entry.legacy) or nil
		
		return self
	end
end

---============================================================================
--- READS (Pure)
---============================================================================

---Get book ID
---@return string Book ID
function BookMeta:GetId()
	return self._id
end

---Get book title
---@return string Book title
function BookMeta:GetTitle()
	return self._title
end

---Get book creator
---@return string Creator name
function BookMeta:GetCreator()
	return self._creator
end

---Get book material
---@return string Material description
function BookMeta:GetMaterial()
	return self._material
end

---Get total page count
---@return number Number of pages
function BookMeta:GetPageCount()
	return #self._pages
end

---Get text for a specific page
---@param pageNum number Page number (1-indexed)
---@return string Page text, or empty string if page doesn't exist
function BookMeta:GetPageText(pageNum)
	if type(pageNum) ~= "number" or pageNum < 1 then
		return ""
	end
	return self._pages[pageNum] or ""
end

---Check if book is editable
---@return boolean True if book can be modified
function BookMeta:IsEditable()
	return self._sourceType == SOURCE_CUSTOM
end

---Get source type
---@return string "CAPTURED" or "CUSTOM"
function BookMeta:GetSourceType()
	return self._sourceType
end

---Get location metadata
---@return table|nil Location info
function BookMeta:GetLocation()
	return self._location and cloneTable(self._location) or nil
end

---Get item ID (for captured books)
---@return number|nil Item ID
function BookMeta:GetItemId()
	return self._itemId
end

---Get object ID (for captured books)
---@return number|nil Object ID
function BookMeta:GetObjectId()
	return self._objectId
end

---Get created timestamp
---@return number Unix timestamp
function BookMeta:GetCreatedAt()
	return self._createdAt
end

---Get updated timestamp
---@return number Unix timestamp
function BookMeta:GetUpdatedAt()
	return self._updatedAt
end

---Get first seen timestamp
---@return number Unix timestamp
function BookMeta:GetFirstSeenAt()
	return self._firstSeenAt
end

---Get last seen timestamp
---@return number Unix timestamp
function BookMeta:GetLastSeenAt()
	return self._lastSeenAt
end

---Get last read timestamp
---@return number|nil Unix timestamp
function BookMeta:GetLastReadAt()
	return self._lastReadAt
end

---Check if book is favorited
---@return boolean True if favorited
function BookMeta:IsFavorite()
	return self._isFavorite
end

---Get all pages as array
---@return table Array of page text strings
function BookMeta:GetPages()
	local pages = {}
	for i, page in ipairs(self._pages) do
		pages[i] = page
	end
	return pages
end

---============================================================================
--- WRITES (Enforce invariants)
---============================================================================

---Set book title (CUSTOM only)
---@param title string New title
---@return boolean success True if title was set
---@return string|nil error Error message if failed
function BookMeta:SetTitle(title)
	if self._sourceType ~= SOURCE_CUSTOM then
		return false, "Cannot modify captured book"
	end
	
	title = trim(title)
	if title == "" then
		return false, "Title cannot be empty"
	end
	
	self._title = title
	self._updatedAt = getTime()
	self._searchText = buildSearchText(self._title, self._pages)
	
	return true
end

---Set page text (CUSTOM only)
---@param pageNum number Page number (1-indexed)
---@param text string Page text
---@return boolean success True if page was set
---@return string|nil error Error message if failed
function BookMeta:SetPageText(pageNum, text)
	if self._sourceType ~= SOURCE_CUSTOM then
		return false, "Cannot modify captured book"
	end
	
	if type(pageNum) ~= "number" or pageNum < 1 then
		return false, "Invalid page number"
	end
	
	text = type(text) == "string" and text or ""
	
	-- Auto-expand pages array if needed
	while #self._pages < pageNum do
		table.insert(self._pages, "")
	end
	
	self._pages[pageNum] = text
	self._updatedAt = getTime()
	self._searchText = buildSearchText(self._title, self._pages)
	
	return true
end

---Set location metadata (CUSTOM only)
---@param location table Location info
---@return boolean success True if location was set
---@return string|nil error Error message if failed
function BookMeta:SetLocation(location)
	if self._sourceType ~= SOURCE_CUSTOM then
		return false, "Cannot modify captured book location"
	end
	
	self._location = location and cloneTable(location) or nil
	self._updatedAt = getTime()
	
	return true
end

---Touch updated timestamp (updates lastSeenAt for re-captures)
---@return boolean success Always true
function BookMeta:TouchUpdatedAt()
	self._updatedAt = getTime()
	self._lastSeenAt = getTime()
	return true
end

---Mark book as favorited
---@param isFavorite boolean Favorite state
---@return boolean success Always true
function BookMeta:SetFavorite(isFavorite)
	self._isFavorite = isFavorite == true
	return true
end

---Mark book as read (updates lastReadAt)
---@return boolean success Always true
function BookMeta:MarkRead()
	self._lastReadAt = getTime()
	return true
end

---Add a new page after specified page (CUSTOM only)
---@param afterPageNum number|nil Page to insert after (nil = append to end)
---@return boolean success True if page was added
---@return string|nil error Error message if failed
function BookMeta:AddPage(afterPageNum)
	if self._sourceType ~= SOURCE_CUSTOM then
		return false, "Cannot modify captured book"
	end
	
	if afterPageNum == nil then
		afterPageNum = #self._pages
	end
	
	if type(afterPageNum) ~= "number" or afterPageNum < 0 or afterPageNum > #self._pages then
		return false, "Invalid page position"
	end
	
	table.insert(self._pages, afterPageNum + 1, "")
	self._updatedAt = getTime()
	
	return true
end

---Remove a page (CUSTOM only, must keep at least 1 page)
---@param pageNum number Page number to remove
---@return boolean success True if page was removed
---@return string|nil error Error message if failed
function BookMeta:RemovePage(pageNum)
	if self._sourceType ~= SOURCE_CUSTOM then
		return false, "Cannot modify captured book"
	end
	
	if #self._pages <= 1 then
		return false, "Cannot remove last page"
	end
	
	if type(pageNum) ~= "number" or pageNum < 1 or pageNum > #self._pages then
		return false, "Invalid page number"
	end
	
	table.remove(self._pages, pageNum)
	self._updatedAt = getTime()
	self._searchText = buildSearchText(self._title, self._pages)
	
	return true
end

---============================================================================
--- SERIALIZATION
---============================================================================

---Convert book to database entry format
---@return table Database entry
function BookMeta:ToEntry()
	local entry = {
		id = self._id,
		sourceType = self._sourceType,
		title = self._title,
		creator = self._creator,
		material = self._material,
		pages = {},
		location = self._location and cloneTable(self._location) or nil,
		itemId = self._itemId,
		objectId = self._objectId,
		createdAt = self._createdAt,
		updatedAt = self._updatedAt,
		firstSeenAt = self._firstSeenAt,
		lastSeenAt = self._lastSeenAt,
		lastReadAt = self._lastReadAt,
		isFavorite = self._isFavorite,
		searchText = self._searchText,
		legacy = self._legacy and cloneTable(self._legacy) or nil,
	}
	
	-- Copy pages array
	for i, page in ipairs(self._pages) do
		entry.pages[i] = page
	end
	
	return entry
end

---============================================================================
--- VALIDATION
---============================================================================

---Validate book invariants
---@return boolean valid True if all invariants hold
---@return string|nil error Error message if invalid
function BookMeta:Validate()
	-- ID must exist
	if not self._id or self._id == "" then
		return false, "Book ID is required"
	end
	
	-- Source type must be valid
	if self._sourceType ~= SOURCE_CAPTURED and self._sourceType ~= SOURCE_CUSTOM then
		return false, "Invalid source type: " .. tostring(self._sourceType)
	end
	
	-- Title must exist
	if not self._title or self._title == "" then
		return false, "Title is required"
	end
	
	-- Must have at least one page
	if not self._pages or #self._pages < 1 then
		return false, "Book must have at least one page"
	end
	
	-- Pages must be contiguous (no gaps)
	for i = 1, #self._pages do
		if self._pages[i] == nil then
			return false, "Page array has gaps at index " .. i
		end
	end
	
	-- Timestamps must be numbers
	if type(self._createdAt) ~= "number" then
		return false, "createdAt must be a number"
	end
	if type(self._updatedAt) ~= "number" then
		return false, "updatedAt must be a number"
	end
	
	return true
end

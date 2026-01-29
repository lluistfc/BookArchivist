---@diagnostic disable: undefined-global
-- BookArchivist_UI_Reader_Copy.lua
-- Handles copy to clipboard functionality for the reader panel.
-- Displays a popup with plain text content that can be selected and copied.

local ADDON_NAME = ...

local BA = BookArchivist
BA.UI = BA.UI or {}
BA.UI.Reader = BA.UI.Reader or {}

local ReaderCopy = {}
BA.UI.Reader.Copy = ReaderCopy

local L = BA and BA.L or {}
local function t(key)
	return (L and L[key]) or key
end

local copyFrame

-- Helper to get CreateFrame (safe version)
local function getCreateFrame()
	return BA.__createFrame
		or CreateFrame
		or function()
			local dummy = {}
			function dummy:SetScript() end
			function dummy:RegisterEvent() end
			return dummy
		end
end

--- Extracts plain text from book content (strips HTML tags and WoW formatting codes).
-- @param text string The raw text content
-- @return string Plain text with HTML and color codes removed
local function stripFormatting(text)
	if not text then
		return ""
	end
	-- Remove HTML tags
	text = text:gsub("<[^>]+>", "")
	-- Remove WoW color codes |cFFxxxxxx ... |r
	text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
	text = text:gsub("|r", "")
	-- Remove texture codes |T...|t
	text = text:gsub("|T[^|]+|t", "")
	-- Remove hyperlinks |H...|h...|h
	text = text:gsub("|H[^|]+|h([^|]+)|h", "%1")
	-- Convert |n to newline
	text = text:gsub("|n", "\n")
	-- Remove any remaining pipe escapes
	text = text:gsub("||", "|")
	-- Trim leading/trailing whitespace
	text = text:match("^%s*(.-)%s*$") or text
	return text
end

--- Gets the full plain text content of a book (all pages combined).
-- @param bookData table The book entry from booksById
-- @return string The combined plain text from all pages
local function getBookPlainText(bookData)
	if not bookData or not bookData.pages then
		return ""
	end
	
	local parts = {}
	local pageOrder = bookData.pageOrder
	
	-- Build ordered list of page keys
	local keys = {}
	if pageOrder and type(pageOrder) == "table" then
		keys = pageOrder
	else
		for k in pairs(bookData.pages) do
			table.insert(keys, k)
		end
		table.sort(keys)
	end
	
	-- Combine all pages
	for i, pageKey in ipairs(keys) do
		local pageText = bookData.pages[pageKey]
		if pageText and pageText ~= "" then
			local plainText = stripFormatting(pageText)
			if plainText and plainText ~= "" then
				if #parts > 0 then
					table.insert(parts, "\n\n--- Page " .. i .. " ---\n\n")
				end
				table.insert(parts, plainText)
			end
		end
	end
	
	return table.concat(parts, "")
end

--- Show the copy popup with the book's plain text content.
-- Displays a modal dialog containing the book's text for easy copying.
--
-- @param bookData table The complete book entry from booksById
-- @param bookTitle string|nil The title of the book (for display)
function ReaderCopy:Show(bookData, bookTitle)
	if not bookData then
		if BA and BA.DebugPrint then
			BA:DebugPrint("|cFFFF0000[BookArchivist]|r Copy: No book data provided")
		end
		return
	end
	
	local plainText = getBookPlainText(bookData)
	if not plainText or plainText == "" then
		if BA and BA.DebugPrint then
			BA:DebugPrint("|cFFFF0000[BookArchivist]|r Copy: Book has no text content")
		end
		return
	end
	
	-- Get or create the copy modal frame
	if not copyFrame then
		local createFrame = getCreateFrame()
		copyFrame = createFrame("Frame", "BookArchivistCopyFrame", UIParent, "BackdropTemplate")
		copyFrame:SetFrameStrata("DIALOG")
		copyFrame:SetSize(500, 350)
		copyFrame:SetPoint("CENTER")
		copyFrame:EnableMouse(true)
		copyFrame:SetMovable(true)
		copyFrame:RegisterForDrag("LeftButton")
		copyFrame:SetScript("OnDragStart", copyFrame.StartMoving)
		copyFrame:SetScript("OnDragStop", copyFrame.StopMovingOrSizing)
		
		if copyFrame.SetBackdrop then
			copyFrame:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true,
				tileSize = 32,
				edgeSize = 32,
				insets = { left = 8, right = 8, top = 8, bottom = 8 },
			})
		end
		
		-- Title bar
		local titleBar = createFrame("Frame", nil, copyFrame)
		titleBar:SetHeight(32)
		titleBar:SetPoint("TOPLEFT", copyFrame, "TOPLEFT", 8, -8)
		titleBar:SetPoint("TOPRIGHT", copyFrame, "TOPRIGHT", -8, -8)
		
		local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		titleText:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
		titleText:SetPoint("RIGHT", titleBar, "RIGHT", -32, 0) -- Leave room for close button
		titleText:SetJustifyH("LEFT")
		titleText:SetWordWrap(false)
		titleText:SetText(t("READER_COPY_POPUP_TITLE"))
		copyFrame.titleText = titleText
		
		-- Close button
		local closeBtn = createFrame("Button", nil, copyFrame, "UIPanelCloseButton")
		closeBtn:SetPoint("TOPRIGHT", copyFrame, "TOPRIGHT", -4, -4)
		closeBtn:SetScript("OnClick", function()
			copyFrame:Hide()
		end)
		
		-- Help text
		local helpText = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		helpText:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -8)
		helpText:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -8)
		helpText:SetJustifyH("LEFT")
		helpText:SetText(t("READER_COPY_POPUP_LABEL"))
		
		-- ScrollFrame for EditBox
		local scrollFrame = createFrame("ScrollFrame", nil, copyFrame, "UIPanelScrollFrameTemplate")
		scrollFrame:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -8)
		scrollFrame:SetPoint("BOTTOMRIGHT", copyFrame, "BOTTOMRIGHT", -28, 48)
		
		if scrollFrame.SetBackdrop then
			scrollFrame:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true,
				tileSize = 16,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 },
			})
		end
		
		-- EditBox
		local editBox = createFrame("EditBox", nil, scrollFrame)
		editBox:SetMultiLine(true)
		editBox:SetAutoFocus(false)
		editBox:SetFontObject("GameFontHighlight")
		editBox:SetWidth(scrollFrame:GetWidth() - 20)
		editBox:SetMaxLetters(0)
		editBox:EnableMouse(true)
		editBox:SetScript("OnEscapePressed", function()
			copyFrame:Hide()
		end)
		
		scrollFrame:SetScrollChild(editBox)
		copyFrame.editBox = editBox
		
		-- Select All button
		local selectAllBtn = createFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
		selectAllBtn:SetSize(120, 22)
		selectAllBtn:SetPoint("BOTTOMLEFT", copyFrame, "BOTTOMLEFT", 8, 12)
		selectAllBtn:SetText(t("READER_COPY_SELECT_ALL"))
		selectAllBtn:SetScript("OnClick", function()
			editBox:SetFocus()
			editBox:HighlightText()
			if editBox.SetCursorPosition then
				editBox:SetCursorPosition(0)
			end
		end)
		
		-- Close button at bottom
		local closeBtnBottom = createFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
		closeBtnBottom:SetSize(80, 22)
		closeBtnBottom:SetPoint("BOTTOMRIGHT", copyFrame, "BOTTOMRIGHT", -8, 12)
		closeBtnBottom:SetText(t("CANCEL"))
		closeBtnBottom:SetScript("OnClick", function()
			copyFrame:Hide()
		end)
	end
	
	-- Update title with book name
	local displayTitle = bookTitle or bookData.title or t("BOOK_UNKNOWN")
	copyFrame.titleText:SetText(t("READER_COPY_POPUP_TITLE") .. ": " .. displayTitle)
	
	-- Set the text content
	copyFrame.editBox:SetText(plainText)
	copyFrame.editBox:SetWidth(copyFrame:GetWidth() - 48)
	
	-- Show and auto-select
	copyFrame:Show()
	copyFrame.editBox:SetFocus()
	copyFrame.editBox:HighlightText()
end

--- Copy the current book's text to the clipboard popup.
-- Gets the currently selected book from the reader and shows the copy dialog.
--
-- @param getSelectedKey function Function that returns the currently selected book key
function ReaderCopy:CopyCurrentBook(getSelectedKey)
	local key = getSelectedKey and getSelectedKey()
	if not key then
		if BA and BA.DebugPrint then
			BA:DebugPrint("|cFFFF0000[BookArchivist]|r Copy: No book selected")
		end
		return
	end
	
	-- Get book data from Repository
	local Repository = BA and BA.Repository
	if not Repository or not Repository.GetDB then
		if BA and BA.DebugPrint then
			BA:DebugPrint("|cFFFF0000[BookArchivist]|r Copy: Repository not available")
		end
		return
	end
	
	local db = Repository:GetDB()
	if not db or not db.booksById then
		return
	end
	
	local bookData = db.booksById[key]
	if not bookData then
		if BA and BA.DebugPrint then
			BA:DebugPrint("|cFFFF0000[BookArchivist]|r Copy: Book not found:", key)
		end
		return
	end
	
	self:Show(bookData, bookData.title)
end

return ReaderCopy

---@diagnostic disable: undefined-global
-- BookArchivist_UI_Reader_Share.lua
-- Handles share functionality for the reader (export single book and show share popup)

local ADDON_NAME = ...

local BA = BookArchivist
BA.UI = BA.UI or {}
BA.UI.Reader = BA.UI.Reader or {}

local ReaderShare = {}
BA.UI.Reader.Share = ReaderShare

local L = BA and BA.L or {}
local function t(key)
	return (L and L[key]) or key
end

local shareFrame

-- Focus navigation state for the share popup
local focusState = {
	enabled = false,
	currentIndex = 0,
	elements = {}, -- { { frame = frame, name = "name" }, ... }
	highlightFrame = nil,
}

-- Create highlight frame for focus indicator
local function ensureFocusHighlight()
	if focusState.highlightFrame then
		return focusState.highlightFrame
	end
	
	local createFrame = BA.__createFrame or CreateFrame
	local highlight = createFrame("Frame", nil, UIParent, "BackdropTemplate")
	highlight:SetFrameStrata("TOOLTIP")
	highlight:SetFrameLevel(100)
	
	if highlight.SetBackdrop then
		highlight:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 12,
		})
		highlight:SetBackdropBorderColor(1, 0.82, 0, 1) -- Gold border
	end
	
	highlight:Hide()
	focusState.highlightFrame = highlight
	return highlight
end

-- Update focus highlight position
local function updateFocusHighlight()
	local highlight = ensureFocusHighlight()
	
	if not focusState.enabled or focusState.currentIndex < 1 or focusState.currentIndex > #focusState.elements then
		highlight:Hide()
		return
	end
	
	local elem = focusState.elements[focusState.currentIndex]
	if not elem or not elem.frame or not elem.frame:IsVisible() then
		highlight:Hide()
		return
	end
	
	highlight:ClearAllPoints()
	highlight:SetPoint("TOPLEFT", elem.frame, "TOPLEFT", -4, 4)
	highlight:SetPoint("BOTTOMRIGHT", elem.frame, "BOTTOMRIGHT", 4, -4)
	highlight:SetParent(elem.frame:GetParent())
	highlight:Show()
end

-- Move focus to next/previous element
local function moveFocus(direction)
	if #focusState.elements == 0 then
		return
	end
	
	focusState.currentIndex = focusState.currentIndex + direction
	
	-- Wrap around
	if focusState.currentIndex < 1 then
		focusState.currentIndex = #focusState.elements
	elseif focusState.currentIndex > #focusState.elements then
		focusState.currentIndex = 1
	end
	
	updateFocusHighlight()
end

-- Activate the currently focused element
-- Uses C_Timer.After to delay the click so keybind character doesn't get inserted into chat
local function activateFocus()
	if focusState.currentIndex < 1 or focusState.currentIndex > #focusState.elements then
		return
	end
	
	local elem = focusState.elements[focusState.currentIndex]
	if not elem or not elem.frame then
		return
	end
	
	-- Delay the click so the keybind character doesn't get inserted into chat editbox
	if elem.frame.Click then
		C_Timer.After(0, function()
			if elem.frame and elem.frame.Click then
				elem.frame:Click()
			end
		end)
	end
end

-- Register share popup elements for focus navigation
-- Note: EditBox is NOT included - users can click it with mouse to copy text
-- Focus navigation only cycles through the action buttons
local function registerFocusElements()
	focusState.elements = {}
	focusState.currentIndex = 0
	focusState.enabled = false
	
	if not shareFrame then
		return
	end
	
	-- Order: Share to Chat -> Select All -> Close (EditBox excluded - use mouse to focus)
	if shareFrame.shareToChatBtn then
		table.insert(focusState.elements, {
			frame = shareFrame.shareToChatBtn,
			name = t("SHARE_TO_CHAT_BUTTON"),
		})
	end
	
	if shareFrame.selectAllBtn then
		table.insert(focusState.elements, {
			frame = shareFrame.selectAllBtn,
			name = t("READER_SHARE_SELECT_ALL"),
		})
	end
	
	if shareFrame.closeBtn then
		table.insert(focusState.elements, {
			frame = shareFrame.closeBtn,
			name = t("CLOSE") or "Close",
		})
	end
	
	if #focusState.elements > 0 then
		focusState.enabled = true
		focusState.currentIndex = 1
		updateFocusHighlight()
	end
end

-- Unregister focus elements when popup hides
local function unregisterFocusElements()
	focusState.enabled = false
	focusState.currentIndex = 0
	focusState.elements = {}
	
	if focusState.highlightFrame then
		focusState.highlightFrame:Hide()
	end
end

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

--- Show the share popup with the export string.
-- Displays a modal dialog containing the export string for a single book,
-- with options to copy the string or share via chat link.
--
-- @param exportStr string The BDB1-encoded export string for the book
-- @param bookTitle string|nil The title of the book being shared (for display)
-- @param bookKey string The unique book ID (used for chat link registration)
-- @param exportContext table|nil Optional context for storing export payload (e.g., { lastExportPayload = exportStr })
-- @param bookData table|nil The complete book entry from booksById (stored for chat link registration)
function ReaderShare:Show(exportStr, bookTitle, bookKey, exportContext, bookData)
	if not exportStr or exportStr == "" then
		BookArchivist:DebugPrint("|cFFFF0000[BookArchivist]|r Failed to generate export string.")
		return
	end

	BookArchivist:DebugPrint("|cFF4A7EBB[Share DEBUG]|r Show() called with:")
	BookArchivist:DebugPrint("  bookTitle:", bookTitle)
	BookArchivist:DebugPrint("  bookKey:", bookKey)
	BookArchivist:DebugPrint("  exportContext:", exportContext and "present" or "nil")
	BookArchivist:DebugPrint("  bookData:", bookData and "present" or "nil")

	-- Get or create the share modal frame
	if not shareFrame then
		local createFrame = getCreateFrame()
		shareFrame = createFrame("Frame", "BookArchivistShareFrame", UIParent, "BackdropTemplate")
		shareFrame:SetFrameStrata("DIALOG")
		shareFrame:SetSize(500, 300)
		shareFrame:SetPoint("CENTER")
		shareFrame:EnableMouse(true)
		shareFrame:SetMovable(true)
		shareFrame:RegisterForDrag("LeftButton")
		shareFrame:SetScript("OnDragStart", shareFrame.StartMoving)
		shareFrame:SetScript("OnDragStop", shareFrame.StopMovingOrSizing)

		if shareFrame.SetBackdrop then
			shareFrame:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true,
				tileSize = 32,
				edgeSize = 32,
				insets = { left = 8, right = 8, top = 8, bottom = 8 },
			})
		end

		-- Title bar
		local titleBar = createFrame("Frame", nil, shareFrame)
		titleBar:SetHeight(32)
		titleBar:SetPoint("TOPLEFT", shareFrame, "TOPLEFT", 8, -8)
		titleBar:SetPoint("TOPRIGHT", shareFrame, "TOPRIGHT", -8, -8)

		local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		titleText:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
		titleText:SetText(t("READER_SHARE_POPUP_TITLE"))

		-- Close button
		local closeBtn = createFrame("Button", "BookArchivistShareCloseBtn", shareFrame, "UIPanelCloseButton")
		closeBtn:SetPoint("TOPRIGHT", shareFrame, "TOPRIGHT", -4, -4)
		closeBtn:SetScript("OnClick", function()
			shareFrame:Hide()
		end)
		shareFrame.closeBtn = closeBtn
		
		-- Keyboard navigation handler for the frame
		shareFrame:EnableKeyboard(true)
		shareFrame:SetPropagateKeyboardInput(true)
		shareFrame:SetScript("OnKeyDown", function(self, key)
			-- Check for BookArchivist focus navigation keybindings
			local nextKey1, nextKey2 = GetBindingKey("BOOKARCHIVIST_FOCUS_NEXT")
			local prevKey1, prevKey2 = GetBindingKey("BOOKARCHIVIST_FOCUS_PREV")
			local actKey1, actKey2 = GetBindingKey("BOOKARCHIVIST_FOCUS_ACTIVATE")
			local keyUpper = key:upper()
			
			if (nextKey1 and keyUpper == nextKey1:upper()) or (nextKey2 and keyUpper == nextKey2:upper()) then
				self:SetPropagateKeyboardInput(false)
				moveFocus(1)
			elseif (prevKey1 and keyUpper == prevKey1:upper()) or (prevKey2 and keyUpper == prevKey2:upper()) then
				self:SetPropagateKeyboardInput(false)
				moveFocus(-1)
			elseif (actKey1 and keyUpper == actKey1:upper()) or (actKey2 and keyUpper == actKey2:upper()) then
				self:SetPropagateKeyboardInput(false)
				activateFocus()
			elseif key == "TAB" then
				self:SetPropagateKeyboardInput(false)
				if IsShiftKeyDown() then
					moveFocus(-1)
				else
					moveFocus(1)
				end
			elseif key == "ENTER" and focusState.enabled and focusState.currentIndex > 0 then
				self:SetPropagateKeyboardInput(false)
				activateFocus()
			elseif key == "ESCAPE" then
				self:SetPropagateKeyboardInput(false)
				shareFrame:Hide()
			else
				self:SetPropagateKeyboardInput(true)
			end
		end)
		
		-- Unregister focus elements when hidden
		shareFrame:SetScript("OnHide", function()
			unregisterFocusElements()
		end)

		-- Help text
		local helpText = shareFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		helpText:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -8)
		helpText:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -8)
		helpText:SetJustifyH("LEFT")
		helpText:SetText(t("READER_SHARE_POPUP_LABEL"))

		-- Chat link hint
		local chatHint = shareFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		chatHint:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -4)
		chatHint:SetPoint("TOPRIGHT", helpText, "BOTTOMRIGHT", 0, -4)
		chatHint:SetJustifyH("LEFT")
		chatHint:SetTextColor(0.29, 0.49, 0.73) -- Blue color
		chatHint:SetText(t("SHARE_CHAT_HINT"))
		shareFrame.chatHint = chatHint

		-- ScrollFrame for EditBox
		local scrollFrame = createFrame("ScrollFrame", nil, shareFrame, "UIPanelScrollFrameTemplate")
		scrollFrame:SetPoint("TOPLEFT", chatHint, "BOTTOMLEFT", 0, -8)
		scrollFrame:SetPoint("BOTTOMRIGHT", shareFrame, "BOTTOMRIGHT", -28, 48)

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

		-- EditBox for displaying export string (allows selection/copy with mouse)
		-- Not included in keyboard focus navigation - users click with mouse to select/copy
		local editBox = createFrame("EditBox", nil, scrollFrame)
		editBox:SetMultiLine(true)
		editBox:SetAutoFocus(false)
		editBox:SetFontObject("GameFontHighlight")
		editBox:SetWidth(scrollFrame:GetWidth() - 20)
		editBox:SetMaxLetters(0)
		editBox:EnableMouse(true)
		
		-- Create "Copied!" indicator overlay
		local copiedIndicator = createFrame("Frame", nil, scrollFrame, "BackdropTemplate")
		copiedIndicator:SetSize(80, 24)
		copiedIndicator:SetPoint("TOP", scrollFrame, "TOP", 0, -10)
		copiedIndicator:SetFrameLevel(scrollFrame:GetFrameLevel() + 10)
		if copiedIndicator.SetBackdrop then
			copiedIndicator:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 8,
				edgeSize = 8,
				insets = { left = 2, right = 2, top = 2, bottom = 2 },
			})
			copiedIndicator:SetBackdropColor(0.1, 0.4, 0.1, 0.9) -- Green background
			copiedIndicator:SetBackdropBorderColor(0.4, 0.8, 0.4, 1)
		end
		local copiedText = copiedIndicator:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		copiedText:SetPoint("CENTER")
		copiedText:SetText(t("COPIED") or "Copied!")
		copiedText:SetTextColor(0.4, 1, 0.4)
		copiedIndicator:Hide()
		shareFrame.copiedIndicator = copiedIndicator
		
		-- Function to show the copied indicator briefly
		local function showCopiedIndicator()
			copiedIndicator:SetAlpha(1)
			copiedIndicator:Show()
			-- Fade out after 1.5 seconds
			C_Timer.After(1.5, function()
				if copiedIndicator:IsShown() then
					copiedIndicator:Hide()
				end
			end)
		end
		
		-- Detect Ctrl+C keypress
		editBox:SetScript("OnKeyDown", function(self, key)
			if key == "C" and IsControlKeyDown() then
				-- User pressed Ctrl+C, show copied indicator
				C_Timer.After(0, function()
					showCopiedIndicator()
				end)
			end
		end)
		
		editBox:SetScript("OnEscapePressed", function()
			shareFrame:Hide()
		end)

		scrollFrame:SetScrollChild(editBox)
		shareFrame.editBox = editBox

		-- Share to Chat button (at bottom)
		local shareToChatBtn = createFrame("Button", nil, shareFrame, "UIPanelButtonTemplate")
		shareToChatBtn:SetSize(140, 22)
		shareToChatBtn:SetPoint("BOTTOMLEFT", shareFrame, "BOTTOMLEFT", 8, 12)
		shareToChatBtn:SetText(t("SHARE_TO_CHAT_BUTTON"))
		shareToChatBtn:SetScript("OnClick", function()
			local bookTitle = shareFrame.bookTitle or "Book"
			local chatLink = string.format("[BookArchivist: %s]", bookTitle)

			BookArchivist:DebugPrint("|cFF4A7EBB[Share DEBUG]|r Share to Chat clicked:")
			BookArchivist:DebugPrint("  bookTitle:", bookTitle)
			BookArchivist:DebugPrint("  bookKey:", shareFrame.bookKey)
			BookArchivist:DebugPrint("  bookData:", shareFrame.bookData and "present" or "nil")

			-- Register book as linked RIGHT NOW when sending to chat
			if BookArchivist.ChatLinks and shareFrame.bookKey and shareFrame.bookData then
				BookArchivist:DebugPrint("|cFF00FF00[Share DEBUG]|r Registering book as linked")
				BookArchivist.ChatLinks:RegisterLinkedBook(shareFrame.bookKey, shareFrame.bookData)
			else
				BookArchivist:DebugPrint(
					"|cFFFF0000[Share DEBUG]|r Cannot register: missing ChatLinks, bookKey, or bookData"
				)
			end

			-- Insert into active chat editbox
			local editbox = ChatEdit_GetActiveWindow()
			if editbox then
				editbox:Insert(chatLink)
				editbox:SetFocus()
			else
				-- No active chat, just put it in the default chat frame
				ChatFrame1EditBox:Show()
				ChatFrame1EditBox:SetFocus()
				ChatFrame1EditBox:Insert(chatLink)
			end

			-- Optional: show confirmation
			BookArchivist:DebugPrint(
				"|cFF4A7EBBBookArchivist:|r "
					.. (t("SHARE_LINK_INSERTED") or "Chat link inserted! Press Enter to send.")
			)
		end)
		shareFrame.shareToChatBtn = shareToChatBtn

		-- Select All button
		local selectAllBtn = createFrame("Button", "BookArchivistShareSelectAllBtn", shareFrame, "UIPanelButtonTemplate")
		selectAllBtn:SetSize(100, 22)
		selectAllBtn:SetPoint("BOTTOM", shareFrame, "BOTTOM", 0, 12)
		selectAllBtn:SetText(t("READER_SHARE_SELECT_ALL"))
		selectAllBtn:SetScript("OnClick", function()
			editBox:SetFocus()
			editBox:HighlightText()
			if editBox.SetCursorPosition then
				editBox:SetCursorPosition(0)
			end
		end)
		shareFrame.selectAllBtn = selectAllBtn
	end

	-- Store book context for Share to Chat button (update EVERY time Show() is called)
	shareFrame.bookTitle = bookTitle
	shareFrame.bookKey = bookKey
	shareFrame.exportContext = exportContext
	shareFrame.bookData = bookData

	BookArchivist:DebugPrint("|cFF4A7EBB[Share DEBUG]|r Stored in shareFrame:")
	BookArchivist:DebugPrint("  bookTitle:", shareFrame.bookTitle)
	BookArchivist:DebugPrint("  bookKey:", shareFrame.bookKey)
	BookArchivist:DebugPrint("  bookData:", shareFrame.bookData and "present" or "nil")

	-- Update chat hint with book title if provided
	if shareFrame.chatHint and bookTitle then
		local hintText = string.format(
			t("SHARE_CHAT_HINT")
				or "Click the button below to insert a chat link, or copy the export string to share directly.",
			bookTitle
		)
		shareFrame.chatHint:SetText(hintText)
	end

	-- Set the export string and show
	shareFrame.editBox:SetText(exportStr)
	shareFrame.editBox:HighlightText()
	shareFrame:Show()
	
	-- Register focus elements for keyboard navigation (buttons only)
	-- EditBox is not in focus list - users click with mouse to select/copy
	registerFocusElements()
end

--- Generate export for the currently selected book and show share popup.
-- This is the main entry point called by the share button in the reader.
-- It retrieves book data from the database, generates the export string,
-- and displays the share dialog.
--
-- @param exportFns table Export function context with:
--                       - ExportBook: function(bookKey) -> exportStr, err (optional)
--                       - Export: function() -> exportStr, err (fallback)
--                       - lastExportPayload: string (optional, for storing result)
-- @param bookKey string The unique book ID to share (from booksById)
function ReaderShare:ShareCurrentBook(exportFns, bookKey)
	if not (exportFns and bookKey) then
		BookArchivist:DebugPrint("|cFFFF0000[BookArchivist]|r No export functions or book key provided.")
		return
	end

	BookArchivist:DebugPrint("|cFF4A7EBB[Share DEBUG]|r ShareCurrentBook called:")
	BookArchivist:DebugPrint("  exportFns:", exportFns and "present" or "nil")
	BookArchivist:DebugPrint("  bookKey:", bookKey)

	-- Get book data directly from DB
	local bookData = BookArchivistDB and BookArchivistDB.booksById and BookArchivistDB.booksById[bookKey]
	local bookTitle = bookData and bookData.title

	BookArchivist:DebugPrint("|cFF4A7EBB[Share DEBUG]|r Retrieved from DB:")
	BookArchivist:DebugPrint("  bookData:", bookData and "found" or "nil")
	BookArchivist:DebugPrint("  bookTitle:", bookTitle or "nil")

	-- Generate export for single book
	local exportStr, err
	if exportFns.ExportBook then
		exportStr, err = exportFns.ExportBook(bookKey)
	elseif exportFns.Export then
		-- Fallback to full export if ExportBook doesn't exist
		exportStr, err = exportFns.Export()
	end

	if exportStr and exportStr ~= "" then
		-- Store for quick access (if context table provided)
		if exportFns then
			exportFns.lastExportPayload = exportStr
		end

		-- Register book as "linked" for auto-response to requests
		if BookArchivist.ChatLinks and bookData then
			BookArchivist.ChatLinks:RegisterLinkedBook(bookKey, bookData)
		end

		-- Show share popup with book title and context
		self:Show(exportStr, bookTitle, bookKey, exportFns, bookData)
	else
		local errMsg = err or "unknown error"
		BookArchivist:DebugPrint("|cFFFF0000[BookArchivist]|r Failed to generate export string: " .. tostring(errMsg))
	end
end

return ReaderShare

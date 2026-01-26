---@diagnostic disable: undefined-global, undefined-field
-- Edit mode for creating and editing custom books
-- This module handles the simplified edit UI that appears in the reader panel

local ReaderUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.Reader
if not ReaderUI then
	return
end

local EditMode = {}
ReaderUI.EditMode = EditMode

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
	return (L and L[key]) or key
end

local state = ReaderUI.__state or {}
local Internal = BookArchivist.UI.Internal

-- Helper to trim whitespace
local function trim(s)
	if not s or s == "" then
		return ""
	end
	return s:match("^%s*(.-)%s*$") or ""
end

-- Edit session state
local editSession = {
	isEditing = false,
	bookId = nil,
	title = "",
	location = nil,
	pages = {}, -- Array of page content strings
	currentPageIndex = 1,
}

-- Check if currently editing
function EditMode:IsEditing()
	return editSession.isEditing
end

-- Initialize edit UI elements (called after reader frame is created)
function EditMode:InitializeUI()
	local editFrame = state.editBookFrame
	local editContent = state.editBookContent
	if not editFrame or not editContent then
		return
	end
	
	local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
	if not AceGUI then
		if BookArchivist and BookArchivist.LogError then
			BookArchivist:LogError("AceGUI-3.0 not found, cannot create edit UI")
		end
		return
	end
	
	-- Title input section
	local titleLabel = editContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titleLabel:SetPoint("TOPLEFT", editContent, "TOPLEFT", 0, 0)
	titleLabel:SetText(t("BOOK_TITLE") .. ":")
	
	local titleBox = CreateFrame("EditBox", nil, editContent, "InputBoxTemplate")
	titleBox:SetHeight(28)
	titleBox:SetPoint("TOPLEFT", titleLabel, "BOTTOMLEFT", 8, -4)
	titleBox:SetPoint("TOPRIGHT", editContent, "TOPRIGHT", -8, -24)
	titleBox:SetAutoFocus(false)
	titleBox:SetMaxLetters(100)
	titleBox:SetFontObject(GameFontNormal)
	titleBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	state.editTitleBox = titleBox
	
	-- Location section
	local locationLabel = editContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	locationLabel:SetPoint("TOPLEFT", titleBox, "BOTTOMLEFT", -8, -12)
	locationLabel:SetText(t("BOOK_LOCATION") .. ":")
	
	local locationDisplay = editContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	locationDisplay:SetPoint("TOPLEFT", locationLabel, "BOTTOMLEFT", 8, -4)
	locationDisplay:SetPoint("TOPRIGHT", editContent, "TOPRIGHT", -120, -74)
	locationDisplay:SetJustifyH("LEFT")
	locationDisplay:SetTextColor(0.7, 0.7, 0.7)
	locationDisplay:SetText(t("NO_LOCATION_SET"))
	state.editLocationDisplay = locationDisplay
	
	local useCurrentLocBtn = CreateFrame("Button", nil, editContent, "UIPanelButtonTemplate")
	useCurrentLocBtn:SetSize(110, 22)
	useCurrentLocBtn:SetPoint("LEFT", locationDisplay, "RIGHT", 8, 0)
	useCurrentLocBtn:SetText(t("USE_CURRENT_LOC"))
	useCurrentLocBtn:SetNormalFontObject(GameFontNormalSmall)
	useCurrentLocBtn:SetScript("OnClick", function()
		EditMode:UseCurrentLocation()
	end)
	state.editUseCurrentLocBtn = useCurrentLocBtn
	
	-- Page content section
	local pageLabel = editContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	pageLabel:SetPoint("TOPLEFT", locationLabel, "BOTTOMLEFT", 0, -32)
	pageLabel:SetText(t("PAGE_CONTENT") .. ":")
	state.editPageLabel = pageLabel
	
	-- Create AceGUI MultiLineEditBox for page content
	local pageEdit = AceGUI:Create("MultiLineEditBox")
	pageEdit:SetLabel("")
	pageEdit:SetNumLines(20)
	pageEdit:SetMaxLetters(4000) -- Generous page limit
	pageEdit:SetWidth(400) -- Explicit width
	pageEdit.frame:SetParent(editContent)
	pageEdit.frame:SetPoint("TOPLEFT", pageLabel, "BOTTOMLEFT", 0, -4)
	pageEdit.frame:SetPoint("BOTTOMRIGHT", editContent, "BOTTOMRIGHT", 0, 100)
	pageEdit.frame:Show() -- Explicitly show the frame
	pageEdit:SetCallback("OnTextChanged", function(widget, event, text)
		-- Auto-save current page content to session
		if editSession.isEditing then
			editSession.pages[editSession.currentPageIndex] = text
		end
	end)
	-- Hide the Accept button (not needed since we auto-save on text change)
	if pageEdit.button then
		pageEdit.button:Hide()
	end
	state.editPageEdit = pageEdit
	
	-- Page navigation and actions footer
	local footerFrame = CreateFrame("Frame", nil, editContent)
	footerFrame:SetPoint("BOTTOMLEFT", editContent, "BOTTOMLEFT", 0, 0)
	footerFrame:SetPoint("BOTTOMRIGHT", editContent, "BOTTOMRIGHT", 0, 0)
	footerFrame:SetHeight(100)
	
	-- Page indicator
	local pageIndicator = footerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	pageIndicator:SetPoint("TOP", footerFrame, "TOP", 0, -4)
	pageIndicator:SetText(t("PAGE") .. " 1 / 1")
	state.editPageIndicator = pageIndicator
	
	-- Navigation buttons row
	local navRow = CreateFrame("Frame", nil, footerFrame)
	navRow:SetSize(280, 32)
	navRow:SetPoint("TOP", pageIndicator, "BOTTOM", 0, -8)
	
	local prevPageBtn = CreateFrame("Button", nil, navRow, "UIPanelButtonTemplate")
	prevPageBtn:SetSize(80, 26)
	prevPageBtn:SetPoint("LEFT", navRow, "LEFT", 0, 0)
	prevPageBtn:SetText(t("PREV_PAGE"))
	prevPageBtn:SetNormalFontObject(GameFontNormal)
	prevPageBtn:SetScript("OnClick", function()
		EditMode:NavigatePage(-1)
	end)
	state.editPrevPageBtn = prevPageBtn
	
	local addPageBtn = CreateFrame("Button", nil, navRow, "UIPanelButtonTemplate")
	addPageBtn:SetSize(90, 26)
	addPageBtn:SetPoint("CENTER", navRow, "CENTER", 0, 0)
	addPageBtn:SetText(t("ADD_PAGE"))
	addPageBtn:SetNormalFontObject(GameFontNormal)
	local fontString = addPageBtn:GetFontString()
	if fontString then
		fontString:SetTextColor(0.1, 0.9, 0.1)
	end
	addPageBtn:SetScript("OnClick", function()
		EditMode:AddPage()
	end)
	state.editAddPageBtn = addPageBtn
	
	local nextPageBtn = CreateFrame("Button", nil, navRow, "UIPanelButtonTemplate")
	nextPageBtn:SetSize(80, 26)
	nextPageBtn:SetPoint("RIGHT", navRow, "RIGHT", 0, 0)
	nextPageBtn:SetText(t("NEXT_PAGE"))
	nextPageBtn:SetNormalFontObject(GameFontNormal)
	nextPageBtn:SetScript("OnClick", function()
		EditMode:NavigatePage(1)
	end)
	state.editNextPageBtn = nextPageBtn
	
	-- Action buttons row (TTS Preview/Save/Cancel)
	local actionRow = CreateFrame("Frame", nil, footerFrame)
	actionRow:SetSize(360, 32)
	actionRow:SetPoint("BOTTOM", footerFrame, "BOTTOM", 0, 4)
	
	-- TTS Preview button (hear what you've written)
	local ttsPreviewBtn = CreateFrame("Button", nil, actionRow, "UIPanelButtonTemplate")
	ttsPreviewBtn:SetSize(100, 32)
	ttsPreviewBtn:SetPoint("LEFT", actionRow, "LEFT", 0, 0)
	ttsPreviewBtn:SetText(t("TTS_PREVIEW") or "Preview")
	ttsPreviewBtn:SetNormalFontObject(GameFontNormal)
	ttsPreviewBtn:SetScript("OnClick", function()
		EditMode:PreviewTTS()
	end)
	ttsPreviewBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(t("TTS_PREVIEW_TOOLTIP_TITLE") or "Preview with TTS", 1, 1, 1)
		GameTooltip:AddLine(t("TTS_PREVIEW_TOOLTIP_BODY") or "Listen to your current page using text-to-speech.", nil, nil, nil, true)
		GameTooltip:Show()
	end)
	ttsPreviewBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	state.editTTSPreviewBtn = ttsPreviewBtn
	
	local saveBtn = CreateFrame("Button", nil, actionRow, "UIPanelButtonTemplate")
	saveBtn:SetSize(110, 32)
	saveBtn:SetPoint("CENTER", actionRow, "CENTER", 0, 0)
	saveBtn:SetText(t("SAVE_BOOK"))
	saveBtn:SetNormalFontObject(GameFontNormal)
	local saveFontString = saveBtn:GetFontString()
	if saveFontString then
		saveFontString:SetTextColor(0.1, 0.9, 0.1)
	end
	saveBtn:SetScript("OnClick", function()
		EditMode:SaveBook()
	end)
	state.editSaveBtn = saveBtn
	
	local cancelBtn = CreateFrame("Button", nil, actionRow, "UIPanelButtonTemplate")
	cancelBtn:SetSize(100, 32)
	cancelBtn:SetPoint("RIGHT", actionRow, "RIGHT", 0, 0)
	cancelBtn:SetText(t("CANCEL"))
	cancelBtn:SetNormalFontObject(GameFontNormal)
	cancelBtn:SetScript("OnClick", function()
		EditMode:Cancel()
	end)
	state.editCancelBtn = cancelBtn
	
	self.initialized = true
end

-- Start creating a new book
function EditMode:StartNewBook()
	if not self.initialized then
		self:InitializeUI()
	end
	
	-- Get current location for new books
	local Location = BookArchivist and BookArchivist.Location
	local currentLocation = nil
	local locText = t("NO_LOCATION_SET")
	
	if Location and Location.BuildWorldLocation then
		currentLocation = Location:BuildWorldLocation()
		if currentLocation and currentLocation.zoneText then
			locText = currentLocation.zoneText
		elseif currentLocation then
			locText = t("UNKNOWN_LOCATION")
		end
	end
	
	-- Reset session with current location
	editSession = {
		isEditing = true,
		bookId = nil,
		title = "",
		location = currentLocation,
		pages = { "" }, -- Start with one empty page
		currentPageIndex = 1,
	}
	
	-- Show edit UI, hide normal reader content
	self:ShowEditUI()
	
	-- Clear and focus title
	if state.editTitleBox then
		state.editTitleBox:SetText("")
		state.editTitleBox:SetFocus()
	end
	
	-- Set location display
	if state.editLocationDisplay then
		state.editLocationDisplay:SetText(locText)
		if currentLocation then
			state.editLocationDisplay:SetTextColor(1, 0.82, 0)
		end
	end
	
	-- Clear page content
	if state.editPageEdit then
		state.editPageEdit:SetText("")
	end
	
	-- Update page indicator
	if state.editPageIndicator then
		state.editPageIndicator:SetText(t("PAGE") .. " 1 / 1")
	end
end

-- Start editing an existing custom book
function EditMode:StartEditingBook(bookId)
	if not self.initialized then
		self:InitializeUI()
	end
	
	local BA = BookArchivist
	if not BA or not BA.Core then
		return
	end
	
	-- Get book via Core service (Step 4: Reader uses aggregate reads)
	local book = BA.Core:GetBook(bookId)
	if not book then
		return
	end
	
	-- Only allow editing custom books
	if not book:IsEditable() then
		return
	end
	
	-- Load book data into edit session from aggregate
	local pages = book:GetPages()
	if #pages == 0 then
		pages = { "" } -- Ensure at least one page
	end
	
	editSession = {
		isEditing = true,
		bookId = bookId,
		title = book:GetTitle(),
		location = book:GetLocation(),
		pages = pages,
		currentPageIndex = 1,
	}
	
	-- Show edit UI
	self:ShowEditUI()
	
	-- Populate title
	if state.editTitleBox then
		state.editTitleBox:SetText(editSession.title)
	end
	
	-- Populate location
	if state.editLocationDisplay then
		if editSession.location and editSession.location.zoneText then
			state.editLocationDisplay:SetText(editSession.location.zoneText)
		else
			state.editLocationDisplay:SetText(t("NO_LOCATION_SET"))
		end
	end
	
	-- Populate first page content
	if state.editPageEdit then
		local pageText = editSession.pages[1] or ""
		state.editPageEdit:SetText(pageText)
		-- Force the widget to refresh its display
		if state.editPageEdit.editBox then
			state.editPageEdit.editBox:SetText(pageText)
			state.editPageEdit.editBox:SetCursorPosition(0)
		end
	end
	
	-- Update page indicator
	if state.editPageIndicator then
		local totalPages = #editSession.pages
		state.editPageIndicator:SetText(t("PAGE") .. " 1 / " .. totalPages)
	end
	
	-- Update navigation buttons
	if state.editPrevBtn then
		state.editPrevBtn:SetEnabled(false)
	end
	if state.editNextBtn then
		state.editNextBtn:SetEnabled(#editSession.pages > 1)
	end
end

-- Show edit UI, hide reader content
function EditMode:ShowEditUI()
	-- Hide normal reader content
	if state.textScroll then state.textScroll:Hide() end
	if state.textScrollBar then state.textScrollBar:Hide() end
	if state.emptyStateFrame then state.emptyStateFrame:Hide() end
	
	-- Update book title in header
	if state.bookTitle then
		state.bookTitle:SetText(t("NEW_BOOK"))
	end
	
	-- Hide location/echo text in header
	if state.echoText then state.echoText:Hide() end
	if state.metaDisplay then state.metaDisplay:Hide() end
	
	-- Hide page navigation (we have our own)
	if state.readerNavRow then state.readerNavRow:Hide() end
	
	-- Hide action buttons (favorite, share, delete)
	if state.favoriteButton then state.favoriteButton:Hide() end
	if state.shareButton then state.shareButton:Hide() end
	if state.deleteButton then state.deleteButton:Hide() end
	if state.customBookIcon then state.customBookIcon:Hide() end
	if state.editButton then state.editButton:Hide() end
	
	-- Show edit frame
	if state.editBookFrame then
		state.editBookFrame:Show()
	end
	
	-- Explicitly show the AceGUI edit box
	if state.editPageEdit and state.editPageEdit.frame then
		state.editPageEdit.frame:Show()
	end
	
	-- Refresh focus registration to include edit mode elements
	local FocusReg = BookArchivist.UI and BookArchivist.UI.FocusRegistration
	if FocusReg and FocusReg.Refresh then
		FocusReg:Refresh()
	end
end

-- Hide edit UI, show normal reader content
function EditMode:HideEditUI()
	if state.editBookFrame then
		state.editBookFrame:Hide()
	end
	
	editSession.isEditing = false
	
	-- Refresh focus registration to remove edit mode elements
	local FocusReg = BookArchivist.UI and BookArchivist.UI.FocusRegistration
	if FocusReg and FocusReg.Refresh then
		FocusReg:Refresh()
	end
	
	-- Restore normal reader UI
	if ReaderUI.RenderSelected then
		ReaderUI:RenderSelected()
	end
end

-- Use current player location
function EditMode:UseCurrentLocation()
	local Location = BookArchivist and BookArchivist.Location
	if not Location or not Location.BuildWorldLocation then
		return
	end
	
	local location = Location:BuildWorldLocation()
	if location then
		editSession.location = location
		
		-- Format location display using zoneText from BuildWorldLocation
		local locText = location.zoneText or ""
		
		if locText == "" then
			locText = t("UNKNOWN_LOCATION")
		end
		
		if state.editLocationDisplay then
			state.editLocationDisplay:SetText(locText)
			state.editLocationDisplay:SetTextColor(1, 0.82, 0)
		end
	end
end

-- Navigate between pages
function EditMode:NavigatePage(direction)
	local newIndex = editSession.currentPageIndex + direction
	if newIndex < 1 or newIndex > #editSession.pages then
		return
	end
	
	editSession.currentPageIndex = newIndex
	
	-- Load page content into editor
	local pageText = editSession.pages[newIndex] or ""
	if state.editPageEdit then
		state.editPageEdit:SetText(pageText)
	end
	
	self:UpdatePageIndicator()
	self:UpdateNavigationButtons()
end

-- Add a new blank page
function EditMode:AddPage()
	table.insert(editSession.pages, "")
	editSession.currentPageIndex = #editSession.pages
	
	-- Clear editor for new page
	if state.editPageEdit then
		state.editPageEdit:SetText("")
		-- Focus the editor
		if state.editPageEdit.editBox and state.editPageEdit.editBox.SetFocus then
			state.editPageEdit.editBox:SetFocus()
		end
	end
	
	self:UpdatePageIndicator()
	self:UpdateNavigationButtons()
	
	-- Success feedback
	if Internal and Internal.chatMessage then
		Internal.chatMessage("|cFF00FF00" .. (t("PAGE_ADDED") or "Page added") .. "|r")
	end
end

-- Update page indicator text
function EditMode:UpdatePageIndicator()
	if not state.editPageIndicator then
		return
	end
	
	local current = editSession.currentPageIndex
	local total = #editSession.pages
	state.editPageIndicator:SetText(t("PAGE") .. " " .. current .. " / " .. total)
end

-- Update navigation button enabled states
function EditMode:UpdateNavigationButtons()
	local current = editSession.currentPageIndex
	local total = #editSession.pages
	
	if state.editPrevPageBtn then
		state.editPrevPageBtn:SetEnabled(current > 1)
	end
	
	if state.editNextPageBtn then
		state.editNextPageBtn:SetEnabled(current < total)
	end
end

-- Save the book
function EditMode:SaveBook()
	-- Get title
	local title = state.editTitleBox and state.editTitleBox:GetText() or ""
	title = trim(title)
	
	if title == "" then
		-- Show error
		if state.editTitleBox then
			state.editTitleBox:SetFocus()
			UIFrameFlash(state.editTitleBox, 0.5, 0.5, 1.0, false, 0, 0)
		end
		if Internal and Internal.chatMessage then
			Internal.chatMessage("|cFFFF0000" .. (t("BOOK_TITLE_REQUIRED") or "Please enter a book title") .. "|r")
		end
		return
	end
	
	-- Check that at least one page has content
	local hasContent = false
	for i, pageText in ipairs(editSession.pages) do
		if trim(pageText) ~= "" then
			hasContent = true
			break
		end
	end
	
	if not hasContent then
		if Internal and Internal.chatMessage then
			Internal.chatMessage("|cFFFF0000" .. (t("BOOK_CONTENT_REQUIRED") or "Please write some content in at least one page") .. "|r")
		end
		return
	end
	
	-- Save the book using Core service methods (Step 3: UI uses Core, not DB)
	local Core = BookArchivist and BookArchivist.Core
	if not Core then
		if Internal and Internal.chatMessage then
			Internal.chatMessage("|cFFFF0000" .. (t("BOOK_SAVE_FAILED") or "Failed to save book") .. "|r")
		end
		return
	end
	
	local bookId = editSession.bookId
	local success = false
	local errorMsg = nil
	
	if bookId then
		-- Update existing book via aggregate
		success, errorMsg = Core:UpdateBook(bookId, function(book)
			-- Update title
			local titleSuccess, titleErr = book:SetTitle(title)
			if not titleSuccess then
				error("Failed to set title: " .. (titleErr or "unknown error"))
			end
			
			-- Update pages
			for i, pageText in ipairs(editSession.pages) do
				local pageSuccess, pageErr = book:SetPageText(i, pageText)
				if not pageSuccess then
					error("Failed to set page " .. i .. ": " .. (pageErr or "unknown error"))
				end
			end
			
			-- Update location
			if editSession.location then
				local locSuccess, locErr = book:SetLocation(editSession.location)
				if not locSuccess then
					error("Failed to set location: " .. (locErr or "unknown error"))
				end
			end
		end)
	else
		-- Create new book via Core service
		bookId, errorMsg = Core:CreateCustomBook(
			title,
			editSession.pages,
			UnitName("player"),
			editSession.location
		)
		success = (bookId ~= nil)
	end
	
	if not success or not bookId then
		if Internal and Internal.chatMessage then
			local msg = t("BOOK_SAVE_FAILED") or "Failed to save book"
			if errorMsg then
				msg = msg .. ": " .. errorMsg
			end
			Internal.chatMessage("|cFFFF0000" .. msg .. "|r")
		end
		return
	end
	
	-- Success!
	if Internal and Internal.chatMessage then
		Internal.chatMessage("|cFF00FF00" .. (t("BOOK_SAVED_SUCCESS") or "Book saved successfully!") .. "|r")
	end
	
	-- Close edit mode
	self:HideEditUI()
	
	-- Refresh UI and select the new book
	if BookArchivist and BookArchivist.RefreshUI then
		BookArchivist:RefreshUI()
	end
	
	local listUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
	if listUI then
		if listUI.SetSelectedKey then
			listUI:SetSelectedKey(bookId)
		end
		if listUI.NotifySelectionChanged then
			listUI:NotifySelectionChanged()
		end
	end
end

-- Cancel editing
function EditMode:Cancel()
	self:HideEditUI()
end

-- Preview current page with TTS (accessibility feature)
function EditMode:PreviewTTS()
	local TTS = BookArchivist and BookArchivist.TTS
	if not TTS then
		if Internal and Internal.chatMessage then
			Internal.chatMessage("|cFFFF0000" .. (t("READER_TTS_UNAVAILABLE") or "Text-to-speech is not available.") .. "|r")
		end
		return
	end
	
	if not TTS:IsSupported() then
		if Internal and Internal.chatMessage then
			Internal.chatMessage("|cFFFF0000" .. (t("TTS_ENABLE_HINT") or "Enable Text-to-Speech in WoW Settings > Accessibility.") .. "|r")
		end
		return
	end
	
	-- If already speaking, stop
	if TTS:IsSpeaking() then
		TTS:Stop()
		-- Update button text
		if state.editTTSPreviewBtn then
			state.editTTSPreviewBtn:SetText(t("TTS_PREVIEW") or "Preview")
		end
		return
	end
	
	-- Get current page text
	local pageText = editSession.pages[editSession.currentPageIndex] or ""
	if trim(pageText) == "" then
		if Internal and Internal.chatMessage then
			Internal.chatMessage("|cFFFFFF00" .. (t("TTS_PREVIEW_EMPTY") or "Nothing to preview. Write some content first.") .. "|r")
		end
		return
	end
	
	-- Speak the page
	local success, err = TTS:Speak(pageText)
	if success then
		-- Update button text to show stop option
		if state.editTTSPreviewBtn then
			state.editTTSPreviewBtn:SetText(t("TTS_STOP_PREVIEW") or "Stop")
		end
	else
		if Internal and Internal.chatMessage then
			Internal.chatMessage("|cFFFF0000" .. (t("TTS_PREVIEW_FAILED") or "TTS preview failed: ") .. (err or "unknown error") .. "|r")
		end
	end
end

-- Hook into ReaderUI
ReaderUI.OpenCreateBook = function()
	EditMode:StartNewBook()
end

ReaderUI.CancelCreateBook = function()
	EditMode:Cancel()
end

ReaderUI.SaveCreateBook = function()
	EditMode:SaveBook()
end

---@diagnostic disable: undefined-global, undefined-field
local addonRoot = BookArchivist
if not addonRoot or not addonRoot.UI or not addonRoot.UI.Internal then
	return
end

local Internal = addonRoot.UI.Internal
local ListUI = Internal.ListUI
local ReaderUI = Internal.ReaderUI
local FrameUI = addonRoot.UI.Frame

local initializationError

local function syncGridOverlayPreference()
	if not Internal or not Internal.setGridOverlayVisible then
		return
	end
	local db
	if addonRoot and addonRoot.GetDB then
		db = addonRoot:GetDB()
	elseif BookArchivistDB then
		db = BookArchivistDB
	end
	local opts = db and db.options or nil
	local wantsDebug = opts and opts.uiDebug and true or false
	Internal.setGridOverlayVisible(wantsDebug)
end

local function debugPrint(...)
	BookArchivist:DebugPrint(...)
end

local function debugMessage(msg)
	BookArchivist:DebugMessage(msg)
end

local function logError(msg)
	BookArchivist:LogError(msg)
end

local function buildFrame(safeCreateFrame)
	if not FrameUI then
		return nil, "BookArchivist frame UI builder missing."
	end

	local builder = FrameUI.Create or FrameUI.CreateFrame
	if type(builder) ~= "function" then
		return nil, "BookArchivist frame UI builder missing."
	end
	local opts = {
		parent = UIParent,
		safeCreateFrame = safeCreateFrame,
		listUI = ListUI,
		readerUI = ReaderUI,
		title = (BookArchivist and BookArchivist.L and BookArchivist.L["ADDON_TITLE"]) or "Book Archivist",
		getPreferredListWidth = function()
			if addonRoot and addonRoot.GetListWidth then
				return addonRoot:GetListWidth()
			end
			return 360
		end,
		onListWidthChanged = function(width)
			if addonRoot and addonRoot.SetListWidth then
				addonRoot:SetListWidth(width)
			end
		end,
		debugPrint = debugPrint,
		logError = logError,
		onOptions = function()
			if addonRoot and type(addonRoot.OpenOptionsPanel) == "function" then
				addonRoot:OpenOptionsPanel()
			end
		end,
		onShow = function()
			local refreshFn = Internal.refreshAll
			if refreshFn then
				refreshFn()
			end
		end,
	}

	return builder(FrameUI, opts)
end

local function setupUI()
	local existing = Internal.getUIFrame()
	if existing then
		debugMessage("|cFF00FF00BookArchivist UI (setupUI) already initialized.|r")
		return true
	end

	if not CreateFrame or not UIParent then
		return false, "Blizzard UI not ready yet. Please try again after entering the world."
	end

	local safeCreateFrame = Internal.safeCreateFrame or CreateFrame
	local frame, err = buildFrame(safeCreateFrame)
	if not frame then
		return false, err or "Unable to create BookArchivist frame."
	end

	Internal.setUIFrame(frame)
	syncGridOverlayPreference()
	if Internal.updateListModeUI then
		Internal.updateListModeUI()
	end

	Internal.setIsInitialized(true)
	frame.__BookArchivistInitialized = true
	if Internal.requestFullRefresh then
		Internal.requestFullRefresh()
	else
		Internal.setNeedsRefresh(true)
	end
	debugPrint("[BookArchivist] setupUI: finished, pending refresh")
	if Internal.flushPendingRefresh then
		Internal.flushPendingRefresh()
	end
	return true
end

Internal.setupUI = setupUI

-- Applies the current language to existing UI without tearing down frames.
-- This avoids re-creating named frames (which can fail in WoW) while still
-- forcing a full refresh of dynamic strings.
local function rebuildUIForLanguageChange()
	if not Internal.getUIFrame then
		return
	end

	local ui = Internal.getUIFrame()
	if not ui then
		-- UI not yet created; future setup will use the new locale.
		return
	end

	local L = BookArchivist and BookArchivist.L or {}
	local function t(key)
		return (L and L[key]) or key
	end

	-- Update the main frame title.
	local title = t("ADDON_TITLE")
	if FrameUI and FrameUI.ConfigureTitle then
		FrameUI.ConfigureTitle(ui, title)
	elseif ui.TitleText and ui.TitleText.SetText then
		ui.TitleText:SetText(title)
	end

	-- Update list header title if the list UI has been created.
	if ListUI and ListUI.GetFrame then
		local headerTitle = ListUI:GetFrame("headerTitle")
		if headerTitle and headerTitle.SetText then
			headerTitle:SetText(title)
		end

		-- Update list tabs text.
		local booksTab = ListUI:GetFrame("booksTabButton")
		if booksTab and booksTab.SetText then
			booksTab:SetText(t("BOOKS_TAB"))
			if booksTab.Text and PanelTemplates_TabResize then
				PanelTemplates_TabResize(booksTab, 0)
			end
		end
		local locationsTab = ListUI:GetFrame("locationsTabButton")
		if locationsTab and locationsTab.SetText then
			locationsTab:SetText(t("LOCATIONS_TAB"))
			if locationsTab.Text and PanelTemplates_TabResize then
				PanelTemplates_TabResize(locationsTab, 0)
			end
		end

		-- Update header buttons (Help/Options).
		local optionsButton = ListUI:GetFrame("optionsButton")
		if optionsButton and optionsButton.SetText then
			optionsButton:SetText(t("HEADER_BUTTON_OPTIONS"))
		end
		local helpButton = ListUI:GetFrame("helpButton")
		if helpButton and helpButton.SetText then
			helpButton:SetText(t("HEADER_BUTTON_HELP"))
		end
		local resumeButton = ListUI:GetFrame("resumeButton")
		if resumeButton and resumeButton.SetText then
			resumeButton:SetText(t("RESUME_LAST_BOOK"))
		end

		-- Update list pagination button labels.
		local listPrev = ListUI:GetFrame("pagePrevButton")
		local listNext = ListUI:GetFrame("pageNextButton")
		local listPageLabel = ListUI:GetFrame("pageLabel")
		if listPrev and listPrev.SetText then
			listPrev:SetText(t("PAGINATION_PREV"))
		end
		if listNext and listNext.SetText then
			listNext:SetText(t("PAGINATION_NEXT"))
		end
		if listPageLabel and listPageLabel.SetText then
			listPageLabel:SetText(t("PAGINATION_PAGE_SINGLE"))
		end

		-- Update sort dropdown label.
		local sortDropdown = ListUI:GetFrame("sortDropdown")
		if sortDropdown and UIDropDownMenu_SetText then
			ListUI:UpdateSortDropdown()
		end
	end

	-- Update reader navigation labels if the reader UI exists.
	if ReaderUI and ReaderUI.__state then
		local rstate = ReaderUI.__state
		local prev = rstate.prevButton or (ReaderUI.__getWidget and ReaderUI.__getWidget("prevButton"))
		local nextBtn = rstate.nextButton or (ReaderUI.__getWidget and ReaderUI.__getWidget("nextButton"))
		local pageIndicator = rstate.pageIndicator or (ReaderUI.__getWidget and ReaderUI.__getWidget("pageIndicator"))
		if prev and prev.SetText then
			prev:SetText(t("PAGINATION_PREV"))
		end
		if nextBtn and nextBtn.SetText then
			nextBtn:SetText(t("PAGINATION_NEXT"))
		end
		if pageIndicator and pageIndicator.SetText then
			pageIndicator:SetText(t("PAGINATION_PAGE_SINGLE"))
		end

		-- If no book is selected, ensure the empty prompt is localized.
		local getSelectedKeyFn = ReaderUI.__getSelectedKey
		local selectedKey = getSelectedKeyFn and getSelectedKeyFn() or nil
		if not selectedKey then
			local bookTitle = rstate.bookTitle or (ReaderUI.__getWidget and ReaderUI.__getWidget("bookTitle"))
			if bookTitle and bookTitle.SetText then
				bookTitle:SetText(t("READER_EMPTY_PROMPT"))
			end
		end

		-- Update reader delete button text.
		local deleteBtn = rstate.deleteButton or (ReaderUI.__getWidget and ReaderUI.__getWidget("deleteBtn"))
		if deleteBtn and deleteBtn.SetText then
			deleteBtn:SetText(t("READER_DELETE_BUTTON"))
		end
	end

	-- Schedule and flush a full UI refresh so that all
	-- dynamically formatted labels pick up the new locale.
	if Internal.requestFullRefresh then
		Internal.requestFullRefresh()
	elseif Internal.setNeedsRefresh then
		Internal.setNeedsRefresh(true)
	end
	if Internal.flushPendingRefresh then
		Internal.flushPendingRefresh()
	end
end

Internal.rebuildUIForLanguageChange = rebuildUIForLanguageChange

local function ensureUI()
	local ui = Internal.getUIFrame()
	if ui then
		if not Internal.getIsInitialized() then
			debugPrint("[BookArchivist] ensureUI: repairing missing initialization flag")
			Internal.setIsInitialized(true)
		end
		syncGridOverlayPreference()
		debugPrint(string.format(
			"[BookArchivist] ensureUI: already initialized (isInitialized=%s needsRefresh=%s)",
			tostring(Internal.getIsInitialized()),
			tostring(Internal.getNeedsRefresh())
		))
		if Internal.flushPendingRefresh then
			Internal.flushPendingRefresh()
		end
		return true
	end

	if Internal.chatMessage then
		Internal.chatMessage("|cFFFFFF00BookArchivist UI not initialized, creating...|r")
	end

	local ok, err = setupUI()
	if not ok then
		initializationError = err or "BookArchivist UI failed to initialize."
		return false, initializationError
	end

	initializationError = nil
	Internal.setIsInitialized(true)
	syncGridOverlayPreference()
	debugPrint("[BookArchivist] ensureUI: initialized via setup (needsRefresh=" .. tostring(Internal.getNeedsRefresh()) .. ")")
	if Internal.getNeedsRefresh() and Internal.flushPendingRefresh then
		Internal.flushPendingRefresh()
	end
	return true
end

Internal.ensureUI = ensureUI

-- Apply list width (called from options slider)
function FrameUI:ApplyListWidth(width)
	if not width or type(width) ~= "number" then
		return
	end
	
	-- Get the main frame
	local frame = Internal.getMainFrame and Internal.getMainFrame()
	if not frame then
		return
	end
	
	-- Update the contentContainer's listWidth
	if frame.contentContainer then
		frame.contentContainer.listWidth = width
		
		-- Trigger layout refresh
		if frame.contentContainer.DoLayout then
			frame.contentContainer:DoLayout()
		end
		
		-- Call onListWidthChanged callback if it exists
		if frame.contentContainer.onListWidthChanged then
			frame.contentContainer.onListWidthChanged(width)
		end
	end
end

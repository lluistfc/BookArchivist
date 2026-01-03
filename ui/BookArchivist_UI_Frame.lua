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
		title = "Book Archivist",
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
	if Internal.updateListModeUI then
		Internal.updateListModeUI()
	end

	Internal.setIsInitialized(true)
	frame.__BookArchivistInitialized = true
	Internal.setNeedsRefresh(true)
	debugPrint("[BookArchivist] setupUI: finished, pending refresh")
	if Internal.flushPendingRefresh then
		Internal.flushPendingRefresh()
	end
	return true
end

Internal.setupUI = setupUI

local function ensureUI()
	local ui = Internal.getUIFrame()
	if ui then
		if not Internal.getIsInitialized() then
			debugPrint("[BookArchivist] ensureUI: repairing missing initialization flag")
			Internal.setIsInitialized(true)
		end
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
	debugPrint("[BookArchivist] ensureUI: initialized via setup (needsRefresh=" .. tostring(Internal.getNeedsRefresh()) .. ")")
	if Internal.getNeedsRefresh() and Internal.flushPendingRefresh then
		Internal.flushPendingRefresh()
	end
	return true
end

Internal.ensureUI = ensureUI

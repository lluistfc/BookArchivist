---@diagnostic disable: undefined-global, undefined-field
-- Shared layout helpers for the main Book Archivist frame.

BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local FrameUI = BookArchivist.UI.Frame or {}
BookArchivist.UI.Frame = FrameUI
local Internal = BookArchivist.UI.Internal

local Metrics = BookArchivist.UI.Metrics or {
	PAD = 12,
	PAD_OUTER = 12,
	PAD_INSET = 10,
	GUTTER = 10,
	GAP_S = 6,
	GAP_M = 10,
	SEPARATOR_W = 10,
	SEPARATOR_GAP = 6,
}

local DEFAULT_WIDTH = FrameUI.DEFAULT_WIDTH or 1080
local MIN_LIST_WIDTH = 260
local MIN_READER_WIDTH = 640

local function resolveSafeCreateFrame(override)
	if type(override) == "function" then
		return override
	end
	if Internal and type(Internal.safeCreateFrame) == "function" then
		return Internal.safeCreateFrame
	end
	if type(CreateFrame) == "function" then
		return CreateFrame
	end
	return nil
end

local function ClearAnchors(frame, resetSize)
	if not frame then
		return
	end
	if frame.ClearAllPoints then
		frame:ClearAllPoints()
	end
	if resetSize and frame.SetSize then
		frame:SetSize(1, 1)
	end
end

local function CreateContainer(name, parent, template, override)
	local safeCreateFrame = resolveSafeCreateFrame(override)
	if not safeCreateFrame or not parent then
		return nil
	end
	return safeCreateFrame("Frame", name, parent, template)
end

local function CreateRow(name, parent, height, template, override)
	local row = CreateContainer(name, parent, template, override)
	if row and height then
		row:SetHeight(height)
	end
	return row
end

FrameUI.CreateContainer = FrameUI.CreateContainer or CreateContainer
FrameUI.CreateRow = FrameUI.CreateRow or CreateRow
FrameUI.ClearAnchors = FrameUI.ClearAnchors or ClearAnchors
if Internal then
	Internal.CreateContainer = Internal.CreateContainer or CreateContainer
	Internal.CreateRow = Internal.CreateRow or CreateRow
	Internal.ClearAnchors = Internal.ClearAnchors or ClearAnchors
end

local function clampListWidth(container, width)
	local padOuter = Metrics.PAD_OUTER or Metrics.PAD or 12
	local gapBetweenPanels = Metrics.GAP_M or Metrics.GUTTER or 10
	local available = (container and container:GetWidth()) or (DEFAULT_WIDTH - (padOuter * 2))
	-- Available space minus the gap and minimum reader width
	local usable = available - gapBetweenPanels - MIN_READER_WIDTH
	local maxWidth = math.max(MIN_LIST_WIDTH, usable)
	return math.max(MIN_LIST_WIDTH, math.min(width, maxWidth))
end



local function createContentLayout(frame, safeCreateFrame, opts)
	local createHeaderBar = FrameUI.CreateHeaderBar
	local header = frame.HeaderFrame or (createHeaderBar and createHeaderBar(frame, safeCreateFrame))
	if not header then
		return nil
	end
	local body = safeCreateFrame("Frame", nil, frame)
	if not body then
		return nil
	end
	local padOuter = Metrics.PAD_OUTER or Metrics.PAD or 12
	local padInset = Metrics.PAD_INSET or Metrics.PAD or 10
	local bodyGap = Metrics.GAP_M or Metrics.GUTTER or 10
	ClearAnchors(body)
	body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -bodyGap)
	body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padOuter, padOuter)
	frame.ContentFrame = body
	frame.BodyFrame = body
	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("body", body)
	end

	local listInset = safeCreateFrame("Frame", nil, body, "InsetFrameTemplate3")
	local readerInset = safeCreateFrame("Frame", nil, body, "InsetFrameTemplate3")
	if not listInset or not readerInset then
		return nil
	end

	-- Fixed list width (no resize functionality)
	local fixedListWidth = opts.getPreferredListWidth and opts.getPreferredListWidth() or 360
	fixedListWidth = clampListWidth(body, fixedListWidth)
	
	-- Gap between the two panels
	local gapBetweenPanels = Metrics.GAP_M or Metrics.GUTTER or 10

	-- Position list inset on the left, flush to body edges
	ClearAnchors(listInset)
	listInset:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
	listInset:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 0, 0)
	listInset:SetWidth(fixedListWidth)

	-- Position reader inset on the right, flush to body edges
	ClearAnchors(readerInset)
	readerInset:SetPoint("TOPLEFT", body, "TOPLEFT", fixedListWidth + gapBetweenPanels, 0)
	readerInset:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)

	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("list-inset", listInset)
		Internal.registerGridTarget("reader-inset", readerInset)
	end

	frame.listBlock = listInset
	frame.ListInset = listInset
	frame.readerBlock = readerInset
	frame.ReaderInset = readerInset
	frame.currentListWidth = fixedListWidth

	return true
end

local function attachListUI(listUI, frame, listWrapper)
	if not listUI or type(listUI.Create) ~= "function" then
		return
	end
	
	-- Use the wrapper frame (traditional frame inside AceGUI container)
	local listContainer = listWrapper or frame
	
	local ok, err = pcall(listUI.Create, listUI, listContainer)
	if not ok and BookArchivist and BookArchivist.LogError then
		BookArchivist:LogError("BookArchivist list UI failed: " .. tostring(err))
	end
end

local function attachReaderUI(readerUI, listUI, frame, readerWrapper)
	if not readerUI or type(readerUI.Create) ~= "function" then
		return
	end
	
	-- Use the wrapper frame (traditional frame inside AceGUI container)
	local readerContainer = readerWrapper or frame
	
	-- CRITICAL: Do NOT pass list block as anchor to prevent cross-anchoring.
	-- Reader should fill readerContainer and be 100% wrapper-relative.
	local ok, err = pcall(readerUI.Create, readerUI, readerContainer, readerContainer)
	if not ok and BookArchivist and BookArchivist.LogError then
		BookArchivist:LogError("BookArchivist reader UI failed: " .. tostring(err))
	end
end

FrameUI.CreateContentLayout = FrameUI.CreateContentLayout or createContentLayout
FrameUI.AttachListUI = FrameUI.AttachListUI or attachListUI
FrameUI.AttachReaderUI = FrameUI.AttachReaderUI or attachReaderUI

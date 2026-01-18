---@diagnostic disable: undefined-global, undefined-field
-- BookArchivist_UI_Frame_Shell.lua
-- Minimal frame shell that appears instantly (<5ms) to prevent game freeze
-- Full content built asynchronously after shell is visible

local BA = BookArchivist
BA.UI = BA.UI or {}

local FrameUI = BA.UI.Frame or {}
BA.UI.Frame = FrameUI

-- Default dimensions
FrameUI.DEFAULT_WIDTH = FrameUI.DEFAULT_WIDTH or 1080
FrameUI.DEFAULT_HEIGHT = FrameUI.DEFAULT_HEIGHT or 680

--- Create minimal shell frame that appears instantly
--- No heavy widgets, just backdrop and loading indicator
--- @param opts table Options for frame creation
--- @return Frame|nil frame The shell frame
--- @return string|nil error Error message if creation failed
function FrameUI:CreateShell(opts)
	opts = opts or {}
	local parent = opts.parent or UIParent
	local safeCreateFrame = opts.safeCreateFrame or CreateFrame

	if type(safeCreateFrame) ~= "function" or not parent then
		return nil, "Blizzard UI not ready yet"
	end

	-- Create frame with PortraitFrameTemplate for proper styling
	-- This is actually fast enough (<10ms) and gives us the correct chrome
	local frame = safeCreateFrame("Frame", "BookArchivistFrame", parent, "PortraitFrameTemplate")
	if not frame then
		return nil, "Unable to create frame shell"
	end

	-- Basic size and position
	frame:SetSize(opts.width or FrameUI.DEFAULT_WIDTH, opts.height or FrameUI.DEFAULT_HEIGHT)
	frame:SetPoint(
		opts.anchorPoint or "CENTER",
		opts.anchorTarget or UIParent,
		opts.anchorRelativePoint or "CENTER",
		opts.offsetX or 0,
		opts.offsetY or 0
	)
	frame:Hide()

	-- PortraitFrameTemplate already has backdrop, just configure it
	-- No need to set custom backdrop, use the template's styling

	-- Make draggable (minimal overhead)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	-- Register with UISpecialFrames for ESC closing
	if type(UISpecialFrames) == "table" then
		local name = frame:GetName()
		if name then
			local alreadyRegistered = false
			for i = 1, #UISpecialFrames do
				if UISpecialFrames[i] == name then
					alreadyRegistered = true
					break
				end
			end
			if not alreadyRegistered then
				table.insert(UISpecialFrames, name)
			end
		end
	end

	-- Loading indicator (centered, highly visible)
	local loadingContainer = safeCreateFrame("Frame", nil, frame)
	loadingContainer:SetSize(600, 300)
	loadingContainer:SetPoint("CENTER")
	loadingContainer:SetFrameStrata("DIALOG") -- Keep above other elements
	frame.__loadingContainer = loadingContainer

	-- Add semi-transparent background for better visibility
	local loadingBg = loadingContainer:CreateTexture(nil, "BACKGROUND")
	loadingBg:SetAllPoints()
	loadingBg:SetColorTexture(0, 0, 0, 0.7)

	local loadingText = loadingContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge2")
	loadingText:SetPoint("CENTER", 0, 30)
	loadingText:SetText("|cFFFFFF00Opening Book Archivist...|r")
	loadingText:SetJustifyH("CENTER")
	loadingText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
	frame.__loadingText = loadingText

	local progressText = loadingContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	progressText:SetPoint("TOP", loadingText, "BOTTOM", 0, -20)
	progressText:SetText("|cFF999999Initializing interface...|r")
	progressText:SetJustifyH("CENTER")
	progressText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	frame.__progressText = progressText

	-- PortraitFrameTemplate already provides CloseButton, TitleText, and PortraitContainer
	-- No need for temporary elements

	-- State flags
	frame.__isShell = true
	frame.__contentReady = false
	frame.__contentBuilding = false

	-- Add method to update progress from outside
	frame.UpdateLoadingProgress = function(stage, progress)
		FrameUI:UpdateLoadingProgress(frame, stage, progress)
	end

	frame.HideLoadingIndicator = function()
		FrameUI:HideLoadingIndicator(frame)
	end

	return frame
end

--- Update loading progress indicator
--- @param frame Frame The shell frame
--- @param stage string Stage name: "building", "filtering", "ready"
--- @param progress number|nil Progress (0-1) for percentage display
function FrameUI:UpdateLoadingProgress(frame, stage, progress)
	if not frame or not frame.__loadingText then
		return
	end

	local loadingText = frame.__loadingText
	local progressText = frame.__progressText

	local messages = {
		building = "Building interface...",
		filtering = "Loading books...",
		ready = "Ready!",
	}

	local msg = messages[stage] or "Loading..."
	loadingText:SetText("|cFFFFD700" .. msg .. "|r") -- Brighter gold

	if progressText then
		if stage == "filtering" and progress then
			local percent = math.floor(progress * 100)
			local color = percent < 50 and "|cFFFFAA00" or "|cFF00FF00" -- Orange -> Green
			progressText:SetText(string.format("%s%d%% complete|r", color, percent))
			progressText:Show()
		elseif stage == "ready" then
			progressText:SetText("|cFF00FF00Complete!|r")
			progressText:Show()
		elseif stage == "building" then
			progressText:SetText("|cFFAAAAAAPlease wait...|r")
			progressText:Show()
		else
			progressText:Hide()
		end
	end

	-- Hide loading indicator after brief delay when ready
	if stage == "ready" then
		local timerAfter = C_Timer and C_Timer.After
		if timerAfter then
			timerAfter(0.3, function()
				if frame.__loadingContainer then
					frame.__loadingContainer:Hide()
				end
			end)
		else
			-- Fallback: hide immediately if C_Timer not available
			if frame.__loadingContainer then
				frame.__loadingContainer:Hide()
			end
		end
	end
end

--- Hide loading indicator immediately
--- @param frame Frame The shell frame
function FrameUI:HideLoadingIndicator(frame)
	if frame and frame.__loadingContainer then
		frame.__loadingContainer:Hide()
		frame.__loadingContainer:SetAlpha(0)
		if frame.__loadingText then
			frame.__loadingText:Hide()
		end
		if frame.__progressText then
			frame.__progressText:Hide()
		end
	end
end

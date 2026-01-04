---@diagnostic disable: undefined-global, undefined-field
-- BookArchivist_UI_Frame_Builder.lua
-- Orchestrates construction of the main Book Archivist frame visuals
-- using helpers provided by the Frame_Chrome and Frame_Layout modules.

BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local FrameUI = BookArchivist.UI.Frame or {}
BookArchivist.UI.Frame = FrameUI

FrameUI.DEFAULT_WIDTH = FrameUI.DEFAULT_WIDTH or 1080
FrameUI.DEFAULT_HEIGHT = FrameUI.DEFAULT_HEIGHT or 680

function FrameUI:Create(opts)
	opts = opts or {}
	local parent = opts.parent or UIParent
	local safeCreateFrame = opts.safeCreateFrame or CreateFrame

	if type(safeCreateFrame) ~= "function" or not parent then
		return nil, "Blizzard UI not ready yet. Please try again after entering the world."
	end

	local frame = safeCreateFrame(
		"Frame",
		"BookArchivistFrame",
		parent,
		"PortraitFrameTemplate",
		"ButtonFrameTemplate"
	)
	if not frame then
		return nil, "Unable to create BookArchivist frame."
	end

	if type(UISpecialFrames) == "table" and frame.GetName then
		local name = frame:GetName()
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

	frame:SetSize(opts.width or FrameUI.DEFAULT_WIDTH, opts.height or FrameUI.DEFAULT_HEIGHT)
	frame:SetPoint(
		opts.anchorPoint or "CENTER",
		opts.anchorTarget or UIParent,
		opts.anchorRelativePoint or "CENTER",
		opts.offsetX or 0,
		opts.offsetY or 0
	)
	frame:Hide()

	if FrameUI.ConfigureDrag then
		FrameUI.ConfigureDrag(frame)
	end
	if FrameUI.ApplyPortrait then
		FrameUI.ApplyPortrait(frame)
	end
	if FrameUI.ConfigureTitle then
		FrameUI.ConfigureTitle(frame, opts.title)
	end
	if FrameUI.ConfigureOptionsButton then
		FrameUI.ConfigureOptionsButton(frame, safeCreateFrame, opts.onOptions)
	end
	if FrameUI.CreateHeaderBar then
		FrameUI.CreateHeaderBar(frame, safeCreateFrame)
	end
	if FrameUI.CreateContentLayout then
		FrameUI.CreateContentLayout(frame, safeCreateFrame, opts)
	end

	if FrameUI.AttachListUI then
		FrameUI.AttachListUI(opts.listUI, frame)
	end
	if FrameUI.AttachReaderUI then
		FrameUI.AttachReaderUI(opts.readerUI, opts.listUI, frame)
	end

	frame:SetScript("OnShow", function()
		if opts.debugPrint then
			opts.debugPrint("[BookArchivist] UI OnShow fired")
		end
		if type(opts.onShow) ~= "function" then
			return
		end
		local ok, err = pcall(opts.onShow, frame)
		if not ok and opts.logError then
			opts.logError("Error refreshing UI: " .. tostring(err))
		end
	end)

	if type(opts.onAfterCreate) == "function" then
		pcall(opts.onAfterCreate, frame)
	end

	if opts.debugPrint then
		opts.debugPrint("[BookArchivist] setupUI: creating BookArchivistFrame")
	end

	return frame
end

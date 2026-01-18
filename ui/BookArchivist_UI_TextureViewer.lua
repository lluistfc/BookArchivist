---@diagnostic disable: undefined-global, undefined-field
-- Texture viewer frame for displaying the book archivist edit texture

local BA = BookArchivist
BA.UI = BA.UI or {}

local TextureViewer = {}
BA.UI.TextureViewer = TextureViewer

local L = BA and BA.L or {}
local function t(key)
	return (L and L[key]) or key
end

local Internal = BA.UI.Internal

-- Frame reference
local textureViewerFrame = nil

local function createTextureViewerFrame()
	if textureViewerFrame then
		return textureViewerFrame
	end

	-- Create the main frame (1080x720 to match texture aspect ratio of 1536x1024)
	local frame = CreateFrame("Frame", "BookArchivistTextureViewer", UIParent, "PortraitFrameTemplate")
	frame:SetSize(1536, 1024)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	
	-- Configure portrait
	if frame.PortraitContainer and frame.PortraitContainer.portrait then
		frame.portrait = frame.PortraitContainer.portrait
		frame.portrait:SetTexture("Interface\\AddOns\\BookArchivist\\BookArchivist_logo_64x64.png")
	end
	
	-- Set title
	if frame.TitleText then
		frame.TitleText:SetText(t("TEXTURE_VIEWER"))
	end
	
	-- Make frame draggable
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)
	
	-- Configure close button
	if frame.CloseButton then
		frame.CloseButton:SetScript("OnClick", function()
			frame:Hide()
		end)
	end
	
	-- Create content area
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -75)
	content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
	
	-- Create texture display
	local texture = content:CreateTexture(nil, "ARTWORK")
	texture:SetAllPoints(content)
	texture:SetTexture("Interface\\AddOns\\BookArchivist\\media\\book_archivist_edit.tga")
	
	-- Store references
	frame.content = content
	frame.texture = texture
	
	-- Hide initially
	frame:Hide()
	
	textureViewerFrame = frame
	return frame
end

function TextureViewer:Show()
	local frame = createTextureViewerFrame()
	if frame then
		frame:Show()
	end
end

function TextureViewer:Hide()
	if textureViewerFrame then
		textureViewerFrame:Hide()
	end
end

function TextureViewer:Toggle()
	local frame = createTextureViewerFrame()
	if frame then
		if frame:IsShown() then
			frame:Hide()
		else
			frame:Show()
		end
	end
end

-- Export for global access
BookArchivist.ShowTextureViewer = function()
	TextureViewer:Show()
end

BookArchivist.ToggleTextureViewer = function()
	TextureViewer:Toggle()
end

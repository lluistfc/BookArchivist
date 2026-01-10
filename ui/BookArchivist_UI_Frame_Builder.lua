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

--- Create frame using two-phase approach: instant shell + async content
--- PHASE 1: Create minimal shell (instant, <5ms, no freeze)
--- PHASE 2: Build full content asynchronously (background, no freeze)
function FrameUI:Create(opts)
	opts = opts or {}
	
	-- PHASE 1: Create shell immediately (prevents freeze)
	local frame, err = self:CreateShell(opts)
	if not frame then
		return nil, err or "Unable to create frame shell"
	end
	
	-- Store opts for async build
	frame.__buildOpts = opts
	frame.__contentBuilding = true
	
	-- PHASE 2: Schedule async content build (yields to game engine)
	local timerAfter = C_Timer and C_Timer.After
	if timerAfter then
		timerAfter(0.05, function()
			self:BuildContent(frame, opts)
		end)
	else
		-- Fallback: build immediately if C_Timer not available
		-- (still better than old code - shell already shown)
		self:BuildContent(frame, opts)
	end
	
	return frame
end

--- Build full frame content asynchronously in chunks
--- Yields control to game engine between widget batches
function FrameUI:BuildContent(frame, opts)
	if not frame or not opts then
		return
	end
	
	local safeCreateFrame = opts.safeCreateFrame or CreateFrame
	local timerAfter = C_Timer and C_Timer.After
	
	-- Update loading indicator
	self:UpdateLoadingProgress(frame, "building")
	
	-- Define build steps (grouped into chunks)
	local steps = {
		-- Chunk 1: Apply portrait and title (PortraitFrameTemplate already exists from shell)
		function()
			if FrameUI.ApplyPortrait then
				FrameUI.ApplyPortrait(frame)
			end
			if FrameUI.ConfigureTitle then
				FrameUI.ConfigureTitle(frame, opts.title)
			end
		end,
		
		-- Chunk 2: Options button and header
		function()
			if FrameUI.ConfigureOptionsButton then
				FrameUI.ConfigureOptionsButton(frame, safeCreateFrame, opts.onOptions)
			end
		end,
		
		-- Chunk 3: Header bar
		function()
			if FrameUI.CreateHeaderBar then
				FrameUI.CreateHeaderBar(frame, safeCreateFrame)
			end
		end,
		
		-- Chunk 4: Content layout (list and reader panels)
		function()
			if FrameUI.CreateContentLayout then
				FrameUI.CreateContentLayout(frame, safeCreateFrame, opts)
			end
		end,
		
		-- Chunk 5: Attach UI modules
		function()
			if FrameUI.AttachListUI then
				FrameUI.AttachListUI(opts.listUI, frame)
			end
			if FrameUI.AttachReaderUI then
				FrameUI.AttachReaderUI(opts.readerUI, opts.listUI, frame)
			end
		end,
		
		-- Chunk 6: Final setup
		function()
			-- Configure OnShow handler
			frame:SetScript("OnShow", function()
				if opts.debugPrint then
					opts.debugPrint("[BookArchivist] UI OnShow fired")
				end
				
				-- Only refresh if content is ready
				if not frame.__contentReady then
					-- Content still building, defer refresh
					if timerAfter then
						timerAfter(0.1, function()
							if frame:IsShown() and frame.__contentReady and opts.onShow then
								local ok, err = pcall(opts.onShow, frame)
								if not ok and opts.logError then
									opts.logError("Error refreshing UI: " .. tostring(err))
								end
							end
						end)
					end
					return
				end
				
				-- Content ready, proceed with refresh
				if type(opts.onShow) == "function" then
					local ok, err = pcall(opts.onShow, frame)
					if not ok and opts.logError then
						opts.logError("Error refreshing UI: " .. tostring(err))
					end
				end
			end)
			
			if type(opts.onAfterCreate) == "function" then
				pcall(opts.onAfterCreate, frame)
			end
			
			if opts.debugPrint then
				opts.debugPrint("[BookArchivist] setupUI: async build complete")
			end
		end,
	}
	
	-- Execute steps asynchronously with yields
	local function runStep(index)
		if not frame or not frame:GetName() then
			-- Frame was destroyed during build
			return
		end
		
		if index > #steps then
			-- All content built successfully
			frame.__contentBuilding = false
			frame.__contentReady = true
			
			-- Mark UI as fully initialized now that content is ready
			local Internal = BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal
			if Internal and Internal.setIsInitialized then
				Internal.setIsInitialized(true)
			end
			
			-- Update list mode UI now that tabs exist
			if Internal and Internal.updateListModeUI then
				local ok, err = pcall(Internal.updateListModeUI)
				if not ok and opts.logError then
					opts.logError("Error updating list mode after build: " .. tostring(err))
				end
			end
			
			-- Show welcome panel immediately (before filtering starts)
			-- This ensures user sees something in the reader during loading
			local ReaderUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.Reader
			if ReaderUI and ReaderUI.RenderSelected then
				local ok, err = pcall(ReaderUI.RenderSelected, ReaderUI)
				if not ok and opts.logError then
					opts.logError("Error rendering welcome panel: " .. tostring(err))
				end
			end
			
			-- Trigger refresh now that content is ready (this will start async filtering)
			-- Call onShow to refresh the list with the newly created data provider
			if opts.onShow then
				local ok, err = pcall(opts.onShow, frame)
				if not ok and opts.logError then
					opts.logError("Error refreshing UI after build: " .. tostring(err))
				end
			end
			
			-- Hide loading overlay after content is ready
			if frame.HideLoadingIndicator then
				frame.HideLoadingIndicator()
			end
			
			return
		end
		
		-- Execute current step
		local ok, err = pcall(steps[index])
		if not ok then
			if opts.logError then
				opts.logError("Error building UI step " .. index .. ": " .. tostring(err))
			end
			-- Continue despite error
		end
		
		-- Schedule next step (yield every 2 steps to prevent freeze)
		if index % 2 == 0 and timerAfter then
			timerAfter(0.01, function() runStep(index + 1) end)
		else
			runStep(index + 1)
		end
	end
	
	-- Start async build
	runStep(1)
end

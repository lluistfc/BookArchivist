---@diagnostic disable: undefined-global
-- BookArchivist_EventHandler_spec.lua
-- Integration tests for event handler wiring in BookArchivist.lua
-- These tests verify that events are properly routed to module methods

local helper = dofile("Tests/test_helper.lua")

describe("BookArchivist Event Handler Integration", function()
	local eventFrame
	local captureBeginCalled, captureReadyCalled, captureClosedCalled
	
	before_each(function()
		-- Reset call tracking
		captureBeginCalled = false
		captureReadyCalled = false
		captureClosedCalled = false
		
		-- Setup namespace
		helper.setupNamespace()
		
		-- Create a simple mock frame
		eventFrame = {
			scripts = {},
			SetScript = function(self, event, callback)
				self.scripts[event] = callback
			end,
			GetScript = function(self, event)
				return self.scripts[event]
			end,
			RegisterEvent = function(self, event)
				-- No-op for tests
			end
		}
		
		-- Mock CreateFrame to return our event frame
		_G.CreateFrame = function(frameType, name, ...)
			if frameType == "Frame" then
				return eventFrame
			end
			-- Fallback for other frame types if needed
			return {
				SetScript = function() end,
				GetScript = function() end,
				RegisterEvent = function() end
			}
		end
		
		-- Load BookArchivist.lua (this registers events and creates handlers)
		helper.loadFile("core/BookArchivist.lua")
		
		-- Now load the Capture module
		helper.loadFile("core/BookArchivist_Capture.lua")
		
		-- Mock the Capture methods to track calls
		BookArchivist.Capture.OnBegin = function()
			captureBeginCalled = true
		end
		
		BookArchivist.Capture.OnReady = function()
			captureReadyCalled = true
		end
		
		BookArchivist.Capture.OnClosed = function()
			captureClosedCalled = true
		end
	end)
	
	after_each(function()
		BookArchivist = nil
		eventFrame = nil
	end)
	
	it("should register ITEM_TEXT_BEGIN event", function()
		assert.is_not_nil(eventFrame)
		
		-- Verify event is registered by checking if handler exists
		local script = eventFrame:GetScript("OnEvent")
		assert.is_not_nil(script)
		assert.is_function(script)
	end)
	
	it("should route ITEM_TEXT_BEGIN to Capture:OnBegin", function()
		assert.is_not_nil(eventFrame)
		
		-- Simulate the event
		local script = eventFrame:GetScript("OnEvent")
		script(eventFrame, "ITEM_TEXT_BEGIN")
		
		-- Verify the Capture method was called
		assert.is_true(captureBeginCalled, "Capture:OnBegin should have been called")
		assert.is_false(captureReadyCalled, "Capture:OnReady should NOT have been called")
		assert.is_false(captureClosedCalled, "Capture:OnClosed should NOT have been called")
	end)
	
	it("should route ITEM_TEXT_READY to Capture:OnReady", function()
		assert.is_not_nil(eventFrame)
		
		-- Simulate the event
		local script = eventFrame:GetScript("OnEvent")
		script(eventFrame, "ITEM_TEXT_READY")
		
		-- Verify the Capture method was called
		assert.is_false(captureBeginCalled, "Capture:OnBegin should NOT have been called")
		assert.is_true(captureReadyCalled, "Capture:OnReady should have been called")
		assert.is_false(captureClosedCalled, "Capture:OnClosed should NOT have been called")
	end)
	
	it("should route ITEM_TEXT_CLOSED to Capture:OnClosed", function()
		assert.is_not_nil(eventFrame)
		
		-- Simulate the event
		local script = eventFrame:GetScript("OnEvent")
		script(eventFrame, "ITEM_TEXT_CLOSED")
		
		-- Verify the Capture method was called
		assert.is_false(captureBeginCalled, "Capture:OnBegin should NOT have been called")
		assert.is_false(captureReadyCalled, "Capture:OnReady should NOT have been called")
		assert.is_true(captureClosedCalled, "Capture:OnClosed should have been called")
	end)
	
	it("should handle full capture sequence", function()
		assert.is_not_nil(eventFrame)
		
		local script = eventFrame:GetScript("OnEvent")
		
		-- Simulate full sequence: BEGIN → READY → CLOSED
		script(eventFrame, "ITEM_TEXT_BEGIN")
		assert.is_true(captureBeginCalled, "BEGIN event should trigger OnBegin")
		
		script(eventFrame, "ITEM_TEXT_READY")
		assert.is_true(captureReadyCalled, "READY event should trigger OnReady")
		
		script(eventFrame, "ITEM_TEXT_CLOSED")
		assert.is_true(captureClosedCalled, "CLOSED event should trigger OnClosed")
	end)
	
	it("should gracefully handle missing Capture module", function()
		-- Remove the Capture module
		BookArchivist.Capture = nil
		
		local script = eventFrame:GetScript("OnEvent")
		
		-- Should not error when Capture is missing
		assert.has_no.errors(function()
			script(eventFrame, "ITEM_TEXT_BEGIN")
			script(eventFrame, "ITEM_TEXT_READY")
			script(eventFrame, "ITEM_TEXT_CLOSED")
		end)
	end)
	
	it("should use fully-qualified module references (not local variables)", function()
		-- This test verifies the fix for the bug we just found
		-- The event handler should reference BookArchivist.Capture, not a local Capture variable
		
		local script = eventFrame:GetScript("OnEvent")
		assert.is_not_nil(script)
		
		-- Get the function's source code
		local info = debug.getinfo(script, "S")
		assert.is_not_nil(info)
		
		-- The handler should work even if we don't have a local Capture variable
		-- (This would have failed with the old code that referenced undefined 'Capture')
		script(eventFrame, "ITEM_TEXT_BEGIN")
		assert.is_true(captureBeginCalled, "Should route to BookArchivist.Capture:OnBegin")
	end)
end)

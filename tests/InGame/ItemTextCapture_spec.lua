-- ItemTextCapture_spec.lua
-- In-game test for ItemText event capture system

describe("ItemText Capture", function()
	it("should have Capture module loaded", function()
		assert.is_not_nil(BookArchivist.Capture, "Capture module not loaded")
	end)

	it("should have event frame created", function()
		local frame = BookArchivist.Capture.frame
		assert.is_not_nil(frame, "Event frame not created")
	end)

	it("should have session state structure", function()
		assert.is_not_nil(BookArchivist.Capture.session, "Session state structure missing")
	end)

	it("should have Location module loaded for capture", function()
		assert.is_not_nil(BookArchivist.Location, "Location module not loaded (required for capture)")
	end)

	it("should have OnBegin handler", function()
		assert.is_not_nil(BookArchivist.Capture.OnBegin, "OnBegin handler missing")
		assert.equals("function", type(BookArchivist.Capture.OnBegin), "OnBegin should be a function")
	end)

	it("should have OnReady handler", function()
		assert.is_not_nil(BookArchivist.Capture.OnReady, "OnReady handler missing")
		assert.equals("function", type(BookArchivist.Capture.OnReady), "OnReady should be a function")
	end)

	it("should have OnClosed handler", function()
		assert.is_not_nil(BookArchivist.Capture.OnClosed, "OnClosed handler missing")
		assert.equals("function", type(BookArchivist.Capture.OnClosed), "OnClosed should be a function")
	end)

	it("should have Core persistence function", function()
		assert.is_not_nil(BookArchivist.Core, "Core module not loaded")
		assert.is_not_nil(BookArchivist.Core.PersistSession, "PersistSession function missing")
		assert.equals("function", type(BookArchivist.Core.PersistSession), "PersistSession should be a function")
	end)
end)

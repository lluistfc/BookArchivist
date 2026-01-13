-- BookEcho_spec.lua
-- Tests for BookArchivist.BookEcho (echo computation logic)

describe("BookEcho", function()
	local BookEcho, Repository, Core
	local testDB
	local mockTime = 1000000

	local function getInternal(name)
		assert(type(name) == "string", "upvalue name required")
		assert(BookEcho and BookEcho.GetEchoText, "BookEcho not initialized")
		local idx = 1
		while true do
			local upvalueName, value = debug.getupvalue(BookEcho.GetEchoText, idx)
			if not upvalueName then
				return nil
			end
			if upvalueName == name then
				return value
			end
			idx = idx + 1
		end
	end
	
	setup(function()
		-- Mock environment
		_G.BookArchivist = {}
		_G.time = function() return mockTime end
		
		-- Mock localization FIRST (before loading BookEcho)
		BookArchivist.L = {
			ECHO_FIRST_READ = "First discovered %s %s. Now, the book has returned to you.",
			ECHO_RETURNED = "You've returned to these pages %d times. Each reading leaves its mark.",
			ECHO_LAST_PAGE = "Left open at page %d. The rest of the tale awaits.",
			ECHO_LAST_OPENED = "Untouched for %s. Time has passed since last you turned these pages.",
			ECHO_TIME_DAYS = "%d days",
			ECHO_TIME_HOURS = "%d hours",
			ECHO_TIME_MINUTES = "%d minutes",
			LOC_CONTEXT_SHELVES = "among the shelves of",
			LOC_CONTEXT_ARCHIVES = "in the archives of",
			LOC_CONTEXT_DEPTHS = "in the depths of",
			LOC_CONTEXT_RUINS = "among the ruins of",
			LOC_CONTEXT_CANOPY = "beneath the canopy of",
			LOC_CONTEXT_SANDS = "in the sands of",
			LOC_CONTEXT_PEAKS = "high among the peaks of",
			LOC_CONTEXT_ABOARD = "aboard",
			LOC_CONTEXT_SHADOWS = "in the shadows of",
			LOC_CONTEXT_DEEP = "deep within",
			LOC_CONTEXT_WILDS = "across the wilds of",
			LOC_CONTEXT_SHORES = "along the shores of",
			LOC_CONTEXT_ISLE = "upon the isle of",
			LOC_CONTEXT_IN = "in",
		}
		
		-- Load dependencies
		dofile("./core/BookArchivist_Repository.lua")
		dofile("./core/BookArchivist_Core.lua")
		dofile("./core/BookArchivist_BookEcho.lua")
		
		Repository = BookArchivist.Repository
		Core = BookArchivist.Core
		BookEcho = BookArchivist.BookEcho
		
		-- Mock Core:Now for time calculations
		if Core then
			Core.Now = function() return mockTime end
		end
	end)
	
	before_each(function()
		-- Reset mock time
		mockTime = 1000000
		
		-- Create test database with v3 schema
		testDB = {
			dbVersion = 3,
			booksById = {},
			order = {},
			options = {},
			indexes = {
				objectToBookId = {},
			},
		}
		
		-- Initialize Repository with test database
		Repository:Init(testDB)
	end)
	
	after_each(function()
		-- Restore production database
		Repository:Init(_G.BookArchivistDB or {})
	end)
	
	describe("Priority: First reopen (readCount == 2)", function()
		it("should show first read location when readCount == 2", function()
			testDB.booksById["book1"] = {
				id = "book1",
				title = "Test Book",
				pages = { [1] = "Content" },
				readCount = 2,
				firstReadLocation = "Stormwind",
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("Stormwind"))
			assert.is_truthy(echo:find("returned to you"))
		end)
		
		it("should use 'among the shelves of' for cities like Stormwind", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 2,
				firstReadLocation = "Stormwind",
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_truthy(echo:find("among the shelves of"))
			assert.is_truthy(echo:find("Stormwind"))
		end)
		
		it("should use 'in the depths of' for caves and caverns", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 2,
				firstReadLocation = "Deepholm Cave",
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_truthy(echo:find("in the depths of"))
			assert.is_truthy(echo:find("Deepholm Cave"))
		end)
		
		it("should use 'among the ruins of' for temples and ruins", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 2,
				firstReadLocation = "Ahn'Qiraj Ruins",
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_truthy(echo:find("among the ruins of"))
			assert.is_truthy(echo:find("Ahn'Qiraj Ruins"))
		end)
		
		it("should use 'in the sands of' for deserts", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 2,
				firstReadLocation = "Silithus Desert",
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_truthy(echo:find("in the sands of"))
			assert.is_truthy(echo:find("Silithus Desert"))
		end)
		
		it("should use 'aboard' for ships and vessels", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 2,
				firstReadLocation = "The Skyfire Ship",
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_truthy(echo:find("aboard"))
			assert.is_truthy(echo:find("The Skyfire Ship"))
		end)
		
		it("should extract final zone from location chain", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 2,
				firstReadLocation = "Azeroth > Eastern Kingdoms > Stormwind City",
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			-- Should use only "Stormwind City", not the full chain
			assert.is_truthy(echo:find("Stormwind City"))
			assert.is_truthy(echo:find("among the shelves of"))
			-- Should NOT contain the full chain
			assert.is_falsy(echo:find("Azeroth >"))
			assert.is_falsy(echo:find("Eastern Kingdoms"))
		end)

		it("should fall back to raw location when parsing fails", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 2,
				firstReadLocation = "",
				pages = { [1] = "Content" },
			}

			local echo = BookEcho:GetEchoText("book1")
			assert.is_truthy(echo:find("First discovered in "))
			assert.is_truthy(echo:find("returned to you"))
			assert.is_truthy(echo:find("in %. Now"))
		end)
		
		it("should use 'in the shadows of' for dungeons and citadels", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 2,
				firstReadLocation = "Icecrown Citadel",
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_truthy(echo:find("in the shadows of"))
			assert.is_truthy(echo:find("Icecrown Citadel"))
		end)
		
		it("should use generic 'in' as fallback for unknown locations", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 2,
				firstReadLocation = "Unknown Zone",
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			-- Should not have any special phrases, just "in Unknown Zone"
			assert.is_falsy(echo:find("among the shelves"))
			assert.is_falsy(echo:find("in the depths"))
			assert.is_truthy(echo:find("Unknown Zone"))
		end)
		
		it("should handle missing firstReadLocation gracefully", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 2,
				firstReadLocation = nil,
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			-- Should skip to next priority (no echo for readCount == 2 without location)
			assert.is_nil(echo)
		end)
	end)
	
	describe("Priority: Multiple reads (readCount > 2)", function()
		it("should show read count when readCount > 2", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 5,
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("4 times")) -- readCount - 1
			assert.is_truthy(echo:find("Each reading leaves its mark"))
		end)
		
		it("should subtract 1 from readCount for accurate count", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 10,
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_truthy(echo:find("9 times"))
		end)
	end)
	
	describe("Priority: Resume state (lastPageRead < totalPages)", function()
		it("should show last page when lastPageRead < totalPages", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 1,
				lastPageRead = 4,
				pages = {
					[1] = "Page 1",
					[2] = "Page 2",
					[3] = "Page 3",
					[4] = "Page 4",
					[5] = "Page 5",
				},
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("Left open at page 4"))
			assert.is_truthy(echo:find("The rest of the tale awaits"))
		end)
		
		it("should not show when book fully read (lastPageRead == totalPages)", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 1,
				lastPageRead = 5,
				pages = {
					[1] = "Page 1",
					[2] = "Page 2",
					[3] = "Page 3",
					[4] = "Page 4",
					[5] = "Page 5",
				},
			}
			
			local echo = BookEcho:GetEchoText("book1")
			-- Should skip to next priority (recency)
			assert.is_nil(echo) -- No lastReadAt, so no fallback either
		end)
	end)
	
	describe("Priority: Recency (lastReadAt fallback)", function()
		it("should show time since last read as fallback", function()
			local now = 1000000
			local twoDaysAgo = now - (2 * 86400) -- 2 days in seconds
			mockTime = now
			
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 1,
				lastReadAt = twoDaysAgo,
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("2 days"))
			assert.is_truthy(echo:find("Time has passed"))
		end)
		
		it("should format time as hours when less than 1 day", function()
			local now = 1000000
			local fiveHoursAgo = now - (5 * 3600) -- 5 hours in seconds
			mockTime = now
			
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 1,
				lastReadAt = fiveHoursAgo,
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_truthy(echo:find("5 hours"))
		end)
		
		it("should format time as minutes when less than 1 hour", function()
			local now = 1000000
			local thirtyMinutesAgo = now - (30 * 60) -- 30 minutes in seconds
			mockTime = now
			
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 1,
				lastReadAt = thirtyMinutesAgo,
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_truthy(echo:find("30 minutes"))
		end)
	end)

	describe("Internal helpers", function()
		it("should fall back to generic context when location is missing", function()
			local getLocationContext = getInternal("getLocationContext")
			assert.is_function(getLocationContext)
			local phrase = getLocationContext(nil)
			assert.are.equal("in", phrase)
		end)
	end)
	
	describe("Edge cases", function()
		it("should return nil when no echo available", function()
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 0,
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			assert.is_nil(echo)
		end)
		
		it("should handle missing book data", function()
			local echo = BookEcho:GetEchoText("nonexistent")
			assert.is_nil(echo)
		end)
		
		it("should handle nil bookId", function()
			local echo = BookEcho:GetEchoText(nil)
			assert.is_nil(echo)
		end)
		
		it("should handle corrupted timestamps gracefully", function()
			mockTime = 1000000
			
			testDB.booksById["book1"] = {
				id = "book1",
				readCount = 1,
				lastReadAt = 9999999999, -- Future timestamp
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("book1")
			-- Should return nil for invalid time diff
			assert.is_nil(echo)
		end)
	end)
end)

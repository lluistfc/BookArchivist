-- BookEcho_Flow_spec.lua
-- Comprehensive flow tests for Book Echo feature - simulates actual user scenarios

describe("BookEcho Flow Scenarios", function()
	local BookEcho, Repository, Core
	local testDB
	local mockTime = 1000000
	
	setup(function()
		-- Mock environment
		_G.BookArchivist = {}
		_G.time = function() return mockTime end
		
		-- Mock localization
		BookArchivist.L = {
			ECHO_FIRST_READ = "First discovered %s %s. Now, the book has returned to you.",
			ECHO_RETURNED = "You've returned to these pages %d times. Each reading leaves its mark.",
			ECHO_LAST_PAGE = "Left open at page %d. The rest of the tale awaits.",
			ECHO_LAST_OPENED = "Untouched for %s. Time has passed since last you turned these pages.",
			ECHO_TIME_DAYS = "%d days",
			ECHO_TIME_HOURS = "%d hours",
			ECHO_TIME_MINUTES = "%d minutes",
			LOC_CONTEXT_SHELVES = "among the shelves of",
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
		mockTime = 1000000
		testDB = {
			dbVersion = 3,
			booksById = {},
			order = {},
			options = {},
			indexes = {
				objectToBookId = {},
			},
		}
		Repository:Init(testDB)
	end)
	
	after_each(function()
		Repository:Init(_G.BookArchivistDB or {})
	end)
	
	describe("Scenario 1: Reading a book for the first time", function()
		it("should show NO echo on first read (readCount 0→1)", function()
			-- Book exists but never been read
			testDB.booksById["newbook"] = {
				id = "newbook",
				title = "New Book",
				pages = { [1] = "Content" },
				readCount = 0, -- Not read yet
			}
			
			-- Calculate echo BEFORE incrementing
			local echo = BookEcho:GetEchoText("newbook")
			assert.is_nil(echo, "First read should have NO echo")
			
			-- Now simulate the increment that happens in UI
			testDB.booksById["newbook"].readCount = 1
			testDB.booksById["newbook"].firstReadLocation = "Stormwind"
			testDB.booksById["newbook"].lastReadAt = mockTime
			testDB.booksById["newbook"].lastPageRead = 1
			
			-- Still no echo after first read
			echo = BookEcho:GetEchoText("newbook")
			-- Should show recency fallback only if time has passed
			assert.is_nil(echo, "No echo immediately after first read (no time passed)")
		end)
	end)
	
	describe("Scenario 2: Reading a book until the end, then clicking it again", function()
		it("should show 'First discovered' echo on second read (readCount 1→2)", function()
			-- Book has been read once before
			testDB.booksById["finishedbook"] = {
				id = "finishedbook",
				title = "Finished Book",
				pages = { [1] = "Page 1", [2] = "Page 2", [3] = "Page 3" },
				readCount = 1,
				firstReadLocation = "Stormwind",
				lastReadAt = mockTime - 3600, -- 1 hour ago
				lastPageRead = 3, -- Finished all pages
			}
			
			-- Calculate echo BEFORE incrementing
			local echo = BookEcho:GetEchoText("finishedbook")
			-- Should show recency (Priority 4) since book is complete
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("Untouched"), "Should show recency before second read")
			
			-- Now simulate clicking it again (readCount 1→2)
			testDB.booksById["finishedbook"].readCount = 2
			testDB.booksById["finishedbook"].lastReadAt = mockTime
			
			-- BEFORE incrementing again, should show Priority 1
			echo = BookEcho:GetEchoText("finishedbook")
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("First discovered"), "Should show Priority 1: first reopen")
			assert.is_truthy(echo:find("Stormwind"), "Should mention location")
			assert.is_truthy(echo:find("returned to you"), "Should complete the phrase")
		end)
		
		it("should show 'Returned X times' on third+ read (readCount 2→3+)", function()
			-- Book has been read twice
			testDB.booksById["popularbook"] = {
				id = "popularbook",
				title = "Popular Book",
				pages = { [1] = "Content" },
				readCount = 2,
				firstReadLocation = "Stormwind",
				lastReadAt = mockTime - 7200, -- 2 hours ago
				lastPageRead = 1,
			}
			
			-- Calculate echo BEFORE incrementing to 3
			local echo = BookEcho:GetEchoText("popularbook")
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("First discovered"), "Should still show Priority 1 at readCount=2")
			
			-- Now simulate third read (readCount 2→3)
			testDB.booksById["popularbook"].readCount = 3
			testDB.booksById["popularbook"].lastReadAt = mockTime
			
			-- BEFORE incrementing again, should show Priority 2
			echo = BookEcho:GetEchoText("popularbook")
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("returned to these pages 2 times"), "Should show 'returned 2 times' (readCount-1)")
			assert.is_truthy(echo:find("Each reading leaves its mark"), "Should complete phrase")
			
			-- Simulate fourth read (readCount 3→4)
			testDB.booksById["popularbook"].readCount = 4
			echo = BookEcho:GetEchoText("popularbook")
			assert.is_truthy(echo:find("3 times"), "Should show 'returned 3 times'")
		end)
	end)
	
	describe("Scenario 3: Revisiting a book you've already read multiple times", function()
		it("should continue showing 'Returned X times' with increasing count", function()
			-- Book read 5 times already
			testDB.booksById["favbook"] = {
				id = "favbook",
				title = "Favorite Book",
				pages = { [1] = "Content" },
				readCount = 5,
				firstReadLocation = "Ironforge",
				lastReadAt = mockTime - 86400, -- 1 day ago
				lastPageRead = 1,
			}
			
			-- Calculate echo BEFORE incrementing to 6
			local echo = BookEcho:GetEchoText("favbook")
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("4 times"), "Should show readCount-1 = 4")
			
			-- Simulate sixth read
			testDB.booksById["favbook"].readCount = 6
			echo = BookEcho:GetEchoText("favbook")
			assert.is_truthy(echo:find("5 times"), "Should increment to 5 times")
			
			-- Simulate tenth read
			testDB.booksById["favbook"].readCount = 10
			echo = BookEcho:GetEchoText("favbook")
			assert.is_truthy(echo:find("9 times"), "Should show 9 times at readCount=10")
		end)
	end)
	
	describe("Scenario 4: Reading a multi-page book partially, then closing and reopening", function()
		it("should show 'Left open at page X' if stopped mid-book", function()
			-- Book with 5 pages, stopped at page 3
			testDB.booksById["longbook"] = {
				id = "longbook",
				title = "Long Book",
				pages = {
					[1] = "Page 1",
					[2] = "Page 2",
					[3] = "Page 3",
					[4] = "Page 4",
					[5] = "Page 5",
				},
				readCount = 1, -- Read once, but not finished
				firstReadLocation = "Dalaran",
				lastReadAt = mockTime - 1800, -- 30 minutes ago
				lastPageRead = 3, -- Stopped at page 3
			}
			
			-- Calculate echo BEFORE incrementing
			local echo = BookEcho:GetEchoText("longbook")
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("Left open at page 3"), "Should show resume state (Priority 3)")
			assert.is_truthy(echo:find("The rest of the tale awaits"), "Should complete phrase")
		end)
		
		it("should NOT show resume echo on first read (readCount must be > 0)", function()
			-- Book being read for first time, currently at page 2
			testDB.booksById["firstreadbook"] = {
				id = "firstreadbook",
				title = "First Read Book",
				pages = {
					[1] = "Page 1",
					[2] = "Page 2",
					[3] = "Page 3",
				},
				readCount = 0, -- First read in progress
				lastPageRead = 2, -- Currently at page 2
			}
			
			-- Calculate echo BEFORE incrementing
			local echo = BookEcho:GetEchoText("firstreadbook")
			assert.is_nil(echo, "Should NOT show resume echo on first read (readCount=0)")
		end)
		
		it("should NOT show resume echo when book is finished", function()
			-- Book read completely
			testDB.booksById["completebook"] = {
				id = "completebook",
				title = "Complete Book",
				pages = {
					[1] = "Page 1",
					[2] = "Page 2",
					[3] = "Page 3",
				},
				readCount = 1,
				firstReadLocation = "Orgrimmar",
				lastReadAt = mockTime - 3600,
				lastPageRead = 3, -- Finished all 3 pages
			}
			
			-- Calculate echo
			local echo = BookEcho:GetEchoText("completebook")
			-- Should skip Priority 3 (complete) and show Priority 4 (recency)
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("Untouched"), "Should show recency fallback")
			assert.is_falsy(echo:find("Left open"), "Should NOT show resume echo for complete book")
		end)
	end)
	
	describe("Scenario 5: Returning to a book after a long time", function()
		it("should show time since last read if no higher priority applies", function()
			-- Book read once, long time ago
			testDB.booksById["oldbook"] = {
				id = "oldbook",
				title = "Old Book",
				pages = { [1] = "Content" },
				readCount = 1,
				firstReadLocation = "Thunder Bluff",
				lastReadAt = mockTime - (7 * 86400), -- 7 days ago
				lastPageRead = 1,
			}
			
			-- Calculate echo
			local echo = BookEcho:GetEchoText("oldbook")
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("7 days"), "Should show time elapsed")
			assert.is_truthy(echo:find("Time has passed"), "Should show recency phrase")
		end)
	end)
	
	describe("Scenario 6: Page navigation within same book", function()
		it("should NOT affect echo or readCount when turning pages", function()
			-- Book at page 2 of 5
			testDB.booksById["activebook"] = {
				id = "activebook",
				title = "Active Book",
				pages = {
					[1] = "Page 1",
					[2] = "Page 2",
					[3] = "Page 3",
					[4] = "Page 4",
					[5] = "Page 5",
				},
				readCount = 2,
				firstReadLocation = "Undercity",
				lastReadAt = mockTime,
				lastPageRead = 2,
			}
			
			-- Get echo at page 2
			local echo1 = BookEcho:GetEchoText("activebook")
			assert.is_not_nil(echo1)
			assert.is_truthy(echo1:find("First discovered"), "Priority 1 at readCount=2")
			
			-- Simulate page turn (update lastPageRead, but NOT readCount)
			testDB.booksById["activebook"].lastPageRead = 3
			
			-- Echo should be EXACTLY the same
			local echo2 = BookEcho:GetEchoText("activebook")
			assert.are.equal(echo1, echo2, "Echo should not change on page turn")
			assert.is.equal(2, testDB.booksById["activebook"].readCount, "readCount should not increment on page turn")
			
			-- Turn to page 4
			testDB.booksById["activebook"].lastPageRead = 4
			local echo3 = BookEcho:GetEchoText("activebook")
			assert.are.equal(echo1, echo3, "Echo should still be the same")
		end)
	end)
	
	describe("Scenario 7: Re-selecting same book from list (with forceRefresh)", function()
		it("should increment readCount when clicking same book from list", function()
			-- This is handled by UI logic, but we can verify the echo progression
			testDB.booksById["testbook"] = {
				id = "testbook",
				title = "Test Book",
				pages = { [1] = "Content" },
				readCount = 1,
				firstReadLocation = "Stormwind",
				lastReadAt = mockTime,
				lastPageRead = 1,
			}
			
			-- First re-select (readCount 1→2)
			local echo1 = BookEcho:GetEchoText("testbook")
			-- Should show recency at readCount=1
			
			testDB.booksById["testbook"].readCount = 2
			local echo2 = BookEcho:GetEchoText("testbook")
			assert.is_truthy(echo2:find("First discovered"), "Should show Priority 1 at readCount=2")
			
			-- Second re-select (readCount 2→3)
			testDB.booksById["testbook"].readCount = 3
			local echo3 = BookEcho:GetEchoText("testbook")
			assert.is_truthy(echo3:find("2 times"), "Should show Priority 2 with count=2 at readCount=3")
			
			-- Third re-select (readCount 3→4)
			testDB.booksById["testbook"].readCount = 4
			local echo4 = BookEcho:GetEchoText("testbook")
			assert.is_truthy(echo4:find("3 times"), "Should show Priority 2 with count=3 at readCount=4")
		end)
	end)
	
	describe("Scenario 8: Priority hierarchy verification", function()
		it("Priority 1 should override Priority 3 when readCount=2", function()
			-- Book at readCount=2 with incomplete pages
			testDB.booksById["book"] = {
				id = "book",
				pages = { [1] = "P1", [2] = "P2", [3] = "P3" },
				readCount = 2,
				firstReadLocation = "Stormwind",
				lastPageRead = 1, -- Incomplete
			}
			
			local echo = BookEcho:GetEchoText("book")
			assert.is_truthy(echo:find("First discovered"), "Priority 1 should win over Priority 3")
			assert.is_falsy(echo:find("Left open"), "Should NOT show Priority 3")
		end)
		
		it("Priority 2 should override Priority 3 when readCount>2", function()
			-- Book at readCount=5 with incomplete pages
			testDB.booksById["book"] = {
				id = "book",
				pages = { [1] = "P1", [2] = "P2", [3] = "P3" },
				readCount = 5,
				firstReadLocation = "Stormwind",
				lastPageRead = 1, -- Incomplete
			}
			
			local echo = BookEcho:GetEchoText("book")
			assert.is_truthy(echo:find("4 times"), "Priority 2 should win over Priority 3")
			assert.is_falsy(echo:find("Left open"), "Should NOT show Priority 3")
		end)
		
		it("Priority 3 should show when readCount=1 and book incomplete", function()
			-- Book at readCount=1, stopped mid-way
			testDB.booksById["book"] = {
				id = "book",
				pages = { [1] = "P1", [2] = "P2", [3] = "P3" },
				readCount = 1,
				firstReadLocation = "Stormwind",
				lastPageRead = 2, -- Stopped at page 2
				lastReadAt = mockTime - 3600,
			}
			
			local echo = BookEcho:GetEchoText("book")
			assert.is_truthy(echo:find("Left open at page 2"), "Priority 3 should show")
		end)
		
		it("Priority 4 should be fallback when no other priority applies", function()
			-- Book at readCount=1, complete, with timestamp
			testDB.booksById["book"] = {
				id = "book",
				pages = { [1] = "P1" },
				readCount = 1,
				firstReadLocation = "Stormwind",
				lastPageRead = 1, -- Complete
				lastReadAt = mockTime - 7200, -- 2 hours ago
			}
			
			local echo = BookEcho:GetEchoText("book")
			assert.is_truthy(echo:find("2 hours"), "Priority 4 should show as fallback")
		end)
	end)
	
	describe("Scenario 9: Edge cases", function()
		it("should handle book with no history at all", function()
			testDB.booksById["newbook"] = {
				id = "newbook",
				title = "Brand New Book",
				pages = { [1] = "Content" },
			}
			
			local echo = BookEcho:GetEchoText("newbook")
			assert.is_nil(echo, "No echo for brand new book with no history")
		end)
		
		it("should handle single-page book progression", function()
			testDB.booksById["shortbook"] = {
				id = "shortbook",
				pages = { [1] = "Only page" },
				readCount = 0,
			}
			
			-- First read
			local echo = BookEcho:GetEchoText("shortbook")
			assert.is_nil(echo)
			
			-- Mark as read
			testDB.booksById["shortbook"].readCount = 1
			testDB.booksById["shortbook"].firstReadLocation = "Stormwind"
			testDB.booksById["shortbook"].lastPageRead = 1
			testDB.booksById["shortbook"].lastReadAt = mockTime - 3600
			
			-- Second read - should show Priority 1 (can't show Priority 3 because book is complete)
			echo = BookEcho:GetEchoText("shortbook")
			-- With readCount=1, no Priority 1 yet, should show Priority 4 (recency)
			assert.is_not_nil(echo)
			assert.is_truthy(echo:find("Untouched"))
			
			-- Increment to 2
			testDB.booksById["shortbook"].readCount = 2
			echo = BookEcho:GetEchoText("shortbook")
			assert.is_truthy(echo:find("First discovered"), "Should show Priority 1 at readCount=2")
		end)
	end)
end)

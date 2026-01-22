---@diagnostic disable: undefined-global
-- Book_spec.lua
-- Tests for the Book aggregate root - enforces invariants and encapsulates mutations

-- Load test helper
local helper = dofile("Tests/test_helper.lua")

describe("BookArchivist.Book", function()
	local Book
	
	before_each(function()
		helper.setupNamespace()
		helper.loadFile("core/BookArchivist_Book.lua")
		Book = BookArchivist.Book
	end)
	
	describe("Constructors", function()
		describe("NewCustom", function()
			it("should create a custom book with valid parameters", function()
				local book = Book.NewCustom("test-id-1", "Test Title", "Author Name")
				
				assert.are.equal("test-id-1", book:GetId())
				assert.are.equal("Test Title", book:GetTitle())
				assert.are.equal("Author Name", book:GetCreator())
				assert.are.equal("CUSTOM", book:GetSourceType())
				assert.is_true(book:IsEditable())
				assert.are.equal(1, book:GetPageCount())
			end)
			
			it("should trim whitespace from title and creator", function()
				local book = Book.NewCustom("test-id", "  Title  ", "  Creator  ")
				
				assert.are.equal("Title", book:GetTitle())
				assert.are.equal("Creator", book:GetCreator())
			end)
			
			it("should error if id is missing", function()
				assert.has_error(function()
					Book.NewCustom(nil, "Title", "Creator")
				end, "Book.NewCustom: id is required")
			end)
			
			it("should error if title is missing", function()
				assert.has_error(function()
					Book.NewCustom("test-id", "", "Creator")
				end, "Book.NewCustom: title is required")
			end)
			
			it("should start with one empty page", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				
				assert.are.equal(1, book:GetPageCount())
				assert.are.equal("", book:GetPageText(1))
			end)
		end)
		
		describe("CapturedFromEntry", function()
			it("should create a captured book from entry", function()
				local entry = {
					id = "cap-id-1",
					title = "Captured Book",
					creator = "Game NPC",
					material = "Parchment",
					pages = { "Page 1 text", "Page 2 text" },
					itemId = 12345,
					createdAt = 1000,
					updatedAt = 1000,
					firstSeenAt = 1000,
					lastSeenAt = 1000,
					isFavorite = false,
				}
				
				local book = Book.CapturedFromEntry(entry)
				
				assert.are.equal("cap-id-1", book:GetId())
				assert.are.equal("Captured Book", book:GetTitle())
				assert.are.equal("Game NPC", book:GetCreator())
				assert.are.equal("Parchment", book:GetMaterial())
				assert.are.equal("CAPTURED", book:GetSourceType())
				assert.is_false(book:IsEditable())
				assert.are.equal(2, book:GetPageCount())
				assert.are.equal("Page 1 text", book:GetPageText(1))
				assert.are.equal("Page 2 text", book:GetPageText(2))
				assert.are.equal(12345, book:GetItemId())
			end)
			
			it("should error if entry is not a table", function()
				assert.has_error(function()
					Book.CapturedFromEntry(nil)
				end, "Book.CapturedFromEntry: entry must be a table")
			end)
		end)
		
		describe("FromEntry", function()
			it("should detect captured books by itemId", function()
				local entry = {
					id = "test-id",
					title = "Test",
					creator = "NPC",
					pages = { "Page 1" },
					itemId = 123,
				}
				
				local book = Book.FromEntry(entry)
				
				assert.are.equal("CAPTURED", book:GetSourceType())
				assert.is_false(book:IsEditable())
			end)
			
			it("should detect captured books by objectId", function()
				local entry = {
					id = "test-id",
					title = "Test",
					creator = "NPC",
					pages = { "Page 1" },
					objectId = 456,
				}
				
				local book = Book.FromEntry(entry)
				
				assert.are.equal("CAPTURED", book:GetSourceType())
				assert.is_false(book:IsEditable())
			end)
			
			it("should detect custom books when no itemId or objectId", function()
				local entry = {
					id = "test-id",
					title = "Test",
					creator = "Player",
					pages = { "Page 1" },
				}
				
				local book = Book.FromEntry(entry)
				
				assert.are.equal("CUSTOM", book:GetSourceType())
				assert.is_true(book:IsEditable())
			end)
			
			it("should respect explicit sourceType field", function()
				local entry = {
					id = "test-id",
					title = "Test",
					creator = "Player",
					pages = { "Page 1" },
					sourceType = "CUSTOM",
				}
				
				local book = Book.FromEntry(entry)
				
				assert.are.equal("CUSTOM", book:GetSourceType())
			end)
		end)
	end)
	
	describe("Read operations", function()
		it("should return correct page count", function()
			local book = Book.NewCustom("test-id", "Title", "Creator")
			assert.are.equal(1, book:GetPageCount())
			
			book:SetPageText(2, "Page 2")
			assert.are.equal(2, book:GetPageCount())
		end)
		
		it("should return empty string for non-existent pages", function()
			local book = Book.NewCustom("test-id", "Title", "Creator")
			
			assert.are.equal("", book:GetPageText(99))
			assert.are.equal("", book:GetPageText(0))
			assert.are.equal("", book:GetPageText(-1))
		end)
		
		it("should return all pages as array", function()
			local book = Book.NewCustom("test-id", "Title", "Creator")
			book:SetPageText(1, "Page 1")
			book:SetPageText(2, "Page 2")
			
			local pages = book:GetPages()
			
			assert.are.equal(2, #pages)
			assert.are.equal("Page 1", pages[1])
			assert.are.equal("Page 2", pages[2])
		end)
		
		it("should return cloned location to prevent mutations", function()
			local entry = {
				id = "test-id",
				title = "Test",
				pages = { "Page 1" },
				location = { zoneText = "Stormwind", x = 10, y = 20 },
			}
			
			local book = Book.FromEntry(entry)
			local loc1 = book:GetLocation()
			local loc2 = book:GetLocation()
			
			-- Should be different tables
			assert.are_not.equal(loc1, loc2)
			-- But same content
			assert.are.equal(loc1.zoneText, loc2.zoneText)
		end)
	end)
	
	describe("Write operations - CUSTOM books", function()
		describe("SetTitle", function()
			it("should update title successfully", function()
				local book = Book.NewCustom("test-id", "Old Title", "Creator")
				
				local success = book:SetTitle("New Title")
				
				assert.is_true(success)
				assert.are.equal("New Title", book:GetTitle())
			end)
			
			it("should trim whitespace", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				
				book:SetTitle("  Trimmed  ")
				
				assert.are.equal("Trimmed", book:GetTitle())
			end)
			
			it("should reject empty title", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				
				local success, err = book:SetTitle("")
				
				assert.is_false(success)
				assert.are.equal("Title cannot be empty", err)
			end)
			
			it("should update timestamps", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				local originalUpdated = book:GetUpdatedAt()
				
				-- Mock time advance
				_G.time = function() return originalUpdated + 100 end
				
				book:SetTitle("New Title")
				
				assert.are.equal(originalUpdated + 100, book:GetUpdatedAt())
			end)
		end)
		
		describe("SetPageText", function()
			it("should set page text successfully", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				
				local success = book:SetPageText(1, "Page content")
				
				assert.is_true(success)
				assert.are.equal("Page content", book:GetPageText(1))
			end)
			
			it("should auto-expand pages array", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				
				book:SetPageText(5, "Page 5")
				
				assert.are.equal(5, book:GetPageCount())
				assert.are.equal("", book:GetPageText(2))
				assert.are.equal("", book:GetPageText(3))
				assert.are.equal("", book:GetPageText(4))
				assert.are.equal("Page 5", book:GetPageText(5))
			end)
			
			it("should reject invalid page numbers", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				
				local success, err = book:SetPageText(0, "Text")
				
				assert.is_false(success)
				assert.are.equal("Invalid page number", err)
			end)
		end)
		
		describe("AddPage", function()
			it("should add page at end by default", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				book:SetPageText(1, "Page 1")
				
				local success = book:AddPage()
				
				assert.is_true(success)
				assert.are.equal(2, book:GetPageCount())
				assert.are.equal("", book:GetPageText(2))
			end)
			
			it("should insert page after specified position", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				book:SetPageText(1, "Page 1")
				book:SetPageText(2, "Page 2")
				
				book:AddPage(1)
				
				assert.are.equal(3, book:GetPageCount())
			end)
		end)
		
		describe("RemovePage", function()
			it("should remove page successfully", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				book:SetPageText(1, "Page 1")
				book:SetPageText(2, "Page 2")
				
				local success = book:RemovePage(2)
				
				assert.is_true(success)
				assert.are.equal(1, book:GetPageCount())
			end)
			
			it("should not remove last page", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				
				local success, err = book:RemovePage(1)
				
				assert.is_false(success)
				assert.are.equal("Cannot remove last page", err)
			end)
		end)
		
		describe("SetFavorite", function()
			it("should set favorite flag", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				
				book:SetFavorite(true)
				assert.is_true(book:IsFavorite())
				
				book:SetFavorite(false)
				assert.is_false(book:IsFavorite())
			end)
		end)
		
		describe("MarkRead", function()
			it("should set lastReadAt timestamp", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				assert.is_nil(book:GetLastReadAt())
				
				book:MarkRead()
				
				assert.is_not_nil(book:GetLastReadAt())
			end)
		end)
	end)
	
	describe("Write operations - CAPTURED books (read-only)", function()
		it("should reject SetTitle on captured books", function()
			local entry = {
				id = "cap-id",
				title = "Captured",
				pages = { "Page 1" },
				itemId = 123,
			}
			local book = Book.CapturedFromEntry(entry)
			
			local success, err = book:SetTitle("New Title")
			
			assert.is_false(success)
			assert.are.equal("Cannot modify captured book", err)
		end)
		
		it("should reject SetPageText on captured books", function()
			local entry = {
				id = "cap-id",
				title = "Captured",
				pages = { "Page 1" },
				itemId = 123,
			}
			local book = Book.CapturedFromEntry(entry)
			
			local success, err = book:SetPageText(1, "Modified")
			
			assert.is_false(success)
			assert.are.equal("Cannot modify captured book", err)
		end)
		
		it("should reject AddPage on captured books", function()
			local entry = {
				id = "cap-id",
				title = "Captured",
				pages = { "Page 1" },
				itemId = 123,
			}
			local book = Book.CapturedFromEntry(entry)
			
			local success, err = book:AddPage()
			
			assert.is_false(success)
			assert.are.equal("Cannot modify captured book", err)
		end)
		
		it("should reject RemovePage on captured books", function()
			local entry = {
				id = "cap-id",
				title = "Captured",
				pages = { "Page 1", "Page 2" },
				itemId = 123,
			}
			local book = Book.CapturedFromEntry(entry)
			
			local success, err = book:RemovePage(1)
			
			assert.is_false(success)
			assert.are.equal("Cannot modify captured book", err)
		end)
		
		it("should allow SetFavorite on captured books", function()
			local entry = {
				id = "cap-id",
				title = "Captured",
				pages = { "Page 1" },
				itemId = 123,
			}
			local book = Book.CapturedFromEntry(entry)
			
			local success = book:SetFavorite(true)
			
			assert.is_true(success)
			assert.is_true(book:IsFavorite())
		end)
	end)
	
	describe("Serialization", function()
		describe("ToEntry", function()
			it("should convert custom book to entry", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				book:SetPageText(1, "Page 1")
				book:SetPageText(2, "Page 2")
				
				local entry = book:ToEntry()
				
				assert.are.equal("test-id", entry.id)
				assert.are.equal("CUSTOM", entry.sourceType)
				assert.are.equal("Title", entry.title)
				assert.are.equal("Creator", entry.creator)
				assert.are.equal(2, #entry.pages)
				assert.are.equal("Page 1", entry.pages[1])
				assert.are.equal("Page 2", entry.pages[2])
			end)
			
			it("should include searchText", function()
				local book = Book.NewCustom("test-id", "Adventure Book", "Creator")
				book:SetPageText(1, "Once upon a time")
				
				local entry = book:ToEntry()
				
				assert.is_not_nil(entry.searchText)
				-- string:find returns position (number) if found, nil if not found
				assert.is_not_nil(entry.searchText:find("adventure"))
				assert.is_not_nil(entry.searchText:find("once"))
			end)
			
			it("should round-trip correctly", function()
				local book1 = Book.NewCustom("test-id", "Title", "Creator")
				book1:SetPageText(1, "Page 1")
				book1:SetFavorite(true)
				
				local entry = book1:ToEntry()
				local book2 = Book.FromEntry(entry)
				
				assert.are.equal(book1:GetId(), book2:GetId())
				assert.are.equal(book1:GetTitle(), book2:GetTitle())
				assert.are.equal(book1:GetCreator(), book2:GetCreator())
				assert.are.equal(book1:GetPageCount(), book2:GetPageCount())
				assert.are.equal(book1:GetPageText(1), book2:GetPageText(1))
				assert.are.equal(book1:IsFavorite(), book2:IsFavorite())
			end)
		end)
	end)
	
	describe("Validation", function()
		describe("Validate", function()
			it("should pass for valid custom book", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				
				local valid, err = book:Validate()
				
				assert.is_true(valid)
				assert.is_nil(err)
			end)
			
			it("should pass for valid captured book", function()
				local entry = {
					id = "cap-id",
					title = "Captured",
					pages = { "Page 1" },
					itemId = 123,
				}
				local book = Book.CapturedFromEntry(entry)
				
				local valid, err = book:Validate()
				
				assert.is_true(valid)
				assert.is_nil(err)
			end)
			
			it("should enforce minimum one page", function()
				local book = Book.NewCustom("test-id", "Title", "Creator")
				-- Manually break invariant for testing
				book._pages = {}
				
				local valid, err = book:Validate()
				
				assert.is_false(valid)
				assert.are.equal("Book must have at least one page", err)
			end)
		end)
	end)
	
	describe("Invariants", function()
		it("should maintain contiguous page array", function()
			local book = Book.NewCustom("test-id", "Title", "Creator")
			
			book:SetPageText(5, "Page 5")
			
			-- Pages 2-4 should be auto-created as empty strings
			for i = 1, 5 do
				assert.is_not_nil(book:GetPageText(i))
			end
		end)
		
		it("should update searchText on content changes", function()
			local book = Book.NewCustom("test-id", "Original Title", "Creator")
			book:SetPageText(1, "Original content")
			
			local entry1 = book:ToEntry()
			local searchText1 = entry1.searchText
			
			book:SetTitle("New Title")
			
			local entry2 = book:ToEntry()
			local searchText2 = entry2.searchText
			
			assert.are_not.equal(searchText1, searchText2)
			-- string:find returns position (number) if found, nil if not found
			assert.is_not_nil(searchText2:find("new"))
		end)
	end)
end)

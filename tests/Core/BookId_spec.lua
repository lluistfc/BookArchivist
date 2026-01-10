-- BookId_spec.lua
-- Sandbox tests for BookArchivist BookId generation and parsing

describe("BookId.NormalizeText", function()
    it("converts to lowercase", function()
        local result = BookArchivist.BookId.NormalizeText("The New HORDE")
        assert.are.equal("the new horde", result)
    end)
    
    it("strips WoW color codes", function()
        local result = BookArchivist.BookId.NormalizeText("|cff00ff00Green|r Text")
        assert.are.equal("green text", result)
    end)
    
    it("strips texture tags", function()
        local result = BookArchivist.BookId.NormalizeText("Icon |T132345:16:16|t here")
        assert.are.equal("icon here", result)
    end)
    
    it("collapses whitespace", function()
        local result = BookArchivist.BookId.NormalizeText("The   New\n\nHorde")
        assert.are.equal("the new horde", result)
    end)
    
    it("trims leading/trailing spaces", function()
        local result = BookArchivist.BookId.NormalizeText("  The New Horde  ")
        assert.are.equal("the new horde", result)
    end)
    
    it("handles nil input", function()
        local result = BookArchivist.BookId.NormalizeText(nil)
        assert.are.equal("", result)
    end)
    
    it("handles empty string", function()
        local result = BookArchivist.BookId.NormalizeText("")
        assert.are.equal("", result)
    end)
end)

describe("BookId.MakeBookIdV2", function()
    it("generates v2 format IDs", function()
        local book = {
            title = "The New Horde",
            pages = {
                [1] = "First page content here"
            },
            source = {
                objectID = 12345
            }
        }
        
        local id = BookArchivist.BookId.MakeBookIdV2(book)
        
        -- v2 format is "b2:<hash>"
        assert(id:match("^b2:%x+$"), "ID should match v2 format: b2:<hex>")
    end)
    
    it("produces consistent IDs for same content", function()
        local book1 = {
            title = "Test Book",
            pages = { [1] = "Content" },
            source = { objectID = 100 }
        }
        
        local book2 = {
            title = "Test Book",
            pages = { [1] = "Content" },
            source = { objectID = 100 }
        }
        
        local id1 = BookArchivist.BookId.MakeBookIdV2(book1)
        local id2 = BookArchivist.BookId.MakeBookIdV2(book2)
        
        assert.are.equal(id1, id2)
    end)
    
    it("produces different IDs for different titles", function()
        local book1 = {
            title = "Book One",
            pages = { [1] = "Content" },
            source = { objectID = 100 }
        }
        
        local book2 = {
            title = "Book Two",
            pages = { [1] = "Content" },
            source = { objectID = 100 }
        }
        
        local id1 = BookArchivist.BookId.MakeBookIdV2(book1)
        local id2 = BookArchivist.BookId.MakeBookIdV2(book2)
        
        assert(id1 ~= id2, "Different titles should produce different IDs")
    end)
    
    it("produces different IDs for different objectIDs", function()
        local book1 = {
            title = "Test Book",
            pages = { [1] = "Content" },
            source = { objectID = 100 }
        }
        
        local book2 = {
            title = "Test Book",
            pages = { [1] = "Content" },
            source = { objectID = 200 }
        }
        
        local id1 = BookArchivist.BookId.MakeBookIdV2(book1)
        local id2 = BookArchivist.BookId.MakeBookIdV2(book2)
        
        assert(id1 ~= id2, "Different objectIDs should produce different IDs")
    end)
    
    it("produces different IDs for different first page content", function()
        local book1 = {
            title = "Test Book",
            pages = { [1] = "First content" },
            source = { objectID = 100 }
        }
        
        local book2 = {
            title = "Test Book",
            pages = { [1] = "Second content" },
            source = { objectID = 100 }
        }
        
        local id1 = BookArchivist.BookId.MakeBookIdV2(book1)
        local id2 = BookArchivist.BookId.MakeBookIdV2(book2)
        
        assert(id1 ~= id2, "Different first page content should produce different IDs")
    end)
    
    it("uses objectID 0 when missing", function()
        local book = {
            title = "Test Book",
            pages = { [1] = "Content" },
            source = {}  -- No objectID
        }
        
        local id = BookArchivist.BookId.MakeBookIdV2(book)
        
        -- Should still generate an ID
        assert(id:match("^b2:%x+$"), "Should generate ID even without objectID")
    end)
    
    it("normalizes title before hashing", function()
        local book1 = {
            title = "The New HORDE",
            pages = { [1] = "Content" },
            source = { objectID = 100 }
        }
        
        local book2 = {
            title = "the new horde",
            pages = { [1] = "Content" },
            source = { objectID = 100 }
        }
        
        local id1 = BookArchivist.BookId.MakeBookIdV2(book1)
        local id2 = BookArchivist.BookId.MakeBookIdV2(book2)
        
        assert.are.equal(id1, id2, "Case differences should not affect ID")
    end)
    
    it("ignores later pages in ID generation", function()
        local book1 = {
            title = "Test Book",
            pages = { [1] = "First", [2] = "Different later content" },
            source = { objectID = 100 }
        }
        
        local book2 = {
            title = "Test Book",
            pages = { [1] = "First", [2] = "Another different content" },
            source = { objectID = 100 }
        }
        
        local id1 = BookArchivist.BookId.MakeBookIdV2(book1)
        local id2 = BookArchivist.BookId.MakeBookIdV2(book2)
        
        assert.are.equal(id1, id2, "Later pages should not affect ID")
    end)
    
    it("returns nil for non-table input", function()
        local id = BookArchivist.BookId.MakeBookIdV2(nil)
        assert.is_nil(id)
        
        id = BookArchivist.BookId.MakeBookIdV2("not a table")
        assert.is_nil(id)
        
        id = BookArchivist.BookId.MakeBookIdV2(12345)
        assert.is_nil(id)
    end)
    
    it("handles missing pages gracefully", function()
        local book = {
            title = "Test Book",
            source = { objectID = 100 }
            -- No pages
        }
        
        local id = BookArchivist.BookId.MakeBookIdV2(book)
        assert(id:match("^b2:%x+$"), "Should generate ID even without pages")
    end)
end)

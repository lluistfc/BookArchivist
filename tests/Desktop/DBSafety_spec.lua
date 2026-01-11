-- DBSafety tests (corruption detection and database validation)
-- Tests SavedVariables structure validation and corruption handling

-- Load test helper for cross-platform path resolution
local helper = dofile("Tests/test_helper.lua")

-- Load bit library for hashing operations
helper.loadFile("tests/stubs/bit_library.lua")

-- Setup BookArchivist namespace
helper.setupNamespace()

-- Mock functions
BookArchivist.DebugPrint = function(self, ...) end
_G.time = function() return 1234567890 end

-- Load DBSafety module
helper.loadFile("core/BookArchivist_DBSafety.lua")

describe("DBSafety (Corruption Detection)", function()
  
  describe("ValidateStructure", function()
    it("should accept valid modern database (v2)", function()
      local db = {
        dbVersion = 2,
        booksById = {},
        order = {},
        indexes = {
          objectToBookId = {},
          itemToBookIds = {},
          titleToBookIds = {},
        }
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(db)
      
      assert.is_true(valid)
      assert.is_nil(err)
    end)
    
    it("should accept valid legacy database (v1)", function()
      local db = {
        version = 1,
        books = {}, -- Legacy structure
        order = {}
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(db)
      
      assert.is_true(valid)
      assert.is_nil(err)
    end)
    
    it("should reject nil input", function()
      local valid, err = BookArchivist.DBSafety:ValidateStructure(nil)
      
      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_true(err:find("not a table") ~= nil)
    end)
    
    it("should reject non-table input", function()
      local valid, err = BookArchivist.DBSafety:ValidateStructure("not a table")
      
      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_true(err:find("not a table") ~= nil)
    end)
    
    it("should reject database without books structure", function()
      local db = {
        order = {} -- Missing both booksById and books
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(db)
      
      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_true(err:find("Neither booksById nor books") ~= nil)
    end)
    
    it("should reject database without order", function()
      local db = {
        booksById = {}
        -- Missing order
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(db)
      
      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_true(err:find("order is missing") ~= nil)
    end)
    
    it("should reject database with non-table order", function()
      local db = {
        booksById = {},
        order = "not a table"
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(db)
      
      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_true(err:find("order") ~= nil)
    end)
    
    it("should reject database with invalid dbVersion type", function()
      local db = {
        booksById = {},
        order = {},
        dbVersion = "not a number"
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(db)
      
      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_true(err:find("dbVersion") ~= nil)
    end)
    
    it("should reject database with invalid indexes structure", function()
      local db = {
        booksById = {},
        order = {},
        indexes = "not a table"
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(db)
      
      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_true(err:find("indexes") ~= nil)
    end)
    
    it("should reject database with invalid objectToBookId", function()
      local db = {
        booksById = {},
        order = {},
        indexes = {
          objectToBookId = "not a table"
        }
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(db)
      
      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_true(err:find("objectToBookId") ~= nil)
    end)
    
    it("should reject database with invalid options", function()
      local db = {
        booksById = {},
        order = {},
        options = "not a table"
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(db)
      
      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_true(err:find("options") ~= nil)
    end)
    
    it("should accept database with optional valid fields", function()
      local db = {
        dbVersion = 2,
        booksById = {},
        order = {},
        indexes = {
          objectToBookId = {},
          itemToBookIds = {},
          titleToBookIds = {}
        },
        options = {
          debugMode = false
        },
        recent = {
          cap = 50,
          list = {}
        }
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(db)
      
      assert.is_true(valid)
      assert.is_nil(err)
    end)
  end)
  
  describe("CloneTable", function()
    it("should clone simple values", function()
      assert.are.equal(42, BookArchivist.DBSafety:CloneTable(42))
      assert.are.equal("test", BookArchivist.DBSafety:CloneTable("test"))
      assert.are.equal(true, BookArchivist.DBSafety:CloneTable(true))
      assert.is_nil(BookArchivist.DBSafety:CloneTable(nil))
    end)
    
    it("should clone simple table", function()
      local original = { a = 1, b = 2, c = 3 }
      local clone = BookArchivist.DBSafety:CloneTable(original)
      
      assert.are.equal(original.a, clone.a)
      assert.are.equal(original.b, clone.b)
      assert.are.equal(original.c, clone.c)
      
      -- Verify it's a different table
      clone.a = 999
      assert.are.equal(1, original.a)
      assert.are.equal(999, clone.a)
    end)
    
    it("should clone nested table", function()
      local original = {
        level1 = {
          level2 = {
            level3 = "deep value"
          }
        }
      }
      local clone = BookArchivist.DBSafety:CloneTable(original)
      
      assert.are.equal("deep value", clone.level1.level2.level3)
      
      -- Verify independence
      clone.level1.level2.level3 = "changed"
      assert.are.equal("deep value", original.level1.level2.level3)
    end)
    
    it("should handle circular references", function()
      local original = { a = 1 }
      original.self = original
      
      local clone = BookArchivist.DBSafety:CloneTable(original)
      
      assert.are.equal(1, clone.a)
      assert.are.equal(clone, clone.self)
    end)
    
    it("should clone array-like tables", function()
      local original = { "a", "b", "c", "d", "e" }
      local clone = BookArchivist.DBSafety:CloneTable(original)
      
      assert.are.equal(5, #clone)
      for i = 1, 5 do
        assert.are.equal(original[i], clone[i])
      end
      
      -- Verify independence
      clone[1] = "changed"
      assert.are.equal("a", original[1])
    end)
    
    it("should clone mixed tables", function()
      local original = {
        [1] = "first",
        [2] = "second",
        name = "test",
        data = { nested = true }
      }
      local clone = BookArchivist.DBSafety:CloneTable(original)
      
      assert.are.equal("first", clone[1])
      assert.are.equal("second", clone[2])
      assert.are.equal("test", clone.name)
      assert.is_true(clone.data.nested)
    end)
  end)
  
  describe("InitializeFreshDB", function()
    it("should create database with v2 structure", function()
      local db = BookArchivist.DBSafety:InitializeFreshDB()
      
      assert.are.equal(2, db.dbVersion)
      assert.are.equal("table", type(db.booksById))
      assert.are.equal("table", type(db.order))
    end)
    
    it("should create all required indexes", function()
      local db = BookArchivist.DBSafety:InitializeFreshDB()
      
      assert.are.equal("table", type(db.indexes))
      assert.are.equal("table", type(db.indexes.objectToBookId))
      assert.are.equal("table", type(db.indexes.itemToBookIds))
      assert.are.equal("table", type(db.indexes.titleToBookIds))
    end)
    
    it("should create recent list with cap", function()
      local db = BookArchivist.DBSafety:InitializeFreshDB()
      
      assert.are.equal("table", type(db.recent))
      assert.are.equal(50, db.recent.cap)
      assert.are.equal("table", type(db.recent.list))
      assert.are.equal(0, #db.recent.list)
    end)
    
    it("should create default UI state", function()
      local db = BookArchivist.DBSafety:InitializeFreshDB()
      
      assert.are.equal("table", type(db.uiState))
      assert.are.equal("__all__", db.uiState.lastCategoryId)
    end)
    
    it("should set creation timestamp", function()
      local db = BookArchivist.DBSafety:InitializeFreshDB()
      
      assert.are.equal("number", type(db.createdAt))
      assert.is_true(db.createdAt > 0)
    end)
    
    it("should create empty options", function()
      local db = BookArchivist.DBSafety:InitializeFreshDB()
      
      assert.are.equal("table", type(db.options))
    end)
    
    it("should pass validation", function()
      local db = BookArchivist.DBSafety:InitializeFreshDB()
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(db)
      
      assert.is_true(valid)
      assert.is_nil(err)
    end)
  end)
  
  describe("Integration scenarios", function()
    it("should detect corrupted database missing critical fields", function()
      local corrupted = {
        -- Missing booksById, books, and order
        someRandomField = "data"
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(corrupted)
      
      assert.is_false(valid)
      assert.is_not_nil(err)
    end)
    
    it("should accept database after migration from v1 to v2", function()
      local migratedDB = {
        version = 1, -- Legacy field preserved
        dbVersion = 2, -- New field
        books = {}, -- Legacy structure preserved
        booksById = {}, -- New structure
        order = {},
        indexes = {
          objectToBookId = {}
        }
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(migratedDB)
      
      assert.is_true(valid)
      assert.is_nil(err)
    end)
    
    it("should handle partial corruption in indexes", function()
      local db = {
        dbVersion = 2,
        booksById = { book1 = { title = "Test" } },
        order = { "book1" },
        indexes = {
          objectToBookId = "CORRUPTED" -- Invalid type
        }
      }
      
      local valid, err = BookArchivist.DBSafety:ValidateStructure(db)
      
      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_true(err:find("objectToBookId") ~= nil)
    end)
    
    it("should clone complex book structure", function()
      local original = {
        dbVersion = 2,
        booksById = {
          book1 = {
            title = "Test Book",
            pages = { [1] = "Page 1", [2] = "Page 2" },
            location = { zoneText = "Stormwind" },
            isFavorite = true
          }
        },
        order = { "book1" }
      }
      
      local clone = BookArchivist.DBSafety:CloneTable(original)
      
      assert.are.equal("Test Book", clone.booksById.book1.title)
      assert.are.equal("Page 1", clone.booksById.book1.pages[1])
      
      -- Verify independence
      clone.booksById.book1.title = "Changed"
      assert.are.equal("Test Book", original.booksById.book1.title)
    end)
  end)
  
end)

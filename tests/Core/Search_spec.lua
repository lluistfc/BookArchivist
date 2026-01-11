-- Search_spec.lua
-- Sandbox tests for search text processing

-- Load test helper
local helper = dofile("tests/test_helper.lua")
helper.setupNamespace()

-- Mock Core module
BookArchivist.Core = BookArchivist.Core or {}

-- Load Search module
helper.loadFile("core/BookArchivist_Search.lua")

describe("Search.NormalizeSearchText", function()
  it("lowercases input", function()
    local result = BookArchivist.Search.NormalizeSearchText("Hello World")
    assert.are.equal("hello world", result)
  end)
  
  it("strips color codes", function()
    local result = BookArchivist.Search.NormalizeSearchText("|cFFFF0000Red|r Text")
    assert.are.equal("red text", result)
  end)
  
  it("trims whitespace", function()
    local result = BookArchivist.Search.NormalizeSearchText("  text  ")
    assert.are.equal("text", result)
  end)
  
  it("collapses whitespace", function()
    local result = BookArchivist.Search.NormalizeSearchText("hello    world")
    assert.are.equal("hello world", result)
  end)
  
  it("handles nil input", function()
    local result = BookArchivist.Search.NormalizeSearchText(nil)
    assert.are.equal("", result)
  end)
  
  it("handles empty string", function()
    local result = BookArchivist.Search.NormalizeSearchText("")
    assert.are.equal("", result)
  end)
  
  it("handles multiple color codes", function()
    local result = BookArchivist.Search.NormalizeSearchText("|cFFFF0000Red|r |cFF00FF00Green|r")
    assert.are.equal("red green", result)
  end)
end)

describe("Search.BuildSearchText", function()
  it("builds from title only", function()
    local result = BookArchivist.Search.BuildSearchText("Test Book", nil)
    assert.are.equal("test book", result)
  end)
  
  it("builds from title and pages", function()
    local pages = {
      [1] = "Page One",
      [2] = "Page Two"
    }
    local result = BookArchivist.Search.BuildSearchText("Test", pages)
    assert.is_true(result:match("test") ~= nil)
    assert.is_true(result:match("page one") ~= nil)
    assert.is_true(result:match("page two") ~= nil)
  end)
  
  it("normalizes all content", function()
    local pages = {[1] = "|cFFFF0000RED|r TEXT"}
    local result = BookArchivist.Search.BuildSearchText("  TITLE  ", pages)
    assert.is_true(result:match("title") ~= nil)
    assert.is_true(result:match("red text") ~= nil)
  end)
  
  it("handles empty pages", function()
    local result = BookArchivist.Search.BuildSearchText("Title", {})
    assert.are.equal("title", result)
  end)
  
  it("handles nil pages", function()
    local result = BookArchivist.Search.BuildSearchText("Title", nil)
    assert.are.equal("title", result)
  end)
  
  it("handles numeric page keys", function()
    local pages = {
      [1] = "First",
      [2] = "Second",
      [3] = "Third"
    }
    local result = BookArchivist.Search.BuildSearchText("Title", pages)
    -- Pages should be in order
    local firstPos = result:find("first")
    local secondPos = result:find("second")
    local thirdPos = result:find("third")
    assert.is_true(firstPos < secondPos)
    assert.is_true(secondPos < thirdPos)
  end)
  
  it("skips empty pages", function()
    local pages = {
      [1] = "Content",
      [2] = "",
      [3] = "   ",
      [4] = "More"
    }
    local result = BookArchivist.Search.BuildSearchText("", pages)
    assert.is_true(result:match("content") ~= nil)
    assert.is_true(result:match("more") ~= nil)
  end)
  
  it("handles mixed page types", function()
    local pages = {
      [1] = "First",
      name = "Named",  -- Non-numeric keys
      [2] = "Second"
    }
    local result = BookArchivist.Search.BuildSearchText("", pages)
    assert.is_true(result ~= nil)
  end)
  
  it("joins with newlines", function()
    local pages = {[1] = "Page1", [2] = "Page2"}
    local result = BookArchivist.Search.BuildSearchText("Title", pages)
    assert.is_true(result:match("\n") ~= nil)
  end)
end)

describe("Search text matching", function()
  it("enables substring search via pattern matching", function()
    local searchText = BookArchivist.Search.BuildSearchText("The Great Book", {[1] = "Chapter One"})
    
    -- Lowercase substring matching
    assert.is_true(searchText:match("great") ~= nil)
    assert.is_true(searchText:match("chapter") ~= nil)
    assert.is_true(searchText:match("book") ~= nil)
  end)
  
  it("is case-insensitive after normalization", function()
    local searchText = BookArchivist.Search.BuildSearchText("UPPERCASE", nil)
    
    assert.is_true(searchText:match("uppercase") ~= nil)
    assert.is_true(searchText:match("upper") ~= nil)
  end)
  
  it("matches across title and content", function()
    local searchText = BookArchivist.Search.BuildSearchText("Magic", {[1] = "Spells"})
    
    assert.is_true(searchText:match("magic") ~= nil)
    assert.is_true(searchText:match("spells") ~= nil)
  end)
end)

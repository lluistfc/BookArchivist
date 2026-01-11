-- Integration test for v2.0.0 async filtering system
-- Tests the REAL BookArchivist.Iterator and filtering pipeline

-- Mock WoW APIs needed by Iterator
_G.GetTime = function()
  return (_G.__mockTime or 0)
end

_G.debugprofilestop = function()
  return (_G.__mockTime or 0) * 1000 -- Convert seconds to milliseconds
end

-- Mock CreateFrame for Iterator's worker frame
local mockFrames = {}
_G.CreateFrame = function(frameType, name, parent, template)
  local frame = {
    type = frameType,
    name = name,
    scripts = {},
  }
  
  function frame:SetScript(event, handler)
    self.scripts[event] = handler
  end
  
  function frame:GetScript(event)
    return self.scripts[event]
  end
  
  -- Method to manually trigger OnUpdate for testing
  function frame:_TriggerUpdate()
    if self.scripts.OnUpdate then
      self.scripts.OnUpdate()
    end
  end
  
  table.insert(mockFrames, frame)
  return frame
end

_G.wipe = function(tbl)
  for k in pairs(tbl) do
    tbl[k] = nil
  end
  return tbl
end

-- Mock C_Timer.After for async operations
_G.C_Timer = {
  After = function(delay, callback)
    -- For testing, execute callback immediately
    if callback then
      callback()
    end
  end
}

-- Setup BookArchivist namespace
BookArchivist = BookArchivist or {}
BookArchivist.L = BookArchivist.L or setmetatable({}, {
  __index = function(t, key) return key end
})

-- Mock Core for Search module dependency
BookArchivist.Core = BookArchivist.Core or {}

-- Simple logging
BookArchivist.LogInfo = function(self, msg)
  -- Silent during tests
end

BookArchivist.LogError = function(self, msg)
  print("[ERROR] " .. tostring(msg))
end

-- Load REAL modules
local coreBase = "g:/development/WorldOfWarcraft/BookArchivist/core/"
dofile(coreBase .. "BookArchivist_Iterator.lua")
dofile(coreBase .. "BookArchivist_Search.lua")

-- Now test the actual filtering logic inline (simplified from List_Filter.lua)
local FilterTester = {}

function FilterTester:matches(entry, tokens)
  if not tokens or #tokens == 0 then
    return true
  end

  local haystack = entry.searchText or ""
  haystack = haystack:lower()
  
  for i = 1, #tokens do
    local token = tokens[i]
    if token ~= "" and not haystack:find(token, 1, true) then
      return false
    end
  end
  
  return true
end

function FilterTester:tokenizeQuery(query)
  local tokens = {}
  query = query or ""
  for token in query:lower():gmatch("%S+") do
    table.insert(tokens, token)
  end
  return tokens
end

function FilterTester:filterBooksAsync(books, order, query, callback)
  local tokens = self:tokenizeQuery(query)
  local filtered = {}
  local matchKinds = {}
  
  -- Use REAL Iterator
  local success, errorMsg = BookArchivist.Iterator:Start(
    "test_filter",
    order, -- Array of book keys
    function(idx, bookKey, context)
      context.filtered = context.filtered or {}
      context.matchKinds = context.matchKinds or {}
      
      local entry = books[bookKey]
      if entry and self:matches(entry, tokens) then
        table.insert(context.filtered, bookKey)
        
        -- Track match kinds
        if #tokens > 0 then
          local titleHaystack = tostring(entry.title or ""):lower()
          local anyTitle = false
          local anyText = false
          
          for i = 1, #tokens do
            local token = tokens[i]
            if token ~= "" then
              if titleHaystack:find(token, 1, true) then
                anyTitle = true
              end
              if (entry.searchText or ""):lower():find(token, 1, true) and not titleHaystack:find(token, 1, true) then
                anyText = true
              end
            end
          end
          
          if anyTitle then
            context.matchKinds[bookKey] = "title"
          elseif anyText then
            context.matchKinds[bookKey] = "content"
          end
        end
      end
      
      return true -- continue
    end,
    {
      isArray = true,
      chunkSize = 50,
      budgetMs = 16,
      onComplete = function(context)
        if callback then
          callback(context.filtered or {}, context.matchKinds or {})
        end
      end
    }
  )
  
  if not success then
    error("Failed to start iterator: " .. tostring(errorMsg))
  end
  
  return success
end

-- Helper to run iterator to completion
local function runIteratorToCompletion(operation, maxIterations)
  maxIterations = maxIterations or 1000
  local iterations = 0
  
  while BookArchivist.Iterator:IsRunning(operation) and iterations < maxIterations do
    -- Find and trigger the worker frame
    for _, frame in ipairs(mockFrames) do
      if frame.type == "Frame" and frame.scripts.OnUpdate then
        frame:_TriggerUpdate()
      end
    end
    iterations = iterations + 1
    _G.__mockTime = (_G.__mockTime or 0) + 0.001 -- Advance time by 1ms
  end
  
  if iterations >= maxIterations then
    error("Iterator exceeded max iterations: " .. operation)
  end
  
  return iterations
end

-- Create test books with searchText
local function createTestBooks(count)
  local books = {}
  local order = {}
  
  for i = 1, count do
    local bookKey = "book" .. i
    books[bookKey] = {
      title = "Test Book " .. i,
      pages = {
        [1] = "This is page one of book " .. i,
        [2] = "This is page two with different content",
      },
      searchText = nil, -- Will be built
    }
    
    -- Build searchText using REAL Search module
    if BookArchivist.Search and BookArchivist.Search.BuildSearchText then
      books[bookKey].searchText = BookArchivist.Search.BuildSearchText(
        books[bookKey].title,
        books[bookKey].pages
      )
    end
    
    table.insert(order, bookKey)
  end
  
  return books, order
end

-- ============================================================================
-- TESTS
-- ============================================================================

-- Helper to reset state between tests
local function resetState()
  _G.__mockTime = 0
  wipe(mockFrames)
  
  -- Cancel any running operations
  BookArchivist.Iterator:Cancel("test_filter")
end

describe("Async Filtering Integration (v2.0.0 Real Systems)", function()
  
  describe("BookArchivist.Iterator (Real Module)", function()
    it("should process small dataset in one chunk", function()
      resetState()
      local books, order = createTestBooks(10)
      local completed = false
      local resultFiltered = nil
      
      FilterTester:filterBooksAsync(books, order, "", function(filtered, matchKinds)
        completed = true
        resultFiltered = filtered
      end)
      
      -- Run iterator to completion
      local iterations = runIteratorToCompletion("test_filter", 100)
      
      assert.is_true(completed, "Should complete filtering")
      assert.are.equal(10, #resultFiltered, "Should return all books")
      assert.is_true(iterations < 10, "Should complete in few iterations for small dataset")
    end)
    
    it("should process large dataset in multiple chunks", function()
      resetState()
      local books, order = createTestBooks(200)
      local completed = false
      local resultFiltered = nil
      
      FilterTester:filterBooksAsync(books, order, "", function(filtered, matchKinds)
        completed = true
        resultFiltered = filtered
      end)
      
      -- Run iterator to completion
      local iterations = runIteratorToCompletion("test_filter", 1000)
      
      assert.is_true(completed, "Should complete filtering")
      assert.are.equal(200, #resultFiltered, "Should return all books")
      assert.is_true(iterations > 1, "Should require multiple iterations for large dataset")
    end)
    
    it("should be cancellable mid-operation", function()
      resetState()
      local books, order = createTestBooks(1000)
      local completed = false
      
      FilterTester:filterBooksAsync(books, order, "", function(filtered, matchKinds)
        completed = true
      end)
      
      -- Run a few iterations
      for i = 1, 3 do
        for _, frame in ipairs(mockFrames) do
          if frame.type == "Frame" and frame.scripts.OnUpdate then
            frame:_TriggerUpdate()
          end
        end
      end
      
      -- Cancel
      BookArchivist.Iterator:Cancel("test_filter")
      
      -- Continue trying to run
      runIteratorToCompletion("test_filter", 10)
      
      assert.is_false(completed, "Should not complete after cancel")
      assert.is_false(BookArchivist.Iterator:IsRunning("test_filter"), "Should not be running")
    end)
  end)
  
  describe("Search and Filtering (Real Logic)", function()
    it("should build searchText from title and pages", function()
      resetState()
      local books, order = createTestBooks(5)
      
      -- Check searchText was built correctly
      for _, bookKey in ipairs(order) do
        local book = books[bookKey]
        assert.is_not_nil(book.searchText, "searchText should be built")
        -- searchText is lowercase normalized
        local lowerTitle = book.title:lower()
        assert.is_true(book.searchText:find(lowerTitle, 1, true) ~= nil, "searchText should contain lowercase title")
        assert.is_true(book.searchText:find("page one", 1, true) ~= nil, "searchText should contain page content (lowercase)")
      end
    end)
    
    it("should filter by search query (title match)", function()
      resetState()
      local books, order = createTestBooks(20)
      local completed = false
      local resultFiltered = nil
      
      -- Search for specific book
      FilterTester:filterBooksAsync(books, order, "Book 5", function(filtered, matchKinds)
        completed = true
        resultFiltered = filtered
      end)
      
      runIteratorToCompletion("test_filter", 100)
      
      assert.is_true(completed, "Should complete filtering")
      -- Should match "Book 5" and "Book 15" (substring match)
      assert.is_true(#resultFiltered >= 2, "Should match books with '5' in title")
      
      -- Verify book5 is in results
      local foundBook5 = false
      for _, bookKey in ipairs(resultFiltered) do
        if bookKey == "book5" then
          foundBook5 = true
          break
        end
      end
      assert.is_true(foundBook5, "Should find book5")
    end)
    
    it("should filter by search query (content match)", function()
      resetState()
      local books, order = createTestBooks(10)
      
      -- Add unique content to one book
      books["book3"].pages[1] = "This book contains unique wizard content"
      books["book3"].searchText = BookArchivist.Search.BuildSearchText(
        books["book3"].title,
        books["book3"].pages
      )
      
      local completed = false
      local resultFiltered = nil
      
      FilterTester:filterBooksAsync(books, order, "wizard", function(filtered, matchKinds)
        completed = true
        resultFiltered = filtered
      end)
      
      runIteratorToCompletion("test_filter", 100)
      
      assert.is_true(completed, "Should complete filtering")
      assert.are.equal(1, #resultFiltered, "Should match only one book")
      assert.are.equal("book3", resultFiltered[1], "Should match book3")
    end)
    
    it("should filter by multiple search tokens (AND logic)", function()
      resetState()
      local books, order = createTestBooks(10)
      
      -- Add specific content to one book
      books["book7"].pages[1] = "This book is about dragons and magic spells"
      books["book7"].searchText = BookArchivist.Search.BuildSearchText(
        books["book7"].title,
        books["book7"].pages
      )
      
      local completed = false
      local resultFiltered = nil
      
      -- Search requires BOTH tokens
      FilterTester:filterBooksAsync(books, order, "dragons magic", function(filtered, matchKinds)
        completed = true
        resultFiltered = filtered
      end)
      
      runIteratorToCompletion("test_filter", 100)
      
      assert.is_true(completed, "Should complete filtering")
      assert.are.equal(1, #resultFiltered, "Should match only book with both terms")
      assert.are.equal("book7", resultFiltered[1], "Should match book7")
    end)
    
    it("should track match kinds (title vs content)", function()
      resetState()
      local books, order = createTestBooks(10)
      
      -- book2 has "Test" in title
      -- book5 will have "testing" only in content
      books["book5"].pages[1] = "This page has testing procedures"
      books["book5"].searchText = BookArchivist.Search.BuildSearchText(
        books["book5"].title,
        books["book5"].pages
      )
      
      local completed = false
      local resultMatchKinds = nil
      
      FilterTester:filterBooksAsync(books, order, "test", function(filtered, matchKinds)
        completed = true
        resultMatchKinds = matchKinds
      end)
      
      runIteratorToCompletion("test_filter", 100)
      
      assert.is_true(completed, "Should complete filtering")
      
      -- All books have "Test" in title "Test Book N"
      for i = 1, 10 do
        local bookKey = "book" .. i
        if i == 5 then
          -- book5 has "testing" in content too, but title match takes precedence
          assert.are.equal("title", resultMatchKinds[bookKey], "book5 should be title match")
        else
          assert.are.equal("title", resultMatchKinds[bookKey], "book" .. i .. " should be title match")
        end
      end
    end)
    
    it("should handle empty search query (return all)", function()
      resetState()
      local books, order = createTestBooks(15)
      local completed = false
      local resultFiltered = nil
      
      FilterTester:filterBooksAsync(books, order, "", function(filtered, matchKinds)
        completed = true
        resultFiltered = filtered
      end)
      
      runIteratorToCompletion("test_filter", 100)
      
      assert.is_true(completed, "Should complete filtering")
      assert.are.equal(15, #resultFiltered, "Should return all books for empty query")
    end)
    
    it("should handle search query with no matches", function()
      resetState()
      local books, order = createTestBooks(10)
      local completed = false
      local resultFiltered = nil
      
      FilterTester:filterBooksAsync(books, order, "nonexistent_term_xyz", function(filtered, matchKinds)
        completed = true
        resultFiltered = filtered
      end)
      
      runIteratorToCompletion("test_filter", 100)
      
      assert.is_true(completed, "Should complete filtering")
      assert.are.equal(0, #resultFiltered, "Should return no matches")
    end)
  end)
  
  describe("Performance Characteristics", function()
    it("should handle 500 books efficiently", function()
      resetState()
      local books, order = createTestBooks(500)
      local completed = false
      local resultFiltered = nil
      local startTime = _G.__mockTime
      
      FilterTester:filterBooksAsync(books, order, "Book 42", function(filtered, matchKinds)
        completed = true
        resultFiltered = filtered
      end)
      
      local iterations = runIteratorToCompletion("test_filter", 5000)
      local endTime = _G.__mockTime
      local duration = endTime - startTime
      
      assert.is_true(completed, "Should complete filtering")
      assert.is_true(#resultFiltered >= 1, "Should find matches")
      
      print(string.format("[PERF] 500 books: %d iterations, %.3fs simulated time", iterations, duration))
    end)
    
    it("should handle 1000 books with complex search", function()
      resetState()
      local books, order = createTestBooks(1000)
      
      -- Add varied content
      for i = 1, 1000 do
        local bookKey = "book" .. i
        if i % 10 == 0 then
          books[bookKey].pages[1] = books[bookKey].pages[1] .. " special marker content"
          books[bookKey].searchText = BookArchivist.Search.BuildSearchText(
            books[bookKey].title,
            books[bookKey].pages
          )
        end
      end
      
      local completed = false
      local resultFiltered = nil
      local startTime = _G.__mockTime
      
      FilterTester:filterBooksAsync(books, order, "special marker", function(filtered, matchKinds)
        completed = true
        resultFiltered = filtered
      end)
      
      local iterations = runIteratorToCompletion("test_filter", 10000)
      local endTime = _G.__mockTime
      local duration = endTime - startTime
      
      assert.is_true(completed, "Should complete filtering")
      assert.are.equal(100, #resultFiltered, "Should match 100 books (every 10th)")
      
      print(string.format("[PERF] 1000 books: %d iterations, %.3fs simulated time", iterations, duration))
    end)
  end)
  
end)

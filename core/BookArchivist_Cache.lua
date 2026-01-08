---@diagnostic disable: undefined-global
-- BookArchivist_Cache.lua
-- In-memory caching layer for expensive operations.

BookArchivist = BookArchivist or {}

local Cache = {}
BookArchivist.Cache = Cache

-- Cache storage by category
local caches = {
  searchText = {},      -- Cached BuildSearchText results
  bookKeys = {},        -- Cached makeKey results  
  filteredLists = {},   -- Cached filter/search results
  locationTree = {},    -- Cached location hierarchy
}

-- Cache hit/miss statistics
local cacheStats = {
  hits = {},
  misses = {},
}

--- Get a value from cache
--- @param cacheName string Cache category name
--- @param key string Cache key
--- @return any|nil value Cached value or nil if not found
function Cache:Get(cacheName, key)
  if not caches[cacheName] then
    return nil
  end
  
  local value = caches[cacheName][key]
  if value ~= nil then
    cacheStats.hits[cacheName] = (cacheStats.hits[cacheName] or 0) + 1
    return value
  end
  
  cacheStats.misses[cacheName] = (cacheStats.misses[cacheName] or 0) + 1
  return nil
end

--- Set a value in cache
--- @param cacheName string Cache category name
--- @param key string Cache key
--- @param value any Value to cache
function Cache:Set(cacheName, key, value)
  if not caches[cacheName] then
    caches[cacheName] = {}
  end
  caches[cacheName][key] = value
end

--- Invalidate cache entries
--- @param cacheName string Cache category name
--- @param key string|nil Specific key to invalidate, or nil to clear entire cache
function Cache:Invalidate(cacheName, key)
  if not caches[cacheName] then
    return
  end
  
  if key then
    caches[cacheName][key] = nil
  else
    -- Clear entire cache category
    caches[cacheName] = {}
  end
end

--- Invalidate all caches related to a specific book
--- @param bookId string Book identifier
function Cache:InvalidateBook(bookId)
  -- Invalidate specific book caches
  self:Invalidate("searchText", bookId)
  self:Invalidate("bookKeys", bookId)
  
  -- Filtered lists depend on all books, so invalidate completely
  self:Invalidate("filteredLists")
end

--- Invalidate all caches (nuclear option)
function Cache:InvalidateAll()
  for cacheName in pairs(caches) do
    caches[cacheName] = {}
  end
end

--- Get cache statistics for monitoring
--- @return table stats Cache hit rates and sizes by category
function Cache:GetStats()
  local report = {}
  
  for cacheName in pairs(caches) do
    local hits = cacheStats.hits[cacheName] or 0
    local misses = cacheStats.misses[cacheName] or 0
    local total = hits + misses
    local hitRate = total > 0 and (hits / total * 100) or 0
    
    report[cacheName] = {
      hits = hits,
      misses = misses,
      total = total,
      hitRate = hitRate,
      size = self:GetCacheSize(caches[cacheName]),
    }
  end
  
  return report
end

--- Get the size of a cache category
--- @param cache table Cache storage table
--- @return number count Number of entries in cache
function Cache:GetCacheSize(cache)
  local count = 0
  for _ in pairs(cache) do
    count = count + 1
  end
  return count
end

--- Reset statistics (for testing/profiling)
function Cache:ResetStats()
  cacheStats = {
    hits = {},
    misses = {},
  }
end

--- Print cache statistics to chat
function Cache:PrintStats()
  local stats = self:GetStats()
  local lines = { "|cFFFFFF00=== BookArchivist Cache Statistics ===|r" }
  
  local hasData = false
  for cacheName, data in pairs(stats) do
    if data.total > 0 then
      hasData = true
      table.insert(lines, string.format(
        "|cFF00FF00%s:|r %d hits, %d misses (%.1f%% hit rate), %d entries",
        cacheName, data.hits, data.misses, data.hitRate, data.size
      ))
    end
  end
  
  if not hasData then
    table.insert(lines, "|cFF999999No cache activity yet|r")
  end
  
  for _, line in ipairs(lines) do
    print(line)
  end
end

-- Module loaded confirmation
if BookArchivist and BookArchivist.DebugPrint then
  BookArchivist:DebugPrint("[Cache] Module loaded")
end

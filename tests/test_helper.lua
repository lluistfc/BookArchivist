-- Test Helper - Cross-platform path resolution
-- Provides utilities for loading test dependencies with relative paths

local TestHelper = {}

-- Get the directory where test_helper.lua lives
-- This is calculated once when the module is first loaded
local function getHelperDir()
	-- Try to get the script path from debug info
	for level = 1, 5 do
		local info = debug.getinfo(level, "S")
		if info and info.source then
			local source = info.source
			if source:sub(1, 1) == "@" then
				-- File path
				local path = source:sub(2):gsub("\\", "/")
				if path:match("test_helper%.lua$") then
					return path:match("^(.+)/test_helper%.lua$") or "Tests"
				end
			end
		end
	end
	-- Fallback
	return "Tests"
end

local helperDir = getHelperDir()

-- Calculate project root (test_helper.lua is in Tests/, so go up one level)
local projectRoot
if helperDir == "Tests" or helperDir == "tests" then
	projectRoot = "."
elseif helperDir:match("/[Tt]ests$") then
	projectRoot = helperDir:match("^(.+)/[Tt]ests$")
else
	projectRoot = helperDir
end

function TestHelper.getProjectRoot()
	return projectRoot
end

-- Load a file relative to project root
function TestHelper.loadFile(relativePath)
	local fullPath = projectRoot .. "/" .. relativePath
	dofile(fullPath)
end

-- Setup BookArchivist namespace with common defaults
function TestHelper.setupNamespace()
	BookArchivist = BookArchivist or {}
	BookArchivist.L = BookArchivist.L or setmetatable({}, {
		__index = function(t, key)
			return key
		end,
	})
end

return TestHelper

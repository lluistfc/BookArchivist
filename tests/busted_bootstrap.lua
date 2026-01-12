-- Busted Bootstrap
-- Loaded before all tests to initialize common test infrastructure
-- Configure this in .busted as: helper = "Tests/busted_bootstrap.lua"

-- Load WoW API stubs (provides C_Timer, C_Map, etc.)
-- Strategy:
-- 1. If in _dev_/BookArchivist, use relative path to _dev_/Mechanic
-- 2. Otherwise, try loading MECHANIC_PATH from .env file
-- 3. Fall back to minimal inline mocks (sufficient for all tests)

local loaded = false
local mechanicPath = nil

-- Check if we're in a _dev_ directory structure
local cwd = io.popen("cd"):read("*l")  -- Get current working directory
if cwd:match("[/\\]_dev_[/\\]") then
	-- We're in _dev_ structure, use relative path
	mechanicPath = "../Mechanic"
	print("✓ Detected _dev_ directory structure")
else
	-- Try loading from .env file
	local envFile = io.open(".env", "r")
	if envFile then
		for line in envFile:lines() do
			local key, value = line:match("^%s*([^=]+)%s*=%s*(.+)%s*$")
			if key == "MECHANIC_PATH" then
				mechanicPath = value:gsub('"', ''):gsub("'", '')  -- Remove quotes
				print("✓ Loaded MECHANIC_PATH from .env")
				break
			end
		end
		envFile:close()
	end
end

-- Try loading Mechanic stubs if path is available
if mechanicPath then
	local stubsPath = mechanicPath .. "/sandbox/generated/wow_stubs.lua"
	local f = io.open(stubsPath, "r")
	if f then
		f:close()
		dofile(stubsPath)
		print("✓ Loaded wow_stubs.lua from: " .. stubsPath)
		loaded = true
	end
end

if not loaded then
	-- Use minimal inline mocks (works for all BookArchivist tests)
	print("✓ Using minimal WoW API mocks (sufficient for all tests)")
	
	-- Minimal WoW API mocks for CI (when Mechanic not available)
	-- These cover the essential APIs used by BookArchivist tests
	
	-- C_Timer namespace
	_G.C_Timer = {
		After = function(delay, callback)
			if callback then callback() end
		end,
		NewTimer = function(duration, callback)
			return { Cancel = function() end }
		end,
		NewTicker = function(duration, callback, iterations)
			return { Cancel = function() end }
		end
	}
	
	-- C_Map namespace (location APIs)
	_G.C_Map = {
		GetBestMapForUnit = function(unit) return 1415 end,  -- Ardenweald
		GetMapInfo = function(mapID) 
			return { name = "Test Zone", mapID = mapID or 1415 }
		end,
		GetPlayerMapPosition = function(mapID, unit)
			return { x = 0.5, y = 0.5 }
		end
	}
	
	-- Item APIs
	_G.GetItemInfo = function(itemID)
		return "Test Item", nil, 0, 1, 1, "Miscellaneous", "Junk", 1, "", "", 0
	end
	
	-- Unit APIs
	_G.UnitName = function(unit) return "TestPlayer", "TestRealm" end
	_G.UnitGUID = function(unit) return "Player-1234-56789ABC" end
	
	print("✓ Loaded minimal WoW API mocks (CI mode)")
end

-- Now load our addon-specific stubs/overrides
dofile("Tests/stubs/bit_library.lua")

-- Add global WoW functions not in Mechanic's stubs
-- wipe() - Clears a table and returns it
if not _G.wipe then
	_G.wipe = function(tbl)
		if type(tbl) ~= "table" then return end
		for k in pairs(tbl) do
			tbl[k] = nil
		end
		return tbl
	end
end

-- time() - Returns current Unix timestamp (use mock value for tests)
if not _G.time then
	_G.time = function()
		return 1000 -- Fixed timestamp for deterministic tests
	end
end

-- Global test utilities (if needed)
-- These can override or extend Mechanic's stubs
_G.TEST_MODE = true

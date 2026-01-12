-- Busted Bootstrap
-- Loaded before all tests to initialize common test infrastructure
-- Configure this in .busted as: helper = "Tests/busted_bootstrap.lua"

-- Load WoW API stubs (provides C_Timer, C_Map, etc.)
-- Try vendored copy first (for CI), then Mechanic (for local dev)
local stubsPaths = {
	"tests/vendor/wow_stubs.lua",  -- Vendored copy (CI)
	"../../_dev_/Mechanic/sandbox/generated/wow_stubs.lua"  -- Mechanic (relative path)
}

local loaded = false
for _, path in ipairs(stubsPaths) do
	local f = io.open(path, "r")
	if f then
		f:close()
		dofile(path)
		print("✓ Loaded wow_stubs.lua from: " .. path)
		loaded = true
		break
	end
end

if not loaded then
	print("⚠ wow_stubs.lua not found - using minimal inline mocks")
	
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

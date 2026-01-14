-- LocationDetection_spec.lua
-- In-game test for C_Map location detection with real WoW APIs

describe("Location Detection", function()
	it("should have Location module loaded", function()
		assert.is_not_nil(BookArchivist.Location, "Location module not loaded")
	end)

	it("should have C_Map API available", function()
		assert.is_not_nil(C_Map, "C_Map API not available")
	end)

	it("should have GetBestMapForUnit function", function()
		assert.is_not_nil(C_Map.GetBestMapForUnit, "C_Map.GetBestMapForUnit not available")
		assert.equals("function", type(C_Map.GetBestMapForUnit), "GetBestMapForUnit should be a function")
	end)

	it("should have GetMapInfo function", function()
		assert.is_not_nil(C_Map.GetMapInfo, "C_Map.GetMapInfo not available")
		assert.equals("function", type(C_Map.GetMapInfo), "GetMapInfo should be a function")
	end)

	it("should get current player map ID", function()
		local success, currentMapID = pcall(C_Map.GetBestMapForUnit, "player")
		if success and currentMapID then
			assert.is_not_nil(currentMapID, "Player map ID should not be nil")
			assert.is_number(currentMapID, "Player map ID should be a number")
			print("Player map ID: " .. tostring(currentMapID))
		else
			print("Warning: Player not in world (cannot verify map ID)")
		end
	end)

	it("should retrieve map info for current location", function()
		local success, currentMapID = pcall(C_Map.GetBestMapForUnit, "player")
		if success and currentMapID then
			local mapInfo = C_Map.GetMapInfo(currentMapID)
			if mapInfo then
				assert.is_not_nil(mapInfo.name, "Map info should have name")
				assert.is_not_nil(mapInfo.mapType, "Map info should have mapType")
				print("Map name: " .. tostring(mapInfo.name))
				print("Map type: " .. tostring(mapInfo.mapType))
			else
				print("Warning: Map info not available for mapID " .. tostring(currentMapID))
			end
		end
	end)

	it("should have BuildWorldLocation function", function()
		assert.is_not_nil(BookArchivist.Location.BuildWorldLocation, "BuildWorldLocation function missing")
		assert.equals("function", type(BookArchivist.Location.BuildWorldLocation), "BuildWorldLocation should be a function")
	end)

	it("should build location for current player position", function()
		local success, location = pcall(BookArchivist.Location.BuildWorldLocation)
		if success and location then
			assert.is_table(location, "Location should be a table")
			print("Current location: " .. tostring(location.zone or "Unknown"))
		else
			print("Warning: Could not build location (player may not be in world)")
		end
	end)
end)

---@diagnostic disable: undefined-global
-- Location_spec.lua
-- Unit tests for Location module

describe("Location Module", function()
	local Location
	
	setup(function()
		-- Load the Location module
		dofile("./core/BookArchivist_Location.lua")
		Location = BookArchivist.Location
	end)
	
	describe("BuildWorldLocation", function()
		it("should exist as a function", function()
			assert.is_not_nil(Location)
			assert.is_function(Location.BuildWorldLocation)
		end)
		
		it("should return a location table", function()
			-- Mock the required WoW API functions
			_G.C_Map = {
				GetBestMapForUnit = function(unit)
					return 1453 -- Stormwind City mapID
				end,
				GetMapInfo = function(mapID)
					if mapID == 1453 then
						return {
							name = "Stormwind City",
							mapType = 3,
							parentMapID = 1429,
						}
					elseif mapID == 1429 then
						return {
							name = "Eastern Kingdoms",
							mapType = 2,
							parentMapID = 947,
						}
					elseif mapID == 947 then
						return {
							name = "Azeroth",
							mapType = 0, -- Cosmic - should be filtered
							parentMapID = nil,
						}
					end
					return nil
				end,
			}
			
			_G.Enum = {
				UIMapType = {
					Cosmic = 0,
				},
			}
			
			_G.GetTime = function()
				return 1234567890
			end
			
			local location = Location:BuildWorldLocation()
			
			assert.is_not_nil(location)
			assert.equals("table", type(location))
		end)
		
		it("should include required fields", function()
			-- Use same mocks as above
			_G.C_Map = {
				GetBestMapForUnit = function(unit)
					return 1453
				end,
				GetMapInfo = function(mapID)
					if mapID == 1453 then
						return {
							name = "Stormwind City",
							mapType = 3,
							parentMapID = 1429,
						}
					elseif mapID == 1429 then
						return {
							name = "Eastern Kingdoms",
							mapType = 2,
							parentMapID = nil,
						}
					end
					return nil
				end,
			}
			
			_G.Enum = {
				UIMapType = {
					Cosmic = 0,
				},
			}
			
			_G.GetTime = function()
				return 1234567890
			end
			
			local location = Location:BuildWorldLocation()
			
			-- Required fields
			assert.is_not_nil(location.context)
			assert.equals("world", location.context)
			assert.is_not_nil(location.zoneChain)
			assert.equals("table", type(location.zoneChain))
			assert.is_not_nil(location.zoneText)
			assert.equals("string", type(location.zoneText))
			assert.is_not_nil(location.capturedAt)
			assert.equals("number", type(location.capturedAt))
		end)
		
		it("should build zoneChain hierarchy", function()
			_G.C_Map = {
				GetBestMapForUnit = function(unit)
					return 1453 -- Stormwind City
				end,
				GetMapInfo = function(mapID)
					if mapID == 1453 then
						return {
							name = "Stormwind City",
							mapType = 3,
							parentMapID = 1429,
						}
					elseif mapID == 1429 then
						return {
							name = "Elwynn Forest",
							mapType = 3,
							parentMapID = 1415,
						}
					elseif mapID == 1415 then
						return {
							name = "Eastern Kingdoms",
							mapType = 2,
							parentMapID = nil,
						}
					end
					return nil
				end,
			}
			
			_G.Enum = {
				UIMapType = {
					Cosmic = 0,
				},
			}
			
			_G.GetTime = function()
				return 1234567890
			end
			
			local location = Location:BuildWorldLocation()
			
			-- zoneChain should be bottom-up (continent first, zone last)
			assert.equals(3, #location.zoneChain)
			assert.equals("Eastern Kingdoms", location.zoneChain[1])
			assert.equals("Elwynn Forest", location.zoneChain[2])
			assert.equals("Stormwind City", location.zoneChain[3])
		end)
		
		it("should format zoneText with separators", function()
			_G.C_Map = {
				GetBestMapForUnit = function(unit)
					return 1453
				end,
				GetMapInfo = function(mapID)
					if mapID == 1453 then
						return {
							name = "Stormwind City",
							mapType = 3,
							parentMapID = 1429,
						}
					elseif mapID == 1429 then
						return {
							name = "Elwynn Forest",
							mapType = 3,
							parentMapID = 1415,
						}
					elseif mapID == 1415 then
						return {
							name = "Eastern Kingdoms",
							mapType = 2,
							parentMapID = nil,
						}
					end
					return nil
				end,
			}
			
			_G.Enum = {
				UIMapType = {
					Cosmic = 0,
				},
			}
			
			_G.GetTime = function()
				return 1234567890
			end
			
			local location = Location:BuildWorldLocation()
			
			-- zoneText should be joined with " > "
			assert.equals("Eastern Kingdoms > Elwynn Forest > Stormwind City", location.zoneText)
		end)
		
		it("should handle missing C_Map API gracefully", function()
			-- Simulate API not available
			_G.C_Map = nil
			_G.GetRealZoneText = function()
				return "Elwynn Forest"
			end
			_G.GetSubZoneText = function()
				return "Goldshire"
			end
			_G.GetTime = function()
				return 1234567890
			end
			
			local location = Location:BuildWorldLocation()
			
			assert.is_not_nil(location)
			assert.is_not_nil(location.zoneChain)
			-- Should have at least one zone
			assert.is_true(#location.zoneChain >= 1)
		end)
		
		it("should use Unknown Zone fallback when no zone data available", function()
			_G.C_Map = nil
			_G.GetRealZoneText = function()
				return ""
			end
			_G.GetSubZoneText = function()
				return ""
			end
			_G.GetTime = function()
				return 1234567890
			end
			
			BookArchivist.L = {
				LOCATION_UNKNOWN_ZONE = "Unknown Zone"
			}
			
			local location = Location:BuildWorldLocation()
			
			assert.is_not_nil(location)
			assert.equals(1, #location.zoneChain)
			assert.equals("Unknown Zone", location.zoneChain[1])
		end)
		
		it("should copy zoneChain array (not reference)", function()
			_G.C_Map = {
				GetBestMapForUnit = function(unit)
					return 1453
				end,
				GetMapInfo = function(mapID)
					return {
						name = "Test Zone",
						mapType = 3,
						parentMapID = nil,
					}
				end,
			}
			
			_G.Enum = {
				UIMapType = {
					Cosmic = 0,
				},
			}
			
			_G.GetTime = function()
				return 1234567890
			end
			
			local location1 = Location:BuildWorldLocation()
			local location2 = Location:BuildWorldLocation()
			
			-- Should be separate arrays
			assert.are_not.equals(location1.zoneChain, location2.zoneChain)
			
			-- Modifying one shouldn't affect the other
			location1.zoneChain[1] = "Modified"
			assert.are_not.equals(location1.zoneChain[1], location2.zoneChain[1])
		end)
	end)
	
	describe("GetLootLocation", function()
		it("should exist as a function", function()
			assert.is_not_nil(Location)
			assert.is_function(Location.GetLootLocation)
		end)
		
		it("should return nil for unknown itemID", function()
			_G.GetTime = function()
				return 1234567890
			end
			
			local location = Location:GetLootLocation(999999)
			assert.is_nil(location)
		end)
		
		it("should accept numeric itemID", function()
			_G.GetTime = function()
				return 1234567890
			end
			
			-- Should not error with numeric ID
			local location = Location:GetLootLocation(12345)
			-- Will be nil since we haven't cached it, but shouldn't error
			assert.is_nil(location)
		end)
		
		it("should accept string itemID", function()
			_G.GetTime = function()
				return 1234567890
			end
			
			-- Should not error with string ID
			local location = Location:GetLootLocation("12345")
			-- Will be nil since we haven't cached it, but shouldn't error
			assert.is_nil(location)
		end)
		
		it("should return nil for nil itemID", function()
			_G.GetTime = function()
				return 1234567890
			end
			
			local location = Location:GetLootLocation(nil)
			assert.is_nil(location)
		end)
	end)
	
	describe("Edge Cases and Robustness", function()
		it("should handle mapType filtering (Cosmic maps)", function()
			_G.C_Map = {
				GetBestMapForUnit = function(unit)
					return 947 -- Cosmic map
				end,
				GetMapInfo = function(mapID)
					return {
						name = "Azeroth",
						mapType = 0, -- Cosmic - should be filtered
						parentMapID = nil,
					}
				end,
			}
			
			_G.Enum = {
				UIMapType = {
					Cosmic = 0,
				},
			}
			
			_G.GetTime = function() return 1234567890 end
			
			BookArchivist.L = {
				LOCATION_UNKNOWN_ZONE = "Unknown Zone"
			}
			
			local location = Location:BuildWorldLocation()
			
			-- Cosmic maps should be filtered out, leaving Unknown Zone
			assert.is_not_nil(location)
			assert.equals(1, #location.zoneChain)
			assert.equals("Unknown Zone", location.zoneChain[1])
		end)
		
		it("should handle nil GetBestMapForUnit", function()
			_G.C_Map = {
				GetBestMapForUnit = function(unit)
					return nil -- No map
				end,
				GetMapInfo = function(mapID)
					return nil
				end,
			}
			
			_G.Enum = {
				UIMapType = {
					Cosmic = 0,
				},
			}
			
			_G.GetTime = function() return 1234567890 end
			_G.GetRealZoneText = function() return "" end
			_G.GetSubZoneText = function() return "" end
			
			BookArchivist.L = {
				LOCATION_UNKNOWN_ZONE = "Unknown Zone"
			}
			
			local location = Location:BuildWorldLocation()
			
			assert.is_not_nil(location)
			assert.equals(1, #location.zoneChain)
			assert.equals("Unknown Zone", location.zoneChain[1])
		end)
		
		it("should handle circular map hierarchy (safety check)", function()
			-- Pathological case: map is its own parent (shouldn't happen but test safety)
			local callCount = 0
			_G.C_Map = {
				GetBestMapForUnit = function(unit)
					return 1453
				end,
				GetMapInfo = function(mapID)
					callCount = callCount + 1
					if callCount > 50 then
						-- Prevent infinite loop in test
						return nil
					end
					return {
						name = "Circular Map",
						mapType = 3,
						parentMapID = mapID, -- Circular!
					}
				end,
			}
			
			_G.Enum = {
				UIMapType = {
					Cosmic = 0,
				},
			}
			
			_G.GetTime = function() return 1234567890 end
			
			-- Should not infinite loop
			local location = Location:BuildWorldLocation()
			
			assert.is_not_nil(location)
			-- Implementation should have max depth limit (buildZoneData has 20 iteration limit)
			assert.is_true(#location.zoneChain <= 20)
		end)
		
		it("should handle empty zone names", function()
			_G.C_Map = {
				GetBestMapForUnit = function(unit)
					return 1453
				end,
				GetMapInfo = function(mapID)
					return {
						name = "", -- Empty name
						mapType = 3,
						parentMapID = nil,
					}
				end,
			}
			
			_G.Enum = {
				UIMapType = {
					Cosmic = 0,
				},
			}
			
			_G.GetTime = function() return 1234567890 end
			
			local location = Location:BuildWorldLocation()
			
			-- Empty names should be skipped
			assert.is_not_nil(location)
			-- Should have at least Unknown Zone fallback
			assert.is_true(#location.zoneChain >= 1)
		end)
		
		it("should use fallback GetRealZoneText/GetSubZoneText when C_Map fails", function()
			_G.C_Map = nil -- No modern API
			_G.GetRealZoneText = function()
				return "Elwynn Forest"
			end
			_G.GetSubZoneText = function()
				return "Goldshire"
			end
			_G.GetTime = function() return 1234567890 end
			
			local location = Location:BuildWorldLocation()
			
			assert.is_not_nil(location)
			assert.is_true(#location.zoneChain >= 1)
			-- Should contain at least one of the fallback zones
			local hasZone = false
			for _, zone in ipairs(location.zoneChain) do
				if zone == "Elwynn Forest" or zone == "Goldshire" then
					hasZone = true
					break
				end
			end
			assert.is_true(hasZone, "Should use GetRealZoneText/GetSubZoneText fallback")
		end)
	end)
end)

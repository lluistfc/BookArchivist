-- InGameTests.lua
-- Test runner for BookArchivist in-game tests (consumed by MechanicIntegration.lua)

BookArchivist = BookArchivist or {}
BookArchivist.InGameTests = BookArchivist.InGameTests or {}

local InGameTests = BookArchivist.InGameTests

-- Test definitions
local tests = {
	-- Core API Integration Tests (run directly in-game)
	{
		id = "tooltip_integration",
		name = "Tooltip Integration",
		category = "Core",
		type = "auto",
		description = "Verifies GameTooltip hooks and TooltipDataProcessor API",
	},
	{
		id = "itemtext_capture",
		name = "ItemText Capture",
		category = "Core",
		type = "auto",
		description = "Verifies ITEM_TEXT event handlers and capture system",
	},
	{
		id = "location_detection",
		name = "Location Detection",
		category = "Core",
		type = "auto",
		description = "Verifies C_Map APIs and location building",
	},
}

-- Test implementations (Core tests)
local function runTooltipTest()
	local details = {}
	local allPassed = true

	local hasModule = BookArchivist.Tooltip ~= nil
	table.insert(details, {
		label = "Tooltip module",
		value = hasModule and "Loaded" or "Missing",
		status = hasModule and "pass" or "fail",
	})
	if not hasModule then
		allPassed = false
	end

	local hasAPI = TooltipDataProcessor ~= nil
	table.insert(details, {
		label = "TooltipDataProcessor API",
		value = hasAPI and "Available" or "Missing",
		status = hasAPI and "pass" or "fail",
	})
	if not hasAPI then
		allPassed = false
	end

	local db = BookArchivist.Repository and BookArchivist.Repository:GetDB()
	local isEnabled = true
	if db and db.options and db.options.tooltip then
		if type(db.options.tooltip) == "table" then
			isEnabled = db.options.tooltip.enabled ~= false
		elseif type(db.options.tooltip) == "boolean" then
			isEnabled = db.options.tooltip
		end
	end
	table.insert(details, {
		label = "Tooltip enabled",
		value = isEnabled and "Yes" or "No",
		status = isEnabled and "pass" or "warn",
	})

	if db and db.indexes then
		local itemCount = 0
		for _ in pairs(db.indexes.itemToBookIds or {}) do
			itemCount = itemCount + 1
		end
		table.insert(details, {
			label = "Item index entries",
			value = tostring(itemCount),
			status = "pass",
		})
	end

	return {
		passed = allPassed,
		message = allPassed and "Tooltip integration ready" or "Tooltip integration incomplete",
		details = details,
	}
end

local function runCaptureTest()
	local details = {}
	local allPassed = true

	local hasModule = BookArchivist.Capture ~= nil
	table.insert(details, {
		label = "Capture module",
		value = hasModule and "Loaded" or "Missing",
		status = hasModule and "pass" or "fail",
	})
	if not hasModule then
		allPassed = false
	end

	local hasOnBegin = BookArchivist.Capture and BookArchivist.Capture.OnBegin ~= nil
	table.insert(details, {
		label = "OnBegin handler",
		value = hasOnBegin and "Available" or "Missing",
		status = hasOnBegin and "pass" or "fail",
	})
	if not hasOnBegin then
		allPassed = false
	end

	local hasOnReady = BookArchivist.Capture and BookArchivist.Capture.OnReady ~= nil
	table.insert(details, {
		label = "OnReady handler",
		value = hasOnReady and "Available" or "Missing",
		status = hasOnReady and "pass" or "fail",
	})
	if not hasOnReady then
		allPassed = false
	end

	local hasOnClosed = BookArchivist.Capture and BookArchivist.Capture.OnClosed ~= nil
	table.insert(details, {
		label = "OnClosed handler",
		value = hasOnClosed and "Available" or "Missing",
		status = hasOnClosed and "pass" or "fail",
	})
	if not hasOnClosed then
		allPassed = false
	end

	local hasLocation = BookArchivist.Location ~= nil
	table.insert(details, {
		label = "Location module",
		value = hasLocation and "Loaded" or "Missing",
		status = hasLocation and "pass" or "warn",
	})

	local hasPersist = BookArchivist.Core and BookArchivist.Core.PersistSession ~= nil
	table.insert(details, {
		label = "PersistSession",
		value = hasPersist and "Available" or "Missing",
		status = hasPersist and "pass" or "fail",
	})
	if not hasPersist then
		allPassed = false
	end

	return {
		passed = allPassed,
		message = allPassed and "Capture system ready" or "Capture system incomplete",
		details = details,
	}
end

local function runLocationTest()
	local details = {}
	local allPassed = true

	local hasModule = BookArchivist.Location ~= nil
	table.insert(details, {
		label = "Location module",
		value = hasModule and "Loaded" or "Missing",
		status = hasModule and "pass" or "fail",
	})
	if not hasModule then
		allPassed = false
	end

	local hasMapAPI = C_Map ~= nil
	table.insert(details, {
		label = "C_Map API",
		value = hasMapAPI and "Available" or "Missing",
		status = hasMapAPI and "pass" or "fail",
	})
	if not hasMapAPI then
		allPassed = false
	end

	if hasMapAPI then
		local success, currentMapID = pcall(C_Map.GetBestMapForUnit, "player")
		if success and currentMapID then
			table.insert(details, {
				label = "Player map ID",
				value = tostring(currentMapID),
				status = "pass",
			})

			local mapInfo = C_Map.GetMapInfo(currentMapID)
			if mapInfo then
				table.insert(details, {
					label = "Map name",
					value = mapInfo.name or "Unknown",
					status = "pass",
				})
			end
		else
			table.insert(details, {
				label = "Player map ID",
				value = "Not in world",
				status = "warn",
			})
		end
	end

	local hasBuildFunc = BookArchivist.Location and BookArchivist.Location.BuildWorldLocation ~= nil
	table.insert(details, {
		label = "BuildWorldLocation",
		value = hasBuildFunc and "Available" or "Missing",
		status = hasBuildFunc and "pass" or "fail",
	})
	if not hasBuildFunc then
		allPassed = false
	end

	return {
		passed = allPassed,
		message = allPassed and "Location detection ready" or "Location detection incomplete",
		details = details,
	}
end

-- Public API (consumed by MechanicIntegration)
function InGameTests.GetAll()
	-- Spec test modules are already loaded via .toc and exported to global namespace
	local ReaderTests = BookArchivist.ReaderTests or {}
	local FilteringTests = BookArchivist.FilteringTests or {}
	local IntegrationTests = BookArchivist.IntegrationTests or {}

	-- Build combined test list
	local allTests = {}
	for _, test in ipairs(tests) do
		table.insert(allTests, test)
	end

	-- Add Reader tests
	for funcName, _ in pairs(ReaderTests) do
		if funcName:match("^test_") then
			local testName = funcName:sub(6):gsub("_", " ")
			table.insert(allTests, {
				id = "reader_" .. funcName:sub(6),
				name = testName,
				category = "UI",
				type = "auto",
				description = "Reader: " .. testName,
			})
		end
	end

	-- Add Filtering tests
	for funcName, _ in pairs(FilteringTests) do
		if funcName:match("^test_") then
			local testName = funcName:sub(6):gsub("_", " ")
			table.insert(allTests, {
				id = "filtering_" .. funcName:sub(6),
				name = testName,
				category = "UI",
				type = "auto",
				description = "Filtering: " .. testName,
			})
		end
	end

	-- Add Integration tests
	for funcName, _ in pairs(IntegrationTests) do
		if funcName:match("^test_") then
			local testName = funcName:sub(6):gsub("_", " ")
			table.insert(allTests, {
				id = "integration_" .. funcName:sub(6),
				name = testName,
				category = "UI",
				type = "auto",
				description = "Integration: " .. testName,
			})
		end
	end

	return allTests
end

function InGameTests.Run(testId)
	local startTime = debugprofilestop()
	local result

	if testId == "tooltip_integration" then
		result = runTooltipTest()
	elseif testId == "itemtext_capture" then
		result = runCaptureTest()
	elseif testId == "location_detection" then
		result = runLocationTest()
	elseif testId:match("^reader_") then
		local funcName = "test_" .. testId:sub(8)
		local ReaderTests = BookArchivist.ReaderTests or {}
		if ReaderTests[funcName] then
			local passed, message = ReaderTests[funcName]()
			result = {
				passed = passed,
				message = message or (passed and "OK" or "FAIL"),
				details = {},
			}
		else
			result = { passed = false, message = "Test function not found", details = {} }
		end
	elseif testId:match("^filtering_") then
		local funcName = "test_" .. testId:sub(11)
		local FilteringTests = BookArchivist.FilteringTests or {}
		if FilteringTests[funcName] then
			local passed, message = FilteringTests[funcName]()
			result = {
				passed = passed,
				message = message or (passed and "OK" or "FAIL"),
				details = {},
			}
		else
			result = { passed = false, message = "Test function not found", details = {} }
		end
	elseif testId:match("^integration_") then
		local funcName = "test_" .. testId:sub(13)
		local IntegrationTests = BookArchivist.IntegrationTests or {}
		if IntegrationTests[funcName] then
			local passed, message = IntegrationTests[funcName]()
			result = {
				passed = passed,
				message = message or (passed and "OK" or "FAIL"),
				details = {},
			}
		else
			result = { passed = false, message = "Test function not found", details = {} }
		end
	else
		result = {
			passed = false,
			message = "Unknown test ID: " .. tostring(testId),
			details = {},
		}
	end

	result.duration = (debugprofilestop() - startTime) / 1000
	result.id = testId

	return result
end

function InGameTests.RunAll()
	local allTests = InGameTests.GetAll()
	local passed = 0
	local total = #allTests
	local results = {}

	for _, test in ipairs(allTests) do
		local result = InGameTests.Run(test.id)
		results[test.id] = result
		if result.passed then
			passed = passed + 1
		end
	end

	return passed, total, results
end

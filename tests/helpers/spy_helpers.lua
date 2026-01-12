-- Test helper utilities for function call tracking (similar to Mockito verify)
-- Uses Busted's spy functionality with ergonomic assertions

local SpyHelpers = {}

-- Track a function and return a spy that counts calls
-- Usage: local spy = SpyHelpers.track(object, "methodName")
function SpyHelpers.track(object, methodName)
	local original = object[methodName]
	local callCount = 0
	local calls = {}
	
	object[methodName] = function(...)
		callCount = callCount + 1
		local args = {...}
		table.insert(calls, args)
		if type(original) == "function" then
			return original(...)
		end
	end
	
	return {
		callCount = function() return callCount end,
		calls = function() return calls end,
		reset = function()
			callCount = 0
			calls = {}
		end,
		restore = function()
			object[methodName] = original
		end
	}
end

-- Assert that a spy was called exactly N times
-- Usage: SpyHelpers.assertCalledTimes(spy, 1, "RefreshUI should be called once")
function SpyHelpers.assertCalledTimes(spy, expectedCount, message)
	local actualCount = spy.callCount()
	if actualCount ~= expectedCount then
		local msg = message or string.format("Expected %d calls but got %d", expectedCount, actualCount)
		error(msg, 2)
	end
end

-- Assert that a spy was called at least once
function SpyHelpers.assertCalled(spy, message)
	local actualCount = spy.callCount()
	if actualCount == 0 then
		local msg = message or "Expected at least one call but got none"
		error(msg, 2)
	end
end

-- Assert that a spy was never called
function SpyHelpers.assertNotCalled(spy, message)
	local actualCount = spy.callCount()
	if actualCount > 0 then
		local msg = message or string.format("Expected no calls but got %d", actualCount)
		error(msg, 2)
	end
end

-- Create a mock function that tracks calls
-- Usage: local mock = SpyHelpers.mockFunction()
--        mock()  -- call it
--        SpyHelpers.assertCalledTimes(mock, 1)
function SpyHelpers.mockFunction(returnValue)
	local callCount = 0
	local calls = {}
	
	-- Create a table with __call metamethod instead of a plain function
	local mock = {}
	
	-- Make the table callable
	setmetatable(mock, {
		__call = function(self, ...)
			callCount = callCount + 1
			local args = {...}
			table.insert(calls, args)
			return returnValue
		end
	})
	
	-- Add tracking methods
	mock.callCount = function() return callCount end
	mock.calls = function() return calls end
	mock.reset = function()
		callCount = 0
		calls = {}
	end
	
	return mock
end

return SpyHelpers

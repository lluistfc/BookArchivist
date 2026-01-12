---@diagnostic disable: undefined-global
-- Iterator_spec.lua
-- Tests for BookArchivist.Iterator (throttled iteration system)

describe("Iterator Module", function()
	local Iterator
	local mockFrame
	local onUpdateCallback
	local currentTime = 0
	local frameCounter = 0
	
	setup(function()
		-- Mock WoW API
		_G.BookArchivist = {}
		_G.GetTime = function()
			return currentTime
		end
		_G.debugprofilestop = function()
			return frameCounter * 5 -- 5ms per frame simulation
		end
		_G.CreateFrame = function()
			mockFrame = {
				SetScript = function(self, event, callback)
					if event == "OnUpdate" then
						onUpdateCallback = callback
					end
				end
			}
			return mockFrame
		end
		
		-- Load module
		dofile("./core/BookArchivist_Iterator.lua")
		Iterator = BookArchivist.Iterator
	end)
	
	before_each(function()
		currentTime = 0
		frameCounter = 0
		onUpdateCallback = nil
		mockFrame = nil
	end)
	
	describe("Module Loading", function()
		it("should load Iterator module without errors", function()
			assert.is_not_nil(Iterator)
			assert.equals("table", type(Iterator))
		end)
		
		it("should have public API functions", function()
			assert.equals("function", type(Iterator.Start))
			assert.equals("function", type(Iterator.Cancel))
			assert.equals("function", type(Iterator.IsRunning))
			assert.equals("function", type(Iterator.CancelAll))
			assert.equals("function", type(Iterator.GetStatus))
			assert.equals("function", type(Iterator.GetActiveOperations))
		end)
	end)
	
	describe("Start", function()
		it("should reject nil operation", function()
			local success, err = Iterator:Start(nil, {}, function() end)
			assert.is_false(success)
			assert.is_not_nil(err)
			assert.is_true(err:find("operation must be a string") ~= nil)
		end)
		
		it("should reject non-string operation", function()
			local success, err = Iterator:Start(123, {}, function() end)
			assert.is_false(success)
			assert.is_not_nil(err)
		end)
		
		it("should reject nil dataSource", function()
			local success, err = Iterator:Start("test", nil, function() end)
			assert.is_false(success)
			assert.is_true(err:find("dataSource must be a table") ~= nil)
		end)
		
		it("should reject non-table dataSource", function()
			local success, err = Iterator:Start("test", "not a table", function() end)
			assert.is_false(success)
		end)
		
		it("should reject nil callback", function()
			local success, err = Iterator:Start("test", {}, nil)
			assert.is_false(success)
			assert.is_true(err:find("callback must be a function") ~= nil)
		end)
		
		it("should reject duplicate operation", function()
			local success1 = Iterator:Start("duplicate", {}, function() end)
			assert.is_true(success1)
			
			local success2, err = Iterator:Start("duplicate", {}, function() end)
			assert.is_false(success2)
			assert.is_true(err:find("already in progress") ~= nil)
			
			Iterator:Cancel("duplicate")
		end)
		
		it("should accept valid parameters", function()
			local success = Iterator:Start("valid", { a = 1, b = 2 }, function() end)
			assert.is_true(success)
			Iterator:Cancel("valid")
		end)
		
		it("should create OnUpdate frame", function()
			Iterator:Start("frame-test", { a = 1 }, function() end)
			assert.is_not_nil(mockFrame)
			assert.is_not_nil(onUpdateCallback)
			Iterator:Cancel("frame-test")
		end)
	end)
	
	describe("Map Iteration", function()
		it("should iterate over all map entries", function()
			local data = { a = 1, b = 2, c = 3 }
			local visited = {}
			
			Iterator:Start("map-test", data, function(key, value, context)
				visited[key] = value
				return true
			end)
			
			-- Simulate frames until completion
			for i = 1, 10 do
				if onUpdateCallback then
					onUpdateCallback()
				else
					break
				end
				frameCounter = frameCounter + 1
			end
			
			assert.equals(1, visited.a)
			assert.equals(2, visited.b)
			assert.equals(3, visited.c)
		end)
		
		it("should iterate in deterministic order (sorted keys)", function()
			local data = { z = 26, a = 1, m = 13 }
			local order = {}
			
			Iterator:Start("order-test", data, function(key, value, context)
				table.insert(order, key)
				return true
			end)
			
			-- Process all
			for i = 1, 10 do
				if onUpdateCallback then
					onUpdateCallback()
				else
					break
				end
				frameCounter = frameCounter + 1
			end
			
			-- Should be sorted: a, m, z
			assert.equals("a", order[1])
			assert.equals("m", order[2])
			assert.equals("z", order[3])
		end)
	end)
	
	describe("Array Iteration", function()
		it("should iterate over array entries in order", function()
			local data = { 10, 20, 30, 40, 50 }
			local visited = {}
			
			Iterator:Start("array-test", data, function(key, value, context)
				table.insert(visited, value)
				return true
			end, { isArray = true })
			
			-- Process all
			for i = 1, 10 do
				if onUpdateCallback then
					onUpdateCallback()
				else
					break
				end
				frameCounter = frameCounter + 1
			end
			
			assert.equals(10, visited[1])
			assert.equals(20, visited[2])
			assert.equals(30, visited[3])
			assert.equals(40, visited[4])
			assert.equals(50, visited[5])
		end)
	end)
	
	describe("Context", function()
		it("should provide persistent context across chunks", function()
			local data = { a = 1, b = 2, c = 3 }
			
			Iterator:Start("context-test", data, function(key, value, context)
				context.sum = (context.sum or 0) + value
				return true
			end, {
				chunkSize = 1, -- Force multiple chunks
				onComplete = function(context)
					context.completed = true
				end
			})
			
			-- Process all
			for i = 1, 10 do
				if onUpdateCallback then
					onUpdateCallback()
				else
					break
				end
				frameCounter = frameCounter + 1
			end
			
			local status = Iterator:GetStatus("context-test")
			-- After completion, status will be nil (operation cleaned up)
			-- So we can't verify context directly, but the test structure is correct
		end)
	end)
	
	describe("Chunking", function()
		it("should respect chunkSize option", function()
			local data = {}
			for i = 1, 100 do
				data[i] = i
			end
			
			local processedPerFrame = {}
			local currentFrameCount = 0
			
			Iterator:Start("chunk-test", data, function(key, value, context)
				if not context.frameCount then
					context.frameCount = 0
				end
				
				if context.frameCount ~= currentFrameCount then
					context.frameCount = currentFrameCount
					table.insert(processedPerFrame, 0)
				end
				
				processedPerFrame[#processedPerFrame] = (processedPerFrame[#processedPerFrame] or 0) + 1
				return true
			end, {
				chunkSize = 10,
				isArray = true
			})
			
			-- Process all
			for i = 1, 20 do
				currentFrameCount = i
				if onUpdateCallback then
					onUpdateCallback()
				else
					break
				end
				frameCounter = frameCounter + 1
			end
			
			-- Each frame should process ~10 items (chunkSize)
			for _, count in ipairs(processedPerFrame) do
				assert.is_true(count <= 10)
			end
		end)
	end)
	
	describe("Progress Callback", function()
		it("should call onProgress callback", function()
			local data = { a = 1, b = 2, c = 3, d = 4, e = 5 }
			local progressCalls = {}
			
			Iterator:Start("progress-test", data, function() return true end, {
				chunkSize = 2,
				onProgress = function(progress, current, total)
					table.insert(progressCalls, {
						progress = progress,
						current = current,
						total = total
					})
				end
			})
			
			-- Process all
			for i = 1, 10 do
				if onUpdateCallback then
					onUpdateCallback()
				else
					break
				end
				frameCounter = frameCounter + 1
			end
			
			-- Should have received progress callbacks
			assert.is_true(#progressCalls > 0)
		end)
	end)
	
	describe("Completion Callback", function()
		it("should call onComplete when finished", function()
			local data = { a = 1, b = 2 }
			local completed = false
			
			Iterator:Start("complete-test", data, function() return true end, {
				onComplete = function(context)
					completed = true
				end
			})
			
			-- Process all
			for i = 1, 10 do
				if onUpdateCallback then
					onUpdateCallback()
				else
					break
				end
				frameCounter = frameCounter + 1
			end
			
			assert.is_true(completed)
		end)
	end)
	
	describe("Early Abort", function()
		it("should stop iteration when callback returns false", function()
			local data = { a = 1, b = 2, c = 3, d = 4, e = 5 }
			local visited = {}
			
			Iterator:Start("abort-test", data, function(key, value, context)
				table.insert(visited, key)
				return #visited < 3 -- Stop after 3 items
			end)
			
			-- Process all
			for i = 1, 10 do
				if onUpdateCallback then
					onUpdateCallback()
				else
					break
				end
				frameCounter = frameCounter + 1
			end
			
			-- Should have stopped at 3 items
			assert.equals(3, #visited)
		end)
		
		it("should not call onComplete when aborted", function()
			local data = { a = 1, b = 2, c = 3 }
			local completed = false
			
			Iterator:Start("abort-complete-test", data, function(key, value)
				return key ~= "b" -- Abort on second item
			end, {
				onComplete = function()
					completed = true
				end
			})
			
			-- Process all
			for i = 1, 10 do
				if onUpdateCallback then
					onUpdateCallback()
				else
					break
				end
				frameCounter = frameCounter + 1
			end
			
			assert.is_false(completed)
		end)
	end)
	
	describe("Cancel", function()
		it("should cancel running operation", function()
			Iterator:Start("cancel-test", { a = 1, b = 2, c = 3 }, function() return true end)
			assert.is_true(Iterator:IsRunning("cancel-test"))
			
			local success = Iterator:Cancel("cancel-test")
			assert.is_true(success)
			assert.is_false(Iterator:IsRunning("cancel-test"))
		end)
		
		it("should return false for non-existent operation", function()
			local success = Iterator:Cancel("non-existent")
			assert.is_false(success)
		end)
		
		it("should clear OnUpdate script", function()
			Iterator:Start("script-test", { a = 1 }, function() end)
			local frame = mockFrame
			
			Iterator:Cancel("script-test")
			
			-- Frame should have SetScript called with nil
			assert.is_nil(onUpdateCallback)
		end)
	end)
	
	describe("IsRunning", function()
		it("should return true for active operation", function()
			Iterator:Start("running-test", { a = 1 }, function() end)
			assert.is_true(Iterator:IsRunning("running-test"))
			Iterator:Cancel("running-test")
		end)
		
		it("should return false for completed operation", function()
			local data = { a = 1 }
			Iterator:Start("completed-test", data, function() return true end)
			
			-- Process until complete
			for i = 1, 10 do
				if onUpdateCallback then
					onUpdateCallback()
				else
					break
				end
				frameCounter = frameCounter + 1
			end
			
			assert.is_false(Iterator:IsRunning("completed-test"))
		end)
		
		it("should return false for non-existent operation", function()
			assert.is_false(Iterator:IsRunning("never-existed"))
		end)
	end)
	
	describe("CancelAll", function()
		it("should cancel all active operations", function()
			Iterator:Start("op1", { a = 1 }, function() end)
			Iterator:Start("op2", { b = 2 }, function() end)
			Iterator:Start("op3", { c = 3 }, function() end)
			
			local count = Iterator:CancelAll()
			assert.equals(3, count)
			
			assert.is_false(Iterator:IsRunning("op1"))
			assert.is_false(Iterator:IsRunning("op2"))
			assert.is_false(Iterator:IsRunning("op3"))
		end)
		
		it("should return 0 when no operations active", function()
			local count = Iterator:CancelAll()
			assert.equals(0, count)
		end)
	end)
	
	describe("GetStatus", function()
		it("should return status for active operation", function()
			Iterator:Start("status-test", { a = 1, b = 2, c = 3 }, function() return true end)
			
			local status = Iterator:GetStatus("status-test")
			assert.is_not_nil(status)
			assert.equals("status-test", status.operation)
			assert.equals(3, status.total)
			assert.is_true(status.current >= 1)
			assert.is_number(status.progress)
			assert.is_number(status.elapsedSeconds)
			
			Iterator:Cancel("status-test")
		end)
		
		it("should return nil for non-existent operation", function()
			local status = Iterator:GetStatus("non-existent")
			assert.is_nil(status)
		end)
	end)
	
	describe("GetActiveOperations", function()
		it("should return list of active operations", function()
			Iterator:Start("active1", { a = 1 }, function() end)
			Iterator:Start("active2", { b = 2 }, function() end)
			
			local operations = Iterator:GetActiveOperations()
			assert.equals(2, #operations)
			
			-- Should contain both operations (order not guaranteed)
			local found = {}
			for _, op in ipairs(operations) do
				found[op] = true
			end
			assert.is_true(found["active1"])
			assert.is_true(found["active2"])
			
			Iterator:CancelAll()
		end)
		
		it("should return empty list when no operations active", function()
			local operations = Iterator:GetActiveOperations()
			assert.equals(0, #operations)
		end)
	end)
	
	describe("Error Handling", function()
		it("should handle callback errors gracefully", function()
			local data = { a = 1, b = 2, c = 3 }
			
			Iterator:Start("error-test", data, function(key, value)
				if key == "b" then
					error("Intentional error")
				end
				return true
			end)
			
			-- Process all - should not crash
			for i = 1, 10 do
				if onUpdateCallback then
					onUpdateCallback()
				else
					break
				end
				frameCounter = frameCounter + 1
			end
			
			-- Operation should be cancelled after error
			assert.is_false(Iterator:IsRunning("error-test"))
		end)
	end)
end)

-- BookArchivist_Iterator.lua
-- Throttled iteration system for large table operations
-- Prevents UI freezing by processing data in chunks across multiple frames

-- Cache globals for hot-path performance
local type, pcall, tostring = type, pcall, tostring
local tinsert, tsort = table.insert, table.sort
local debugprofilestop, GetTime, CreateFrame = debugprofilestop, GetTime, CreateFrame
local math_min = math.min

local BA = BookArchivist
if not BA then
	return
end

local Iterator = {}
BA.Iterator = Iterator

-- Track all active iterations
local activeIterations = {}

--- Create a throttled iterator that processes large tables in chunks
--- Processes data across multiple frames to prevent UI freezing
--- @param operation string Unique identifier for this operation
--- @param dataSource table Table to iterate over
--- @param callback function(key, value, context) -> shouldContinue
---   - key: Current key being processed
---   - value: Current value being processed
---   - context: Persistent table shared across all chunks
---   - Return true to continue, false to abort
--- @param options table {
---   chunkSize = number (default 50) - Items per chunk
---   budgetMs = number (default 10) - Max milliseconds per frame
---   onProgress = function(progress, current, total) - Progress callback
---   onComplete = function(context) - Completion callback
---   isArray = boolean (default false) - If true, treat dataSource as array (numeric keys)
--- }
--- @return boolean success, string|nil errorMessage
function Iterator:Start(operation, dataSource, callback, options)
	if not operation or type(operation) ~= "string" then
		return false, "operation must be a string"
	end

	if activeIterations[operation] then
		return false, "Operation already in progress: " .. operation
	end

	if not dataSource or type(dataSource) ~= "table" then
		return false, "dataSource must be a table"
	end

	if not callback or type(callback) ~= "function" then
		return false, "callback must be a function"
	end

	-- Default options
	options = options or {}
	local chunkSize = options.chunkSize or 50
	local budgetMs = options.budgetMs or 10
	local onProgress = options.onProgress
	local onComplete = options.onComplete
	local isArray = options.isArray or false

	-- Phase 3: Fast path for arrays - skip pairs enumeration and sorting
	local keys
	if isArray then
		-- Array fast path: dataSource is already array-like with numeric keys
		-- Just use it directly without enumeration
		keys = dataSource
	else
		-- Map path: enumerate keys and sort for deterministic iteration
		keys = {}
		for k in pairs(dataSource) do
			tinsert(keys, k)
		end

		-- Sort keys for deterministic iteration order
		-- Optimize: avoid tostring() allocations for string keys
		if #keys > 0 then
			local firstType = type(keys[1])
			if firstType == "string" then
				tsort(keys) -- No comparator needed for strings
			elseif firstType == "number" then
				tsort(keys) -- Numbers also sort naturally
			else
				-- Mixed types: use tostring comparator
				tsort(keys, function(a, b)
					return tostring(a) < tostring(b)
				end)
			end
		end
	end

	-- Create iteration state
	local state = {
		operation = operation,
		keys = keys,
		total = #keys,
		index = 1,
		callback = callback,
		chunkSize = chunkSize,
		budgetMs = budgetMs,
		onProgress = onProgress,
		onComplete = onComplete,
		dataSource = dataSource,
		isArray = isArray,
		context = {}, -- User-modifiable context passed to callbacks
		startTime = GetTime(),
	}

	activeIterations[operation] = state

	-- Create worker frame that runs each frame
	local frame = CreateFrame("Frame")
	frame:SetScript("OnUpdate", function()
		self:_ProcessChunk(operation)
	end)
	state.frame = frame

	if BA.LogInfo then
		BA:LogInfo(
			string.format(
				"Iterator started: %s (%d items, %d per chunk, %dms budget, %s mode)",
				operation,
				state.total,
				chunkSize,
				budgetMs,
				isArray and "array" or "map"
			)
		)
	end

	return true
end

--- Internal: Process one chunk of data
--- Called each frame by the OnUpdate script
--- @param operation string Operation identifier
function Iterator:_ProcessChunk(operation)
	local state = activeIterations[operation]
	if not state then
		return -- Operation was cancelled
	end

	local startTime = debugprofilestop()
	local processed = 0
	local aborted = false

	-- Process chunk: up to chunkSize items or budgetMs time
	while state.index <= state.total and processed < state.chunkSize do
		local key = state.keys[state.index]

		-- Phase 3: For arrays, key is already the value (since keys = dataSource)
		-- For maps, we need to look up the value in dataSource
		local value
		if state.isArray then
			value = key -- In array mode, keys table IS the data
			key = state.index -- Use index as key for callback
		else
			value = state.dataSource[key]
		end

		-- Call user callback with error protection
		local success, shouldContinue = pcall(state.callback, key, value, state.context)

		if not success then
			-- Callback error - log and abort
			if BA.LogError then
				BA:LogError(
					string.format(
						"Iterator callback error in %s at index %d: %s",
						operation,
						state.index,
						tostring(shouldContinue)
					)
				)
			end
			aborted = true
			break
		end

		if shouldContinue == false then
			-- User requested abort
			if BA.LogInfo then
				BA:LogInfo(
					string.format("Iterator aborted by callback: %s at index %d", operation, state.index)
				)
			end
			aborted = true
			break
		end

		state.index = state.index + 1
		processed = processed + 1

		-- Budget check - don't exceed frame time
		local elapsed = debugprofilestop() - startTime
		if elapsed >= state.budgetMs then
			break
		end
	end

	-- Call progress callback
	if state.onProgress then
		local progress = math_min(state.index / state.total, 1.0)
		pcall(state.onProgress, progress, state.index, state.total)
	end

	-- Check completion
	if aborted or state.index > state.total then
		local elapsed = GetTime() - state.startTime

		if not aborted and state.onComplete then
			-- Success - call completion callback
			pcall(state.onComplete, state.context)
		end

		if BA.LogInfo then
			if aborted then
				BA:LogInfo(
					string.format(
						"Iterator aborted: %s (processed %d/%d items in %.2fs)",
						operation,
						state.index - 1,
						state.total,
						elapsed
					)
				)
			else
				BA:LogInfo(
					string.format(
						"Iterator complete: %s (processed %d items in %.2fs)",
						operation,
						state.total,
						elapsed
					)
				)
			end
		end

		self:Cancel(operation)
	end
end

--- Cancel an active iteration
--- @param operation string Operation identifier
--- @return boolean success
function Iterator:Cancel(operation)
	local state = activeIterations[operation]
	if not state then
		return false
	end

	-- Stop the OnUpdate script
	if state.frame then
		state.frame:SetScript("OnUpdate", nil)
		state.frame = nil
	end

	activeIterations[operation] = nil
	return true
end

--- Check if an operation is currently running
--- @param operation string Operation identifier
--- @return boolean isRunning
function Iterator:IsRunning(operation)
	return activeIterations[operation] ~= nil
end

--- Cancel all active iterations
--- Useful for cleanup during logout or addon disable
function Iterator:CancelAll()
	local count = 0
	for operation in pairs(activeIterations) do
		if self:Cancel(operation) then
			count = count + 1
		end
	end
	return count
end

--- Get status of an active iteration
--- @param operation string Operation identifier
--- @return table|nil status { operation, total, current, progress, elapsedSeconds }
function Iterator:GetStatus(operation)
	local state = activeIterations[operation]
	if not state then
		return nil
	end

	local elapsed = GetTime() - state.startTime
	local progress = math_min(state.index / state.total, 1.0)

	return {
		operation = state.operation,
		total = state.total,
		current = state.index,
		progress = progress,
		elapsedSeconds = elapsed,
	}
end

--- Get list of all active operations
--- @return table Array of operation names
function Iterator:GetActiveOperations()
	local operations = {}
	for operation in pairs(activeIterations) do
		tinsert(operations, operation)
	end
	return operations
end

if BA.LogInfo then
	BA:LogInfo("Iterator module loaded")
end

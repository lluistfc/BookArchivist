---@diagnostic disable: undefined-global
-- BookArchivist_Profiler.lua
-- Performance profiling infrastructure for measuring and optimizing hot paths.

local BA = BookArchivist

local Profiler = {}
BA.Profiler = Profiler

local profiles = {}
local startTimes = {}
local enabled = false

-- Module loaded confirmation
if BookArchivist and BookArchivist.DebugPrint then
	BookArchivist:DebugPrint("[Profiler] Module loaded")
end

--- Enable or disable profiler
--- @param state boolean
function Profiler:SetEnabled(state)
	enabled = state and true or false
	if not enabled then
		self:Reset()
	end
end

--- Check if profiler is enabled
--- @return boolean
function Profiler:IsEnabled()
	return enabled
end

--- Start profiling a labeled operation
--- @param label string Unique identifier for this operation
function Profiler:Start(label)
	if not enabled then
		return
	end
	if not label then
		return
	end

	startTimes[label] = debugprofilestop()
end

--- Stop profiling an operation and record metrics
--- @param label string Must match the label passed to Start()
--- @return number elapsed Milliseconds elapsed since Start()
function Profiler:Stop(label)
	if not enabled then
		return 0
	end
	if not label or not startTimes[label] then
		return 0
	end

	local elapsed = debugprofilestop() - startTimes[label]

	profiles[label] = profiles[label] or {
		count = 0,
		total = 0,
		max = 0,
		min = math.huge,
		last = 0,
	}

	local p = profiles[label]
	p.count = p.count + 1
	p.total = p.total + elapsed
	p.max = math.max(p.max, elapsed)
	p.min = math.min(p.min, elapsed)
	p.last = elapsed

	startTimes[label] = nil
	return elapsed
end

--- Measure a function call and record its execution time
--- @param label string Profile label
--- @param func function Function to execute
--- @param ... any Arguments to pass to the function
--- @return any... Return values from the function
function Profiler:Measure(label, func, ...)
	if not enabled or not label or not func then
		return func(...)
	end

	self:Start(label)
	local results = { func(...) }
	self:Stop(label)

	return unpack(results)
end

--- Get raw profile data for a specific label
--- @param label string
--- @return table|nil profile data
function Profiler:GetProfile(label)
	return profiles[label]
end

--- Get all profile data
--- @return table profiles Map of label -> profile data
function Profiler:GetAllProfiles()
	return profiles
end

--- Generate a human-readable performance report
--- @param sortBy string|nil "avg", "total", "count", "max" (default: "total")
--- @return string report
function Profiler:Report(sortBy)
	if not enabled then
		return "Profiler is disabled. Enable with /ba profile on"
	end

	sortBy = sortBy or "total"

	local lines = {
		"=== BOOKARCHIVIST PERFORMANCE REPORT ===",
		string.format("Profiler enabled: %s", enabled and "YES" or "NO"),
		string.format("Total operations tracked: %d", self:GetOperationCount()),
		"",
		string.format(
			"%-30s %8s %8s %8s %8s %8s %10s",
			"Operation",
			"Count",
			"Avg(ms)",
			"Max(ms)",
			"Min(ms)",
			"Last(ms)",
			"Total(ms)"
		),
		string.rep("-", 100),
	}

	-- Sort profiles by specified metric
	local sorted = {}
	for label, data in pairs(profiles) do
		table.insert(sorted, {
			label = label,
			data = data,
			sortKey = sortBy == "avg" and (data.total / data.count) or data[sortBy] or 0,
		})
	end

	table.sort(sorted, function(a, b)
		return a.sortKey > b.sortKey
	end)

	-- Format each profile
	for _, item in ipairs(sorted) do
		local label = item.label
		local data = item.data
		local avg = data.count > 0 and (data.total / data.count) or 0

		table.insert(
			lines,
			string.format(
				"%-30s %8d %8.2f %8.2f %8.2f %8.2f %10.2f",
				self:TruncateLabel(label, 30),
				data.count,
				avg,
				data.max,
				data.min == math.huge and 0 or data.min,
				data.last,
				data.total
			)
		)
	end

	table.insert(lines, string.rep("-", 100))
	table.insert(lines, string.format("Total profiled time: %.2f ms", self:GetTotalTime()))
	table.insert(lines, "")
	table.insert(lines, "Sort by: /ba profile <sort> where <sort> = avg, total, count, max")
	table.insert(lines, "Reset: /ba profile reset")
	table.insert(lines, "")

	return table.concat(lines, "\n")
end

--- Truncate label to fit in column width
--- @param label string
--- @param maxWidth number
--- @return string
function Profiler:TruncateLabel(label, maxWidth)
	if #label <= maxWidth then
		return label
	end
	return label:sub(1, maxWidth - 3) .. "..."
end

--- Get total count of all operations
--- @return number
function Profiler:GetOperationCount()
	local count = 0
	for _, data in pairs(profiles) do
		count = count + data.count
	end
	return count
end

--- Get total time across all profiles
--- @return number milliseconds
function Profiler:GetTotalTime()
	local total = 0
	for _, data in pairs(profiles) do
		total = total + data.total
	end
	return total
end

--- Reset all profiling data
function Profiler:Reset()
	profiles = {}
	startTimes = {}
end

--- Get the top N slowest operations
--- @param n number Number of results to return (default: 10)
--- @return table List of {label, avgTime, count}
function Profiler:GetSlowestOperations(n)
	n = n or 10
	local sorted = {}

	for label, data in pairs(profiles) do
		local avg = data.count > 0 and (data.total / data.count) or 0
		table.insert(sorted, {
			label = label,
			avg = avg,
			count = data.count,
			total = data.total,
		})
	end

	table.sort(sorted, function(a, b)
		return a.avg > b.avg
	end)

	local result = {}
	for i = 1, math.min(n, #sorted) do
		table.insert(result, sorted[i])
	end

	return result
end

--- Print a quick summary to chat
function Profiler:PrintSummary()
	if not enabled then
		print("|cFFFF6B6BBookArchivist Profiler:|r Disabled. Use /ba profile on to enable.")
		return
	end

	local slowest = self:GetSlowestOperations(5)
	local lines = {
		"|cFF00FF00BookArchivist Profiler Summary:|r",
		string.format("  Total operations: %d", self:GetOperationCount()),
		string.format("  Total time: %.2f ms", self:GetTotalTime()),
		"  Top 5 slowest (avg):",
	}

	for i, op in ipairs(slowest) do
		table.insert(lines, string.format("    %d. %s: %.2fms (n=%d)", i, op.label, op.avg, op.count))
	end

	for _, line in ipairs(lines) do
		print(line)
	end

	print("  Use |cFFFFFF00/ba profile report|r for full details")
end

---@diagnostic disable: undefined-global, undefined-field

local addonRoot = BookArchivist
if not addonRoot or not addonRoot.UI or not addonRoot.UI.Internal then
	return
end

local Internal = addonRoot.UI.Internal

local function trim(msg)
	if type(msg) ~= "string" then
		return ""
	end
	local cleaned = msg:match("^%s*(.-)%s*$")
	return cleaned or ""
end

local function call(fn)
	if type(fn) == "function" then
		return fn()
	end
end

local function ensureUI()
	if Internal.ensureUI then
		return Internal.ensureUI()
	end
	return false, "BookArchivist UI ensure handler missing"
end

local function refreshAllImpl()
	local Profiler = BookArchivist.Profiler
	if Profiler then
		Profiler:Start("UI_refreshAll")
	end

	BookArchivist:DebugMessage("|cFFFFFF00BookArchivist UI (refreshAllImpl) refreshing...|r")
	local ui = call(Internal.getUIFrame)
	if not ui or not call(Internal.getIsInitialized) then
		BookArchivist:DebugPrint("[BookArchivist] refreshAll skipped (UI not initialized)")
		if Profiler then
			Profiler:Stop("UI_refreshAll")
		end
		return
	end

	BookArchivist:DebugPrint("[BookArchivist] refreshAll")
	local flags = call(Internal.getRefreshFlags) or { list = true, location = true, reader = true }
	local needsList = flags.list
	local needsLocation = flags.location
	local needsReader = flags.reader

	if needsList then
		if Profiler then
			Profiler:Start("UI_rebuildFiltered")
		end
		BookArchivist:DebugPrint("[BookArchivist] refreshAll: starting rebuildFiltered")
		if
			not Internal.safeStep
			or not Internal.safeStep("BookArchivist rebuildFiltered", function()
				call(Internal.rebuildFiltered)
			end)
		then
			BookArchivist:DebugPrint("[BookArchivist] refreshAll: rebuildFiltered failed")
		end
		if Profiler then
			Profiler:Stop("UI_rebuildFiltered")
		end
		if Internal.markRefreshComplete then
			Internal.markRefreshComplete("list")
		end
	end

	if needsLocation then
		BookArchivist:DebugPrint("[BookArchivist] refreshAll: starting rebuildLocationView")
		if
			not Internal.safeStep
			or not Internal.safeStep("BookArchivist rebuildLocationView", function()
				call(Internal.rebuildLocationView)
			end)
		then
			BookArchivist:DebugPrint("[BookArchivist] refreshAll: rebuildLocationView failed")
			return
		end
		if Internal.markRefreshComplete then
			Internal.markRefreshComplete("location")
		end
	end

	if needsList or needsLocation then
		BookArchivist:DebugPrint("[BookArchivist] refreshAll: starting updateList")
		if
			not Internal.safeStep
			or not Internal.safeStep("BookArchivist updateList", function()
				call(Internal.updateList)
			end)
		then
			BookArchivist:DebugPrint("[BookArchivist] refreshAll: updateList failed")
			return
		end
	end

	if needsReader then
		BookArchivist:DebugPrint("[BookArchivist] refreshAll: starting renderSelected")
		if Internal.safeStep then
			Internal.safeStep("BookArchivist renderSelected", function()
				call(Internal.renderSelected)
			end)
		else
			call(Internal.renderSelected)
		end
		if Internal.markRefreshComplete then
			Internal.markRefreshComplete("reader")
		end
	end

	if not (needsList or needsLocation or needsReader) and Internal.setNeedsRefresh then
		Internal.setNeedsRefresh(false)
	end

	if Profiler then
		Profiler:Stop("UI_refreshAll")
	end
end

Internal.refreshAll = refreshAllImpl

function addonRoot.RefreshUI()
	if Internal.requestFullRefresh then
		Internal.requestFullRefresh()
	elseif Internal.setNeedsRefresh then
		Internal.setNeedsRefresh(true)
	end
	BookArchivist:DebugPrint(
		"[BookArchivist] RefreshUI: invoked (UI exists="
			.. tostring(call(Internal.getUIFrame) ~= nil)
			.. ", initialized="
			.. tostring(call(Internal.getIsInitialized))
			.. ")"
	)
	if not call(Internal.getUIFrame) then
		if Internal.chatMessage then
			Internal.chatMessage("|cFFFF0000BookArchivist UI not available, creating...|r")
		end
		call(Internal.ensureUI)
	end
	call(Internal.flushPendingRefresh)
end

local function toggleUI()
	local Profiler = BookArchivist.Profiler
	if Profiler then
		Profiler:Start("UI_toggle")
	end

	local ok, err = ensureUI()
	if not ok then
		if Internal.logError then
			Internal.logError(err or "BookArchivist UI unavailable.")
		end
		if Profiler then
			Profiler:Stop("UI_toggle")
		end
		return
	end

	local frame = call(Internal.getUIFrame)
	if not frame then
		if Profiler then
			Profiler:Stop("UI_toggle")
		end
		return
	end

	if frame:IsShown() then
		frame:Hide()
	else
		-- Don't call requestFullRefresh here - OnShow handler will do it
		-- This prevents duplicate refreshAll calls
		frame:Show()
	end

	if Profiler then
		Profiler:Stop("UI_toggle")
	end
end

addonRoot.ToggleUI = toggleUI

SLASH_BOOKARCHIVIST1 = "/ba"
SLASH_BOOKARCHIVIST2 = "/bookarchivist"
SlashCmdList = SlashCmdList or {}

SlashCmdList["BOOKARCHIVIST"] = function(msg)
	local cleaned = trim(msg or "")
	local verb, rest = cleaned:match("^(%S+)%s*(.*)$")
	verb = (verb or ""):lower()
	rest = trim(rest or "")

	-- Options/Tools window commands
	if verb == "options" or verb == "settings" or verb == "config" then
		if BookArchivist and BookArchivist.UI and BookArchivist.UI.OptionsUI then
			BookArchivist.UI.OptionsUI:Open()
		end
		return
	end

	if verb == "tools" or verb == "import" or verb == "export" then
		if BookArchivist and BookArchivist.UI and BookArchivist.UI.OptionsUI then
			BookArchivist.UI.OptionsUI:OpenTools()
		end
		return
	end

	-- Module status diagnostic - dev only
	if verb == "modules" or verb == "modstatus" then
		-- Module diagnostic requires dev tools
		return
	end

	-- Help command
	if verb == "help" or verb == "?" or verb == "commands" then
		print("|cFF00FF00BookArchivist Commands:|r")
		print("  |cFFFFFF00/ba|r - Open main UI")
		print("  |cFFFFFF00/ba help|r - Show this help")
		print("  |cFFFFFF00/ba options|r - Open options panel")
		print("  |cFFFFFF00/ba import|r - Open import/export tools")

		-- Show dev commands only if dev tools are loaded
		if BookArchivist.DevTools then
			print("")
			print("|cFF00FF00Dev Tools Commands:|r")
			print("  |cFFFFFF00/badev help|r - Show all dev commands")
			print("  |cFFFFFF00/ba modules|r - Check module loading status")
			print("  |cFFFFFF00/ba pool|r - Show frame pool statistics")
			print("  |cFFFFFF00/ba profile|r - Profiler commands")
			print("  |cFFFFFF00/ba iter|r - Iterator commands")
			print("  |cFFFFFF00/ba gentest <count>|r - Generate test books")
			print("  |cFFFFFF00/ba uigrid|r - Toggle UI debug grid")
		end
		return
	end

	-- Frame pool statistics - dev only
	if verb == "pool" or verb == "pools" or verb == "poolstats" then
		print("|cFFFF0000BookArchivist:|r Dev commands not available in production build")
		print("These commands require BookArchivist_Dev.toc to be loaded")
		return
	end

	-- Profiler commands - dev only
	if verb == "profile" then
		print("|cFFFF0000BookArchivist:|r Dev commands not available in production build")
		print("These commands require BookArchivist_Dev.toc to be loaded")
		return
	end

	-- Legacy profiler handler (never reached in production)
	if verb == "_profile_legacy" then
		local Profiler = BookArchivist.Profiler
		if not Profiler then
			print("|cFFFF0000BookArchivist:|r Profiler module not loaded!")
			return
		end

		local subCmd = rest:lower()

		if subCmd == "" or subCmd == "report" then
			-- Print full report
			local report = Profiler:Report("total")
			print(report)
			return
		elseif subCmd == "summary" then
			-- Print quick summary
			Profiler:PrintSummary()
			return
		elseif subCmd == "on" or subCmd == "enable" then
			Profiler:SetEnabled(true)
			print("|cFF00FF00BookArchivist Profiler:|r Enabled")
			return
		elseif subCmd == "off" or subCmd == "disable" then
			Profiler:SetEnabled(false)
			print("|cFFFF6B6BBookArchivist Profiler:|r Disabled")
			return
		elseif subCmd == "reset" or subCmd == "clear" then
			Profiler:Reset()
			print("|cFF00FF00BookArchivist Profiler:|r Data reset")
			return
		elseif subCmd == "avg" or subCmd == "total" or subCmd == "count" or subCmd == "max" then
			local report = Profiler:Report(subCmd)
			print(report)
			return
		elseif subCmd == "slow" then
			local slowest = Profiler:GetSlowestOperations(10)
			print("|cFF00FF00Top 10 Slowest Operations:|r")
			for i, op in ipairs(slowest) do
				print(string.format("  %d. %s: %.2fms avg (n=%d)", i, op.label, op.avg, op.count))
			end
			return
		elseif subCmd == "help" then
			print("|cFF00FF00BookArchivist Profiler Commands:|r")
			print("  /ba profile [report] - Full performance report (default)")
			print("  /ba profile summary - Quick summary")
			print("  /ba profile on/off - Enable/disable profiler")
			print("  /ba profile reset - Clear all data")
			print("  /ba profile <sort> - Sort by: avg, total, count, max")
			print("  /ba profile slow - Show 10 slowest operations")
			return
		else
			print("|cFFFF0000Unknown profile command:|r " .. subCmd)
			print("Type |cFFFFFF00/ba profile help|r for usage")
			return
		end
	end

	-- Iterator commands - dev only
	if verb == "iter" or verb == "iterator" then
		print("|cFFFF0000BookArchivist:|r Dev commands not available in production build")
		print("These commands require BookArchivist_Dev.toc to be loaded")
		return
	end

	-- Legacy iterator handler (never reached in production)
	if verb == "_iter_legacy" or verb == "_iterator_legacy" then
		local Iterator = BookArchivist.Iterator
		if not Iterator then
			print("|cFFFF0000BookArchivist:|r Iterator module not loaded!")
			return
		end

		local subCmd, opName = rest:match("^(%S+)%s*(.*)$")
		subCmd = (subCmd or ""):lower()
		opName = trim(opName or "")

		if subCmd == "test" then
			-- Test iteration with visible progress
			print("|cFF00FF00Iterator Test:|r Starting slow test iteration...")
			Iterator:Start("test_iteration", BookArchivistDB.booksById or {}, function(bookId, entry, context)
				context.count = (context.count or 0) + 1
				return true
			end, {
				chunkSize = 25,
				budgetMs = 3,
				onProgress = function(progress, current, total)
					if current % 100 == 0 then
						print(string.format("|cFFFFFF00  Progress:|r %d/%d (%.1f%%)", current, total, progress * 100))
					end
				end,
				onComplete = function(context)
					print(string.format("|cFF00FF00Iterator Test:|r Complete! Processed %d books", context.count or 0))
				end,
			})
			return
		elseif subCmd == "" or subCmd == "status" then
			-- Show all active iterations
			local operations = Iterator:GetActiveOperations()
			if #operations == 0 then
				print("|cFF00FF00Iterator:|r No active iterations")
			else
				print(string.format("|cFF00FF00Iterator:|r %d active operation(s):", #operations))
				for _, op in ipairs(operations) do
					local status = Iterator:GetStatus(op)
					if status then
						print(
							string.format(
								"  %s: %d/%d (%.1f%%) - %.1fs elapsed",
								op,
								status.current,
								status.total,
								status.progress * 100,
								status.elapsedSeconds
							)
						)
					end
				end
			end
			return
		elseif subCmd == "cancel" then
			if opName == "" then
				print("|cFFFF0000Usage:|r /ba iter cancel <operation>")
				return
			end
			if Iterator:Cancel(opName) then
				print(string.format("|cFF00FF00Iterator:|r Cancelled '%s'", opName))
			else
				print(string.format("|cFFFF0000Iterator:|r No such operation '%s'", opName))
			end
			return
		elseif subCmd == "cancelall" then
			local count = Iterator:CancelAll()
			print(string.format("|cFF00FF00Iterator:|r Cancelled %d operation(s)", count))
			return
		else
			print("|cFFFF0000Unknown iter command:|r " .. subCmd)
			print("Type |cFFFFFF00/ba help|r for usage")
			return
		end
	end

	-- Test data generator commands moved to dev/BookArchivist_DevTools.lua
	-- UI grid debug commands moved to dev/BookArchivist_DevTools.lua

	if
		verb == "uigrid"
		or verb == "uidebug"
		or verb == "gentest"
		or verb == "genpreset"
		or verb == "cleartest"
		or verb == "stats"
	then
		print("|cFFFF0000BookArchivist:|r Dev commands not available in production build")
		print("These commands require BookArchivist_Dev.toc to be loaded")
		return
	end

	-- Legacy UI grid debug (kept for compatibility, but disabled in production)
	if verb == "_uigrid_legacy" or verb == "_uidebug_legacy" then
		print("|cFFFF0000BookArchivist:|r UI debug commands moved to dev tools")
		print("Use /badev grid when BookArchivist_Dev.toc is loaded")
		return
	end

	local okCall, err = pcall(toggleUI)
	if not okCall and Internal.logError then
		Internal.logError(tostring(err))
	end
end

SLASH_BOOKARCHIVISTLIST1 = "/balist"
SlashCmdList["BOOKARCHIVISTLIST"] = function()
	local addon = call(Internal.getAddon)
	if not addon or not addon.GetDB then
		if Internal.logError then
			Internal.logError("BookArchivist not ready.")
		end
		return
	end
	local db = addon:GetDB()
	local order = db.order or {}
	local books = db and (db.booksById or db.books) or {}
	print(string.format("[BookArchivist] %d book(s) in archive", #order))
	for i, key in ipairs(order) do
		local entry = books[key]
		local pageCount = 0
		if entry and entry.pages then
			for _ in pairs(entry.pages) do
				pageCount = pageCount + 1
			end
		end
		print(
			string.format(" #%d key='%s' pages=%d title='%s'", i, tostring(key), pageCount, entry and entry.title or "")
		)
	end
end

SLASH_BOOKARCHIVISTDB1 = "/badb"
SlashCmdList["BOOKARCHIVISTDB"] = function()
	local addon = call(Internal.getAddon)
	if not addon or not addon.GetDB then
		if Internal.logError then
			Internal.logError("BookArchivist not ready.")
		end
		return
	end
	local db = addon:GetDB()
	if not db then
		print("[BookArchivist] DB missing")
		return
	end
	local legacyBooks = db.legacy and db.legacy.books or db.books or {}
	local newBooks = db.booksById or {}
	local order = db.order or {}
	local dbVersion = tostring(db.dbVersion or "?")
	print(
		string.format(
			"[BookArchivist] DB debug: dbVersion=%s legacyBooks=%d booksById=%d order=%d",
			dbVersion,
			legacyBooks and (#{ legacyBooks } or 0) or 0,
			newBooks and (#{ newBooks } or 0) or 0,
			#order
		)
	)

	local shown = 0
	for i, key in ipairs(order) do
		local entry = newBooks[key]
		print(string.format(" #%d id='%s' title='%s'", i, tostring(key), entry and entry.title or ""))
		shown = shown + 1
		if shown >= 10 then
			break
		end
	end
	if shown == 0 then
		print("[BookArchivist] No ordered books to display.")
	end
end

local loadMessageShown = false

local function announceReady()
	-- Just announce addon is ready, don't create UI frames yet
	-- UI frames are created on-demand when user opens window
	if not loadMessageShown then
		loadMessageShown = true
		if print then
			print("|cFF00FF00BookArchivist loaded.|r Type /ba to open.")
		end
	end
end

if CreateFrame then
	local loadFrame = CreateFrame("Frame")
	loadFrame:RegisterEvent("PLAYER_LOGIN")
	loadFrame:SetScript("OnEvent", function(self, event)
		announceReady()
		if event == "PLAYER_LOGIN" then
			self:UnregisterEvent("PLAYER_LOGIN")
		end
	end)
end

if type(IsLoggedIn) == "function" and IsLoggedIn() then
	announceReady()
end

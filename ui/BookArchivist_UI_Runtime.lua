---@diagnostic disable: undefined-global, undefined-field
local addonRoot = BookArchivist
if not addonRoot or not addonRoot.UI or not addonRoot.UI.Internal then
	return
end

local Internal = addonRoot.UI.Internal

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
	BookArchivist:DebugMessage("|cFFFFFF00BookArchivist UI (refreshAllImpl) refreshing...|r")
	local ui = call(Internal.getUIFrame)
	if not ui or not call(Internal.getIsInitialized) then
		BookArchivist:DebugPrint("[BookArchivist] refreshAll skipped (UI not initialized)")
		return
	end

	BookArchivist:DebugPrint("[BookArchivist] refreshAll")
	BookArchivist:DebugPrint("[BookArchivist] refreshAll: starting rebuildFiltered")
	if not Internal.safeStep or not Internal.safeStep("BookArchivist rebuildFiltered", function()
		call(Internal.rebuildFiltered)
	end) then
		BookArchivist:DebugPrint("[BookArchivist] refreshAll: rebuildFiltered failed")
		return
	end

	if not Internal.safeStep or not Internal.safeStep("BookArchivist rebuildLocationView", function()
		call(Internal.rebuildLocationView)
	end) then
		BookArchivist:DebugPrint("[BookArchivist] refreshAll: rebuildLocationView failed")
		return
	end

	BookArchivist:DebugPrint("[BookArchivist] refreshAll: starting updateList")
	if not Internal.safeStep or not Internal.safeStep("BookArchivist updateList", function()
		call(Internal.updateList)
	end) then
		BookArchivist:DebugPrint("[BookArchivist] refreshAll: updateList failed")
		return
	end

	BookArchivist:DebugPrint("[BookArchivist] refreshAll: starting renderSelected")
	if Internal.safeStep then
		Internal.safeStep("BookArchivist renderSelected", function()
			call(Internal.renderSelected)
		end)
	else
		call(Internal.renderSelected)
	end

	if Internal.setNeedsRefresh then
		Internal.setNeedsRefresh(false)
	end
end

Internal.refreshAll = refreshAllImpl

function addonRoot.RefreshUI()
	if Internal.setNeedsRefresh then
		Internal.setNeedsRefresh(true)
	end
	BookArchivist:DebugPrint(
		"[BookArchivist] RefreshUI: invoked (UI exists=" .. tostring(call(Internal.getUIFrame) ~= nil)
			.. ", initialized=" .. tostring(call(Internal.getIsInitialized)) .. ")"
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
	local ok, err = ensureUI()
	if not ok then
		if Internal.logError then
			Internal.logError(err or "BookArchivist UI unavailable.")
		end
		return
	end

	local frame = call(Internal.getUIFrame)
	if not frame then
		return
	end

	if frame:IsShown() then
		frame:Hide()
	else
		if Internal.setNeedsRefresh then
			Internal.setNeedsRefresh(true)
		end
		call(Internal.flushPendingRefresh)
		frame:Show()
	end
end

addonRoot.ToggleUI = toggleUI

SLASH_BOOKARCHIVIST1 = "/ba"
SLASH_BOOKARCHIVIST2 = "/bookarchivist"
SlashCmdList = SlashCmdList or {}
SlashCmdList["BOOKARCHIVIST"] = function()
	local ok, err = pcall(toggleUI)
	if not ok and Internal.logError then
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
	print(string.format("[BookArchivist] %d book(s) in archive", #order))
	for i, key in ipairs(order) do
		local entry = db.books and db.books[key]
		local pageCount = 0
		if entry and entry.pages then
			for _ in pairs(entry.pages) do
				pageCount = pageCount + 1
			end
		end
		print(string.format(" #%d key='%s' pages=%d title='%s'", i, tostring(key), pageCount, entry and entry.title or ""))
	end
end

local loadMessageShown = false

local function tryInitializeAndAnnounce()
	local ok, err = ensureUI()
	if not ok then
		if (not err or not err:find("not ready")) and Internal.logError then
			Internal.logError(err or "BookArchivist UI unavailable.")
		end
		return
	end

	if not loadMessageShown then
		loadMessageShown = true
		if print then
			print("|cFF00FF00BookArchivist UI loaded.|r Type /ba to open.")
		end
	end

	if type(addonRoot.RefreshUI) == "function" then
		addonRoot.RefreshUI()
	end
end

if CreateFrame then
	local loadFrame = CreateFrame("Frame")
	loadFrame:RegisterEvent("PLAYER_LOGIN")
	loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	loadFrame:SetScript("OnEvent", function(self, event)
		tryInitializeAndAnnounce()
		if event == "PLAYER_LOGIN" then
			self:UnregisterEvent("PLAYER_LOGIN")
		end
		if loadMessageShown then
			self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end
	end)
end

if type(IsLoggedIn) == "function" and IsLoggedIn() then
	tryInitializeAndAnnounce()
end

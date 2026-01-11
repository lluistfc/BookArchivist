---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then
	return
end

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
	return (L and L[key]) or key
end

local SEARCH_DEBOUNCE_SECONDS = 0.2

local function getSearchTooltipText()
	local text = L and L["BOOK_SEARCH_TOOLTIP"]
	if text and text ~= "" then
		return text
	end
	return "Search matches all words anywhere in the title or text.\nIt does not require the exact phrase."
end

function ListUI:GetSearchText()
	local box = self:GetFrame("searchBox") or self:GetWidget("searchBox")
	if not box or not box.GetText then
		return ""
	end
	return box:GetText() or ""
end

function ListUI:ClearSearchMatchKinds()
	local search = self.__state.search or {}
	self.__state.search = search
	search.matchFlags = {}
end

function ListUI:SetSearchMatchKind(key, kind)
	if not key or not kind then
		return
	end
	local search = self.__state.search or {}
	self.__state.search = search
	search.matchFlags = search.matchFlags or {}
	local flags = search.matchFlags[key] or {}
	if kind == "title" then
		flags.title = true
	elseif kind == "content" then
		flags.text = true
	end
	search.matchFlags[key] = flags
end

function ListUI:GetSearchMatchKind(key)
	local search = self.__state.search
	if not search or not search.matchFlags then
		return nil
	end
	return search.matchFlags[key]
end

function ListUI:ClearSearch()
	local box = self:GetFrame("searchBox") or self:GetWidget("searchBox")
	if box and box.SetText then
		box:SetText("")
		if box.ClearFocus then
			box:ClearFocus()
		end
	end
	self:RunSearchRefresh()
end

function ListUI:UpdateSearchClearButton()
	local button = self:GetFrame("searchClearButton")
	if not button then
		return
	end
	if self.GetSearchQuery and self:GetSearchQuery() ~= "" then
		button:Show()
	else
		button:Hide()
	end
end

function ListUI:RunSearchRefresh()
	if self.RebuildFiltered then
		self:RebuildFiltered()
	end
	if self.UpdateList then
		self:UpdateList()
	end
end

function ListUI:ScheduleSearchRefresh()
	local search = self.__state.search or {}
	self.__state.search = search
	search.pendingToken = (search.pendingToken or 0) + 1
	local token = search.pendingToken
	if not C_Timer or not C_Timer.After then
		search.pendingToken = nil
		self:RunSearchRefresh()
		return
	end
	C_Timer.After(SEARCH_DEBOUNCE_SECONDS, function()
		if search.pendingToken ~= token then
			return
		end
		search.pendingToken = nil
		self:RunSearchRefresh()
	end)
end

function ListUI:WireSearchBox(searchBox)
	if not (self and searchBox) then
		return
	end

	local instructions = searchBox.Instructions
	if instructions and instructions.SetText then
		instructions:SetText(t("BOOK_SEARCH_PLACEHOLDER"))
	end

	local function syncInstructions(box)
		if not instructions then
			return
		end
		if (box:GetText() or "") == "" then
			instructions:Show()
		else
			instructions:Hide()
		end
	end

	searchBox:SetScript("OnEditFocusGained", function()
		if instructions then
			instructions:Hide()
		end
	end)

	searchBox:SetScript("OnEditFocusLost", function(box)
		syncInstructions(box)
	end)

	searchBox:SetScript("OnEscapePressed", function(box)
		box:SetText("")
		box:ClearFocus()
		syncInstructions(box)
		if self.RunSearchRefresh then
			self:RunSearchRefresh()
		end
		if self.UpdateSearchClearButton then
			self:UpdateSearchClearButton()
		end
	end)

	searchBox:SetScript("OnEnterPressed", function(box)
		box:ClearFocus()
	end)

	searchBox:SetScript("OnTextChanged", function(box, userInput)
		syncInstructions(box)
		if userInput then
			if self.ScheduleSearchRefresh then
				self:ScheduleSearchRefresh()
			elseif self.RunSearchRefresh then
				self:RunSearchRefresh()
			end
			if self.UpdateSearchClearButton then
				self:UpdateSearchClearButton()
			end
		end
	end)

	searchBox:SetScript("OnEnter", function(box)
		if not GameTooltip or not GameTooltip.SetOwner then
			return
		end
		GameTooltip:SetOwner(box, "ANCHOR_BOTTOMLEFT")
		GameTooltip:SetText(getSearchTooltipText(), 1, 1, 1, 1, true)
	end)

	searchBox:SetScript("OnLeave", function()
		if GameTooltip and GameTooltip.Hide then
			GameTooltip:Hide()
		end
	end)

	syncInstructions(searchBox)
end

---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then
	return
end

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
	return (L and L[key]) or key
end

local SORT_OPTIONS = {
	{ value = "title", labelKey = "SORT_TITLE" },
	{ value = "zone", labelKey = "SORT_ZONE" },
	{ value = "firstSeen", labelKey = "SORT_FIRST_SEEN" },
	{ value = "lastSeen", labelKey = "SORT_LAST_SEEN" },
}

local function normalizeTextValue(text)
	text = text or ""
	text = tostring(text)
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	return text:lower()
end

local function getBooksTable(db)
	if not db then
		return nil
	end
	if db.booksById and next(db.booksById) ~= nil then
		return db.booksById
	end
	return db.books
end

local function getZoneLabel(entry)
	if not entry or not entry.location then
		return nil
	end
	local location = entry.location
	if location.zoneText and location.zoneText ~= "" then
		return location.zoneText
	end
	if location.zoneChain and #location.zoneChain > 0 then
		return table.concat(location.zoneChain, " > ")
	end
	return nil
end

local function alphaComparator(db, selector)
	return function(aKey, bKey)
		local books = getBooksTable(db) or {}
		local aEntry = books[aKey] or {}
		local bEntry = books[bKey] or {}
		local aVal = normalizeTextValue(selector(aEntry) or "")
		local bVal = normalizeTextValue(selector(bEntry) or "")
		if aVal == bVal then
			return aKey < bKey
		end
		return aVal < bVal
	end
end

local function numericComparator(db, selector, desc)
	return function(aKey, bKey)
		local books = getBooksTable(db) or {}
		local aEntry = books[aKey] or {}
		local bEntry = books[bKey] or {}
		local aVal = selector(aEntry) or 0
		local bVal = selector(bEntry) or 0
		if aVal == bVal then
			return aKey < bKey
		end
		if desc then
			return aVal > bVal
		end
		return aVal < bVal
	end
end

function ListUI:GetSortOptions()
	local opts = {}
	for i, opt in ipairs(SORT_OPTIONS) do
		opts[i] = { value = opt.value, label = t(opt.labelKey) }
	end
	return opts
end

function ListUI:GetSortMode()
	local ctx = self:GetContext()
	if ctx and ctx.getSortMode then
		local mode = ctx.getSortMode()
		if mode and mode ~= "" then
			return mode
		end
	end
	return SORT_OPTIONS[1].value
end

function ListUI:SetSortMode(mode)
	local ctx = self:GetContext()
	if ctx and ctx.setSortMode then
		ctx.setSortMode(mode)
	end
end

function ListUI:GetSortComparator(mode, db)
	local books = getBooksTable(db)
	if not books then
		return nil
	end
	if mode == "title" then
		return alphaComparator(db, function(entry)
			return entry.title or ""
		end)
	elseif mode == "zone" then
		return alphaComparator(db, function(entry)
			return getZoneLabel(entry) or "zzzzz"
		end)
	elseif mode == "firstSeen" then
		return numericComparator(db, function(entry)
			return entry.firstSeenAt or entry.createdAt or 0
		end, false)
	elseif mode == "lastSeen" then
		return numericComparator(db, function(entry)
			return entry.lastSeenAt or entry.createdAt or 0
		end, true)
	end
	return nil
end

function ListUI:ApplySort(filteredKeys, db)
	local mode = self:GetSortMode()
	local categoryId = (self.GetCategoryId and self:GetCategoryId()) or "__all__"

	-- Apply user-selected sorting to all views (including Recent and Favorites)
	local comparator = self:GetSortComparator(mode, db)
	if comparator then
		table.sort(filteredKeys, comparator)
	end
	if self.UpdateSortDropdown then
		self:UpdateSortDropdown()
	end
end

function ListUI:InitializeSortDropdown(dropdown)
	if not dropdown or type(UIDropDownMenu_SetWidth) ~= "function" then
		return
	end

	UIDropDownMenu_SetWidth(dropdown, 120)
	UIDropDownMenu_SetText(dropdown, t("SORT_DROPDOWN_PLACEHOLDER"))

	UIDropDownMenu_Initialize(dropdown, function(selfDropdown)
		local currentSort = ListUI:GetSortMode()
		local currentCategory = (ListUI.GetCategoryId and ListUI:GetCategoryId()) or "__all__"

		if ListUI.IsVirtualCategoriesEnabled and ListUI:IsVirtualCategoriesEnabled() then
			local headerCategories = UIDropDownMenu_CreateInfo()
			headerCategories.isTitle = true
			headerCategories.notCheckable = true
			headerCategories.text = t("SORT_GROUP_CATEGORY")
			UIDropDownMenu_AddButton(headerCategories)

			local infoAll = UIDropDownMenu_CreateInfo()
			infoAll.text = t("CATEGORY_ALL")
			infoAll.func = function()
				ListUI:SetCategoryId("__all__")
				ListUI:UpdateSortDropdown()
			end
			infoAll.checked = (currentCategory == "__all__")
			UIDropDownMenu_AddButton(infoAll)

			local infoFav = UIDropDownMenu_CreateInfo()
			infoFav.text = t("CATEGORY_FAVORITES")
			infoFav.func = function()
				ListUI:SetCategoryId("__favorites__")
				ListUI:UpdateSortDropdown()
			end
			infoFav.checked = (currentCategory == "__favorites__")
			UIDropDownMenu_AddButton(infoFav)

			local infoRecent = UIDropDownMenu_CreateInfo()
			infoRecent.text = t("CATEGORY_RECENT")
			infoRecent.func = function()
				ListUI:SetCategoryId("__recent__")
				ListUI:UpdateSortDropdown()
			end
			infoRecent.checked = (currentCategory == "__recent__")
			UIDropDownMenu_AddButton(infoRecent)

			local sep = UIDropDownMenu_CreateInfo()
			sep.disabled = true
			sep.notCheckable = true
			sep.text = " "
			UIDropDownMenu_AddButton(sep)
		end

		local headerSort = UIDropDownMenu_CreateInfo()
		headerSort.isTitle = true
		headerSort.notCheckable = true
		headerSort.text = t("SORT_GROUP_ORDER")
		UIDropDownMenu_AddButton(headerSort)

		for _, option in ipairs(SORT_OPTIONS) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = t(option.labelKey)
			info.value = option.value
			info.func = function()
				ListUI:SetSortMode(option.value)
				ListUI:UpdateSortDropdown()
				ListUI:RebuildFiltered()
				ListUI:UpdateList()
			end
			info.checked = (currentSort == option.value)
			UIDropDownMenu_AddButton(info)
		end
	end)

	self:SetFrame("sortDropdown", dropdown)
	self:UpdateSortDropdown()

	-- Style the dropdown text with gold color
	local dropdownText = _G[dropdown:GetName() .. "Text"]
	if dropdownText and dropdownText.SetTextColor then
		dropdownText:SetTextColor(1.0, 0.82, 0.0)
	end
end

function ListUI:UpdateSortDropdown()
	local dropdown = self:GetFrame("sortDropdown")
	if not dropdown or type(UIDropDownMenu_SetText) ~= "function" then
		return
	end
	local current = self:GetSortMode()
	local label = nil
	for _, option in ipairs(SORT_OPTIONS) do
		if option.value == current then
			label = t(option.labelKey)
			break
		end
	end
	UIDropDownMenu_SetText(dropdown, label or t("SORT_DROPDOWN_PLACEHOLDER"))

	-- Ensure dropdown text stays gold after updates
	local dropdownText = _G[dropdown:GetName() .. "Text"]
	if dropdownText and dropdownText.SetTextColor then
		dropdownText:SetTextColor(1.0, 0.82, 0.0)
	end
end

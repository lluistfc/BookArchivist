---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then
	return
end

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
	return (L and L[key]) or key
end

function ListUI:GetSelectedKey()
	local ctx = self:GetContext()
	if ctx and ctx.getSelectedKey then
		return ctx.getSelectedKey()
	end
end

function ListUI:SetSelectedKey(key)
	local ctx = self:GetContext()
	if ctx and ctx.setSelectedKey then
		ctx.setSelectedKey(key)
	end
end

function ListUI:DisableDeleteButton()
	local ctx = self:GetContext()
	if ctx and ctx.disableDeleteButton then
		ctx.disableDeleteButton()
	end
end

function ListUI:NotifySelectionChanged()
	local ctx = self:GetContext()
	if ctx and ctx.onSelectionChanged then
		ctx.onSelectionChanged()
	end
	if self.UpdateResumeButton then
		self:UpdateResumeButton()
	end
end

function ListUI:ShowBookContextMenu(anchorButton, bookKey)
	if not anchorButton or not bookKey then
		return
	end
	local addon = self:GetAddon()
	if not addon or not addon.Favorites or not addon.Favorites.IsFavorite then
		return
	end
	local isFav = addon.Favorites:IsFavorite(bookKey)
	local menuFrame = self.GetLocationMenuFrame and self:GetLocationMenuFrame() or nil
	if not menuFrame then
		return
	end
	local label = isFav and t("READER_FAVORITE_REMOVE") or t("READER_FAVORITE_ADD")
	local menu = {
		{
			text = label,
			notCheckable = true,
			func = function()
				if isFav and addon.Favorites.Set then
					addon.Favorites:Set(bookKey, false)
				else
					addon.Favorites:Set(bookKey, true)
				end
				if type(addon.RefreshUI) == "function" then
					addon:RefreshUI()
				end
			end,
		},
	}

	local Reader = BookArchivist and BookArchivist.UI and BookArchivist.UI.Reader or nil
	if Reader and Reader.ShowExportForBook then
		menu[#menu + 1] = {
			text = t("LIST_SHARE_BOOK_MENU"),
			notCheckable = true,
			func = function()
				Reader:ShowExportForBook(bookKey)
			end,
		}
	end
	if type(EasyMenu) == "function" then
		EasyMenu(menu, menuFrame, anchorButton, 0, 0, "MENU")
		return
	end

	if
		type(UIDropDownMenu_Initialize) == "function"
		and type(ToggleDropDownMenu) == "function"
		and type(UIDropDownMenu_CreateInfo) == "function"
		and type(UIDropDownMenu_AddButton) == "function"
	then
		UIDropDownMenu_Initialize(menuFrame, function(_, level)
			level = level or 1
			for _, item in ipairs(menu) do
				local info = UIDropDownMenu_CreateInfo()
				for k, v in pairs(item) do
					info[k] = v
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end, "MENU")
		ToggleDropDownMenu(1, nil, menuFrame, anchorButton, 0, 0)
		return
	end

	local first = menu[1]
	if first and type(first.func) == "function" then
		first.func()
	end
end

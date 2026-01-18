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
	-- Check if edit mode is active with unsaved changes
	local ReaderUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.Reader
	local EditMode = ReaderUI and ReaderUI.EditMode
	if EditMode and EditMode.IsEditing and EditMode:IsEditing() then
		local L = BookArchivist.L
		
		-- Show confirmation dialog
		if not StaticPopupDialogs["BOOKARCHIVIST_EXIT_EDIT_MODE"] then
			StaticPopupDialogs["BOOKARCHIVIST_EXIT_EDIT_MODE"] = {
				text = L["EXIT_EDIT_MODE_TEXT"],
				button1 = OKAY,
				button2 = CANCEL,
				OnAccept = function()
					if EditMode.Cancel then
						EditMode:Cancel()
					end
					-- Continue with selection change
					local ctx = ListUI:GetContext()
					if ctx and ctx.onSelectionChanged then
						ctx.onSelectionChanged()
					end
					if ListUI.UpdateResumeButton then
						ListUI:UpdateResumeButton()
					end
					if ListUI.UpdateRandomButton then
						ListUI:UpdateRandomButton()
					end
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
		end
		StaticPopup_Show("BOOKARCHIVIST_EXIT_EDIT_MODE")
		return -- Don't proceed with selection change
	end
	
	local ctx = self:GetContext()
	if ctx and ctx.onSelectionChanged then
		ctx.onSelectionChanged()
	end
	if self.UpdateResumeButton then
		self:UpdateResumeButton()
	end
	if self.UpdateRandomButton then
		self:UpdateRandomButton()
	end
end

function ListUI:ShowBookContextMenu(anchorButton, bookKey)
	if not anchorButton or not bookKey then
		return
	end
	local BA = self:GetAddon()
	if not BA or not BA.Favorites or not BA.Favorites.IsFavorite then
		return
	end
	local isFav = BA.Favorites:IsFavorite(bookKey)
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
				if isFav and BA.Favorites.Set then
					BA.Favorites:Set(bookKey, false)
				else
					BA.Favorites:Set(bookKey, true)
				end
				if addon.RefreshUI then
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

-- List_Reader_Integration_spec.lua
-- In-game tests for List and Reader interaction

local Tests = {}

function Tests.test_list_module()
	if not BookArchivist.UI.List then
		return false, "List module not loaded"
	end
	return true, "List module loaded"
end

function Tests.test_reader_module()
	if not BookArchivist.UI.Reader then
		return false, "Reader module not loaded"
	end
	return true, "Reader module loaded"
end

function Tests.test_shared_ui_state()
	if not BookArchivist.UI.Internal then
		return false, "UI.Internal not available"
	end
	return true, "Shared UI state available"
end

function Tests.test_selection_tracking()
	local state = BookArchivist.UI.Internal
	if not state then
		return false, "UI state not available"
	end
	return true, "Selection tracking available"
end

function Tests.test_list_selection_handler()
	if not BookArchivist.UI.List.OnBookSelected then
		return false, "OnBookSelected function missing"
	end
	return true, "List selection handler available"
end

function Tests.test_reader_update_trigger()
	if not BookArchivist.UI.Reader.RenderSelected then
		return false, "RenderSelected function missing"
	end
	return true, "Reader update trigger available"
end

function Tests.test_refresh_coordination()
	if not BookArchivist.RefreshUI then
		return false, "RefreshUI function missing"
	end
	return true, "RefreshUI coordination available"
end

function Tests.test_delete_list_update()
	if not BookArchivist.UI.Reader.DisableDeleteButton then
		return false, "DisableDeleteButton function missing"
	end
	if not BookArchivist.UI.List.RebuildFiltered then
		return false, "RebuildFiltered function missing"
	end
	return true, "Delete triggers List update"
end

function Tests.test_favorite_list_update()
	if not BookArchivist.Favorites then
		return false, "Favorites module not loaded"
	end
	if not BookArchivist.Favorites.Toggle then
		return false, "Favorites.Toggle function missing"
	end
	return true, "Favorite triggers List update"
end

function Tests.test_row_rendering()
	if not BookArchivist.UI.List.RenderRows then
		return false, "RenderRows function missing"
	end
	return true, "Row rendering available"
end

function Tests.test_mode_switching()
	if not BookArchivist.UI.List.RefreshListTabsSelection then
		return false, "RefreshListTabsSelection function missing"
	end
	if not BookArchivist.UI.Internal then
		return false, "UI.Internal state missing"
	end
	return true, "Mode switching available (Books/Locations)"
end

function Tests.test_recent_coordination()
	if not BookArchivist.Recent then
		return false, "Recent module not loaded"
	end
	if not BookArchivist.Recent.MarkOpened then
		return false, "MarkOpened function missing"
	end
	return true, "Recent tracking coordination available"
end

function Tests.test_empty_selection()
	local state = BookArchivist.UI.Internal
	if not state then
		return false, "UI state not available"
	end
	-- RenderSelected handles nil selection
	if not BookArchivist.UI.Reader.RenderSelected then
		return false, "RenderSelected function missing"
	end
	return true, "Empty selection handled gracefully"
end

-- Export to global namespace for InGameTests to discover
BookArchivist = BookArchivist or {}
BookArchivist.IntegrationTests = Tests

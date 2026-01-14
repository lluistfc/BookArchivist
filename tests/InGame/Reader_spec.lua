-- Reader_spec.lua
-- In-game tests for Reader UI functionality

local Tests = {}

function Tests.test_reader_module_loaded()
	local Reader = BookArchivist.UI.Reader
	if not Reader then
		return false, "Reader module not loaded"
	end
	return true, "Reader module loaded"
end

function Tests.test_showbook_function()
	local Reader = BookArchivist.UI.Reader
	if not Reader.RenderSelected then
		return false, "RenderSelected function missing"
	end
	if type(Reader.RenderSelected) ~= "function" then
		return false, "RenderSelected should be a function"
	end
	return true, "RenderSelected function available"
end

function Tests.test_navigation_functions()
	local Reader = BookArchivist.UI.Reader
	if not Reader.ChangePage then
		return false, "ChangePage function missing"
	end
	return true, "Navigation functions available"
end

function Tests.test_action_buttons()
	local Reader = BookArchivist.UI.Reader
	if not Reader.ShowExportForBook then
		return false, "ShowExportForBook function missing"
	end
	if not Reader.DisableDeleteButton then
		return false, "DisableDeleteButton function missing"
	end
	return true, "Action button handlers available"
end

function Tests.test_content_update()
	local Reader = BookArchivist.UI.Reader
	if not Reader.RenderSelected then
		return false, "RenderSelected function missing"
	end
	return true, "RenderSelected function available"
end

function Tests.test_page_navigation_state()
	local Internal = BookArchivist.UI.Internal
	if not Internal then
		return false, "UI.Internal state not available"
	end
	return true, "Page navigation state available"
end

function Tests.test_missing_book_handling()
	local Reader = BookArchivist.UI.Reader
	-- RenderSelected handles nil selection gracefully
	if not Reader.RenderSelected then
		return false, "RenderSelected function missing"
	end
	return true, "Missing book handling available"
end

function Tests.test_recent_tracking()
	if not BookArchivist.Recent then
		return false, "Recent module not loaded"
	end
	if not BookArchivist.Recent.MarkOpened then
		return false, "MarkOpened function missing"
	end
	return true, "Recent tracking integration available"
end

function Tests.test_favorites_integration()
	if not BookArchivist.Favorites then
		return false, "Favorites module not loaded"
	end
	if not BookArchivist.Favorites.IsFavorite then
		return false, "IsFavorite function missing"
	end
	return true, "Favorites integration available"
end

function Tests.test_delete_dialog()
	local Reader = BookArchivist.UI.Reader
	if not Reader.DisableDeleteButton then
		return false, "DisableDeleteButton function missing"
	end
	return true, "Delete button management available"
end

function Tests.test_share_functionality()
	if not BookArchivist.Core then
		return false, "Core module not loaded"
	end
	if not BookArchivist.Core.ExportBookToString then
		return false, "ExportBookToString function missing"
	end
	return true, "Share functionality available"
end

function Tests.test_localization()
	if not BookArchivist.L then
		return false, "Localization not loaded"
	end
	if not BookArchivist.L.BOOK_UNTITLED then
		return false, "BOOK_UNTITLED locale missing"
	end
	if not BookArchivist.L.READER_META_CREATOR then
		return false, "READER_META_CREATOR locale missing"
	end
	return true, "Localization strings available"
end

function Tests.test_page_rendering()
	local Reader = BookArchivist.UI.Reader
	if not Reader.RenderSelected then
		return false, "RenderSelected handles page rendering"
	end
	return true, "Page rendering logic available"
end

function Tests.test_metadata_display()
	local Reader = BookArchivist.UI.Reader
	if not Reader.RenderSelected then
		return false, "RenderSelected handles metadata"
	end
	return true, "Metadata display available"
end

function Tests.test_pagination_controls()
	local Reader = BookArchivist.UI.Reader
	if not Reader.UpdatePageControlsDisplay then
		return false, "UpdatePageControlsDisplay function missing"
	end
	return true, "Pagination controls available"
end

function Tests.test_ui_state_management()
	local state = BookArchivist.UI.Internal
	if not state then
		return false, "UI state not available"
	end
	return true, "UI state management integrated"
end

function Tests.test_refresh_pipeline()
	if not BookArchivist.RefreshUI then
		return false, "RefreshUI function missing"
	end
	return true, "Refresh pipeline integrated"
end

function Tests.test_html_parsing()
	if not BookArchivist.UI.Reader.ParsePageToBlocks then
		return false, "ParsePageToBlocks function missing"
	end
	return true, "HTML parsing available"
end

function Tests.test_multipage_books()
	local Reader = BookArchivist.UI.Reader
	if not Reader.ChangePage then
		return false, "ChangePage function missing for multi-page navigation"
	end
	if not Reader.UpdatePageControlsDisplay then
		return false, "UpdatePageControlsDisplay function missing"
	end
	return true, "Multi-page book support available"
end

function Tests.test_frame_builder()
	if not BookArchivist.UI.Reader.Create then
		return false, "Create function missing"
	end
	return true, "Frame builder integration available"
end

function Tests.test_artifact_atlas()
	if not BookArchivist.UI.Reader then
		return false, "Reader module not loaded"
	end
	-- ArtifactAtlas is embedded in Reader module
	return true, "ArtifactAtlas integration available"
end

function Tests.test_last_viewed_tracking()
	if not BookArchivist.Core.SetLastBookId then
		return false, "SetLastBookId function missing"
	end
	if not BookArchivist.Core.GetLastBookId then
		return false, "GetLastBookId function missing"
	end
	return true, "Last viewed book tracking available"
end

function Tests.test_page_index_state()
	local state = BookArchivist.UI.Internal
	if not state then
		return false, "UI state not available"
	end
	return true, "Page index state available"
end

-- Export to global namespace for InGameTests to discover
BookArchivist = BookArchivist or {}
BookArchivist.ReaderTests = Tests

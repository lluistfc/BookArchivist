---@diagnostic disable: undefined-global
-- English locale definitions for BookArchivist

BookArchivist = BookArchivist or {}
BookArchivist.__Locales = BookArchivist.__Locales or {}
local Locales = BookArchivist.__Locales

Locales.enUS = {
  -- Addon & options
  ["ADDON_TITLE"] = "Book Archivist",
  ["OPTIONS_TITLE"] = "Book Archivist Options",
  ["OPTIONS_TOOLTIP_OPEN_PANEL"] = "Open the settings panel",

  -- List header / tabs
  ["BOOKS_TAB"] = "Books",
  ["LOCATIONS_TAB"] = "Locations",
  ["BOOK_LIST_HEADER"] = "Saved Books",
  ["BOOK_LIST_SUBHEADER"] = "Saving every page you read",
  ["BOOK_SEARCH_PLACEHOLDER"] = "Search title or text…",
  ["BOOK_SEARCH_TOOLTIP"] = "Search finds books where all your words appear somewhere in the title or text. It does not require the exact phrase.",

  -- Pagination / sort
  ["PAGINATION_PREV"] = "< Prev",
  ["PAGINATION_NEXT"] = "Next >",
  ["PAGINATION_PAGE_SINGLE"] = "Page 1 / 1",
  ["PAGINATION_PAGE_FORMAT"] = "Page %d / %d",
  ["PAGINATION_PAGE_SIZE_FORMAT"] = "%d / page",
  ["SORT_DROPDOWN_PLACEHOLDER"] = "Sorting...",

  -- Sort dropdown grouping labels
  ["SORT_GROUP_CATEGORY"] = "View",
  ["SORT_GROUP_ORDER"] = "Sort by",

  -- Sort option labels
  ["SORT_RECENT"] = "Recently Read",
  ["SORT_TITLE"] = "Title (A–Z)",
  ["SORT_ZONE"] = "Zone",
  ["SORT_FIRST_SEEN"] = "First Seen",
  ["SORT_LAST_SEEN"] = "Last Seen",

  -- Header buttons & help
  ["HEADER_BUTTON_OPTIONS"] = "Options",
  ["HEADER_BUTTON_HELP"] = "Help",
  ["HEADER_HELP_CHAT"] = "Use the search, filters, and sort menu to find any saved book instantly.",
  ["RESUME_LAST_BOOK"] = "Resume last book",

  -- Reader
  ["READER_EMPTY_PROMPT"] = "Select a book from the list",
  ["READER_NO_CONTENT"] = "|cFF888888No content available|r",
  ["READER_FOOTER_HINT"] = "|cFF888888Books are saved as you read them in-game|r",
  ["READER_META_CREATOR"] = "Creator:",
  ["READER_META_MATERIAL"] = "Material:",
  ["READER_META_LAST_VIEWED"] = "Last viewed:",
  ["READER_META_CAPTURED_AUTOMATICALLY"] = "Captured automatically from ItemText.",
  ["READER_PAGE_COUNT_SINGULAR"] = "%d page",
  ["READER_PAGE_COUNT_PLURAL"] = "%d pages",
  ["READER_LAST_VIEWED_AT_FORMAT"] = "Last viewed %s",
  ["READER_DELETE_BUTTON"] = "Delete",
  ["READER_DELETE_TOOLTIP_ENABLED_TITLE"] = "Delete this book",
  ["READER_DELETE_TOOLTIP_ENABLED_BODY"] = "This will permanently remove the book from your archive.",
  ["READER_DELETE_TOOLTIP_DISABLED_TITLE"] = "Select a saved book",
  ["READER_DELETE_TOOLTIP_DISABLED_BODY"] = "Choose a book from the list to enable deletion.",
  ["READER_DELETE_CONFIRM"] = "Delete '%s'? This cannot be undone.",
  ["READER_DELETE_CHAT_SUCCESS"] = "|cFFFF0000Book deleted from archive.|r",
  ["READER_SHARE_BUTTON"] = "Share",
  ["READER_SHARE_TOOLTIP_TITLE"] = "Export this book",
  ["READER_SHARE_TOOLTIP_BODY"] = "Generate an export string for this single book. Copy it with Ctrl+C and share it with others, or paste it into the Import panel (Options → Export / Import) on another character or client.",
  ["READER_SHARE_POPUP_TITLE"] = "Book export string",
  ["READER_SHARE_POPUP_LABEL"] = "Use Ctrl+C to copy this string, then share it with other players or paste it into another client of Book Archivist.",
  ["READER_SHARE_SELECT_ALL"] = "Select All",
  ["SHARE_CHAT_HINT"] = "Create a clickable chat link, or copy the export string below to share directly.",
  ["SHARE_TO_CHAT_BUTTON"] = "Share to Chat",
  ["SHARE_LINK_INSERTED"] = "Chat link inserted! Press Enter to send.",

  -- Import from chat links
  ["IMPORT_PROMPT_TITLE"] = "Import Book",
  ["IMPORT_PROMPT_TEXT"] = "Paste the book export string below:",
  ["IMPORT_PROMPT_HINT"] = "The sender must share the full export string with you separately (outside WoW chat).",
  ["IMPORT_PROMPT_BUTTON"] = "Import",
  ["IMPORT_SUCCESS"] = "Imported: %s",
  ["IMPORT_FAILED"] = "Import failed: %s",
  ["IMPORT_COMPLETED_WITH_WARNINGS"] = "Import completed with warnings",
  ["REQUESTING_BOOK"] = "Requesting book from %s...",
  ["REQUEST_TIMEOUT"] = "No response from %s",
  ["BOOK_NOT_AVAILABLE"] = "Book no longer available for sharing",
  ["IMPORT_PROMPT_TITLE_WITH_DATA"] = "Import: %s",
  ["IMPORT_CONFIRM_MESSAGE"] = "Book received! Click Import to add '%s' to your library.",

  -- Favorites
  ["READER_FAVORITE_ADD"] = "Add to Favorites",
  ["READER_FAVORITE_REMOVE"] = "Remove from Favorites",
  ["CATEGORY_ALL"] = "All books",
  ["CATEGORY_FAVORITES"] = "Favorites",
  ["CATEGORY_RECENT"] = "Recently read",

  -- Options panel
  ["OPTIONS_SUBTITLE_DEBUG"] = "Enable verbose diagnostics to troubleshoot refresh issues.",
  ["OPTIONS_DEBUG_LOGGING_LABEL"] = "Enable debug logging",
  ["OPTIONS_DEBUG_LOGGING_TOOLTIP"] = "Shows extra BookArchivist information in chat for troubleshooting.",
  ["OPTIONS_UI_DEBUG_LABEL"] = "Show UI debug grid",
  ["OPTIONS_UI_DEBUG_TOOLTIP"] = "Highlights layout bounds for troubleshooting. Same as /ba uidebug on/off.",
	["OPTIONS_RESUME_LAST_PAGE_LABEL"] = "Resume on last page",
	["OPTIONS_RESUME_LAST_PAGE_TOOLTIP"] = "When enabled, reopening a saved book returns to the last page you viewed instead of always starting at page 1.",
  ["OPTIONS_EXPORT_IMPORT_LABEL"] = "Export / Import",
  ["OPTIONS_EXPORT_BUTTON"] = "Generate export string",
  ["OPTIONS_EXPORT_LABEL"] = "Export",
  ["OPTIONS_EXPORT_BUTTON_COPY"] = "Copy",
  ["OPTIONS_EXPORT_STATUS_UNAVAILABLE"] = "Export unavailable.",
  ["OPTIONS_EXPORT_STATUS_FAILED"] = "Export failed: %s",
  ["OPTIONS_EXPORT_STATUS_READY"] = "Export ready (%d chars). Click Import here to test/restore, or Copy to share to another client.",
  ["OPTIONS_EXPORT_STATUS_NOTHING_TO_COPY"] = "Nothing to copy yet. Click Export first.",
  ["OPTIONS_EXPORT_STATUS_DEFAULT"] = "No export generated yet.",
  ["OPTIONS_EXPORT_STATUS_COPY_HINT"] = "Press Ctrl+C to copy, then Ctrl+V to paste.",
  ["OPTIONS_IMPORT_LABEL"] = "Import",
  ["OPTIONS_IMPORT_HELP"] = "Paste an export string into the box below. Import starts automatically when valid data is detected.",
  ["OPTIONS_IMPORT_PERF_TIP"] = "How to import:\n1) Generate an export string on the source client\n2) Paste it into the Import box on this client\n3) Wait for the import to finish\n\nTip: Very large exports can be slow to paste. If needed, import in smaller batches.",
  ["OPTIONS_IMPORT_STATUS_DEFAULT"] = "Paste export text to start importing.",
  ["OPTIONS_IMPORT_STATUS_PASTE_HINT"] = "Press Ctrl+V to paste. Import will start automatically.",
  ["OPTIONS_IMPORT_STATUS_PREPARING"] = "Preparing import…",
  ["OPTIONS_IMPORT_STATUS_PHASE_DECODE"] = "Decoding data",
  ["OPTIONS_IMPORT_STATUS_PHASE_PARSED"] = "Reading books",
  ["OPTIONS_IMPORT_STATUS_PHASE_MERGE"] = "Merging books",
  ["OPTIONS_IMPORT_STATUS_PHASE_SEARCH"] = "Updating search index",
  ["OPTIONS_IMPORT_STATUS_PHASE_TITLES"] = "Updating titles",
  ["OPTIONS_IMPORT_STATUS_COMPLETE"] = "Import complete.",
  ["OPTIONS_IMPORT_STATUS_FAILED"] = "Import failed: %s",
  ["OPTIONS_IMPORT_STATUS_ERROR"] = "Import error (%s): %s",
  ["OPTIONS_IMPORT_STATUS_TOO_LARGE"] = "Payload too large. Aborting.",
  ["OPTIONS_IMPORT_STATUS_NO_EXPORT_IN_CLIPBOARD"] = "No export text detected in clipboard. Make sure you clicked Copy on the source client first.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_RECEIVED"] = "Payload received (%d chars). Importing…",
	["OPTIONS_IMPORT_STATUS_UNAVAILABLE"] = "Import unavailable.",
	["OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING"] = "No import data to process.",
	["OPTIONS_IMPORT_STATUS_IN_PROGRESS"] = "Import already in progress.",
	["OPTIONS_IMPORT_STATUS_SUMMARY"] = "Imported: %d new, %d merged",
	["OPTIONS_TOOLTIP_LABEL"] = "Show tooltip 'Archived' tag",
	["OPTIONS_TOOLTIP_TOOLTIP"] = "When enabled, readable items whose text has been saved for this character will show an extra 'Book Archivist: Archived' line in their tooltip.",
  ["OPTIONS_DEBUG_LABEL"] = "Debug mode",
  ["OPTIONS_DEBUG_TOOLTIP"] = "When enabled, shows a debug log below the import box with detailed diagnostics for troubleshooting.",
  ["LOCATION_UNKNOWN_ZONE"] = "Unknown Zone",
  ["LOCATION_UNKNOWN_MOB"] = "Unknown Mob",
  ["LOCATION_LOOTED_LABEL"] = "Looted:",
  ["LOCATION_LOCATION_LABEL"] = "Location:",

  -- Minimap tooltip
  ["MINIMAP_TIP_LEFT"] = "Left-click: Open library",
  ["MINIMAP_TIP_RIGHT"] = "Right-click: Open options",
  ["MINIMAP_TIP_DRAG"] = "Drag: Move button",

  -- List empty states / generic labels
  ["BOOK_META_FALLBACK"] = "Stored automatically when you read",
  ["BOOK_LIST_EMPTY_HEADER"] = "No books captured yet",
  ["PAGINATION_EMPTY_RESULTS"] = "No results",
  ["LIST_EMPTY_SEARCH"] = "No matches. Clear filters or search.",
  ["LIST_EMPTY_NO_BOOKS"] = "No books saved yet. Read any in-game book to capture it.",
  ["LOCATIONS_BROWSE_HEADER"] = "Browse locations",

  -- Count / formatting helpers
  ["COUNT_BOOK_SINGULAR"] = "%d book",
  ["COUNT_BOOK_PLURAL"] = "%d books",
  ["COUNT_BOOKS_FILTERED_FORMAT"] = "%d / %d books",
  ["COUNT_LOCATION_SINGULAR"] = "%d location",
  ["COUNT_LOCATION_PLURAL"] = "%d locations",
  ["LOCATIONS_BREADCRUMB_ROOT"] = "All locations",
  ["COUNT_BOOKS_HERE_PLURAL"] = "%d books here",
  ["COUNT_BOOKS_HERE_SINGULAR"] = "%d book here",
  ["COUNT_SUBLOCATION_SINGULAR"] = "%d sub-location",
  ["COUNT_SUBLOCATION_PLURAL"] = "%d sub-locations",
  ["COUNT_BOOKS_IN_LOCATION_SINGULAR"] = "%d book in this location",
  ["COUNT_BOOKS_IN_LOCATION_PLURAL"] = "%d books in this location",

  -- Location list rows
  ["LOCATION_BACK_TITLE"] = "Back",
  ["LOCATION_BACK_SUBTITLE"] = "Up one level",
  ["LOCATION_EMPTY"] = "Empty location",
  ["LOCATIONS_EMPTY"] = "No saved locations yet",
  ["LOCATIONS_BROWSE_SAVED"] = "Browse saved locations",
  ["LOCATIONS_NO_RESULTS"] = "No locations or books available here.",

  -- Book rows
  ["BOOK_UNTITLED"] = "(Untitled)",
  ["BOOK_UNKNOWN"] = "Unknown Book",
  ["BOOK_MISSING_DATA"] = "Missing data",
	["TOOLTIP_ARCHIVED"] = "Book Archivist: Archived",
  ["SEARCH_MATCH_TITLE"] = "Title match",
  ["SEARCH_MATCH_CONTENT"] = "Text match",
  ["MATCH_TITLE"] = "TITLE",
  ["MATCH_TEXT"] = "TEXT",
	["LIST_SHARE_BOOK_MENU"] = "Share / Export this book",

  -- Language names / options
  ["LANGUAGE_LABEL"] = "Language",
  ["LANGUAGE_NAME_ENGLISH"] = "English",
  ["LANGUAGE_NAME_SPANISH"] = "Spanish",
  ["LANGUAGE_NAME_CATALAN"] = "Catalan",
  ["LANGUAGE_NAME_GERMAN"] = "German",
  ["LANGUAGE_NAME_FRENCH"] = "French",
  ["LANGUAGE_NAME_ITALIAN"] = "Italian",
  ["LANGUAGE_NAME_PORTUGUESE"] = "Portuguese",
}

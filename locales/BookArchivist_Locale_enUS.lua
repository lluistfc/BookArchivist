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

  -- Location / provenance
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

---@diagnostic disable: undefined-global
-- German (deDE) locale definitions for BookArchivist

BookArchivist = BookArchivist or {}
BookArchivist.__Locales = BookArchivist.__Locales or {}
local Locales = BookArchivist.__Locales

Locales.deDE = {
  -- Addon & options
  ["ADDON_TITLE"] = "Bucharchivar",
  ["OPTIONS_TITLE"] = "Bucharchivar-Optionen",
  ["OPTIONS_TOOLTIP_OPEN_PANEL"] = "Einstellungsfenster öffnen",

  -- List header / tabs
  ["BOOKS_TAB"] = "Bücher",
  ["LOCATIONS_TAB"] = "Orte",
  ["BOOK_LIST_HEADER"] = "Gespeicherte Bücher",
  ["BOOK_LIST_SUBHEADER"] = "Jede Seite, die du liest",
  ["BOOK_SEARCH_PLACEHOLDER"] = "Titel oder Text suchen…",
  ["BOOK_SEARCH_TOOLTIP"] = "Die Suche findet Bücher, in denen alle deine Wörter im Titel oder Text vorkommen. Die exakte Wortfolge ist nicht erforderlich.",

  -- Pagination / sort
  ["PAGINATION_PREV"] = "< Zurück",
  ["PAGINATION_NEXT"] = "Weiter >",
  ["PAGINATION_PAGE_SINGLE"] = "Seite 1 / 1",
  ["PAGINATION_PAGE_FORMAT"] = "Seite %d / %d",
  ["PAGINATION_PAGE_SIZE_FORMAT"] = "%d / Seite",
  ["SORT_DROPDOWN_PLACEHOLDER"] = "Sortierung…",

  -- Sort option labels
  ["SORT_RECENT"] = "Zuletzt gelesen",
  ["SORT_TITLE"] = "Titel (A–Z)",
  ["SORT_ZONE"] = "Zone",
  ["SORT_FIRST_SEEN"] = "Zuerst gesehen",
  ["SORT_LAST_SEEN"] = "Zuletzt gesehen",

  -- Header buttons & help
  ["HEADER_BUTTON_OPTIONS"] = "Optionen",
  ["HEADER_BUTTON_HELP"] = "Hilfe",
  ["HEADER_HELP_CHAT"] = "Nutze Suche, Filter und Sortierung, um jedes gespeicherte Buch sofort zu finden.",
  ["RESUME_LAST_BOOK"] = "Letztes Buch fortsetzen",
  ["RESUME_LAST_BOOK"] = "Letztes Buch fortsetzen",

  -- Reader
  ["READER_EMPTY_PROMPT"] = "Wähle ein Buch aus der Liste",
  ["READER_NO_CONTENT"] = "|cFF888888Kein Inhalt verfügbar|r",
  ["READER_FOOTER_HINT"] = "|cFF888888Bücher werden gespeichert, während du sie im Spiel liest|r",
  ["READER_META_CREATOR"] = "Autor:",
  ["READER_META_MATERIAL"] = "Material:",
  ["READER_META_LAST_VIEWED"] = "Zuletzt angesehen:",
  ["READER_META_CAPTURED_AUTOMATICALLY"] = "Automatisch aus ItemText übernommen.",
  ["READER_PAGE_COUNT_SINGULAR"] = "%d Seite",
  ["READER_PAGE_COUNT_PLURAL"] = "%d Seiten",
  ["READER_LAST_VIEWED_AT_FORMAT"] = "Zuletzt angesehen %s",
  ["READER_DELETE_BUTTON"] = "Löschen",
  ["READER_DELETE_TOOLTIP_ENABLED_TITLE"] = "Dieses Buch löschen",
  ["READER_DELETE_TOOLTIP_ENABLED_BODY"] = "Entfernt das Buch dauerhaft aus deinem Archiv.",
  ["READER_DELETE_TOOLTIP_DISABLED_TITLE"] = "Gespeichertes Buch auswählen",
  ["READER_DELETE_TOOLTIP_DISABLED_BODY"] = "Wähle ein Buch aus der Liste, um es zu löschen.",
  ["READER_DELETE_CONFIRM"] = "'%s' löschen? Dies kann nicht rückgängig gemacht werden.",
  ["READER_DELETE_CHAT_SUCCESS"] = "|cFFFF0000Buch aus dem Archiv gelöscht.|r",

  -- Favorites
  ["READER_FAVORITE_ADD"] = "Zu Favoriten hinzufügen",
  ["READER_FAVORITE_REMOVE"] = "Aus Favoriten entfernen",
  ["CATEGORY_ALL"] = "Alle Bücher",
  ["CATEGORY_FAVORITES"] = "Favoriten",
  ["CATEGORY_RECENT"] = "Kürzlich gelesen",
  ["SORT_GROUP_CATEGORY"] = "Ansicht",
  ["SORT_GROUP_ORDER"] = "Sortieren nach",

  -- Options panel
  ["OPTIONS_SUBTITLE_DEBUG"] = "Aktiviere ausführliche Diagnosen, um Aktualisierungsprobleme zu untersuchen.",
  ["OPTIONS_DEBUG_LOGGING_LABEL"] = "Debug-Protokollierung aktivieren",
  ["OPTIONS_DEBUG_LOGGING_TOOLTIP"] = "Zeigt zusätzliche BookArchivist-Informationen im Chat zur Fehleranalyse.",
  ["OPTIONS_UI_DEBUG_LABEL"] = "UI-Raster anzeigen",
  ["OPTIONS_UI_DEBUG_TOOLTIP"] = "Hebt Layoutgrenzen zur Fehleranalyse hervor. Entspricht /ba uidebug on/off.",
	["OPTIONS_RESUME_LAST_PAGE_LABEL"] = "Auf letzter Seite fortsetzen",
	["OPTIONS_RESUME_LAST_PAGE_TOOLTIP"] = "Wenn aktiviert, springt das erneute Öffnen eines gespeicherten Buches zur zuletzt angesehenen Seite, anstatt immer bei Seite 1 zu beginnen.",
  ["OPTIONS_EXPORT_IMPORT_LABEL"] = "Export / Import",
  ["OPTIONS_EXPORT_BUTTON"] = "Exportzeichenkette erzeugen",
  ["OPTIONS_IMPORT_LABEL"] = "Zeichenkette importieren",
  ["OPTIONS_IMPORT_BUTTON"] = "Importieren",

  -- Location / provenance
  ["LOCATION_UNKNOWN_ZONE"] = "Unbekannte Zone",
  ["LOCATION_UNKNOWN_MOB"] = "Unbekannter Gegner",
  ["LOCATION_LOOTED_LABEL"] = "Beute:",
  ["LOCATION_LOCATION_LABEL"] = "Ort:",

  -- Minimap tooltip
  ["MINIMAP_TIP_LEFT"] = "Linksklick: Bibliothek öffnen",
  ["MINIMAP_TIP_RIGHT"] = "Rechtsklick: Optionen öffnen",
  ["MINIMAP_TIP_DRAG"] = "Ziehen: Symbol bewegen",

  -- List empty states / generic labels
  ["BOOK_META_FALLBACK"] = "Automatisch gespeichert, wenn du liest",
  ["BOOK_LIST_EMPTY_HEADER"] = "Noch keine Bücher erfasst",
  ["PAGINATION_EMPTY_RESULTS"] = "Keine Ergebnisse",
  ["LIST_EMPTY_SEARCH"] = "Keine Treffer. Filter oder Suche anpassen.",
  ["LIST_EMPTY_NO_BOOKS"] = "Noch keine Bücher gespeichert. Lies ein Buch im Spiel, um es zu erfassen.",
  ["LOCATIONS_BROWSE_HEADER"] = "Orte durchsuchen",

  -- Count / formatting helpers
  ["COUNT_BOOK_SINGULAR"] = "%d Buch",
  ["COUNT_BOOK_PLURAL"] = "%d Bücher",
  ["COUNT_BOOKS_FILTERED_FORMAT"] = "%d / %d Bücher",
  ["COUNT_LOCATION_SINGULAR"] = "%d Ort",
  ["COUNT_LOCATION_PLURAL"] = "%d Orte",
  ["LOCATIONS_BREADCRUMB_ROOT"] = "Alle Orte",
  ["COUNT_BOOKS_HERE_PLURAL"] = "%d Bücher hier",
  ["COUNT_BOOKS_HERE_SINGULAR"] = "%d Buch hier",
  ["COUNT_SUBLOCATION_SINGULAR"] = "%d Unterort",
  ["COUNT_SUBLOCATION_PLURAL"] = "%d Unterorte",
  ["COUNT_BOOKS_IN_LOCATION_SINGULAR"] = "%d Buch an diesem Ort",
  ["COUNT_BOOKS_IN_LOCATION_PLURAL"] = "%d Bücher an diesem Ort",

  -- Location list rows
  ["LOCATION_BACK_TITLE"] = "Zurück",
  ["LOCATION_BACK_SUBTITLE"] = "Eine Ebene nach oben",
  ["LOCATION_EMPTY"] = "Leerer Ort",
  ["LOCATIONS_EMPTY"] = "Noch keine Orte gespeichert",
  ["LOCATIONS_BROWSE_SAVED"] = "Gespeicherte Orte durchsuchen",
  ["LOCATIONS_NO_RESULTS"] = "Keine Orte oder Bücher hier verfügbar.",

  -- Book rows
  ["BOOK_UNTITLED"] = "(Ohne Titel)",
  ["BOOK_UNKNOWN"] = "Unbekanntes Buch",
  ["BOOK_MISSING_DATA"] = "Fehlende Daten",
	["MATCH_TITLE"] = "TITEL",
	["MATCH_TEXT"] = "TEXT",

  -- Language names / options
  ["LANGUAGE_LABEL"] = "Sprache",
  ["LANGUAGE_NAME_ENGLISH"] = "Englisch",
  ["LANGUAGE_NAME_SPANISH"] = "Spanisch",
  ["LANGUAGE_NAME_CATALAN"] = "Katalanisch",
  ["LANGUAGE_NAME_GERMAN"] = "Deutsch",
  ["LANGUAGE_NAME_FRENCH"] = "Französisch",
  ["LANGUAGE_NAME_ITALIAN"] = "Italienisch",
  ["LANGUAGE_NAME_PORTUGUESE"] = "Portugiesisch",
}

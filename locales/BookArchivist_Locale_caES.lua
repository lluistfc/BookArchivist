---@diagnostic disable: undefined-global
-- Catalan (caES) locale definitions for BookArchivist

BookArchivist = BookArchivist or {}
BookArchivist.__Locales = BookArchivist.__Locales or {}
local Locales = BookArchivist.__Locales

Locales.caES = {
  -- Addon & options
  ["ADDON_TITLE"] = "Arxivista de Llibres",
  ["OPTIONS_TITLE"] = "Opcions d'Arxivista de Llibres",
  ["OPTIONS_TOOLTIP_OPEN_PANEL"] = "Obre el panell d'opcions",

  -- List header / tabs
  ["BOOKS_TAB"] = "Llibres",
  ["LOCATIONS_TAB"] = "Ubicacions",
  ["BOOK_LIST_HEADER"] = "Llibres desats",
  ["BOOK_LIST_SUBHEADER"] = "Desant cada pàgina que llegeixes",
  ["BOOK_SEARCH_PLACEHOLDER"] = "Cerca per títol o text…",

  -- Pagination / sort
  ["PAGINATION_PREV"] = "< Anterior",
  ["PAGINATION_NEXT"] = "Següent >",
  ["PAGINATION_PAGE_SINGLE"] = "Pàgina 1 / 1",
  ["PAGINATION_PAGE_FORMAT"] = "Pàgina %d / %d",
  ["PAGINATION_PAGE_SIZE_FORMAT"] = "%d / pàgina",
  ["SORT_DROPDOWN_PLACEHOLDER"] = "Ordena...",

  -- Sort option labels
  ["SORT_RECENT"] = "Llegits recentment",
  ["SORT_TITLE"] = "Títol (A–Z)",
  ["SORT_ZONE"] = "Zona",
  ["SORT_FIRST_SEEN"] = "Primera vegada vist",
  ["SORT_LAST_SEEN"] = "Darrera vegada vist",

  -- Header buttons & help
  ["HEADER_BUTTON_OPTIONS"] = "Opcions",
  ["HEADER_BUTTON_HELP"] = "Ajuda",
  ["HEADER_HELP_CHAT"] = "Utilitza la cerca, els filtres i el menú d'ordenació per trobar qualsevol llibre desat a l'instant.",

  -- Reader
  ["READER_EMPTY_PROMPT"] = "Selecciona un llibre de la llista",
  ["READER_NO_CONTENT"] = "|cFF888888No hi ha contingut disponible|r",
  ["READER_FOOTER_HINT"] = "|cFF888888Els llibres es desen a mesura que els llegeixes dins del joc|r",
  ["READER_META_CREATOR"] = "Autor:",
  ["READER_META_MATERIAL"] = "Material:",
  ["READER_META_LAST_VIEWED"] = "Darrera vegada vist:",
  ["READER_META_CAPTURED_AUTOMATICALLY"] = "Capturat automàticament des d'ItemText.",
  ["READER_PAGE_COUNT_SINGULAR"] = "%d pàgina",
  ["READER_PAGE_COUNT_PLURAL"] = "%d pàgines",
  ["READER_LAST_VIEWED_AT_FORMAT"] = "Vist per darrera vegada %s",
  ["READER_DELETE_BUTTON"] = "Eliminar",
  ["READER_DELETE_TOOLTIP_ENABLED_TITLE"] = "Elimina aquest llibre",
  ["READER_DELETE_TOOLTIP_ENABLED_BODY"] = "Això eliminarà definitivament el llibre del teu arxiu.",
  ["READER_DELETE_TOOLTIP_DISABLED_TITLE"] = "Selecciona un llibre desat",
  ["READER_DELETE_TOOLTIP_DISABLED_BODY"] = "Tria un llibre de la llista per poder eliminar-lo.",
  ["READER_DELETE_CONFIRM"] = "Vols eliminar '%s'? Aquesta acció no es pot desfer.",
  ["READER_DELETE_CHAT_SUCCESS"] = "|cFFFF0000Llibre eliminat de l'arxiu.|r",

  -- Options panel
  ["OPTIONS_SUBTITLE_DEBUG"] = "Activa diagnòstics detallats per solucionar problemes d'actualització.",
  ["OPTIONS_DEBUG_LOGGING_LABEL"] = "Activa el registre de depuració",
  ["OPTIONS_DEBUG_LOGGING_TOOLTIP"] = "Mostra informació addicional de BookArchivist al xat per diagnosticar problemes.",
  ["OPTIONS_UI_DEBUG_LABEL"] = "Mostra la quadrícula de depuració de la interfície",
  ["OPTIONS_UI_DEBUG_TOOLTIP"] = "Ressalta els límits de disseny per diagnosticar problemes. Igual que /ba uidebug on/off.",

  -- Location / provenance
  ["LOCATION_UNKNOWN_ZONE"] = "Zona desconeguda",
  ["LOCATION_UNKNOWN_MOB"] = "Enemic desconegut",
  ["LOCATION_LOOTED_LABEL"] = "Botí:",
  ["LOCATION_LOCATION_LABEL"] = "Ubicació:",

  -- Minimap tooltip
  ["MINIMAP_TIP_LEFT"] = "Clic esquerre: Obre la biblioteca",
  ["MINIMAP_TIP_RIGHT"] = "Clic dret: Obre les opcions",
  ["MINIMAP_TIP_DRAG"] = "Arrossega: Mou el botó",

  -- List empty states / generic labels
  ["BOOK_META_FALLBACK"] = "Es desa automàticament quan llegeixes",
  ["BOOK_LIST_EMPTY_HEADER"] = "Encara no s'ha desat cap llibre",
  ["PAGINATION_EMPTY_RESULTS"] = "Sense resultats",
  ["LIST_EMPTY_SEARCH"] = "Sense coincidències. Neteja els filtres o la cerca.",
  ["LIST_EMPTY_NO_BOOKS"] = "Encara no s'han desat llibres. Llegeix qualsevol llibre del joc per desar-lo.",
  ["LOCATIONS_BROWSE_HEADER"] = "Explora les ubicacions",

  -- Count / formatting helpers
  ["COUNT_BOOK_SINGULAR"] = "%d llibre",
  ["COUNT_BOOK_PLURAL"] = "%d llibres",
  ["COUNT_BOOKS_FILTERED_FORMAT"] = "%d / %d llibres",
  ["COUNT_LOCATION_SINGULAR"] = "%d ubicació",
  ["COUNT_LOCATION_PLURAL"] = "%d ubicacions",
  ["LOCATIONS_BREADCRUMB_ROOT"] = "Totes les ubicacions",
  ["COUNT_BOOKS_HERE_PLURAL"] = "%d llibres aquí",
  ["COUNT_BOOKS_HERE_SINGULAR"] = "%d llibre aquí",
  ["COUNT_SUBLOCATION_SINGULAR"] = "%d sububicació",
  ["COUNT_SUBLOCATION_PLURAL"] = "%d sububicacions",
  ["COUNT_BOOKS_IN_LOCATION_SINGULAR"] = "%d llibre en aquesta ubicació",
  ["COUNT_BOOKS_IN_LOCATION_PLURAL"] = "%d llibres en aquesta ubicació",

  -- Location list rows
  ["LOCATION_BACK_TITLE"] = "Enrere",
  ["LOCATION_BACK_SUBTITLE"] = "Puja un nivell",
  ["LOCATION_EMPTY"] = "Ubicació buida",
  ["LOCATIONS_EMPTY"] = "Encara no s'han desat ubicacions",
  ["LOCATIONS_BROWSE_SAVED"] = "Explora les ubicacions desades",
  ["LOCATIONS_NO_RESULTS"] = "No hi ha ubicacions ni llibres disponibles aquí.",

  -- Book rows
  ["BOOK_UNTITLED"] = "(Sense títol)",
  ["BOOK_UNKNOWN"] = "Llibre desconegut",
  ["BOOK_MISSING_DATA"] = "Falten dades",

  -- Language names / options
  ["LANGUAGE_LABEL"] = "Idioma",
  ["LANGUAGE_NAME_ENGLISH"] = "Anglès",
  ["LANGUAGE_NAME_SPANISH"] = "Espanyol",
  ["LANGUAGE_NAME_CATALAN"] = "Català",
}

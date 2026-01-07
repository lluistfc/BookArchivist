---@diagnostic disable: undefined-global
-- Catalan (caES) locale definitions for BookArchivist

BookArchivist = BookArchivist or {}
BookArchivist.__Locales = BookArchivist.__Locales or {}
local Locales = BookArchivist.__Locales

Locales.caES = {
  -- Addon & options
  ["ADDON_TITLE"] = "Book Archivist",
  ["OPTIONS_TITLE"] = "Opcions de Book Archivist",
  ["OPTIONS_TOOLTIP_OPEN_PANEL"] = "Obre el panell d'opcions",

  -- List header / tabs
  ["BOOKS_TAB"] = "Llibres",
  ["LOCATIONS_TAB"] = "Ubicacions",
  ["BOOK_LIST_HEADER"] = "Llibres desats",
  ["BOOK_LIST_SUBHEADER"] = "Desant cada pàgina que llegeixes",
  ["BOOK_SEARCH_PLACEHOLDER"] = "Cerca per títol o text…",
  ["BOOK_SEARCH_TOOLTIP"] = "La cerca troba llibres on totes les paraules apareixen al títol o al text. No requereix la frase exacta.",

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
  ["RESUME_LAST_BOOK"] = "Reprèn llibre",

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

  -- Favorites
  ["READER_FAVORITE_ADD"] = "Afegeix als preferits",
  ["READER_FAVORITE_REMOVE"] = "Treu dels preferits",
  ["CATEGORY_ALL"] = "Tots els llibres",
  ["CATEGORY_FAVORITES"] = "Preferits",
  ["CATEGORY_RECENT"] = "Llegits recentment",
  ["SORT_GROUP_CATEGORY"] = "Vista",
  ["SORT_GROUP_ORDER"] = "Ordena per",

  -- Options panel
  ["OPTIONS_SUBTITLE_DEBUG"] = "Activa diagnòstics detallats per solucionar problemes d'actualització.",
  ["OPTIONS_DEBUG_LOGGING_LABEL"] = "Activa el registre de depuració",
  ["OPTIONS_DEBUG_LOGGING_TOOLTIP"] = "Mostra informació addicional de BookArchivist al xat per diagnosticar problemes.",
  ["OPTIONS_UI_DEBUG_LABEL"] = "Mostra la quadrícula de depuració de la interfície",
  ["OPTIONS_UI_DEBUG_TOOLTIP"] = "Ressalta els límits de disseny per diagnosticar problemes. Igual que /ba uidebug on/off.",
	["OPTIONS_RESUME_LAST_PAGE_LABEL"] = "Reprèn a l'última pàgina",
	["OPTIONS_RESUME_LAST_PAGE_TOOLTIP"] = "Quan està activat, en tornar a obrir un llibre desat s'anirà a l'última pàgina que vas veure en lloc de començar sempre a la pàgina 1.",
  ["OPTIONS_EXPORT_IMPORT_LABEL"] = "Exporta / Importa",
  ["OPTIONS_EXPORT_BUTTON"] = "Genera exportació",
  ["OPTIONS_EXPORT_LABEL"] = "Exporta",
  ["OPTIONS_EXPORT_BUTTON_COPY"] = "Copia",
  ["OPTIONS_EXPORT_STATUS_UNAVAILABLE"] = "Exportació no disponible.",
  ["OPTIONS_EXPORT_STATUS_FAILED"] = "Error en exportar: %s",
  ["OPTIONS_EXPORT_STATUS_READY"] = "Exportació preparada (%d caràcters). Fes clic a Importa aquí per provar/restaurar les teves dades, o a Copia per compartir-les amb un altre client.",
  ["OPTIONS_EXPORT_STATUS_NOTHING_TO_COPY"] = "Encara no hi ha res per copiar. Fes primer clic a Exporta.",
  ["OPTIONS_EXPORT_STATUS_DEFAULT"] = "Encara no s'ha generat cap exportació.",
  ["OPTIONS_EXPORT_STATUS_COPY_HINT"] = "Prem Ctrl+C per copiar i després Ctrl+V per enganxar.",
  ["OPTIONS_IMPORT_LABEL"] = "Cadena per importar",
  ["OPTIONS_IMPORT_BUTTON"] = "Importa",
  ["OPTIONS_IMPORT_BUTTON_CAPTURE"] = "Captura enganxat",
  ["OPTIONS_IMPORT_HELP"] = "En aquest client: després d'Exporta pots fer clic a Importa aquí per provar o restaurar les teves pròpies dades sense enganxar res.\n\nPer moure dades a un altre client/compte:\n1) Al client d'origen, fes clic a Exporta i després a Copia.\n2) Comparteix el text d'exportació copiat com vulguis (Discord, llocs de pega, fitxers compartits, etc.).\n3) Al client de destinació, copia aquest text, obre aquest panell, fes clic a Captura enganxat i després prem una vegada Ctrl+V.\n4) Quan l'estat mostri 'Dades rebudes', fes clic a Importa.\n\nNota: un simple Ctrl+V dins del joc no inicia la importació per si sol; l'addon només escolta l'enganxat mentre Captura enganxat està actiu, o reutilitza la teva última Exportació quan simplement fas clic a Importa aquí.",
    ["OPTIONS_IMPORT_PERF_TIP"] = "Consell: Pots enganxar l'exportació completa directament al quadre d'importació amb Ctrl+V, però les cadenes molt grans poden congelar el client del joc durant uns segons mentre acaba l'enganxat. Fes servir Captura enganxat per introduir el text gradualment i evitar aquest pic de rendiment.",
  ["OPTIONS_IMPORT_STATUS_DEFAULT"] = "Enganxa el text d'exportació i espera 'Dades rebudes' abans d'importar.",
  ["OPTIONS_IMPORT_STATUS_PASTE_HINT"] = "Prem ara Ctrl+V per enganxar i després espera 'Dades rebudes'.",
  ["OPTIONS_IMPORT_STATUS_PREPARING"] = "Preparant la importació…",
  ["OPTIONS_IMPORT_STATUS_PHASE_DECODE"] = "Descodificant dades",
  ["OPTIONS_IMPORT_STATUS_PHASE_PARSED"] = "Llegint llibres",
  ["OPTIONS_IMPORT_STATUS_PHASE_MERGE"] = "Fusionant llibres",
  ["OPTIONS_IMPORT_STATUS_PHASE_SEARCH"] = "Actualitzant l'índex de cerca",
  ["OPTIONS_IMPORT_STATUS_PHASE_TITLES"] = "Actualitzant títols",
  ["OPTIONS_IMPORT_STATUS_COMPLETE"] = "Importació completada.",
  ["OPTIONS_IMPORT_STATUS_FAILED"] = "Error en la importació: %s",
  ["OPTIONS_IMPORT_STATUS_TOO_LARGE"] = "Càrrega massa gran. S'està cancel·lant.",
  ["OPTIONS_IMPORT_STATUS_NO_EXPORT_IN_CLIPBOARD"] = "No s'ha detectat cap text d'exportació al porta-retalls. Assegura't d'haver fet clic a Copia al client d'origen.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_RECEIVED"] = "Dades rebudes (%d caràcters). Fes clic a Importa.",
  ["OPTIONS_IMPORT_STATUS_UNAVAILABLE"] = "Importació no disponible.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING"] = "No hi ha dades d'importació per processar.",
  ["OPTIONS_IMPORT_STATUS_IN_PROGRESS"] = "Ja hi ha una importació en curs.",
  ["OPTIONS_IMPORT_STATUS_SUMMARY"] = "Importats: %d nous, %d fusionats",

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
	["MATCH_TITLE"] = "TÍTOL",
	["MATCH_TEXT"] = "TEXT",

  -- Language names / options
  ["LANGUAGE_LABEL"] = "Idioma",
  ["LANGUAGE_NAME_ENGLISH"] = "Anglès",
  ["LANGUAGE_NAME_SPANISH"] = "Espanyol",
    ["LANGUAGE_NAME_CATALAN"] = "Català",
    ["LANGUAGE_NAME_GERMAN"] = "Alemany",
    ["LANGUAGE_NAME_FRENCH"] = "Francès",
    ["LANGUAGE_NAME_ITALIAN"] = "Italià",
    ["LANGUAGE_NAME_PORTUGUESE"] = "Portuguès",
}

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
	["READER_EMPTY_TIP_SEARCH"] = "Consell: Utilitza el quadre de cerca per trobar llibres per títol o text.",
	["READER_EMPTY_TIP_LOCATIONS"] = "Consell: Canvia a Ubicacions per navegar per on els vas trobar.",
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
	["READER_SHARE_BUTTON"] = "Comparteix",
	["READER_SHARE_TOOLTIP_TITLE"] = "Exporta aquest llibre",
	["READER_SHARE_TOOLTIP_BODY"] = "Genera una cadena d'exportació per a aquest únic llibre. Copia-la amb Ctrl+C i comparteix-la amb altres, o enganxa-la al panell d'Importació (Opcions → Exporta / Importa) en un altre personatge o client.",
	["READER_SHARE_POPUP_TITLE"] = "Cadena d'exportació del llibre",
	["READER_SHARE_POPUP_LABEL"] = "Fes servir Ctrl+C per copiar aquesta cadena i després comparteix-la amb altres jugadors o enganxa-la en un altre client de Book Archivist.",
	["READER_SHARE_SELECT_ALL"] = "Selecciona-ho tot",
	["SHARE_CHAT_HINT"] = "Crea un enllaç clicable al xat, o copia la cadena d'exportació a sota per compartir directament.",
	["SHARE_TO_CHAT_BUTTON"] = "Comparteix al xat",
	["SHARE_LINK_INSERTED"] = "Enllaç inserit al xat! Prem Enter per enviar.",

	-- Import from chat links
	["IMPORT_PROMPT_TITLE"] = "Importa llibre",
	["IMPORT_PROMPT_TEXT"] = "Enganxa la cadena d'exportació del llibre a continuació:",
	["IMPORT_PROMPT_HINT"] = "El remitent ha de compartir la cadena d'exportació completa per separat (fora del xat de WoW).",
	["IMPORT_PROMPT_BUTTON"] = "Importa",
	["IMPORT_SUCCESS"] = "Importat: %s",
	["IMPORT_FAILED"] = "Error en importar: %s",
	["IMPORT_COMPLETED_WITH_WARNINGS"] = "Importació completada amb advertiments",
	["REQUESTING_BOOK"] = "Sol·licitant llibre de %s...",
	["REQUEST_TIMEOUT"] = "Sense resposta de %s",
	["BOOK_NOT_AVAILABLE"] = "Llibre ja no disponible per compartir",
	["IMPORT_PROMPT_TITLE_WITH_DATA"] = "Importar: %s",
	["IMPORT_CONFIRM_MESSAGE"] = "Llibre rebut! Fes clic a Importar per afegir '%s' a la teva biblioteca.",

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
	["OPTIONS_IMPORT_EXPORT_DEBUG_BUTTON"] = "Importar / Exportar / Depurar",
	["OPTIONS_IMPORT_EXPORT_DEBUG_TOOLTIP"] = "Obre una finestra separada per importar i exportar llibres.",
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
	["OPTIONS_IMPORT_LABEL"] = "Importa un sol llibre",

	["OPTIONS_IMPORT_HELP"] = "Enganxa una cadena d'exportació al quadre inferior. La importació es fa automàticament quan es detecten dades vàlides.",
	["OPTIONS_IMPORT_PERF_TIP"] = "Com importar en aquest client:\n\n- Des d'un altre client/compte: A l'origen, fes clic a Exporta i després a Copia. En aquest client, obre aquest panell, fes clic a Captura enganxat i després prem Ctrl+V una vegada. La importació començarà automàticament quan es detectin les dades.\n\n- Mateix client després de Copia: Fes clic a Exporta, després a Copia, després (opcionalment) a Captura enganxat i prem Ctrl+V una vegada. Això et permet provar exactament el que s'ha copiat.\n\nImportant: Captura enganxat no pot llegir el porta-retalls per si sol. Només li diu a l'addon que escolti el *proper* Ctrl+V que facis al joc; sense aquest enganxat manual, no s'importa res.\n\nAdvertiment de rendiment: Importar una cadena d'exportació gran pot congelar temporalment el client del joc mentre WoW processa l'enganxat i es descodifiquen els llibres. Per exemple, importar al voltant de 10-15 llibres pot pausar el joc durant 10-15 segons; importar 50 o més llibres pot trigar prop d'un minut, i càrregues molt grans poden fer que l'enganxat falli o fins i tot bloquegi el client degut a limitacions del motor. Sempre que sigui possible, prefereix exportacions més petites o importacions per personatge en lloc d'importacions extremadament grans tot en un.",
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
	["OPTIONS_IMPORT_STATUS_ERROR"] = "Error d'importació (%s): %s",
	["OPTIONS_IMPORT_STATUS_TOO_LARGE"] = "Càrrega massa gran. S'està cancel·lant.",
	["OPTIONS_IMPORT_STATUS_NO_EXPORT_IN_CLIPBOARD"] = "No s'ha detectat cap text d'exportació al porta-retalls. Assegura't d'haver fet clic a Copia al client d'origen.",
	["OPTIONS_IMPORT_STATUS_PAYLOAD_RECEIVED"] = "Dades rebudes (%d caràcters). Important…",
	["OPTIONS_IMPORT_STATUS_UNAVAILABLE"] = "Importació no disponible.",
	["OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING"] = "No hi ha dades d'importació per processar.",
	["OPTIONS_IMPORT_STATUS_IN_PROGRESS"] = "Ja hi ha una importació en curs.",
	["OPTIONS_IMPORT_STATUS_SUMMARY"] = "Importats: %d nous, %d fusionats",
	["OPTIONS_TOOLTIP_LABEL"] = "Mostra l'etiqueta 'Arxivat' a la descripció",
	["OPTIONS_TOOLTIP_TOOLTIP"] = "Quan està activat, els elements llegibles el text dels quals s'ha desat per a aquest personatge mostraran una línia addicional 'Book Archivist: Arxivat' a la seva descripció.",
	["OPTIONS_RELOAD_REQUIRED"] = "Idioma de la interfície principal actualitzat!\n\nRecarregar ara per actualitzar aquest panell?",
	["OPTIONS_RELOAD_NOW"] = "Recarrega ara",
	["OPTIONS_RELOAD_LATER"] = "Ara no",
	["OPTIONS_DEBUG_LABEL"] = "Mode de depuració",
	["OPTIONS_DEBUG_TOOLTIP"] = "Quan està activat, mostra un registre de depuració sota el quadre d'importació amb diagnòstics detallats per solucionar problemes.",

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

	["LIST_SHARE_BOOK_MENU"] = "Comparteix / Exporta aquest llibre",

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

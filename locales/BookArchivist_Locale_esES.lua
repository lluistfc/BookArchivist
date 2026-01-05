---@diagnostic disable: undefined-global
-- Spanish (esES/esMX) locale definitions for BookArchivist

BookArchivist = BookArchivist or {}
BookArchivist.__Locales = BookArchivist.__Locales or {}
local Locales = BookArchivist.__Locales

Locales.esES = {
  -- Addon & options
  ["ADDON_TITLE"] = "Archivista de Libros",
  ["OPTIONS_TITLE"] = "Opciones de Archivista de Libros",
  ["OPTIONS_TOOLTIP_OPEN_PANEL"] = "Abrir el panel de opciones",

  -- List header / tabs
  ["BOOKS_TAB"] = "Libros",
  ["LOCATIONS_TAB"] = "Ubicaciones",
  ["BOOK_LIST_HEADER"] = "Libros guardados",
  ["BOOK_LIST_SUBHEADER"] = "Guardando cada página que lees",
  ["BOOK_SEARCH_PLACEHOLDER"] = "Buscar por título o texto…",

  -- Pagination / sort
  ["PAGINATION_PREV"] = "< Anterior",
  ["PAGINATION_NEXT"] = "Siguiente >",
  ["PAGINATION_PAGE_SINGLE"] = "Página 1 / 1",
  ["PAGINATION_PAGE_FORMAT"] = "Página %d / %d",
  ["PAGINATION_PAGE_SIZE_FORMAT"] = "%d / página",
  ["SORT_DROPDOWN_PLACEHOLDER"] = "Ordenar...",

  -- Sort option labels
  ["SORT_RECENT"] = "Recientemente leídos",
  ["SORT_TITLE"] = "Título (A–Z)",
  ["SORT_ZONE"] = "Zona",
  ["SORT_FIRST_SEEN"] = "Primera vez visto",
  ["SORT_LAST_SEEN"] = "Última vez visto",

  -- Header buttons & help
  ["HEADER_BUTTON_OPTIONS"] = "Opciones",
  ["HEADER_BUTTON_HELP"] = "Ayuda",
  ["HEADER_HELP_CHAT"] = "Usa la búsqueda, los filtros y el menú de ordenación para encontrar cualquier libro guardado al instante.",

  -- Reader
  ["READER_EMPTY_PROMPT"] = "Selecciona un libro de la lista",
  ["READER_NO_CONTENT"] = "|cFF888888No hay contenido disponible|r",
  ["READER_FOOTER_HINT"] = "|cFF888888Los libros se guardan a medida que los lees en el juego|r",
  ["READER_META_CREATOR"] = "Autor:",
  ["READER_META_MATERIAL"] = "Material:",
  ["READER_META_LAST_VIEWED"] = "Última vez visto:",
  ["READER_META_CAPTURED_AUTOMATICALLY"] = "Capturado automáticamente desde ItemText.",
  ["READER_PAGE_COUNT_SINGULAR"] = "%d página",
  ["READER_PAGE_COUNT_PLURAL"] = "%d páginas",
  ["READER_LAST_VIEWED_AT_FORMAT"] = "Visto por última vez %s",
  ["READER_DELETE_BUTTON"] = "Eliminar",
  ["READER_DELETE_TOOLTIP_ENABLED_TITLE"] = "Eliminar este libro",
  ["READER_DELETE_TOOLTIP_ENABLED_BODY"] = "Esto eliminará permanentemente el libro de tu archivo.",
  ["READER_DELETE_TOOLTIP_DISABLED_TITLE"] = "Selecciona un libro guardado",
  ["READER_DELETE_TOOLTIP_DISABLED_BODY"] = "Elige un libro de la lista para poder eliminarlo.",
  ["READER_DELETE_CONFIRM"] = "¿Eliminar '%s'? Esta acción no se puede deshacer.",
  ["READER_DELETE_CHAT_SUCCESS"] = "|cFFFF0000Libro eliminado del archivo.|r",

  -- Options panel
  ["OPTIONS_SUBTITLE_DEBUG"] = "Activa diagnósticos detallados para solucionar problemas de actualización.",
  ["OPTIONS_DEBUG_LOGGING_LABEL"] = "Activar registro de depuración",
  ["OPTIONS_DEBUG_LOGGING_TOOLTIP"] = "Muestra información adicional de BookArchivist en el chat para diagnosticar problemas.",
  ["OPTIONS_UI_DEBUG_LABEL"] = "Mostrar cuadrícula de depuración de la interfaz",
  ["OPTIONS_UI_DEBUG_TOOLTIP"] = "Resalta los límites de diseño para diagnosticar problemas. Igual que /ba uidebug on/off.",

  -- Location / provenance
  ["LOCATION_UNKNOWN_ZONE"] = "Zona desconocida",
  ["LOCATION_UNKNOWN_MOB"] = "Enemigo desconocido",
  ["LOCATION_LOOTED_LABEL"] = "Despojado:",
  ["LOCATION_LOCATION_LABEL"] = "Ubicación:",

  -- Minimap tooltip
  ["MINIMAP_TIP_LEFT"] = "Clic izquierdo: Abrir biblioteca",
  ["MINIMAP_TIP_RIGHT"] = "Clic derecho: Abrir opciones",
  ["MINIMAP_TIP_DRAG"] = "Arrastrar: Mover botón",

  -- List empty states / generic labels
  ["BOOK_META_FALLBACK"] = "Se guarda automáticamente cuando lees",
  ["BOOK_LIST_EMPTY_HEADER"] = "Todavía no se ha guardado ningún libro",
  ["PAGINATION_EMPTY_RESULTS"] = "Sin resultados",
  ["LIST_EMPTY_SEARCH"] = "Sin coincidencias. Limpia los filtros o la búsqueda.",
  ["LIST_EMPTY_NO_BOOKS"] = "Todavía no se han guardado libros. Lee cualquier libro del juego para guardarlo.",
  ["LOCATIONS_BROWSE_HEADER"] = "Explorar ubicaciones",

  -- Count / formatting helpers
  ["COUNT_BOOK_SINGULAR"] = "%d libro",
  ["COUNT_BOOK_PLURAL"] = "%d libros",
  ["COUNT_BOOKS_FILTERED_FORMAT"] = "%d / %d libros",
  ["COUNT_LOCATION_SINGULAR"] = "%d ubicación",
  ["COUNT_LOCATION_PLURAL"] = "%d ubicaciones",
  ["LOCATIONS_BREADCRUMB_ROOT"] = "Todas las ubicaciones",
  ["COUNT_BOOKS_HERE_PLURAL"] = "%d libros aquí",
  ["COUNT_BOOKS_HERE_SINGULAR"] = "%d libro aquí",
  ["COUNT_SUBLOCATION_SINGULAR"] = "%d sububicación",
  ["COUNT_SUBLOCATION_PLURAL"] = "%d sububicaciones",
  ["COUNT_BOOKS_IN_LOCATION_SINGULAR"] = "%d libro en esta ubicación",
  ["COUNT_BOOKS_IN_LOCATION_PLURAL"] = "%d libros en esta ubicación",

  -- Location list rows
  ["LOCATION_BACK_TITLE"] = "Atrás",
  ["LOCATION_BACK_SUBTITLE"] = "Subir un nivel",
  ["LOCATION_EMPTY"] = "Ubicación vacía",
  ["LOCATIONS_EMPTY"] = "Todavía no se han guardado ubicaciones",
  ["LOCATIONS_BROWSE_SAVED"] = "Explorar ubicaciones guardadas",
  ["LOCATIONS_NO_RESULTS"] = "No hay ubicaciones ni libros disponibles aquí.",

  -- Book rows
  ["BOOK_UNTITLED"] = "(Sin título)",
  ["BOOK_UNKNOWN"] = "Libro desconocido",
  ["BOOK_MISSING_DATA"] = "Datos faltantes",

  -- Language names / options
  ["LANGUAGE_LABEL"] = "Idioma",
  ["LANGUAGE_NAME_ENGLISH"] = "Inglés",
  ["LANGUAGE_NAME_SPANISH"] = "Español",
  ["LANGUAGE_NAME_CATALAN"] = "Catalán",
}

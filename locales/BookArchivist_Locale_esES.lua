---@diagnostic disable: undefined-global
-- Spanish (esES/esMX) locale definitions for BookArchivist

BookArchivist = BookArchivist or {}
BookArchivist.__Locales = BookArchivist.__Locales or {}
local Locales = BookArchivist.__Locales

Locales.esES = {
  -- Addon & options
  ["ADDON_TITLE"] = "Book Archivist",
  ["OPTIONS_TITLE"] = "Opciones de Book Archivist",
  ["OPTIONS_TOOLTIP_OPEN_PANEL"] = "Abrir el panel de opciones",

  -- List header / tabs
  ["BOOKS_TAB"] = "Libros",
  ["LOCATIONS_TAB"] = "Ubicaciones",
  ["BOOK_LIST_HEADER"] = "Libros guardados",
  ["BOOK_LIST_SUBHEADER"] = "Guardando cada página que lees",
  ["BOOK_SEARCH_PLACEHOLDER"] = "Buscar por título o texto…",
  ["BOOK_SEARCH_TOOLTIP"] = "La búsqueda encuentra libros donde todas tus palabras aparecen en el título o en el texto. No requiere la frase exacta.",

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
  ["RESUME_LAST_BOOK"] = "Reanudar libro",

  -- Reader
  ["READER_EMPTY_PROMPT"] = "Selecciona un libro de la lista",
  ["READER_EMPTY_TIP_SEARCH"] = "Consejo: Usa el cuadro de búsqueda para encontrar libros por título o texto.",
  ["READER_EMPTY_TIP_LOCATIONS"] = "Consejo: Cambia a Ubicaciones para navegar por donde los encontraste.",
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
  ["READER_SHARE_BUTTON"] = "Compartir",
  ["READER_SHARE_TOOLTIP_TITLE"] = "Exportar este libro",
  ["READER_SHARE_TOOLTIP_BODY"] = "Genera una cadena de exportación para este único libro. Cópiala con Ctrl+C y compártela con otros, o pégala en el panel de Importación (Opciones → Exportar / Importar) en otro personaje o cliente.",
  ["READER_SHARE_POPUP_TITLE"] = "Cadena de exportación del libro",
  ["READER_SHARE_POPUP_LABEL"] = "Usa Ctrl+C para copiar esta cadena y luego compártela con otros jugadores o pégala en otro cliente de Book Archivist.",
  ["READER_SHARE_SELECT_ALL"] = "Seleccionar todo",
  ["SHARE_CHAT_HINT"] = "Crea un enlace clicable en el chat, o copia la cadena de exportación abajo para compartir directamente.",
  ["SHARE_TO_CHAT_BUTTON"] = "Compartir en el chat",
  ["SHARE_LINK_INSERTED"] = "¡Enlace insertado en el chat! Presiona Enter para enviar.",

  -- Import from chat links
  ["IMPORT_PROMPT_TITLE"] = "Importar libro",
  ["IMPORT_PROMPT_TEXT"] = "Pega la cadena de exportación del libro a continuación:",
  ["IMPORT_PROMPT_HINT"] = "El remitente debe compartir la cadena de exportación completa por separado (fuera del chat de WoW).",
  ["IMPORT_PROMPT_BUTTON"] = "Importar",
  ["IMPORT_SUCCESS"] = "Importado: %s",
  ["IMPORT_FAILED"] = "Error al importar: %s",
  ["IMPORT_COMPLETED_WITH_WARNINGS"] = "Importación completada con advertencias",
  ["REQUESTING_BOOK"] = "Solicitando libro de %s...",
  ["REQUEST_TIMEOUT"] = "Sin respuesta de %s",
  ["BOOK_NOT_AVAILABLE"] = "Libro ya no disponible para compartir",
  ["IMPORT_PROMPT_TITLE_WITH_DATA"] = "Importar: %s",
  ["IMPORT_CONFIRM_MESSAGE"] = "¡Libro recibido! Haz clic en Importar para agregar '%s' a tu biblioteca.",

  -- Favorites
  ["READER_FAVORITE_ADD"] = "Añadir a Favoritos",
  ["READER_FAVORITE_REMOVE"] = "Quitar de Favoritos",
  ["CATEGORY_ALL"] = "Todos los libros",
  ["CATEGORY_FAVORITES"] = "Favoritos",
  ["CATEGORY_RECENT"] = "Leídos recientemente",
  ["SORT_GROUP_CATEGORY"] = "Vista",
  ["SORT_GROUP_ORDER"] = "Ordenar por",

  -- Options panel
  ["OPTIONS_SUBTITLE_DEBUG"] = "Activa diagnósticos detallados para solucionar problemas de actualización.",
  ["OPTIONS_DEBUG_LOGGING_LABEL"] = "Activar registro de depuración",
  ["OPTIONS_DEBUG_LOGGING_TOOLTIP"] = "Muestra información adicional de BookArchivist en el chat para diagnosticar problemas.",
  ["OPTIONS_IMPORT_EXPORT_DEBUG_BUTTON"] = "Importar / Exportar / Depurar",
  ["OPTIONS_IMPORT_EXPORT_DEBUG_TOOLTIP"] = "Abre una ventana separada para importar y exportar libros.",
  ["OPTIONS_UI_DEBUG_LABEL"] = "Mostrar cuadrícula de depuración de la interfaz",
  ["OPTIONS_UI_DEBUG_TOOLTIP"] = "Resalta los límites de diseño para diagnosticar problemas. Igual que /ba uidebug on/off.",
	["OPTIONS_RESUME_LAST_PAGE_LABEL"] = "Reanudar en la última página",
	["OPTIONS_RESUME_LAST_PAGE_TOOLTIP"] = "Si está activado, al volver a abrir un libro guardado se irá a la última página que viste en lugar de empezar siempre en la página 1.",
  ["OPTIONS_EXPORT_IMPORT_LABEL"] = "Exportar / Importar",
  ["OPTIONS_EXPORT_BUTTON"] = "Generar exportación",
  ["OPTIONS_EXPORT_LABEL"] = "Exportar",
  ["OPTIONS_EXPORT_BUTTON_COPY"] = "Copiar",
  ["OPTIONS_EXPORT_STATUS_UNAVAILABLE"] = "Exportación no disponible.",
  ["OPTIONS_EXPORT_STATUS_FAILED"] = "Error al exportar: %s",
  ["OPTIONS_EXPORT_STATUS_READY"] = "Exportación lista (%d caracteres). Haz clic en Importar aquí para probar/restaurar, o en Copiar para compartirla con otro cliente.",
  ["OPTIONS_EXPORT_STATUS_NOTHING_TO_COPY"] = "Nada que copiar todavía. Haz clic en Exportar primero.",
  ["OPTIONS_EXPORT_STATUS_DEFAULT"] = "Todavía no se ha generado ninguna exportación.",
  ["OPTIONS_EXPORT_STATUS_COPY_HINT"] = "Pulsa Ctrl+C para copiar y luego Ctrl+V para pegar.",
  ["OPTIONS_IMPORT_LABEL"] = "Importar",

  ["OPTIONS_IMPORT_HELP"] = "Pega una cadena de exportación en el cuadro inferior. La importación comienza automáticamente cuando se detectan datos válidos.",
  ["OPTIONS_IMPORT_PERF_TIP"] = "Cómo importar:\n1) Genera una cadena de exportación en el cliente de origen\n2) Pégala en el cuadro de Importar en este cliente\n3) Espera a que termine la importación\n\nConsejo: Las exportaciones muy grandes pueden ser lentas al pegar. Si es necesario, importa en lotes más pequeños.",
  ["OPTIONS_IMPORT_STATUS_DEFAULT"] = "Pega el texto de exportación para empezar a importar.",
  ["OPTIONS_IMPORT_STATUS_PASTE_HINT"] = "Pulsa Ctrl+V para pegar. La importación empezará automáticamente.",
  ["OPTIONS_IMPORT_STATUS_PREPARING"] = "Preparando importación…",
  ["OPTIONS_IMPORT_STATUS_PHASE_DECODE"] = "Descodificando datos",
  ["OPTIONS_IMPORT_STATUS_PHASE_PARSED"] = "Leyendo libros",
  ["OPTIONS_IMPORT_STATUS_PHASE_MERGE"] = "Combinando libros",
  ["OPTIONS_IMPORT_STATUS_PHASE_SEARCH"] = "Actualizando índice de búsqueda",
  ["OPTIONS_IMPORT_STATUS_PHASE_TITLES"] = "Actualizando títulos",
  ["OPTIONS_IMPORT_STATUS_COMPLETE"] = "Importación completada.",
  ["OPTIONS_IMPORT_STATUS_FAILED"] = "Error de importación: %s",  ["OPTIONS_IMPORT_STATUS_ERROR"] = "Error de importación (%s): %s",  ["OPTIONS_IMPORT_STATUS_TOO_LARGE"] = "Carga demasiado grande. Cancelando.",
  ["OPTIONS_IMPORT_STATUS_NO_EXPORT_IN_CLIPBOARD"] = "No se ha detectado texto de exportación en el portapapeles. Asegúrate de haber hecho clic en Copiar en el cliente de origen.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_RECEIVED"] = "Datos recibidos (%d caracteres). Importando…",
  ["OPTIONS_IMPORT_STATUS_UNAVAILABLE"] = "Importación no disponible.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING"] = "No hay datos de importación para procesar.",
  ["OPTIONS_IMPORT_STATUS_IN_PROGRESS"] = "La importación ya está en curso.",
  ["OPTIONS_IMPORT_STATUS_SUMMARY"] = "Importados: %d nuevos, %d combinados",
	["OPTIONS_TOOLTIP_LABEL"] = "Mostrar etiqueta 'Archivado' en descripción",
	["OPTIONS_TOOLTIP_TOOLTIP"] = "Cuando está activado, los elementos legibles cuyo texto se ha guardado para este personaje mostrarán una línea adicional 'Book Archivist: Archivado' en su descripción.",	["OPTIONS_RELOAD_REQUIRED"] = "Idioma cambiado. Escribe /reload para actualizar este panel de configuración.",  ["OPTIONS_DEBUG_LABEL"] = "Modo de depuración",
  ["OPTIONS_DEBUG_TOOLTIP"] = "Cuando está activado, muestra un registro de depuración debajo del cuadro de importación con diagnósticos detallados para solucionar problemas.",

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
	["MATCH_TITLE"] = "TÍTULO",
	["MATCH_TEXT"] = "TEXTO",

  ["LIST_SHARE_BOOK_MENU"] = "Compartir / Exportar este libro",

  -- Language names / options
  ["LANGUAGE_LABEL"] = "Idioma",
  ["LANGUAGE_NAME_ENGLISH"] = "Inglés",
  ["LANGUAGE_NAME_SPANISH"] = "Español",
  ["LANGUAGE_NAME_CATALAN"] = "Catalán",
  ["LANGUAGE_NAME_GERMAN"] = "Alemán",
  ["LANGUAGE_NAME_FRENCH"] = "Francés",
  ["LANGUAGE_NAME_ITALIAN"] = "Italiano",
  ["LANGUAGE_NAME_PORTUGUESE"] = "Portugués",
}

---@diagnostic disable: undefined-global
-- Spanish (esES/esMX) locale definitions for BookArchivist

local BA = BookArchivist
BA.__Locales = BA.__Locales or {}
local Locales = BA.__Locales

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
	["RANDOM_BOOK_TOOLTIP"] = "Abrir un libro aleatorio de tu biblioteca",

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
	["COPIED"] = "¡Copiado!",
	["SHARE_CHAT_HINT"] = "Crea un enlace clicable en el chat, o copia la cadena de exportación abajo para compartir directamente.",
	["SHARE_TO_CHAT_BUTTON"] = "Compartir en el chat",
	["SHARE_LINK_INSERTED"] = "¡Enlace insertado en el chat! Presiona Enter para enviar.",

	-- Copy to clipboard
	["READER_COPY_BUTTON"] = "Copiar",
	["READER_COPY_TOOLTIP_BODY"] = "Copia el texto del libro al portapapeles. Abre una ventana donde puedes seleccionar y copiar el texto plano.",
	["READER_COPY_POPUP_TITLE"] = "Copiar texto del libro",
	["READER_COPY_POPUP_LABEL"] = "Selecciona el texto abajo y usa Ctrl+C para copiarlo al portapapeles.",
	["READER_COPY_SELECT_ALL"] = "Seleccionar todo",
	-- Waypoint feature
	["READER_WAYPOINT_BUTTON"] = "Poner Marcador",
	["READER_WAYPOINT_TOOLTIP_BODY"] = "Coloca un marcador en el mapa donde se descubrió este libro.",
	["READER_WAYPOINT_UNAVAILABLE"] = "Datos de ubicación no disponibles para este libro.",
	-- Text-to-Speech feature
	["READER_TTS_BUTTON"] = "Leer en Voz Alta",
	["READER_TTS_TOOLTIP_BODY"] = "Usa texto a voz para leer este libro en voz alta. Haz clic de nuevo para detener.",
	["TTS_ENABLE_HINT"] = "Habilita Texto a Voz en Configuración de WoW > Accesibilidad para usar esta función.",
	["READER_TTS_STOP"] = "Detener Lectura",
	["READER_TTS_STOP_TOOLTIP"] = "Detener la reproducción de texto a voz.",
	["READER_TTS_UNAVAILABLE"] = "Texto a voz no disponible en tu sistema.",
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
	["CATEGORY_RECENT"] = "Leídos recientemente",	["CATEGORY_CUSTOM"] = "Libros personalizados",	["SORT_GROUP_CATEGORY"] = "Vista",
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
	["OPTIONS_FONT_SIZE_LABEL"] = "Tamaño de fuente del lector",
	["OPTIONS_FONT_SIZE_TOOLTIP"] = "Ajusta el tamaño del texto en el panel del lector. 100% es el tamaño normal.",
	["OPTIONS_TTS_FOCUS_NAV_LABEL"] = "TTS: Anunciar elementos enfocados",
	["OPTIONS_TTS_FOCUS_NAV_TOOLTIP"] = "Cuando está habilitado, el texto a voz anuncia los elementos de la interfaz (pestañas, botones) mientras navegas con el teclado.",
	["OPTIONS_TTS_LIST_ITEM_LABEL"] = "TTS: Anunciar elementos de la lista",
	["OPTIONS_TTS_LIST_ITEM_TOOLTIP"] = "Cuando está habilitado, el texto a voz anuncia los títulos de los libros y nombres de ubicaciones al enfocar elementos en la lista.",
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
	["OPTIONS_IMPORT_STATUS_FAILED"] = "Error de importación: %s",
	["OPTIONS_IMPORT_STATUS_ERROR"] = "Error de importación (%s): %s",
	["OPTIONS_IMPORT_STATUS_TOO_LARGE"] = "Carga demasiado grande. Cancelando.",
	["OPTIONS_IMPORT_STATUS_NO_EXPORT_IN_CLIPBOARD"] = "No se ha detectado texto de exportación en el portapapeles. Asegúrate de haber hecho clic en Copiar en el cliente de origen.",
	["OPTIONS_IMPORT_STATUS_PAYLOAD_RECEIVED"] = "Datos recibidos (%d caracteres). Importando…",
	["OPTIONS_IMPORT_STATUS_UNAVAILABLE"] = "Importación no disponible.",
	["OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING"] = "No hay datos de importación para procesar.",
	["OPTIONS_IMPORT_STATUS_IN_PROGRESS"] = "La importación ya está en curso.",
	["OPTIONS_IMPORT_STATUS_SUMMARY"] = "Importados: %d nuevos, %d combinados",
	["OPTIONS_TOOLTIP_LABEL"] = "Mostrar etiqueta 'Archivado' en descripción",
	["OPTIONS_TOOLTIP_TOOLTIP"] = "Cuando está activado, los elementos legibles cuyo texto se ha guardado para este personaje mostrarán una línea adicional 'Book Archivist: Archivado' en su descripción.",
	["OPTIONS_RELOAD_REQUIRED"] = "¡Idioma de la interfaz principal actualizado!\n\n¿Recargar ahora para actualizar este panel?",
	["OPTIONS_RELOAD_NOW"] = "Recargar ahora",
	["OPTIONS_RELOAD_LATER"] = "Ahora no",
	["OPTIONS_DEBUG_LABEL"] = "Modo de depuración",
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
	["TOOLTIP_ARCHIVED"] = "Book Archivist: Archivado",
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

	-- Book Echo strings
	["ECHO_FIRST_READ"] = "Descubierto por primera vez %s %s. Ahora, el libro ha vuelto a ti.",
	["ECHO_RETURNED"] = "Has vuelto a estas páginas %d veces. Cada lectura deja su huella.",
	["ECHO_LAST_PAGE"] = "Dejado abierto en la página %d. El resto del relato te espera.",
	["ECHO_LAST_OPENED"] = "Intacto durante %s. Ha pasado el tiempo desde la última vez que pasaste estas páginas.",
	["ECHO_TIME_DAYS"] = "%d días",
	["ECHO_TIME_HOURS"] = "%d horas",
	["ECHO_TIME_MINUTES"] = "%d minutos",
	
	-- Location context phrases
	["LOC_CONTEXT_SHELVES"] = "entre los estantes de",
	["LOC_CONTEXT_ARCHIVES"] = "en los archivos de",
	["LOC_CONTEXT_DEPTHS"] = "en las profundidades de",
	["LOC_CONTEXT_RUINS"] = "entre las ruinas de",
	["LOC_CONTEXT_CANOPY"] = "bajo el dosel de",
	["LOC_CONTEXT_SANDS"] = "en las arenas de",
	["LOC_CONTEXT_PEAKS"] = "en lo alto de los picos de",
	["LOC_CONTEXT_ABOARD"] = "a bordo de",
	["LOC_CONTEXT_SHADOWS"] = "en las sombras de",
	["LOC_CONTEXT_DEEP"] = "en lo profundo de",
	["LOC_CONTEXT_WILDS"] = "a través de las tierras salvajes de",
	["LOC_CONTEXT_SHORES"] = "a lo largo de las costas de",
	["LOC_CONTEXT_ISLE"] = "en la isla de",
	["LOC_CONTEXT_IN"] = "en",
	["NEW_BOOK"] = "Nuevo Libro",
	["SAVE_BOOK"] = "Guardar",
	["BOOK_TITLE_PLACEHOLDER"] = "Introduce el título del libro...",
	["BOOK_TITLE_REQUIRED"] = "Por favor introduce un título para el libro",
	["BOOK_CONTENT_REQUIRED"] = "Por favor escribe contenido en al menos una página",
	["BOOK_SAVE_FAILED"] = "Error al guardar el libro",
	["BOOK_SAVED_SUCCESS"] = "¡Libro guardado con éxito!",
	["SAVE_BOOK_TOOLTIP"] = "Guardar este libro en tu biblioteca",
	["BOOK_TITLE"] = "Título",
	["BOOK_LOCATION"] = "Ubicación",
	["NO_LOCATION_SET"] = "Sin ubicación establecida",
	["USE_CURRENT_LOC"] = "Usar Actual",
	["PAGE_CONTENT"] = "Contenido de la Página",
	["PAGE"] = "Página",
	["PREV_PAGE"] = "< Anterior",
	["NEXT_PAGE"] = "Siguiente >",
	["ADD_PAGE"] = "Añadir Página",
	["PAGE_ADDED"] = "Página añadida",
	["UNKNOWN_LOCATION"] = "Ubicación Desconocida",
	["CANCEL"] = "Cancelar",
	["CUSTOM_BOOK_TITLE_PLACEHOLDER"] = "Título del libro…",
	["CUSTOM_BOOK_TOOLTIP"] = "Libro Personalizado",
	["EXIT_EDIT_MODE_TITLE"] = "¿Salir del modo de edición?",
	["EXIT_EDIT_MODE_TEXT"] = "Tienes cambios sin guardar. ¿Descartarlos?",
	
	-- Focus Navigation (accessibility keyboard navigation)
	["FOCUS_INSTRUCTIONS"] = "Tab: Sig. | Shift+Tab: Ant. | Enter: Activar | Esc: Salir",
	["FOCUS_NO_ELEMENTS"] = "Sin elementos enfocables",
	["FOCUS_SEARCH_BOX"] = "Cuadro de búsqueda",
	["FOCUS_BOOK_ROW"] = "Libro",
	["FOCUS_LOCATION_ROW"] = "Ubicación",
	["FOCUS_CATEGORY_HEADER"] = "Encabezado",
	["FOCUS_CATEGORY_TABS"] = "Pestañas",
	["FOCUS_CATEGORY_FILTERS"] = "Filtros",
	["FOCUS_CATEGORY_LIST"] = "Lista de Libros",
	["FOCUS_CATEGORY_READER"] = "Acciones del Lector",
	["FOCUS_CATEGORY_PAGINATION"] = "Paginación",
	["FOCUS_CATEGORY_OTHER"] = "Otros",
	["FOCUS_BLOCK_HEADER"] = "Cabecera",
	["FOCUS_BLOCK_LIST"] = "Lista",
	["FOCUS_BLOCK_READER"] = "Lector",
	
	-- Pagination buttons
	["PAGINATION_FIRST"] = "Primera Página",
	["PAGINATION_LAST"] = "Última Página",

	-- Reader actions (for focus manager)
	["ACTION_SHARE"] = "Compartir Libro",
	["ACTION_COPY"] = "Copiar Texto",
	["ACTION_WAYPOINT"] = "Establecer Waypoint",
	["ACTION_FAVORITE"] = "Añadir a Favoritos",
	["ACTION_UNFAVORITE"] = "Quitar de Favoritos",
	["ACTION_DELETE"] = "Eliminar Libro",

	-- Tab names for focus manager
	["TAB_BOOKS"] = "Pestaña Libros",
	["TAB_LOCATIONS"] = "Pestaña Ubicaciones",

	-- TTS Preview (accessibility for custom books)
	["TTS_PREVIEW"] = "Vista previa",
	["TTS_STOP_PREVIEW"] = "Detener",
	["TTS_PREVIEW_TOOLTIP_TITLE"] = "Vista previa con TTS",
	["TTS_PREVIEW_TOOLTIP_BODY"] = "Escucha tu página actual usando texto a voz. Útil para revisar texto dictado.",
	["TTS_PREVIEW_EMPTY"] = "Nada que previsualizar. Escribe contenido primero.",
	["TTS_PREVIEW_FAILED"] = "Error en vista previa TTS: ",

	-- Keybindings Panel
	["KEYBINDINGS_PANEL_TITLE"] = "Atajos de teclado",
}

-- ============================================================================
-- Key Binding Localization (Global scope for Bindings.xml)
-- These strings appear in WoW's Key Bindings UI (ESC → Key Bindings)
-- Only set if the game locale is Spanish
-- ============================================================================

if GetLocale() == "esES" or GetLocale() == "esMX" then
	BINDING_HEADER_BOOKARCHIVIST = "Book Archivist"
	BINDING_NAME_BOOKARCHIVIST_TOGGLE = "Mostrar/Ocultar Book Archivist"
	BINDING_NAME_BOOKARCHIVIST_TTS_READ = "Leer libro actual (TTS)"
	BINDING_NAME_BOOKARCHIVIST_TTS_STOP = "Detener lectura (TTS)"
	BINDING_NAME_BOOKARCHIVIST_PAGE_NEXT = "Página siguiente"
	BINDING_NAME_BOOKARCHIVIST_PAGE_PREV = "Página anterior"
	BINDING_NAME_BOOKARCHIVIST_NEW_BOOK = "Nuevo libro personalizado"
	BINDING_NAME_BOOKARCHIVIST_FOCUS_NEXT = "Enfocar siguiente elemento"
	BINDING_NAME_BOOKARCHIVIST_FOCUS_PREV = "Enfocar elemento anterior"
	BINDING_NAME_BOOKARCHIVIST_FOCUS_ACTIVATE = "Activar elemento enfocado"
	BINDING_NAME_BOOKARCHIVIST_FOCUS_TOGGLE = "Alternar navegación por foco"
	BINDING_NAME_BOOKARCHIVIST_FOCUS_NEXT_BLOCK = "Siguiente bloque"
	BINDING_NAME_BOOKARCHIVIST_FOCUS_PREV_BLOCK = "Bloque anterior"
end

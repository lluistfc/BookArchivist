---@diagnostic disable: undefined-global
-- German (deDE) locale definitions for BookArchivist

BookArchivist = BookArchivist or {}
BookArchivist.__Locales = BookArchivist.__Locales or {}
local Locales = BookArchivist.__Locales

Locales.deDE = {
  -- Addon & options
  ["ADDON_TITLE"] = "Book Archivist",
  ["OPTIONS_TITLE"] = "Book Archivist-Optionen",
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
  ["RESUME_LAST_BOOK"] = "Weiterlesen",

  -- Reader
  ["READER_EMPTY_PROMPT"] = "Wähle ein Buch aus der Liste",
  ["READER_EMPTY_TIP_SEARCH"] = "Tipp: Verwende das Suchfeld, um Bücher nach Titel oder Text zu finden.",
  ["READER_EMPTY_TIP_LOCATIONS"] = "Tipp: Wechsle zu Orte, um nach Fundorten zu durchsuchen.",
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
  ["READER_SHARE_BUTTON"] = "Teilen",
  ["READER_SHARE_TOOLTIP_TITLE"] = "Dieses Buch exportieren",
  ["READER_SHARE_TOOLTIP_BODY"] = "Erstelle einen Exportstring für dieses einzelne Buch. Kopiere ihn mit Strg+C und teile ihn mit anderen, oder füge ihn in das Importpanel (Optionen → Export / Import) auf einem anderen Charakter oder Client ein.",
  ["READER_SHARE_POPUP_TITLE"] = "Buch-Exportzeichenkette",
  ["READER_SHARE_POPUP_LABEL"] = "Verwende Strg+C, um diese Zeichenkette zu kopieren, und teile sie dann mit anderen Spielern oder füge sie in einem anderen Book Archivist-Client ein.",
  ["READER_SHARE_SELECT_ALL"] = "Alles auswählen",
  ["SHARE_CHAT_HINT"] = "Erstellen Sie einen anklickbaren Chat-Link oder kopieren Sie die Exportzeichenfolge unten, um sie direkt zu teilen.",
  ["SHARE_TO_CHAT_BUTTON"] = "Im Chat teilen",
  ["SHARE_LINK_INSERTED"] = "Chat-Link eingefügt! Drücken Sie Enter zum Senden.",

  -- Import from chat links
  ["IMPORT_PROMPT_TITLE"] = "Buch importieren",
  ["IMPORT_PROMPT_TEXT"] = "Fügen Sie die Buchexportzeichenfolge unten ein:",
  ["IMPORT_PROMPT_HINT"] = "Der Absender muss die vollständige Exportzeichenfolge separat teilen (außerhalb des WoW-Chats).",
  ["IMPORT_PROMPT_BUTTON"] = "Importieren",
  ["IMPORT_SUCCESS"] = "Importiert: %s",
  ["IMPORT_FAILED"] = "Import fehlgeschlagen: %s",
  ["IMPORT_COMPLETED_WITH_WARNINGS"] = "Import mit Warnungen abgeschlossen",
  ["REQUESTING_BOOK"] = "Buch von %s wird angefordert...",
  ["REQUEST_TIMEOUT"] = "Keine Antwort von %s",
  ["BOOK_NOT_AVAILABLE"] = "Buch nicht mehr zum Teilen verfügbar",
  ["IMPORT_PROMPT_TITLE_WITH_DATA"] = "Importieren: %s",
  ["IMPORT_CONFIRM_MESSAGE"] = "Buch empfangen! Klicke auf Importieren, um '%s' zu deiner Bibliothek hinzuzufügen.",

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
  ["OPTIONS_IMPORT_EXPORT_DEBUG_BUTTON"] = "Importieren / Exportieren / Debuggen",
  ["OPTIONS_IMPORT_EXPORT_DEBUG_TOOLTIP"] = "Öffnet ein separates Fenster zum Importieren und Exportieren von Büchern.",
  ["OPTIONS_UI_DEBUG_LABEL"] = "UI-Raster anzeigen",
  ["OPTIONS_UI_DEBUG_TOOLTIP"] = "Hebt Layoutgrenzen zur Fehleranalyse hervor. Entspricht /ba uidebug on/off.",
	["OPTIONS_RESUME_LAST_PAGE_LABEL"] = "Auf letzter Seite fortsetzen",
	["OPTIONS_RESUME_LAST_PAGE_TOOLTIP"] = "Wenn aktiviert, springt das erneute Öffnen eines gespeicherten Buches zur zuletzt angesehenen Seite, anstatt immer bei Seite 1 zu beginnen.",
  ["OPTIONS_EXPORT_IMPORT_LABEL"] = "Export / Import",
  ["OPTIONS_EXPORT_BUTTON"] = "Export erstellen",
  ["OPTIONS_EXPORT_LABEL"] = "Export",
  ["OPTIONS_EXPORT_BUTTON_COPY"] = "Kopieren",
  ["OPTIONS_EXPORT_STATUS_UNAVAILABLE"] = "Export nicht verfügbar.",
  ["OPTIONS_EXPORT_STATUS_FAILED"] = "Export fehlgeschlagen: %s",
  ["OPTIONS_EXPORT_STATUS_READY"] = "Export bereit (%d Zeichen). Klicke hier auf Importieren, um deine eigenen Daten zu testen/wiederherzustellen, oder auf Kopieren, um sie auf einen anderen Client zu übertragen.",
  ["OPTIONS_EXPORT_STATUS_NOTHING_TO_COPY"] = "Noch nichts zu kopieren. Klicke zuerst auf Export.",
  ["OPTIONS_EXPORT_STATUS_DEFAULT"] = "Es wurde noch kein Export erstellt.",
  ["OPTIONS_EXPORT_STATUS_COPY_HINT"] = "Drücke Strg+C zum Kopieren und dann Strg+V zum Einfügen.",
  ["OPTIONS_IMPORT_LABEL"] = "Importieren",
  ["OPTIONS_IMPORT_HELP"] = "Füge eine Exportzeichenfolge in das Feld unten ein. Der Import startet automatisch, wenn gültige Daten erkannt werden.",
  ["OPTIONS_IMPORT_PERF_TIP"] = "So importierst du auf diesem Client:\n\n- Von einem anderen Client/Account: Auf der Quelle auf Exportieren und dann auf Kopieren klicken. Auf diesem Client dieses Panel öffnen, auf Einfügen erfassen klicken und dann einmal Strg+V drücken. Der Import startet automatisch, wenn die Daten erkannt werden.\n\n- Derselbe Client nach Kopieren: Auf Exportieren klicken, dann auf Kopieren, dann (optional) auf Einfügen erfassen klicken und einmal Strg+V drücken. So kannst du genau testen, was kopiert wurde.\n\nWichtig: Einfügen erfassen kann deine Zwischenablage nicht selbst lesen. Es teilt dem Addon nur mit, dass es auf das *nächste* Strg+V lauschen soll, das du im Spiel durchführst; ohne dieses manuelle Einfügen wird nichts importiert.\n\nLeistungswarnung: Das Importieren eines großen Exporttexts kann den Spielclient vorübergehend einfrieren, während WoW das Einfügen verarbeitet und die Bücher dekodiert werden. Beispielsweise kann das Importieren von etwa 10–15 Büchern das Spiel für 10–15 Sekunden pausieren; das Importieren von 50 oder mehr Büchern kann fast eine Minute dauern, und sehr große Datenmengen können dazu führen, dass das Einfügen fehlschlägt oder sogar den Client aufgrund von Engine-Beschränkungen zum Absturz bringt. Bevorzuge nach Möglichkeit kleinere Exporte oder Importe pro Charakter anstelle extrem großer All-in-One-Importe.",
  ["OPTIONS_IMPORT_STATUS_DEFAULT"] = "Füge den Exporttext ein und warte auf 'Daten empfangen', bevor du importierst.",
  ["OPTIONS_IMPORT_STATUS_PASTE_HINT"] = "Drücke jetzt Strg+V zum Einfügen und warte dann auf 'Daten empfangen'.",
  ["OPTIONS_IMPORT_STATUS_PREPARING"] = "Import wird vorbereitet…",
  ["OPTIONS_IMPORT_STATUS_PHASE_DECODE"] = "Daten werden dekodiert",
  ["OPTIONS_IMPORT_STATUS_PHASE_PARSED"] = "Bücher werden gelesen",
  ["OPTIONS_IMPORT_STATUS_PHASE_MERGE"] = "Bücher werden zusammengeführt",
  ["OPTIONS_IMPORT_STATUS_PHASE_SEARCH"] = "Suchindex wird aktualisiert",
  ["OPTIONS_IMPORT_STATUS_PHASE_TITLES"] = "Titel werden aktualisiert",
  ["OPTIONS_IMPORT_STATUS_COMPLETE"] = "Import abgeschlossen.",
  ["OPTIONS_IMPORT_STATUS_FAILED"] = "Import fehlgeschlagen: %s",  ["OPTIONS_IMPORT_STATUS_ERROR"] = "Importfehler (%s): %s",  ["OPTIONS_IMPORT_STATUS_TOO_LARGE"] = "Datenmenge zu groß. Abbruch.",
  ["OPTIONS_IMPORT_STATUS_NO_EXPORT_IN_CLIPBOARD"] = "Im Zwischenspeicher wurde kein Exporttext gefunden. Stelle sicher, dass du auf dem Quell-Client auf Kopieren geklickt hast.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_RECEIVED"] = "Daten empfangen (%d Zeichen). Klicke auf Importieren.",
  ["OPTIONS_IMPORT_STATUS_UNAVAILABLE"] = "Import nicht verfügbar.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING"] = "Keine Importdaten zum Verarbeiten vorhanden.",
  ["OPTIONS_IMPORT_STATUS_IN_PROGRESS"] = "Import läuft bereits.",
  ["OPTIONS_IMPORT_STATUS_SUMMARY"] = "Importiert: %d neu, %d zusammengeführt",
	["OPTIONS_TOOLTIP_LABEL"] = "'Archiviert'-Tag im Tooltip anzeigen",
	["OPTIONS_TOOLTIP_TOOLTIP"] = "Wenn aktiviert, zeigen lesbare Gegenstände, deren Text für diesen Charakter gespeichert wurde, eine zusätzliche Zeile 'Book Archivist: Archiviert' in ihrem Tooltip.",	["OPTIONS_RELOAD_REQUIRED"] = "Sprache geändert. Geben Sie /reload ein, um dieses Einstellungsfenster zu aktualisieren.",  ["OPTIONS_DEBUG_LABEL"] = "Debug-Modus",
  ["OPTIONS_DEBUG_TOOLTIP"] = "Wenn aktiviert, wird unter dem Importfeld ein Debug-Protokoll mit detaillierten Diagnoseinformationen zur Fehleranalyse angezeigt.",

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

  ["LIST_SHARE_BOOK_MENU"] = "Dieses Buch teilen / exportieren",

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

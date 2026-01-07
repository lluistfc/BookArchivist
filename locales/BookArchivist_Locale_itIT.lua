---@diagnostic disable: undefined-global
-- Italian (itIT) locale definitions for BookArchivist

BookArchivist = BookArchivist or {}
BookArchivist.__Locales = BookArchivist.__Locales or {}
local Locales = BookArchivist.__Locales

Locales.itIT = {
  -- Addon & options
  ["ADDON_TITLE"] = "Book Archivist",
  ["OPTIONS_TITLE"] = "Opzioni di Book Archivist",
  ["OPTIONS_TOOLTIP_OPEN_PANEL"] = "Apri il pannello delle opzioni",

  -- List header / tabs
  ["BOOKS_TAB"] = "Libri",
  ["LOCATIONS_TAB"] = "Luoghi",
  ["BOOK_LIST_HEADER"] = "Libri salvati",
  ["BOOK_LIST_SUBHEADER"] = "Ogni pagina che leggi",
  ["BOOK_SEARCH_PLACEHOLDER"] = "Cerca per titolo o testo…",
  ["BOOK_SEARCH_TOOLTIP"] = "La ricerca trova libri in cui tutte le tue parole compaiono nel titolo o nel testo. Non richiede la frase esatta.",

  -- Pagination / sort
  ["PAGINATION_PREV"] = "< Prec.",
  ["PAGINATION_NEXT"] = "Succ. >",
  ["PAGINATION_PAGE_SINGLE"] = "Pagina 1 / 1",
  ["PAGINATION_PAGE_FORMAT"] = "Pagina %d / %d",
  ["PAGINATION_PAGE_SIZE_FORMAT"] = "%d / pagina",
  ["SORT_DROPDOWN_PLACEHOLDER"] = "Ordinamento…",

  -- Sort option labels
  ["SORT_RECENT"] = "Letti di recente",
  ["SORT_TITLE"] = "Titolo (A–Z)",
  ["SORT_ZONE"] = "Zona",
  ["SORT_FIRST_SEEN"] = "Visto per primo",
  ["SORT_LAST_SEEN"] = "Visto per ultimo",

  -- Header buttons & help
  ["HEADER_BUTTON_OPTIONS"] = "Opzioni",
  ["HEADER_BUTTON_HELP"] = "Aiuto",
  ["HEADER_HELP_CHAT"] = "Usa ricerca, filtri e ordinamento per trovare subito qualsiasi libro salvato.",
	["RESUME_LAST_BOOK"] = "Riprendi libro",

  -- Reader
  ["READER_EMPTY_PROMPT"] = "Seleziona un libro dall'elenco",  ["READER_EMPTY_TIP_SEARCH"] = "Suggerimento: Usa la casella di ricerca per trovare libri per titolo o testo.",
  ["READER_EMPTY_TIP_LOCATIONS"] = "Suggerimento: Passa a Posizioni per sfogliare per dove li hai trovati.",  ["READER_NO_CONTENT"] = "|cFF888888Nessun contenuto disponibile|r",
  ["READER_FOOTER_HINT"] = "|cFF888888I libri vengono salvati mentre li leggi in gioco|r",
  ["READER_META_CREATOR"] = "Autore:",
  ["READER_META_MATERIAL"] = "Materiale:",
  ["READER_META_LAST_VIEWED"] = "Ultima lettura:",
  ["READER_META_CAPTURED_AUTOMATICALLY"] = "Catturato automaticamente da ItemText.",
  ["READER_PAGE_COUNT_SINGULAR"] = "%d pagina",
  ["READER_PAGE_COUNT_PLURAL"] = "%d pagine",
  ["READER_LAST_VIEWED_AT_FORMAT"] = "Ultima lettura %s",
  ["READER_DELETE_BUTTON"] = "Elimina",
  ["READER_DELETE_TOOLTIP_ENABLED_TITLE"] = "Elimina questo libro",
  ["READER_DELETE_TOOLTIP_ENABLED_BODY"] = "Rimuove definitivamente il libro dal tuo archivio.",
  ["READER_DELETE_TOOLTIP_DISABLED_TITLE"] = "Seleziona un libro salvato",
  ["READER_DELETE_TOOLTIP_DISABLED_BODY"] = "Scegli un libro dall'elenco per poterlo eliminare.",
  ["READER_DELETE_CONFIRM"] = "Eliminare '%s'? Questa azione non può essere annullata.",
  ["READER_DELETE_CHAT_SUCCESS"] = "|cFFFF0000Libro eliminato dall'archivio.|r",
  ["READER_SHARE_BUTTON"] = "Condividi",
  ["READER_SHARE_TOOLTIP_TITLE"] = "Esporta questo libro",
  ["READER_SHARE_TOOLTIP_BODY"] = "Genera una stringa di esportazione per questo singolo libro. Copiala con Ctrl+C e condividila con altri, oppure incollala nel pannello di Importazione (Opzioni → Esporta / Importa) su un altro personaggio o client.",
  ["READER_SHARE_POPUP_TITLE"] = "Stringa di esportazione del libro",
  ["READER_SHARE_POPUP_LABEL"] = "Usa Ctrl+C per copiare questa stringa, quindi condividila con altri giocatori o incollala in un altro client di Book Archivist.",
  ["READER_SHARE_SELECT_ALL"] = "Seleziona tutto",
  ["SHARE_CHAT_HINT"] = "Crea un link cliccabile nella chat, o copia la stringa di esportazione qui sotto per condividere direttamente.",
  ["SHARE_TO_CHAT_BUTTON"] = "Condividi nella chat",
  ["SHARE_LINK_INSERTED"] = "Link inserito nella chat! Premi Invio per inviare.",

  -- Import from chat links
  ["IMPORT_PROMPT_TITLE"] = "Importa libro",
  ["IMPORT_PROMPT_TEXT"] = "Incolla la stringa di esportazione del libro qui sotto:",
  ["IMPORT_PROMPT_HINT"] = "Il mittente deve condividere la stringa di esportazione completa separatamente (fuori dalla chat di WoW).",
  ["IMPORT_PROMPT_BUTTON"] = "Importa",
  ["IMPORT_SUCCESS"] = "Importato: %s",
  ["IMPORT_FAILED"] = "Importazione fallita: %s",
  ["IMPORT_COMPLETED_WITH_WARNINGS"] = "Importazione completata con avvisi",
  ["REQUESTING_BOOK"] = "Richiesta libro da %s...",
  ["REQUEST_TIMEOUT"] = "Nessuna risposta da %s",
  ["BOOK_NOT_AVAILABLE"] = "Libro non più disponibile per la condivisione",
  ["IMPORT_PROMPT_TITLE_WITH_DATA"] = "Importa: %s",
  ["IMPORT_CONFIRM_MESSAGE"] = "Libro ricevuto! Clicca su Importa per aggiungere '%s' alla tua biblioteca.",

  -- Favorites
  ["READER_FAVORITE_ADD"] = "Aggiungi ai preferiti",
  ["READER_FAVORITE_REMOVE"] = "Rimuovi dai preferiti",
  ["CATEGORY_ALL"] = "Tutti i libri",
  ["CATEGORY_FAVORITES"] = "Preferiti",
  ["CATEGORY_RECENT"] = "Letti di recente",
  ["SORT_GROUP_CATEGORY"] = "Vista",
  ["SORT_GROUP_ORDER"] = "Ordina per",

  -- Options panel
  ["OPTIONS_SUBTITLE_DEBUG"] = "Abilita diagnostica dettagliata per risolvere problemi di aggiornamento.",
  ["OPTIONS_DEBUG_LOGGING_LABEL"] = "Abilita log di debug",
  ["OPTIONS_DEBUG_LOGGING_TOOLTIP"] = "Mostra informazioni aggiuntive di BookArchivist in chat per la diagnosi.",
  ["OPTIONS_UI_DEBUG_LABEL"] = "Mostra griglia di debug UI",
  ["OPTIONS_UI_DEBUG_TOOLTIP"] = "Evidenzia i limiti del layout. Uguale a /ba uidebug on/off.",
	["OPTIONS_RESUME_LAST_PAGE_LABEL"] = "Riprendi all'ultima pagina",
	["OPTIONS_RESUME_LAST_PAGE_TOOLTIP"] = "Se abilitato, riaprire un libro salvato ti riporta all'ultima pagina visualizzata invece di iniziare sempre dalla pagina 1.",
  ["OPTIONS_EXPORT_IMPORT_LABEL"] = "Esporta / Importa",
  ["OPTIONS_EXPORT_BUTTON"] = "Genera esportazione",
  ["OPTIONS_EXPORT_LABEL"] = "Esporta",
  ["OPTIONS_EXPORT_BUTTON_COPY"] = "Copia",
  ["OPTIONS_EXPORT_STATUS_UNAVAILABLE"] = "Esportazione non disponibile.",
  ["OPTIONS_EXPORT_STATUS_FAILED"] = "Esportazione non riuscita: %s",
  ["OPTIONS_EXPORT_STATUS_READY"] = "Esportazione pronta (%d caratteri). Fai clic su Importa qui per testare/ripristinare i tuoi dati oppure su Copia per condividerli con un altro client.",
  ["OPTIONS_EXPORT_STATUS_NOTHING_TO_COPY"] = "Niente da copiare per ora. Fai prima clic su Esporta.",
  ["OPTIONS_EXPORT_STATUS_DEFAULT"] = "Non è ancora stata generata alcuna esportazione.",
  ["OPTIONS_EXPORT_STATUS_COPY_HINT"] = "Premi Ctrl+C per copiare e poi Ctrl+V per incollare.",
  ["OPTIONS_IMPORT_LABEL"] = "Importa",
  ["OPTIONS_IMPORT_HELP"] = "Incolla una stringa di esportazione nel riquadro sottostante. L'importazione inizia automaticamente quando vengono rilevati dati validi.",
  ["OPTIONS_IMPORT_PERF_TIP"] = "Come importare su questo client:\n\n- Da un altro client/account: Sulla sorgente, fai clic su Esporta poi su Copia. Su questo client, apri questo pannello, fai clic su Cattura incolla, poi premi una volta Ctrl+V. L'importazione partirà automaticamente quando i dati vengono rilevati.\n\n- Stesso client dopo Copia: Fai clic su Esporta, poi su Copia, poi (facoltativo) su Cattura incolla e premi una volta Ctrl+V. Questo ti permette di testare esattamente ciò che è stato copiato.\n\nImportante: Cattura incolla non può leggere gli appunti da solo. Dice solo all'addon di ascoltare il *prossimo* Ctrl+V che esegui nel gioco; senza quell'incolla manuale, non viene importato nulla.\n\nAvviso prestazioni: L'importazione di una grande stringa di esportazione può bloccare temporaneamente il client di gioco mentre WoW elabora l'incolla e i libri vengono decodificati. Ad esempio, l'importazione di circa 10-15 libri può mettere in pausa il gioco per 10-15 secondi; l'importazione di 50 o più libri può richiedere quasi un minuto, e carichi molto grandi possono causare il fallimento dell'incolla o addirittura il crash del client a causa delle limitazioni del motore. Quando possibile, preferisci esportazioni più piccole o importazioni per personaggio invece di importazioni estremamente grandi tutto-in-uno.",
  ["OPTIONS_IMPORT_STATUS_DEFAULT"] = "Incolla il testo di esportazione e attendi 'Dati ricevuti' prima di importare.",
  ["OPTIONS_IMPORT_STATUS_PASTE_HINT"] = "Premi ora Ctrl+V per incollare e poi attendi 'Dati ricevuti'.",
  ["OPTIONS_IMPORT_STATUS_PREPARING"] = "Preparazione dell'importazione…",
  ["OPTIONS_IMPORT_STATUS_PHASE_DECODE"] = "Decodifica dei dati",
  ["OPTIONS_IMPORT_STATUS_PHASE_PARSED"] = "Lettura dei libri",
  ["OPTIONS_IMPORT_STATUS_PHASE_MERGE"] = "Unione dei libri",
  ["OPTIONS_IMPORT_STATUS_PHASE_SEARCH"] = "Aggiornamento dell'indice di ricerca",
  ["OPTIONS_IMPORT_STATUS_PHASE_TITLES"] = "Aggiornamento dei titoli",
  ["OPTIONS_IMPORT_STATUS_COMPLETE"] = "Importazione completata.",
  ["OPTIONS_IMPORT_STATUS_FAILED"] = "Importazione non riuscita: %s",
  ["OPTIONS_IMPORT_STATUS_ERROR"] = "Errore di importazione (%s): %s",
  ["OPTIONS_IMPORT_STATUS_TOO_LARGE"] = "Dati troppo grandi. Interruzione.",
  ["OPTIONS_IMPORT_STATUS_NO_EXPORT_IN_CLIPBOARD"] = "Nessun testo di esportazione rilevato negli appunti. Assicurati di aver fatto clic su Copia sul client di origine.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_RECEIVED"] = "Dati ricevuti (%d caratteri). Importazione in corso…",
  ["OPTIONS_IMPORT_STATUS_UNAVAILABLE"] = "Importazione non disponibile.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING"] = "Nessun dato di importazione da elaborare.",
  ["OPTIONS_IMPORT_STATUS_IN_PROGRESS"] = "Importazione già in corso.",
  ["OPTIONS_IMPORT_STATUS_SUMMARY"] = "Importati: %d nuovi, %d uniti",	["OPTIONS_TOOLTIP_LABEL"] = "Mostra etichetta 'Archiviato' nel tooltip",
	["OPTIONS_TOOLTIP_TOOLTIP"] = "Quando abilitato, gli oggetti leggibili il cui testo è stato salvato per questo personaggio mostreranno una riga aggiuntiva 'Book Archivist: Archiviato' nel loro tooltip.",
  ["OPTIONS_DEBUG_LABEL"] = "Modalità debug",
  ["OPTIONS_DEBUG_TOOLTIP"] = "Quando abilitato, mostra un log di debug sotto la casella di importazione con diagnostiche dettagliate per la risoluzione dei problemi.",
  -- Location / provenance
  ["LOCATION_UNKNOWN_ZONE"] = "Zona sconosciuta",
  ["LOCATION_UNKNOWN_MOB"] = "Nemico sconosciuto",
  ["LOCATION_LOOTED_LABEL"] = "Bottino:",
  ["LOCATION_LOCATION_LABEL"] = "Luogo:",

  -- Minimap tooltip
  ["MINIMAP_TIP_LEFT"] = "Clic sinistro: apri la libreria",
  ["MINIMAP_TIP_RIGHT"] = "Clic destro: apri le opzioni",
  ["MINIMAP_TIP_DRAG"] = "Trascina: sposta il pulsante",

  -- List empty states / generic labels
  ["BOOK_META_FALLBACK"] = "Salvato automaticamente quando leggi",
  ["BOOK_LIST_EMPTY_HEADER"] = "Nessun libro ancora salvato",
  ["PAGINATION_EMPTY_RESULTS"] = "Nessun risultato",
  ["LIST_EMPTY_SEARCH"] = "Nessuna corrispondenza. Pulisci filtri o ricerca.",
  ["LIST_EMPTY_NO_BOOKS"] = "Nessun libro salvato. Leggi un libro in gioco per salvarlo.",
  ["LOCATIONS_BROWSE_HEADER"] = "Esplora i luoghi",

  -- Count / formatting helpers
  ["COUNT_BOOK_SINGULAR"] = "%d libro",
  ["COUNT_BOOK_PLURAL"] = "%d libri",
  ["COUNT_BOOKS_FILTERED_FORMAT"] = "%d / %d libri",
  ["COUNT_LOCATION_SINGULAR"] = "%d luogo",
  ["COUNT_LOCATION_PLURAL"] = "%d luoghi",
  ["LOCATIONS_BREADCRUMB_ROOT"] = "Tutti i luoghi",
  ["COUNT_BOOKS_HERE_PLURAL"] = "%d libri qui",
  ["COUNT_BOOKS_HERE_SINGULAR"] = "%d libro qui",
  ["COUNT_SUBLOCATION_SINGULAR"] = "%d sottoluogo",
  ["COUNT_SUBLOCATION_PLURAL"] = "%d sottoluoghi",
  ["COUNT_BOOKS_IN_LOCATION_SINGULAR"] = "%d libro in questo luogo",
  ["COUNT_BOOKS_IN_LOCATION_PLURAL"] = "%d libri in questo luogo",

  -- Location list rows
  ["LOCATION_BACK_TITLE"] = "Indietro",
  ["LOCATION_BACK_SUBTITLE"] = "Sali di un livello",
  ["LOCATION_EMPTY"] = "Luogo vuoto",
  ["LOCATIONS_EMPTY"] = "Nessun luogo ancora salvato",
  ["LOCATIONS_BROWSE_SAVED"] = "Esplora i luoghi salvati",
  ["LOCATIONS_NO_RESULTS"] = "Nessun luogo o libro disponibile qui.",

  -- Book rows
  ["BOOK_UNTITLED"] = "(Senza titolo)",
  ["BOOK_UNKNOWN"] = "Libro sconosciuto",
  ["BOOK_MISSING_DATA"] = "Dati mancanti",
	["MATCH_TITLE"] = "TITOLO",
	["MATCH_TEXT"] = "TESTO",

  ["LIST_SHARE_BOOK_MENU"] = "Condividi / Esporta questo libro",

  -- Language names / options
  ["LANGUAGE_LABEL"] = "Lingua",
  ["LANGUAGE_NAME_ENGLISH"] = "Inglese",
  ["LANGUAGE_NAME_SPANISH"] = "Spagnolo",
  ["LANGUAGE_NAME_CATALAN"] = "Catalano",
  ["LANGUAGE_NAME_GERMAN"] = "Tedesco",
  ["LANGUAGE_NAME_FRENCH"] = "Francese",
  ["LANGUAGE_NAME_ITALIAN"] = "Italiano",
  ["LANGUAGE_NAME_PORTUGUESE"] = "Portoghese",
}

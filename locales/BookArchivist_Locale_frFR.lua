---@diagnostic disable: undefined-global
-- French (frFR) locale definitions for BookArchivist

BookArchivist = BookArchivist or {}
BookArchivist.__Locales = BookArchivist.__Locales or {}
local Locales = BookArchivist.__Locales

Locales.frFR = {
  -- Addon & options
  ["ADDON_TITLE"] = "Book Archivist",
  ["OPTIONS_TITLE"] = "Options de Book Archivist",
  ["OPTIONS_TOOLTIP_OPEN_PANEL"] = "Ouvrir le panneau de configuration",

  -- List header / tabs
  ["BOOKS_TAB"] = "Livres",
  ["LOCATIONS_TAB"] = "Lieux",
  ["BOOK_LIST_HEADER"] = "Livres enregistrés",
  ["BOOK_LIST_SUBHEADER"] = "Chaque page que vous lisez",
  ["BOOK_SEARCH_PLACEHOLDER"] = "Rechercher par titre ou texte…",
  ["BOOK_SEARCH_TOOLTIP"] = "La recherche trouve les livres où tous vos mots apparaissent dans le titre ou le texte. Elle ne nécessite pas la phrase exacte.",

  -- Pagination / sort
  ["PAGINATION_PREV"] = "< Préc.",
  ["PAGINATION_NEXT"] = "Suiv. >",
  ["PAGINATION_PAGE_SINGLE"] = "Page 1 / 1",
  ["PAGINATION_PAGE_FORMAT"] = "Page %d / %d",
  ["PAGINATION_PAGE_SIZE_FORMAT"] = "%d / page",
  ["SORT_DROPDOWN_PLACEHOLDER"] = "Tri…",

  -- Sort option labels
  ["SORT_RECENT"] = "Récemment lus",
  ["SORT_TITLE"] = "Titre (A–Z)",
  ["SORT_ZONE"] = "Zone",
  ["SORT_FIRST_SEEN"] = "Vu en premier",
  ["SORT_LAST_SEEN"] = "Vu en dernier",

  -- Header buttons & help
  ["HEADER_BUTTON_OPTIONS"] = "Options",
  ["HEADER_BUTTON_HELP"] = "Aide",
  ["HEADER_HELP_CHAT"] = "Utilisez la recherche, les filtres et le tri pour retrouver n'importe quel livre enregistré instantanément.",
  ["RESUME_LAST_BOOK"] = "Dernier livre",

  -- Reader
  ["READER_EMPTY_PROMPT"] = "Sélectionnez un livre dans la liste",
  ["READER_NO_CONTENT"] = "|cFF888888Aucun contenu disponible|r",
  ["READER_FOOTER_HINT"] = "|cFF888888Les livres sont enregistrés au fur et à mesure que vous les lisez en jeu|r",
  ["READER_META_CREATOR"] = "Auteur :",
  ["READER_META_MATERIAL"] = "Matériau :",
  ["READER_META_LAST_VIEWED"] = "Dernière lecture :",
  ["READER_META_CAPTURED_AUTOMATICALLY"] = "Enregistré automatiquement depuis ItemText.",
  ["READER_PAGE_COUNT_SINGULAR"] = "%d page",
  ["READER_PAGE_COUNT_PLURAL"] = "%d pages",
  ["READER_LAST_VIEWED_AT_FORMAT"] = "Dernière lecture %s",
  ["READER_DELETE_BUTTON"] = "Supprimer",
  ["READER_DELETE_TOOLTIP_ENABLED_TITLE"] = "Supprimer ce livre",
  ["READER_DELETE_TOOLTIP_ENABLED_BODY"] = "Supprime définitivement le livre de votre archive.",
  ["READER_DELETE_TOOLTIP_DISABLED_TITLE"] = "Sélectionnez un livre enregistré",
  ["READER_DELETE_TOOLTIP_DISABLED_BODY"] = "Choisissez un livre dans la liste pour pouvoir le supprimer.",
  ["READER_DELETE_CONFIRM"] = "Supprimer '%s' ? Cette action est irréversible.",
  ["READER_DELETE_CHAT_SUCCESS"] = "|cFFFF0000Livre supprimé de l'archive.|r",
  ["READER_SHARE_BUTTON"] = "Partager",
  ["READER_SHARE_TOOLTIP_TITLE"] = "Exporter ce livre",
  ["READER_SHARE_TOOLTIP_BODY"] = "Génère une chaîne d'exportation pour ce livre unique. Copiez-la avec Ctrl+C et partagez-la avec d'autres, ou collez-la dans le panneau d'Importation (Options → Exporter / Importer) sur un autre personnage ou client.",
  ["READER_SHARE_POPUP_TITLE"] = "Chaîne d'exportation du livre",
  ["READER_SHARE_POPUP_LABEL"] = "Utilisez Ctrl+C pour copier cette chaîne, puis partagez-la avec d'autres joueurs ou collez-la dans un autre client de Book Archivist.",
  ["READER_SHARE_SELECT_ALL"] = "Tout sélectionner",

  -- Favorites
  ["READER_FAVORITE_ADD"] = "Ajouter aux favoris",
  ["READER_FAVORITE_REMOVE"] = "Retirer des favoris",
  ["CATEGORY_ALL"] = "Tous les livres",
  ["CATEGORY_FAVORITES"] = "Favoris",
  ["CATEGORY_RECENT"] = "Récemment lus",
  ["SORT_GROUP_CATEGORY"] = "Vue",
  ["SORT_GROUP_ORDER"] = "Trier par",

  -- Options panel
  ["OPTIONS_SUBTITLE_DEBUG"] = "Active des diagnostics détaillés pour résoudre les problèmes de rafraîchissement.",
  ["OPTIONS_DEBUG_LOGGING_LABEL"] = "Activer le journal de débogage",
  ["OPTIONS_DEBUG_LOGGING_TOOLTIP"] = "Affiche des informations supplémentaires de BookArchivist dans le chat pour le diagnostic.",
  ["OPTIONS_UI_DEBUG_LABEL"] = "Afficher la grille de débogage de l'interface",
  ["OPTIONS_UI_DEBUG_TOOLTIP"] = "Met en évidence les limites de mise en page. Identique à /ba uidebug on/off.",
	["OPTIONS_RESUME_LAST_PAGE_LABEL"] = "Reprendre à la dernière page",
	["OPTIONS_RESUME_LAST_PAGE_TOOLTIP"] = "Si cette option est activée, rouvrir un livre enregistré revient à la dernière page lue au lieu de toujours commencer à la page 1.",
  ["OPTIONS_EXPORT_IMPORT_LABEL"] = "Exporter / Importer",
  ["OPTIONS_EXPORT_BUTTON"] = "Générer l'export",
  ["OPTIONS_EXPORT_LABEL"] = "Exporter",
  ["OPTIONS_EXPORT_BUTTON_COPY"] = "Copier",
  ["OPTIONS_EXPORT_STATUS_UNAVAILABLE"] = "Exportation indisponible.",
  ["OPTIONS_EXPORT_STATUS_FAILED"] = "Échec de l'exportation : %s",
  ["OPTIONS_EXPORT_STATUS_READY"] = "Exportation prête (%d caractères). Cliquez sur Importer ici pour tester/restaurer vos propres données, ou sur Copier pour les partager avec un autre client.",
  ["OPTIONS_EXPORT_STATUS_NOTHING_TO_COPY"] = "Rien à copier pour le moment. Cliquez d'abord sur Exporter.",
  ["OPTIONS_EXPORT_STATUS_DEFAULT"] = "Aucune exportation n'a encore été générée.",
  ["OPTIONS_EXPORT_STATUS_COPY_HINT"] = "Appuyez sur Ctrl+C pour copier puis Ctrl+V pour coller.",
  ["OPTIONS_IMPORT_LABEL"] = "Importer un seul livre",

  ["OPTIONS_IMPORT_HELP"] = "Collez une chaîne d'exportation dans la zone ci-dessous. L'importation se fait automatiquement lorsque des données valides sont détectées.",
  ["OPTIONS_IMPORT_PERF_TIP"] = "Comment importer sur ce client :\n\n- Depuis un autre client/compte : Sur la source, cliquez sur Exporter puis sur Copier. Sur ce client, ouvrez ce panneau, cliquez sur Capturer le collage, puis appuyez une fois sur Ctrl+V. L'importation démarrera automatiquement lorsque les données seront détectées.\n\n- Même client après Copier : Cliquez sur Exporter, puis sur Copier, puis (facultatif) sur Capturer le collage et appuyez une fois sur Ctrl+V. Cela vous permet de tester exactement ce qui a été copié.\n\nImportant : Capturer le collage ne peut pas lire votre presse-papiers tout seul. Il indique seulement à l'addon d'écouter le *prochain* Ctrl+V que vous effectuez dans le jeu ; sans ce collage manuel, rien n'est importé.\n\nAvertissement de performance : L'importation d'une grande chaîne d'exportation peut geler temporairement le client de jeu pendant que WoW traite le collage et que les livres sont décodés. Par exemple, l'importation d'environ 10-15 livres peut mettre le jeu en pause pendant 10-15 secondes ; l'importation de 50 livres ou plus peut prendre près d'une minute, et de très grandes charges peuvent provoquer l'échec du collage ou même planter le client en raison des limitations du moteur. Dans la mesure du possible, préférez des exports plus petits ou des importations par personnage plutôt que des importations extrêmement volumineuses tout-en-un.",
  ["OPTIONS_IMPORT_STATUS_DEFAULT"] = "Collez le texte d'exportation et attendez l'apparition de 'Données reçues' avant d'importer.",
  ["OPTIONS_IMPORT_STATUS_PASTE_HINT"] = "Appuyez maintenant sur Ctrl+V pour coller puis attendez 'Données reçues'.",
  ["OPTIONS_IMPORT_STATUS_PREPARING"] = "Préparation de l'importation…",
  ["OPTIONS_IMPORT_STATUS_PHASE_DECODE"] = "Décodage des données",
  ["OPTIONS_IMPORT_STATUS_PHASE_PARSED"] = "Lecture des livres",
  ["OPTIONS_IMPORT_STATUS_PHASE_MERGE"] = "Fusion des livres",
  ["OPTIONS_IMPORT_STATUS_PHASE_SEARCH"] = "Mise à jour de l'index de recherche",
  ["OPTIONS_IMPORT_STATUS_PHASE_TITLES"] = "Mise à jour des titres",
  ["OPTIONS_IMPORT_STATUS_COMPLETE"] = "Importation terminée.",
  ["OPTIONS_IMPORT_STATUS_FAILED"] = "Échec de l'importation : %s",
  ["OPTIONS_IMPORT_STATUS_ERROR"] = "Erreur d'importation (%s) : %s",
  ["OPTIONS_IMPORT_STATUS_TOO_LARGE"] = "Charge trop volumineuse. Abandon.",
  ["OPTIONS_IMPORT_STATUS_NO_EXPORT_IN_CLIPBOARD"] = "Aucun texte d'export détecté dans le presse-papiers. Assurez-vous d'avoir cliqué sur Copier sur le client source.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_RECEIVED"] = "Données reçues (%d caractères). Import en cours…",
  ["OPTIONS_IMPORT_STATUS_UNAVAILABLE"] = "Importation indisponible.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING"] = "Aucune donnée à importer.",
  ["OPTIONS_IMPORT_STATUS_IN_PROGRESS"] = "Une importation est déjà en cours.",
  ["OPTIONS_IMPORT_STATUS_SUMMARY"] = "Importé : %d nouveaux, %d fusionnés",

  -- Location / provenance
  ["LOCATION_UNKNOWN_ZONE"] = "Zone inconnue",
  ["LOCATION_UNKNOWN_MOB"] = "Ennemi inconnu",
  ["LOCATION_LOOTED_LABEL"] = "Butin :",
  ["LOCATION_LOCATION_LABEL"] = "Lieu :",

  -- Minimap tooltip
  ["MINIMAP_TIP_LEFT"] = "Clic gauche : ouvrir la bibliothèque",
  ["MINIMAP_TIP_RIGHT"] = "Clic droit : ouvrir les options",
  ["MINIMAP_TIP_DRAG"] = "Glisser : déplacer le bouton",

  -- List empty states / generic labels
  ["BOOK_META_FALLBACK"] = "Enregistré automatiquement lorsque vous lisez",
  ["BOOK_LIST_EMPTY_HEADER"] = "Aucun livre encore enregistré",
  ["PAGINATION_EMPTY_RESULTS"] = "Aucun résultat",
  ["LIST_EMPTY_SEARCH"] = "Aucune correspondance. Effacez les filtres ou la recherche.",
  ["LIST_EMPTY_NO_BOOKS"] = "Aucun livre enregistré. Lisez un livre en jeu pour l'ajouter.",
  ["LOCATIONS_BROWSE_HEADER"] = "Parcourir les lieux",

  -- Count / formatting helpers
  ["COUNT_BOOK_SINGULAR"] = "%d livre",
  ["COUNT_BOOK_PLURAL"] = "%d livres",
  ["COUNT_BOOKS_FILTERED_FORMAT"] = "%d / %d livres",
  ["COUNT_LOCATION_SINGULAR"] = "%d lieu",
  ["COUNT_LOCATION_PLURAL"] = "%d lieux",
  ["LOCATIONS_BREADCRUMB_ROOT"] = "Tous les lieux",
  ["COUNT_BOOKS_HERE_PLURAL"] = "%d livres ici",
  ["COUNT_BOOKS_HERE_SINGULAR"] = "%d livre ici",
  ["COUNT_SUBLOCATION_SINGULAR"] = "%d sous-lieu",
  ["COUNT_SUBLOCATION_PLURAL"] = "%d sous-lieux",
  ["COUNT_BOOKS_IN_LOCATION_SINGULAR"] = "%d livre à ce lieu",
  ["COUNT_BOOKS_IN_LOCATION_PLURAL"] = "%d livres à ce lieu",

  -- Location list rows
  ["LOCATION_BACK_TITLE"] = "Retour",
  ["LOCATION_BACK_SUBTITLE"] = "Remonter d'un niveau",
  ["LOCATION_EMPTY"] = "Lieu vide",
  ["LOCATIONS_EMPTY"] = "Aucun lieu encore enregistré",
  ["LOCATIONS_BROWSE_SAVED"] = "Parcourir les lieux enregistrés",
  ["LOCATIONS_NO_RESULTS"] = "Aucun lieu ou livre disponible ici.",

  -- Book rows
  ["BOOK_UNTITLED"] = "(Sans titre)",
  ["BOOK_UNKNOWN"] = "Livre inconnu",
  ["BOOK_MISSING_DATA"] = "Données manquantes",
	["MATCH_TITLE"] = "TITRE",
	["MATCH_TEXT"] = "TEXTE",

  ["LIST_SHARE_BOOK_MENU"] = "Partager / Exporter ce livre",

  -- Language names / options
  ["LANGUAGE_LABEL"] = "Langue",
  ["LANGUAGE_NAME_ENGLISH"] = "Anglais",
  ["LANGUAGE_NAME_SPANISH"] = "Espagnol",
  ["LANGUAGE_NAME_CATALAN"] = "Catalan",
  ["LANGUAGE_NAME_GERMAN"] = "Allemand",
  ["LANGUAGE_NAME_FRENCH"] = "Français",
  ["LANGUAGE_NAME_ITALIAN"] = "Italien",
  ["LANGUAGE_NAME_PORTUGUESE"] = "Portugais",
}

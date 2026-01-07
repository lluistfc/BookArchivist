---@diagnostic disable: undefined-global
-- Portuguese (ptBR/ptPT) locale definitions for BookArchivist

BookArchivist = BookArchivist or {}
BookArchivist.__Locales = BookArchivist.__Locales or {}
local Locales = BookArchivist.__Locales

Locales.ptBR = {
  -- Addon & options
  ["ADDON_TITLE"] = "Book Archivist",
  ["OPTIONS_TITLE"] = "Opções do Book Archivist",
  ["OPTIONS_TOOLTIP_OPEN_PANEL"] = "Abrir o painel de opções",

  -- List header / tabs
  ["BOOKS_TAB"] = "Livros",
  ["LOCATIONS_TAB"] = "Locais",
  ["BOOK_LIST_HEADER"] = "Livros salvos",
  ["BOOK_LIST_SUBHEADER"] = "Cada página que você lê",
  ["BOOK_SEARCH_PLACEHOLDER"] = "Buscar por título ou texto…",
  ["BOOK_SEARCH_TOOLTIP"] = "A busca encontra livros em que todas as suas palavras aparecem no título ou no texto. Ela não exige a frase exata.",

  -- Pagination / sort
  ["PAGINATION_PREV"] = "< Anterior",
  ["PAGINATION_NEXT"] = "Próximo >",
  ["PAGINATION_PAGE_SINGLE"] = "Página 1 / 1",
  ["PAGINATION_PAGE_FORMAT"] = "Página %d / %d",
  ["PAGINATION_PAGE_SIZE_FORMAT"] = "%d / página",
  ["SORT_DROPDOWN_PLACEHOLDER"] = "Ordenação…",

  -- Sort option labels
  ["SORT_RECENT"] = "Lidos recentemente",
  ["SORT_TITLE"] = "Título (A–Z)",
  ["SORT_ZONE"] = "Zona",
  ["SORT_FIRST_SEEN"] = "Visto primeiro",
  ["SORT_LAST_SEEN"] = "Visto por último",

  -- Header buttons & help
  ["HEADER_BUTTON_OPTIONS"] = "Opções",
  ["HEADER_BUTTON_HELP"] = "Ajuda",
  ["HEADER_HELP_CHAT"] = "Use busca, filtros e ordenação para encontrar qualquer livro salvo instantaneamente.",
	["RESUME_LAST_BOOK"] = "Retomar livro",

  -- Reader
  ["READER_EMPTY_PROMPT"] = "Selecione um livro na lista",
  ["READER_NO_CONTENT"] = "|cFF888888Nenhum conteúdo disponível|r",
  ["READER_FOOTER_HINT"] = "|cFF888888Os livros são salvos enquanto você os lê no jogo|r",
  ["READER_META_CREATOR"] = "Autor:",
  ["READER_META_MATERIAL"] = "Material:",
  ["READER_META_LAST_VIEWED"] = "Última leitura:",
  ["READER_META_CAPTURED_AUTOMATICALLY"] = "Capturado automaticamente de ItemText.",
  ["READER_PAGE_COUNT_SINGULAR"] = "%d página",
  ["READER_PAGE_COUNT_PLURAL"] = "%d páginas",
  ["READER_LAST_VIEWED_AT_FORMAT"] = "Última leitura %s",
  ["READER_DELETE_BUTTON"] = "Excluir",
  ["READER_DELETE_TOOLTIP_ENABLED_TITLE"] = "Excluir este livro",
  ["READER_DELETE_TOOLTIP_ENABLED_BODY"] = "Remove permanentemente o livro do seu arquivo.",
  ["READER_DELETE_TOOLTIP_DISABLED_TITLE"] = "Selecione um livro salvo",
  ["READER_DELETE_TOOLTIP_DISABLED_BODY"] = "Escolha um livro na lista para poder excluí-lo.",
  ["READER_DELETE_CONFIRM"] = "Excluir '%s'? Esta ação não pode ser desfeita.",
  ["READER_DELETE_CHAT_SUCCESS"] = "|cFFFF0000Livro removido do arquivo.|r",

  -- Favorites
  ["READER_FAVORITE_ADD"] = "Adicionar aos Favoritos",
  ["READER_FAVORITE_REMOVE"] = "Remover dos Favoritos",
  ["CATEGORY_ALL"] = "Todos os livros",
  ["CATEGORY_FAVORITES"] = "Favoritos",
  ["CATEGORY_RECENT"] = "Lidos recentemente",
  ["SORT_GROUP_CATEGORY"] = "Visualização",
  ["SORT_GROUP_ORDER"] = "Ordenar por",

  -- Options panel
  ["OPTIONS_SUBTITLE_DEBUG"] = "Ative diagnósticos detalhados para resolver problemas de atualização.",
  ["OPTIONS_DEBUG_LOGGING_LABEL"] = "Ativar registro de depuração",
  ["OPTIONS_DEBUG_LOGGING_TOOLTIP"] = "Mostra informações adicionais do BookArchivist no chat para diagnóstico.",
  ["OPTIONS_UI_DEBUG_LABEL"] = "Mostrar grade de depuração da interface",
  ["OPTIONS_UI_DEBUG_TOOLTIP"] = "Destaca os limites do layout. Igual a /ba uidebug on/off.",
	["OPTIONS_RESUME_LAST_PAGE_LABEL"] = "Retomar na última página",
	["OPTIONS_RESUME_LAST_PAGE_TOOLTIP"] = "Quando ativado, reabrir um livro salvo leva à última página visualizada em vez de começar sempre na página 1.",
  ["OPTIONS_EXPORT_IMPORT_LABEL"] = "Exportar / Importar",
  ["OPTIONS_EXPORT_BUTTON"] = "Gerar exportação",
  ["OPTIONS_EXPORT_LABEL"] = "Exportar",
  ["OPTIONS_EXPORT_BUTTON_COPY"] = "Copiar",
  ["OPTIONS_EXPORT_STATUS_UNAVAILABLE"] = "Exportação indisponível.",
  ["OPTIONS_EXPORT_STATUS_FAILED"] = "Falha na exportação: %s",
  ["OPTIONS_EXPORT_STATUS_READY"] = "Exportação pronta (%d caracteres). Clique em Importar aqui para testar/restaurar seus próprios dados ou em Copiar para compartilhá-los com outro cliente.",
  ["OPTIONS_EXPORT_STATUS_NOTHING_TO_COPY"] = "Nada para copiar ainda. Clique primeiro em Exportar.",
  ["OPTIONS_EXPORT_STATUS_DEFAULT"] = "Nenhuma exportação foi gerada ainda.",
  ["OPTIONS_EXPORT_STATUS_COPY_HINT"] = "Pressione Ctrl+C para copiar e depois Ctrl+V para colar.",
  ["OPTIONS_IMPORT_LABEL"] = "String para importar",
  ["OPTIONS_IMPORT_BUTTON"] = "Importar",
  ["OPTIONS_IMPORT_BUTTON_CAPTURE"] = "Capturar colagem",
  ["OPTIONS_IMPORT_HELP"] = "Neste cliente: após Exportar, você pode clicar em Importar aqui para testar ou restaurar seus próprios dados sem colar.\n\nPara mover dados para outro cliente/conta:\n1) No cliente de origem, clique em Exportar e depois em Copiar.\n2) Compartilhe o texto de exportação copiado como quiser (Discord, sites de paste, arquivos compartilhados, etc.).\n3) No cliente de destino, copie esse texto, abra este painel, clique em Capturar colagem e depois pressione Ctrl+V uma vez.\n4) Quando o status mostrar 'Dados recebidos', clique em Importar.\n\nObservação: um simples Ctrl+V no jogo não inicia a importação por si só; o addon só escuta a colagem enquanto Capturar colagem está ativo, ou reutiliza sua última Exportação quando você apenas clica em Importar aqui.",
    ["OPTIONS_IMPORT_PERF_TIP"] = "Dica: você pode colar a exportação completa diretamente na caixa de importação com Ctrl+V, mas strings muito grandes podem travar o cliente do jogo por alguns segundos enquanto a colagem termina. Use Capturar colagem para inserir o texto aos poucos e evitar esse pico de desempenho.",
  ["OPTIONS_IMPORT_STATUS_DEFAULT"] = "Cole o texto de exportação e aguarde 'Dados recebidos' antes de importar.",
  ["OPTIONS_IMPORT_STATUS_PASTE_HINT"] = "Pressione agora Ctrl+V para colar e depois aguarde 'Dados recebidos'.",
  ["OPTIONS_IMPORT_STATUS_PREPARING"] = "Preparando importação…",
  ["OPTIONS_IMPORT_STATUS_PHASE_DECODE"] = "Decodificando dados",
  ["OPTIONS_IMPORT_STATUS_PHASE_PARSED"] = "Lendo livros",
  ["OPTIONS_IMPORT_STATUS_PHASE_MERGE"] = "Mesclando livros",
  ["OPTIONS_IMPORT_STATUS_PHASE_SEARCH"] = "Atualizando índice de busca",
  ["OPTIONS_IMPORT_STATUS_PHASE_TITLES"] = "Atualizando títulos",
  ["OPTIONS_IMPORT_STATUS_COMPLETE"] = "Importação concluída.",
  ["OPTIONS_IMPORT_STATUS_FAILED"] = "Falha na importação: %s",
  ["OPTIONS_IMPORT_STATUS_TOO_LARGE"] = "Carga muito grande. Cancelando.",
  ["OPTIONS_IMPORT_STATUS_NO_EXPORT_IN_CLIPBOARD"] = "Nenhum texto de exportação detectado na área de transferência. Certifique-se de ter clicado em Copiar no cliente de origem.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_RECEIVED"] = "Dados recebidos (%d caracteres). Clique em Importar.",
  ["OPTIONS_IMPORT_STATUS_UNAVAILABLE"] = "Importação indisponível.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING"] = "Nenhum dado de importação para processar.",
  ["OPTIONS_IMPORT_STATUS_IN_PROGRESS"] = "Uma importação já está em andamento.",
  ["OPTIONS_IMPORT_STATUS_SUMMARY"] = "Importados: %d novos, %d mesclados",

  -- Location / provenance
  ["LOCATION_UNKNOWN_ZONE"] = "Zona desconhecida",
  ["LOCATION_UNKNOWN_MOB"] = "Inimigo desconhecido",
  ["LOCATION_LOOTED_LABEL"] = "Saque:",
  ["LOCATION_LOCATION_LABEL"] = "Local:",

  -- Minimap tooltip
  ["MINIMAP_TIP_LEFT"] = "Clique esquerdo: abrir biblioteca",
  ["MINIMAP_TIP_RIGHT"] = "Clique direito: abrir opções",
  ["MINIMAP_TIP_DRAG"] = "Arrastar: mover botão",

  -- List empty states / generic labels
  ["BOOK_META_FALLBACK"] = "Salvo automaticamente quando você lê",
  ["BOOK_LIST_EMPTY_HEADER"] = "Ainda nenhum livro salvo",
  ["PAGINATION_EMPTY_RESULTS"] = "Nenhum resultado",
  ["LIST_EMPTY_SEARCH"] = "Nenhuma correspondência. Limpe filtros ou busca.",
  ["LIST_EMPTY_NO_BOOKS"] = "Nenhum livro salvo. Leia um livro no jogo para salvá-lo.",
  ["LOCATIONS_BROWSE_HEADER"] = "Explorar locais",

  -- Count / formatting helpers
  ["COUNT_BOOK_SINGULAR"] = "%d livro",
  ["COUNT_BOOK_PLURAL"] = "%d livros",
  ["COUNT_BOOKS_FILTERED_FORMAT"] = "%d / %d livros",
  ["COUNT_LOCATION_SINGULAR"] = "%d local",
  ["COUNT_LOCATION_PLURAL"] = "%d locais",
  ["LOCATIONS_BREADCRUMB_ROOT"] = "Todos os locais",
  ["COUNT_BOOKS_HERE_PLURAL"] = "%d livros aqui",
  ["COUNT_BOOKS_HERE_SINGULAR"] = "%d livro aqui",
  ["COUNT_SUBLOCATION_SINGULAR"] = "%d sublocal",
  ["COUNT_SUBLOCATION_PLURAL"] = "%d sublocais",
  ["COUNT_BOOKS_IN_LOCATION_SINGULAR"] = "%d livro neste local",
  ["COUNT_BOOKS_IN_LOCATION_PLURAL"] = "%d livros neste local",

  -- Location list rows
  ["LOCATION_BACK_TITLE"] = "Voltar",
  ["LOCATION_BACK_SUBTITLE"] = "Subir um nível",
  ["LOCATION_EMPTY"] = "Local vazio",
  ["LOCATIONS_EMPTY"] = "Ainda nenhum local salvo",
  ["LOCATIONS_BROWSE_SAVED"] = "Explorar locais salvos",
  ["LOCATIONS_NO_RESULTS"] = "Nenhum local ou livro disponível aqui.",

  -- Book rows
  ["BOOK_UNTITLED"] = "(Sem título)",
  ["BOOK_UNKNOWN"] = "Livro desconhecido",
  ["BOOK_MISSING_DATA"] = "Dados ausentes",
	["MATCH_TITLE"] = "TÍTULO",
	["MATCH_TEXT"] = "TEXTO",

  -- Language names / options
  ["LANGUAGE_LABEL"] = "Idioma",
  ["LANGUAGE_NAME_ENGLISH"] = "Inglês",
  ["LANGUAGE_NAME_SPANISH"] = "Espanhol",
  ["LANGUAGE_NAME_CATALAN"] = "Catalão",
  ["LANGUAGE_NAME_GERMAN"] = "Alemão",
  ["LANGUAGE_NAME_FRENCH"] = "Francês",
  ["LANGUAGE_NAME_ITALIAN"] = "Italiano",
  ["LANGUAGE_NAME_PORTUGUESE"] = "Português",
}

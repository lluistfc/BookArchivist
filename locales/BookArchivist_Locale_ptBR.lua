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
  ["READER_EMPTY_PROMPT"] = "Selecione um livro na lista",  ["READER_EMPTY_TIP_SEARCH"] = "Dica: Use a caixa de pesquisa para encontrar livros por título ou texto.",
  ["READER_EMPTY_TIP_LOCATIONS"] = "Dica: Mude para Localizações para navegar por onde você os encontrou.",  ["READER_NO_CONTENT"] = "|cFF888888Nenhum conteúdo disponível|r",
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
  ["READER_SHARE_BUTTON"] = "Compartilhar",
  ["READER_SHARE_TOOLTIP_TITLE"] = "Exportar este livro",
  ["READER_SHARE_TOOLTIP_BODY"] = "Gera uma string de exportação para este único livro. Copie-a com Ctrl+C e compartilhe com outras pessoas, ou cole-a no painel de Importação (Opções → Exportar / Importar) em outro personagem ou cliente.",
  ["READER_SHARE_POPUP_TITLE"] = "String de exportação do livro",
  ["READER_SHARE_POPUP_LABEL"] = "Use Ctrl+C para copiar esta string e depois compartilhe-a com outros jogadores ou cole-a em outro cliente do Book Archivist.",
  ["READER_SHARE_SELECT_ALL"] = "Selecionar tudo",
  ["SHARE_CHAT_HINT"] = "Crie um link clicável no chat, ou copie a string de exportação abaixo para compartilhar diretamente.",
  ["SHARE_TO_CHAT_BUTTON"] = "Compartilhar no chat",
  ["SHARE_LINK_INSERTED"] = "Link inserido no chat! Pressione Enter para enviar.",

  -- Import from chat links
  ["IMPORT_PROMPT_TITLE"] = "Importar livro",
  ["IMPORT_PROMPT_TEXT"] = "Cole a string de exportação do livro abaixo:",
  ["IMPORT_PROMPT_HINT"] = "O remetente deve compartilhar a string de exportação completa separadamente (fora do chat do WoW).",
  ["IMPORT_PROMPT_BUTTON"] = "Importar",
  ["IMPORT_SUCCESS"] = "Importado: %s",
  ["IMPORT_FAILED"] = "Falha na importação: %s",
  ["IMPORT_COMPLETED_WITH_WARNINGS"] = "Importação concluída com avisos",
  ["REQUESTING_BOOK"] = "Solicitando livro de %s...",
  ["REQUEST_TIMEOUT"] = "Sem resposta de %s",
  ["BOOK_NOT_AVAILABLE"] = "Livro não está mais disponível para compartilhamento",
  ["IMPORT_PROMPT_TITLE_WITH_DATA"] = "Importar: %s",
  ["IMPORT_CONFIRM_MESSAGE"] = "Livro recebido! Clique em Importar para adicionar '%s' à sua biblioteca.",

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
  ["OPTIONS_IMPORT_EXPORT_DEBUG_BUTTON"] = "Importar / Exportar / Depurar",
  ["OPTIONS_IMPORT_EXPORT_DEBUG_TOOLTIP"] = "Abre uma janela separada para importar e exportar livros.",
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
  ["OPTIONS_IMPORT_LABEL"] = "Importar um único livro",

  ["OPTIONS_IMPORT_HELP"] = "Cole uma string de exportação na caixa abaixo. A importação acontece automaticamente quando dados válidos são detectados.",
  ["OPTIONS_IMPORT_PERF_TIP"] = "Como importar neste cliente:\n\n- De outro cliente/conta: Na origem, clique em Exportar e depois em Copiar. Neste cliente, abra este painel, clique em Capturar colagem e depois pressione Ctrl+V uma vez. A importação começará automaticamente quando os dados forem detectados.\n\n- Mesmo cliente após Copiar: Clique em Exportar, depois em Copiar, depois (opcionalmente) em Capturar colagem e pressione Ctrl+V uma vez. Isso permite testar exatamente o que foi copiado.\n\nImportante: Capturar colagem não pode ler sua área de transferência sozinho. Apenas diz ao addon para escutar o *próximo* Ctrl+V que você realizar no jogo; sem essa colagem manual, nada é importado.\n\nAviso de desempenho: Importar uma string de exportação grande pode travar temporariamente o cliente do jogo enquanto o WoW processa a colagem e os livros são decodificados. Por exemplo, importar cerca de 10-15 livros pode pausar o jogo por 10-15 segundos; importar 50 ou mais livros pode levar perto de um minuto, e cargas muito grandes podem causar falha na colagem ou até travar o cliente devido a limitações do motor. Sempre que possível, prefira exportações menores ou importações por personagem em vez de importações extremamente grandes tudo-em-um.",
  ["OPTIONS_IMPORT_STATUS_DEFAULT"] = "Cole o texto de exportação e aguarde 'Dados recebidos' antes de importar.",
  ["OPTIONS_IMPORT_STATUS_PASTE_HINT"] = "Pressione agora Ctrl+V para colar e depois aguarde 'Dados recebidos'.",
  ["OPTIONS_IMPORT_STATUS_PREPARING"] = "Preparando importação…",
  ["OPTIONS_IMPORT_STATUS_PHASE_DECODE"] = "Decodificando dados",
  ["OPTIONS_IMPORT_STATUS_PHASE_PARSED"] = "Lendo livros",
  ["OPTIONS_IMPORT_STATUS_PHASE_MERGE"] = "Mesclando livros",
  ["OPTIONS_IMPORT_STATUS_PHASE_SEARCH"] = "Atualizando índice de busca",
  ["OPTIONS_IMPORT_STATUS_PHASE_TITLES"] = "Atualizando títulos",
  ["OPTIONS_IMPORT_STATUS_COMPLETE"] = "Importação concluída.",
  ["OPTIONS_IMPORT_STATUS_FAILED"] = "Falha na importação: %s",  ["OPTIONS_IMPORT_STATUS_ERROR"] = "Erro na importação (%s): %s",  ["OPTIONS_IMPORT_STATUS_TOO_LARGE"] = "Carga muito grande. Cancelando.",
  ["OPTIONS_IMPORT_STATUS_NO_EXPORT_IN_CLIPBOARD"] = "Nenhum texto de exportação detectado na área de transferência. Certifique-se de ter clicado em Copiar no cliente de origem.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_RECEIVED"] = "Dados recebidos (%d caracteres). Importando…",
  ["OPTIONS_IMPORT_STATUS_UNAVAILABLE"] = "Importação indisponível.",
  ["OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING"] = "Nenhum dado de importação para processar.",
  ["OPTIONS_IMPORT_STATUS_IN_PROGRESS"] = "Uma importação já está em andamento.",
  ["OPTIONS_IMPORT_STATUS_SUMMARY"] = "Importados: %d novos, %d mesclados",	["OPTIONS_TOOLTIP_LABEL"] = "Mostrar etiqueta 'Arquivado' na dica",
	["OPTIONS_TOOLTIP_TOOLTIP"] = "Quando ativado, itens legíveis cujo texto foi salvo para este personagem mostrarão uma linha adicional 'Book Archivist: Arquivado' na dica de ferramenta.",
	["OPTIONS_RELOAD_REQUIRED"] = "Idioma alterado! Interface principal atualizada. Digite /reload se quiser atualizar este painel de configurações também.",
  ["OPTIONS_DEBUG_LABEL"] = "Modo de depuração",
  ["OPTIONS_DEBUG_TOOLTIP"] = "Quando ativado, mostra um registro de depuração abaixo da caixa de importação com diagnósticos detalhados para solução de problemas.",
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

  ["LIST_SHARE_BOOK_MENU"] = "Compartilhar / Exportar este livro",

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

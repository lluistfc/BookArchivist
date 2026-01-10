# Detailed SavedVariables Usage Audit

## Summary

Analyzed all "ACTIVELY USED" options to verify if they're genuinely necessary or can be removed.

## Analysis Results

### ✅ ESSENTIAL (Must Keep)

#### 1. `tooltip.enabled` (`options.tooltip.enabled`)
- **Read locations**: 
  - `BookArchivist_Tooltip.lua:19-30` - `isTooltipEnabled()` checks this to enable/disable item tooltip tags
  - `Options.lua:70-86` - `IsTooltipEnabled()` API method
- **Write locations**: UI Options panel
- **Purpose**: Controls whether addon adds "[Read]" tags to item tooltips
- **User control**: Yes (Options panel checkbox)
- **Verdict**: **KEEP** - Actively used, user-controllable feature

#### 2. `list.sortMode` (`options.list.sortMode`)
- **Read locations**:
  - `BookArchivist_UI_List_Sort.lua:85-94` - `GetSortMode()` reads for list sorting
  - `ListConfig.lua:86-96` - `GetSortMode()` validates and returns sort mode
- **Write locations**: Sort dropdown menu in UI
- **Purpose**: Controls book list order (lastSeen/title/firstSeen/seenCount)
- **User control**: Yes (Sort dropdown in UI)
- **Verdict**: **KEEP** - Actively used, user-controllable feature

#### 3. `list.pageSize` (`options.list.pageSize`)
- **Read locations**:
  - `BookArchivist_UI_List_Pagination.lua:23-42` - `GetPageSize()` for pagination
  - `BookArchivist_UI_List_Rows.lua:83,87` - Used to paginate book list
  - `ListConfig.lua:117-120` - Normalizes and returns page size
- **Write locations**: Page size controls in UI
- **Purpose**: Controls how many books show per page (25/50/100)
- **User control**: Yes (Page size selector in UI)
- **Verdict**: **KEEP** - Actively used, user-controllable feature

#### 4. `list.filters.favoritesOnly` (`options.list.filters.favoritesOnly`)
- **Read locations**:
  - `BookArchivist_UI_List_Header.lua:99` - `EntryMatchesFilters()` filters list
  - `BookArchivist_UI_List_Location.lua:525` - Cache key for location lists
  - `Core.lua:531,533` - Virtual category handling
- **Write locations**: Filter toggle in UI
- **Purpose**: Show only favorited books
- **User control**: Yes (Filter toggle in list header)
- **Verdict**: **KEEP** - Actively used, user-controllable feature

#### 5. `list.filters.multiPage` (`options.list.filters.multiPage`)
- **Read locations**:
  - `BookArchivist_UI_List_Header.lua:93` - `EntryMatchesFilters()` filters list
- **Write locations**: Filter toggle in UI
- **Purpose**: Show only books with multiple pages
- **User control**: Yes (Filter toggle in list header)
- **Verdict**: **KEEP** - Actively used, user-controllable feature

#### 6. `list.filters.unread` (`options.list.filters.unread`)
- **Read locations**:
  - `BookArchivist_UI_List_Header.lua:96` - `EntryMatchesFilters()` filters list
- **Write locations**: Filter toggle in UI
- **Purpose**: Show only unread books
- **User control**: Yes (Filter toggle in list header)
- **Verdict**: **KEEP** - Actively used, user-controllable feature

#### 7. `list.filters.hasLocation` (`options.list.filters.hasLocation`)
- **Read locations**:
  - `BookArchivist_UI_List_Header.lua:90` - `EntryMatchesFilters()` filters list
- **Write locations**: Filter toggle in UI
- **Purpose**: Show only books with known locations
- **User control**: Yes (Filter toggle in list header)
- **Verdict**: **KEEP** - Actively used, user-controllable feature

#### 8. `ui.resumeLastPage` (`options.ui.resumeLastPage`)
- **Read locations**:
  - `BookArchivist_UI_Reader.lua:264-265` - `shouldResumeLastPage()` checks setting
  - `BookArchivist_UI_Reader.lua:663,689` - Implements bookmark resumption
  - `Options.lua:126-131` - `IsResumeLastPageEnabled()` API
- **Write locations**: Options panel checkbox
- **Purpose**: Resume reading at last page when reopening a book
- **User control**: Yes (Options panel checkbox)
- **Verdict**: **KEEP** - Actively used, user-controllable feature

#### 9. `minimapButton` (`options.minimapButton`)
- **Read locations**:
  - `BookArchivist_Minimap.lua:19-20` - `getOptions()` reads minimap button state
  - `Options.lua:44-50` - `GetMinimapButtonOptions()` returns button config
- **Write locations**: Minimap button drag/position updates
- **Purpose**: Stores minimap button position (angle)
- **User control**: Indirectly (by dragging minimap button)
- **Verdict**: **KEEP** - Actively used for minimap icon positioning

#### 10. `ui.virtualCategoriesEnabled` (`options.ui.virtualCategoriesEnabled`)
- **Read locations**:
  - `BookArchivist_UI_List_Sort.lua:154` - Checks if virtual categories active
  - `BookArchivist_UI_List_Categories.lua:13-17` - `IsVirtualCategoriesEnabled()`
  - `Options.lua:113-118` - API method
- **Write locations**: Options panel (planned feature toggle)
- **Purpose**: Enable/disable "Recent", "Favorites" virtual categories
- **User control**: Yes (Options panel checkbox)
- **Verdict**: **KEEP** - Actively used, user-controllable feature

#### 11. `language` (`options.language`)
- **Read locations**:
  - `Core.lua:114-116` - Validates and initializes language tag
  - `Core.lua:302-306` - `GetLanguage()` returns normalized tag
- **Write locations**: Options panel language selector
- **Purpose**: Controls addon localization language
- **User control**: Yes (Options panel dropdown)
- **Verdict**: **KEEP** - Actively used, user-controllable feature

### ⚠️ DEV-ONLY (Keep but verify cleanup in production)

#### 12. `debug` (`options.debug`)
- **Read locations**:
  - `BookArchivist_DB.lua:96-98` - Disables if DevTools not loaded
  - `DevOptions.lua:29,30,50,55` - Dev panel toggle
- **Write locations**: Dev Options panel (when dev TOC loaded)
- **Purpose**: Enables dev-mode debugging features
- **User control**: Only when dev TOC present
- **Production behavior**: Auto-disabled if DevTools missing
- **Verdict**: **KEEP** - Properly handled, auto-disables in production

#### 13. `uiDebug` (`options.uiDebug`)
- **Read locations**:
  - `BookArchivist_UI_Frame.lua:27` - `wantsDebug` checks both debug flags
  - `BookArchivist_UI.lua:376` - Same check for debug features
  - `BookArchivist_DB.lua:101-103` - Disables if InitDebugGrid missing
  - `DevOptions.lua:32,33,60,65,110` - Dev panel toggle
- **Write locations**: Dev Options panel (when dev TOC loaded)
- **Purpose**: Enables UI debug grid overlay
- **User control**: Only when dev TOC present
- **Production behavior**: Auto-disabled if DevTools.InitDebugGrid missing
- **Verdict**: **KEEP** - Properly handled, auto-disables in production

## Recommendations

### All Options Are Valid
All 13 "ACTIVELY USED" options are genuinely used and serve real purposes:
- 11 are user-facing features with UI controls
- 2 are dev-only but properly handle production environments

### No Removals Needed
Unlike `listWidth` (which had no UI to change it), all these options:
1. Have active read consumers
2. Have UI controls for users to modify them
3. Serve documented purposes
4. Are properly validated and defaulted

### Dev Options Handling
`debug` and `uiDebug` are properly safeguarded:
- Auto-disable if dev modules not loaded (DB.lua:96-103)
- Only show in Options when DevTools present
- Won't cause errors in production builds

## Comparison: listWidth vs Other Options

**listWidth (REMOVED)**:
- ❌ No UI to change it
- ❌ Setter never called
- ❌ Effectively a hardcoded constant
- ✅ Correctly removed and hardcoded to 360

**Other Options (KEPT)**:
- ✅ All have UI controls
- ✅ All have active consumers
- ✅ All serve user-visible purposes
- ✅ Dev options properly handle production

## Conclusion

**No additional options should be removed.** All 13 are legitimate, actively used settings that users can control and that affect addon behavior.

The `listWidth` removal was correct because it was a pseudo-option (no UI to change it). The remaining options are genuine user preferences that belong in SavedVariables.

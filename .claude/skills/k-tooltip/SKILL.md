---
name: k-tooltip
description: >
  GameTooltip integration for showing "Archived" status on items and world objects.
  Covers TooltipDataProcessor hooks, index lookups (O(1) performance), item vs object
  detection, GUID parsing, title normalization, and enable/disable settings. Use when
  debugging tooltip issues or implementing similar tooltip integration.
  Triggers: tooltip, GameTooltip, Archived, TooltipDataProcessor, item tooltip, object tooltip.
---

# Tooltip Integration System

Knowledge for how BookArchivist adds "Archived ✓" to GameTooltip.

## Quick Reference

| Tooltip Type | Data Source | Index Used |
|--------------|-------------|------------|
| **Inventory items** | `data.id` (itemID) | `itemToBookIds[itemID]` |
| **World objects** | `data.guid` (GUID) | `objectToBookId[objectID]` |
| **Chat links** | Title text (fallback) | `titleToBookIds[normalized]` |

All lookups are O(1) using the index system.

## Full Documentation

See: [../../.github/copilot-skills/4-tooltip-integration.md](../../.github/copilot-skills/4-tooltip-integration.md)

Contains:
- GameTooltip hook setup (TooltipDataProcessor)
- Item tooltip handler (handleItemTooltip)
- Object tooltip handler (handleObjectTooltip)
- Index lookup logic (item/object/title)
- GUID parsing (GameObject vs Creature)
- Title normalization (lowercase, strip markup)
- Enable/disable settings (`options.tooltip.enabled`)
- Performance optimization (O(1) lookups, no iteration)

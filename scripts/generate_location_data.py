#!/usr/bin/env python3
"""
Generate Lua location data file from Wowhead zones JSON.

Filters out scenarios, BGs, arenas, and housing areas.
Creates a lookup table for Book Echo location context system.
"""

import json
import os
from pathlib import Path

# Category mapping
CATEGORY_MAP = {
    -1: "Housing",
    0: "Eastern Kingdoms",
    1: "Kalimdor",
    2: "Dungeon",
    3: "Raid",
    6: "Battleground",
    7: "Scenario",
    8: "Outland",
    9: "Arena",
    10: "Northrend",
    11: "Cataclysm Zone",
    12: "Scenario",
    13: "Draenor",
    14: "Broken Isles",
    15: "Kul Tiras",
    16: "Zandalar",
    17: "Shadowlands",
    18: "Dragon Isles",
    19: "Khaz Algar"
}

# Expansion mapping
EXPANSION_MAP = {
    0: "Classic",
    1: "The Burning Crusade",
    2: "Wrath of the Lich King",
    3: "Cataclysm",
    4: "Mists of Pandaria",
    5: "Warlords of Draenor",
    6: "Legion",
    7: "Battle for Azeroth",
    8: "Shadowlands",
    9: "Dragonflight",
    10: "The War Within"
}

# Categories to exclude
EXCLUDED_CATEGORIES = {
    -1,  # Housing
    6,   # Battleground
    7,   # Scenario
    9,   # Arena
    12   # Scenario
}

# Test/dev zone patterns to exclude
TEST_ZONE_PATTERNS = [
    'test', 'dev', 'DEV', 'Test', 'Dev',
    '[DEV', '[DO NOT', 'DO NOT USE',
    'delete me', 'Delete me',
    'Playground', 'playground',
    'Land', 'land',  # "Marie Lazar Land", "Doug Land", etc.
    '_dev', 'dev_', 'dev1', 'dev2',
    'New Hire', 'NewHire', 'New hires',
    'Map ', 'map ',  # "Map 2437 [DEV AREA]"
    'Zone2l', 'Zone3', 'Zone4', 'Zone6',  # Test zone naming patterns
    '10 Canyon', '10 Highlands', '11 Zone',
    '10.2 Devland', '10Zone6', '11Test',
    'Doodad', 'doodad',
    'Dev Area', 'Dev area',  # "Dev Area - A", "Dev Area - B", etc.
]

def is_test_zone(name: str) -> bool:
    """Check if zone name indicates it's a test/dev zone."""
    if not name:
        return False
    
    name_lower = name.lower()
    
    # Starts with patterns (dev/test prefixes)
    if name_lower.startswith(('zz_', 'zzold', 'envart', 'sinew', 'mal', 'dev map -', '[temp]')):
        return True
    
    # Version prefix patterns (10dur_, 11dur_, 12dur_ etc.)
    if len(name) > 4 and name[:2].isdigit() and name[2:5].lower() in ('dur', 'zon', 'map'):
        return True
    
    # Ends with patterns (test suffixes)
    if name_lower.endswith(('test', 'test1', 'test2', 'testarea', 'demoarea', '_demoarea')):
        return True
    
    # Contains patterns
    exact_patterns = [
        'dev area -',  # "Dev Area - A", "Dev Area - B"
        '[dev',
        '[do not',
        'do not use',
        'delete me',
        'playground',
        '_dev', 'dev_', 'dev1', 'dev2',
        'new hire',
        'newhire',
        'zone2l', 'zone3', 'zone4', 'zone6',
        'doodad',
        ' test', 'test ',  # Space-bounded test
        '_test_', '_test',  # Underscore-bounded test (12DUR_Oasis_TEST_MCarwen)
        'testarea',
        'jrz',  # "JrzTest"
        'reborntree',
        'darkglow',  # "Darkglow Hollows" seems test-like
        'zsewell',  # Dev name
        'alexandradd',  # Dev name
        'demoarea',  # "Durotar_DemoArea", "Azshara_DemoArea"
        'prototype',  # "Housing NPC Prototype Neighborhood"
        'smoketest',  # "Sound Room - Audio Smoketest"
        'housing_plots',  # "Housing_Plots"
        '[dnt]',  # Do Not Test
        '[ph]',  # Placeholder
        '_mcarwen', '_acarwen',  # Dev names in zone titles
        ' (v2)', ' (v3)', ' (v4)',  # Version suffixes (test duplicates)
        'damarcus_world',  # Dev world
        'qa and dvd',  # "- QA and DVD GLOBAL -"
        'dvd global',
        ' - qa ',  # QA zones with dash formatting
    ]
    
    for pattern in exact_patterns:
        if pattern in name_lower:
            return True    
    # Check for street addresses (e.g., "2510 Coreway")
    # Pattern: starts with digits followed by space
    if len(name) > 0 and name[0].isdigit():
        parts = name.split()
        if len(parts) >= 2 and parts[0].isdigit():
            return True    
    # Names containing "Land" that are likely test zones
    if ' land' in name_lower or 'land ' in name_lower:
        # Exclude legitimate zones
        legitimate_lands = ['outland', 'northrend', 'wetland', 'highland', 'homeland', 'shadowland', 'borderland', 'bloodland', 'heartland', 'timeless land', 'wasteland', 'badland']
        if not any(legit in name_lower for legit in legitimate_lands):
            return True
    
    # Specific test naming patterns
    test_names = [
        '10 canyon', '10 highlands', '11 zone',
        '10.2 devland', '10zone6', '11test',
        'map 24', 'map 25',  # "Map 2437"
    ]
    
    for test_name in test_names:
        if test_name in name_lower:
            return True
    
    return False

def generate_lua_file(json_path: str, output_path: str):
    """Generate Lua location data file from JSON."""
    
    # Read JSON
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    locations = data.get('data', [])
    
    # Filter locations
    filtered = []
    excluded_by_category = 0
    excluded_by_test = 0
    
    for loc in locations:
        category = loc.get('category')
        name = loc.get('name', '')
        
        if category in EXCLUDED_CATEGORIES:
            excluded_by_category += 1
            continue
        
        if is_test_zone(name):
            excluded_by_test += 1
            continue
        
        filtered.append(loc)
    
    print(f"Total locations: {len(locations)}")
    print(f"Filtered locations: {len(filtered)}")
    print(f"Excluded by category: {excluded_by_category}")
    print(f"Excluded as test zones: {excluded_by_test}")
    print(f"Total excluded: {len(locations) - len(filtered)}")
    
    # Generate Lua file
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("-- Location Data for Book Echo Context System\n")
        f.write("-- Generated from Wowhead zones data\n")
        f.write("-- DO NOT EDIT MANUALLY - regenerate with scripts/generate_location_data.py\n")
        f.write("\n")
        f.write("local LocationData = {}\n")
        f.write("BookArchivist.LocationData = LocationData\n")
        f.write("\n")
        
        # Category map
        f.write("-- Category mapping\n")
        f.write("LocationData.CATEGORY = {\n")
        for cat_id, cat_name in sorted(CATEGORY_MAP.items()):
            if cat_id not in EXCLUDED_CATEGORIES:
                f.write(f'  [{cat_id}] = "{cat_name}",\n')
        f.write("}\n\n")
        
        # Expansion map
        f.write("-- Expansion mapping\n")
        f.write("LocationData.EXPANSION = {\n")
        for exp_id, exp_name in sorted(EXPANSION_MAP.items()):
            f.write(f'  [{exp_id}] = "{exp_name}",\n')
        f.write("}\n\n")
        
        # Location type detection
        f.write("-- Location type helpers\n")
        f.write("function LocationData:IsDungeon(category)\n")
        f.write("  return category == 2\n")
        f.write("end\n\n")
        
        f.write("function LocationData:IsRaid(category)\n")
        f.write("  return category == 3\n")
        f.write("end\n\n")
        
        f.write("function LocationData:IsInstance(category)\n")
        f.write("  return category == 2 or category == 3\n")
        f.write("end\n\n")
        
        # Locations by ID
        f.write("-- All locations by ID\n")
        f.write("LocationData.byId = {\n")
        
        for loc in sorted(filtered, key=lambda x: x.get('id', 0)):
            loc_id = loc.get('id')
            name = loc.get('name', 'Unknown').replace('"', '\\"')
            category = loc.get('category', -1)
            expansion = loc.get('expansion', 0)
            instance = loc.get('instance', 0)
            
            f.write(f'  [{loc_id}] = {{\n')
            f.write(f'    name = "{name}",\n')
            f.write(f'    category = {category},\n')
            f.write(f'    expansion = {expansion},\n')
            f.write(f'    instance = {instance},\n')
            f.write(f'  }},\n')
        
        f.write("}\n\n")
        
        # Locations by name (for lookup)
        f.write("-- Location lookup by name (case-insensitive)\n")
        f.write("LocationData.byName = {}\n")
        f.write("for id, data in pairs(LocationData.byId) do\n")
        f.write("  local nameLower = data.name:lower()\n")
        f.write("  LocationData.byName[nameLower] = data\n")
        f.write("end\n\n")
        
        # Lookup function
        f.write("-- Lookup location by name\n")
        f.write("function LocationData:Find(name)\n")
        f.write("  if not name then return nil end\n")
        f.write("  local nameLower = name:lower()\n")
        f.write("  return self.byName[nameLower]\n")
        f.write("end\n\n")
        
        # Context phrase helpers
        f.write("-- Get location type for context phrase selection\n")
        f.write("function LocationData:GetLocationType(name)\n")
        f.write("  local data = self:Find(name)\n")
        f.write("  if not data then return 'zone' end\n")
        f.write("  \n")
        f.write("  if data.category == 2 then return 'dungeon' end\n")
        f.write("  if data.category == 3 then return 'raid' end\n")
        f.write("  \n")
        f.write("  -- Zone type\n")
        f.write("  return 'zone'\n")
        f.write("end\n\n")
        
        # Stats
        f.write(f"-- Total locations: {len(filtered)}\n")
        
        # Count by category
        category_counts = {}
        for loc in filtered:
            cat = loc.get('category', -1)
            category_counts[cat] = category_counts.get(cat, 0) + 1
        
        f.write("-- Locations by category:\n")
        for cat_id in sorted(category_counts.keys()):
            cat_name = CATEGORY_MAP.get(cat_id, f"Unknown ({cat_id})")
            count = category_counts[cat_id]
            f.write(f"--   {cat_name}: {count}\n")
    
    print(f"\nGenerated: {output_path}")
    print(f"Total locations in Lua: {len(filtered)}")

def main():
    # Paths
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    json_path = project_root / "docs" / "feature-plans" / "locations.json"
    output_path = project_root / "core" / "BookArchivist_LocationData.lua"
    
    if not json_path.exists():
        print(f"ERROR: {json_path} not found")
        return
    
    generate_lua_file(str(json_path), str(output_path))
    print("\nDone! Location data generated successfully.")
    print("\nNext steps:")
    print("1. Add BookArchivist_LocationData.lua to BookArchivist.toc")
    print("2. Update BookArchivist_BookEcho.lua to use LocationData:GetLocationType()")
    print("3. Enhance context phrase selection based on location metadata")

if __name__ == "__main__":
    main()

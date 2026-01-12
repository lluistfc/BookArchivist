-- Book Echo: Zone-Specific Phrase Suggestions (Refactored)
-- Categories group zones by environmental type for better maintainability
-- Format: [zoneId] = "CATEGORY_NAME" or { primary = "...", alt1 = "...", alt2 = "..." } for unique zones

-- Phrase category definitions
local PHRASE_CATEGORIES = {
  -- Generic fallback (used for 100+ zones)
  GENERIC = {
    primary = "in",
    alt1 = "across",
    alt2 = "through"
  },
  
  -- Dungeons & Raids (formal structures)
  DUNGEON_HALLS = {
    primary = "within",
    alt1 = "in the depths of",
    alt2 = "in the halls of"
  },
  
  DUNGEON_SHADOWS = {
    primary = "within",
    alt1 = "in the shadows of",
    alt2 = "deep inside"
  },
  
  -- Cities & settlements
  CITY_STREETS = {
    primary = "among the shelves of",
    alt1 = "in the streets of",
    alt2 = "within the walls of"
  },
  
  -- Natural environments
  FOREST = {
    primary = "beneath the canopy of",
    alt1 = "along the paths of",
    alt2 = "deep within"
  },
  
  MOUNTAINS = {
    primary = "high among the peaks of",
    alt1 = "along the ridges of",
    alt2 = "in the foothills of"
  },
  
  COLD_NORTH = {
    primary = "in the cold of",
    alt1 = "across the snowfields of",
    alt2 = "beneath the northern lights of"
  },
  
  MARSHLANDS = {
    primary = "through the marshes of",
    alt1 = "in the wetlands of",
    alt2 = "along the reeds of"
  },
  
  DESERT_BARRENS = {
    primary = "in the sands of",
    alt1 = "across the wilds of",
    alt2 = "under the open sky of"
  },
  
  COASTAL_OCEAN = {
    primary = "along the shores of",
    alt1 = "out on",
    alt2 = "beneath the waves of"
  },
  
  ISLAND = {
    primary = "upon the isle of",
    alt1 = "along the shores of",
    alt2 = "out on"
  },
  
  -- Dark/cursed zones
  SHADOWED_RUINS = {
    primary = "in the shadow of",
    alt1 = "amid the ruins of",
    alt2 = "on the edge of"
  },
  
  ANCIENT_RUINS = {
    primary = "among the ruins of",
    alt1 = "within the ancient halls of",
    alt2 = "amid the echoes of"
  },
}

-- Zone assignments by category
BookArchivist.BookEchoZonePhrases = {
  -- GENERIC (100+ zones with no distinctive features)
  [1] = "GENERIC", [14] = "GENERIC", [16] = "GENERIC", [33] = "GENERIC", [38] = "GENERIC",
  [40] = "GENERIC", [47] = "GENERIC", [141] = "GENERIC", [215] = "GENERIC", [357] = "GENERIC",
  [3433] = "GENERIC", [3518] = "GENERIC", [3523] = "GENERIC", [3711] = "GENERIC", [4714] = "GENERIC",
  [4737] = "GENERIC", [4859] = "GENERIC", [5095] = "GENERIC", [5287] = "GENERIC", [5389] = "GENERIC",
  [5416] = "GENERIC", [5733] = "GENERIC", [6170] = "GENERIC", [6452] = "GENERIC", [6457] = "GENERIC",
  [6662] = "GENERIC", [6721] = "GENERIC", [6722] = "GENERIC", [6755] = "GENERIC", [6756] = "GENERIC",
  [6941] = "GENERIC", [7078] = "GENERIC", [7083] = "GENERIC", [7332] = "GENERIC", [7333] = "GENERIC",
  [7334] = "GENERIC", [7541] = "GENERIC", [7558] = "GENERIC", [7578] = "GENERIC", [7634] = "GENERIC",
  [7638] = "GENERIC", [7674] = "GENERIC", [7679] = "GENERIC", [7731] = "GENERIC", [7744] = "GENERIC",
  [7745] = "GENERIC", [7813] = "GENERIC", [7830] = "GENERIC", [7875] = "GENERIC", [7877] = "GENERIC",
  [7879] = "GENERIC", [7884] = "GENERIC", [7885] = "GENERIC", [7887] = "GENERIC", [7888] = "GENERIC",
  [7889] = "GENERIC", [7890] = "GENERIC", [7891] = "GENERIC", [7893] = "GENERIC", [7895] = "GENERIC",
  [7896] = "GENERIC", [7897] = "GENERIC", [7898] = "GENERIC", [7899] = "GENERIC", [7900] = "GENERIC",
  [7901] = "GENERIC", [7921] = "GENERIC", [7967] = "GENERIC", [8000] = "GENERIC", [8054] = "GENERIC",
  [8091] = "GENERIC", [8093] = "GENERIC", [8473] = "GENERIC", [8476] = "GENERIC", [8488] = "GENERIC",
  [8525] = "GENERIC", [8526] = "GENERIC", [8529] = "GENERIC", [8567] = "GENERIC", [8568] = "GENERIC",
  [8574] = "GENERIC", [8591] = "GENERIC", [8598] = "GENERIC", [8656] = "GENERIC", [8665] = "GENERIC",
  [8666] = "GENERIC", [8667] = "GENERIC", [8668] = "GENERIC", [8670] = "GENERIC", [8685] = "GENERIC",
  [8701] = "GENERIC", [8714] = "GENERIC", [8716] = "GENERIC", [8718] = "GENERIC", [8721] = "GENERIC",
  [8726] = "GENERIC", [8729] = "GENERIC", [8915] = "GENERIC", [8916] = "GENERIC", [8956] = "GENERIC",
  [8978] = "GENERIC", [9023] = "GENERIC", [9172] = "GENERIC", [9173] = "GENERIC", [9183] = "GENERIC",
  [9310] = "GENERIC", [9355] = "GENERIC", [9383] = "GENERIC", [9387] = "GENERIC", [9388] = "GENERIC",
  [9396] = "GENERIC", [9397] = "GENERIC", [9407] = "GENERIC", [9485] = "GENERIC", [9489] = "GENERIC",
  [9541] = "GENERIC", [9552] = "GENERIC", [9554] = "GENERIC", [9562] = "GENERIC", [9588] = "GENERIC",
  [9593] = "GENERIC", [9599] = "GENERIC", [9602] = "GENERIC", [9627] = "GENERIC", [9660] = "GENERIC",
  [9661] = "GENERIC", [9662] = "GENERIC", [9663] = "GENERIC", [9664] = "GENERIC", [9665] = "GENERIC",
  [9698] = "GENERIC", [9703] = "GENERIC", [9704] = "GENERIC", [9765] = "GENERIC", [9771] = "GENERIC",
  [9772] = "GENERIC", [9808] = "GENERIC", [9962] = "GENERIC", [9970] = "GENERIC", [9979] = "GENERIC",
  [9980] = "GENERIC", [9994] = "GENERIC", [10015] = "GENERIC", [10034] = "GENERIC", [10088] = "GENERIC",
  [10157] = "GENERIC", [10213] = "GENERIC", [10267] = "GENERIC", [10290] = "GENERIC", [10380] = "GENERIC",
  [10397] = "GENERIC", [10413] = "GENERIC", [10430] = "GENERIC", [10456] = "GENERIC", [10534] = "GENERIC",
  [10565] = "GENERIC", [10625] = "GENERIC", [10714] = "GENERIC", [10727] = "GENERIC", [10986] = "GENERIC",
  [11012] = "GENERIC", [11356] = "GENERIC", [11382] = "GENERIC", [11400] = "GENERIC", [11510] = "GENERIC",
  [11539] = "GENERIC", [11540] = "GENERIC", [12847] = "GENERIC", [12848] = "GENERIC", [13329] = "GENERIC",
  [13332] = "GENERIC", [13409] = "GENERIC", [13433] = "GENERIC", [13536] = "GENERIC", [13553] = "GENERIC",
  [13570] = "GENERIC", [13581] = "GENERIC", [13582] = "GENERIC", [13633] = "GENERIC", [13645] = "GENERIC",
  [13646] = "GENERIC", [13647] = "GENERIC", [13672] = "GENERIC", [13708] = "GENERIC", [13802] = "GENERIC",
  [13844] = "GENERIC", [13862] = "GENERIC", [13891] = "GENERIC", [13898] = "GENERIC", [13928] = "GENERIC",
  [13952] = "GENERIC", [14433] = "GENERIC", [14665] = "GENERIC", [14730] = "GENERIC", [14748] = "GENERIC",
  [14765] = "GENERIC", [14769] = "GENERIC", [14771] = "GENERIC", [14776] = "GENERIC", [15105] = "GENERIC",
  [15336] = "GENERIC", [15667] = "GENERIC", [15781] = "GENERIC", [15827] = "GENERIC", [16092] = "GENERIC",
  [16093] = "GENERIC", [16309] = "GENERIC", [16505] = "GENERIC", [16579] = "GENERIC",
  
  -- DUNGEON_HALLS (80+ dungeons/raids with formal architecture)
  [206] = "DUNGEON_HALLS", [209] = "DUNGEON_HALLS", [717] = "DUNGEON_HALLS", [718] = "DUNGEON_HALLS",
  [796] = "DUNGEON_HALLS", [1477] = "DUNGEON_HALLS", [1581] = "DUNGEON_HALLS", [1583] = "DUNGEON_HALLS",
  [1584] = "DUNGEON_HALLS", [2159] = "DUNGEON_HALLS", [2677] = "DUNGEON_HALLS", [3428] = "DUNGEON_HALLS",
  [3562] = "DUNGEON_HALLS", [3713] = "DUNGEON_HALLS", [3714] = "DUNGEON_HALLS", [3715] = "DUNGEON_HALLS",
  [3716] = "DUNGEON_HALLS", [3717] = "DUNGEON_HALLS", [3789] = "DUNGEON_HALLS", [3790] = "DUNGEON_HALLS",
  [3791] = "DUNGEON_HALLS", [3792] = "DUNGEON_HALLS", [3836] = "DUNGEON_HALLS", [3847] = "DUNGEON_HALLS",
  [3848] = "DUNGEON_HALLS", [3849] = "DUNGEON_HALLS", [3923] = "DUNGEON_HALLS", [4196] = "DUNGEON_HALLS",
  [4228] = "DUNGEON_HALLS", [4264] = "DUNGEON_HALLS", [4265] = "DUNGEON_HALLS", [4272] = "DUNGEON_HALLS",
  [4415] = "DUNGEON_HALLS", [4493] = "DUNGEON_HALLS", [4603] = "DUNGEON_HALLS", [4812] = "DUNGEON_HALLS",
  [4820] = "DUNGEON_HALLS", [4926] = "DUNGEON_HALLS", [4945] = "DUNGEON_HALLS", [4987] = "DUNGEON_HALLS",
  [5004] = "DUNGEON_HALLS", [5088] = "DUNGEON_HALLS", [5334] = "DUNGEON_HALLS", [5600] = "DUNGEON_HALLS",
  [5638] = "DUNGEON_HALLS", [5786] = "DUNGEON_HALLS", [5918] = "DUNGEON_HALLS", [5956] = "DUNGEON_HALLS",
  [6052] = "DUNGEON_HALLS", [6109] = "DUNGEON_HALLS", [6125] = "DUNGEON_HALLS", [6182] = "DUNGEON_HALLS",
  [6214] = "DUNGEON_HALLS", [6622] = "DUNGEON_HALLS", [6874] = "DUNGEON_HALLS", [6951] = "DUNGEON_HALLS",
  [6967] = "DUNGEON_HALLS", [6984] = "DUNGEON_HALLS", [7307] = "DUNGEON_HALLS", [7545] = "DUNGEON_HALLS",
  [7546] = "DUNGEON_HALLS", [7672] = "DUNGEON_HALLS", [7787] = "DUNGEON_HALLS", [7805] = "DUNGEON_HALLS",
  [7812] = "DUNGEON_HALLS", [7855] = "DUNGEON_HALLS", [7996] = "DUNGEON_HALLS", [8025] = "DUNGEON_HALLS",
  [8583] = "DUNGEON_HALLS", [8638] = "DUNGEON_HALLS", [9164] = "DUNGEON_HALLS", [9527] = "DUNGEON_HALLS",
  [10425] = "DUNGEON_HALLS", [10448] = "DUNGEON_HALLS", [10581] = "DUNGEON_HALLS", [10582] = "DUNGEON_HALLS",
  [11384] = "DUNGEON_HALLS", [11395] = "DUNGEON_HALLS", [11397] = "DUNGEON_HALLS", [12831] = "DUNGEON_HALLS",
  [12837] = "DUNGEON_HALLS", [12842] = "DUNGEON_HALLS", [13561] = "DUNGEON_HALLS", [13954] = "DUNGEON_HALLS",
  [14030] = "DUNGEON_HALLS", [14082] = "DUNGEON_HALLS", [14144] = "DUNGEON_HALLS", [14872] = "DUNGEON_HALLS",
  [14883] = "DUNGEON_HALLS", [14980] = "DUNGEON_HALLS", [15522] = "DUNGEON_HALLS", [15913] = "DUNGEON_HALLS",
  
  -- DUNGEON_SHADOWS (70+ dungeons/raids with darker themes)
  [491] = "DUNGEON_SHADOWS", [721] = "DUNGEON_SHADOWS", [722] = "DUNGEON_SHADOWS", [1176] = "DUNGEON_SHADOWS",
  [1196] = "DUNGEON_SHADOWS", [1337] = "DUNGEON_SHADOWS", [1977] = "DUNGEON_SHADOWS", [2017] = "DUNGEON_SHADOWS",
  [2057] = "DUNGEON_SHADOWS", [2100] = "DUNGEON_SHADOWS", [2366] = "DUNGEON_SHADOWS", [2367] = "DUNGEON_SHADOWS",
  [2437] = "DUNGEON_SHADOWS", [2557] = "DUNGEON_SHADOWS", [3429] = "DUNGEON_SHADOWS", [3606] = "DUNGEON_SHADOWS",
  [3607] = "DUNGEON_SHADOWS", [3805] = "DUNGEON_SHADOWS", [3845] = "DUNGEON_SHADOWS", [4075] = "DUNGEON_SHADOWS",
  [4100] = "DUNGEON_SHADOWS", [4131] = "DUNGEON_SHADOWS", [4273] = "DUNGEON_SHADOWS", [4277] = "DUNGEON_SHADOWS",
  [4416] = "DUNGEON_SHADOWS", [4494] = "DUNGEON_SHADOWS", [4500] = "DUNGEON_SHADOWS", [4722] = "DUNGEON_SHADOWS",
  [4723] = "DUNGEON_SHADOWS", [4809] = "DUNGEON_SHADOWS", [4813] = "DUNGEON_SHADOWS", [4950] = "DUNGEON_SHADOWS",
  [5035] = "DUNGEON_SHADOWS", [5094] = "DUNGEON_SHADOWS", [5396] = "DUNGEON_SHADOWS", [5723] = "DUNGEON_SHADOWS",
  [5788] = "DUNGEON_SHADOWS", [5789] = "DUNGEON_SHADOWS", [5844] = "DUNGEON_SHADOWS", [5892] = "DUNGEON_SHADOWS",
  [5963] = "DUNGEON_SHADOWS", [5976] = "DUNGEON_SHADOWS", [6066] = "DUNGEON_SHADOWS", [6067] = "DUNGEON_SHADOWS",
  [6297] = "DUNGEON_SHADOWS", [6384] = "DUNGEON_SHADOWS", [6386] = "DUNGEON_SHADOWS", [6738] = "DUNGEON_SHADOWS",
  [6912] = "DUNGEON_SHADOWS", [6932] = "DUNGEON_SHADOWS", [6988] = "DUNGEON_SHADOWS", [6996] = "DUNGEON_SHADOWS",
  [7109] = "DUNGEON_SHADOWS", [7673] = "DUNGEON_SHADOWS", [7811] = "DUNGEON_SHADOWS", [8005] = "DUNGEON_SHADOWS",
  [8026] = "DUNGEON_SHADOWS", [8040] = "DUNGEON_SHADOWS", [8064] = "DUNGEON_SHADOWS", [8079] = "DUNGEON_SHADOWS",
  [8124] = "DUNGEON_SHADOWS", [8348] = "DUNGEON_SHADOWS", [8422] = "DUNGEON_SHADOWS", [8440] = "DUNGEON_SHADOWS",
  [8443] = "DUNGEON_SHADOWS", [8524] = "DUNGEON_SHADOWS", [8527] = "DUNGEON_SHADOWS", [8712] = "DUNGEON_SHADOWS",
  [8910] = "DUNGEON_SHADOWS", [9028] = "DUNGEON_SHADOWS", [9327] = "DUNGEON_SHADOWS", [9354] = "DUNGEON_SHADOWS",
  [9382] = "DUNGEON_SHADOWS", [9389] = "DUNGEON_SHADOWS", [9391] = "DUNGEON_SHADOWS", [9424] = "DUNGEON_SHADOWS",
  [9525] = "DUNGEON_SHADOWS", [9526] = "DUNGEON_SHADOWS", [9826] = "DUNGEON_SHADOWS", [9830] = "DUNGEON_SHADOWS",
  [10043] = "DUNGEON_SHADOWS", [10047] = "DUNGEON_SHADOWS", [10057] = "DUNGEON_SHADOWS", [10076] = "DUNGEON_SHADOWS",
  [10225] = "DUNGEON_SHADOWS", [10522] = "DUNGEON_SHADOWS", [12841] = "DUNGEON_SHADOWS", [12916] = "DUNGEON_SHADOWS",
  [13224] = "DUNGEON_SHADOWS", [13228] = "DUNGEON_SHADOWS", [13309] = "DUNGEON_SHADOWS", [13334] = "DUNGEON_SHADOWS",
  [13548] = "DUNGEON_SHADOWS", [13549] = "DUNGEON_SHADOWS", [13577] = "DUNGEON_SHADOWS", [13742] = "DUNGEON_SHADOWS",
  [13968] = "DUNGEON_SHADOWS", [13982] = "DUNGEON_SHADOWS", [13991] = "DUNGEON_SHADOWS", [14011] = "DUNGEON_SHADOWS",
  [14032] = "DUNGEON_SHADOWS", [14063] = "DUNGEON_SHADOWS", [14143] = "DUNGEON_SHADOWS", [14514] = "DUNGEON_SHADOWS",
  [14643] = "DUNGEON_SHADOWS", [14663] = "DUNGEON_SHADOWS", [14842] = "DUNGEON_SHADOWS", [14882] = "DUNGEON_SHADOWS",
  [14938] = "DUNGEON_SHADOWS", [14954] = "DUNGEON_SHADOWS", [14971] = "DUNGEON_SHADOWS", [14979] = "DUNGEON_SHADOWS",
  [15093] = "DUNGEON_SHADOWS", [15103] = "DUNGEON_SHADOWS", [15452] = "DUNGEON_SHADOWS", [16104] = "DUNGEON_SHADOWS",
  [16178] = "DUNGEON_SHADOWS", [16571] = "DUNGEON_SHADOWS", [16572] = "DUNGEON_SHADOWS",
  
  -- CITY_STREETS (30+ major cities)
  [1497] = "CITY_STREETS", [1519] = "CITY_STREETS", [1537] = "CITY_STREETS", [1637] = "CITY_STREETS",
  [1638] = "CITY_STREETS", [1657] = "CITY_STREETS", [2257] = "CITY_STREETS", [3487] = "CITY_STREETS",
  [3557] = "CITY_STREETS", [3703] = "CITY_STREETS", [4395] = "CITY_STREETS", [4755] = "CITY_STREETS",
  [4821] = "CITY_STREETS", [5351] = "CITY_STREETS", [6980] = "CITY_STREETS", [7502] = "CITY_STREETS",
  [7886] = "CITY_STREETS", [7892] = "CITY_STREETS", [7894] = "CITY_STREETS", [8392] = "CITY_STREETS",
  [8449] = "CITY_STREETS", [8474] = "CITY_STREETS", [8535] = "CITY_STREETS", [8700] = "CITY_STREETS",
  [8717] = "CITY_STREETS", [9394] = "CITY_STREETS", [9395] = "CITY_STREETS", [14753] = "CITY_STREETS",
  
  -- FOREST (20+ forested zones)
  [10] = "FOREST", [12] = "FOREST", [85] = "FOREST", [130] = "FOREST", [331] = "FOREST",
  [361] = "FOREST", [493] = "FOREST", [2817] = "FOREST", [3430] = "FOREST", [3519] = "FOREST",
  [4815] = "FOREST", [5339] = "FOREST", [6456] = "FOREST", [6723] = "FOREST", [7846] = "FOREST",
  [7976] = "FOREST", [12858] = "FOREST", [13975] = "FOREST", [13983] = "FOREST", [14045] = "FOREST",
  
  -- MOUNTAINS (15+ highland/mountain zones)
  [25] = "MOUNTAINS", [36] = "MOUNTAINS", [44] = "MOUNTAINS", [45] = "MOUNTAINS", [267] = "MOUNTAINS",
  [394] = "MOUNTAINS", [406] = "MOUNTAINS", [616] = "MOUNTAINS", [3522] = "MOUNTAINS", [4922] = "MOUNTAINS",
  [6176] = "MOUNTAINS", [7503] = "MOUNTAINS", [9168] = "MOUNTAINS", [9361] = "MOUNTAINS", [9386] = "MOUNTAINS",
  [10713] = "MOUNTAINS", [14357] = "MOUNTAINS",
  
  -- COLD_NORTH (10+ frozen zones)
  [67] = "COLD_NORTH", [495] = "COLD_NORTH", [618] = "COLD_NORTH", [3537] = "COLD_NORTH",
  [4197] = "COLD_NORTH", [6720] = "COLD_NORTH", [7004] = "COLD_NORTH", [10155] = "COLD_NORTH",
  [10156] = "COLD_NORTH", [14620] = "COLD_NORTH",
  
  -- MARSHLANDS (swamps/wetlands)
  [8] = "MARSHLANDS", [11] = "MARSHLANDS", [15] = "MARSHLANDS", [3521] = "MARSHLANDS", [9488] = "MARSHLANDS",
  
  -- DESERT_BARRENS (desert zones)
  [17] = "DESERT_BARRENS", [400] = "DESERT_BARRENS", [4709] = "DESERT_BARRENS", [8573] = "DESERT_BARRENS",
  [8899] = "DESERT_BARRENS", [13580] = "DESERT_BARRENS", [13583] = "DESERT_BARRENS",
  
  -- COASTAL_OCEAN (20+ coastal/ocean zones)
  [148] = "COASTAL_OCEAN", [457] = "COASTAL_OCEAN", [5144] = "COASTAL_OCEAN", [5145] = "COASTAL_OCEAN",
  [5146] = "COASTAL_OCEAN", [7543] = "COASTAL_OCEAN", [7656] = "COASTAL_OCEAN", [8053] = "COASTAL_OCEAN",
  [8445] = "COASTAL_OCEAN", [8502] = "COASTAL_OCEAN", [8566] = "COASTAL_OCEAN", [8600] = "COASTAL_OCEAN",
  [9147] = "COASTAL_OCEAN", [9598] = "COASTAL_OCEAN", [9669] = "COASTAL_OCEAN", [10028] = "COASTAL_OCEAN",
  [10731] = "COASTAL_OCEAN", [12876] = "COASTAL_OCEAN", [13643] = "COASTAL_OCEAN", [13644] = "COASTAL_OCEAN",
  [15525] = "COASTAL_OCEAN", [16108] = "COASTAL_OCEAN",
  
  -- ISLAND (25+ island zones)
  [3524] = "ISLAND", [3525] = "ISLAND", [4080] = "ISLAND", [4720] = "ISLAND", [5736] = "ISLAND",
  [5861] = "ISLAND", [6453] = "ISLAND", [6455] = "ISLAND", [8470] = "ISLAND", [8489] = "ISLAND",
  [8579] = "ISLAND", [9029] = "ISLAND", [9101] = "ISLAND", [9331] = "ISLAND", [9443] = "ISLAND",
  [9467] = "ISLAND", [9483] = "ISLAND", [10416] = "ISLAND", [13642] = "ISLAND", [14717] = "ISLAND",
  
  -- SHADOWED_RUINS (dark/cursed zones)
  [28] = "SHADOWED_RUINS", [41] = "SHADOWED_RUINS", [65] = "SHADOWED_RUINS", [139] = "SHADOWED_RUINS",
  [3483] = "SHADOWED_RUINS", [3520] = "SHADOWED_RUINS", [4298] = "SHADOWED_RUINS", [5166] = "SHADOWED_RUINS",
  [6450] = "SHADOWED_RUINS", [6454] = "SHADOWED_RUINS", [6719] = "SHADOWED_RUINS", [8012] = "SHADOWED_RUINS",
  [8023] = "SHADOWED_RUINS", [9010] = "SHADOWED_RUINS", [10154] = "SHADOWED_RUINS",
  
  -- ANCIENT_RUINS (temple/ruin zones)
  [66] = "ANCIENT_RUINS", [4706] = "ANCIENT_RUINS", [5034] = "ANCIENT_RUINS", [5695] = "ANCIENT_RUINS",
  [7834] = "ANCIENT_RUINS", [7903] = "ANCIENT_RUINS", [8499] = "ANCIENT_RUINS", [9570] = "ANCIENT_RUINS",
  [13753] = "ANCIENT_RUINS",
  
  -- UNIQUE ZONES (special/custom phrasing - 25 zones with distinctive features)
  [3] = { primary = "across the harsh badlands of", alt1 = "through the rocky canyons of", alt2 = "amid the barren wastes of" },
  [46] = { primary = "across the scorched earth of", alt1 = "through the burning wastes of", alt2 = "amid the volcanic ash of" },
  [51] = { primary = "in the molten depths of", alt1 = "amid the volcanic fury of", alt2 = "through the scorched paths of" },
  [210] = { primary = "in the frozen shadow of", alt1 = "beneath the citadel of", alt2 = "amid the eternal ice of" },
  [405] = { primary = "across the desolate wastes of", alt1 = "through the barren lands of", alt2 = "in the forsaken reaches of" },
  [440] = { primary = "in the sands of", alt1 = "across the dunes of", alt2 = "under the desert sun of" },
  [490] = { primary = "in the prehistoric wilds of", alt1 = "beneath the crater's canopy of", alt2 = "among the ancient mysteries of" },
  [719] = { primary = "in the flooded depths of", alt1 = "beneath the waters of", alt2 = "in the submerged halls of" },
  [1377] = { primary = "in the sands of", alt1 = "amid the silithid wastes of", alt2 = "beneath the scorching sun of" },
  [2717] = { primary = "in the molten heart of", alt1 = "amid the volcanic fury of", alt2 = "deep within the fiery depths of" },
  [3456] = { primary = "within the necropolis of", alt1 = "in the plague-ridden halls of", alt2 = "aboard the floating citadel of" },
  [3457] = { primary = "within the haunted tower of", alt1 = "among the twisted halls of", alt2 = "in the arcane sanctum of" },
  [3959] = { primary = "within the dark sanctum of", alt1 = "in the demon-haunted halls of", alt2 = "atop the cursed fortress of" },
  [5042] = { primary = "in the depths of", alt1 = "within the stone realm of", alt2 = "beneath the world's crust in" },
  [6451] = { primary = "through", alt1 = "along the roads of", alt2 = "in" },
  [7637] = { primary = "within the elegant streets of", alt1 = "among the nightborne spires of", alt2 = "in the arcane city of" },
  [8500] = { primary = "through the marshes of", alt1 = "in the blood-soaked swamps of", alt2 = "amid the decay of" },
  [8501] = { primary = "in the sands of", alt1 = "across the endless dunes of", alt2 = "beneath the harsh sun of" },
  [9042] = { primary = "through", alt1 = "along the roads of", alt2 = "in" },
  [14022] = { primary = "in the depths of", alt1 = "within the shadowed caverns of", alt2 = "beneath the Dragon Isles in" },
  [14529] = { primary = "within the verdant realm of", alt1 = "among the dreamscapes of", alt2 = "beneath the eternal canopy of" },
  [14752] = { primary = "in the depths of", alt1 = "within the nerubian empire of", alt2 = "beneath the webs of" },
  [14795] = { primary = "in the depths of", alt1 = "within the echoing halls of", alt2 = "amid the forges of" },
  [14838] = { primary = "beneath the sacred light of", alt1 = "within the blessed depths of", alt2 = "among the crystalline halls of" },
  [15347] = { primary = "in the bustling streets of", alt1 = "within the trade-halls of", alt2 = "among the markets of" },
}

-- Helper function to retrieve phrase data (for implementation)
function BookArchivist.GetBookEchoPhrase(zoneId)
  local entry = BookArchivist.BookEchoZonePhrases[zoneId]
  if not entry then
    return PHRASE_CATEGORIES.GENERIC -- Fallback for unknown zones
  end
  
  if type(entry) == "string" then
    return PHRASE_CATEGORIES[entry] -- Lookup category
  else
    return entry -- Return unique phrase table
  end
end

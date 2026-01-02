-- BookArchivist_Examples.lua
-- Seeds the SavedVariables with sample entries on first install.

BookArchivist = BookArchivist or {}

local Core = BookArchivist.Core
local Examples = {}
BookArchivist.Examples = Examples

local function now()
  if Core and Core.Now then
    return Core:Now()
  end
  local osTime = type(os) == "table" and os.time
  return osTime and osTime() or 0
end

local function daysAgo(days)
  return now() - (86400 * days)
end

local function buildExamples()
  return {
    {
      key = "journal of the explorer||ancient parchment||the path to knowledge begins",
      title = "Journal of the Explorer",
      creator = "Brann Bronzebeard",
      author = "",
      material = "Ancient Parchment",
      createdAt = daysAgo(7),
      firstSeenAt = daysAgo(7),
      lastSeenAt = daysAgo(2),
      seenCount = 3,
      pages = {
        [1] = "Day 47: The ancient ruins of Ulduar continue to reveal their secrets. The stone guardians here are unlike anything I've seen before. Their construction suggests a level of engineering far beyond what we previously understood.\n\nThe titanforged technology is remarkable. Each mechanism, each gear, perfectly aligned after thousands of years. Truly, the makers of this place were masters of their craft.",
        [2] = "Day 48: Found an interesting inscription today. It speaks of 'ordering the world' and 'shaping the very essence of Azeroth.' The implications are staggering.\n\nI must document everything carefully. This discovery could rewrite our understanding of history itself.",
        [3] = "Day 49: Weather turning bad. Storm approaching from the north. Will need to seek shelter soon, but the work is too important to abandon now. Just a few more measurements...",
        },
        location = {
          context = "world",
          zoneChain = { "Northrend", "The Storm Peaks", "Ulduar" },
          zoneText = "Northrend > The Storm Peaks > Ulduar",
        },
    },
    {
      key = "letter from stormwind||clean parchment||dearest friend i hope this",
      title = "Letter from Stormwind",
      creator = "A Concerned Citizen",
      author = "A Concerned Citizen",
      material = "Clean Parchment",
      createdAt = daysAgo(3),
      firstSeenAt = daysAgo(3),
      lastSeenAt = daysAgo(1),
      seenCount = 2,
      pages = {
        [1] = "Dearest Friend,\n\nI hope this letter finds you well. The situation in Stormwind has grown dire. The nobles bicker while the people suffer. I fear for what the future may bring.\n\nPlease, if you receive this, send word. We need all the help we can get.\n\nYours in hope,\nMarcus",
        },
        location = {
          context = "loot",
          zoneChain = { "Eastern Kingdoms", "Stormwind City" },
          zoneText = "Eastern Kingdoms > Stormwind City",
          mobName = "Marcus",
        },
    },
    {
      key = "the arcane primer||worn book||magic is the lifeblood of",
      title = "The Arcane Primer",
      creator = "Kirin Tor Press",
      author = "Archmage Antonidas",
      material = "Worn Book",
      createdAt = daysAgo(30),
      firstSeenAt = daysAgo(30),
      lastSeenAt = now(),
      seenCount = 5,
      pages = {
        [1] = "Magic is the lifeblood of our world. It flows through everything, connecting all things in ways we are only beginning to understand.\n\nThis primer serves as an introduction to the fundamental principles of arcane magic. Study it well, young apprentice, for the path ahead is long and demanding.",
        [2] = "Chapter One: The Basics of Mana\n\nMana is the raw energy that fuels all magical endeavors. It exists naturally in the world, flowing through ley lines and pooling in places of power. A mage must learn to sense this energy, to draw it forth, and to shape it according to their will.",
        [3] = "The first exercise is simple: meditation. Sit quietly, clear your mind, and feel the energy around you. Do not try to grasp it yet. Simply observe. Understanding must come before manipulation.",
        [4] = "Chapter Two: Shaping Reality\n\nOnce you can sense mana, you must learn to channel it. This requires focus, discipline, and above all, respect for the forces you are wielding.\n\nMany young mages are eager to demonstrate their power. This eagerness leads to mistakes. Magic demands patience.",
        },
        location = {
          context = "world",
          zoneChain = { "Kalimdor", "Dalaran" },
          zoneText = "Kalimdor > Dalaran",
        },
    },
  }
end

function Examples:Seed()
  if not Core then return end
  local db = Core:GetDB()
  if next(db.books) ~= nil then
    return
  end

  for _, entry in ipairs(buildExamples()) do
    Core:InjectEntry(entry, { append = true })
  end

  if print then
    print("|cFF00FF00BookArchivist:|r Added 3 example books for demonstration")
  end
end

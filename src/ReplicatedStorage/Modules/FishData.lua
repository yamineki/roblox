-- ReplicatedStorage/Modules/FishData.lua
-- Reef Diver — Данные всех рыб (MVP: 20 видов, 4 на зону)
-- Image = "" — плейсхолдер, заменить на Asset ID позже

local FishData = {}

FishData.Fish = {

    -- ══ ЗОНА 1: SUNNY REEF (0–100 м) ══
    Clownfish = {
        id          = "Clownfish",
        displayName = "Clownfish",
        zone        = "SunnyReef",
        rarity      = "Common",
        behavior    = "Lazy",
        basePrice   = 10,
        description = "Яркая оранжевая рыбка, любит кораллы.",
        -- PLACEHOLDER: заменить на реальный Roblox Asset ID
        image       = "",       -- rbxassetid://XXXXX
        size        = {1, 1, 1} -- Vector3 заглушка для модели
    },

    Tang = {
        id          = "Tang",
        displayName = "Tang",
        zone        = "SunnyReef",
        rarity      = "Common",
        behavior    = "Smooth",
        basePrice   = 15,
        description = "Синяя рыба-хирург, быстро плавает.",
        image       = "",
        size        = {1.2, 1, 0.8}
    },

    Butterflyfish = {
        id          = "Butterflyfish",
        displayName = "Butterflyfish",
        zone        = "SunnyReef",
        rarity      = "Uncommon",
        behavior    = "Floater",
        basePrice   = 35,
        description = "Элегантная полосатая рыба.",
        image       = "",
        size        = {1, 0.8, 0.5}
    },

    Triggerfish = {
        id          = "Triggerfish",
        displayName = "Triggerfish",
        zone        = "SunnyReef",
        rarity      = "Rare",
        behavior    = "Dart",
        basePrice   = 80,
        description = "Агрессивная рыба с острым шипом.",
        image       = "",
        size        = {1.5, 1.2, 0.9}
    },

    -- ══ ЗОНА 2: CORAL TRENCH (100–300 м) ══
    Lionfish = {
        id          = "Lionfish",
        displayName = "Lionfish",
        zone        = "CoralTrench",
        rarity      = "Uncommon",
        behavior    = "Smooth",
        basePrice   = 60,
        description = "Ядовитые плавники, величественный вид.",
        image       = "",
        size        = {1.8, 1.5, 1.2}
    },

    MorayEel = {
        id          = "MorayEel",
        displayName = "Moray Eel",
        zone        = "CoralTrench",
        rarity      = "Rare",
        behavior    = "Sinker",
        basePrice   = 120,
        description = "Угорь с острыми зубами, скрывается в расщелинах.",
        image       = "",
        size        = {4, 0.5, 0.5}
    },

    Pufferfish = {
        id          = "Pufferfish",
        displayName = "Pufferfish",
        zone        = "CoralTrench",
        rarity      = "Rare",
        behavior    = "Floater",
        basePrice   = 150,
        description = "Надувается при опасности.",
        image       = "",
        size        = {1.5, 1.5, 1.5}
    },

    Barracuda = {
        id          = "Barracuda",
        displayName = "Barracuda",
        zone        = "CoralTrench",
        rarity      = "Epic",
        behavior    = "Dart",
        basePrice   = 300,
        description = "Молниеносный хищник с острыми зубами.",
        image       = "",
        size        = {5, 0.8, 0.8}
    },

    -- ══ ЗОНА 3: OPEN OCEAN (300–700 м) ══
    Tuna = {
        id          = "Tuna",
        displayName = "Tuna",
        zone        = "OpenOcean",
        rarity      = "Rare",
        behavior    = "Smooth",
        basePrice   = 200,
        description = "Мощная стремительная рыба открытого океана.",
        image       = "",
        size        = {3, 1.2, 1}
    },

    Swordfish = {
        id          = "Swordfish",
        displayName = "Swordfish",
        zone        = "OpenOcean",
        rarity      = "Epic",
        behavior    = "Dart",
        basePrice   = 500,
        description = "Рыба-меч, самая быстрая в океане.",
        image       = "",
        size        = {5, 1, 0.8}
    },

    MahiMahi = {
        id          = "MahiMahi",
        displayName = "Mahi-Mahi",
        zone        = "OpenOcean",
        rarity      = "Epic",
        behavior    = "Dart",
        basePrice   = 450,
        description = "Яркая золотисто-синяя рыба.",
        image       = "",
        size        = {2.5, 1.2, 1}
    },

    Hammerhead = {
        id          = "Hammerhead",
        displayName = "Hammerhead Shark",
        zone        = "OpenOcean",
        rarity      = "Legendary",
        behavior    = "Sinker",
        basePrice   = 1200,
        description = "Акула-молот с уникальной формой головы.",
        image       = "",
        size        = {6, 2, 1.5}
    },

    -- ══ ЗОНА 4: DARK WATERS (700–1500 м) ══
    Anglerfish = {
        id          = "Anglerfish",
        displayName = "Anglerfish",
        zone        = "DarkWaters",
        rarity      = "Legendary",
        behavior    = "Sinker",
        basePrice   = 2000,
        description = "Глубоководная рыба с биолюминесцентной приманкой.",
        image       = "",
        size        = {2, 2, 1.8}
    },

    Dragonfish = {
        id          = "Dragonfish",
        displayName = "Dragonfish",
        zone        = "DarkWaters",
        rarity      = "Legendary",
        behavior    = "Dart",
        basePrice   = 2500,
        description = "Глубоководный хищник с острыми клыками.",
        image       = "",
        size        = {3, 0.8, 0.8}
    },

    GulperEel = {
        id          = "GulperEel",
        displayName = "Gulper Eel",
        zone        = "DarkWaters",
        rarity      = "Mythic",
        behavior    = "Chaos",
        basePrice   = 5000,
        description = "Огромная пасть, способная проглотить добычу больше себя.",
        image       = "",
        size        = {6, 1, 1}
    },

    GiantSquid = {
        id          = "GiantSquid",
        displayName = "Giant Squid",
        zone        = "DarkWaters",
        rarity      = "Mythic",
        behavior    = "Chaos",
        basePrice   = 8000,
        description = "Легендарный кракен из морских сказаний.",
        image       = "",
        size        = {8, 4, 4}
    },

    -- ══ ЗОНА 5: ABYSS (1500–3000 м) ══
    VoidSerpent = {
        id          = "VoidSerpent",
        displayName = "Void Serpent",
        zone        = "Abyss",
        rarity      = "Mythic",
        behavior    = "Chaos",
        basePrice   = 15000,
        description = "Бесконечный змей из пустоты.",
        image       = "",
        size        = {15, 1.5, 1.5}
    },

    AbyssWhale = {
        id          = "AbyssWhale",
        displayName = "Abyss Whale",
        zone        = "Abyss",
        rarity      = "Mythic",
        behavior    = "Sinker",
        basePrice   = 20000,
        description = "Гигантский кит бездны, медленно дрейфующий в темноте.",
        image       = "",
        size        = {20, 8, 6}
    },

    KrakenSpawn = {
        id          = "KrakenSpawn",
        displayName = "Kraken Spawn",
        zone        = "Abyss",
        rarity      = "Secret",
        behavior    = "Chaos",
        basePrice   = 50000,
        description = "Потомок древнего Кракена. Почти не встречается.",
        image       = "",
        size        = {10, 6, 6}
    },

    Leviathan = {
        id          = "Leviathan",
        displayName = "Leviathan",
        zone        = "Abyss",
        rarity      = "Secret",
        behavior    = "Chaos",
        basePrice   = 100000,
        description = "Существо из конца времён. Поймать его — легенда сервера.",
        image       = "",
        size        = {30, 10, 10}
    },
}

-- Вспомогательная функция: вернуть список рыб по зоне
function FishData:GetFishInZone(zoneName)
    local result = {}
    for _, fish in pairs(self.Fish) do
        if fish.zone == zoneName then
            table.insert(result, fish)
        end
    end
    return result
end

-- Вспомогательная функция: вернуть рыбу по ID
function FishData:GetFish(fishId)
    return self.Fish[fishId]
end

return FishData

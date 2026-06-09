-- ReplicatedStorage/Modules/RodData.lua
-- Reef Diver — Данные всех удочек (MVP: 10 удочек)
-- Image = "" — плейсхолдер, заменить на Asset ID позже

local RodData = {}

RodData.Rods = {

    WoodenRod = {
        id              = "WoodenRod",
        displayName     = "Wooden Rod",
        icon            = "",           -- rbxassetid://XXXXX (PLACEHOLDER)
        price           = 0,            -- стартовая бесплатно
        description     = "Базовая удочка. Нет бонусов.",
        specialization  = "Стартовая",
        -- Бонусы (0 = без изменений)
        greenZoneBonus      = 0,
        rarityBonus         = 0,
        sizeBonus           = 0,
        catchRateBonus      = 0,
        mutationChanceBonus = 0,
        crossZone           = false,
        -- Зоны, доступные с этой удочкой
        allowedZones    = { "SunnyReef" },
    },

    FisherRod = {
        id              = "FisherRod",
        displayName     = "Fisher Rod",
        icon            = "",           -- PLACEHOLDER
        price           = 500,
        description     = "Увеличенная зелёная зона — легче ловить.",
        specialization  = "Размер зоны",
        greenZoneBonus      = 0.10,     -- +10%
        rarityBonus         = 0,
        sizeBonus           = 0,
        catchRateBonus      = 0,
        mutationChanceBonus = 0,
        crossZone           = false,
        allowedZones    = { "SunnyReef", "CoralTrench" },
    },

    CoralRod = {
        id              = "CoralRod",
        displayName     = "Coral Rod",
        icon            = "",           -- PLACEHOLDER
        price           = 1500,
        description     = "Значительно увеличенная зелёная зона.",
        specialization  = "Размер зоны (улучшенный)",
        greenZoneBonus      = 0.20,     -- +20%
        rarityBonus         = 0,
        sizeBonus           = 0,
        catchRateBonus      = 0,
        mutationChanceBonus = 0,
        crossZone           = false,
        allowedZones    = { "SunnyReef", "CoralTrench", "OpenOcean" },
    },

    HunterRod = {
        id              = "HunterRod",
        displayName     = "Hunter Rod",
        icon            = "",           -- PLACEHOLDER
        price           = 3000,
        description     = "Повышает шанс поимки редких рыб.",
        specialization  = "Редкость рыбы",
        greenZoneBonus      = 0,
        rarityBonus         = 0.10,     -- +10% к весу редких
        sizeBonus           = 0,
        catchRateBonus      = 0,
        mutationChanceBonus = 0,
        crossZone           = false,
        allowedZones    = { "SunnyReef", "CoralTrench", "OpenOcean" },
    },

    SharkRod = {
        id              = "SharkRod",
        displayName     = "Shark Rod",
        icon            = "",           -- PLACEHOLDER
        price           = 5000,
        description     = "Притягивает крупных особей.",
        specialization  = "Размер рыбы",
        greenZoneBonus      = 0,
        rarityBonus         = 0,
        sizeBonus           = 0.15,     -- +15% шанс крупного размера
        catchRateBonus      = 0,
        mutationChanceBonus = 0,
        crossZone           = false,
        allowedZones    = { "SunnyReef", "CoralTrench", "OpenOcean" },
    },

    DeepRod = {
        id              = "DeepRod",
        displayName     = "Deep Rod",
        icon            = "",           -- PLACEHOLDER
        price           = 8000,
        description     = "Открывает доступ к тёмным глубинам.",
        specialization  = "Доступ к глубинам",
        greenZoneBonus      = 0,
        rarityBonus         = 0,
        sizeBonus           = 0,
        catchRateBonus      = 0,
        mutationChanceBonus = 0,
        crossZone           = false,
        allowedZones    = { "SunnyReef", "CoralTrench", "OpenOcean", "DarkWaters" },
    },

    StormRod = {
        id              = "StormRod",
        displayName     = "Storm Rod",
        icon            = "",           -- PLACEHOLDER
        price           = 15000,
        description     = "Притягивает мутации как гроза.",
        specialization  = "Мутации",
        greenZoneBonus      = 0,
        rarityBonus         = 0,
        sizeBonus           = 0,
        catchRateBonus      = 0,
        mutationChanceBonus = 0.10,     -- +10% шанс мутации
        crossZone           = false,
        allowedZones    = { "SunnyReef", "CoralTrench", "OpenOcean", "DarkWaters" },
    },

    AbyssRod = {
        id              = "AbyssRod",
        displayName     = "Abyss Rod",
        icon            = "",           -- PLACEHOLDER
        price           = 25000,
        description     = "Ускоренная ловля — рыба не успевает убежать.",
        specialization  = "Скорость поимки",
        greenZoneBonus      = 0,
        rarityBonus         = 0,
        sizeBonus           = 0,
        catchRateBonus      = 0.25,     -- +25% CatchRate
        mutationChanceBonus = 0,
        crossZone           = false,
        allowedZones    = { "SunnyReef", "CoralTrench", "OpenOcean", "DarkWaters", "Abyss" },
    },

    VoidRod = {
        id              = "VoidRod",
        displayName     = "Void Rod",
        icon            = "",           -- PLACEHOLDER
        price           = 50000,
        description     = "Может поймать рыбу из следующей зоны глубины.",
        specialization  = "Зональный кросс-спавн",
        greenZoneBonus      = 0,
        rarityBonus         = 0,
        sizeBonus           = 0,
        catchRateBonus      = 0,
        mutationChanceBonus = 0,
        crossZone           = true,     -- УНИКАЛЬНАЯ МЕХАНИКА
        crossZoneChance     = 0.15,     -- 15% шанс рыбы из следующей зоны
        allowedZones    = { "SunnyReef", "CoralTrench", "OpenOcean", "DarkWaters", "Abyss" },
    },

    LeviathanRod = {
        id              = "LeviathanRod",
        displayName     = "Leviathan Rod",
        icon            = "",           -- PLACEHOLDER
        price           = 200000,
        description     = "Легендарная удочка эндгейма. Бонусы во всём.",
        specialization  = "Универсальный эндгейм",
        greenZoneBonus      = 0.20,     -- +20%
        rarityBonus         = 0.10,     -- +10%
        sizeBonus           = 0,
        catchRateBonus      = 0.10,     -- +10%
        mutationChanceBonus = 0.10,     -- +10%
        crossZone           = false,
        allowedZones    = { "SunnyReef", "CoralTrench", "OpenOcean", "DarkWaters", "Abyss" },
    },
}

-- Порядок для отображения в магазине (Rod Master)
RodData.ShopOrder = {
    "WoodenRod", "FisherRod", "CoralRod", "HunterRod", "SharkRod",
    "DeepRod", "StormRod", "AbyssRod", "VoidRod", "LeviathanRod"
}

-- Вспомогательные функции
function RodData:GetRod(rodId)
    return self.Rods[rodId]
end

function RodData:GetStarterRod()
    return self.Rods["WoodenRod"]
end

return RodData

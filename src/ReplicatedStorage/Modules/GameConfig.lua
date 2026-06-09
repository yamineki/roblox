-- ReplicatedStorage/Modules/GameConfig.lua
-- Reef Diver — Все числовые константы игры
-- Изменяй здесь, изменения применяются везде

local GameConfig = {}

-- ══ МИНИ-ИГРА РЫБАЛКИ ══
GameConfig.Fishing = {
    ScaleHeight      = 400,      -- высота вертикальной шкалы (px, визуально)
    CatchRate        = 12,       -- очки/сек когда рыба внутри зоны
    EscapeRate       = 18,       -- очки/сек когда рыба вне зоны
    MaxProgress      = 100,
    MinProgress      = 0,

    -- Stress Meter
    StressStartDelay = 5,        -- секунды до начала Stress Meter
    StressInterval   = 10,       -- каждые N секунд
    StressSpeedBonus = 0.10,     -- +10% скорость рыбы

    -- Hook Phase
    HookArrowBaseSpeed  = 90,    -- градусов/сек базовая скорость стрелки
    HookZoneAngle       = 75,    -- ширина зелёной зоны в градусах
    HookPerfectWindow   = 15,    -- окно Perfect внутри зелёной зоны (центр ±7.5°)

    -- Perfect Hook бонусы
    PerfectHookValueBonus    = 0.10,  -- +10% стоимость
    PerfectHookMutationBonus = 0.05,  -- +5% шанс мутации

    -- Perfect Catch бонусы
    PerfectCatchValueBonus = 0.25,    -- +25% стоимость
    PerfectCatchXPBonus    = 0.15,    -- +15% опыт
}

-- ══ ЗЕЛЁНАЯ ЗОНА (физика) ══
GameConfig.GreenZone = {
    Height          = 80,        -- высота зоны (px)
    Acceleration    = 600,       -- ускорение вверх при удержании кнопки (px/s²)
    Gravity         = 400,       -- гравитация вниз при отпускании (px/s²)
    MaxSpeed        = 500,       -- максимальная скорость зоны
}

-- ══ ПОВЕДЕНИЕ РЫБ ══
-- Параметры поведения рыбы в мини-игре (Catching Phase)
-- speed        = базовая скорость движения по шкале (px/сек)
-- dirCooldown  = как часто рыба может менять направление (сек; меньше = непредсказуемее)
-- jumpChance   = шанс резкого рывка при смене направления
-- jumpDistance = насколько далеко прыгает (px)
-- accel        = плавность ускорения (выше = резче дёргается)
-- gravityBias  = тяга вниз (Sinker тонет)
GameConfig.FishBehavior = {
    Lazy    = { speed = 60,  dirCooldown = 2.5, jumpChance = 0.00, jumpDistance = 0,   accel = 2.5, gravityBias = 0   },
    Smooth  = { speed = 110, dirCooldown = 1.8, jumpChance = 0.05, jumpDistance = 30,  accel = 3.5, gravityBias = 0   },
    Floater = { speed = 90,  dirCooldown = 1.2, jumpChance = 0.15, jumpDistance = 50,  accel = 4.0, gravityBias = -0.3},
    Sinker  = { speed = 100, dirCooldown = 1.4, jumpChance = 0.00, jumpDistance = 0,   accel = 3.0, gravityBias = 0.4 },
    Dart    = { speed = 200, dirCooldown = 0.6, jumpChance = 0.25, jumpDistance = 80,  accel = 6.0, gravityBias = 0   },
    Chaos   = { speed = 260, dirCooldown = 0.35,jumpChance = 0.40, jumpDistance = 120, accel = 8.0, gravityBias = 0   },
}

-- ══ СИСТЕМА РАЗМЕРОВ ══
GameConfig.Sizes = {
    Tiny      = { mult = 0.50,  weight = 25 },
    Small     = { mult = 0.75,  weight = 22 },
    Normal    = { mult = 1.00,  weight = 20 },
    Large     = { mult = 1.50,  weight = 14 },
    Huge      = { mult = 2.00,  weight = 9  },
    Giant     = { mult = 3.00,  weight = 5  },
    Titanic   = { mult = 5.00,  weight = 3  },
    Colossal  = { mult = 8.00,  weight = 1.5},
    Leviathan = { mult = 15.00, weight = 0.5},
}

-- ══ РЕДКОСТЬ РЫБ ══
GameConfig.Rarity = {
    Common    = { weight = 45,  colorHex = "#aaaaaa", hookSpeedMult = 1.0 },
    Uncommon  = { weight = 25,  colorHex = "#44cc66", hookSpeedMult = 1.1 },
    Rare      = { weight = 15,  colorHex = "#5599ff", hookSpeedMult = 1.3 },
    Epic      = { weight = 8,   colorHex = "#aa66ff", hookSpeedMult = 1.5 },
    Legendary = { weight = 4,   colorHex = "#ffcc44", hookSpeedMult = 1.8 },
    Mythic    = { weight = 2,   colorHex = "#ff6655", hookSpeedMult = 2.2 },
    Secret    = { weight = 1,   colorHex = "#ff44cc", hookSpeedMult = 2.8 },
    -- Divine: зарезервировано для будущих обновлений
}

-- ══ МУТАЦИИ ══
GameConfig.Mutations = {
    -- name = { valueMult, rarityThreshold (min rarity для триггера объявления) }
    Golden          = { valueMult = 3.0,  announceOnServer = false },
    Frozen          = { valueMult = 2.0,  announceOnServer = false },
    Crystal         = { valueMult = 2.5,  announceOnServer = false },
    Shadow          = { valueMult = 3.5,  announceOnServer = false },
    Toxic           = { valueMult = 2.0,  announceOnServer = false },
    Infernal        = { valueMult = 3.0,  announceOnServer = false },
    Lunar           = { valueMult = 2.5,  announceOnServer = false },
    Solar           = { valueMult = 2.5,  announceOnServer = false },
    Cosmic          = { valueMult = 4.0,  announceOnServer = false },
    Prismatic       = { valueMult = 8.0,  announceOnServer = true  }, -- тригер объявления
    Ancient         = { valueMult = 5.0,  announceOnServer = false },
    Primordial      = { valueMult = 6.0,  announceOnServer = false },
    LeviathanTouched= { valueMult = 10.0, announceOnServer = true  }, -- тригер объявления
}

-- Базовый шанс мутации без удочки
GameConfig.BaseMutationChance = 0.03  -- 3%

-- ══ AFK ЭКСПЕДИЦИИ ══
GameConfig.Expeditions = {
    Short  = { duration = 3600,   coinMult = 1,  fishMin = 2, fishMax = 4,  maxRarity = "Common", mutationChance = 0,    label = "1 час"  },
    Medium = { duration = 14400,  coinMult = 3,  fishMin = 4, fishMax = 8,  maxRarity = "Rare",   mutationChance = 0.05, label = "4 часа" },
    Long   = { duration = 28800,  coinMult = 8,  fishMin = 6, fishMax = 12, maxRarity = "Epic",   mutationChance = 0.15, label = "8 часов"},
}

-- ══ СОБЫТИЯ ══
GameConfig.Events = {
    MutationSwarm     = { durationSecs = 300,  mutationChanceMult = 3.0,  interval = {600, 1200} },
    GoldenTide        = { durationSecs = 180,  forceMutation = "Golden",  interval = {600, 1200} },
    BloodMoon         = { durationSecs = 600,  exclusiveFish = true,      interval = {600, 1200} },
    LeviathanMigration= { durationSecs = 180,  leviathanTouchedBonus=true,interval = {600, 1200} },
}

-- ══ СЕРВЕРНЫЕ ОБЪЯВЛЕНИЯ ══
GameConfig.Announcements = {
    PlayerCooldown  = 30,   -- секунд до следующего объявления от того же игрока
    DisplayTime     = 5,    -- секунд показа баннера
    HallOfFameSize  = 10,   -- топ-N в зале славы
}

-- ══ DAILY REWARDS ══
GameConfig.DailyRewards = {
    [1] = { type = "Coins",         amount = 500 },
    [2] = { type = "LuckBoost",     duration = 1800, mult = 1.5 },
    [3] = { type = "MutationBoost", duration = 1800, mult = 2.0 },
    [4] = { type = "AFKTicket",     amount = 1 },
    [5] = { type = "MutationChest", amount = 3 },
    [6] = { type = "RareFishChest", minRarity = "Rare" },
    [7] = { type = "ExclusiveMutation", pool = "DailyOnly" },
}

-- ══ REBIRTH ══
GameConfig.Rebirth = {
    [1]  = { reward = "ExtraAFKSlot",       description = "Вторая AFK-экспедиция одновременно" },
    [2]  = { reward = "DoubleCatchChance",  description = "Шанс двойного улова" },
    [3]  = { reward = "MythicMutationPool", description = "Доступ к Mythic Mutation Pool" },
    [4]  = { reward = "ExtraCollectSlot",   description = "Дополнительный слот коллекции" },
    [5]  = { reward = "CharacterAura",      description = "Уникальная Aura вокруг персонажа" },
    [6]  = { reward = "TreasureFish",       description = "Treasure Fish — особый вид рыб с бонусами" },
    [7]  = { reward = "ChatColor",          description = "Уникальный цвет ника в чате" },
    [8]  = { reward = "BonusDailyWheel",    description = "Дополнительное ежедневное колесо фортуны" },
    [9]  = { reward = "SwimTrail",          description = "Визуальный след при плавании" },
    [10] = { reward = "GoldenDiverTitle",   description = "Титул Golden Diver + особый badge" },
}

-- ══ PRESTIGE: МНОЖИТЕЛЬ МОНЕТ ОТ REBIRTH ══
-- Итоговый множитель = 1 + rebirthLevel * RebirthCoinMultPerLevel
GameConfig.RebirthCoinMultPerLevel = 0.5   -- +50% монет за каждый уровень rebirth

-- Стоимость следующего перерождения (монеты). nextLevel = текущий+1
-- Fast Rebirth геймпасс уменьшает это на свой процент.
GameConfig.RebirthBaseCost = 50000     -- база для 1-го rebirth
GameConfig.RebirthCostGrowth = 4       -- ×4 за каждый следующий уровень
function GameConfig.GetRebirthCost(nextLevel)
    return math.floor(GameConfig.RebirthBaseCost * (GameConfig.RebirthCostGrowth ^ (nextLevel - 1)))
end

-- ══ PERFECT CATCH COMBO ══
-- Серия Perfect Catch подряд даёт растущий множитель монет
GameConfig.PerfectCombo = {
    bonusPerStreak = 0.10,   -- +10% за каждый Perfect в серии
    maxMultiplier  = 2.0,    -- максимум ×2 (т.е. до +100%)
    resetOnMiss    = true,   -- сброс при не-Perfect улове или промахе
    resetSeconds   = 30,     -- серия сбрасывается если долго не ловил
}

-- ══ ЗОНЫ: ТЕЛЕПОРТ ЗА МОНЕТЫ (NPC у щели) ══
-- unlockCost = единоразовая плата за разблокировку зоны (0 = бесплатно)
-- minRebirth = минимальный rebirth для доступа (0 = без требований)
-- depthLabel = подпись глубины для UI
GameConfig.Zones = {
    SunnyReef   = { order = 1, unlockCost = 0,      minRebirth = 0, depthLabel = "0 – 100 м"     },
    CoralTrench = { order = 2, unlockCost = 1000,   minRebirth = 0, depthLabel = "100 – 300 м"   },
    OpenOcean   = { order = 3, unlockCost = 5000,   minRebirth = 0, depthLabel = "300 – 700 м"   },
    DarkWaters  = { order = 4, unlockCost = 25000,  minRebirth = 0, depthLabel = "700 – 1500 м"  },
    Abyss       = { order = 5, unlockCost = 100000, minRebirth = 1, depthLabel = "1500 – 3000 м" },
}
GameConfig.ZoneOrder = { "SunnyReef", "CoralTrench", "OpenOcean", "DarkWaters", "Abyss" }

-- ══ СУНДУКИ КОЛЛЕКЦИИ (FishDex completion) ══
-- За поимку ВСЕХ видов зоны — единоразовая награда
GameConfig.CollectionRewards = {
    SunnyReef   = { coins = 2500,   rodReward = nil,            title = "Reef Explorer"   },
    CoralTrench = { coins = 10000,  rodReward = nil,            title = "Trench Diver"    },
    OpenOcean   = { coins = 40000,  rodReward = nil,            title = "Ocean Master"    },
    DarkWaters  = { coins = 150000, rodReward = nil,            title = "Abyss Walker"    },
    Abyss       = { coins = 500000, rodReward = "LeviathanRod", title = "Leviathan Hunter"},
}

return GameConfig

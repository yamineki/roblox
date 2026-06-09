-- ServerScriptService/Services/DataService.lua
-- Reef Diver — Сохранение и загрузка данных игроков через DataStore

local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local DataService = {}

-- DataStore ключи
-- В Studio без публикации DataStore недоступен — используем in-memory заглушку
local IS_STUDIO = RunService:IsStudio()

local function makeMockStore()
    local store = {}
    local cache = {}
    function store:GetAsync(key) return cache[key] end
    function store:SetAsync(key, val) cache[key] = val end
    function store:UpdateAsync(key, fn)
        local newVal = fn(cache[key])
        if newVal ~= nil then cache[key] = newVal end
        return cache[key]
    end
    return store
end

local PLAYER_DATA_STORE, HALL_OF_FAME_STORE
do
    local ok, ds = pcall(function()
        return DataStoreService:GetDataStore("ReefDiver_PlayerData_v1")
    end)
    PLAYER_DATA_STORE = ok and ds or makeMockStore()

    local ok2, hs = pcall(function()
        return DataStoreService:GetDataStore("ReefDiver_HallOfFame_v1")
    end)
    HALL_OF_FAME_STORE = ok2 and hs or makeMockStore()

    if IS_STUDIO and not ok then
        warn("[DataService] Studio: DataStore недоступен, используется in-memory заглушка")
    end
end

-- Кэш данных в памяти (userId → data)
local playerCache = {}

-- ══ СТРУКТУРА ДАННЫХ ИГРОКА ══
local function getDefaultData()
    return {
        -- Экономика
        coins       = 0,

        -- Удочки
        ownedRods   = { "WoodenRod" },
        equippedRod = "WoodenRod",

        -- Инвентарь рыб { fishId, rarity, size, mutation, value }[]
        fishInventory = {},

        -- FishDex — какие рыбы поймал { fishId → { count, bestSize, hasMutation } }
        fishDex = {},

        -- AFK экспедиции
        expeditions = {
            -- { slot=1, startTime=os.time(), durationType="Short", active=false }
        },

        -- Rebirth
        rebirthLevel = 0,
        rebirthBonuses = {},

        -- Daily Rewards
        lastDailyClaim  = 0,    -- os.time() последнего получения
        dailyStreak     = 0,    -- текущая серия дней

        -- Статистика (для FishDex и Hall of Fame)
        stats = {
            totalFishCaught     = 0,
            totalMythicCaught   = 0,
            totalSecretCaught   = 0,
            totalPrismaticCaught= 0,
            bestFishValue       = 0,
        },

        -- Активные бусты
        activeBoosts = {},

        -- Разблокированные зоны (SunnyReef всегда открыта)
        unlockedZones = { SunnyReef = true },
        currentZone   = "SunnyReef",

        -- Perfect Catch combo
        perfectStreak    = 0,
        lastPerfectAt    = 0,

        -- Полученные награды за коллекцию зон { zoneName = true }
        collectionClaimed = {},

        -- Полученные титулы
        titles      = {},

        -- Монетизация
        rebirthTokens   = 0,
        autoSellEnabled = true,        -- если есть геймпасс AutoSell
        purchaseHistory = {},          -- идемпотентность dev products
        lastVipBonusDay = 0,

        -- Метаданные
        createdAt   = os.time(),
        lastSeen    = os.time(),
        version     = 2,
    }
end

-- ══ ЗАГРУЗКА ══
function DataService:LoadPlayer(player)
    local userId = tostring(player.UserId)
    local success, data = pcall(function()
        return PLAYER_DATA_STORE:GetAsync(userId)
    end)

    if success and data then
        -- Миграция: добавить новые поля если данные старые
        local defaults = getDefaultData()
        for key, val in pairs(defaults) do
            if data[key] == nil then
                data[key] = val
            end
        end
        playerCache[userId] = data
    else
        -- Новый игрок
        playerCache[userId] = getDefaultData()
        if not success then
            warn("[DataService] Ошибка загрузки данных:", userId, data)
        end
    end

    playerCache[userId].lastSeen = os.time()
    return playerCache[userId]
end

-- ══ СОХРАНЕНИЕ ══
function DataService:SavePlayer(player)
    local userId = tostring(player.UserId)
    local data = playerCache[userId]
    if not data then return end

    data.lastSeen = os.time()

    local success, err = pcall(function()
        PLAYER_DATA_STORE:SetAsync(userId, data)
    end)

    if not success then
        warn("[DataService] Ошибка сохранения:", userId, err)
    end
end

-- ══ ПОЛУЧИТЬ ДАННЫЕ (быстро из кэша) ══
function DataService:Get(player)
    return playerCache[tostring(player.UserId)]
end

-- ══ ОБНОВИТЬ ПОЛЕ ══
function DataService:Set(player, path, value)
    local data = self:Get(player)
    if not data then return end
    -- path = "coins" или "stats.totalFishCaught"
    local parts = path:split(".")
    local t = data
    for i = 1, #parts - 1 do
        t = t[parts[i]]
        if not t then return end
    end
    t[parts[#parts]] = value
end

-- ══ ДОБАВИТЬ МОНЕТЫ ══
function DataService:AddCoins(player, amount)
    local data = self:Get(player)
    if not data then return end
    data.coins = math.max(0, data.coins + amount)
    return data.coins
end

-- ══ ДОБАВИТЬ РЫБУ В ИНВЕНТАРЬ ══
function DataService:AddFishToInventory(player, fishEntry)
    -- fishEntry = { id, displayName, rarity, size, mutation, value }
    local data = self:Get(player)
    if not data then return end
    table.insert(data.fishInventory, fishEntry)

    -- Обновить FishDex
    local dex = data.fishDex
    if not dex[fishEntry.id] then
        dex[fishEntry.id] = { count = 0, bestSizeMult = 0, hasMutation = false }
    end
    local entry = dex[fishEntry.id]
    entry.count = entry.count + 1
    if fishEntry.mutation and fishEntry.mutation ~= "" then
        entry.hasMutation = true
    end
    -- Лучший пойманный размер (по множителю)
    local sm = fishEntry.sizeMult or 1
    if sm > (entry.bestSizeMult or 0) then
        entry.bestSizeMult = sm
        entry.bestSize = fishEntry.size
    end

    -- Обновить статистику
    data.stats.totalFishCaught = data.stats.totalFishCaught + 1
    if fishEntry.value > data.stats.bestFishValue then
        data.stats.bestFishValue = fishEntry.value
    end
    if fishEntry.rarity == "Mythic" then
        data.stats.totalMythicCaught = data.stats.totalMythicCaught + 1
    end
    if fishEntry.rarity == "Secret" then
        data.stats.totalSecretCaught = data.stats.totalSecretCaught + 1
    end
    if fishEntry.mutation == "Prismatic" then
        data.stats.totalPrismaticCaught = data.stats.totalPrismaticCaught + 1
    end
end

-- ══ ПРОДАТЬ РЫБУ ══
function DataService:SellFish(player, fishIndex)
    local data = self:Get(player)
    if not data then return 0 end
    local fish = data.fishInventory[fishIndex]
    if not fish then return 0 end
    table.remove(data.fishInventory, fishIndex)
    self:AddCoins(player, fish.value)
    return fish.value
end

-- ══ ПРОДАТЬ ВСЁ ══
function DataService:SellAll(player)
    local data = self:Get(player)
    if not data then return 0 end
    local total = 0
    for _, fish in ipairs(data.fishInventory) do
        total = total + fish.value
    end
    data.fishInventory = {}
    self:AddCoins(player, total)
    return total
end

-- ══ КУПИТЬ УДОЧКУ ══
function DataService:BuyRod(player, rodId, price)
    local data = self:Get(player)
    if not data then return false, "no_data" end
    if data.coins < price then return false, "not_enough_coins" end

    for _, owned in ipairs(data.ownedRods) do
        if owned == rodId then return false, "already_owned" end
    end

    data.coins = data.coins - price
    table.insert(data.ownedRods, rodId)
    return true, "success"
end

-- ══ ПЕРЕРОЖДЕНИЕ ══
function DataService:DoRebirth(player, rebirthDiscount)
    local data = self:Get(player)
    if not data then return false, "no_data" end
    if data.rebirthLevel >= 10 then return false, "max_level" end

    local newLevel = data.rebirthLevel + 1

    -- Проверить стоимость (с учётом Fast Rebirth скидки)
    local cost = GameConfig.GetRebirthCost(newLevel)
    local discount = rebirthDiscount or 0
    cost = math.floor(cost * (1 - discount))

    -- Rebirth Token может пропустить требование монет
    local usedToken = false
    if data.coins < cost then
        if (data.rebirthTokens or 0) > 0 then
            data.rebirthTokens = data.rebirthTokens - 1
            usedToken = true
        else
            return false, "not_enough_coins"
        end
    end

    if not usedToken then
        data.coins = data.coins - cost
    end

    -- Применить постоянный бонус нового уровня
    data.rebirthLevel = newLevel

    -- Сброс прогресса: рыба, удочки (монеты уже списаны на стоимость)
    data.coins = 0
    data.fishInventory = {}
    data.ownedRods = { "WoodenRod" }
    data.equippedRod = "WoodenRod"

    -- Запомнить полученные награды rebirth (накапливаются)
    data.rebirthBonuses = data.rebirthBonuses or {}
    local rewardInfo = GameConfig.Rebirth and GameConfig.Rebirth[newLevel]
    if rewardInfo then
        data.rebirthBonuses[rewardInfo.reward] = true
    end

    return true, "success"
end

-- ══ PERFECT CATCH COMBO ══

-- Обновить серию и вернуть текущий combo-множитель ПЕРЕД засчётом улова
function DataService:UpdatePerfectCombo(player, isPerfectCatch)
    local data = self:Get(player)
    if not data then return 1 end

    local cfg = GameConfig.PerfectCombo
    local now = os.time()

    -- Сброс серии если давно не ловил
    if data.lastPerfectAt and (now - data.lastPerfectAt) > cfg.resetSeconds then
        data.perfectStreak = 0
    end

    if isPerfectCatch then
        data.perfectStreak = (data.perfectStreak or 0) + 1
        data.lastPerfectAt = now
    elseif cfg.resetOnMiss then
        data.perfectStreak = 0
    end

    -- Множитель: 1 + (streak-1)*bonus, capped
    local streak = data.perfectStreak or 0
    local mult = 1
    if streak > 1 then
        mult = 1 + (streak - 1) * cfg.bonusPerStreak
        mult = math.min(mult, cfg.maxMultiplier)
    end
    return mult, streak
end

-- ══ РАЗБЛОКИРОВКА ЗОН ══
function DataService:IsZoneUnlocked(player, zoneName)
    local data = self:Get(player)
    if not data then return false end
    data.unlockedZones = data.unlockedZones or { SunnyReef = true }
    return data.unlockedZones[zoneName] == true
end

-- Возвращает: success, reason
function DataService:UnlockZone(player, zoneName)
    local data = self:Get(player)
    if not data then return false, "no_data" end

    local zoneCfg = GameConfig.Zones[zoneName]
    if not zoneCfg then return false, "invalid_zone" end

    data.unlockedZones = data.unlockedZones or { SunnyReef = true }
    if data.unlockedZones[zoneName] then return false, "already_unlocked" end

    -- Проверка rebirth
    if (data.rebirthLevel or 0) < (zoneCfg.minRebirth or 0) then
        return false, "rebirth_required"
    end

    -- Проверка монет
    if data.coins < (zoneCfg.unlockCost or 0) then
        return false, "not_enough_coins"
    end

    data.coins = data.coins - (zoneCfg.unlockCost or 0)
    data.unlockedZones[zoneName] = true
    return true, "success"
end

-- Сменить текущую зону (только если разблокирована)
function DataService:SetCurrentZone(player, zoneName)
    local data = self:Get(player)
    if not data then return false end
    if not self:IsZoneUnlocked(player, zoneName) then return false end
    data.currentZone = zoneName
    return true
end

-- ══ ПРОВЕРКА КОЛЛЕКЦИИ ЗОНЫ ══
-- Возвращает: claimed (bool), reward (table|nil)
function DataService:CheckCollectionComplete(player, zoneName)
    local data = self:Get(player)
    if not data then return false end

    data.collectionClaimed = data.collectionClaimed or {}
    if data.collectionClaimed[zoneName] then return false end  -- уже забрано

    local FishData = require(game:GetService("ReplicatedStorage").Modules.FishData)
    local zoneFish = FishData:GetFishInZone(zoneName)
    if #zoneFish == 0 then return false end

    -- Все ли виды зоны пойманы?
    for _, fish in ipairs(zoneFish) do
        local dexEntry = data.fishDex[fish.id]
        if not dexEntry or (dexEntry.count or 0) < 1 then
            return false  -- не вся коллекция
        end
    end

    -- Коллекция полна — выдать награду
    local reward = GameConfig.CollectionRewards[zoneName]
    if not reward then return false end

    data.collectionClaimed[zoneName] = true
    if reward.coins then
        self:AddCoins(player, reward.coins)
    end
    if reward.rodReward and not table.find(data.ownedRods, reward.rodReward) then
        table.insert(data.ownedRods, reward.rodReward)
    end
    if reward.title then
        data.titles = data.titles or {}
        data.titles[reward.title] = true
    end

    return true, reward
end

-- ══ HALL OF FAME ══
function DataService:UpdateHallOfFame(catchEntry)
    -- catchEntry = { playerName, fishId, fishName, rarity, size, mutation, value }
    local success, err = pcall(function()
        HALL_OF_FAME_STORE:UpdateAsync("top10", function(current)
            current = current or {}
            table.insert(current, catchEntry)
            -- Сортировка по value убыванием
            table.sort(current, function(a, b) return a.value > b.value end)
            -- Оставить топ-10
            while #current > 10 do table.remove(current) end
            return current
        end)
    end)
    if not success then
        warn("[DataService] Hall of Fame ошибка:", err)
    end
end

function DataService:GetHallOfFame()
    local success, data = pcall(function()
        return HALL_OF_FAME_STORE:GetAsync("top10")
    end)
    return (success and data) or {}
end

-- ══ АВТОСОХРАНЕНИЕ ══
-- Отдельный цикл вместо Heartbeat (не нужно проверять каждый кадр)
local AUTOSAVE_INTERVAL = 60  -- секунд

task.spawn(function()
    while true do
        task.wait(AUTOSAVE_INTERVAL)
        for _, player in ipairs(Players:GetPlayers()) do
            -- Защита от ошибки в одном игроке, чтобы цикл не падал
            pcall(function()
                DataService:SavePlayer(player)
            end)
        end
    end
end)

-- Сохранение при выходе
Players.PlayerRemoving:Connect(function(player)
    DataService:SavePlayer(player)
    playerCache[tostring(player.UserId)] = nil
end)

-- Сохранение при закрытии сервера (ждём завершения всех записей)
game:BindToClose(function()
    local players = Players:GetPlayers()
    if #players == 0 then return end

    local remaining = #players
    for _, player in ipairs(players) do
        task.spawn(function()
            pcall(function() DataService:SavePlayer(player) end)
            remaining -= 1
        end)
    end

    -- Дать запросам завершиться (макс ~30 сек до форс-клоза)
    local t = 0
    while remaining > 0 and t < 25 do
        task.wait(0.2)
        t += 0.2
    end
end)

return DataService

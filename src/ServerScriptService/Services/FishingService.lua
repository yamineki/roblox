-- ServerScriptService/Services/FishingService.lua
-- Reef Diver — Серверная логика рыбалки
-- Обрабатывает: выбор рыбы, мутации, размер, стоимость, объявления

local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local FishData   = require(ReplicatedStorage.Modules.FishData)
local RodData    = require(ReplicatedStorage.Modules.RodData)

local FishingService = {}

-- Серверный RNG (один инстанс — честнее и быстрее глобального math.random)
local rng = Random.new()

-- Проверка активности буста с учётом истечения
local function boostActive(boost)
    if not boost then return false end
    if boost.endsAt and os.time() > boost.endsAt then return false end
    return true
end

-- ══ ВЫБОР СЛУЧАЙНОЙ РЫБЫ ══
function FishingService:RollFish(zoneName, rodId, luckMult)
    local rod = RodData:GetRod(rodId) or RodData:GetStarterRod()
    local fishInZone = table.clone(FishData:GetFishInZone(zoneName))

    -- Если VoidRod — шанс рыбы из следующей зоны
    if rod.crossZone and rng:NextNumber() < (rod.crossZoneChance or 0.15) then
        local zoneOrder = {"SunnyReef","CoralTrench","OpenOcean","DarkWaters","Abyss"}
        for i, z in ipairs(zoneOrder) do
            if z == zoneName and zoneOrder[i+1] then
                local nextFish = FishData:GetFishInZone(zoneOrder[i+1])
                for _, f in ipairs(nextFish) do
                    table.insert(fishInZone, f)
                end
                break
            end
        end
    end

    if #fishInZone == 0 then return nil end

    -- Взвешенный выбор по редкости
    local rarityConfig = GameConfig.Rarity
    local totalWeight = 0
    local weightedPool = {}

    for _, fish in ipairs(fishInZone) do
        local rConfig = rarityConfig[fish.rarity]
        if rConfig then
            local w = rConfig.weight
            -- Бонус удочки к редкости + геймпасс Luck (повышают вес НЕ-Common рыб)
            if fish.rarity ~= "Common" then
                if rod.rarityBonus and rod.rarityBonus > 0 then
                    w = w * (1 + rod.rarityBonus)
                end
                if luckMult and luckMult > 1 then
                    w = w * luckMult
                end
            end
            totalWeight = totalWeight + w
            table.insert(weightedPool, { fish = fish, weight = totalWeight })
        end
    end

    local roll = rng:NextNumber() * totalWeight
    for _, entry in ipairs(weightedPool) do
        if roll <= entry.weight then
            return entry.fish
        end
    end

    return fishInZone[1]
end

-- ══ ОПРЕДЕЛЕНИЕ РАЗМЕРА ══
function FishingService:RollSize(rodId)
    local rod = RodData:GetRod(rodId) or RodData:GetStarterRod()
    local sizes = GameConfig.Sizes
    local sizeOrder = {"Tiny","Small","Normal","Large","Huge","Giant","Titanic","Colossal","Leviathan"}

    local totalWeight = 0
    local pool = {}

    for _, sizeName in ipairs(sizeOrder) do
        local s = sizes[sizeName]
        local w = s.weight
        -- Бонус удочки к размеру
        if rod.sizeBonus and rod.sizeBonus > 0 then
            local idx = table.find(sizeOrder, sizeName) or 1
            if idx >= 4 then -- Large и выше
                w = w * (1 + rod.sizeBonus)
            end
        end
        totalWeight = totalWeight + w
        table.insert(pool, { name = sizeName, weight = totalWeight, mult = s.mult })
    end

    local roll = rng:NextNumber() * totalWeight
    for _, entry in ipairs(pool) do
        if roll <= entry.weight then
            return entry.name, entry.mult
        end
    end

    return "Normal", 1.0
end

-- ══ ОПРЕДЕЛЕНИЕ МУТАЦИИ ══
function FishingService:RollMutation(rodId, isPerfectHook, activeBoosts, activeEvent)
    local rod = RodData:GetRod(rodId) or RodData:GetStarterRod()

    -- GoldenTide: гарантированная Golden мутация
    if activeEvent == "GoldenTide" then
        return "Golden"
    end

    local chance = GameConfig.BaseMutationChance
        + (rod.mutationChanceBonus or 0)

    if isPerfectHook then
        chance = chance + GameConfig.Fishing.PerfectHookMutationBonus
    end

    -- MutationSwarm: множитель шанса
    if activeEvent == "MutationSwarm" then
        local ev = GameConfig.Events.MutationSwarm
        chance = chance * (ev and ev.mutationChanceMult or 3)
    end

    -- Активные бусты (с проверкой истечения)
    if activeBoosts and boostActive(activeBoosts.MutationBoost) then
        chance = chance * activeBoosts.MutationBoost.mult
    end

    -- Геймпасс 2x Mutation
    if activeBoosts and activeBoosts._gamepassMutationMult then
        chance = chance * activeBoosts._gamepassMutationMult
    end

    if rng:NextNumber() > chance then return nil end

    -- Выбрать мутацию из доступного пула
    local pool = {}
    for mutName in pairs(GameConfig.Mutations) do
        table.insert(pool, mutName)
    end
    if #pool == 0 then return nil end

    return pool[rng:NextInteger(1, #pool)]
end

-- ══ РАССЧИТАТЬ СТОИМОСТЬ ══
function FishingService:CalculateValue(fish, sizeName, sizeMult, mutation, isPerfectHook, isPerfectCatch, rebirthLevel, comboMult, coinMult)
    local value = fish.basePrice * sizeMult

    -- Мутация
    if mutation then
        local mutConfig = GameConfig.Mutations[mutation]
        if mutConfig then
            value = value * mutConfig.valueMult
        end
    end

    -- Perfect Hook бонус
    if isPerfectHook then
        value = value * (1 + GameConfig.Fishing.PerfectHookValueBonus)
    end

    -- Perfect Catch бонус
    if isPerfectCatch then
        value = value * (1 + GameConfig.Fishing.PerfectCatchValueBonus)
    end

    -- Perfect Combo множитель (серия Perfect подряд)
    if comboMult and comboMult > 1 then
        value = value * comboMult
    end

    -- PRESTIGE: множитель монет от rebirth
    local rl = rebirthLevel or 0
    if rl > 0 then
        value = value * (1 + rl * GameConfig.RebirthCoinMultPerLevel)
    end

    -- Геймпасс 2x Coins (и прочие coin-множители)
    if coinMult and coinMult > 1 then
        value = value * coinMult
    end

    return math.floor(value)
end

-- ══ ПРОВЕРИТЬ — НУЖНО ЛИ ОБЪЯВЛЕНИЕ ══
function FishingService:ShouldAnnounce(fish, sizeName, mutation)
    if fish.rarity == "Mythic" then return true, "Mythic" end
    if fish.rarity == "Secret" then return true, "Secret" end
    if mutation == "Prismatic" then return true, "Prismatic" end
    if mutation == "LeviathanTouched" then return true, "LeviathanTouched" end
    if sizeName == "Leviathan" then return true, "LeviathanSize" end
    return false, nil
end

-- ══ ОБРАБОТАТЬ ПОИМКУ (главная функция) ══
function FishingService:ProcessCatch(player, data)
    -- data = { zone, rodId, hookResult, isPerfectCatch, activeBoosts }
    local fish = self:RollFish(data.zone, data.rodId, data.luckMult)
    if not fish then return nil end

    local sizeName, sizeMult = self:RollSize(data.rodId)
    local mutation = self:RollMutation(
        data.rodId,
        data.hookResult == "perfect",
        data.activeBoosts,
        data.activeEvent
    )

    local isPerfectHook  = (data.hookResult == "perfect")
    local isPerfectCatch = data.isPerfectCatch or false

    local value = self:CalculateValue(
        fish, sizeName, sizeMult, mutation,
        isPerfectHook, isPerfectCatch,
        data.rebirthLevel, data.comboMult, data.coinMult
    )

    local catchEntry = {
        id          = fish.id,
        displayName = fish.displayName,
        rarity      = fish.rarity,
        zone        = fish.zone,
        behavior    = fish.behavior,  -- для мини-игры на клиенте
        size        = sizeName,
        sizeMult    = sizeMult,
        mutation    = mutation,
        value       = value,
        isPerfectHook  = isPerfectHook,
        isPerfectCatch = isPerfectCatch,
        comboMult   = data.comboMult or 1,
        rebirthLevel= data.rebirthLevel or 0,
        -- PLACEHOLDER: image подставляется из FishData
        image       = fish.image,
        timestamp   = os.time(),
        playerName  = player.Name,
    }

    local shouldAnnounce, announceType = self:ShouldAnnounce(fish, sizeName, mutation)

    return catchEntry, shouldAnnounce, announceType
end

return FishingService

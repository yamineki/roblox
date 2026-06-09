-- ServerScriptService/ServerMain.server.lua
-- Reef Diver — Главный серверный скрипт
-- Инициализирует все сервисы и обрабатывает RemoteEvents

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

-- ── Инициализация ремоутов ──
require(ReplicatedStorage.Remotes.RemoteSetup)

-- ── Загрузка сервисов ──
local DataService            = require(script.Parent.Services.DataService)
local FishingService         = require(script.Parent.Services.FishingService)
local AnnouncementService    = require(script.Parent.Services.AnnouncementService)
local EventService           = require(script.Parent.Services.EventService)
local FishInventoryService   = require(script.Parent.Services.FishInventoryService)
local MonetizationService    = require(script.Parent.Services.MonetizationService)
local MarketplaceService     = game:GetService("MarketplaceService")
local MonetizationConfig     = require(ReplicatedStorage.Modules.MonetizationConfig)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Кэш ссылок на ремоуты (один раз, не WaitForChild в каждом хендлере)
local R = {
    PlayerDataLoaded   = Remotes:WaitForChild("PlayerDataLoaded"),
    GetPlayerData      = Remotes:WaitForChild("GetPlayerData"),
    CatchResult        = Remotes:WaitForChild("CatchResult"),
    FishCaught         = Remotes:WaitForChild("FishCaught"),
    CoinsUpdated       = Remotes:WaitForChild("CoinsUpdated"),
    GetInventory       = Remotes:WaitForChild("GetInventory"),
    SellFish           = Remotes:WaitForChild("SellFish"),
    SellFishByName     = Remotes:WaitForChild("SellFishByName"),
    SellAll            = Remotes:WaitForChild("SellAll"),
    BuyRod             = Remotes:WaitForChild("BuyRod"),
    RodPurchased       = Remotes:WaitForChild("RodPurchased"),
    EquipRod           = Remotes:WaitForChild("EquipRod"),
    RodEquipped        = Remotes:WaitForChild("RodEquipped"),
    GetRods            = Remotes:WaitForChild("GetRods"),
    StartExpedition    = Remotes:WaitForChild("StartExpedition"),
    CollectExpedition  = Remotes:WaitForChild("CollectExpedition"),
    ExpeditionStarted  = Remotes:WaitForChild("ExpeditionStarted"),
    ExpeditionComplete = Remotes:WaitForChild("ExpeditionComplete"),
    GetExpeditionStatus= Remotes:WaitForChild("GetExpeditionStatus"),
    RequestRebirth     = Remotes:WaitForChild("RequestRebirth"),
    RebirthComplete    = Remotes:WaitForChild("RebirthComplete"),
    GetDailyStatus     = Remotes:WaitForChild("GetDailyStatus"),
    ClaimDailyReward   = Remotes:WaitForChild("ClaimDailyReward"),
    DailyRewardClaimed = Remotes:WaitForChild("DailyRewardClaimed"),
    GetFishDex         = Remotes:WaitForChild("GetFishDex"),
    UnlockZone         = Remotes:WaitForChild("UnlockZone"),
    ZoneUnlocked       = Remotes:WaitForChild("ZoneUnlocked"),
    GetZoneStatus      = Remotes:WaitForChild("GetZoneStatus"),
    EnterZone          = Remotes:WaitForChild("EnterZone"),
    ZoneEntered        = Remotes:WaitForChild("ZoneEntered"),
    CollectionComplete = Remotes:WaitForChild("CollectionComplete"),
    ComboUpdate        = Remotes:WaitForChild("ComboUpdate"),
    GetShopData        = Remotes:WaitForChild("GetShopData"),
    PromptGamePass     = Remotes:WaitForChild("PromptGamePass"),
    PromptProduct      = Remotes:WaitForChild("PromptProduct"),
    GamePassPurchased  = Remotes:WaitForChild("GamePassPurchased"),
    ToggleAutoSell     = Remotes:WaitForChild("ToggleAutoSell"),
    GetAutoSellState   = Remotes:WaitForChild("GetAutoSellState"),
    GetActiveBoosts    = Remotes:WaitForChild("GetActiveBoosts"),
    BoostsUpdated      = Remotes:WaitForChild("BoostsUpdated"),
}

-- Анти-спам ловли: минимум секунд между засчитанными уловами на игрока
local CATCH_COOLDOWN = 1.0
local lastCatchAt = {}  -- userId -> os.clock()

-- Кэш модулей (не require в хендлерах)
local RodData    = require(ReplicatedStorage.Modules.RodData)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local FishData   = require(ReplicatedStorage.Modules.FishData)

-- ══ ИНИЦИАЛИЗАЦИЯ ИГРОКА ══
Players.PlayerAdded:Connect(function(player)
    local data = DataService:LoadPlayer(player)
    if not data then return end

    -- Загрузить физический инвентарь рыб ПОСЛЕ данных (исключаем гонку)
    FishInventoryService:LoadFromDataStore(player)

    -- Сообщить клиенту что данные готовы
    R.PlayerDataLoaded:FireClient(player, {
        coins       = data.coins,
        equippedRod = data.equippedRod,
        ownedRods   = data.ownedRods,
        rebirthLevel= data.rebirthLevel,
        stats       = data.stats,
    })
end)

Players.PlayerRemoving:Connect(function(player)
    DataService:SavePlayer(player)
end)

-- ══ ПОЛУЧИТЬ ДАННЫЕ ИГРОКА ══
R.GetPlayerData.OnServerInvoke = function(player)
    local data = DataService:Get(player)
    if not data then return nil end
    return {
        coins           = data.coins,
        equippedRod     = data.equippedRod,
        ownedRods       = data.ownedRods,
        rebirthLevel    = data.rebirthLevel,
        rebirthBonuses  = data.rebirthBonuses,
        stats           = data.stats,
        activeBoosts    = data.activeBoosts,
    }
end

-- ══ РЫБАЛКА: РЕЗУЛЬТАТ ПОИМКИ ══
R.CatchResult.OnServerEvent:Connect(function(player, requestData)
    -- requestData = { zone, hookResult, isPerfectCatch }
    if type(requestData) ~= "table" then return end
    local data = DataService:Get(player)
    if not data then return end

    -- Анти-спам: кулдаун между засчитанными уловами
    local uid = player.UserId
    local now = os.clock()
    if lastCatchAt[uid] and (now - lastCatchAt[uid]) < CATCH_COOLDOWN then
        return
    end
    lastCatchAt[uid] = now

    -- Источник правды для удочки — реально надетый Tool в персонаже.
    -- Это устраняет рассинхрон между хотбаром (EquipTool) и data.equippedRod.
    local equippedRodId = data.equippedRod
    local char = player.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and RodData:GetRod(item.Name) then
                equippedRodId = item.Name
                break
            end
        end
    end
    -- Синхронизировать данные, если разошлось
    if equippedRodId ~= data.equippedRod then
        data.equippedRod = equippedRodId
    end

    local rod = RodData:GetRod(equippedRodId) or RodData:GetStarterRod()

    -- Зона определяется ТЕКУЩЕЙ зоной игрока (куда телепортировал NPC),
    -- а не удочкой. Игрок может быть только в разблокированной зоне.
    local activeZone = data.currentZone or "SunnyReef"
    if not DataService:IsZoneUnlocked(player, activeZone) then
        activeZone = "SunnyReef"
        data.currentZone = activeZone
    end

    -- Санитизация hookResult
    local hr = requestData.hookResult
    if hr ~= "perfect" and hr ~= "good" then hr = "good" end

    local isPerfectCatch = requestData.isPerfectCatch == true

    -- PERFECT COMBO: обновить серию ДО расчёта стоимости
    local comboMult, comboStreak = DataService:UpdatePerfectCombo(player, isPerfectCatch)

    -- Множители от геймпассов (2x Coins / Luck / Mutation)
    local gpMult = MonetizationService:GetMultipliers(player)

    -- Прокинуть mutation-множитель через activeBoosts (FishingService читает оттуда)
    local boostsWithGP = data.activeBoosts or {}
    boostsWithGP._gamepassMutationMult = gpMult.mutation

    local serverRequest = {
        zone           = activeZone,
        rodId          = equippedRodId,
        hookResult     = hr,
        isPerfectCatch = isPerfectCatch,
        activeBoosts   = boostsWithGP,
        activeEvent    = EventService:GetActiveEvent(),
        rebirthLevel   = data.rebirthLevel or 0,
        comboMult      = comboMult,
        luckMult       = gpMult.luck,
        coinMult       = gpMult.coin,
    }

    local catchEntry, shouldAnnounce, announceType =
        FishingService:ProcessCatch(player, serverRequest)

    if not catchEntry then return end

    -- Сохранить рыбу в физический инвентарь (папка FishInventory) + DataStore
    local fishItem = FishInventoryService:AddFish(player, catchEntry)

    -- AUTO-SELL (геймпасс): сразу продать, если включено
    if MonetizationService:HasAutoSell(player) and data.autoSellEnabled ~= false then
        if fishItem then
            local _, earned = FishInventoryService:RemoveFish(player, fishItem.Name)
            if earned and earned > 0 then
                DataService:AddCoins(player, earned)
            end
        end
    end

    -- Отправить результат клиенту
    R.FishCaught:FireClient(player, catchEntry)
    R.CoinsUpdated:FireClient(player, data.coins)

    -- Сообщить клиенту combo-серию
    R.ComboUpdate:FireClient(player, {
        streak = comboStreak or 0,
        mult   = comboMult or 1,
    })

    -- Проверить завершение коллекции зоны (после добавления в FishDex)
    local collClaimed, collReward = DataService:CheckCollectionComplete(player, catchEntry.zone)
    if collClaimed and collReward then
        R.CollectionComplete:FireClient(player, {
            zone   = catchEntry.zone,
            reward = collReward,
        })
        R.CoinsUpdated:FireClient(player, data.coins)
        -- Если в награду удочка — выдать Tool
        if collReward.rodReward then
            local GiveRodEvent = ServerStorage:FindFirstChild("GiveRodToPlayer")
            if GiveRodEvent then
                GiveRodEvent:Fire(player, collReward.rodReward)
            end
        end
    end

    -- Серверное объявление
    if shouldAnnounce then
        AnnouncementService:Announce(player, catchEntry, announceType)
        DataService:UpdateHallOfFame(catchEntry)
    end
end)

-- ══ ИНВЕНТАРЬ: ПОЛУЧИТЬ ══
R.GetInventory.OnServerInvoke = function(player)
    local data = DataService:Get(player)
    return data and data.fishInventory or {}
end

-- ══ ПРОДАТЬ РЫБУ ПО ИНДЕКСУ (legacy) ══
R.SellFish.OnServerEvent:Connect(function(player, fishIndex)
    DataService:SellFish(player, fishIndex)
    local data = DataService:Get(player)
    R.CoinsUpdated:FireClient(player, data and data.coins or 0)
end)

-- ══ ПРОДАТЬ РЫБУ ПО ИМЕНИ (кастомный UI) ══
R.SellFishByName.OnServerEvent:Connect(function(player, itemName)
    if type(itemName) ~= "string" then return end
    local success, earned = FishInventoryService:RemoveFish(player, itemName)
    if success then
        DataService:AddCoins(player, earned)
    end
    local data = DataService:Get(player)
    R.CoinsUpdated:FireClient(player, data and data.coins or 0)
end)

-- ══ ПРОДАТЬ ВСЁ ══
R.SellAll.OnServerEvent:Connect(function(player)
    FishInventoryService:SellAll(player)
    local data = DataService:Get(player)
    R.CoinsUpdated:FireClient(player, data and data.coins or 0)
end)

-- ══ КУПИТЬ УДОЧКУ ══
R.BuyRod.OnServerEvent:Connect(function(player, rodId)
    if type(rodId) ~= "string" then return end
    local rod = RodData:GetRod(rodId)
    if not rod then return end

    local success, reason = DataService:BuyRod(player, rodId, rod.price)
    R.RodPurchased:FireClient(player, { success = success, reason = reason, rodId = rodId })

    if success then
        local data = DataService:Get(player)
        R.CoinsUpdated:FireClient(player, data.coins)

        -- Выдать Tool удочки в Backpack игрока
        local GiveRodEvent = ServerStorage:FindFirstChild("GiveRodToPlayer")
        if GiveRodEvent then
            GiveRodEvent:Fire(player, rodId)
        end
    end
end)

-- ══ НАДЕТЬ УДОЧКУ ══
R.EquipRod.OnServerEvent:Connect(function(player, rodId)
    if type(rodId) ~= "string" then return end
    local data = DataService:Get(player)
    if not data then return end
    for _, owned in ipairs(data.ownedRods) do
        if owned == rodId then
            data.equippedRod = rodId
            R.RodEquipped:FireClient(player, rodId)
            return
        end
    end
end)

-- ══ ПОЛУЧИТЬ УДОЧКИ ══
R.GetRods.OnServerInvoke = function(player)
    local data = DataService:Get(player)
    return data and { owned = data.ownedRods, equipped = data.equippedRod } or {}
end

-- ══ AFK ЭКСПЕДИЦИЯ: ЗАПУСК ══
R.StartExpedition.OnServerEvent:Connect(function(player, durationType)
    if type(durationType) ~= "string" then return end
    local data = DataService:Get(player)
    if not data then return end

    local cfg = GameConfig.Expeditions[durationType]
    if not cfg then return end

    -- Проверить слоты (базово 1, Rebirth 1 = 2)
    local maxSlots = 1
        + (data.rebirthLevel >= 1 and 1 or 0)
        + MonetizationService:GetExtraAFKSlots(player)
    local activeCount = 0
    for _, exp in ipairs(data.expeditions) do
        if exp.active then activeCount = activeCount + 1 end
    end
    if activeCount >= maxSlots then return end

    table.insert(data.expeditions, {
        slot        = #data.expeditions + 1,
        startTime   = os.time(),
        endTime     = os.time() + cfg.duration,
        durationType= durationType,
        active      = true,
    })

    R.ExpeditionStarted:FireClient(player, data.expeditions)
end)

-- ══ AFK ЭКСПЕДИЦИЯ: ЗАБРАТЬ РЕЗУЛЬТАТЫ ══
R.CollectExpedition.OnServerEvent:Connect(function(player, slotIndex)
    if type(slotIndex) ~= "number" then return end
    local data = DataService:Get(player)
    if not data then return end

    local exp = data.expeditions[slotIndex]
    if not exp or not exp.active then return end
    if os.time() < exp.endTime then return end  -- ещё не готова

    local cfg = GameConfig.Expeditions[exp.durationType]
    if not cfg then return end

    -- Генерация добычи
    local rewards = { coins = 0, fish = {} }
    rewards.coins = math.random(100, 300) * cfg.coinMult

    local count = math.random(cfg.fishMin, cfg.fishMax)
    for _ = 1, count do
        local pool = FishData:GetFishInZone("SunnyReef")
        if #pool > 0 then
            local fish = pool[math.random(#pool)]
            table.insert(rewards.fish, {
                id          = fish.id,
                displayName = fish.displayName,
                rarity      = fish.rarity,
                zone        = fish.zone,
                size        = "Normal",
                sizeMult    = 1.0,
                mutation    = nil,
                value       = fish.basePrice,
                image       = fish.image,
            })
        end
    end

    -- Применить награды (рыбы через FishInventoryService -> папка + DataStore)
    DataService:AddCoins(player, rewards.coins)
    for _, fishEntry in ipairs(rewards.fish) do
        FishInventoryService:AddFish(player, fishEntry)
    end

    -- Снять экспедицию
    table.remove(data.expeditions, slotIndex)

    R.ExpeditionComplete:FireClient(player, rewards)
    R.CoinsUpdated:FireClient(player, data.coins)
end)

-- ══ ПОЛУЧИТЬ СТАТУС ЭКСПЕДИЦИЙ ══
R.GetExpeditionStatus.OnServerInvoke = function(player)
    local data = DataService:Get(player)
    return data and data.expeditions or {}
end

-- ══ REBIRTH ══
R.RequestRebirth.OnServerEvent:Connect(function(player)
    local discount = MonetizationService:GetRebirthDiscount(player)
    local success = DataService:DoRebirth(player, discount)
    local data = DataService:Get(player)
    R.RebirthComplete:FireClient(player, {
        success    = success,
        newLevel   = data and data.rebirthLevel or 0,
        bonuses    = data and data.rebirthBonuses or {},
    })
    if success and data then
        -- Очистить физический инвентарь рыб (без начисления монет)
        FishInventoryService:ClearAll(player)

        -- Удалить ВСЕ физические Tool-удочки (Backpack + надетую), кроме стартовой
        local function purgeRods(container)
            if not container then return end
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and RodData:GetRod(item.Name) and item.Name ~= "WoodenRod" then
                    item:Destroy()
                end
            end
        end
        purgeRods(player:FindFirstChild("Backpack"))
        purgeRods(player.Character)

        -- Убедиться что стартовая удочка есть в наличии
        local GiveRodEvent = ServerStorage:FindFirstChild("GiveRodToPlayer")
        if GiveRodEvent and player:FindFirstChild("Backpack")
           and not player.Backpack:FindFirstChild("WoodenRod") then
            GiveRodEvent:Fire(player, "WoodenRod")
        end

        R.CoinsUpdated:FireClient(player, data.coins)
    end
end)

-- ══ DAILY REWARDS: СТАТУС ══
R.GetDailyStatus.OnServerInvoke = function(player)
    local data = DataService:Get(player)
    if not data then return nil end

    local now = os.time()
    local today = math.floor(now / 86400)
    local lastDay = math.floor((data.lastDailyClaim or 0) / 86400)
    local streak = data.dailyStreak or 0

    local canClaim = today > lastDay
    if canClaim and (today - lastDay > 1) then streak = 0 end

    return {
        canClaim    = canClaim,
        streak      = streak,
        nextDay     = (streak % 7) + 1,
        lastClaim   = data.lastDailyClaim or 0,
        nextClaimAt = (lastDay + 1) * 86400,  -- начало следующих суток UTC
    }
end

-- ══ DAILY REWARDS: ЗАБРАТЬ ══
-- Дни считаем по календарным суткам UTC (00:00), а не по «прошло 86400 сек»
local function dayNumber(t)
    return math.floor(t / 86400)
end

R.ClaimDailyReward.OnServerEvent:Connect(function(player)
    local data = DataService:Get(player)
    if not data then return end

    local now = os.time()
    local today = dayNumber(now)
    local lastDay = dayNumber(data.lastDailyClaim or 0)

    if today <= lastDay then return end  -- уже забирал сегодня

    -- Серия: +1 если вчера, иначе сброс
    if today - lastDay == 1 then
        data.dailyStreak = (data.dailyStreak or 0) + 1
    else
        data.dailyStreak = 1
    end
    local dayIndex = ((data.dailyStreak - 1) % 7) + 1
    data.lastDailyClaim = now

    local reward = GameConfig.DailyRewards[dayIndex]
    local reward_payload = { day = dayIndex, reward = reward }

    -- Применить награду
    if reward.type == "Coins" then
        DataService:AddCoins(player, reward.amount)
        R.CoinsUpdated:FireClient(player, data.coins)
    elseif reward.type == "LuckBoost" then
        data.activeBoosts = data.activeBoosts or {}
        data.activeBoosts.LuckBoost = {
            mult    = reward.mult,
            endsAt  = now + reward.duration,
        }
    elseif reward.type == "MutationBoost" then
        data.activeBoosts = data.activeBoosts or {}
        data.activeBoosts.MutationBoost = {
            mult    = reward.mult,
            endsAt  = now + reward.duration,
        }
    end
    -- Остальные типы наград — TODO по мере реализации соответствующих систем

    R.DailyRewardClaimed:FireClient(player, reward_payload)
end)

-- ══ FISHDEX ══
R.GetFishDex.OnServerInvoke = function(player)
    local data = DataService:Get(player)
    return data and data.fishDex or {}
end

-- ══ ЗОНЫ: СТАТУС ══
R.GetZoneStatus.OnServerInvoke = function(player)
    local data = DataService:Get(player)
    if not data then return nil end

    local result = {}
    for _, zoneName in ipairs(GameConfig.ZoneOrder) do
        local cfg = GameConfig.Zones[zoneName]
        result[zoneName] = {
            order      = cfg.order,
            unlockCost = cfg.unlockCost,
            minRebirth = cfg.minRebirth,
            depthLabel = cfg.depthLabel,
            unlocked   = (data.unlockedZones and data.unlockedZones[zoneName]) == true,
            current    = data.currentZone == zoneName,
        }
    end
    return {
        zones        = result,
        currentZone  = data.currentZone or "SunnyReef",
        rebirthLevel = data.rebirthLevel or 0,
    }
end

-- ══ ЗОНЫ: РАЗБЛОКИРОВКА (покупка у NPC) ══
R.UnlockZone.OnServerEvent:Connect(function(player, zoneName)
    if type(zoneName) ~= "string" then return end
    local success, reason = DataService:UnlockZone(player, zoneName)
    R.ZoneUnlocked:FireClient(player, {
        success  = success,
        reason   = reason,
        zoneName = zoneName,
    })
    if success then
        local data = DataService:Get(player)
        R.CoinsUpdated:FireClient(player, data.coins)
    end
end)

-- ══ ЗОНЫ: ВХОД (телепорт через NPC) ══
R.EnterZone.OnServerEvent:Connect(function(player, zoneName)
    if type(zoneName) ~= "string" then return end
    local data = DataService:Get(player)
    if not data then return end

    if not DataService:IsZoneUnlocked(player, zoneName) then
        R.ZoneEntered:FireClient(player, { success = false, reason = "locked", zoneName = zoneName })
        return
    end

    DataService:SetCurrentZone(player, zoneName)

    -- Телепортировать персонажа к точке зоны (если есть в workspace/Zones)
    local char = player.Character
    local zonesFolder = workspace:FindFirstChild("Zones")
    if char and char:FindFirstChild("HumanoidRootPart") and zonesFolder then
        local zonePart = zonesFolder:FindFirstChild(zoneName .. "_Zone")
        if zonePart then
            char:PivotTo(zonePart.CFrame + Vector3.new(0, 5, 0))
        end
    end

    R.ZoneEntered:FireClient(player, {
        success  = true,
        zoneName = zoneName,
    })
end)

-- ══ МАГАЗИН: ДАННЫЕ ГЕЙМПАССОВ ══
R.GetShopData.OnServerInvoke = function(player)
    local owned = {}
    for key in pairs(MonetizationConfig.GamePasses) do
        owned[key] = MonetizationService:OwnsGamePass(player, key)
    end
    return { owned = owned }
end

-- ══ ЗАПРОС ПОКУПКИ ГЕЙМПАССА ══
R.PromptGamePass.OnServerEvent:Connect(function(player, gamePassKey)
    if type(gamePassKey) ~= "string" then return end
    local gp = MonetizationConfig.GamePasses[gamePassKey]
    if not gp or gp.id == 0 then return end
    MarketplaceService:PromptGamePassPurchase(player, gp.id)
end)

-- ══ ЗАПРОС ПОКУПКИ ПРОДУКТА ══
R.PromptProduct.OnServerEvent:Connect(function(player, productKey)
    if type(productKey) ~= "string" then return end
    local prod = MonetizationConfig.Products[productKey]
    if not prod or prod.id == 0 then return end
    MarketplaceService:PromptProductPurchase(player, prod.id)
end)

-- ══ AUTO-SELL ТОГЛ ══
R.ToggleAutoSell.OnServerEvent:Connect(function(player, enabled)
    local data = DataService:Get(player)
    if not data then return end
    data.autoSellEnabled = (enabled == true)
end)

R.GetAutoSellState.OnServerInvoke = function(player)
    local data = DataService:Get(player)
    return {
        owned   = MonetizationService:HasAutoSell(player),
        enabled = data and data.autoSellEnabled ~= false,
    }
end

-- ══ АКТИВНЫЕ БУСТЫ (для HUD-индикатора) ══
R.GetActiveBoosts.OnServerInvoke = function(player)
    return MonetizationService:GetActiveBoostsSummary(player)
end

-- Периодический пуш бустов (чтобы таймеры тикали и истёкшие пропадали)
task.spawn(function()
    while true do
        task.wait(5)
        for _, player in ipairs(Players:GetPlayers()) do
            local ok, summary = pcall(function()
                return MonetizationService:GetActiveBoostsSummary(player)
            end)
            if ok then
                R.BoostsUpdated:FireClient(player, summary)
            end
        end
    end
end)

-- ══ КРОСС-СЕРВЕРНЫЕ ОБЪЯВЛЕНИЯ ══
-- AnnouncementService публикует в "ReefDiverAnnounce" — здесь подписываемся,
-- чтобы баннер о редком улове видели игроки на ВСЕХ серверах.
do
    local MessagingService = game:GetService("MessagingService")
    local ServerAnnouncement = Remotes:WaitForChild("ServerAnnouncement")
    local ok, err = pcall(function()
        MessagingService:SubscribeAsync("ReefDiverAnnounce", function(packet)
            local payload = packet.Data
            if type(payload) == "table" then
                -- Пропустить эхо со своего же сервера (уже показали локально)
                if payload.originJobId == game.JobId then return end
                payload.crossServer = true
                ServerAnnouncement:FireAllClients(payload)
            end
        end)
    end)
    if not ok then
        warn("[ReefDiver] MessagingService подписка не удалась (норма в Studio):", err)
    end
end

print("[ReefDiver] ServerMain инициализирован ✓")

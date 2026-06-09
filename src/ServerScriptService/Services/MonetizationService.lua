-- ServerScriptService/Services/MonetizationService.lua
-- Reef Diver — Серверная логика монетизации
-- Геймпассы (UserOwnsGamePassAsync) + Developer Products (ProcessReceipt)

local Players              = game:GetService("Players")
local MarketplaceService   = game:GetService("MarketplaceService")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local ServerStorage        = game:GetService("ServerStorage")

local MonetizationConfig = require(ReplicatedStorage.Modules.MonetizationConfig)
local DataService        = require(script.Parent.DataService)

local MonetizationService = {}

-- Кэш владения геймпассами: userId -> { gamePassKey -> bool }
local ownedCache = {}

-- ══ ПРОВЕРКА ВЛАДЕНИЯ ГЕЙМПАССОМ ══
function MonetizationService:OwnsGamePass(player, gamePassKey)
    local uid = player.UserId
    ownedCache[uid] = ownedCache[uid] or {}

    -- Из кэша
    if ownedCache[uid][gamePassKey] ~= nil then
        return ownedCache[uid][gamePassKey]
    end

    local gp = MonetizationConfig.GamePasses[gamePassKey]
    if not gp or gp.id == 0 then
        ownedCache[uid][gamePassKey] = false
        return false
    end

    local success, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gp.id)
    end)

    local result = success and owns or false
    ownedCache[uid][gamePassKey] = result
    return result
end

-- Сбросить кэш (после новой покупки)
function MonetizationService:InvalidateCache(player, gamePassKey)
    local uid = player.UserId
    if ownedCache[uid] then
        if gamePassKey then
            ownedCache[uid][gamePassKey] = nil
        else
            ownedCache[uid] = {}
        end
    end
end

-- ══ ПОЛУЧИТЬ ВСЕ МНОЖИТЕЛИ ИГРОКА ══
-- Возвращает таблицу множителей для FishingService
function MonetizationService:GetMultipliers(player)
    local mult = {
        coin      = 1.0,
        luck      = 1.0,
        mutation  = 1.0,
        catchSpeed= 1.0,
    }

    if self:OwnsGamePass(player, "Coins2x") then
        mult.coin = mult.coin * MonetizationConfig.GamePasses.Coins2x.effect.value
    end
    if self:OwnsGamePass(player, "Luck2x") then
        mult.luck = mult.luck * MonetizationConfig.GamePasses.Luck2x.effect.value
    end
    if self:OwnsGamePass(player, "Mutation2x") then
        mult.mutation = mult.mutation * MonetizationConfig.GamePasses.Mutation2x.effect.value
    end
    if self:OwnsGamePass(player, "CatchSpeed2x") then
        mult.catchSpeed = mult.catchSpeed * MonetizationConfig.GamePasses.CatchSpeed2x.effect.value
    end

    return mult
end

-- ══ ПРОВЕРКИ ОТДЕЛЬНЫХ ПАССОВ (для других систем) ══
function MonetizationService:HasAutoSell(player)
    return self:OwnsGamePass(player, "AutoSell")
end

function MonetizationService:GetExtraAFKSlots(player)
    if self:OwnsGamePass(player, "ExtraAFKSlots") then
        return MonetizationConfig.GamePasses.ExtraAFKSlots.effect.value
    end
    return 0
end

function MonetizationService:GetExtraInventory(player)
    if self:OwnsGamePass(player, "ExtraInventory") then
        return MonetizationConfig.GamePasses.ExtraInventory.effect.value
    end
    return 0
end

function MonetizationService:GetRebirthDiscount(player)
    if self:OwnsGamePass(player, "FastRebirth") then
        return MonetizationConfig.GamePasses.FastRebirth.effect.value
    end
    return 0
end

function MonetizationService:HasExclusiveMutations(player)
    return self:OwnsGamePass(player, "ExclusiveMutations")
end

function MonetizationService:IsVIP(player)
    return self:OwnsGamePass(player, "VIP")
end

-- ══ ПРИМЕНИТЬ ГЕЙМПАСС (одноразовые эффекты при покупке/входе) ══
function MonetizationService:ApplyOneTimeGamePass(player, gamePassKey)
    local gp = MonetizationConfig.GamePasses[gamePassKey]
    if not gp then return end

    local effect = gp.effect
    if effect.type == "grantRod" then
        -- Выдать удочку (если ещё нет)
        local data = DataService:Get(player)
        if data and not table.find(data.ownedRods, effect.value) then
            table.insert(data.ownedRods, effect.value)
            local GiveRodEvent = ServerStorage:FindFirstChild("GiveRodToPlayer")
            if GiveRodEvent then
                GiveRodEvent:Fire(player, effect.value)
            end
        end
    end
    -- Остальные пассы (множители, autoSell, vip) проверяются динамически,
    -- одноразово применять не нужно.
end

-- ══ DEVELOPER PRODUCTS: ОБРАБОТКА ПОКУПКИ ══
-- Идемпотентность через сохранённый список обработанных purchaseId
local function applyProductEffect(player, productKey)
    local prod = MonetizationConfig.Products[productKey]
    if not prod then return false end
    local effect = prod.effect

    if effect.type == "grantCoins" then
        DataService:AddCoins(player, effect.value)
        local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if Remotes then
            local cu = Remotes:FindFirstChild("CoinsUpdated")
            local data = DataService:Get(player)
            if cu and data then cu:FireClient(player, data.coins) end
        end
        return true

    elseif effect.type == "tempBoost" then
        local data = DataService:Get(player)
        if data then
            data.activeBoosts = data.activeBoosts or {}
            data.activeBoosts[effect.boost] = {
                mult   = effect.mult,
                endsAt = os.time() + effect.duration,
            }
        end
        return true

    elseif effect.type == "instantExpedition" then
        local data = DataService:Get(player)
        if data and data.expeditions then
            -- Завершить первую активную экспедицию мгновенно
            for _, exp in ipairs(data.expeditions) do
                if exp.active then
                    exp.endTime = os.time()
                    break
                end
            end
        end
        return true

    elseif effect.type == "rebirthToken" then
        local data = DataService:Get(player)
        if data then
            data.rebirthTokens = (data.rebirthTokens or 0) + 1
        end
        return true
    end

    return false
end

-- ProcessReceipt — единственный надёжный способ обработки dev products
MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        -- Игрок вышел — попробуем позже
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local data = DataService:Get(player)
    if not data then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- Идемпотентность: не выдавать дважды
    data.purchaseHistory = data.purchaseHistory or {}
    local purchaseKey = tostring(receiptInfo.PurchaseId)
    if data.purchaseHistory[purchaseKey] then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    -- Найти продукт по ID
    local productKey = MonetizationConfig:GetProductById(receiptInfo.ProductId)
    if not productKey then
        warn("[Monetization] Неизвестный продукт ID:", receiptInfo.ProductId)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- Применить эффект
    local applied = applyProductEffect(player, productKey)
    if not applied then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- Записать как обработанный и сохранить НЕМЕДЛЕННО
    data.purchaseHistory[purchaseKey] = os.time()
    DataService:SavePlayer(player)

    return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ══ ОБРАБОТКА ПОКУПКИ ГЕЙМПАССА В СЕССИИ ══
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
    if not wasPurchased then return end

    local key = MonetizationConfig:GetGamePassById(gamePassId)
    if not key then return end

    -- Сбросить кэш и применить одноразовый эффект
    MonetizationService:InvalidateCache(player, key)
    MonetizationService:ApplyOneTimeGamePass(player, key)

    -- Уведомить клиента
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if Remotes then
        local ev = Remotes:FindFirstChild("GamePassPurchased")
        if ev then ev:FireClient(player, key) end
    end
end)

-- ══ VIP ЕЖЕДНЕВНЫЙ БОНУС + ЧАТ-ТЕГ ══
Players.PlayerAdded:Connect(function(player)
    task.delay(3, function()
        if MonetizationService:IsVIP(player) then
            -- Применить разовые геймпасс-эффекты (например StarterRod при первом входе)
            for key in pairs(MonetizationConfig.GamePasses) do
                if MonetizationService:OwnsGamePass(player, key) then
                    MonetizationService:ApplyOneTimeGamePass(player, key)
                end
            end

            -- VIP ежедневный бонус (раз в сутки UTC)
            local data = DataService:Get(player)
            if data then
                local today = math.floor(os.time() / 86400)
                if (data.lastVipBonusDay or 0) < today then
                    data.lastVipBonusDay = today
                    DataService:AddCoins(player, MonetizationConfig.GamePasses.VIP.vipDailyCoins)
                end
            end
        end
    end)
end)

-- ══ СВОДКА АКТИВНЫХ БУСТОВ (для HUD) ══
-- Возвращает список { id, label, mult, kind, endsAt? } для отображения
function MonetizationService:GetActiveBoostsSummary(player)
    local list = {}

    -- Постоянные геймпасс-множители
    if self:OwnsGamePass(player, "Coins2x") then
        table.insert(list, { id = "Coins2x", label = "2× Coins", mult = 2.0, kind = "coin", permanent = true })
    end
    if self:OwnsGamePass(player, "Luck2x") then
        table.insert(list, { id = "Luck2x", label = "2× Luck", mult = 2.0, kind = "luck", permanent = true })
    end
    if self:OwnsGamePass(player, "Mutation2x") then
        table.insert(list, { id = "Mutation2x", label = "2× Mutation", mult = 2.0, kind = "mutation", permanent = true })
    end
    if self:OwnsGamePass(player, "CatchSpeed2x") then
        table.insert(list, { id = "CatchSpeed2x", label = "2× Speed", mult = 2.0, kind = "speed", permanent = true })
    end

    -- Временные бусты (из data.activeBoosts с таймерами)
    local data = DataService:Get(player)
    if data and data.activeBoosts then
        local now = os.time()
        for boostName, boost in pairs(data.activeBoosts) do
            -- Пропустить служебные поля (начинаются с _)
            if type(boost) == "table" and boost.endsAt then
                if boost.endsAt > now then
                    local kind = (boostName == "LuckBoost" and "luck")
                        or (boostName == "MutationBoost" and "mutation")
                        or "other"
                    table.insert(list, {
                        id    = boostName,
                        label = (boost.mult or 1) .. "× " .. (kind == "luck" and "Luck" or "Mutation"),
                        mult  = boost.mult or 1,
                        kind  = kind,
                        endsAt= boost.endsAt,
                    })
                end
            end
        end
    end

    -- Rebirth множитель монет (если есть)
    if data and (data.rebirthLevel or 0) > 0 then
        local rl = data.rebirthLevel
        table.insert(list, {
            id    = "Rebirth",
            label = string.format("+%d%% Coins", math.floor(rl * 50)),
            mult  = 1 + rl * 0.5,
            kind  = "coin",
            permanent = true,
        })
    end

    return list
end

return MonetizationService

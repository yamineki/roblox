-- ReplicatedStorage/Remotes/RemoteSetup.lua
-- Reef Diver — Создание всех RemoteEvent и RemoteFunction
-- Этот скрипт запускается на сервере один раз при старте

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Создаём папку для ремоутов если нет
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "Remotes"
    Remotes.Parent = ReplicatedStorage
end

local function makeEvent(name)
    if not Remotes:FindFirstChild(name) then
        local e = Instance.new("RemoteEvent")
        e.Name = name
        e.Parent = Remotes
    end
end

local function makeFunction(name)
    if not Remotes:FindFirstChild(name) then
        local f = Instance.new("RemoteFunction")
        f.Name = name
        f.Parent = Remotes
    end
end

-- ══ РЫБАЛКА ══
makeEvent("StartFishing")          -- Client → Server: игрок нажал рыбачить
makeEvent("HookResult")            -- Client → Server: результат подсечки (perfect/good/miss)
makeEvent("CatchResult")           -- Client → Server: результат мини-игры (caught/escaped)
makeEvent("FishCaught")            -- Server → Client: подтверждение поимки с данными рыбы
makeEvent("FishEscaped")           -- Server → Client: рыба сбежала

-- ══ ИНВЕНТАРЬ / ЭКОНОМИКА ══
makeFunction("GetInventory")       -- Client запрашивает инвентарь
makeEvent("SellFish")              -- Client → Server: продать рыбу по индексу
makeEvent("SellFishByName")        -- Client → Server: продать рыбу по itemName (кастомный UI)
makeEvent("SellAll")               -- Client → Server: продать весь улов
makeEvent("CoinsUpdated")          -- Server → Client: обновить монеты в HUD
makeEvent("RodGiven")              -- Server → Client: удочка добавлена в Backpack

-- ══ УДОЧКИ ══
makeFunction("GetRods")            -- Client запрашивает список удочек игрока
makeEvent("BuyRod")                -- Client → Server: купить удочку
makeEvent("EquipRod")              -- Client → Server: надеть удочку
makeEvent("RodPurchased")          -- Server → Client: подтверждение покупки
makeEvent("RodEquipped")           -- Server → Client: подтверждение смены удочки

-- ══ ЗОНЫ ══
makeFunction("GetZones")           -- Client запрашивает доступные зоны
makeEvent("EnterZone")             -- Client → Server: войти в зону
makeEvent("ZoneEntered")           -- Server → Client: подтверждение входа
makeEvent("UnlockZone")            -- Client → Server: купить разблокировку зоны
makeEvent("ZoneUnlocked")          -- Server → Client: зона разблокирована (success/reason)
makeFunction("GetZoneStatus")      -- Client: статус всех зон (unlocked/cost/rebirth)
makeEvent("OpenZoneMenu")          -- Server → Client: открыть меню зон (Zone Keeper NPC)
makeEvent("OpenNPC")               -- Server → Client: открыть UI конкретного NPC

-- ══ МОНЕТИЗАЦИЯ ══
makeFunction("GetShopData")        -- Client: статус геймпассов (owned) + цены
makeEvent("PromptGamePass")        -- Client → Server: запросить покупку геймпасса
makeEvent("PromptProduct")         -- Client → Server: запросить покупку продукта
makeEvent("GamePassPurchased")     -- Server → Client: геймпасс куплен
makeEvent("ToggleAutoSell")        -- Client → Server: вкл/выкл авто-продажу
makeFunction("GetAutoSellState")   -- Client: текущее состояние авто-продажи
makeFunction("GetActiveBoosts")    -- Client: активные бусты (геймпассы + временные)
makeEvent("BoostsUpdated")         -- Server → Client: бусты изменились (push)

-- ══ КОЛЛЕКЦИЯ / COMBO ══
makeEvent("CollectionComplete")    -- Server → Client: коллекция зоны собрана + награда
makeEvent("ComboUpdate")           -- Server → Client: текущая серия Perfect

-- ══ AFK ЭКСПЕДИЦИИ ══
makeEvent("StartExpedition")       -- Client → Server: запустить экспедицию
makeEvent("CollectExpedition")     -- Client → Server: забрать результаты
makeEvent("ExpeditionStarted")     -- Server → Client: подтверждение старта
makeEvent("ExpeditionComplete")    -- Server → Client: экспедиция завершена, список добычи
makeFunction("GetExpeditionStatus")-- Client запрашивает статус экспедиций

-- ══ REBIRTH ══
makeEvent("RequestRebirth")        -- Client → Server: хочет перерождение
makeEvent("RebirthComplete")       -- Server → Client: перерождение завершено

-- ══ DAILY REWARDS ══
makeFunction("GetDailyStatus")     -- Client запрашивает статус наград
makeEvent("ClaimDailyReward")      -- Client → Server: забрать награду дня
makeEvent("DailyRewardClaimed")    -- Server → Client: награда выдана

-- ══ СОБЫТИЯ (World Events) ══
makeEvent("WorldEventStarted")     -- Server → All Clients: началось событие
makeEvent("WorldEventEnded")       -- Server → All Clients: событие закончилось

-- ══ СЕРВЕРНЫЕ ОБЪЯВЛЕНИЯ ══
makeEvent("ServerAnnouncement")    -- Server → All Clients: показать баннер

-- ══ FISHDEX ══
makeFunction("GetFishDex")         -- Client запрашивает прогресс FishDex

-- ══ ДАННЫЕ ИГРОКА ══
makeFunction("GetPlayerData")      -- Client запрашивает все данные при загрузке
makeEvent("PlayerDataLoaded")      -- Server → Client: данные загружены, можно запускать UI

return Remotes

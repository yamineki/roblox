-- ServerScriptService/Services/FishInventoryService.lua
-- Reef Diver — Физический инвентарь рыб
-- Пойманная рыба = ObjectValue/Configuration объект в папке FishInventory игрока
-- Отображается в кастомном UI через 2D иконки (ImageLabel)
-- Также сохраняется в DataStore через DataService

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local FishData    = require(ReplicatedStorage.Modules.FishData)
local GameConfig  = require(ReplicatedStorage.Modules.GameConfig)

local FishInventoryService = {}

-- ══ СОЗДАТЬ ПАПКУ ИНВЕНТАРЯ ДЛЯ ИГРОКА ══
local function getOrCreateFishFolder(player)
    -- Хранится в PlayerGui чтобы быть доступной клиенту
    -- Альтернатива: папка в самом Player (более правильно для сервера)
    local folder = player:FindFirstChild("FishInventory")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "FishInventory"
        folder.Parent = player
    end
    return folder
end

-- ══ СОЗДАТЬ ОБЪЕКТ РЫБЫ ══
-- Каждая рыба в инвентаре = Configuration с атрибутами
local function createFishItem(catchEntry)
    local item = Instance.new("Configuration")
    -- Уникальный стабильный ID (нужен для точной синхронизации с DataStore)
    local uid = catchEntry.uid
    if not uid then
        uid = string.format("%d_%d", os.clock() * 1e6, math.random(100000, 999999))
        catchEntry.uid = uid
    end
    item.Name = catchEntry.id .. "_" .. uid

    -- Все данные рыбы как атрибуты
    item:SetAttribute("UID",          uid)
    item:SetAttribute("FishId",       catchEntry.id)
    item:SetAttribute("DisplayName",  catchEntry.displayName)
    item:SetAttribute("Rarity",       catchEntry.rarity)
    item:SetAttribute("Zone",         catchEntry.zone)
    item:SetAttribute("Size",         catchEntry.size)
    item:SetAttribute("SizeMult",     catchEntry.sizeMult)
    item:SetAttribute("Mutation",     catchEntry.mutation or "")
    item:SetAttribute("Value",        catchEntry.value)
    item:SetAttribute("IsPerfectHook",catchEntry.isPerfectHook or false)
    item:SetAttribute("IsPerfectCatch",catchEntry.isPerfectCatch or false)
    item:SetAttribute("Image",        catchEntry.image or "")  -- PLACEHOLDER ""
    item:SetAttribute("CaughtAt",     os.time())

    return item
end

-- ══ ДОБАВИТЬ РЫБУ В ИНВЕНТАРЬ ══
function FishInventoryService:AddFish(player, catchEntry)
    local folder = getOrCreateFishFolder(player)
    local item = createFishItem(catchEntry)
    item.Parent = folder

    -- Также сохранить в DataStore через DataService
    DataService:AddFishToInventory(player, catchEntry)

    return item
end

-- ══ УДАЛИТЬ РЫБУ ИЗ ИНВЕНТАРЯ ══
function FishInventoryService:RemoveFish(player, itemName)
    local folder = getOrCreateFishFolder(player)
    local item = folder:FindFirstChild(itemName)
    if not item then return false, 0 end

    -- Считать все атрибуты ДО уничтожения
    local value = item:GetAttribute("Value") or 0
    local uid   = item:GetAttribute("UID")
    item:Destroy()

    -- Синхронизировать DataStore по UID (точное совпадение)
    local data = DataService:Get(player)
    if data then
        for i, fish in ipairs(data.fishInventory) do
            if fish.uid == uid then
                table.remove(data.fishInventory, i)
                break
            end
        end
    end

    return true, value
end

-- ══ ПРОДАТЬ ВСЕ РЫБЫ ══
function FishInventoryService:SellAll(player)
    local folder = getOrCreateFishFolder(player)
    local total = 0

    for _, item in ipairs(folder:GetChildren()) do
        if item:IsA("Configuration") then
            total = total + (item:GetAttribute("Value") or 0)
            item:Destroy()
        end
    end

    -- Обновить DataService
    local data = DataService:Get(player)
    if data then
        data.fishInventory = {}
        DataService:AddCoins(player, total)
    end

    return total
end

-- ══ ОЧИСТИТЬ ВСЕ РЫБЫ (без начисления, для Rebirth) ══
function FishInventoryService:ClearAll(player)
    local folder = getOrCreateFishFolder(player)
    for _, item in ipairs(folder:GetChildren()) do
        if item:IsA("Configuration") then
            item:Destroy()
        end
    end
    local data = DataService:Get(player)
    if data then
        data.fishInventory = {}
    end
end

-- ══ ЗАГРУЗИТЬ РЫБЫ ИЗ DATASTORE ПРИ ВХОДЕ ══
function FishInventoryService:LoadFromDataStore(player)
    local data = DataService:Get(player)
    if not data then return end

    local folder = getOrCreateFishFolder(player)

    -- Очистить существующие
    for _, child in ipairs(folder:GetChildren()) do
        child:Destroy()
    end

    -- Восстановить из DataStore
    for _, fishEntry in ipairs(data.fishInventory or {}) do
        local item = createFishItem(fishEntry)
        item.Parent = folder
    end
end

-- ══ ПОЛУЧИТЬ СПИСОК РЫБ ══
function FishInventoryService:GetFishList(player)
    local folder = getOrCreateFishFolder(player)
    local list = {}

    for _, item in ipairs(folder:GetChildren()) do
        if item:IsA("Configuration") then
            table.insert(list, {
                itemName    = item.Name,
                fishId      = item:GetAttribute("FishId"),
                displayName = item:GetAttribute("DisplayName"),
                rarity      = item:GetAttribute("Rarity"),
                size        = item:GetAttribute("Size"),
                mutation    = item:GetAttribute("Mutation"),
                value       = item:GetAttribute("Value"),
                image       = item:GetAttribute("Image"),
            })
        end
    end

    return list
end

-- ИНИЦИАЛИЗАЦИЯ:
-- LoadFromDataStore вызывается из ServerMain ПОСЛЕ DataService:LoadPlayer,
-- чтобы исключить гонку порядка PlayerAdded-коннектов.

return FishInventoryService

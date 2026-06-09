-- StarterPlayerScripts/ShopController.client.lua
-- Reef Diver — Магазин удочек (Rod Master NPC)
-- PLACEHOLDER: модель NPC Rod Master = заглушка, замени позже

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RodData = require(ReplicatedStorage.Modules.RodData)
local Strings = require(ReplicatedStorage.Modules.Strings)

local Player    = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyRod      = Remotes:WaitForChild("BuyRod")
local GetRods     = Remotes:WaitForChild("GetRods")
local RodPurchased= Remotes:WaitForChild("RodPurchased")
local RodEquipped = Remotes:WaitForChild("RodEquipped")

-- Данные игрока (кэш на клиенте)
local ownedRods   = {}
local equippedRod = "WoodenRod"
local playerCoins = 0

local ShopGui = PlayerGui:WaitForChild("ShopGui", 15)
local isShopOpen = false

-- Обновить монеты из HUD (слушаем CoinsUpdated)
Remotes:WaitForChild("CoinsUpdated").OnClientEvent:Connect(function(amount)
    playerCoins = amount
end)

-- ══ ОТКРЫТЬ МАГАЗИН ══
local function openShop()
    if not ShopGui then return end

    -- Получить данные удочек с сервера
    local rodsData = GetRods:InvokeServer()
    if rodsData then
        ownedRods   = rodsData.owned   or {}
        equippedRod = rodsData.equipped or "WoodenRod"
    end

    -- Обновить UI карточек удочек
    local grid = ShopGui:FindFirstChild("RodGrid", true)
    if not grid then
        ShopGui.Enabled = true
        return
    end

    -- Очистить старые карточки
    for _, child in ipairs(grid:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- Создать карточки для каждой удочки
    for _, rodId in ipairs(RodData.ShopOrder) do
        local rod = RodData:GetRod(rodId)
        if not rod then continue end

        -- PLACEHOLDER: создать UI карточку программно
        -- В финале это будет Template-фрейм с клонированием
        local card = Instance.new("Frame")
        card.Name = rodId
        card.Size = UDim2.new(0.48, 0, 0, 120)
        card.Parent = grid

        -- Фон карточки
        -- card.BackgroundColor3 = ...
        -- PLACEHOLDER: card.Image = rod.icon (rbxassetid://...)

        -- Название
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "RodName"
        nameLabel.Text = rod.displayName
        nameLabel.Size = UDim2.new(1, 0, 0.25, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextScaled = true
        nameLabel.Parent = card

        -- Бонус
        local bonusLabel = Instance.new("TextLabel")
        bonusLabel.Name = "RodBonus"
        bonusLabel.Text = rod.description
        bonusLabel.Size = UDim2.new(1, 0, 0.35, 0)
        bonusLabel.Position = UDim2.new(0, 0, 0.25, 0)
        bonusLabel.BackgroundTransparency = 1
        bonusLabel.TextColor3 = Color3.fromRGB(180, 230, 200)
        bonusLabel.Font = Enum.Font.Gotham
        bonusLabel.TextScaled = true
        bonusLabel.Parent = card

        -- Цена / Кнопка
        local isOwned    = false
        local isEquipped = (equippedRod == rodId)
        for _, owned in ipairs(ownedRods) do
            if owned == rodId then isOwned = true; break end
        end

        local actionButton = Instance.new("TextButton")
        actionButton.Name = "ActionButton"
        actionButton.Size = UDim2.new(0.8, 0, 0.3, 0)
        actionButton.Position = UDim2.new(0.1, 0, 0.65, 0)
        actionButton.Font = Enum.Font.GothamBold
        actionButton.TextScaled = true
        actionButton.Parent = card

        if isOwned or rod.price == 0 then
            -- Уже куплена — экипировка через хотбар инвентаря (1-5)
            actionButton.Text = "✓ Куплено"
            actionButton.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
            actionButton.TextColor3 = Color3.new(1,1,1)
            actionButton.Active = false
        else
            actionButton.Text = "🪙 " .. tostring(rod.price)
            actionButton.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
            actionButton.TextColor3 = Color3.new(1,1,1)
            -- Проверить достаточно ли монет
            if playerCoins < rod.price then
                actionButton.BackgroundColor3 = Color3.fromRGB(80,80,80)
                actionButton.Text = "🔒 " .. tostring(rod.price)
            end
            actionButton.MouseButton1Click:Connect(function()
                BuyRod:FireServer(rodId)
            end)
        end
    end

    ShopGui.Enabled = true
    isShopOpen = true

    -- Анимация появления
    if ShopGui:IsA("ScreenGui") then
        local frame = ShopGui:FindFirstChildOfClass("Frame")
        if frame then
            frame.Position = UDim2.new(0.5, 0, 1.5, 0)
            TweenService:Create(
                frame,
                TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Position = UDim2.new(0.5, 0, 0.5, 0) }
            ):Play()
        end
    end
end

-- ══ ЗАКРЫТЬ МАГАЗИН ══
local function closeShop()
    if not ShopGui then return end
    isShopOpen = false

    local frame = ShopGui:FindFirstChildOfClass("Frame")
    if frame then
        TweenService:Create(
            frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.new(0.5, 0, 1.5, 0) }
        ):Play()
    end

    task.delay(0.35, function()
        ShopGui.Enabled = false
    end)
end

-- ══ ОТВЕТ СЕРВЕРА: ПОКУПКА ══
RodPurchased.OnClientEvent:Connect(function(result)
    if result.success then
        table.insert(ownedRods, result.rodId)
        -- Обновить UI магазина
        if isShopOpen then openShop() end
    else
        -- Показать ошибку
        if result.reason == "not_enough_coins" then
            -- TODO: показать popup "Недостаточно монет!"
            warn("[Shop] Не хватает монет")
        end
    end
end)

-- ══ НАДЕЛИ УДОЧКУ ══
RodEquipped.OnClientEvent:Connect(function(rodId)
    equippedRod = rodId
    if isShopOpen then openShop() end
end)

-- ══ ВЗАИМОДЕЙСТВИЕ С NPC ══
-- PLACEHOLDER: модель NPC Rod Master
-- Когда реальная модель будет добавлена, подключи ProximityPrompt здесь
-- Пример:
--[[
local RodMasterNPC = workspace:WaitForChild("Village"):WaitForChild("RodMaster")  -- PLACEHOLDER путь
local prompt = RodMasterNPC:FindFirstChildOfClass("ProximityPrompt")
if prompt then
    prompt.Triggered:Connect(function(plr)
        if plr == Player then openShop() end
    end)
end
]]

-- Открытие магазина по взаимодействию с Rod Master NPC
local OpenNPC = Remotes:WaitForChild("OpenNPC")
OpenNPC.OnClientEvent:Connect(function(npcId)
    if npcId == "RodMaster" then
        openShop()
    end
end)

-- Временная кнопка для тестирования (можно убрать — NPC уже работают)
local testButton = PlayerGui:WaitForChild("TestButtons", 5)
if testButton then
    local shopBtn = testButton:FindFirstChild("OpenShop")
    if shopBtn then
        shopBtn.MouseButton1Click:Connect(openShop)
    end
    local closeBtn = testButton:FindFirstChild("CloseShop")
    if closeBtn then
        closeBtn.MouseButton1Click:Connect(closeShop)
    end
end

-- Закрытие по кнопке в GUI
if ShopGui then
    local closeBtn = ShopGui:FindFirstChild("CloseButton", true)
    if closeBtn then
        closeBtn.MouseButton1Click:Connect(closeShop)
    end
end

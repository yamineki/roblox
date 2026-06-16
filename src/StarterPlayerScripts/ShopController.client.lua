-- StarterPlayerScripts/ShopController.client.lua
-- Reef Diver — Магазин удочек (Rod Master NPC)
-- PLACEHOLDER: модель NPC Rod Master = заглушка, замени позже

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RodData = require(ReplicatedStorage.Modules.RodData)
local Strings = require(ReplicatedStorage.Modules.Strings)
local SoundFX = require(ReplicatedStorage.Modules.SoundFX)
local ShopBridge = require(ReplicatedStorage.Modules.ShopBridge)

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
    if ShopGui then
        local coinsLbl = ShopGui:FindFirstChild("ShopCoinsLabel", true)
        if coinsLbl then coinsLbl.Text = "🪙 " .. tostring(playerCoins) end
    end
end)

-- ══ ОТКРЫТЬ МАГАЗИН ══
local function rebuildRodGrid()
    if not ShopGui then return end
    local grid = ShopGui:FindFirstChild("RodGrid", true)
    if not grid then return end

    for _, child in ipairs(grid:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local coinsLbl = ShopGui:FindFirstChild("ShopCoinsLabel", true)
    if coinsLbl then coinsLbl.Text = "🪙 " .. tostring(playerCoins) end

    for _, rodId in ipairs(RodData.ShopOrder) do
        local rod = RodData:GetRod(rodId)
        if not rod then continue end

        local card = Instance.new("Frame")
        card.Name = rodId
        card.Size = UDim2.new(0.48, 0, 0, 120)
        card.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        card.BorderSizePixel = 0
        card.Parent = grid

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = card

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = Color3.fromRGB(70, 75, 85)
        cardStroke.Thickness = 1
        cardStroke.Parent = card

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "RodName"
        nameLabel.Text = rod.displayName
        nameLabel.Size = UDim2.new(1, 0, 0.25, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextScaled = true
        nameLabel.Parent = card

        local bonusLabel = Instance.new("TextLabel")
        bonusLabel.Name = "RodBonus"
        bonusLabel.Text = rod.description or ""
        bonusLabel.Size = UDim2.new(1, -8, 0.35, 0)
        bonusLabel.Position = UDim2.new(0, 4, 0.25, 0)
        bonusLabel.BackgroundTransparency = 1
        bonusLabel.TextColor3 = Color3.fromRGB(160, 165, 175)
        bonusLabel.Font = Enum.Font.Gotham
        bonusLabel.TextScaled = true
        bonusLabel.TextWrapped = true
        bonusLabel.Parent = card

        local isOwned = (rod.price == 0)
        for _, owned in ipairs(ownedRods) do
            if owned == rodId then isOwned = true; break end
        end

        local actionButton = Instance.new("TextButton")
        actionButton.Name = "ActionButton"
        actionButton.Size = UDim2.new(0.8, 0, 0.3, 0)
        actionButton.Position = UDim2.new(0.1, 0, 0.65, 0)
        actionButton.Font = Enum.Font.GothamBold
        actionButton.TextScaled = true
        actionButton.BorderSizePixel = 0
        actionButton.Parent = card
        local abCorner = Instance.new("UICorner")
        abCorner.CornerRadius = UDim.new(0, 4)
        abCorner.Parent = actionButton

        if isOwned then
            actionButton.Text = "✓ Owned"
            actionButton.BackgroundColor3 = Color3.fromRGB(50, 52, 60)
            actionButton.TextColor3 = Color3.fromRGB(160, 165, 175)
            actionButton.Active = false
        else
            local canAfford = (playerCoins >= rod.price)
            actionButton.Text = (canAfford and "🪙 " or "🔒 ") .. tostring(rod.price)
            actionButton.BackgroundColor3 = canAfford
                and Color3.fromRGB(70, 160, 90)
                or  Color3.fromRGB(50, 52, 60)
            actionButton.TextColor3 = Color3.new(1,1,1)
            actionButton.MouseButton1Click:Connect(function()
                SoundFX.Play("Click")
                BuyRod:FireServer(rodId)
            end)
        end
    end
end

local function openShop()
    if not ShopGui then return end
    isShopOpen = true
    ShopGui.Enabled = true
    SoundFX.Play("Open")

    -- Анимация появления — сразу
    local frame = ShopGui:FindFirstChildOfClass("Frame")
    if frame then
        frame.Position = UDim2.new(0.5, 0, 1.5, 0)
        TweenService:Create(
            frame,
            TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Position = UDim2.new(0.5, 0, 0.5, 0) }
        ):Play()
    end

    -- Загрузить данные удочек асинхронно, не блокируя открытие
    task.spawn(function()
        local ok, rodsData = pcall(function() return GetRods:InvokeServer() end)
        if ok and rodsData and isShopOpen then
            ownedRods   = rodsData.owned   or {}
            equippedRod = rodsData.equipped or "WoodenRod"
            rebuildRodGrid()
        end
    end)
end

-- ══ ЗАКРЫТЬ МАГАЗИН ══
local function closeShop()
    if not ShopGui then return end
    isShopOpen = false
    SoundFX.Play("Close")

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
        SoundFX.Play("Purchase")
        table.insert(ownedRods, result.rodId)
        if isShopOpen then rebuildRodGrid() end
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
    if isShopOpen then rebuildRodGrid() end
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

-- Открытие магазина теперь происходит через NPCDialog после положительного
-- выбора в диалоге (см. NPCDialog.client.lua + ShopBridge)
ShopBridge.OpenRodShop = openShop

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

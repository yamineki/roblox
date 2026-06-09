-- StarterPlayerScripts/MonetizationShop.client.lua
-- Reef Diver — UI магазина геймпассов и продуктов
-- Открывается кнопкой 💎 в HUD

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Modules.MonetizationConfig)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetShopData    = Remotes:WaitForChild("GetShopData")
local PromptGamePass = Remotes:WaitForChild("PromptGamePass")
local PromptProduct  = Remotes:WaitForChild("PromptProduct")
local GamePassPurchased = Remotes:WaitForChild("GamePassPurchased")
local ToggleAutoSell = Remotes:WaitForChild("ToggleAutoSell")
local GetAutoSellState = Remotes:WaitForChild("GetAutoSellState")

local function corner(o, r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=o end
local function stroke(o, col, t) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=t or 1.5; s.Transparency=0.4; s.Parent=o end

-- ══ GUI ══
local gui = Instance.new("ScreenGui")
gui.Name = "MonetizationShop"
gui.DisplayOrder = 129
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = PlayerGui

local dim = Instance.new("TextButton")
dim.Size = UDim2.fromScale(1,1)
dim.BackgroundColor3 = Color3.new(0,0,0)
dim.BackgroundTransparency = 0.5
dim.Text = ""
dim.AutoButtonColor = false
dim.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(640, 520)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(8, 16, 32)
panel.BorderSizePixel = 0
panel.Parent = gui
corner(panel, 14)
stroke(panel, Color3.fromRGB(255, 200, 60), 1.5)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "💎 Магазин"
title.TextColor3 = Color3.fromRGB(255, 210, 80)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.Parent = panel

-- Табы: Геймпассы / Продукты
local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, -32, 0, 36)
tabRow.Position = UDim2.fromOffset(16, 52)
tabRow.BackgroundTransparency = 1
tabRow.Parent = panel

local function makeTab(name, text, x)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.fromOffset(150, 36)
    btn.Position = UDim2.fromOffset(x, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20, 32, 52)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = text
    btn.Parent = tabRow
    corner(btn, 8)
    return btn
end
local tabGamePasses = makeTab("TabGP", "Геймпассы", 0)
local tabProducts   = makeTab("TabProd", "Монеты и бусты", 158)

-- Скролл-контейнер
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Items"
scroll.Size = UDim2.new(1, -32, 1, -156)
scroll.Position = UDim2.fromOffset(16, 96)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 60)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.Parent = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(290, 92)
grid.CellPadding = UDim2.fromOffset(12, 12)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(200, 40)
closeBtn.Position = UDim2.new(0.5, 0, 1, -48)
closeBtn.AnchorPoint = Vector2.new(0.5, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Text = "✕ Закрыть"
closeBtn.Parent = panel
corner(closeBtn, 8)

-- ══ СОСТОЯНИЕ ══
local currentTab = "gamepasses"
local ownedCache = {}

-- ══ СОЗДАТЬ КАРТОЧКУ ══
local function makeCard(cfg, key, isOwned, isProduct, order)
    local card = Instance.new("Frame")
    card.Name = key
    card.BackgroundColor3 = Color3.fromRGB(14, 24, 42)
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = scroll
    corner(card, 10)
    stroke(card, isOwned and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 200, 60), 1)

    -- Иконка (PLACEHOLDER emoji)
    local iconHolder = Instance.new("Frame")
    iconHolder.Size = UDim2.fromOffset(56, 56)
    iconHolder.Position = UDim2.fromOffset(10, 10)
    iconHolder.BackgroundColor3 = Color3.fromRGB(22, 36, 58)
    iconHolder.BorderSizePixel = 0
    iconHolder.Parent = card
    corner(iconHolder, 8)

    local iconImg = Instance.new("ImageLabel")
    iconImg.Size = UDim2.fromScale(1,1)
    iconImg.BackgroundTransparency = 1
    iconImg.Image = cfg.icon ~= "" and cfg.icon or ""  -- PLACEHOLDER
    iconImg.Parent = iconHolder
    if cfg.icon == "" then
        local ph = Instance.new("TextLabel")
        ph.Size = UDim2.fromScale(1,1)
        ph.BackgroundTransparency = 1
        ph.Text = isProduct and "🪙" or "🎁"
        ph.TextScaled = true
        ph.Font = Enum.Font.GothamBold
        ph.Parent = iconHolder
    end

    -- Название
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.fromOffset(150, 22)
    nameLabel.Position = UDim2.fromOffset(76, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = cfg.displayName
    nameLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 15
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card

    -- Описание
    if cfg.description then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.fromOffset(204, 30)
        desc.Position = UDim2.fromOffset(76, 32)
        desc.BackgroundTransparency = 1
        desc.Text = cfg.description
        desc.TextColor3 = Color3.fromRGB(140, 180, 215)
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top
        desc.TextWrapped = true
        desc.Parent = card
    end

    -- Кнопка покупки
    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.fromOffset(200, 24)
    buyBtn.Position = UDim2.fromOffset(76, 62)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 13
    buyBtn.TextColor3 = Color3.new(1,1,1)
    buyBtn.Parent = card
    corner(buyBtn, 6)

    if isOwned then
        buyBtn.Text = "✓ Куплено"
        buyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
        buyBtn.Active = false
    elseif cfg.id == 0 then
        buyBtn.Text = "Скоро"
        buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        buyBtn.Active = false
    else
        buyBtn.Text = "R$ " .. (cfg.priceRobux or "?")
        buyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
        buyBtn.MouseButton1Click:Connect(function()
            if isProduct then
                PromptProduct:FireServer(key)
            else
                PromptGamePass:FireServer(key)
            end
        end)
    end

    return card
end

-- ══ ПОСТРОИТЬ СПИСОК ══
local function rebuild()
    for _, ch in ipairs(scroll:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end

    if currentTab == "gamepasses" then
        local shopData = GetShopData:InvokeServer()
        ownedCache = (shopData and shopData.owned) or {}
        for i, key in ipairs(MonetizationConfig.GamePassOrder) do
            local cfg = MonetizationConfig.GamePasses[key]
            if cfg then
                makeCard(cfg, key, ownedCache[key] == true, false, i)
            end
        end
        local rows = math.ceil(#MonetizationConfig.GamePassOrder / 2)
        scroll.CanvasSize = UDim2.fromOffset(0, rows * 104 + 12)
    else
        for i, key in ipairs(MonetizationConfig.ProductOrder) do
            local cfg = MonetizationConfig.Products[key]
            if cfg then
                makeCard(cfg, key, false, true, i)
            end
        end
        local rows = math.ceil(#MonetizationConfig.ProductOrder / 2)
        scroll.CanvasSize = UDim2.fromOffset(0, rows * 104 + 12)
    end

    -- Подсветка активного таба
    tabGamePasses.BackgroundColor3 = currentTab == "gamepasses"
        and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(20, 32, 52)
    tabGamePasses.TextColor3 = currentTab == "gamepasses"
        and Color3.fromRGB(20, 20, 20) or Color3.new(1,1,1)
    tabProducts.BackgroundColor3 = currentTab == "products"
        and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(20, 32, 52)
    tabProducts.TextColor3 = currentTab == "products"
        and Color3.fromRGB(20, 20, 20) or Color3.new(1,1,1)
end

tabGamePasses.MouseButton1Click:Connect(function()
    currentTab = "gamepasses"; rebuild()
end)
tabProducts.MouseButton1Click:Connect(function()
    currentTab = "products"; rebuild()
end)

-- ══ ОТКРЫТЬ / ЗАКРЫТЬ ══
local function open()
    rebuild()
    gui.Enabled = true
    panel.Position = UDim2.new(0.5, 0, 0.6, 0)
    TweenService:Create(panel,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
end
local function close() gui.Enabled = false end

closeBtn.MouseButton1Click:Connect(close)
dim.MouseButton1Click:Connect(close)

-- Обновить после покупки геймпасса
GamePassPurchased.OnClientEvent:Connect(function(key)
    if gui.Enabled and currentTab == "gamepasses" then
        rebuild()
    end
end)

-- ══ КНОПКА ОТКРЫТИЯ В HUD ══
local shopBtn = Instance.new("ScreenGui")
shopBtn.Name = "ShopButton"
shopBtn.ResetOnSpawn = false
shopBtn.DisplayOrder = 121
shopBtn.Parent = PlayerGui

local btn = Instance.new("TextButton")
btn.Size = UDim2.fromOffset(56, 56)
btn.Position = UDim2.new(1, -70, 0.5, -28)
btn.BackgroundColor3 = Color3.fromRGB(255, 190, 50)
btn.Text = "💎"
btn.TextScaled = true
btn.Font = Enum.Font.GothamBold
btn.Parent = shopBtn
corner(btn, 14)
stroke(btn, Color3.fromRGB(255, 230, 150), 2)
btn.MouseButton1Click:Connect(open)

print("[ReefDiver] MonetizationShop инициализирован ✓")

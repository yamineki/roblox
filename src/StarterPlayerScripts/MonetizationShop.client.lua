-- StarterPlayerScripts/MonetizationShop.client.lua
-- Reef Diver — UI магазина геймпассов и продуктов
-- Открывается кнопкой 💎 в HUD (MonetizationBtn в MainHUD)

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Modules.MonetizationConfig)
local SoundFX = require(ReplicatedStorage.Modules.SoundFX)
local ShopBridge = require(ReplicatedStorage.Modules.ShopBridge)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetShopData       = Remotes:WaitForChild("GetShopData")
local PromptGamePass    = Remotes:WaitForChild("PromptGamePass")
local PromptProduct     = Remotes:WaitForChild("PromptProduct")
local GamePassPurchased = Remotes:WaitForChild("GamePassPurchased")

local function corner(o, r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 4); c.Parent=o end
local function stroke(o, col, t) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=t or 1; s.Transparency=0; s.Parent=o end

-- ══ GUI (создан UIBuilder.lua) ══
local gui          = PlayerGui:WaitForChild("MonetizationShop", 20)
local dim          = gui:WaitForChild("Dim")
local panel        = gui:WaitForChild("Panel")
local tabRow       = panel:WaitForChild("TabRow")
local tabGamePasses= tabRow:WaitForChild("TabGP")
local tabProducts  = tabRow:WaitForChild("TabProd")
local scroll       = panel:WaitForChild("Items")
local closeBtn     = panel:WaitForChild("CloseBtn")
local balanceLabel = panel:WaitForChild("BalanceLabel")

-- ══ СОСТОЯНИЕ ══
local currentTab = "gamepasses"
local ownedCache = {}

-- ══ БАЛАНС ══
Remotes:WaitForChild("CoinsUpdated").OnClientEvent:Connect(function(amount)
    balanceLabel.Text = "🪙 " .. tostring(amount)
end)

-- ══ СОЗДАТЬ КАРТОЧКУ ══
local function makeCard(cfg, key, isOwned, isProduct, order)
    local card = Instance.new("Frame")
    card.Name = key
    card.BackgroundColor3 = Color3.fromRGB(245, 248, 255)
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = scroll
    corner(card, 8)
    stroke(card, isOwned and Color3.fromRGB(50,175,100) or Color3.fromRGB(210,220,235), 1.5)

    local iconHolder = Instance.new("Frame")
    iconHolder.Size = UDim2.fromOffset(54, 54)
    iconHolder.Position = UDim2.fromOffset(10, 10)
    iconHolder.BackgroundColor3 = Color3.fromRGB(125, 70, 195)
    iconHolder.BackgroundTransparency = 0.2
    iconHolder.BorderSizePixel = 0
    iconHolder.Parent = card
    corner(iconHolder, 8)

    local iconImg = Instance.new("ImageLabel")
    iconImg.Size = UDim2.fromScale(1,1)
    iconImg.BackgroundTransparency = 1
    iconImg.Image = cfg.icon ~= "" and cfg.icon or ""
    iconImg.Parent = iconHolder
    if cfg.icon == "" then
        local ph = Instance.new("TextLabel")
        ph.Size = UDim2.fromScale(1,1)
        ph.BackgroundTransparency = 1
        ph.Text = isProduct and "🪙" or "🎁"
        ph.TextScaled = true
        ph.Font = Enum.Font.GothamBold
        ph.TextColor3 = Color3.new(1,1,1)
        ph.Parent = iconHolder
    end

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.fromOffset(150, 22)
    nameLabel.Position = UDim2.fromOffset(72, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = cfg.displayName
    nameLabel.TextColor3 = Color3.fromRGB(30, 35, 50)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card

    if cfg.description then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.fromOffset(204, 28)
        desc.Position = UDim2.fromOffset(72, 30)
        desc.BackgroundTransparency = 1
        desc.Text = cfg.description
        desc.TextColor3 = Color3.fromRGB(100, 110, 135)
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top
        desc.TextWrapped = true
        desc.Parent = card
    end

    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.fromOffset(200, 26)
    buyBtn.Position = UDim2.fromOffset(72, 60)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 13
    buyBtn.TextColor3 = Color3.new(1,1,1)
    buyBtn.BorderSizePixel = 0
    buyBtn.Parent = card
    corner(buyBtn, 8)

    if isOwned then
        buyBtn.Text = "✓ Owned"
        buyBtn.BackgroundColor3 = Color3.fromRGB(50, 175, 100)
        buyBtn.Active = false
    elseif cfg.id == 0 then
        buyBtn.Text = "Coming soon"
        buyBtn.BackgroundColor3 = Color3.fromRGB(170, 175, 190)
        buyBtn.Active = false
    else
        buyBtn.Text = "R$ " .. (cfg.priceRobux or "?")
        buyBtn.BackgroundColor3 = Color3.fromRGB(125, 70, 195)
        buyBtn.MouseButton1Click:Connect(function()
            SoundFX.Play("Purchase")
            if isProduct then
                PromptProduct:FireServer(key)
            else
                PromptGamePass:FireServer(key)
            end
        end)
    end
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
            if cfg then makeCard(cfg, key, ownedCache[key] == true, false, i) end
        end
        local rows = math.ceil(#MonetizationConfig.GamePassOrder / 2)
        scroll.CanvasSize = UDim2.fromOffset(0, rows * 104 + 12)
    else
        for i, key in ipairs(MonetizationConfig.ProductOrder) do
            local cfg = MonetizationConfig.Products[key]
            if cfg then makeCard(cfg, key, false, true, i) end
        end
        local rows = math.ceil(#MonetizationConfig.ProductOrder / 2)
        scroll.CanvasSize = UDim2.fromOffset(0, rows * 104 + 12)
    end

    local ACTIVE_TAB   = Color3.fromRGB(125, 70, 195)
    local INACTIVE_TAB = Color3.fromRGB(80, 50, 120)
    tabGamePasses.BackgroundColor3 = currentTab == "gamepasses" and ACTIVE_TAB or INACTIVE_TAB
    tabGamePasses.TextColor3 = Color3.new(1,1,1)
    tabProducts.BackgroundColor3 = currentTab == "products" and ACTIVE_TAB or INACTIVE_TAB
    tabProducts.TextColor3 = Color3.new(1,1,1)
end

tabGamePasses.MouseButton1Click:Connect(function()
    SoundFX.Play("Click")
    currentTab = "gamepasses"; rebuild()
end)
tabProducts.MouseButton1Click:Connect(function()
    SoundFX.Play("Click")
    currentTab = "products"; rebuild()
end)

-- ══ ОТКРЫТЬ / ЗАКРЫТЬ ══
local function open()
    rebuild()
    gui.Enabled = true
    SoundFX.Play("Open")
    panel.Position = UDim2.new(0.5, 0, 0.6, 0)
    TweenService:Create(panel,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
end
local function close()
    SoundFX.Play("Close")
    gui.Enabled = false
end

closeBtn.MouseButton1Click:Connect(close)
dim.MouseButton1Click:Connect(close)

GamePassPurchased.OnClientEvent:Connect(function()
    SoundFX.Play("Purchase")
    if gui.Enabled and currentTab == "gamepasses" then rebuild() end
end)

-- ══ КНОПКА В MAIN HUD ══
task.spawn(function()
    local mainHud = PlayerGui:WaitForChild("MainHUD", 20)
    if not mainHud then return end
    local monBtn = mainHud:WaitForChild("MonetizationBtn", 10)
    if monBtn then
        monBtn.MouseButton1Click:Connect(open)
    end
end)

ShopBridge.Register("MonetizationShop", open)
ShopBridge.OpenMonetizationShop = open

print("[ReefDiver] MonetizationShop инициализирован ✓")

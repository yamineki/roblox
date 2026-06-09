-- StarterPlayerScripts/ZoneController.client.lua
-- Reef Diver — UI путешествия по зонам (Zone Keeper NPC)
-- Телепорт между разблокированными зонами + покупка новых за монеты

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Strings    = require(ReplicatedStorage.Modules.Strings)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetZoneStatus = Remotes:WaitForChild("GetZoneStatus")
local UnlockZone    = Remotes:WaitForChild("UnlockZone")
local ZoneUnlocked  = Remotes:WaitForChild("ZoneUnlocked")
local EnterZone     = Remotes:WaitForChild("EnterZone")
local ZoneEntered   = Remotes:WaitForChild("ZoneEntered")
local OpenZoneMenu  = Remotes:WaitForChild("OpenZoneMenu")
local CoinsUpdated  = Remotes:WaitForChild("CoinsUpdated")

local playerCoins = 0
CoinsUpdated.OnClientEvent:Connect(function(amount) playerCoins = amount end)

-- ══ ПОСТРОИТЬ GUI ══
local gui = Instance.new("ScreenGui")
gui.Name = "ZoneMenu"
gui.DisplayOrder = 127
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = PlayerGui

local function corner(o, r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=o end
local function stroke(o, col, t) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=t or 1.5; s.Transparency=0.4; s.Parent=o end

-- Затемнение фона
local dim = Instance.new("TextButton")
dim.Name = "Dim"
dim.Size = UDim2.fromScale(1,1)
dim.BackgroundColor3 = Color3.new(0,0,0)
dim.BackgroundTransparency = 0.5
dim.Text = ""
dim.AutoButtonColor = false
dim.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(560, 480)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(8, 16, 32)
panel.BorderSizePixel = 0
panel.Parent = gui
corner(panel, 14)
stroke(panel, Color3.fromRGB(0, 180, 255), 1.5)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 56)
title.BackgroundTransparency = 1
title.Text = "🌀 Путешествие по зонам"
title.TextColor3 = Color3.fromRGB(0, 220, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.Parent = panel

local list = Instance.new("Frame")
list.Name = "List"
list.Size = UDim2.new(1, -32, 1, -120)
list.Position = UDim2.fromOffset(16, 60)
list.BackgroundTransparency = 1
list.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(200, 40)
closeBtn.Position = UDim2.new(0.5, 0, 1, -50)
closeBtn.AnchorPoint = Vector2.new(0.5, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Text = "✕ Закрыть"
closeBtn.Parent = panel
corner(closeBtn, 8)

-- Цвета зон
local ZONE_COLORS = {
    SunnyReef   = Color3.fromRGB(0, 200, 255),
    CoralTrench = Color3.fromRGB(0, 180, 150),
    OpenOcean   = Color3.fromRGB(50, 100, 200),
    DarkWaters  = Color3.fromRGB(120, 40, 200),
    Abyss       = Color3.fromRGB(80, 10, 110),
}

-- ══ ПОСТРОИТЬ СТРОКИ ЗОН ══
local function buildRows()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local status = GetZoneStatus:InvokeServer()
    if not status then return end

    for _, zoneName in ipairs(GameConfig.ZoneOrder) do
        local z = status.zones[zoneName]
        if not z then continue end

        local row = Instance.new("Frame")
        row.Name = zoneName
        row.Size = UDim2.new(1, 0, 0, 60)
        row.BackgroundColor3 = Color3.fromRGB(12, 22, 40)
        row.BackgroundTransparency = 0.2
        row.LayoutOrder = z.order
        row.Parent = list
        corner(row, 8)
        stroke(row, ZONE_COLORS[zoneName] or Color3.new(1,1,1), z.current and 2.5 or 1)

        -- Цветная метка зоны слева
        local tag = Instance.new("Frame")
        tag.Size = UDim2.fromOffset(6, 44)
        tag.Position = UDim2.fromOffset(8, 8)
        tag.BackgroundColor3 = ZONE_COLORS[zoneName] or Color3.new(1,1,1)
        tag.BorderSizePixel = 0
        tag.Parent = row
        corner(tag, 3)

        -- Название + глубина
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, 0, 0.55, 0)
        nameLabel.Position = UDim2.fromOffset(24, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = (Strings["Zone_" .. zoneName] or zoneName)
        nameLabel.TextColor3 = Color3.new(1,1,1)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 16
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row

        local depthLabel = Instance.new("TextLabel")
        depthLabel.Size = UDim2.new(0.5, 0, 0.4, 0)
        depthLabel.Position = UDim2.fromOffset(24, 34)
        depthLabel.BackgroundTransparency = 1
        depthLabel.Text = z.depthLabel
        depthLabel.TextColor3 = Color3.fromRGB(120, 170, 210)
        depthLabel.Font = Enum.Font.Gotham
        depthLabel.TextSize = 12
        depthLabel.TextXAlignment = Enum.TextXAlignment.Left
        depthLabel.Parent = row

        -- Кнопка действия справа
        local actionBtn = Instance.new("TextButton")
        actionBtn.Size = UDim2.fromOffset(150, 40)
        actionBtn.Position = UDim2.new(1, -160, 0.5, -20)
        actionBtn.Font = Enum.Font.GothamBold
        actionBtn.TextSize = 14
        actionBtn.TextColor3 = Color3.new(1,1,1)
        actionBtn.Parent = row
        corner(actionBtn, 6)

        if z.current then
            actionBtn.Text = "📍 Вы здесь"
            actionBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
            actionBtn.Active = false
        elseif z.unlocked then
            actionBtn.Text = "Перейти →"
            actionBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
            actionBtn.MouseButton1Click:Connect(function()
                EnterZone:FireServer(zoneName)
                gui.Enabled = false
            end)
        else
            -- Заблокирована — показать условие
            if (status.rebirthLevel or 0) < (z.minRebirth or 0) then
                actionBtn.Text = "🔒 Rebirth " .. z.minRebirth
                actionBtn.BackgroundColor3 = Color3.fromRGB(90, 60, 120)
                actionBtn.Active = false
            else
                actionBtn.Text = "🪙 " .. z.unlockCost
                actionBtn.BackgroundColor3 = (playerCoins >= z.unlockCost)
                    and Color3.fromRGB(200, 130, 0)
                    or Color3.fromRGB(80, 80, 80)
                actionBtn.MouseButton1Click:Connect(function()
                    UnlockZone:FireServer(zoneName)
                end)
            end
        end
    end
end

-- ══ ОТКРЫТЬ / ЗАКРЫТЬ ══
local function openMenu()
    buildRows()
    gui.Enabled = true
    panel.Position = UDim2.new(0.5, 0, 0.6, 0)
    TweenService:Create(panel,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
end

local function closeMenu()
    gui.Enabled = false
end

OpenZoneMenu.OnClientEvent:Connect(openMenu)
closeBtn.MouseButton1Click:Connect(closeMenu)
dim.MouseButton1Click:Connect(closeMenu)

-- Перестроить после покупки
ZoneUnlocked.OnClientEvent:Connect(function(payload)
    if payload.success and gui.Enabled then
        buildRows()
    end
end)
ZoneEntered.OnClientEvent:Connect(function(payload)
    if gui.Enabled then buildRows() end
end)

print("[ReefDiver] ZoneController инициализирован ✓")

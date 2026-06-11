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

-- ══ GUI (создан UIBuilder.lua) ══
local gui      = PlayerGui:WaitForChild("ZoneMenu", 20)
local dim      = gui:WaitForChild("Dim")
local panel    = gui:WaitForChild("Panel")
local list     = panel:WaitForChild("List")
local closeBtn = panel:WaitForChild("CloseBtn")

-- Цвета зон
local ZONE_COLORS = {
    SunnyReef   = Color3.fromRGB(0, 200, 255),
    CoralTrench = Color3.fromRGB(0, 180, 150),
    OpenOcean   = Color3.fromRGB(50, 100, 200),
    DarkWaters  = Color3.fromRGB(120, 40, 200),
    Abyss       = Color3.fromRGB(80, 10, 110),
}

local function corner(o, r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 4); c.Parent=o end
local function stroke(o, col, t) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=t or 1; s.Transparency=0; s.Parent=o end

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
        row.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        row.BackgroundTransparency = 0
        row.LayoutOrder = z.order
        row.Parent = list
        corner(row, 4)
        stroke(row, z.current and Color3.fromRGB(235, 235, 235) or Color3.fromRGB(70, 75, 85), z.current and 2 or 1)

        local tag = Instance.new("Frame")
        tag.Size = UDim2.fromOffset(6, 44)
        tag.Position = UDim2.fromOffset(8, 8)
        tag.BackgroundColor3 = ZONE_COLORS[zoneName] or Color3.new(1,1,1)
        tag.BorderSizePixel = 0
        tag.Parent = row
        corner(tag, 3)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, 0, 0.55, 0)
        nameLabel.Position = UDim2.fromOffset(24, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = (Strings["Zone_" .. zoneName] or zoneName)
        nameLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 16
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row

        local depthLabel = Instance.new("TextLabel")
        depthLabel.Size = UDim2.new(0.5, 0, 0.4, 0)
        depthLabel.Position = UDim2.fromOffset(24, 34)
        depthLabel.BackgroundTransparency = 1
        depthLabel.Text = z.depthLabel
        depthLabel.TextColor3 = Color3.fromRGB(160, 165, 175)
        depthLabel.Font = Enum.Font.Gotham
        depthLabel.TextSize = 12
        depthLabel.TextXAlignment = Enum.TextXAlignment.Left
        depthLabel.Parent = row

        local actionBtn = Instance.new("TextButton")
        actionBtn.Size = UDim2.fromOffset(150, 40)
        actionBtn.Position = UDim2.new(1, -160, 0.5, -20)
        actionBtn.Font = Enum.Font.GothamBold
        actionBtn.TextSize = 14
        actionBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
        actionBtn.BorderSizePixel = 0  -- БАГФИКС: убрана серая рамка по умолчанию
        actionBtn.Parent = row
        corner(actionBtn, 4)

        if z.current then
            actionBtn.Text = "📍 Вы здесь"
            actionBtn.BackgroundColor3 = Color3.fromRGB(50, 52, 60)
            actionBtn.Active = false
        elseif z.unlocked then
            actionBtn.Text = "Перейти →"
            actionBtn.BackgroundColor3 = Color3.fromRGB(70, 160, 90)
            actionBtn.MouseButton1Click:Connect(function()
                EnterZone:FireServer(zoneName)
                gui.Enabled = false
            end)
        else
            if (status.rebirthLevel or 0) < (z.minRebirth or 0) then
                actionBtn.Text = "🔒 Rebirth " .. z.minRebirth
                actionBtn.BackgroundColor3 = Color3.fromRGB(50, 52, 60)
                actionBtn.Active = false
            else
                actionBtn.Text = "🪙 " .. z.unlockCost
                actionBtn.BackgroundColor3 = (playerCoins >= z.unlockCost)
                    and Color3.fromRGB(70, 160, 90)
                    or Color3.fromRGB(50, 52, 60)
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

ZoneUnlocked.OnClientEvent:Connect(function(payload)
    if payload.success and gui.Enabled then buildRows() end
end)
ZoneEntered.OnClientEvent:Connect(function()
    if gui.Enabled then buildRows() end
end)

print("[ReefDiver] ZoneController инициализирован ✓")

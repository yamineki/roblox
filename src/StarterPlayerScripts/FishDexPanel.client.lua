-- StarterPlayerScripts/FishDexPanel.client.lua
-- Reef Diver — Fish collection / dex panel (opened via Collector NPC)

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishData   = require(ReplicatedStorage.Modules.FishData)
local Strings    = require(ReplicatedStorage.Modules.Strings)
local ShopBridge = require(ReplicatedStorage.Modules.ShopBridge)
local okFX, SoundFX = pcall(function() return require(ReplicatedStorage.Modules.SoundFX) end)
local function playSound(n) if okFX and SoundFX then SoundFX.Play(n) end end

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local GetFishDex = Remotes:WaitForChild("GetFishDex")

local gui = PlayerGui:WaitForChild("FishDexPanel", 15)
if not gui then return end

local panel         = gui:WaitForChild("Panel")
local closeBtn      = panel:WaitForChild("CloseBtn")
local progressLabel = panel:WaitForChild("ProgressLabel")
local progressBar   = panel:WaitForChild("ProgressBar")
local progressFill  = progressBar:WaitForChild("Fill")
local dexGrid       = panel:WaitForChild("DexGrid")

-- Стабильный порядок: сортируем по id
local fishOrder = {}
for id in pairs(FishData.Fish) do table.insert(fishOrder, id) end
table.sort(fishOrder)

local RARITY_COLOR = {
    Common    = Color3.fromRGB(150, 170, 190),
    Uncommon  = Color3.fromRGB(90, 200, 110),
    Rare      = Color3.fromRGB(70, 140, 230),
    Epic      = Color3.fromRGB(170, 90, 220),
    Legendary = Color3.fromRGB(230, 180, 60),
    Mythic    = Color3.fromRGB(230, 80, 80),
}

local function buildGrid(dex)
    for _, ch in ipairs(dexGrid:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end

    local caughtCount = 0

    for i, fishId in ipairs(fishOrder) do
        local fish  = FishData.Fish[fishId]
        local entry = dex[fishId]
        local caught = entry ~= nil
        if caught then caughtCount += 1 end

        local card = Instance.new("Frame")
        card.Name = fishId
        card.LayoutOrder = i
        card.BackgroundColor3 = caught and Color3.fromRGB(34, 38, 46) or Color3.fromRGB(26, 28, 34)
        card.BorderSizePixel = 0
        card.Parent = dexGrid
        local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,8); cc.Parent = card
        local cs = Instance.new("UIStroke")
        cs.Color = caught and (RARITY_COLOR[fish.rarity] or Color3.fromRGB(100,110,130)) or Color3.fromRGB(60,64,72)
        cs.Thickness = 1.5
        cs.Parent = card

        local iconHolder = Instance.new("Frame")
        iconHolder.Size = UDim2.new(1,-12,0,48)
        iconHolder.Position = UDim2.fromOffset(6,6)
        iconHolder.BackgroundColor3 = caught and (RARITY_COLOR[fish.rarity] or Color3.fromRGB(150,160,180)) or Color3.fromRGB(50,54,62)
        iconHolder.BackgroundTransparency = caught and 0.15 or 0.3
        iconHolder.BorderSizePixel = 0
        iconHolder.Parent = card
        local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0,6); ic.Parent = iconHolder

        if caught and fish.image ~= "" then
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.fromScale(0.8,0.8)
            img.Position = UDim2.fromScale(0.1,0.1)
            img.BackgroundTransparency = 1
            img.Image = fish.image
            img.Parent = iconHolder
        else
            local ph = Instance.new("TextLabel")
            ph.Size = UDim2.fromScale(1,1)
            ph.BackgroundTransparency = 1
            ph.Text = caught and "🐟" or "❓"
            ph.TextScaled = true
            ph.Font = Enum.Font.GothamBold
            ph.TextColor3 = Color3.new(1,1,1)
            ph.Parent = iconHolder
        end

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1,-8,0,18)
        nameLbl.Position = UDim2.fromOffset(4,56)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = caught and fish.displayName or Strings.FishDex_Unknown
        nameLbl.TextColor3 = caught and Color3.fromRGB(235,238,245) or Color3.fromRGB(120,125,135)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextScaled = true
        nameLbl.Parent = card

        local subLbl = Instance.new("TextLabel")
        subLbl.Size = UDim2.new(1,-8,0,16)
        subLbl.Position = UDim2.fromOffset(4,76)
        subLbl.BackgroundTransparency = 1
        subLbl.TextScaled = true
        subLbl.Font = Enum.Font.Gotham
        if caught then
            subLbl.Text = "x" .. tostring(entry.count or 1) .. (entry.hasMutation and " ✨" or "")
            subLbl.TextColor3 = Color3.fromRGB(150,158,175)
        else
            subLbl.Text = Strings.FishDex_NotCaught
            subLbl.TextColor3 = Color3.fromRGB(110,115,125)
        end
        subLbl.Parent = card
    end

    local total = #fishOrder
    progressLabel.Text = caughtCount .. " / " .. total
    local pct = total > 0 and (caughtCount / total) or 0
    progressFill.Size = UDim2.new(pct, 0, 1, 0)

    dexGrid.CanvasSize = UDim2.fromOffset(0, math.ceil(total / 4) * 108 + 16)
end

local function openPanel()
    gui.Enabled = true
    panel.Position = UDim2.new(0.5,0,0.6,0)
    TweenService:Create(panel,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5,0,0.5,0) }):Play()
    playSound("Open")
    task.spawn(function()
        local ok, dex = pcall(function() return GetFishDex:InvokeServer() end)
        buildGrid(ok and dex or {})
    end)
end

local function closePanel()
    TweenService:Create(panel,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5,0,1.4,0) }):Play()
    task.delay(0.22, function() gui.Enabled = false end)
    playSound("Close")
end

closeBtn.MouseButton1Click:Connect(closePanel)
ShopBridge.Register("FishDexPanel", openPanel)

print("[ReefDiver] FishDexPanel initialised ✓")

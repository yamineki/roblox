-- StarterPlayerScripts/SellPanel.client.lua
-- Reef Diver — Fish selling panel (opened via FishMerchant NPC)

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopBridge = require(ReplicatedStorage.Modules.ShopBridge)
local okFX, SoundFX = pcall(function() return require(ReplicatedStorage.Modules.SoundFX) end)
local function playSound(n) if okFX and SoundFX then SoundFX.Play(n) end end

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local GetInventory  = Remotes:WaitForChild("GetInventory")
local SellFish      = Remotes:WaitForChild("SellFish")
local SellAllRemote = Remotes:WaitForChild("SellAll")

local gui = PlayerGui:WaitForChild("SellPanel", 15)
if not gui then return end

local panel        = gui:WaitForChild("Panel")
local closeBtn     = panel:WaitForChild("CloseBtn")
local fishList     = panel:WaitForChild("FishList")
local balanceLabel = panel:WaitForChild("BalanceLabel")
local summaryBar   = panel:WaitForChild("SummaryBar")
local totalLbl     = summaryBar:WaitForChild("TotalValue")
local sellSelBtn   = summaryBar:WaitForChild("SellSelected")
local sellAllBtn   = summaryBar:WaitForChild("SellAll")

Remotes:WaitForChild("CoinsUpdated").OnClientEvent:Connect(function(amount)
    balanceLabel.Text = "🪙 " .. tostring(amount)
end)

local heldIdx   = nil   -- index of the single "held" fish picked to sell alone
local inventory = {}    -- cached fish list

local function updateSummary()
    local entry = heldIdx and inventory[heldIdx]
    if entry then
        totalLbl.Text = "Held fish: 🪙 " .. (entry.value or 0)
        sellSelBtn.Active = true
    else
        local allTotal = 0
        for _, e in ipairs(inventory) do allTotal = allTotal + (e.value or 0) end
        totalLbl.Text = "All fish worth: 🪙 " .. allTotal
        sellSelBtn.Active = false
    end
end

local function buildList()
    for _, ch in ipairs(fishList:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end
    heldIdx = nil
    updateSummary()

    local rowButtons = {}
    for i, entry in ipairs(inventory) do
        local row = Instance.new("Frame")
        row.Name = "Row"..i
        row.Size = UDim2.new(1,0,0,44)
        row.BackgroundColor3 = Color3.fromRGB(40,150,170)
        row.BackgroundTransparency = 0.15
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = fishList
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = row

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0.55,0,1,0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = (entry.name or "Unknown") .. (entry.mutation ~= "None" and (" ✨") or "")
        nameLbl.TextColor3 = Color3.new(1,1,1)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 13
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Position = UDim2.fromOffset(8,0)
        nameLbl.Parent = row

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0.25,0,1,0)
        valLbl.Position = UDim2.fromScale(0.55,0)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = "🪙 " .. (entry.value or 0)
        valLbl.TextColor3 = Color3.fromRGB(255,220,80)
        valLbl.Font = Enum.Font.Gotham
        valLbl.TextSize = 13
        valLbl.Parent = row

        local selBtn = Instance.new("TextButton")
        selBtn.Size = UDim2.fromOffset(60,30)
        selBtn.Position = UDim2.new(1,-66,0.5,-15)
        selBtn.BackgroundColor3 = Color3.fromRGB(70,190,100)
        selBtn.TextColor3 = Color3.new(1,1,1)
        selBtn.Text = "Select"
        selBtn.Font = Enum.Font.GothamBold
        selBtn.TextSize = 12
        selBtn.BorderSizePixel = 0
        selBtn.Parent = row
        local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0,6); sc.Parent = selBtn

        local idx = i
        rowButtons[idx] = { btn = selBtn, row = row }
        selBtn.MouseButton1Click:Connect(function()
            playSound("Click")
            if heldIdx == idx then
                heldIdx = nil
                selBtn.Text = "Select"
                selBtn.BackgroundColor3 = Color3.fromRGB(70,190,100)
                row.BackgroundTransparency = 0.15
            else
                if heldIdx and rowButtons[heldIdx] then
                    rowButtons[heldIdx].btn.Text = "Select"
                    rowButtons[heldIdx].btn.BackgroundColor3 = Color3.fromRGB(70,190,100)
                    rowButtons[heldIdx].row.BackgroundTransparency = 0.15
                end
                heldIdx = idx
                selBtn.Text = "✓ Held"
                selBtn.BackgroundColor3 = Color3.fromRGB(40,150,70)
                row.BackgroundTransparency = 0.5
            end
            updateSummary()
        end)
    end

    fishList.CanvasSize = UDim2.fromOffset(0, #inventory * 48 + 4)
end

local function openPanel()
    inventory = {}
    selected = {}
    local ok, inv = pcall(function() return GetInventory:InvokeServer() end)
    if ok and inv then
        inventory = inv
    end
    buildList()
    gui.Enabled = true
    panel.Position = UDim2.new(0.5,0,0.6,0)
    TweenService:Create(panel,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5,0,0.5,0) }):Play()
    playSound("Open")
end

local function closePanel()
    TweenService:Create(panel,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5,0,1.4,0) }):Play()
    task.delay(0.22, function() gui.Enabled = false end)
    playSound("Close")
end

closeBtn.MouseButton1Click:Connect(closePanel)

sellSelBtn.MouseButton1Click:Connect(function()
    if not heldIdx or not inventory[heldIdx] then return end
    pcall(function() SellFish:FireServer(heldIdx) end)
    playSound("Purchase")
    task.wait(0.4)
    openPanel()
end)

sellAllBtn.MouseButton1Click:Connect(function()
    pcall(function() SellAllRemote:FireServer() end)
    playSound("Purchase")
    task.wait(0.4)
    openPanel()
end)

ShopBridge.Register("SellPanel", openPanel)

print("[ReefDiver] SellPanel initialised ✓")

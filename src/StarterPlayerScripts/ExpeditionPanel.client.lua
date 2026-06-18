-- StarterPlayerScripts/ExpeditionPanel.client.lua
-- Reef Diver — AFK Expedition panel (opened via ResearchSubmarine NPC)

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopBridge = require(ReplicatedStorage.Modules.ShopBridge)
local okFX, SoundFX = pcall(function() return require(ReplicatedStorage.Modules.SoundFX) end)
local function playSound(n) if okFX and SoundFX then SoundFX.Play(n) end end

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local GetExpeditionStatus = Remotes:WaitForChild("GetExpeditionStatus")
local StartExpedition     = Remotes:WaitForChild("StartExpedition")
local CollectExpedition   = Remotes:WaitForChild("CollectExpedition")
local ExpeditionStarted   = Remotes:WaitForChild("ExpeditionStarted")
local ExpeditionComplete  = Remotes:WaitForChild("ExpeditionComplete")
local GetShopData         = Remotes:WaitForChild("GetShopData")

local gui = PlayerGui:WaitForChild("ExpeditionPanel", 15)
if not gui then return end

local panel       = gui:WaitForChild("Panel")
local closeBtn    = panel:WaitForChild("CloseBtn")
local slotCont    = panel:WaitForChild("SlotContainer")
local timerLbl    = panel:WaitForChild("TimerLabel")
local balanceLabel = panel:WaitForChild("BalanceLabel")

Remotes:WaitForChild("CoinsUpdated").OnClientEvent:Connect(function(amount)
    balanceLabel.Text = "🪙 " .. tostring(amount)
end)

local SLOT_COUNT = 3
local SLOT_DURATION = { "Short", "Medium", "Long" }
local LOCKED_GAMEPASS = "ExtraAFKSlots"
local hasExtraSlotPass = false

local slots = {}
for i = 1, SLOT_COUNT do
    local sl = slotCont:FindFirstChild("Slot"..i)
    if sl then
        slots[i] = {
            frame     = sl,
            status    = sl:FindFirstChild("SlotStatus"),
            startBtn  = sl:FindFirstChild("StartBtn"),
            collectBtn= sl:FindFirstChild("CollectBtn"),
            glow      = sl:FindFirstChild("ActiveGlow"),
        }
    end
end

local expeditionData = {}  -- server status (array of active expeditions)

local function formatTime(s)
    if s <= 0 then return "Ready!" end
    local h = math.floor(s/3600)
    local m = math.floor((s%3600)/60)
    local sec = s%60
    if h > 0 then return string.format("%dh %02dm", h, m) end
    return string.format("%dm %02ds", m, sec)
end

local function refreshUI(data)
    expeditionData = data or {}
    for i, slot in ipairs(slots) do
        local locked = (i == 3) and not hasExtraSlotPass
        local exp = expeditionData[i]
        local status
        if locked then
            status = "locked"
        elseif not exp then
            status = "idle"
        elseif os.time() >= (exp.endTime or 0) then
            status = "complete"
        else
            status = "running"
        end

        if slot.status then
            if status == "locked" then
                slot.status.Text = "🔒 Requires +2 AFK Slots gamepass"
                slot.status.TextColor3 = Color3.fromRGB(255,160,160)
            elseif status == "idle" then
                slot.status.Text = "Empty — ready to launch"
                slot.status.TextColor3 = Color3.fromRGB(180,220,255)
            elseif status == "running" then
                local rem = math.max(0, (exp.endTime or 0) - os.time())
                slot.status.Text = "Underway: " .. formatTime(rem)
                slot.status.TextColor3 = Color3.fromRGB(255,220,100)
            elseif status == "complete" then
                slot.status.Text = "✓ Complete — collect now!"
                slot.status.TextColor3 = Color3.fromRGB(100,240,130)
            end
        end
        if slot.startBtn   then slot.startBtn.Visible   = (status == "idle") end
        if slot.collectBtn then slot.collectBtn.Visible = (status == "complete") end
        if slot.glow        then slot.glow.Enabled = (status == "running" or status == "complete") end
    end
end

-- Wire slot buttons
for i, slot in ipairs(slots) do
    if slot.startBtn then
        slot.startBtn.MouseButton1Click:Connect(function()
            if i == 3 and not hasExtraSlotPass then return end
            playSound("Click")
            pcall(function() StartExpedition:FireServer(SLOT_DURATION[i]) end)
            task.wait(0.4)
            local ok, data = pcall(function() return GetExpeditionStatus:InvokeServer() end)
            if ok and data then refreshUI(data) end
        end)
    end
    if slot.collectBtn then
        slot.collectBtn.MouseButton1Click:Connect(function()
            playSound("Purchase")
            pcall(function() CollectExpedition:FireServer(i) end)
            task.wait(0.4)
            local ok, data = pcall(function() return GetExpeditionStatus:InvokeServer() end)
            if ok and data then refreshUI(data) end
        end)
    end
end

-- Live timer update
task.spawn(function()
    while true do
        task.wait(1)
        if gui.Enabled then
            local now = os.time()
            for i, slot in ipairs(slots) do
                local exp = expeditionData[i]
                if exp and slot.status and now < (exp.endTime or 0) then
                    local rem = math.max(0, (exp.endTime or 0) - now)
                    slot.status.Text = "Underway: " .. formatTime(rem)
                elseif exp and slot.status and now >= (exp.endTime or 0) and slot.collectBtn and not slot.collectBtn.Visible then
                    slot.status.Text = "✓ Complete — collect now!"
                    slot.status.TextColor3 = Color3.fromRGB(100,240,130)
                    if slot.startBtn   then slot.startBtn.Visible   = false end
                    if slot.collectBtn then slot.collectBtn.Visible  = true  end
                    if slot.glow        then slot.glow.Enabled = true end
                end
            end
        end
    end
end)

ExpeditionStarted.OnClientEvent:Connect(function(data)
    refreshUI(data)
end)

ExpeditionComplete.OnClientEvent:Connect(function(data)
    refreshUI(data)
    playSound("Purchase")
end)

local function openPanel()
    gui.Enabled = true
    panel.Position = UDim2.new(0.5,0,0.6,0)
    TweenService:Create(panel,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5,0,0.5,0) }):Play()
    playSound("Open")
    task.spawn(function()
        local okShop, shopData = pcall(function() return GetShopData:InvokeServer() end)
        if okShop and shopData and shopData.owned then
            hasExtraSlotPass = shopData.owned[LOCKED_GAMEPASS] == true
        end
        local ok, data = pcall(function() return GetExpeditionStatus:InvokeServer() end)
        if ok and data then refreshUI(data) end
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
ShopBridge.Register("ExpeditionPanel", openPanel)

print("[ReefDiver] ExpeditionPanel initialised ✓")

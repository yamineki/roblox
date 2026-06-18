-- StarterPlayerScripts/RebirthPanel.client.lua
-- Reef Diver — Rebirth confirmation panel (opened via ElderDiver NPC)

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopBridge  = require(ReplicatedStorage.Modules.ShopBridge)
local GameConfig  = require(ReplicatedStorage.Modules.GameConfig)
local okFX, SoundFX = pcall(function() return require(ReplicatedStorage.Modules.SoundFX) end)
local function playSound(n) if okFX and SoundFX then SoundFX.Play(n) end end

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local GetPlayerData    = Remotes:WaitForChild("GetPlayerData")
local RequestRebirth   = Remotes:WaitForChild("RequestRebirth")
local RebirthComplete  = Remotes:WaitForChild("RebirthComplete")

local gui = PlayerGui:WaitForChild("RebirthPanel", 15)
if not gui then return end

local panel         = gui:WaitForChild("Panel")
local closeBtn      = panel:WaitForChild("CloseBtn")
local cancelBtn     = panel:WaitForChild("CancelBtn")
local confirmBtn    = panel:WaitForChild("ConfirmRebirth")
local statsFrame    = panel:WaitForChild("RebirthStats")
local reqFrame       = panel:WaitForChild("Requirements")
local reqValueLbl     = reqFrame:WaitForChild("ReqValue")
local reqRewardLbl    = reqFrame:WaitForChild("ReqReward")

local function getStatRow(name)
    local row = statsFrame:FindFirstChild(name)
    if not row then return nil end
    return row:FindFirstChild("Value")
end

local coinVal    = getStatRow("CurrentCoins")
local catchVal   = getStatRow("TotalCatch")
local rebirthVal = getStatRow("RebirthCount")

local function populateStats(data)
    if not data then return end
    local rebirthLevel = data.rebirthLevel or 0
    if coinVal    then coinVal.Text    = tostring(data.coins or 0) end
    if catchVal   then catchVal.Text   = tostring(data.stats and data.stats.totalFishCaught or 0) end
    if rebirthVal then rebirthVal.Text = tostring(rebirthLevel) end

    if rebirthLevel >= 10 then
        reqValueLbl.Text = "🏆 Max rebirth level reached"
        reqRewardLbl.Text = ""
        confirmBtn.Active = false
        confirmBtn.Text = "Max Level"
    else
        local nextLevel = rebirthLevel + 1
        local cost = GameConfig.GetRebirthCost(nextLevel)
        local rewardInfo = GameConfig.Rebirth[nextLevel]
        reqValueLbl.Text = "🪙 Need " .. string.format("%d", cost) .. " coins"
        reqRewardLbl.Text = "Reward: " .. (rewardInfo and rewardInfo.description or "—")
    end
end

local function openPanel()
    gui.Enabled = true
    panel.Position = UDim2.new(0.5,0,0.6,0)
    TweenService:Create(panel,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5,0,0.5,0) }):Play()
    playSound("Open")
    confirmBtn.Active = true
    confirmBtn.Text = "⚡ Rebirth Now!"
    task.spawn(function()
        local ok, data = pcall(function() return GetPlayerData:InvokeServer() end)
        if ok and data then populateStats(data) end
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
cancelBtn.MouseButton1Click:Connect(closePanel)

confirmBtn.MouseButton1Click:Connect(function()
    if not confirmBtn.Active then return end
    confirmBtn.Active = false
    confirmBtn.Text = "⏳ Rebirthing..."
    playSound("Purchase")
    RequestRebirth:FireServer()
end)

RebirthComplete.OnClientEvent:Connect(function(result)
    -- БАГФИКС: раньше success вообще не проверялся — кнопка всегда писала
    -- "Reborn!" и панель закрывалась, даже если на сервере rebirth провалился
    -- (не хватило монет / max level), из-за чего казалось что "можно", хотя
    -- ничего на самом деле не происходило.
    if result and result.success then
        confirmBtn.Text = "✓ Reborn!"
        task.delay(1.5, closePanel)
    else
        confirmBtn.Text = "✗ Not enough coins!"
        playSound("HookMiss")
        task.spawn(function()
            local ok, data = pcall(function() return GetPlayerData:InvokeServer() end)
            if ok and data then populateStats(data) end
        end)
        task.delay(1.6, function()
            if confirmBtn.Active == false and confirmBtn.Text == "✗ Not enough coins!" then
                confirmBtn.Active = true
                confirmBtn.Text = "⚡ Rebirth Now!"
            end
        end)
    end
end)

ShopBridge.Register("RebirthPanel", openPanel)

print("[ReefDiver] RebirthPanel initialised ✓")

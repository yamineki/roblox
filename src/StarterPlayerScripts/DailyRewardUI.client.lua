-- StarterPlayerScripts/DailyRewardUI.client.lua
-- Reef Diver — Ежедневные награды
--
-- ЗАМЕНА ИКОНОК:
--   Открой Studio → StarterGui → DailyRewardGui → Panel → Day1..Day7
--   → IconContainer → RewardIcon → установи Image = rbxassetid://XXXXXXXX
--   Поле EmojiIcon (TextLabel) скроется автоматически при следующем запуске.
--
-- Все GUI создаются UIBuilder.lua — этот скрипт только подключает логику.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Remotes          = ReplicatedStorage:WaitForChild("Remotes")
local GetDailyStatus   = Remotes:WaitForChild("GetDailyStatus")
local ClaimDailyReward = Remotes:WaitForChild("ClaimDailyReward")
local DailyRewardClaimed = Remotes:WaitForChild("DailyRewardClaimed")
local PlayerDataLoaded = Remotes:WaitForChild("PlayerDataLoaded")

-- ══════════════════════════════════════════════════════════════
--  ОПИСАНИЯ НАГРАД
-- ══════════════════════════════════════════════════════════════
local function getRewardTitle(reward)
    local t = reward.type
    if t == "Coins"             then return "🪙 " .. (reward.amount or 0) .. " монет" end
    if t == "LuckBoost"         then return "🍀 Удача ×" .. (reward.mult or 1.5) .. "\n30 мин" end
    if t == "MutationBoost"     then return "✨ Мутации ×" .. (reward.mult or 2) .. "\n30 мин" end
    if t == "AFKTicket"         then return "⏱ AFK билет ×" .. (reward.amount or 1) end
    if t == "MutationChest"     then return "📦 Сундук мутаций\n×" .. (reward.amount or 1) end
    if t == "RareFishChest"     then return "🐠 Rare+ сундук" end
    if t == "ExclusiveMutation" then return "🌟 Особая мутация\nТолько сегодня" end
    return "🎁 Награда"
end

-- ══════════════════════════════════════════════════════════════
--  ЦВЕТА СОСТОЯНИЙ КАРТОЧЕК
-- ══════════════════════════════════════════════════════════════
local STATE = {
    claimed  = { bg = Color3.fromRGB(12, 22, 12),  border = Color3.fromRGB(60, 130, 60),   alpha = 0.5  },
    current  = { bg = Color3.fromRGB(5,  20, 45),  border = Color3.fromRGB(0,  200, 255),  alpha = 0.05 },
    future   = { bg = Color3.fromRGB(10, 16, 28),  border = Color3.fromRGB(60, 80,  120),  alpha = 0.3  },
}

-- ══════════════════════════════════════════════════════════════
--  GUI — получаем ссылки из уже созданных UIBuilder элементов
-- ══════════════════════════════════════════════════════════════
local gui          = PlayerGui:WaitForChild("DailyRewardGui", 20)
local dim          = gui:WaitForChild("Dim")
local panel        = gui:WaitForChild("Panel")
local streakLabel  = panel:WaitForChild("StreakLabel")
local timerLabel   = panel:WaitForChild("TimerLabel")
local claimBtn     = panel:WaitForChild("ClaimButton")
local resultPopup  = gui:WaitForChild("ResultPopup")
local resultTitle  = resultPopup:WaitForChild("ResultTitle")
local resultBody   = resultPopup:WaitForChild("ResultBody")

-- DailyBtn и NotifDot в MainHUD
local mainHud  = PlayerGui:WaitForChild("MainHUD", 20)
local dailyBtn = mainHud and mainHud:WaitForChild("DailyBtn", 10)
local notifDot = dailyBtn and dailyBtn:WaitForChild("NotifDot", 5)

-- ══ КАРТОЧКИ ══
local dayCards = {}
for day = 1, 7 do
    local card     = panel:WaitForChild("Day" .. day)
    local iconCont = card:WaitForChild("IconContainer")
    local iconImg  = iconCont:WaitForChild("RewardIcon")
    local iconEmoji= iconImg:WaitForChild("EmojiIcon")
    local checkmark= card:WaitForChild("Checkmark")

    -- Найти UIStroke по именам
    local cardStroke, glowStroke
    for _, ch in ipairs(card:GetChildren()) do
        if ch:IsA("UIStroke") then
            if ch.Name == "CardStroke" then
                cardStroke = ch
            elseif ch.Name == "GlowStroke" then
                glowStroke = ch
            end
        end
    end

    -- Если изображение задано — скрыть emoji
    if iconImg.Image ~= "" then
        iconEmoji.Visible = false
    end

    dayCards[day] = {
        frame     = card,
        iconImg   = iconImg,
        iconEmoji = iconEmoji,
        title     = card:WaitForChild("RewardTitle"),
        stroke    = cardStroke,
        glow      = glowStroke,
        checkmark = checkmark,
    }
end

-- ══════════════════════════════════════════════════════════════
--  ЛОГИКА
-- ══════════════════════════════════════════════════════════════
local currentStatus = nil
local countdownConn = nil

local function applyStatus(status)
    currentStatus = status
    local todayCard = status.nextDay

    streakLabel.Text = "🔥 Серия: " .. status.streak .. " " .. (status.streak == 1 and "день" or "дней")

    for day = 1, 7 do
        local c = dayCards[day]
        local isClaimed = (day < todayCard) or (status.streak >= 7 and not status.canClaim)
        local isCurrent = (day == todayCard)

        if isClaimed then
            c.frame.BackgroundColor3       = STATE.claimed.bg
            c.frame.BackgroundTransparency = STATE.claimed.alpha
            if c.stroke then c.stroke.Color = STATE.claimed.border; c.stroke.Transparency = 0.2 end
            if c.glow   then c.glow.Transparency = 1 end
            c.checkmark.Visible = true
        elseif isCurrent then
            c.frame.BackgroundColor3       = STATE.current.bg
            c.frame.BackgroundTransparency = STATE.current.alpha
            if c.stroke then c.stroke.Color = STATE.current.border; c.stroke.Transparency = 0.1 end
            if c.glow   then
                c.glow.Transparency = 0.55
                TweenService:Create(c.glow,
                    TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    { Transparency = 0.85 }):Play()
            end
            c.checkmark.Visible = false
        else
            c.frame.BackgroundColor3       = STATE.future.bg
            c.frame.BackgroundTransparency = STATE.future.alpha
            if c.stroke then c.stroke.Color = STATE.future.border; c.stroke.Transparency = 0.4 end
            if c.glow   then c.glow.Transparency = 1 end
            c.checkmark.Visible = false
        end
    end

    claimBtn.Active           = status.canClaim
    claimBtn.AutoButtonColor  = status.canClaim
    claimBtn.BackgroundColor3 = status.canClaim
        and Color3.fromRGB(0, 160, 255)
        or  Color3.fromRGB(40, 50, 70)
    claimBtn.Text = status.canClaim and "🎁  Забрать награду" or "✓  Уже получено"

    if countdownConn then countdownConn:Disconnect(); countdownConn = nil end

    if not status.canClaim and status.nextClaimAt then
        countdownConn = RunService.Heartbeat:Connect(function()
            if not gui.Enabled then return end
            local remaining = math.max(0, status.nextClaimAt - os.time())
            local h = math.floor(remaining / 3600)
            local m = math.floor((remaining % 3600) / 60)
            local s = remaining % 60
            timerLabel.Text = string.format("Следующая через %02d:%02d:%02d", h, m, s)
            if remaining <= 0 then timerLabel.Text = "Обновляется..." end
        end)
    else
        timerLabel.Text = ""
    end
end

local function openGui()
    gui.Enabled = true
    panel.Size = UDim2.fromOffset(760, 0)
    panel.BackgroundTransparency = 1
    TweenService:Create(panel,
        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.fromOffset(760, 440), BackgroundTransparency = 0 }
    ):Play()
end

local function showResult(reward)
    resultBody.Text = getRewardTitle(reward)
    resultPopup.Visible = true
    resultPopup.BackgroundTransparency = 1
    resultBody.TextTransparency = 1
    resultTitle.TextTransparency = 1

    TweenService:Create(resultPopup,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0.05 }):Play()
    TweenService:Create(resultTitle, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
    TweenService:Create(resultBody,  TweenInfo.new(0.25), { TextTransparency = 0 }):Play()

    task.delay(3, function()
        TweenService:Create(resultPopup,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }):Play()
        TweenService:Create(resultTitle, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        TweenService:Create(resultBody,  TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        task.delay(0.35, function() resultPopup.Visible = false end)
    end)
end

local function updateDot(canClaim)
    if notifDot then notifDot.Visible = canClaim == true end
end

-- ══ КНОПКИ ══
dim.MouseButton1Click:Connect(function() gui.Enabled = false end)

local closeBtnPanel = panel:FindFirstChild("CloseBtn")
if closeBtnPanel then
    closeBtnPanel.MouseButton1Click:Connect(function() gui.Enabled = false end)
end

claimBtn.MouseButton1Click:Connect(function()
    if not currentStatus or not currentStatus.canClaim then return end
    claimBtn.Active = false
    claimBtn.Text = "⏳ Получение..."
    ClaimDailyReward:FireServer()
end)

if dailyBtn then
    dailyBtn.MouseButton1Click:Connect(function()
        if gui.Enabled then
            gui.Enabled = false
        else
            local ok, status = pcall(function() return GetDailyStatus:InvokeServer() end)
            if ok and status then applyStatus(status) end
            openGui()
        end
    end)
end

-- ══ СОБЫТИЯ СЕРВЕРА ══
DailyRewardClaimed.OnClientEvent:Connect(function(payload)
    local day = payload.day
    if dayCards[day] then
        dayCards[day].checkmark.Visible = true
        if dayCards[day].glow then dayCards[day].glow.Transparency = 1 end

        local flash = Instance.new("Frame")
        flash.Size = UDim2.fromScale(1, 1)
        flash.BackgroundColor3 = Color3.new(1, 1, 1)
        flash.BackgroundTransparency = 0.3
        flash.ZIndex = 6
        flash.BorderSizePixel = 0
        flash.Parent = dayCards[day].frame
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = flash
        TweenService:Create(flash,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = 1 }):Play()
        task.delay(0.55, function() flash:Destroy() end)
    end

    claimBtn.Active = false
    claimBtn.AutoButtonColor = false
    claimBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
    claimBtn.Text = "✓  Уже получено"

    if currentStatus then
        currentStatus.canClaim = false
        currentStatus.streak = (currentStatus.streak or 0) + 1
        local today = math.floor(os.time() / 86400)
        currentStatus.nextClaimAt = (today + 1) * 86400
        applyStatus(currentStatus)
    end

    updateDot(false)
    showResult(payload.reward)
end)

PlayerDataLoaded.OnClientEvent:Connect(function()
    task.spawn(function()
        task.wait(1)
        local ok, status = pcall(function() return GetDailyStatus:InvokeServer() end)
        if ok and status then
            updateDot(status.canClaim)
            if status.canClaim then
                applyStatus(status)
                openGui()
            end
        end
    end)
end)

print("[ReefDiver] DailyRewardUI инициализирован ✓")

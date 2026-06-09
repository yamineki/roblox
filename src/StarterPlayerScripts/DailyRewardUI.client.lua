-- StarterPlayerScripts/DailyRewardUI.client.lua
-- Reef Diver — Ежедневные награды
--
-- ЗАМЕНА ИКОНОК:
--   Найди таблицу REWARD_ICONS ниже и замени поле image на rbxassetid://XXXXXXXX
--   Каждый тип награды имеет отдельную запись.
--   Поле emoji остаётся как фолбэк пока image = "".

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Strings    = require(ReplicatedStorage.Modules.Strings)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Remotes          = ReplicatedStorage:WaitForChild("Remotes")
local GetDailyStatus   = Remotes:WaitForChild("GetDailyStatus")
local ClaimDailyReward = Remotes:WaitForChild("ClaimDailyReward")
local DailyRewardClaimed = Remotes:WaitForChild("DailyRewardClaimed")
local PlayerDataLoaded = Remotes:WaitForChild("PlayerDataLoaded")

-- ══════════════════════════════════════════════════════════════
--  ИКОНКИ НАГРАД
--  image  = "" → показывается emoji (фолбэк)
--  image  = "rbxassetid://XXXXXXXX" → показывается изображение
--  Размер ImageLabel: 80×80 пикселей
-- ══════════════════════════════════════════════════════════════
local REWARD_ICONS = {
    Coins           = { image = "", emoji = "🪙", tint = Color3.fromRGB(255, 210, 50)  },
    LuckBoost       = { image = "", emoji = "🍀", tint = Color3.fromRGB(80,  220, 120) },
    MutationBoost   = { image = "", emoji = "✨", tint = Color3.fromRGB(220, 100, 230) },
    AFKTicket       = { image = "", emoji = "⏱",  tint = Color3.fromRGB(80,  200, 255) },
    MutationChest   = { image = "", emoji = "📦", tint = Color3.fromRGB(180, 80,  230) },
    RareFishChest   = { image = "", emoji = "🐠", tint = Color3.fromRGB(80,  160, 255) },
    ExclusiveMutation={ image ="", emoji = "🌟", tint = Color3.fromRGB(255, 180, 40)  },
    Default         = { image = "", emoji = "🎁", tint = Color3.fromRGB(150, 200, 255) },
}

-- ══════════════════════════════════════════════════════════════
--  ОПИСАНИЯ НАГРАД (что показывается на карточке)
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
    claimed  = { bg = Color3.fromRGB(12, 22, 12),  border = Color3.fromRGB(60, 130, 60),   alpha = 0.5 },
    current  = { bg = Color3.fromRGB(5,  20, 45),  border = Color3.fromRGB(0,  200, 255),  alpha = 0.05 },
    future   = { bg = Color3.fromRGB(10, 16, 28),  border = Color3.fromRGB(60, 80,  120),  alpha = 0.3 },
}

-- ══════════════════════════════════════════════════════════════
--  ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ПОСТРОЕНИЯ UI
-- ══════════════════════════════════════════════════════════════
local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
end

local function uistroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1.5
    s.Transparency = transparency or 0.3
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function label(name, parent, text, size, pos, color, fontSize, font)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.Size = size
    l.Position = pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.new(1,1,1)
    l.Font = font or Enum.Font.GothamBold
    l.TextSize = fontSize or 14
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.Parent = parent
    return l
end

-- ══════════════════════════════════════════════════════════════
--  ПОСТРОЕНИЕ GUI
-- ══════════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "DailyRewardGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 150
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = PlayerGui

-- Затемнение фона
local dim = Instance.new("TextButton")
dim.Name = "Dim"
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.45
dim.Text = ""
dim.AutoButtonColor = false
dim.Parent = gui
dim.MouseButton1Click:Connect(function() gui.Enabled = false end)

-- Основная панель
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(760, 440)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(6, 14, 30)
panel.BackgroundTransparency = 0
panel.BorderSizePixel = 0
panel.Parent = gui
corner(panel, 16)
uistroke(panel, Color3.fromRGB(0, 180, 255), 2, 0.15)

-- Градиентная плашка-заголовок
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 64)
header.BackgroundColor3 = Color3.fromRGB(0, 30, 70)
header.BorderSizePixel = 0
header.Parent = panel
corner(header, 16)
-- нижние углы не скруглены (частичное скругление через дополнительный Frame)
local headerFill = Instance.new("Frame")
headerFill.Size = UDim2.new(1, 0, 0.5, 0)
headerFill.Position = UDim2.new(0, 0, 0.5, 0)
headerFill.BackgroundColor3 = Color3.fromRGB(0, 30, 70)
headerFill.BorderSizePixel = 0
headerFill.Parent = header

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 60, 140)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 20, 50)),
})
grad.Rotation = 90
grad.Parent = header

-- Заголовок
label("Title", panel,
    "🗓  ЕЖЕДНЕВНЫЕ НАГРАДЫ",
    UDim2.new(1, -80, 0, 64),
    UDim2.new(0, 0, 0, 0),
    Color3.fromRGB(0, 220, 255), 22)

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.fromOffset(36, 36)
closeBtn.Position = UDim2.new(1, -46, 0, 14)
closeBtn.AnchorPoint = Vector2.new(0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BorderSizePixel = 0
closeBtn.Parent = panel
corner(closeBtn, 8)
closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

-- Стрик-лейбл
local streakLabel = label("StreakLabel", panel,
    "Серия: 0 дней",
    UDim2.new(1, -20, 0, 28),
    UDim2.new(0, 10, 0, 68),
    Color3.fromRGB(255, 210, 80), 15, Enum.Font.Gotham)
streakLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Таймер до следующей награды
local timerLabel = label("TimerLabel", panel,
    "",
    UDim2.new(0.5, 0, 0, 28),
    UDim2.new(0.5, 0, 0, 68),
    Color3.fromRGB(160, 200, 220), 14, Enum.Font.Gotham)
timerLabel.AnchorPoint = Vector2.new(0.5, 0)

-- ══ КАРТОЧКИ (7 дней) ══
local CARD_W = 90
local CARD_H = 250
local CARD_GAP = 10
local CARDS_TOTAL_W = 7 * CARD_W + 6 * CARD_GAP   -- 700
local CARDS_START_X = (760 - CARDS_TOTAL_W) / 2     -- 30

local dayCards = {}  -- { frame, iconImg, iconLabel, titleLabel, stroke, glow, checkmark }

for day = 1, 7 do
    local reward = GameConfig.DailyRewards[day] or { type = "Default" }
    local iconInfo = REWARD_ICONS[reward.type] or REWARD_ICONS.Default

    local x = CARDS_START_X + (day - 1) * (CARD_W + CARD_GAP)

    -- Карточка
    local card = Instance.new("Frame")
    card.Name = "Day" .. day
    card.Size = UDim2.fromOffset(CARD_W, CARD_H)
    card.Position = UDim2.fromOffset(x, 100)
    card.BackgroundColor3 = STATE.future.bg
    card.BackgroundTransparency = STATE.future.alpha
    card.BorderSizePixel = 0
    card.Parent = panel
    corner(card, 10)

    local cardStroke = uistroke(card, STATE.future.border, 1.5, 0.4)

    -- Внешнее свечение (скрыто по умолчанию, появляется у текущего дня)
    local glow = Instance.new("UIStroke")
    glow.Color = Color3.fromRGB(0, 220, 255)
    glow.Thickness = 4
    glow.Transparency = 1
    glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    glow.Parent = card

    -- Номер дня
    label("DayNum", card,
        "День " .. day,
        UDim2.new(1, 0, 0, 22),
        UDim2.new(0, 0, 0, 6),
        Color3.fromRGB(160, 200, 230), 12)

    -- Контейнер иконки (80×80, центрирован)
    local iconContainer = Instance.new("Frame")
    iconContainer.Name = "IconContainer"
    iconContainer.Size = UDim2.fromOffset(68, 68)
    iconContainer.Position = UDim2.new(0.5, -34, 0, 32)
    iconContainer.BackgroundColor3 = iconInfo.tint
    iconContainer.BackgroundTransparency = 0.75
    iconContainer.BorderSizePixel = 0
    iconContainer.Parent = card
    corner(iconContainer, 12)
    uistroke(iconContainer, iconInfo.tint, 1.5, 0.3)

    -- ImageLabel — СЮДА ВСТАВЛЯТЬ rbxassetid (замена emoji)
    -- Name: "RewardIcon" — ищи по этому имени если хочешь менять программно
    local iconImg = Instance.new("ImageLabel")
    iconImg.Name = "RewardIcon"
    iconImg.Size = UDim2.fromOffset(56, 56)
    iconImg.Position = UDim2.new(0.5, -28, 0.5, -28)
    iconImg.BackgroundTransparency = 1
    iconImg.Image = iconInfo.image   -- "" = показывает emoji-фолбэк
    iconImg.ImageColor3 = Color3.new(1, 1, 1)
    iconImg.ScaleType = Enum.ScaleType.Fit
    iconImg.Parent = iconContainer

    -- Emoji-фолбэк (скрывается когда image задан)
    local iconEmoji = Instance.new("TextLabel")
    iconEmoji.Name = "EmojiIcon"
    iconEmoji.Size = UDim2.fromScale(1, 1)
    iconEmoji.BackgroundTransparency = 1
    iconEmoji.Text = iconInfo.emoji
    iconEmoji.TextScaled = true
    iconEmoji.Font = Enum.Font.GothamBold
    iconEmoji.Visible = (iconInfo.image == "")
    iconEmoji.Parent = iconImg

    -- Название награды
    local titleLbl = label("RewardTitle", card,
        getRewardTitle(reward),
        UDim2.new(1, -8, 0, 80),
        UDim2.new(0, 4, 0, 106),
        Color3.fromRGB(220, 230, 255), 11, Enum.Font.Gotham)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Center

    -- Галочка «уже получено» (скрыта по умолчанию)
    local checkmark = Instance.new("Frame")
    checkmark.Name = "Checkmark"
    checkmark.Size = UDim2.fromScale(1, 1)
    checkmark.BackgroundColor3 = Color3.fromRGB(10, 40, 10)
    checkmark.BackgroundTransparency = 0.3
    checkmark.Visible = false
    checkmark.ZIndex = 4
    checkmark.BorderSizePixel = 0
    checkmark.Parent = card
    corner(checkmark, 10)

    local checkIcon = Instance.new("TextLabel")
    checkIcon.Size = UDim2.fromScale(1, 1)
    checkIcon.BackgroundTransparency = 1
    checkIcon.Text = "✓"
    checkIcon.TextColor3 = Color3.fromRGB(80, 230, 100)
    checkIcon.TextScaled = true
    checkIcon.Font = Enum.Font.GothamBold
    checkIcon.ZIndex = 5
    checkIcon.Parent = checkmark

    dayCards[day] = {
        frame    = card,
        iconImg  = iconImg,
        iconEmoji= iconEmoji,
        title    = titleLbl,
        stroke   = cardStroke,
        glow     = glow,
        checkmark= checkmark,
    }
end

-- ══ КНОПКА ПОЛУЧИТЬ ══
local claimBtn = Instance.new("TextButton")
claimBtn.Name = "ClaimButton"
claimBtn.Size = UDim2.fromOffset(240, 50)
claimBtn.Position = UDim2.new(0.5, -120, 1, -66)
claimBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
claimBtn.TextColor3 = Color3.new(1, 1, 1)
claimBtn.Text = "🎁  Забрать награду"
claimBtn.Font = Enum.Font.GothamBold
claimBtn.TextSize = 18
claimBtn.BorderSizePixel = 0
claimBtn.Parent = panel
corner(claimBtn, 12)
uistroke(claimBtn, Color3.fromRGB(0, 220, 255), 1.5, 0.2)

-- ══ ВСПЛЫВАШКА РЕЗУЛЬТАТА ══
local resultPopup = Instance.new("Frame")
resultPopup.Name = "ResultPopup"
resultPopup.Size = UDim2.fromOffset(320, 110)
resultPopup.Position = UDim2.new(0.5, -160, 0.5, -55)
resultPopup.AnchorPoint = Vector2.new(0, 0)
resultPopup.BackgroundColor3 = Color3.fromRGB(5, 25, 55)
resultPopup.BackgroundTransparency = 0.05
resultPopup.BorderSizePixel = 0
resultPopup.ZIndex = 10
resultPopup.Visible = false
resultPopup.Parent = gui
corner(resultPopup, 14)
uistroke(resultPopup, Color3.fromRGB(0, 220, 255), 2, 0.1)

local resultTitle = label("ResultTitle", resultPopup,
    "🎉 Награда получена!",
    UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 8),
    Color3.fromRGB(0, 220, 255), 18)

local resultBody = label("ResultBody", resultPopup,
    "",
    UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 50),
    Color3.fromRGB(220, 230, 255), 15, Enum.Font.Gotham)

-- ══════════════════════════════════════════════════════════════
--  ЛОГИКА
-- ══════════════════════════════════════════════════════════════

local currentStatus = nil
local countdownConn = nil

-- Обновить состояние всех карточек
local function applyStatus(status)
    currentStatus = status
    local claimedUpTo = status.streak % 7   -- 0..6 дней уже взяты в текущем цикле
    local todayCard    = status.nextDay      -- 1..7 — сегодняшний день

    streakLabel.Text = "🔥 Серия: " .. status.streak .. " " .. (status.streak == 1 and "день" or "дней")

    for day = 1, 7 do
        local c = dayCards[day]
        -- Дни ДО текущего в этом цикле — уже забраны
        local isClaimed = (day < todayCard) or (status.streak >= 7 and day <= 7 and not status.canClaim)
        local isCurrent = (day == todayCard)

        if isClaimed then
            c.frame.BackgroundColor3      = STATE.claimed.bg
            c.frame.BackgroundTransparency= STATE.claimed.alpha
            c.stroke.Color                = STATE.claimed.border
            c.stroke.Transparency         = 0.2
            c.glow.Transparency           = 1
            c.checkmark.Visible           = true
        elseif isCurrent then
            c.frame.BackgroundColor3      = STATE.current.bg
            c.frame.BackgroundTransparency= STATE.current.alpha
            c.stroke.Color                = STATE.current.border
            c.stroke.Transparency         = 0.1
            c.glow.Transparency           = 0.55
            c.checkmark.Visible           = false
            -- Пульс свечения
            TweenService:Create(c.glow,
                TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                { Transparency = 0.85 }):Play()
        else
            c.frame.BackgroundColor3      = STATE.future.bg
            c.frame.BackgroundTransparency= STATE.future.alpha
            c.stroke.Color                = STATE.future.border
            c.stroke.Transparency         = 0.4
            c.glow.Transparency           = 1
            c.checkmark.Visible           = false
        end
    end

    -- Кнопка
    claimBtn.Active    = status.canClaim
    claimBtn.AutoButtonColor = status.canClaim
    claimBtn.BackgroundColor3 = status.canClaim
        and Color3.fromRGB(0, 160, 255)
        or  Color3.fromRGB(40, 50, 70)
    claimBtn.Text = status.canClaim
        and "🎁  Забрать награду"
        or  "✓  Уже получено"

    -- Таймер
    if countdownConn then countdownConn:Disconnect(); countdownConn = nil end

    if not status.canClaim and status.nextClaimAt then
        countdownConn = RunService.Heartbeat:Connect(function()
            if not gui.Enabled then return end
            local remaining = math.max(0, status.nextClaimAt - os.time())
            local h = math.floor(remaining / 3600)
            local m = math.floor((remaining % 3600) / 60)
            local s = remaining % 60
            timerLabel.Text = string.format("Следующая через %02d:%02d:%02d", h, m, s)
            if remaining <= 0 then
                timerLabel.Text = "Обновляется..."
            end
        end)
    else
        timerLabel.Text = ""
    end
end

-- Анимация открытия панели
local function openGui()
    gui.Enabled = true
    panel.Size = UDim2.fromOffset(760, 0)
    panel.BackgroundTransparency = 1
    TweenService:Create(panel,
        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.fromOffset(760, 440), BackgroundTransparency = 0 }
    ):Play()
end

-- Показать всплывашку с результатом
local function showResult(reward)
    resultBody.Text = getRewardTitle(reward)
    resultPopup.Visible = true
    resultPopup.BackgroundTransparency = 1
    resultBody.TextTransparency = 1
    resultTitle.TextTransparency = 1

    TweenService:Create(resultPopup,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0.05 }):Play()
    TweenService:Create(resultTitle,
        TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
    TweenService:Create(resultBody,
        TweenInfo.new(0.25), { TextTransparency = 0 }):Play()

    task.delay(3, function()
        TweenService:Create(resultPopup,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }):Play()
        TweenService:Create(resultTitle,
            TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        TweenService:Create(resultBody,
            TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        task.delay(0.35, function()
            resultPopup.Visible = false
        end)
    end)
end

-- ══ КНОПКА «ЗАБРАТЬ» ══
claimBtn.MouseButton1Click:Connect(function()
    if not currentStatus or not currentStatus.canClaim then return end
    claimBtn.Active = false
    claimBtn.Text = "⏳ Получение..."
    ClaimDailyReward:FireServer()
end)

-- ══ СЕРВЕР ПОДТВЕРДИЛ ══
DailyRewardClaimed.OnClientEvent:Connect(function(payload)
    -- Пометить день как полученный
    local day = payload.day
    if dayCards[day] then
        dayCards[day].checkmark.Visible = true
        dayCards[day].glow.Transparency = 1
        -- Вспышка на карточке
        local flash = Instance.new("Frame")
        flash.Size = UDim2.fromScale(1, 1)
        flash.BackgroundColor3 = Color3.new(1, 1, 1)
        flash.BackgroundTransparency = 0.3
        flash.ZIndex = 6
        flash.BorderSizePixel = 0
        flash.Parent = dayCards[day].frame
        corner(flash, 10)
        TweenService:Create(flash,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = 1 }):Play()
        task.delay(0.55, function() flash:Destroy() end)
    end

    -- Обновить кнопку и таймер
    claimBtn.Active = false
    claimBtn.AutoButtonColor = false
    claimBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
    claimBtn.Text = "✓  Уже получено"

    if currentStatus then
        currentStatus.canClaim = false
        currentStatus.streak = (currentStatus.streak or 0) + 1
        -- Пересчитать nextClaimAt (начало следующих UTC-суток)
        local today = math.floor(os.time() / 86400)
        currentStatus.nextClaimAt = (today + 1) * 86400
        applyStatus(currentStatus)
    end

    showResult(payload.reward)
end)

-- ══ КНОПКА В HUD (добавляем в MainHUD) ══
-- Маленькая кнопка-значок в правом верхнем углу
task.spawn(function()
    local mainHud = PlayerGui:WaitForChild("MainHUD", 20)
    if not mainHud then return end

    local dailyBtn = Instance.new("TextButton")
    dailyBtn.Name = "DailyBtn"
    dailyBtn.Size = UDim2.fromOffset(44, 44)
    dailyBtn.Position = UDim2.new(1, -58, 0, 10)
    dailyBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 70)
    dailyBtn.BackgroundTransparency = 0.2
    dailyBtn.Text = "🗓"
    dailyBtn.TextScaled = true
    dailyBtn.Font = Enum.Font.GothamBold
    dailyBtn.TextColor3 = Color3.new(1, 1, 1)
    dailyBtn.BorderSizePixel = 0
    dailyBtn.Parent = mainHud
    corner(dailyBtn, 10)
    uistroke(dailyBtn, Color3.fromRGB(0, 180, 255), 1.5, 0.3)

    -- Красная точка-уведомление (видна если можно забрать)
    local dot = Instance.new("Frame")
    dot.Name = "NotifDot"
    dot.Size = UDim2.fromOffset(12, 12)
    dot.Position = UDim2.new(1, -3, 0, -3)
    dot.AnchorPoint = Vector2.new(0, 0)
    dot.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    dot.BorderSizePixel = 0
    dot.Visible = false
    dot.Parent = dailyBtn
    corner(dot, 6)

    dailyBtn.MouseButton1Click:Connect(function()
        if gui.Enabled then
            gui.Enabled = false
        else
            local ok, status = pcall(function() return GetDailyStatus:InvokeServer() end)
            if ok and status then
                applyStatus(status)
            end
            openGui()
        end
    end)

    -- Хранить ссылку для управления точкой из PlayerDataLoaded
    gui:SetAttribute("DailyBtnRef", true)
    gui:SetAttribute("CanClaim", false)

    -- Обновлять точку при изменении canClaim
    local function updateDot(canClaim)
        dot.Visible = canClaim == true
        gui:SetAttribute("CanClaim", canClaim == true)
    end

    -- Первичная проверка после загрузки
    PlayerDataLoaded.OnClientEvent:Connect(function()
        task.spawn(function()
            task.wait(1)  -- дать серверу инициализироваться
            local ok, status = pcall(function() return GetDailyStatus:InvokeServer() end)
            if ok and status then
                updateDot(status.canClaim)
                -- Автооткрытие если есть незабранная награда
                if status.canClaim then
                    applyStatus(status)
                    openGui()
                end
            end
        end)
    end)

    DailyRewardClaimed.OnClientEvent:Connect(function()
        updateDot(false)
    end)
end)

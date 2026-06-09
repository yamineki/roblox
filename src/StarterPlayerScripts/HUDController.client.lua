-- StarterPlayerScripts/HUDController.client.lua
-- Reef Diver — Контроллер главного HUD
-- Монеты, зона, глубина, текущая удочка

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Strings    = require(ReplicatedStorage.Modules.Strings)
local RodData    = require(ReplicatedStorage.Modules.RodData)

local Player    = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CoinsUpdated    = Remotes:WaitForChild("CoinsUpdated")
local PlayerDataLoaded= Remotes:WaitForChild("PlayerDataLoaded")
local RodEquipped     = Remotes:WaitForChild("RodEquipped")
local WorldEventStarted = Remotes:WaitForChild("WorldEventStarted")
local WorldEventEnded   = Remotes:WaitForChild("WorldEventEnded")
local ServerAnnouncement= Remotes:WaitForChild("ServerAnnouncement")
local ComboUpdate       = Remotes:WaitForChild("ComboUpdate")
local CollectionComplete= Remotes:WaitForChild("CollectionComplete")
local ZoneEntered       = Remotes:WaitForChild("ZoneEntered")

-- Ожидание GUI
local MainHUD = PlayerGui:WaitForChild("MainHUD", 15)
local EventBanner = PlayerGui:WaitForChild("EventBanner", 15)
local AnnounceBanner = PlayerGui:WaitForChild("AnnounceBanner", 15)

-- Элементы HUD
local coinLabel, zoneLabel, depthLabel, rodLabel

if MainHUD then
    local bottomLeft = MainHUD:FindFirstChild("BottomLeft")
    local topLeft    = MainHUD:FindFirstChild("TopLeft")
    local bottomRight= MainHUD:FindFirstChild("BottomRight")

    if bottomLeft then
        coinLabel = bottomLeft:FindFirstChild("CoinsLabel")
    end
    if topLeft then
        zoneLabel  = topLeft:FindFirstChild("ZoneLabel")
        depthLabel = topLeft:FindFirstChild("DepthLabel")
    end
    if bottomRight then
        rodLabel = bottomRight:FindFirstChild("RodLabel")
    end
end

-- ══ ОБНОВИТЬ МОНЕТЫ ══
local function updateCoins(amount)
    if coinLabel then
        coinLabel.Text = "🪙 " .. tostring(amount)
    end
end

-- ══ ОБНОВИТЬ ЗОНУ / ГЛУБИНУ ══
local zoneDepths = {
    SunnyReef    = { label = Strings.Zone_SunnyReef,    depth = "0 – 100 м"     },
    CoralTrench  = { label = Strings.Zone_CoralTrench,  depth = "100 – 300 м"   },
    OpenOcean    = { label = Strings.Zone_OpenOcean,    depth = "300 – 700 м"   },
    DarkWaters   = { label = Strings.Zone_DarkWaters,   depth = "700 – 1500 м"  },
    Abyss        = { label = Strings.Zone_Abyss,        depth = "1500 – 3000 м" },
}

local function updateZone(zoneName)
    local info = zoneDepths[zoneName]
    if not info then return end
    if zoneLabel  then zoneLabel.Text  = info.label end
    if depthLabel then depthLabel.Text = info.depth  end
end

-- ══ ОБНОВИТЬ УДОЧКУ ══
local function updateRod(rodId)
    local rod = RodData:GetRod(rodId)
    if rod and rodLabel then
        rodLabel.Text = rod.displayName
        -- PLACEHOLDER: rodIcon.Image = rod.icon
    end
end

-- ══ СОБЫТИЯ ══
WorldEventStarted.OnClientEvent:Connect(function(data)
    if not EventBanner then return end
    EventBanner.Visible = true

    local nameLabel = EventBanner:FindFirstChild("EventName")
    local timerLabel = EventBanner:FindFirstChild("EventTimer")

    local eventStrKey = "Event_" .. data.eventName
    if nameLabel then
        nameLabel.Text = Strings[eventStrKey] or data.eventName
    end

    -- Анимация появления
    if EventBanner:IsA("Frame") then
        EventBanner.Position = UDim2.new(0.5, 0, -0.1, 0)
        TweenService:Create(
            EventBanner,
            TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Position = UDim2.new(0.5, 0, 0.05, 0) }
        ):Play()
    end

    -- Таймер обратного отсчёта
    local remaining = data.durationSecs
    local timerConn
    timerConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not EventBanner or not EventBanner.Parent then
            timerConn:Disconnect()
            return
        end
        remaining = remaining - dt
        if timerLabel then
            timerLabel.Text = Strings:Format("Event_Ends", math.max(0, math.floor(remaining)))
        end
        if remaining <= 0 then
            timerConn:Disconnect()
        end
    end)
end)

WorldEventEnded.OnClientEvent:Connect(function()
    if not EventBanner then return end
    TweenService:Create(
        EventBanner,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5, 0, -0.15, 0) }
    ):Play()
    task.delay(0.5, function()
        EventBanner.Visible = false
    end)
end)

-- ══ СЕРВЕРНЫЕ ОБЪЯВЛЕНИЯ ══
ServerAnnouncement.OnClientEvent:Connect(function(payload)
    if not AnnounceBanner then return end

    local msgLabel = AnnounceBanner:FindFirstChild("MessageLabel")
    local fishImg  = AnnounceBanner:FindFirstChild("FishImage")

    if msgLabel then msgLabel.Text = payload.message end
    if fishImg  then
        fishImg.Image = payload.fishImage or ""  -- PLACEHOLDER
    end

    AnnounceBanner.Visible = true
    AnnounceBanner.BackgroundTransparency = 1

    TweenService:Create(
        AnnounceBanner,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0.2 }
    ):Play()

    -- Скрыть через 5 секунд
    task.delay(5, function()
        TweenService:Create(
            AnnounceBanner,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }
        ):Play()
        task.delay(0.6, function()
            AnnounceBanner.Visible = false
        end)
    end)
end)

-- ══ PERFECT COMBO ИНДИКАТОР ══
local comboGui = PlayerGui:WaitForChild("ComboDisplay", 10)
ComboUpdate.OnClientEvent:Connect(function(payload)
    if not comboGui then return end
    local label = comboGui:FindFirstChild("ComboLabel")
    if not label then return end

    local streak = payload.streak or 0
    if streak >= 2 then
        label.Text = string.format("🔥 PERFECT ×%d  (×%.1f монет)", streak, payload.mult or 1)
        label.Visible = true
        -- Пульс
        label.TextTransparency = 0
        TweenService:Create(label,
            TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { TextSize = 28 }):Play()
        task.delay(0.2, function()
            TweenService:Create(label,
                TweenInfo.new(0.15), { TextSize = 22 }):Play()
        end)
    else
        -- Серия сброшена
        if label.Visible then
            TweenService:Create(label, TweenInfo.new(0.4),
                { TextTransparency = 1 }):Play()
            task.delay(0.4, function() label.Visible = false end)
        end
    end
end)

-- ══ КОЛЛЕКЦИЯ ЗОНЫ СОБРАНА ══
CollectionComplete.OnClientEvent:Connect(function(payload)
    if not AnnounceBanner then return end
    local msgLabel = AnnounceBanner:FindFirstChild("MessageLabel")
    if msgLabel then
        local reward = payload.reward or {}
        local txt = "🏆 Коллекция " .. (payload.zone or "") .. " собрана!"
        if reward.coins then txt = txt .. "  +🪙" .. reward.coins end
        if reward.title then txt = txt .. "  Титул: " .. reward.title end
        msgLabel.Text = txt
    end
    AnnounceBanner.Visible = true
    AnnounceBanner.BackgroundTransparency = 0.1
    task.delay(6, function()
        AnnounceBanner.Visible = false
    end)
end)

-- ══ СМЕНА ЗОНЫ ══
ZoneEntered.OnClientEvent:Connect(function(payload)
    if payload.success and payload.zoneName then
        updateZone(payload.zoneName)
    end
end)

-- ══ ИНИЦИАЛИЗАЦИЯ ══
PlayerDataLoaded.OnClientEvent:Connect(function(data)
    updateCoins(data.coins or 0)
    updateRod(data.equippedRod or "WoodenRod")
    updateZone("SunnyReef")  -- стартовая зона
end)

CoinsUpdated.OnClientEvent:Connect(updateCoins)
RodEquipped.OnClientEvent:Connect(updateRod)

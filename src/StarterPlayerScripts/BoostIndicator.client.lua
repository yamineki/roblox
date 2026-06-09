-- StarterPlayerScripts/BoostIndicator.client.lua
-- Reef Diver — Индикатор активных бустов в HUD
-- Иконки 2x/буст рядом с монетами, с таймерами для временных

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetActiveBoosts = Remotes:WaitForChild("GetActiveBoosts")
local BoostsUpdated   = Remotes:WaitForChild("BoostsUpdated")

local KIND_COLORS = {
    coin     = Color3.fromRGB(255, 200, 50),
    luck     = Color3.fromRGB(80, 220, 120),
    mutation = Color3.fromRGB(220, 100, 230),
    speed    = Color3.fromRGB(80, 200, 255),
    other    = Color3.fromRGB(160, 180, 200),
}
local KIND_ICONS = {
    coin     = "🪙",
    luck     = "🍀",
    mutation = "✨",
    speed    = "⚡",
    other    = "★",
}

-- ══ GUI (создан UIBuilder.lua) ══
local gui       = PlayerGui:WaitForChild("BoostIndicator", 20)
local container = gui:WaitForChild("BoostRow")

local activeChips = {}

local function corner(o, r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=o end

-- ══ СОЗДАТЬ ЧИП БУСТА ══
local function makeChip(boost)
    local color = KIND_COLORS[boost.kind] or KIND_COLORS.other
    local icon  = KIND_ICONS[boost.kind] or KIND_ICONS.other

    local chip = Instance.new("Frame")
    chip.Name = boost.id
    chip.Size = UDim2.fromOffset(boost.permanent and 64 or 90, 32)
    chip.BackgroundColor3 = Color3.fromRGB(12, 20, 34)
    chip.BackgroundTransparency = 0.1
    chip.BorderSizePixel = 0
    chip.LayoutOrder = boost.permanent and 1 or 2
    chip.Parent = container
    corner(chip, 8)

    local s = Instance.new("UIStroke")
    s.Color = color; s.Thickness = 1.5; s.Transparency = 0.2; s.Parent = chip

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.fromOffset(20, 20)
    iconLabel.Position = UDim2.fromOffset(5, 6)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Parent = chip

    local multLabel = Instance.new("TextLabel")
    multLabel.Size = UDim2.fromOffset(boost.permanent and 34 or 28, 20)
    multLabel.Position = UDim2.fromOffset(28, 6)
    multLabel.BackgroundTransparency = 1
    multLabel.Text = boost.permanent
        and (boost.label:match("[%d%.×%+%%]+x?") or "2×")
        or (string.format("%.0f×", boost.mult or 1))
    multLabel.TextColor3 = color
    multLabel.TextScaled = true
    multLabel.Font = Enum.Font.GothamBold
    multLabel.TextXAlignment = Enum.TextXAlignment.Left
    multLabel.Parent = chip

    local timerLabel
    if not boost.permanent and boost.endsAt then
        timerLabel = Instance.new("TextLabel")
        timerLabel.Size = UDim2.fromOffset(56, 12)
        timerLabel.Position = UDim2.fromOffset(28, 18)
        timerLabel.BackgroundTransparency = 1
        timerLabel.Text = ""
        timerLabel.TextColor3 = Color3.fromRGB(160, 180, 200)
        timerLabel.Font = Enum.Font.Gotham
        timerLabel.TextSize = 10
        timerLabel.TextXAlignment = Enum.TextXAlignment.Left
        timerLabel.Parent = chip
    end

    chip.Size = UDim2.fromOffset(0, 32)
    TweenService:Create(chip,
        TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.fromOffset(boost.permanent and 64 or 90, 32) }
    ):Play()

    return { frame = chip, endsAt = boost.endsAt, timerLabel = timerLabel, permanent = boost.permanent }
end

-- ══ ОБНОВИТЬ ЧИПЫ ══
local function refresh(boosts)
    local seen = {}

    for _, boost in ipairs(boosts) do
        seen[boost.id] = true
        if not activeChips[boost.id] then
            activeChips[boost.id] = makeChip(boost)
        else
            activeChips[boost.id].endsAt = boost.endsAt
        end
    end

    for id, chip in pairs(activeChips) do
        if not seen[id] then
            local frame = chip.frame
            TweenService:Create(frame,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Size = UDim2.fromOffset(0, 32) }
            ):Play()
            task.delay(0.22, function()
                if frame then frame:Destroy() end
            end)
            activeChips[id] = nil
        end
    end
end

BoostsUpdated.OnClientEvent:Connect(refresh)

task.spawn(function()
    local ok, boosts = pcall(function() return GetActiveBoosts:InvokeServer() end)
    if ok and boosts then refresh(boosts) end
end)

-- ══ ТИКЕР ТАЙМЕРОВ ══
task.spawn(function()
    while true do
        task.wait(1)
        local now = os.time()
        for id, chip in pairs(activeChips) do
            if chip.timerLabel and chip.endsAt then
                local remaining = chip.endsAt - now
                if remaining > 0 then
                    local m = math.floor(remaining / 60)
                    local s = remaining % 60
                    chip.timerLabel.Text = string.format("%d:%02d", m, s)
                else
                    chip.timerLabel.Text = "0:00"
                end
            end
        end
    end
end)

print("[ReefDiver] BoostIndicator инициализирован ✓")

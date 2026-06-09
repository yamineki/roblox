-- StarterPlayerScripts/CustomProximityPrompt.client.lua
-- Reef Diver — Кастомный рендер всех ProximityPrompt (Style = Custom)
-- Красивый анимированный промпт: иконка действия, клавиша, hold-прогресс
-- Цвет/иконка зависят от PromptKind (Fishing / ZoneKeeper / NPC)

local Players              = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService         = game:GetService("TweenService")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")

local Player = Players.LocalPlayer

-- ══ СТИЛИ ПО ТИПУ ПРОМПТА ══
-- icon = emoji-заглушка (PLACEHOLDER: можно заменить на ImageLabel с rbxassetid)
local PROMPT_STYLES = {
    Fishing = {
        accent   = Color3.fromRGB(0, 200, 255),
        accentDark = Color3.fromRGB(0, 90, 130),
        icon     = "🎣",
        glow     = Color3.fromRGB(0, 220, 255),
    },
    ZoneKeeper = {
        accent   = Color3.fromRGB(140, 90, 255),
        accentDark = Color3.fromRGB(70, 40, 140),
        icon     = "🌀",
        glow     = Color3.fromRGB(160, 110, 255),
    },
    NPC = {
        accent   = Color3.fromRGB(255, 190, 60),
        accentDark = Color3.fromRGB(140, 95, 20),
        icon     = "💬",
        glow     = Color3.fromRGB(255, 210, 90),
    },
    Default = {
        accent   = Color3.fromRGB(120, 200, 255),
        accentDark = Color3.fromRGB(40, 80, 120),
        icon     = "✦",
        glow     = Color3.fromRGB(150, 210, 255),
    },
}

-- Определить отображаемую клавишу
local function keyLabel(prompt)
    local gamepad = UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1
    if gamepad and prompt.GamepadKeyCode ~= Enum.KeyCode.Unknown then
        local map = {
            [Enum.KeyCode.ButtonX] = "X",
            [Enum.KeyCode.ButtonY] = "Y",
            [Enum.KeyCode.ButtonA] = "A",
            [Enum.KeyCode.ButtonB] = "B",
        }
        return map[prompt.GamepadKeyCode] or "X"
    end
    -- Клавиатура
    local kc = prompt.KeyboardKeyCode
    if kc == Enum.KeyCode.Unknown then return "E" end
    return UserInputService:GetStringForKeyCode(kc)
end

-- ══ СОЗДАТЬ ВИЗУАЛ ПРОМПТА ══
local function createPromptGui(prompt, inputType)
    local kind = prompt:GetAttribute("PromptKind") or "Default"
    local style = PROMPT_STYLES[kind] or PROMPT_STYLES.Default

    -- BillboardGui крепится к части с промптом
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CustomPrompt"
    billboard.Size = UDim2.fromOffset(260, 90)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = prompt.MaxActivationDistance + 5

    -- Корневой контейнер (для анимации появления)
    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = billboard

    -- ── Карточка ──
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(0, 0)  -- анимируется до 240x64
    card.BackgroundColor3 = Color3.fromRGB(10, 16, 28)
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    card.Parent = root

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 14)
    cardCorner.Parent = card

    -- Акцентная обводка
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = style.accent
    cardStroke.Thickness = 2
    cardStroke.Transparency = 0.1
    cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cardStroke.Parent = card

    -- Лёгкое свечение (внешняя полупрозрачная рамка)
    local glow = Instance.new("UIStroke")
    glow.Color = style.glow
    glow.Thickness = 6
    glow.Transparency = 0.85
    glow.Parent = card

    -- ── Иконка действия (слева, в кружке) ──
    local iconHolder = Instance.new("Frame")
    iconHolder.Name = "IconHolder"
    iconHolder.AnchorPoint = Vector2.new(0, 0.5)
    iconHolder.Position = UDim2.new(0, 8, 0.5, 0)
    iconHolder.Size = UDim2.fromOffset(48, 48)
    iconHolder.BackgroundColor3 = style.accentDark
    iconHolder.BackgroundTransparency = 0.2
    iconHolder.BorderSizePixel = 0
    iconHolder.Parent = card
    local ihCorner = Instance.new("UICorner")
    ihCorner.CornerRadius = UDim.new(0, 12)
    ihCorner.Parent = iconHolder

    -- PLACEHOLDER: emoji-иконка (замени на ImageLabel.Image = rbxassetid)
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.fromScale(1, 1)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = style.icon
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Parent = iconHolder

    -- ── Текст действия ──
    local actionLabel = Instance.new("TextLabel")
    actionLabel.Name = "Action"
    actionLabel.AnchorPoint = Vector2.new(0, 0.5)
    actionLabel.Position = UDim2.new(0, 64, 0.5, -8)
    actionLabel.Size = UDim2.fromOffset(120, 24)
    actionLabel.BackgroundTransparency = 1
    actionLabel.Text = prompt.ActionText ~= "" and prompt.ActionText or "Взаимодействовать"
    actionLabel.TextColor3 = Color3.new(1, 1, 1)
    actionLabel.TextScaled = true
    actionLabel.TextXAlignment = Enum.TextXAlignment.Left
    actionLabel.Font = Enum.Font.GothamBold
    actionLabel.Parent = card

    -- ── Подпись объекта (мельче) ──
    local objLabel = Instance.new("TextLabel")
    objLabel.Name = "Object"
    objLabel.AnchorPoint = Vector2.new(0, 0.5)
    objLabel.Position = UDim2.new(0, 64, 0.5, 12)
    objLabel.Size = UDim2.fromOffset(120, 16)
    objLabel.BackgroundTransparency = 1
    objLabel.Text = prompt.ObjectText
    objLabel.TextColor3 = style.accent
    objLabel.TextScaled = true
    objLabel.TextXAlignment = Enum.TextXAlignment.Left
    objLabel.Font = Enum.Font.Gotham
    objLabel.Visible = prompt.ObjectText ~= ""
    objLabel.Parent = card

    -- ── Клавиша (справа, в квадрате) ──
    local keyHolder = Instance.new("Frame")
    keyHolder.Name = "KeyHolder"
    keyHolder.AnchorPoint = Vector2.new(1, 0.5)
    keyHolder.Position = UDim2.new(1, -10, 0.5, 0)
    keyHolder.Size = UDim2.fromOffset(36, 36)
    keyHolder.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    keyHolder.BorderSizePixel = 0
    keyHolder.Parent = card
    local khCorner = Instance.new("UICorner")
    khCorner.CornerRadius = UDim.new(0, 8)
    khCorner.Parent = keyHolder
    local khStroke = Instance.new("UIStroke")
    khStroke.Color = style.accent
    khStroke.Thickness = 2
    khStroke.Parent = keyHolder

    local keyText = Instance.new("TextLabel")
    keyText.Name = "Key"
    keyText.Size = UDim2.fromScale(1, 1)
    keyText.BackgroundTransparency = 1
    keyText.Text = keyLabel(prompt)
    keyText.TextColor3 = Color3.fromRGB(20, 25, 35)
    keyText.TextScaled = true
    keyText.Font = Enum.Font.GothamBold
    keyText.Parent = keyHolder
    -- ограничить размер текста клавиши
    local keyConstraint = Instance.new("UITextSizeConstraint")
    keyConstraint.MaxTextSize = 20
    keyConstraint.Parent = keyText

    -- ── Кольцо hold-прогресса (вокруг клавиши) ──
    -- Используем UIStroke с анимацией прозрачности как индикатор
    local holdRing = Instance.new("Frame")
    holdRing.Name = "HoldRing"
    holdRing.AnchorPoint = Vector2.new(0.5, 0.5)
    holdRing.Position = UDim2.fromScale(0.5, 0.5)
    holdRing.Size = UDim2.fromScale(1.3, 1.3)
    holdRing.BackgroundTransparency = 1
    holdRing.Parent = keyHolder
    local holdStroke = Instance.new("UIStroke")
    holdStroke.Color = style.accent
    holdStroke.Thickness = 0
    holdStroke.Transparency = 0.2
    holdStroke.Parent = holdRing
    local holdCorner = Instance.new("UICorner")
    holdCorner.CornerRadius = UDim.new(0, 10)
    holdCorner.Parent = holdRing

    return billboard, {
        card = card,
        iconHolder = iconHolder,
        holdStroke = holdStroke,
        keyHolder = keyHolder,
        style = style,
    }
end

-- ══ АНИМАЦИИ ══
local activeGuis = {}  -- prompt -> { billboard, parts, connections }

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
    if prompt.Style ~= Enum.ProximityPromptStyle.Custom then return end

    local billboard, parts = createPromptGui(prompt, inputType)
    billboard.Adornee = prompt.Parent
    billboard.Parent = prompt.Parent

    activeGuis[prompt] = { billboard = billboard, parts = parts }

    -- Анимация появления: карточка раскрывается
    parts.card.Size = UDim2.fromOffset(0, 64)
    TweenService:Create(parts.card,
        TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.fromOffset(240, 64) }
    ):Play()

    -- Лёгкое «дыхание» иконки
    local pulseTween = TweenService:Create(parts.iconHolder,
        TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Size = UDim2.fromOffset(52, 52) }
    )
    pulseTween:Play()
    activeGuis[prompt].pulse = pulseTween
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
    local entry = activeGuis[prompt]
    if not entry then return end

    if entry.pulse then entry.pulse:Cancel() end

    -- Анимация исчезновения
    local card = entry.parts.card
    TweenService:Create(card,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Size = UDim2.fromOffset(0, 64) }
    ):Play()

    task.delay(0.16, function()
        if entry.billboard then entry.billboard:Destroy() end
    end)
    activeGuis[prompt] = nil
end)

-- ══ HOLD-ПРОГРЕСС ══
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
    local entry = activeGuis[prompt]
    if not entry then return end
    local holdStroke = entry.parts.holdStroke
    local keyHolder  = entry.parts.keyHolder

    -- Анимировать рост кольца за время HoldDuration
    holdStroke.Thickness = 0
    TweenService:Create(holdStroke,
        TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear),
        { Thickness = 4 }
    ):Play()

    -- Сжать клавишу (эффект нажатия)
    TweenService:Create(keyHolder,
        TweenInfo.new(0.1),
        { Size = UDim2.fromOffset(32, 32) }
    ):Play()
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
    local entry = activeGuis[prompt]
    if not entry then return end
    local holdStroke = entry.parts.holdStroke
    local keyHolder  = entry.parts.keyHolder

    holdStroke.Thickness = 0
    TweenService:Create(keyHolder,
        TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.fromOffset(36, 36) }
    ):Play()
end)

-- ══ ВСПЫШКА ПРИ СРАБАТЫВАНИИ ══
ProximityPromptService.PromptTriggered:Connect(function(prompt)
    local entry = activeGuis[prompt]
    if not entry then return end
    local card = entry.parts.card
    local style = entry.parts.style

    -- Короткая вспышка акцентным цветом
    local flash = TweenService:Create(card,
        TweenInfo.new(0.08, Enum.EasingStyle.Quad),
        { BackgroundColor3 = style.accent }
    )
    flash:Play()
    flash.Completed:Connect(function()
        TweenService:Create(card,
            TweenInfo.new(0.2),
            { BackgroundColor3 = Color3.fromRGB(10, 16, 28) }
        ):Play()
    end)
end)

print("[ReefDiver] CustomProximityPrompt инициализирован ✓")

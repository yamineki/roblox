-- StarterGui/GUIStubs.client.lua
-- Reef Diver — Минимальные GUI заглушки
-- CustomInventory.client.lua полностью управляет инвентарём
-- Здесь только Event-баннеры и Announcement-баннеры

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Отключить стандартный Backpack (дублирующий вызов на случай race condition)
local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local function makeScreenGui(name)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 126
    gui.Parent = PlayerGui
    return gui
end

local function makeFrame(name, parent, size, pos, color, transp)
    local f = Instance.new("Frame")
    f.Name = name
    f.Size = size or UDim2.fromScale(1,1)
    f.Position = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = color or Color3.fromRGB(5,15,30)
    f.BackgroundTransparency = transp or 0
    f.BorderSizePixel = 0
    f.Parent = parent
    return f
end

local function makeLabel(name, parent, text, size, pos, textColor, fontSize)
    local l = Instance.new("TextLabel")
    l.Name = name; l.Text = text or ""
    l.Size = size or UDim2.fromScale(1,1)
    l.Position = pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency = 1
    l.TextColor3 = textColor or Color3.new(1,1,1)
    l.Font = Enum.Font.GothamBold
    l.TextScaled = true
    l.Parent = parent
    return l
end

local function makeCorner(parent, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = parent
end

-- ══ 1. MAIN HUD (монеты, зона, удочка) ══
do
    local gui = makeScreenGui("MainHUD")
    gui.DisplayOrder = 120

    local bl = makeFrame("BottomLeft", gui,
        UDim2.fromOffset(200, 50),
        UDim2.new(0, 10, 1, -60),
        Color3.fromRGB(5,15,30), 0.3)
    makeCorner(bl, 8)
    makeLabel("CoinsLabel", bl, "🪙 0", UDim2.fromScale(1,1),
        UDim2.fromScale(0,0), Color3.fromRGB(255,210,50))

    local tl = makeFrame("TopLeft", gui,
        UDim2.fromOffset(220, 70),
        UDim2.new(0, 10, 0, 10),
        Color3.fromRGB(5,15,30), 0.3)
    makeCorner(tl, 8)
    makeLabel("ZoneLabel",  tl, "Sunny Reef", UDim2.new(1,0,0.5,0), UDim2.new(0,0,0,0),   Color3.fromRGB(0,220,255))
    makeLabel("DepthLabel", tl, "0 – 100 м",  UDim2.new(1,0,0.5,0), UDim2.new(0,0,0.5,0), Color3.fromRGB(100,180,200))

    local br = makeFrame("BottomRight", gui,
        UDim2.fromOffset(200, 50),
        UDim2.new(1, -210, 1, -60),
        Color3.fromRGB(5,15,30), 0.3)
    makeCorner(br, 8)
    makeLabel("RodLabel", br, "🎣 Wooden Rod", UDim2.fromScale(1,1),
        UDim2.fromScale(0,0), Color3.fromRGB(180,220,255))
end

-- ══ 2. FISHING GUI (мини-игра) ══
do
    local gui = makeScreenGui("FishingGui")
    gui.DisplayOrder = 130

    -- Hook Phase
    local hookPhase = makeFrame("HookPhase", gui,
        UDim2.fromScale(1,1), UDim2.new(0,0,0,0),
        Color3.new(0,0,0), 0.5)
    hookPhase.Visible = false

    local circle = Instance.new("ImageLabel")
    circle.Name = "CircleIndicator"
    circle.Image = ""  -- PLACEHOLDER: rbxassetid://круговой индикатор
    circle.Size = UDim2.fromOffset(300, 300)
    circle.Position = UDim2.new(0.5,-150, 0.5,-150)
    circle.BackgroundColor3 = Color3.fromRGB(10,20,40)
    circle.BackgroundTransparency = 0.3
    circle.Parent = hookPhase
    makeCorner(circle, 150)

    local arrow = Instance.new("ImageLabel")
    arrow.Name = "Arrow"
    arrow.Image = ""  -- PLACEHOLDER
    arrow.Size = UDim2.fromOffset(8, 130)
    arrow.Position = UDim2.new(0.5,-4, 0.5,-130)
    arrow.AnchorPoint = Vector2.new(0.5, 1)
    arrow.BackgroundColor3 = Color3.fromRGB(0,200,255)
    arrow.BorderSizePixel = 0
    arrow.Parent = hookPhase
    makeCorner(arrow, 4)

    -- Зелёная зона Hook (дуга 75°)
    local greenArc = makeFrame("GreenZone", hookPhase,
        UDim2.fromOffset(300, 300),
        UDim2.new(0.5,-150, 0.5,-150),
        Color3.fromRGB(0,200,80), 0.6)
    makeCorner(greenArc, 150)

    makeLabel("HintLabel", hookPhase, "Нажми [E] для подсечки!",
        UDim2.fromOffset(400, 40),
        UDim2.new(0.5,-200, 0.75,0),
        Color3.fromRGB(0,220,255))

    -- Catch Phase
    local catchPhase = makeFrame("CatchPhase", gui,
        UDim2.fromScale(1,1), UDim2.new(0,0,0,0),
        Color3.new(0,0,0), 0.5)
    catchPhase.Visible = false

    local scaleFrame = makeFrame("ScaleFrame", catchPhase,
        UDim2.fromOffset(60, 400),
        UDim2.new(0.5,-30, 0.5,-200),
        Color3.fromRGB(20,40,80), 0.2)
    makeCorner(scaleFrame, 6)

    local greenZone = makeFrame("GreenZone", scaleFrame,
        UDim2.new(1,0,0,80),
        UDim2.new(0,0,0.5,-40),
        Color3.fromRGB(0,200,80), 0.3)
    makeCorner(greenZone, 4)

    local fishInd = Instance.new("ImageLabel")
    fishInd.Name = "FishIndicator"
    fishInd.Image = ""  -- PLACEHOLDER
    fishInd.Size = UDim2.fromOffset(50,30)
    fishInd.Position = UDim2.new(-1,0, 0.5,-15)
    fishInd.BackgroundColor3 = Color3.fromRGB(255,150,50)
    fishInd.BorderSizePixel = 0
    fishInd.Parent = scaleFrame
    makeCorner(fishInd, 6)

    local pbContainer = makeFrame("ProgressBar", catchPhase,
        UDim2.fromOffset(20, 400),
        UDim2.new(0.5,35, 0.5,-200),
        Color3.fromRGB(10,20,40), 0.2)
    makeCorner(pbContainer, 4)
    local fill = makeFrame("Fill", pbContainer,
        UDim2.new(1,0,0,0),
        UDim2.new(0,0,1,0),
        Color3.fromRGB(0,220,100), 0)

    makeLabel("StressLabel", catchPhase, "⚠ Рыба злится!",
        UDim2.fromOffset(300,40), UDim2.new(0.5,-150, 0.15,0),
        Color3.fromRGB(255,100,50))
    makeLabel("PerfectLabel", catchPhase, "PERFECT CATCH!",
        UDim2.fromOffset(300,40), UDim2.new(0.5,-150, 0.08,0),
        Color3.fromRGB(0,255,150))
    makeLabel("BehaviorLabel", catchPhase, "Lazy",
        UDim2.fromOffset(200,30), UDim2.new(0.5,-100, 0.22,0),
        Color3.fromRGB(150,200,255))
    makeLabel("EscapeLabel", catchPhase, "Рыба сбежала...",
        UDim2.fromOffset(400,50), UDim2.new(0.5,-200, 0.45,0),
        Color3.fromRGB(255,80,80))

    -- Result Phase
    local resultPhase = makeFrame("ResultPhase", gui,
        UDim2.fromOffset(400,550),
        UDim2.new(0.5,-200, 0.5,-275),
        Color3.fromRGB(5,15,35), 0.1)
    resultPhase.Visible = false
    makeCorner(resultPhase, 12)

    local fishImg = Instance.new("ImageLabel")
    fishImg.Name = "FishImage"
    fishImg.Image = ""  -- PLACEHOLDER
    fishImg.Size = UDim2.new(0.8,0,0.38,0)
    fishImg.Position = UDim2.new(0.1,0, 0.04,0)
    fishImg.BackgroundColor3 = Color3.fromRGB(10,20,40)
    fishImg.BackgroundTransparency = 0.4
    fishImg.ScaleType = Enum.ScaleType.Fit
    fishImg.Parent = resultPhase
    makeCorner(fishImg, 10)

    makeLabel("FishName",    resultPhase, "???",     UDim2.new(1,0,0.08,0), UDim2.new(0,0,0.44,0), Color3.fromRGB(255,220,100))
    makeLabel("FishRarity",  resultPhase, "Common",  UDim2.new(0.5,0,0.07,0),UDim2.new(0.1,0,0.52,0),Color3.fromRGB(180,180,180))
    makeLabel("FishSize",    resultPhase, "Normal",  UDim2.new(0.5,0,0.07,0),UDim2.new(0.5,0,0.52,0),Color3.fromRGB(0,220,200))
    makeLabel("FishMutation",resultPhase, "",        UDim2.new(1,0,0.07,0),  UDim2.new(0,0,0.60,0), Color3.fromRGB(255,100,220))
    makeLabel("FishValue",   resultPhase, "0 🪙",    UDim2.new(1,0,0.08,0),  UDim2.new(0,0,0.68,0), Color3.fromRGB(255,210,50))
    makeLabel("PerfectBonus",resultPhase, "+25% Perfect!", UDim2.new(1,0,0.06,0),UDim2.new(0,0,0.77,0),Color3.fromRGB(0,255,150))
end

-- ══ 3. EVENT BANNER ══
do
    local gui = makeScreenGui("EventBanner")
    local banner = makeFrame("EventBanner", gui,
        UDim2.fromOffset(500,60),
        UDim2.new(0.5,-250, -0.1,0),
        Color3.fromRGB(5,15,35), 0.1)
    makeCorner(banner, 10)
    banner.Visible = false
    makeLabel("EventName",  banner, "🌀 Event",  UDim2.new(0.6,0,1,0), UDim2.new(0,5,0,0),   Color3.fromRGB(0,220,255))
    makeLabel("EventTimer", banner, "...",        UDim2.new(0.38,0,1,0),UDim2.new(0.6,0,0,0), Color3.fromRGB(200,200,200))
end

-- ══ 4. ANNOUNCEMENT BANNER ══
do
    local gui = makeScreenGui("AnnounceBanner")
    local banner = makeFrame("AnnounceBanner", gui,
        UDim2.fromOffset(700,80),
        UDim2.new(0.5,-350, 0,10),
        Color3.fromRGB(5,15,35), 0.2)
    makeCorner(banner, 10)
    banner.Visible = false

    local fishImg = Instance.new("ImageLabel")
    fishImg.Name = "FishImage"
    fishImg.Image = ""  -- PLACEHOLDER
    fishImg.Size = UDim2.fromOffset(70,70)
    fishImg.Position = UDim2.fromOffset(5,5)
    fishImg.BackgroundTransparency = 1
    fishImg.Parent = banner

    makeLabel("MessageLabel", banner, "",
        UDim2.new(0.85,0,1,0), UDim2.new(0,85,0,0),
        Color3.fromRGB(255,220,100))
end

-- ══ 5. SHOP GUI (магазин удочек) ══
do
    local gui = makeScreenGui("ShopGui")
    gui.DisplayOrder = 128

    local panel = makeFrame("ShopPanel", gui,
        UDim2.fromOffset(700, 600),
        UDim2.new(0.5, -350, 1.5, 0),  -- ниже экрана (анимируется ShopController)
        Color3.fromRGB(5, 15, 35), 0.05)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    makeCorner(panel, 14)

    makeLabel("Title", panel, "🎣 Магазин удочек",
        UDim2.new(1, 0, 0.1, 0), UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(255, 210, 50))

    local grid = Instance.new("ScrollingFrame")
    grid.Name = "RodGrid"
    grid.Size = UDim2.new(0.95, 0, 0.78, 0)
    grid.Position = UDim2.new(0.025, 0, 0.1, 0)
    grid.BackgroundTransparency = 1
    grid.ScrollBarThickness = 5
    grid.ScrollBarImageColor3 = Color3.fromRGB(0, 180, 255)
    grid.CanvasSize = UDim2.new(0, 0, 0, 0)
    grid.Parent = panel

    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0.48, 0, 0, 120)
    layout.CellPadding = UDim2.new(0.02, 0, 0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = grid

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0.3, 0, 0.07, 0)
    closeBtn.Position = UDim2.new(0.35, 0, 0.91, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Text = "✕ Закрыть"
    closeBtn.Parent = panel
    makeCorner(closeBtn, 8)

    gui.Enabled = true
    panel.Visible = true  -- ShopController управляет видимостью ScreenGui.Enabled
    gui.Enabled = false   -- по умолчанию закрыт
end

-- ══ 6. TEST BUTTONS (временно, убрать после привязки NPC) ══
do
    local gui = makeScreenGui("TestButtons")
    gui.DisplayOrder = 200

    local panel = makeFrame("TestPanel", gui,
        UDim2.fromOffset(160, 130),
        UDim2.new(1, -170, 0, 90),
        Color3.fromRGB(10, 10, 10), 0.3)
    makeCorner(panel, 8)
    makeLabel("TestLabel", panel, "⚙ TEST",
        UDim2.new(1, 0, 0.22, 0), UDim2.new(0, 0, 0, 4),
        Color3.fromRGB(200, 200, 200))

    local function mkBtn(name, text, y, color)
        local b = Instance.new("TextButton")
        b.Name = name
        b.Size = UDim2.new(0.9, 0, 0.3, 0)
        b.Position = UDim2.new(0.05, 0, y, 0)
        b.BackgroundColor3 = color
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.Text = text
        b.Parent = panel
        makeCorner(b, 6)
        return b
    end
    mkBtn("OpenShop",  "Магазин",  0.28, Color3.fromRGB(0, 120, 200))
    mkBtn("CloseShop", "Закрыть",  0.62, Color3.fromRGB(150, 40, 40))
end

-- ══ 7. COMBO DISPLAY ══
do
    local gui = makeScreenGui("ComboDisplay")
    gui.DisplayOrder = 131
    local label = Instance.new("TextLabel")
    label.Name = "ComboLabel"
    label.Size = UDim2.fromOffset(400, 40)
    label.Position = UDim2.new(0.5, -200, 0.28, 0)
    label.BackgroundTransparency = 1
    label.Text = ""
    label.TextColor3 = Color3.fromRGB(255, 180, 40)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 22
    label.TextStrokeTransparency = 0.4
    label.Visible = false
    label.Parent = gui
end

print("[ReefDiver] GUIStubs инициализированы ✓")

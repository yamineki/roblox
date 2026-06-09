-- StarterGui/CustomInventory.client.lua
-- Reef Diver — Кастомный инвентарь
-- Полностью заменяет стандартный Roblox Backpack
-- Хотбар снизу (удочки) + панель рыб (открывается по кнопке)
-- Удочки = Roblox Tool (держатся в руке через Handle)
-- Рыбы = 2D иконки с атрибутами

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

-- Отключить стандартный Roblox Backpack
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid")
local Backpack  = Player:WaitForChild("Backpack")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Strings = require(ReplicatedStorage.Modules.Strings)
local RodData = require(ReplicatedStorage.Modules.RodData)

-- ══ КОНСТАНТЫ ══
local SLOT_SIZE        = 70    -- px размер слота хотбара
local SLOT_GAP         = 8     -- px между слотами
local SLOT_PADDING     = 10    -- px внешний отступ хотбара
local HOTBAR_ROD_COUNT = 5     -- максимум удочек в хотбаре (из 10)
local ANIM_TIME        = 0.25  -- сек анимации открытия
local FISH_SLOT_SIZE   = 80    -- px размер слота рыбы
local FISH_COLS        = 5     -- колонок в инвентаре рыб
local FISH_ROWS_VIS    = 3     -- видимых строк рыб

-- Цвета редкости
local RARITY_COLORS = {
    Common    = Color3.fromRGB(170, 170, 170),
    Uncommon  = Color3.fromRGB(68,  204, 102),
    Rare      = Color3.fromRGB(85,  153, 255),
    Epic      = Color3.fromRGB(170, 102, 255),
    Legendary = Color3.fromRGB(255, 204, 68),
    Mythic    = Color3.fromRGB(255, 102, 85),
    Secret    = Color3.fromRGB(255, 68,  204),
}

local MUTATION_COLORS = {
    Golden          = Color3.fromRGB(255, 215, 0),
    Frozen          = Color3.fromRGB(136, 221, 255),
    Crystal         = Color3.fromRGB(200, 220, 255),
    Shadow          = Color3.fromRGB(136, 68,  204),
    Toxic           = Color3.fromRGB(136, 255, 68),
    Infernal        = Color3.fromRGB(255, 85,  34),
    Lunar           = Color3.fromRGB(170, 187, 255),
    Solar           = Color3.fromRGB(255, 204, 51),
    Cosmic          = Color3.fromRGB(204, 136, 255),
    Prismatic       = Color3.fromRGB(255, 68,  238),
    Ancient         = Color3.fromRGB(221, 170, 85),
    Primordial      = Color3.fromRGB(255, 136, 34),
    LeviathanTouched= Color3.fromRGB(0,   255, 204),
}

-- ══ СОСТОЯНИЕ ══
local isInventoryOpen  = false
local isFishPanelOpen  = false
local equippedRodId    = nil
local hotbarSlots      = {}    -- { slotFrame, rodId, isEmpty }
local fishItems        = {}    -- кэш текущих рыб { itemName, fishId, ... }
local selectedFishItem = nil   -- для highlight в UI
local textBoxFocused   = false

-- ══ GUI ROOT ══
local InventoryGui = Instance.new("ScreenGui")
InventoryGui.Name = "ReefDiverInventory"
InventoryGui.DisplayOrder = 125
InventoryGui.IgnoreGuiInset = true
InventoryGui.ResetOnSpawn = false
InventoryGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
InventoryGui.Parent = PlayerGui

-- ══ ХЕЛПЕРЫ ══
local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function makeStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.new(1,1,1)
    s.Thickness = thickness or 1.5
    s.Transparency = transparency or 0.6
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function makePadding(parent, all)
    local p = Instance.new("UIPadding")
    local u = UDim.new(0, all or 6)
    p.PaddingTop = u; p.PaddingBottom = u
    p.PaddingLeft = u; p.PaddingRight = u
    p.Parent = parent
end

local function tween(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or ANIM_TIME,
            style or Enum.EasingStyle.Quart,
            dir or Enum.EasingDirection.Out),
        props):Play()
end

-- ══ ФОНОВЫЙ КОНТЕЙНЕР ══
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromScale(1, 1)
MainFrame.BackgroundTransparency = 1
MainFrame.Parent = InventoryGui

-- ══════════════════════════════════════════
--   ХОТБАР (УДОЧКИ)
-- ══════════════════════════════════════════

local hotbarWidth = SLOT_PADDING * 2 + HOTBAR_ROD_COUNT * SLOT_SIZE + (HOTBAR_ROD_COUNT - 1) * SLOT_GAP
local hotbarHeight = SLOT_PADDING * 2 + SLOT_SIZE

local HotbarBG = Instance.new("Frame")
HotbarBG.Name = "HotbarBG"
HotbarBG.Size = UDim2.fromOffset(hotbarWidth, hotbarHeight)
HotbarBG.Position = UDim2.new(0.5, -hotbarWidth/2, 1, -(hotbarHeight + 12))
HotbarBG.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
HotbarBG.BackgroundTransparency = 0.15
HotbarBG.BorderSizePixel = 0
HotbarBG.Parent = MainFrame
makeCorner(HotbarBG, 12)
makeStroke(HotbarBG, Color3.fromRGB(0, 180, 255), 1.5, 0.55)

-- Список удочек (слоты хотбара)
for i = 1, HOTBAR_ROD_COUNT do
    local x = SLOT_PADDING + (i-1) * (SLOT_SIZE + SLOT_GAP)

    local slotFrame = Instance.new("Frame")
    slotFrame.Name = "RodSlot_" .. i
    slotFrame.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
    slotFrame.Position = UDim2.fromOffset(x, SLOT_PADDING)
    slotFrame.BackgroundColor3 = Color3.fromRGB(8, 14, 25)
    slotFrame.BackgroundTransparency = 0.3
    slotFrame.BorderSizePixel = 0
    slotFrame.Parent = HotbarBG
    makeCorner(slotFrame, 8)

    -- Иконка удочки (PLACEHOLDER: заменить ImageLabel.Image)
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.75, 0, 0.75, 0)
    icon.Position = UDim2.fromScale(0.5, 0.4)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = ""  -- PLACEHOLDER: rbxassetid://XXXXX
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Visible = false
    icon.Parent = slotFrame

    -- Текст (когда нет иконки)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -4, 0.5, 0)
    nameLabel.Position = UDim2.fromScale(0.5, 0.55)
    nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = ""
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextWrapped = true
    nameLabel.Visible = false
    nameLabel.Parent = slotFrame

    -- Номер слота
    local numLabel = Instance.new("TextLabel")
    numLabel.Name = "Number"
    numLabel.Size = UDim2.fromOffset(18, 18)
    numLabel.Position = UDim2.new(0, 4, 0, 4)
    numLabel.BackgroundTransparency = 1
    numLabel.Text = tostring(i)
    numLabel.TextColor3 = Color3.fromRGB(120, 160, 200)
    numLabel.TextScaled = true
    numLabel.Font = Enum.Font.GothamBold
    numLabel.ZIndex = 3
    numLabel.Parent = slotFrame

    -- Индикатор экипировки (синяя нижняя полоска)
    local equipBar = Instance.new("Frame")
    equipBar.Name = "EquipBar"
    equipBar.Size = UDim2.new(0.7, 0, 0, 3)
    equipBar.Position = UDim2.new(0.15, 0, 1, -5)
    equipBar.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    equipBar.BorderSizePixel = 0
    equipBar.Visible = false
    makeCorner(equipBar, 2)
    equipBar.Parent = slotFrame

    -- Кнопка
    local btn = Instance.new("TextButton")
    btn.Name = "Button"
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 5
    btn.Parent = slotFrame

    hotbarSlots[i] = {
        frame    = slotFrame,
        icon     = icon,
        nameLabel= nameLabel,
        equipBar = equipBar,
        button   = btn,
        rodId    = nil,
        isEmpty  = true,
    }
end

-- ══ КНОПКА ОТКРЫТИЯ ИНВЕНТАРЯ РЫБ ══
local fishBtnSize = 42
local fishButton = Instance.new("TextButton")
fishButton.Name = "FishInventoryToggle"
fishButton.Size = UDim2.fromOffset(fishBtnSize + 30, fishBtnSize)
fishButton.Position = UDim2.new(0.5, hotbarWidth/2 + 12, 1, -(hotbarHeight/2 + fishBtnSize/2 + 12))
fishButton.BackgroundColor3 = Color3.fromRGB(0, 140, 200)
fishButton.BackgroundTransparency = 0.1
fishButton.BorderSizePixel = 0
fishButton.Text = "🐟 ▲"
fishButton.TextColor3 = Color3.new(1,1,1)
fishButton.Font = Enum.Font.GothamBold
fishButton.TextSize = 14
fishButton.Parent = MainFrame
makeCorner(fishButton, 8)

-- ══════════════════════════════════════════
--   ПАНЕЛЬ РЫБ (ИНВЕНТАРЬ)
-- ══════════════════════════════════════════

local fishPanelW = FISH_COLS * (FISH_SLOT_SIZE + SLOT_GAP) + SLOT_GAP + 220  -- +220 = панель деталей
local fishPanelH = FISH_ROWS_VIS * (FISH_SLOT_SIZE + SLOT_GAP) + SLOT_GAP + 60  -- 60 = заголовок

local fishPanelOpenY   = -(hotbarHeight + fishPanelH + 16)
local fishPanelClosedY = -(hotbarHeight + 8)

local FishPanel = Instance.new("Frame")
FishPanel.Name = "FishPanel"
FishPanel.Size = UDim2.fromOffset(fishPanelW, fishPanelH)
FishPanel.Position = UDim2.new(0.5, -fishPanelW/2, 1, fishPanelClosedY)
FishPanel.BackgroundColor3 = Color3.fromRGB(8, 14, 28)
FishPanel.BackgroundTransparency = 0.08
FishPanel.BorderSizePixel = 0
FishPanel.ClipsDescendants = false
FishPanel.Visible = false
FishPanel.Parent = MainFrame
makeCorner(FishPanel, 12)
makeStroke(FishPanel, Color3.fromRGB(0, 180, 255), 1.5, 0.5)

-- Заголовок панели рыб
local fishHeader = Instance.new("Frame")
fishHeader.Name = "Header"
fishHeader.Size = UDim2.new(1, 0, 0, 52)
fishHeader.BackgroundColor3 = Color3.fromRGB(5, 12, 22)
fishHeader.BackgroundTransparency = 0.2
fishHeader.BorderSizePixel = 0
fishHeader.Parent = FishPanel
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = fishHeader
end

local fishTitle = Instance.new("TextLabel")
fishTitle.Size = UDim2.new(0.5, 0, 1, 0)
fishTitle.Position = UDim2.fromOffset(16, 0)
fishTitle.BackgroundTransparency = 1
fishTitle.Text = "🐠 Улов"
fishTitle.TextColor3 = Color3.fromRGB(0, 220, 255)
fishTitle.Font = Enum.Font.GothamBold
fishTitle.TextSize = 18
fishTitle.TextXAlignment = Enum.TextXAlignment.Left
fishTitle.Parent = fishHeader

-- Счётчик рыб
local fishCountLabel = Instance.new("TextLabel")
fishCountLabel.Name = "FishCount"
fishCountLabel.Size = UDim2.new(0.45, 0, 1, 0)
fishCountLabel.Position = UDim2.new(0.5, 0, 0, 0)
fishCountLabel.BackgroundTransparency = 1
fishCountLabel.Text = "0 рыб"
fishCountLabel.TextColor3 = Color3.fromRGB(120, 180, 220)
fishCountLabel.Font = Enum.Font.Gotham
fishCountLabel.TextSize = 13
fishCountLabel.TextXAlignment = Enum.TextXAlignment.Center
fishCountLabel.Parent = fishHeader

-- Подсказка о продаже
local sellHintLabel = Instance.new("TextLabel")
sellHintLabel.Name = "SellHint"
sellHintLabel.Size = UDim2.new(0.45, -10, 1, 0)
sellHintLabel.Position = UDim2.new(0.55, 0, 0, 0)
sellHintLabel.BackgroundTransparency = 1
sellHintLabel.Text = "💬 Продай у Fish Merchant"
sellHintLabel.TextColor3 = Color3.fromRGB(70, 110, 150)
sellHintLabel.Font = Enum.Font.Gotham
sellHintLabel.TextSize = 11
sellHintLabel.TextXAlignment = Enum.TextXAlignment.Right
sellHintLabel.TextYAlignment = Enum.TextYAlignment.Center
sellHintLabel.Parent = fishHeader

-- ══ СЕТКА РЫБ ══
local fishGridW = FISH_COLS * (FISH_SLOT_SIZE + SLOT_GAP) + SLOT_GAP
local fishGridH = fishPanelH - 52  -- минус заголовок

local FishScrollFrame = Instance.new("ScrollingFrame")
FishScrollFrame.Name = "FishGrid"
FishScrollFrame.Size = UDim2.fromOffset(fishGridW, fishGridH)
FishScrollFrame.Position = UDim2.fromOffset(0, 52)
FishScrollFrame.BackgroundTransparency = 1
FishScrollFrame.BorderSizePixel = 0
FishScrollFrame.ScrollBarThickness = 5
FishScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 180, 255)
FishScrollFrame.ScrollBarImageTransparency = 0.4
FishScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
FishScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
FishScrollFrame.ClipsDescendants = true
FishScrollFrame.Parent = FishPanel

local fishGrid = Instance.new("Frame")
fishGrid.Name = "Grid"
fishGrid.Size = UDim2.new(1, 0, 1, 0)
fishGrid.BackgroundTransparency = 1
fishGrid.Parent = FishScrollFrame

local fishGridLayout = Instance.new("UIGridLayout")
fishGridLayout.CellSize = UDim2.fromOffset(FISH_SLOT_SIZE, FISH_SLOT_SIZE)
fishGridLayout.CellPadding = UDim2.fromOffset(SLOT_GAP, SLOT_GAP)
fishGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
fishGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
fishGridLayout.Parent = fishGrid

local fishGridPadding = Instance.new("UIPadding")
fishGridPadding.PaddingLeft = UDim.new(0, SLOT_GAP)
fishGridPadding.PaddingTop = UDim.new(0, SLOT_GAP)
fishGridPadding.Parent = fishGrid

-- ══ ПАНЕЛЬ ДЕТАЛЕЙ РЫБЫ (справа) ══
local detailPanelW = fishPanelW - fishGridW - 8
local DetailPanel = Instance.new("Frame")
DetailPanel.Name = "DetailPanel"
DetailPanel.Size = UDim2.fromOffset(detailPanelW - 8, fishGridH - 8)
DetailPanel.Position = UDim2.fromOffset(fishGridW + 4, 56)
DetailPanel.BackgroundColor3 = Color3.fromRGB(5, 12, 22)
DetailPanel.BackgroundTransparency = 0.2
DetailPanel.BorderSizePixel = 0
DetailPanel.Parent = FishPanel
makeCorner(DetailPanel, 10)
makeStroke(DetailPanel, Color3.fromRGB(0, 180, 255), 1, 0.7)

-- Иконка рыбы в деталях
local detailIcon = Instance.new("ImageLabel")
detailIcon.Name = "Icon"
detailIcon.Size = UDim2.fromOffset(detailPanelW - 40, detailPanelW - 40)
detailIcon.Position = UDim2.new(0.5, 0, 0, 16)
detailIcon.AnchorPoint = Vector2.new(0.5, 0)
detailIcon.BackgroundTransparency = 1
detailIcon.Image = ""  -- PLACEHOLDER
detailIcon.ScaleType = Enum.ScaleType.Fit
detailIcon.Parent = DetailPanel

-- Заглушка иконки (emoji или текст)
local detailIconPlaceholder = Instance.new("TextLabel")
detailIconPlaceholder.Name = "IconPlaceholder"
detailIconPlaceholder.Size = UDim2.fromOffset(detailPanelW - 40, detailPanelW - 40)
detailIconPlaceholder.Position = UDim2.new(0.5, 0, 0, 16)
detailIconPlaceholder.AnchorPoint = Vector2.new(0.5, 0)
detailIconPlaceholder.BackgroundColor3 = Color3.fromRGB(10, 20, 40)
detailIconPlaceholder.BackgroundTransparency = 0.3
detailIconPlaceholder.Text = "🐟"
detailIconPlaceholder.TextScaled = true
detailIconPlaceholder.Font = Enum.Font.GothamBold
detailIconPlaceholder.TextColor3 = Color3.new(1,1,1)
detailIconPlaceholder.Parent = DetailPanel
makeCorner(detailIconPlaceholder, 8)

local function makeDetailRow(name, yOff, labelText, valueText, valueColor)
    local row = Instance.new("Frame")
    row.Name = name
    row.Size = UDim2.new(1, -16, 0, 22)
    row.Position = UDim2.fromOffset(8, yOff)
    row.BackgroundTransparency = 1
    row.Parent = DetailPanel

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Size = UDim2.fromScale(0.45, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(120, 160, 200)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local val = Instance.new("TextLabel")
    val.Name = "Value"
    val.Size = UDim2.fromScale(0.55, 1)
    val.Position = UDim2.fromScale(0.45, 0)
    val.BackgroundTransparency = 1
    val.Text = valueText or "—"
    val.TextColor3 = valueColor or Color3.new(1,1,1)
    val.Font = Enum.Font.GothamBold
    val.TextSize = 12
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Parent = row

    return val  -- вернуть Value label для обновления
end

local iconAreaH = detailPanelW - 40 + 20
local detailName        = makeDetailRow("RowName",     iconAreaH,      "Имя",      "—", Color3.fromRGB(255,220,100))
local detailRarity      = makeDetailRow("RowRarity",   iconAreaH+26,   "Редкость", "—")
local detailSize        = makeDetailRow("RowSize",     iconAreaH+50,   "Размер",   "—", Color3.fromRGB(0,220,200))
local detailMutation    = makeDetailRow("RowMutation", iconAreaH+74,   "Мутация",  "—", Color3.fromRGB(255,100,220))
local detailValue       = makeDetailRow("RowValue",    iconAreaH+98,   "Цена",     "—", Color3.fromRGB(255,210,50))
local detailZone        = makeDetailRow("RowZone",     iconAreaH+122,  "Зона",     "—", Color3.fromRGB(0,180,255))

-- (продажа только у NPC Fish Merchant — кнопки продажи в инвентаре нет)

-- Placeholder текст "выбери рыбу"
local detailPlaceholder = Instance.new("TextLabel")
detailPlaceholder.Name = "Placeholder"
detailPlaceholder.Size = UDim2.fromScale(1, 0.3)
detailPlaceholder.Position = UDim2.fromScale(0, 0.35)
detailPlaceholder.BackgroundTransparency = 1
detailPlaceholder.Text = "Выбери рыбу\nчтобы увидеть детали"
detailPlaceholder.TextColor3 = Color3.fromRGB(80, 120, 160)
detailPlaceholder.Font = Enum.Font.Gotham
detailPlaceholder.TextSize = 13
detailPlaceholder.TextWrapped = true
detailPlaceholder.Parent = DetailPanel

-- ══════════════════════════════════════════
--   ЛОГИКА ХОТБАРА (УДОЧКИ)
-- ══════════════════════════════════════════

local function getCharacter()
    return Player.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isToolEquipped(toolName)
    local char = getCharacter()
    if not char then return false end
    return char:FindFirstChild(toolName) ~= nil
end

local function equipTool(toolName)
    local hum = getHumanoid()
    if not hum then return end

    -- Сначала снять ВСЁ — за раз можно держать только одну удочку
    hum:UnequipTools()

    -- Небольшая пауза чтобы Roblox успел вернуть Tool в Backpack
    task.defer(function()
        local tool = Backpack:FindFirstChild(toolName)
        if tool then
            hum:EquipTool(tool)
        end
    end)
end

local function unequipAll()
    local hum = getHumanoid()
    if hum then hum:UnequipTools() end
end

-- Обновить отображение слота хотбара
local function updateHotbarSlot(slotIdx, rodId)
    local slot = hotbarSlots[slotIdx]
    if not slot then return end

    if not rodId then
        -- Пустой слот
        slot.rodId = nil
        slot.isEmpty = true
        slot.icon.Visible = false
        slot.nameLabel.Visible = false
        slot.nameLabel.Text = ""
        slot.equipBar.Visible = false
        slot.frame.BackgroundTransparency = 0.5
        makeStroke(slot.frame, Color3.fromRGB(40, 60, 90), 1, 0.7)
        return
    end

    local rod = RodData:GetRod(rodId)
    slot.rodId = rodId
    slot.isEmpty = false

    -- PLACEHOLDER: если есть иконка — показываем ImageLabel
    -- Иначе — текстовый fallback
    if rod.icon and rod.icon ~= "" then
        slot.icon.Image = rod.icon
        slot.icon.Visible = true
        slot.nameLabel.Visible = false
    else
        -- Fallback: текст названия
        slot.nameLabel.Text = rod.displayName:gsub("Rod", ""):gsub(" ", "\n")
        slot.nameLabel.Visible = true
        slot.icon.Visible = false
    end

    -- Цвет рамки по типу удочки
    local equipped = isToolEquipped(rodId)
    slot.equipBar.Visible = equipped
    slot.frame.BackgroundTransparency = equipped and 0.1 or 0.35
    if equipped then
        makeStroke(slot.frame, Color3.fromRGB(0, 200, 255), 2, 0.1)
    else
        makeStroke(slot.frame, Color3.fromRGB(40, 80, 120), 1, 0.6)
    end
end

-- Построить хотбар из текущих удочек в Backpack + Character
local function rebuildHotbar()
    local rodList = {}

    -- Собрать удочки из backpack
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") and RodData:GetRod(item.Name) then
            table.insert(rodList, item.Name)
        end
    end

    -- И из character (экипированный)
    local char = getCharacter()
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and RodData:GetRod(item.Name) then
                -- Убедиться что нет дублей
                local found = false
                for _, r in ipairs(rodList) do
                    if r == item.Name then found = true; break end
                end
                if not found then table.insert(rodList, item.Name) end
            end
        end
    end

    for i = 1, HOTBAR_ROD_COUNT do
        updateHotbarSlot(i, rodList[i])
    end
end

-- Нажатие на слот удочки
for i, slot in ipairs(hotbarSlots) do
    slot.button.MouseButton1Click:Connect(function()
        if slot.isEmpty or not slot.rodId then return end

        if isToolEquipped(slot.rodId) then
            unequipAll()
        else
            equipTool(slot.rodId)
        end

        -- Обновить визуал всех слотов
        task.delay(0.05, rebuildHotbar)
    end)

    -- Hover эффект
    slot.button.MouseEnter:Connect(function()
        if slot.isEmpty then return end
        tween(slot.frame, {BackgroundTransparency = 0.1}, 0.1)
    end)
    slot.button.MouseLeave:Connect(function()
        if slot.isEmpty then return end
        local eq = isToolEquipped(slot.rodId or "")
        tween(slot.frame, {BackgroundTransparency = eq and 0.1 or 0.35}, 0.1)
    end)
end

-- ══════════════════════════════════════════
--   ЛОГИКА ИНВЕНТАРЯ РЫБ
-- ══════════════════════════════════════════

-- Создать слот рыбы в сетке
local function createFishSlot(fishEntry, layoutOrder)
    local rarityColor = RARITY_COLORS[fishEntry.rarity] or Color3.new(1,1,1)
    local mutColor    = fishEntry.mutation ~= "" and MUTATION_COLORS[fishEntry.mutation]

    -- Фоновый цвет слегка тонирован цветом редкости
    local bgTint = Color3.fromRGB(
        math.clamp(rarityColor.R * 255 * 0.08 + 8,  0, 40),
        math.clamp(rarityColor.G * 255 * 0.08 + 10, 0, 40),
        math.clamp(rarityColor.B * 255 * 0.10 + 20, 0, 60)
    )

    local slotFrame = Instance.new("Frame")
    slotFrame.Name = "FishSlot_" .. fishEntry.itemName
    slotFrame.BackgroundColor3 = bgTint
    slotFrame.BackgroundTransparency = 0.1
    slotFrame.BorderSizePixel = 0
    slotFrame.LayoutOrder = layoutOrder
    slotFrame.Parent = fishGrid
    makeCorner(slotFrame, 10)

    -- Обводка цвета редкости: яркая, заметная
    local strokeThickness = 2
    local strokeTransparency = 0.15  -- почти непрозрачная
    local stroke = Instance.new("UIStroke")
    stroke.Color = rarityColor
    stroke.Thickness = strokeThickness
    stroke.Transparency = strokeTransparency
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = slotFrame
    slotFrame:SetAttribute("RarityStroke", true)
    slotFrame:SetAttribute("RarityR", rarityColor.R)
    slotFrame:SetAttribute("RarityG", rarityColor.G)
    slotFrame:SetAttribute("RarityB", rarityColor.B)

    -- Иконка рыбы (PLACEHOLDER — заменить Image)
    local icon = Instance.new("ImageLabel")
    icon.Name = "FishIcon"
    icon.Size = UDim2.new(0.82, 0, 0.82, 0)
    icon.Position = UDim2.fromScale(0.5, 0.46)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = fishEntry.image ~= "" and fishEntry.image or ""  -- PLACEHOLDER
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = slotFrame

    -- Если нет иконки — emoji заглушка
    if fishEntry.image == "" then
        local placeholder = Instance.new("TextLabel")
        placeholder.Size = UDim2.new(0.82, 0, 0.65, 0)
        placeholder.Position = UDim2.fromScale(0.5, 0.43)
        placeholder.AnchorPoint = Vector2.new(0.5, 0.5)
        placeholder.BackgroundTransparency = 1
        placeholder.Text = "🐠"
        placeholder.TextScaled = true
        placeholder.Font = Enum.Font.GothamBold
        placeholder.TextColor3 = rarityColor
        placeholder.Parent = slotFrame
    end

    -- Мутация — маленький цветной бейдж сверху справа
    if mutColor then
        local mutBadge = Instance.new("Frame")
        mutBadge.Name = "MutBadge"
        mutBadge.Size = UDim2.fromOffset(10, 10)
        mutBadge.Position = UDim2.new(1, -12, 0, 4)
        mutBadge.BackgroundColor3 = mutColor
        mutBadge.BorderSizePixel = 0
        mutBadge.Parent = slotFrame
        makeCorner(mutBadge, 5)
    end

    -- Цена снизу
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "Price"
    priceLabel.Size = UDim2.new(1, -4, 0, 16)
    priceLabel.Position = UDim2.new(0.5, 0, 1, -17)
    priceLabel.AnchorPoint = Vector2.new(0.5, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "🪙" .. tostring(fishEntry.value)
    priceLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextSize = 11
    priceLabel.TextScaled = false
    priceLabel.Parent = slotFrame

    -- Кнопка поверх
    local btn = Instance.new("TextButton")
    btn.Name = "Btn"
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 4
    btn.Parent = slotFrame

    -- Клик: показать детали
    btn.MouseButton1Click:Connect(function()
        selectedFishItem = fishEntry

        -- Обновить панель деталей
        detailIcon.Image = fishEntry.image or ""
        detailIconPlaceholder.Text = "🐠"
        detailIconPlaceholder.BackgroundColor3 = (RARITY_COLORS[fishEntry.rarity] or Color3.new(0.1, 0.2, 0.4))
        detailIconPlaceholder.BackgroundTransparency = fishEntry.image ~= "" and 1 or 0.3

        detailName.Text     = fishEntry.displayName
        detailRarity.Text   = fishEntry.rarity
        detailRarity.TextColor3 = RARITY_COLORS[fishEntry.rarity] or Color3.new(1,1,1)
        detailSize.Text     = fishEntry.size
        detailMutation.Text = (fishEntry.mutation ~= "" and fishEntry.mutation) or "—"
        detailMutation.TextColor3 = (mutColor or Color3.fromRGB(120, 160, 180))
        detailValue.Text    = "🪙 " .. tostring(fishEntry.value)
        detailZone.Text     = fishEntry.zone

        detailPlaceholder.Visible = false

        -- Подсветить выбранный слот, остальные приглушить
        for _, child in ipairs(fishGrid:GetChildren()) do
            if child:IsA("Frame") and child:GetAttribute("RarityStroke") then
                local s = child:FindFirstChildOfClass("UIStroke")
                if s then
                    if child.Name == slotFrame.Name then
                        -- Выбранный: толстая яркая обводка + белый внутренний свет
                        s.Thickness = 3
                        s.Transparency = 0
                        tween(child, {BackgroundTransparency = 0}, 0.12)
                    else
                        -- Остальные: тонкая полупрозрачная обводка
                        s.Thickness = 2
                        s.Transparency = 0.55
                        tween(child, {BackgroundTransparency = 0.25}, 0.12)
                    end
                end
            end
        end
    end)

    btn.MouseEnter:Connect(function()
        if selectedFishItem and selectedFishItem.itemName == fishEntry.itemName then return end
        local s = slotFrame:FindFirstChildOfClass("UIStroke")
        if s then s.Thickness = 2.5; s.Transparency = 0 end
        tween(slotFrame, {BackgroundTransparency = 0}, 0.1)
    end)
    btn.MouseLeave:Connect(function()
        if selectedFishItem and selectedFishItem.itemName == fishEntry.itemName then return end
        local s = slotFrame:FindFirstChildOfClass("UIStroke")
        if s then s.Thickness = 2; s.Transparency = 0.15 end
        tween(slotFrame, {BackgroundTransparency = 0.1}, 0.1)
    end)

    return slotFrame
end

-- Обновить сетку рыб из FishInventory папки
local function refreshFishGrid()
    -- Очистить сетку
    for _, child in ipairs(fishGrid:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    fishItems = {}

    local fishFolder = Player:FindFirstChild("FishInventory")
    if not fishFolder then
        fishCountLabel.Text = "0 рыб"
        FishScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        return
    end

    local items = fishFolder:GetChildren()
    local count = 0

    for i, item in ipairs(items) do
        if item:IsA("Configuration") then
            local entry = {
                itemName    = item.Name,
                fishId      = item:GetAttribute("FishId") or "???",
                displayName = item:GetAttribute("DisplayName") or "???",
                rarity      = item:GetAttribute("Rarity") or "Common",
                zone        = item:GetAttribute("Zone") or "—",
                size        = item:GetAttribute("Size") or "Normal",
                mutation    = item:GetAttribute("Mutation") or "",
                value       = item:GetAttribute("Value") or 0,
                image       = item:GetAttribute("Image") or "",
            }
            table.insert(fishItems, entry)
            createFishSlot(entry, i)
            count = count + 1
        end
    end

    fishCountLabel.Text = count .. " рыб"

    -- Canvas size
    local rows = math.ceil(count / FISH_COLS)
    local canvasH = rows * (FISH_SLOT_SIZE + SLOT_GAP) + SLOT_GAP
    FishScrollFrame.CanvasSize = UDim2.fromOffset(0, canvasH)
end

-- (кнопок продажи нет — продажа только у NPC Fish Merchant)

-- Слушать изменения папки рыб
local function hookFishFolder(folder)
    -- Новая рыба поймана
    folder.ChildAdded:Connect(function(item)
        -- Обновить счётчик всегда
        local count = 0
        for _, c in ipairs(folder:GetChildren()) do
            if c:IsA("Configuration") then count = count + 1 end
        end
        fishCountLabel.Text = count .. " рыб"

        -- Если панель открыта — добавить слот сразу, без полного rebuild
        if isFishPanelOpen then
            if item:IsA("Configuration") then
                local entry = {
                    itemName    = item.Name,
                    fishId      = item:GetAttribute("FishId") or "???",
                    displayName = item:GetAttribute("DisplayName") or "???",
                    rarity      = item:GetAttribute("Rarity") or "Common",
                    zone        = item:GetAttribute("Zone") or "—",
                    size        = item:GetAttribute("Size") or "Normal",
                    mutation    = item:GetAttribute("Mutation") or "",
                    value       = item:GetAttribute("Value") or 0,
                    image       = item:GetAttribute("Image") or "",
                }
                table.insert(fishItems, entry)
                createFishSlot(entry, #fishItems)
                -- Пересчитать canvas
                local rows = math.ceil(#fishItems / FISH_COLS)
                FishScrollFrame.CanvasSize = UDim2.fromOffset(0,
                    rows * (FISH_SLOT_SIZE + SLOT_GAP) + SLOT_GAP)
            end
        end
    end)

    -- Рыба продана/удалена
    folder.ChildRemoved:Connect(function()
        local count = 0
        for _, c in ipairs(folder:GetChildren()) do
            if c:IsA("Configuration") then count = count + 1 end
        end
        fishCountLabel.Text = count .. " рыб"

        if isFishPanelOpen then refreshFishGrid() end
    end)
end

-- Подождать папку
local fishFolder = Player:FindFirstChild("FishInventory")
if fishFolder then
    hookFishFolder(fishFolder)
else
    Player.ChildAdded:Connect(function(child)
        if child.Name == "FishInventory" then
            hookFishFolder(child)
        end
    end)
end

-- ══════════════════════════════════════════
--   ОТКРЫТИЕ / ЗАКРЫТИЕ ПАНЕЛИ РЫБ
-- ══════════════════════════════════════════

local function openFishPanel()
    if isFishPanelOpen then return end
    isFishPanelOpen = true

    refreshFishGrid()
    FishPanel.Visible = true
    FishPanel.Position = UDim2.new(0.5, -fishPanelW/2, 1, fishPanelClosedY - 20)

    tween(FishPanel,
        {Position = UDim2.new(0.5, -fishPanelW/2, 1, fishPanelOpenY)},
        ANIM_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    fishButton.Text = "🐟 ▼"
end

local function closeFishPanel()
    if not isFishPanelOpen then return end
    isFishPanelOpen = false

    tween(FishPanel,
        {Position = UDim2.new(0.5, -fishPanelW/2, 1, fishPanelClosedY)},
        ANIM_TIME - 0.05, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

    task.delay(ANIM_TIME, function()
        if not isFishPanelOpen then
            FishPanel.Visible = false
        end
    end)

    fishButton.Text = "🐟 ▲"
end

fishButton.MouseButton1Click:Connect(function()
    if isFishPanelOpen then closeFishPanel() else openFishPanel() end
end)

-- Закрыть по клику вне панели
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Проверить не внутри ли панели
        if isFishPanelOpen then
            local mPos = UserInputService:GetMouseLocation()
            local pPos = FishPanel.AbsolutePosition
            local pSize = FishPanel.AbsoluteSize
            local inside = mPos.X > pPos.X and mPos.X < pPos.X + pSize.X
                       and mPos.Y > pPos.Y and mPos.Y < pPos.Y + pSize.Y
            local onBtn  = (function()
                local bPos = fishButton.AbsolutePosition
                local bSize = fishButton.AbsoluteSize
                return mPos.X > bPos.X and mPos.X < bPos.X + bSize.X
                   and mPos.Y > bPos.Y and mPos.Y < bPos.Y + bSize.Y
            end)()
            if not inside and not onBtn then
                closeFishPanel()
            end
        end
    end
end)

-- ══════════════════════════════════════════
--   ГОРЯЧИЕ КЛАВИШИ (1-5 для удочек)
-- ══════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or textBoxFocused then return end

    -- 1-5: выбрать удочку
    local keyVal = input.KeyCode.Value
    local oneVal = Enum.KeyCode.One.Value
    for i = 1, HOTBAR_ROD_COUNT do
        if keyVal == oneVal + i - 1 then
            local slot = hotbarSlots[i]
            if not slot.isEmpty and slot.rodId then
                if isToolEquipped(slot.rodId) then
                    unequipAll()
                else
                    equipTool(slot.rodId)
                end
                task.delay(0.05, rebuildHotbar)
            end
            return
        end
    end

    -- Tab / F: открыть/закрыть инвентарь рыб
    if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.F then
        if isFishPanelOpen then closeFishPanel() else openFishPanel() end
    end
end)

UserInputService.TextBoxFocused:Connect(function() textBoxFocused = true end)
UserInputService.TextBoxFocusReleased:Connect(function() textBoxFocused = false end)

-- ══════════════════════════════════════════
--   СЛЕЖЕНИЕ ЗА BACKPACK / CHARACTER
-- ══════════════════════════════════════════

-- Обновлять хотбар при добавлении/удалении Tool из backpack
Backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") and RodData:GetRod(child.Name) then
        task.delay(0.05, rebuildHotbar)
    end
end)
Backpack.ChildRemoved:Connect(function(child)
    if child:IsA("Tool") and RodData:GetRod(child.Name) then
        task.delay(0.05, rebuildHotbar)
    end
end)

-- Обновлять при смене персонажа
Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    Backpack  = Player:WaitForChild("Backpack")

    -- Следить за экипированными инструментами
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.delay(0.05, rebuildHotbar)
        end
    end)
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            task.delay(0.05, rebuildHotbar)
        end
    end)

    task.delay(0.5, rebuildHotbar)
end)

-- Следить за текущим персонажем
if Character then
    Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then task.delay(0.05, rebuildHotbar) end
    end)
    Character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then task.delay(0.05, rebuildHotbar) end
    end)
end

-- ══ ИНИЦИАЛИЗАЦИЯ ══
task.delay(0.5, rebuildHotbar)

-- Слушать загрузку данных игрока
Remotes:WaitForChild("PlayerDataLoaded").OnClientEvent:Connect(function(data)
    task.delay(0.5, rebuildHotbar)
    -- Обновить счётчик рыб из папки
    task.delay(1, function()
        local folder = Player:FindFirstChild("FishInventory")
        if folder then
            local count = 0
            for _, c in ipairs(folder:GetChildren()) do
                if c:IsA("Configuration") then count = count + 1 end
            end
            fishCountLabel.Text = count .. " рыб"
        end
    end)
end)

-- Рыба поймана — мигнуть кнопкой инвентаря рыб
Remotes:WaitForChild("FishCaught").OnClientEvent:Connect(function(catchEntry)
    -- Пульс на кнопке чтобы игрок заметил новую рыбу
    local originalColor = fishButton.BackgroundColor3
    tween(fishButton, {BackgroundColor3 = Color3.fromRGB(0, 220, 100)}, 0.15)
    task.delay(0.15, function()
        tween(fishButton, {BackgroundColor3 = originalColor}, 0.3)
    end)
end)

print("[ReefDiver] CustomInventory инициализирован ✓")

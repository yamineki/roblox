-- StarterGui/CustomInventory.client.lua
-- Reef Diver — Кастомный инвентарь
-- Хотбар снизу (удочки) + панель fish (открывается по кнопке)
-- GUI создаётся UIBuilder.lua — этот скрипт подключает всю логику.

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid")
local Backpack  = Player:WaitForChild("Backpack")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Strings = require(ReplicatedStorage.Modules.Strings)
local RodData = require(ReplicatedStorage.Modules.RodData)

-- ══ КОНСТАНТЫ (должны совпадать с UIBuilder.lua) ══
local SLOT_SIZE        = 60
local SLOT_GAP         = 6
local SLOT_PADDING     = 8
local HOTBAR_ROD_COUNT = 5
local ANIM_TIME        = 0.25
local FISH_SLOT_SIZE   = 66
local FISH_COLS        = 5
local FISH_ROWS_VIS    = 3

local hotbarWidth  = SLOT_PADDING * 2 + HOTBAR_ROD_COUNT * SLOT_SIZE + (HOTBAR_ROD_COUNT - 1) * SLOT_GAP
local hotbarHeight = SLOT_PADDING * 2 + SLOT_SIZE
local fishPanelW   = FISH_COLS * (FISH_SLOT_SIZE + SLOT_GAP) + SLOT_GAP + 220
local fishPanelH   = FISH_ROWS_VIS * (FISH_SLOT_SIZE + SLOT_GAP) + SLOT_GAP + 60
local fishPanelOpenY   = -(hotbarHeight + fishPanelH + 16)
local fishPanelClosedY = -(hotbarHeight + 8)

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
local hotbarSlots      = {}
local fishItems        = {}
local selectedFishItem = nil
local textBoxFocused   = false

-- ══ GUI (создан UIBuilder.lua) ══
local InventoryGui = PlayerGui:WaitForChild("ReefDiverInventory", 20)
local MainFrame    = InventoryGui:WaitForChild("MainFrame")
local HotbarBG     = MainFrame:WaitForChild("HotbarBG")
local fishButton   = MainFrame:WaitForChild("FishInventoryToggle")
local FishPanel    = MainFrame:WaitForChild("FishPanel")

local fishHeader      = FishPanel:WaitForChild("Header")
local fishCountLabel  = fishHeader:WaitForChild("FishCount")
local FishScrollFrame = FishPanel:WaitForChild("FishGrid")
local fishGrid        = FishScrollFrame:WaitForChild("Grid")

local DetailPanel           = FishPanel:WaitForChild("DetailPanel")
local detailIcon            = DetailPanel:WaitForChild("Icon")
local detailIconPlaceholder = DetailPanel:WaitForChild("IconPlaceholder")
local detailName            = DetailPanel:WaitForChild("RowName"):WaitForChild("Value")
local detailRarity          = DetailPanel:WaitForChild("RowRarity"):WaitForChild("Value")
local detailSize            = DetailPanel:WaitForChild("RowSize"):WaitForChild("Value")
local detailMutation        = DetailPanel:WaitForChild("RowMutation"):WaitForChild("Value")
local detailValue           = DetailPanel:WaitForChild("RowValue"):WaitForChild("Value")
local detailZone            = DetailPanel:WaitForChild("RowZone"):WaitForChild("Value")
local detailPlaceholder     = DetailPanel:WaitForChild("Placeholder")

-- ══ ХЕЛПЕРЫ ══
local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 4)
    c.Parent = parent
    return c
end

local function makeStroke(parent, color, thickness, transparency)
    -- Удалить существующий UIStroke перед добавлением нового
    local existing = parent:FindFirstChildOfClass("UIStroke")
    if existing then existing:Destroy() end
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.new(1,1,1)
    s.Thickness = thickness or 1.5
    s.Transparency = transparency or 0.6
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function tween(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or ANIM_TIME,
            style or Enum.EasingStyle.Quart,
            dir or Enum.EasingDirection.Out),
        props):Play()
end

-- ══ ЗАПОЛНИТЬ МАССИВ HOTBAR SLOTS ══
for i = 1, HOTBAR_ROD_COUNT do
    local slotFrame = HotbarBG:WaitForChild("RodSlot_" .. i)
    hotbarSlots[i] = {
        frame     = slotFrame,
        icon      = slotFrame:WaitForChild("Icon"),
        nameLabel = slotFrame:WaitForChild("NameLabel"),
        equipBar  = slotFrame:WaitForChild("EquipBar"),
        button    = slotFrame:WaitForChild("Button"),
        rodId     = nil,
        isEmpty   = true,
    }
end

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
    hum:UnequipTools()
    task.defer(function()
        local tool = Backpack:FindFirstChild(toolName)
        if tool then hum:EquipTool(tool) end
    end)
end

local function unequipAll()
    local hum = getHumanoid()
    if hum then hum:UnequipTools() end
end

local function updateHotbarSlot(slotIdx, rodId)
    local slot = hotbarSlots[slotIdx]
    if not slot then return end

    if not rodId then
        slot.rodId = nil
        slot.isEmpty = true
        slot.icon.Visible = false
        slot.nameLabel.Visible = false
        slot.nameLabel.Text = ""
        slot.equipBar.Visible = false
        slot.frame.BackgroundTransparency = 0.5
        makeStroke(slot.frame, Color3.fromRGB(70, 75, 85), 1, 0.5)
        return
    end

    local rod = RodData:GetRod(rodId)
    slot.rodId = rodId
    slot.isEmpty = false

    if rod.icon and rod.icon ~= "" then
        slot.icon.Image = rod.icon
        slot.icon.Visible = true
        slot.nameLabel.Visible = false
    else
        slot.nameLabel.Text = rod.displayName:gsub("Rod", ""):gsub(" ", "\n")
        slot.nameLabel.Visible = true
        slot.icon.Visible = false
    end

    local equipped = isToolEquipped(rodId)
    slot.equipBar.Visible = equipped
    slot.frame.BackgroundTransparency = equipped and 0.1 or 0.35
    if equipped then
        makeStroke(slot.frame, Color3.fromRGB(235, 235, 235), 2, 0)
    else
        makeStroke(slot.frame, Color3.fromRGB(70, 75, 85), 1, 0)
    end
end

local function rebuildHotbar()
    local rodList = {}

    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") and RodData:GetRod(item.Name) then
            table.insert(rodList, item.Name)
        end
    end

    local char = getCharacter()
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and RodData:GetRod(item.Name) then
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

for i, slot in ipairs(hotbarSlots) do
    slot.button.MouseButton1Click:Connect(function()
        if slot.isEmpty or not slot.rodId then return end
        if isToolEquipped(slot.rodId) then
            unequipAll()
        else
            equipTool(slot.rodId)
        end
        task.delay(0.05, rebuildHotbar)
    end)

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

local function createFishSlot(fishEntry, layoutOrder)
    local rarityColor = RARITY_COLORS[fishEntry.rarity] or Color3.new(1,1,1)
    local mutColor    = fishEntry.mutation ~= "" and MUTATION_COLORS[fishEntry.mutation]

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
    makeCorner(slotFrame, 4)

    local stroke = Instance.new("UIStroke")
    stroke.Color = rarityColor
    stroke.Thickness = 2
    stroke.Transparency = 0.15
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = slotFrame
    slotFrame:SetAttribute("RarityStroke", true)

    local icon = Instance.new("ImageLabel")
    icon.Name = "FishIcon"
    icon.Size = UDim2.new(0.82, 0, 0.82, 0)
    icon.Position = UDim2.fromScale(0.5, 0.46)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = fishEntry.image ~= "" and fishEntry.image or ""
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = slotFrame

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

    if mutColor then
        local mutBadge = Instance.new("Frame")
        mutBadge.Size = UDim2.fromOffset(10, 10)
        mutBadge.Position = UDim2.new(1, -12, 0, 4)
        mutBadge.BackgroundColor3 = mutColor
        mutBadge.BorderSizePixel = 0
        mutBadge.Parent = slotFrame
        makeCorner(mutBadge, 5)
    end

    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(1, -4, 0, 16)
    priceLabel.Position = UDim2.new(0.5, 0, 1, -17)
    priceLabel.AnchorPoint = Vector2.new(0.5, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "🪙" .. tostring(fishEntry.value)
    priceLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextSize = 11
    priceLabel.Parent = slotFrame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 4
    btn.Parent = slotFrame

    btn.MouseButton1Click:Connect(function()
        selectedFishItem = fishEntry

        detailIcon.Image = fishEntry.image or ""
        detailIconPlaceholder:WaitForChild("PlaceholderText").Text = "🐠"
        detailIconPlaceholder.BackgroundColor3 = (RARITY_COLORS[fishEntry.rarity] or Color3.new(0.1, 0.2, 0.4))
        detailIconPlaceholder.BackgroundTransparency = fishEntry.image ~= "" and 1 or 0.3

        detailName.Text     = fishEntry.displayName
        detailRarity.Text   = fishEntry.rarity
        detailRarity.TextColor3 = RARITY_COLORS[fishEntry.rarity] or Color3.new(1,1,1)
        detailSize.Text     = fishEntry.size
        detailMutation.Text = (fishEntry.mutation ~= "" and fishEntry.mutation) or "—"
        detailMutation.TextColor3 = mutColor or Color3.fromRGB(120, 160, 180)
        detailValue.Text    = "🪙 " .. tostring(fishEntry.value)
        detailZone.Text     = fishEntry.zone

        detailPlaceholder.Visible = false

        for _, child in ipairs(fishGrid:GetChildren()) do
            if child:IsA("Frame") and child:GetAttribute("RarityStroke") then
                local s = child:FindFirstChildOfClass("UIStroke")
                if s then
                    if child.Name == slotFrame.Name then
                        s.Thickness = 3; s.Transparency = 0
                        tween(child, {BackgroundTransparency = 0}, 0.12)
                    else
                        s.Thickness = 2; s.Transparency = 0.55
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

local function refreshFishGrid()
    for _, child in ipairs(fishGrid:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    fishItems = {}

    local fishFolder = Player:FindFirstChild("FishInventory")
    if not fishFolder then
        fishCountLabel.Text = "0 fish"
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

    fishCountLabel.Text = count .. " fish"
    local rows = math.ceil(count / FISH_COLS)
    FishScrollFrame.CanvasSize = UDim2.fromOffset(0, rows * (FISH_SLOT_SIZE + SLOT_GAP) + SLOT_GAP)
end

local function hookFishFolder(folder)
    folder.ChildAdded:Connect(function(item)
        local count = 0
        for _, c in ipairs(folder:GetChildren()) do
            if c:IsA("Configuration") then count = count + 1 end
        end
        fishCountLabel.Text = count .. " fish"

        if isFishPanelOpen and item:IsA("Configuration") then
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
            local rows = math.ceil(#fishItems / FISH_COLS)
            FishScrollFrame.CanvasSize = UDim2.fromOffset(0,
                rows * (FISH_SLOT_SIZE + SLOT_GAP) + SLOT_GAP)
        end
    end)

    folder.ChildRemoved:Connect(function()
        local count = 0
        for _, c in ipairs(folder:GetChildren()) do
            if c:IsA("Configuration") then count = count + 1 end
        end
        fishCountLabel.Text = count .. " fish"
        if isFishPanelOpen then refreshFishGrid() end
    end)
end

local fishFolder = Player:FindFirstChild("FishInventory")
if fishFolder then
    hookFishFolder(fishFolder)
else
    Player.ChildAdded:Connect(function(child)
        if child.Name == "FishInventory" then hookFishFolder(child) end
    end)
end

-- ══ ОТКРЫТИЕ / ЗАКРЫТИЕ ПАНЕЛИ РЫБ ══

local function openFishPanel()
    if isFishPanelOpen then return end
    isFishPanelOpen = true

    refreshFishGrid()
    FishPanel.Visible = true
    FishPanel.Position = UDim2.new(0.5, -fishPanelW/2, 1, fishPanelClosedY - 20)
    tween(FishPanel,
        {Position = UDim2.new(0.5, -fishPanelW/2, 1, fishPanelOpenY)},
        ANIM_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    fishButton.Text = "🐠 ▼"
end

local function closeFishPanel()
    if not isFishPanelOpen then return end
    isFishPanelOpen = false

    tween(FishPanel,
        {Position = UDim2.new(0.5, -fishPanelW/2, 1, fishPanelClosedY)},
        ANIM_TIME - 0.05, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.delay(ANIM_TIME, function()
        if not isFishPanelOpen then FishPanel.Visible = false end
    end)
    fishButton.Text = "🐠 ▲"
end

fishButton.MouseButton1Click:Connect(function()
    if isFishPanelOpen then closeFishPanel() else openFishPanel() end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if isFishPanelOpen then
            local mPos = UserInputService:GetMouseLocation()
            local pPos = FishPanel.AbsolutePosition
            local pSize = FishPanel.AbsoluteSize
            local inside = mPos.X > pPos.X and mPos.X < pPos.X + pSize.X
                       and mPos.Y > pPos.Y and mPos.Y < pPos.Y + pSize.Y
            local bPos = fishButton.AbsolutePosition
            local bSize = fishButton.AbsoluteSize
            local onBtn = mPos.X > bPos.X and mPos.X < bPos.X + bSize.X
                      and mPos.Y > bPos.Y and mPos.Y < bPos.Y + bSize.Y
            if not inside and not onBtn then closeFishPanel() end
        end
    end
end)

-- ══ ГОРЯЧИЕ КЛАВИШИ ══
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or textBoxFocused then return end

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

    if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.F then
        if isFishPanelOpen then closeFishPanel() else openFishPanel() end
    end
end)

UserInputService.TextBoxFocused:Connect(function() textBoxFocused = true end)
UserInputService.TextBoxFocusReleased:Connect(function() textBoxFocused = false end)

-- ══ СЛЕЖЕНИЕ ЗА BACKPACK / CHARACTER ══
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

Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    Backpack  = Player:WaitForChild("Backpack")

    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then task.delay(0.05, rebuildHotbar) end
    end)
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then task.delay(0.05, rebuildHotbar) end
    end)

    task.delay(0.5, rebuildHotbar)
end)

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

Remotes:WaitForChild("PlayerDataLoaded").OnClientEvent:Connect(function(data)
    task.delay(0.5, rebuildHotbar)
    task.delay(1, function()
        local folder = Player:FindFirstChild("FishInventory")
        if folder then
            local count = 0
            for _, c in ipairs(folder:GetChildren()) do
                if c:IsA("Configuration") then count = count + 1 end
            end
            fishCountLabel.Text = count .. " fish"
        end
    end)
end)

Remotes:WaitForChild("FishCaught").OnClientEvent:Connect(function()
    local originalColor = fishButton.BackgroundColor3
    tween(fishButton, {BackgroundColor3 = Color3.fromRGB(0, 220, 100)}, 0.15)
    task.delay(0.15, function()
        tween(fishButton, {BackgroundColor3 = originalColor}, 0.3)
    end)
end)

print("[ReefDiver] CustomInventory инициализирован ✓")

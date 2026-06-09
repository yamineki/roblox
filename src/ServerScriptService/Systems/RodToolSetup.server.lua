-- ServerScriptService/Systems/RodToolSetup.server.lua
-- Reef Diver — Инициализация Tool-объектов удочек
--
-- КАК ЗАМЕНИТЬ ПЛЕЙСХОЛДЕР НА РЕАЛЬНУЮ МОДЕЛЬ:
--   1. Создай модель удочки в Roblox Studio
--   2. Убедись что деталь Handle называется "Handle"
--   3. Помести модель в ServerStorage → RodTools → <RodId>
--      (например: ServerStorage/RodTools/WoodenRod)
--   4. Удали Part-заглушку с тем же именем — реальная модель подхватится автоматически

local Players       = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RodData    = require(ReplicatedStorage.Modules.RodData)
local DataService = require(script.Parent.Parent.Services.DataService)

-- ══ ПАПКА ШАБЛОНОВ ══
local ToolTemplates = ServerStorage:FindFirstChild("RodTools")
if not ToolTemplates then
    ToolTemplates = Instance.new("Folder")
    ToolTemplates.Name = "RodTools"
    ToolTemplates.Parent = ServerStorage
end

-- ══ СОЗДАТЬ ПЛЕЙСХОЛДЕР TOOL (если реальной модели ещё нет) ══
local function createPlaceholderTool(rodId)
    local rod = RodData:GetRod(rodId)
    if not rod then return nil end

    local tool = Instance.new("Tool")
    tool.Name        = rodId
    tool.ToolTip     = rod.description
    tool.RequiresHandle = true
    tool.CanBeDropped   = false

    -- Handle = простой Part-заглушка
    -- PLACEHOLDER: замени на реальную модель в ServerStorage/RodTools/<RodId>
    local handle = Instance.new("Part")
    handle.Name     = "Handle"
    handle.Size     = Vector3.new(0.3, 0.3, 3)
    handle.BrickColor = BrickColor.new("Medium stone grey")
    handle.Material   = Enum.Material.SmoothPlastic
    handle.CanCollide = false
    handle.Massless   = true
    handle.Parent     = tool

    -- Стандартный хват
    tool.GripPos     = Vector3.new(0, 0, 1)
    tool.GripForward = Vector3.new(0, 0, -1)
    tool.GripRight   = Vector3.new(1, 0, 0)
    tool.GripUp      = Vector3.new(0, 1, 0)

    return tool
end

-- ══ ПОЛУЧИТЬ ИЛИ СОЗДАТЬ TOOL ══
-- Если в RodTools уже лежит реальная модель — берём её.
-- Если нет — создаём плейсхолдер.
local function getOrCreateTool(rodId)
    local existing = ToolTemplates:FindFirstChild(rodId)
    if existing then
        return existing  -- реальная модель уже на месте
    end

    local placeholder = createPlaceholderTool(rodId)
    if placeholder then
        placeholder.Parent = ToolTemplates
        print("[RodToolSetup] Плейсхолдер:", rodId, "— замени на модель в ServerStorage/RodTools/", rodId)
    end
    return placeholder
end

-- Инициализировать все удочки при старте
for rodId in pairs(RodData.Rods) do
    getOrCreateTool(rodId)
end

-- ══ ВЫДАТЬ УДОЧКИ ИГРОКУ ══
local function giveRodsToPlayer(player)
    task.wait(1.5)  -- ждём загрузки DataService

    local data = DataService:Get(player)
    if not data then return end

    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end

    for _, rodId in ipairs(data.ownedRods or { "WoodenRod" }) do
        -- Не дублировать
        if not backpack:FindFirstChild(rodId) then
            local template = ToolTemplates:FindFirstChild(rodId)
            if template then
                template:Clone().Parent = backpack
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        giveRodsToPlayer(player)
    end)
    if player.Character then
        giveRodsToPlayer(player)
    end
end)

-- ══ ВЫДАТЬ КУПЛЕННУЮ УДОЧКУ ══
-- ServerMain вызывает этот BindableEvent после успешной покупки
local GiveRodEvent = ServerStorage:FindFirstChild("GiveRodToPlayer")
if not GiveRodEvent then
    GiveRodEvent = Instance.new("BindableEvent")
    GiveRodEvent.Name = "GiveRodToPlayer"
    GiveRodEvent.Parent = ServerStorage
end

GiveRodEvent.Event:Connect(function(player, rodId)
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end
    if backpack:FindFirstChild(rodId) then return end  -- уже есть

    local template = ToolTemplates:FindFirstChild(rodId)
    if template then
        template:Clone().Parent = backpack
    end
end)

print("[ReefDiver] RodToolSetup готов ✓")
print("[ReefDiver] Плейсхолдеры в ServerStorage/RodTools — заменяй на реальные модели")

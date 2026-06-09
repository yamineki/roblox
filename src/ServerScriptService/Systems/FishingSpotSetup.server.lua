-- ServerScriptService/Systems/FishingSpotSetup.server.lua
-- Reef Diver — Мир, зоны, рыбы-AI, обработка начала рыбалки
-- Рыбы плавают свободно в зонах. Лунок нет.
-- Рыбалка: игрок в зоне + удочка + F клавиша → RequestFishing → StartFishing

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RodData     = require(ReplicatedStorage.Modules.RodData)
local DataService = require(script.Parent.Parent.Services.DataService)

local Remotes         = ReplicatedStorage:WaitForChild("Remotes", 10)
local StartFishing    = Remotes:WaitForChild("StartFishing")
local RequestFishing  = Remotes:WaitForChild("RequestFishing")

local rng = Random.new()

-- ══════════════════════════════════════════════════════════════
-- ДАННЫЕ ЗОН
-- ══════════════════════════════════════════════════════════════
local ZONE_DATA = {
    {
        id    = "SunnyReef",
        pos   = Vector3.new(0, 2, 100),
        size  = Vector3.new(220, 36, 220),
        color = Color3.fromRGB(0, 180, 255),
        fishCount = 8,
        fishColors = {
            Color3.fromRGB(255, 100, 20),  -- Clownfish
            Color3.fromRGB(50, 100, 220),  -- Tang
            Color3.fromRGB(255, 220, 80),  -- Butterflyfish
            Color3.fromRGB(180, 60, 200),  -- Triggerfish
        },
    },
    {
        id    = "CoralTrench",
        pos   = Vector3.new(0, 2, 360),
        size  = Vector3.new(220, 36, 220),
        color = Color3.fromRGB(0, 160, 140),
        fishCount = 8,
        fishColors = {
            Color3.fromRGB(220, 60, 80),
            Color3.fromRGB(80, 180, 100),
            Color3.fromRGB(200, 120, 40),
            Color3.fromRGB(100, 60, 180),
        },
    },
    {
        id    = "OpenOcean",
        pos   = Vector3.new(0, 2, 640),
        size  = Vector3.new(280, 40, 280),
        color = Color3.fromRGB(30, 80, 180),
        fishCount = 8,
        fishColors = {
            Color3.fromRGB(60, 160, 255),
            Color3.fromRGB(40, 220, 160),
            Color3.fromRGB(255, 80, 140),
            Color3.fromRGB(180, 200, 255),
        },
    },
    {
        id    = "DarkWaters",
        pos   = Vector3.new(0, 2, 960),
        size  = Vector3.new(320, 44, 320),
        color = Color3.fromRGB(60, 20, 120),
        fishCount = 6,
        fishColors = {
            Color3.fromRGB(120, 40, 200),
            Color3.fromRGB(200, 20, 80),
            Color3.fromRGB(60, 200, 200),
            Color3.fromRGB(40, 40, 180),
        },
    },
    {
        id    = "Abyss",
        pos   = Vector3.new(0, 2, 1320),
        size  = Vector3.new(400, 50, 400),
        color = Color3.fromRGB(20, 5, 50),
        fishCount = 6,
        fishColors = {
            Color3.fromRGB(180, 0, 60),
            Color3.fromRGB(0, 180, 80),
            Color3.fromRGB(80, 0, 160),
            Color3.fromRGB(0, 120, 200),
        },
    },
}

-- ══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ ЗОН
-- ══════════════════════════════════════════════════════════════
local zonesFolder = workspace:FindFirstChild("Zones")
if not zonesFolder then
    zonesFolder = Instance.new("Folder")
    zonesFolder.Name = "Zones"
    zonesFolder.Parent = workspace
end

local zoneParts = {}  -- id → Part

for _, z in ipairs(ZONE_DATA) do
    -- Убрать старую версию если была
    local existing = zonesFolder:FindFirstChild(z.id)
    if existing then existing:Destroy() end

    local part = Instance.new("Part")
    part.Name         = z.id
    part.Size         = z.size
    part.CFrame       = CFrame.new(z.pos)
    part.Anchored     = true
    part.CanCollide   = false
    part.Transparency = 0.65
    part.Color        = z.color
    part.Material     = Enum.Material.Glass
    part.CastShadow   = false
    part.Parent       = zonesFolder
    zoneParts[z.id]   = part

    -- Текстовый лейбл над зоной
    local billboard = Instance.new("BillboardGui")
    billboard.Size         = UDim2.fromOffset(220, 50)
    billboard.StudsOffset  = Vector3.new(0, z.size.Y / 2 + 4, 0)
    billboard.AlwaysOnTop  = false
    billboard.LightInfluence = 0.2
    billboard.Parent       = part

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text                  = "🌊 " .. z.id
    lbl.TextColor3            = z.color
    lbl.TextStrokeTransparency = 0.3
    lbl.TextStrokeColor3      = Color3.new(0, 0, 0)
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextScaled            = true
    lbl.Parent                = billboard
end

-- ══════════════════════════════════════════════════════════════
-- РЫБЫ AI
-- ══════════════════════════════════════════════════════════════
local fishFolder = workspace:FindFirstChild("Fish")
if not fishFolder then
    fishFolder = Instance.new("Folder")
    fishFolder.Name = "Fish"
    fishFolder.Parent = workspace
end

local allFish = {}  -- { part, zoneId, zoneBounds, targetPos, tweenTime }

-- Случайная позиция внутри зоны Part
local function randomPosInZone(z)
    local half = z.size / 2
    local margin = 8  -- отступ от краёв
    return Vector3.new(
        z.pos.X + rng:NextNumber(-half.X + margin, half.X - margin),
        z.pos.Y + rng:NextNumber(-half.Y * 0.4, half.Y * 0.4),
        z.pos.Z + rng:NextNumber(-half.Z + margin, half.Z - margin)
    )
end

for _, z in ipairs(ZONE_DATA) do
    for i = 1, z.fishCount do
        local colorIdx = ((i - 1) % #z.fishColors) + 1
        local color = z.fishColors[colorIdx]

        -- Форма рыбы (клин = WedgePart даёт треугольный силуэт)
        local fishPart = Instance.new("Part")
        fishPart.Name         = z.id .. "_Fish_" .. i
        fishPart.Size         = Vector3.new(2.5, 1, 1.2)
        fishPart.Anchored     = true
        fishPart.CanCollide   = false
        fishPart.CastShadow   = false
        fishPart.Color        = color
        fishPart.Material     = Enum.Material.SmoothPlastic
        fishPart.CFrame       = CFrame.new(randomPosInZone(z))
        fishPart.Parent       = fishFolder

        -- Плавники (маленький Part сверху)
        local fin = Instance.new("WedgePart")
        fin.Name        = "Fin"
        fin.Size        = Vector3.new(0.3, 0.8, 1)
        fin.Anchored    = true
        fin.CanCollide  = false
        fin.CastShadow  = false
        fin.Color       = color
        fin.Material    = Enum.Material.SmoothPlastic
        fin.Parent      = fishPart

        -- Имя рыбы
        local bb = Instance.new("BillboardGui")
        bb.Size        = UDim2.fromOffset(90, 20)
        bb.StudsOffset = Vector3.new(0, 1.5, 0)
        bb.AlwaysOnTop = false
        bb.LightInfluence = 0.1
        bb.Parent      = fishPart

        local fishLbl = Instance.new("TextLabel")
        fishLbl.Size                    = UDim2.fromScale(1, 1)
        fishLbl.BackgroundTransparency  = 1
        fishLbl.Text                    = "🐠"
        fishLbl.TextScaled              = true
        fishLbl.Font                    = Enum.Font.GothamBold
        fishLbl.TextColor3              = color
        fishLbl.Parent                  = bb

        table.insert(allFish, {
            part      = fishPart,
            fin       = fin,
            zoneData  = z,
            target    = randomPosInZone(z),
            moveTimer = rng:NextNumber(0, 3),  -- разный старт
        })
    end
end

-- ══ AI: плавание рыб ══
local FISH_SPEED_MIN = 4   -- ступени/сек
local FISH_SPEED_MAX = 9

RunService.Heartbeat:Connect(function(dt)
    for _, fish in ipairs(allFish) do
        local part = fish.part
        if not part or not part.Parent then continue end

        fish.moveTimer = fish.moveTimer - dt
        if fish.moveTimer <= 0 then
            -- Новая цель внутри зоны
            fish.target = randomPosInZone(fish.zoneData)
            fish.moveTimer = rng:NextNumber(2, 5)
        end

        -- Плавно двигаться к цели
        local current = part.CFrame.Position
        local dir = fish.target - current
        local dist = dir.Magnitude
        if dist > 0.2 then
            local speed = rng:NextNumber(FISH_SPEED_MIN, FISH_SPEED_MAX)
            local move  = math.min(dist, speed * dt)
            local newPos = current + dir.Unit * move
            -- Повернуть рыбу в сторону движения
            local cf = CFrame.lookAt(newPos, fish.target) * CFrame.Angles(0, math.rad(90), 0)
            part.CFrame = cf
            -- Обновить плавник
            if fish.fin then
                fish.fin.CFrame = cf * CFrame.new(0, 0.9, 0)
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- ОПРЕДЕЛЕНИЕ ЗОНЫ ИГРОКА
-- ══════════════════════════════════════════════════════════════
local function getPlayerZone(player)
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local pos = hrp.Position

    for _, z in ipairs(ZONE_DATA) do
        local half = z.size / 2
        local c    = z.pos
        if  pos.X >= c.X - half.X and pos.X <= c.X + half.X
        and pos.Y >= c.Y - half.Y - 5 and pos.Y <= c.Y + half.Y + 10
        and pos.Z >= c.Z - half.Z and pos.Z <= c.Z + half.Z then
            return z.id
        end
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════
-- ЗАПРОС НАЧАЛА РЫБАЛКИ (Client → Server)
-- ══════════════════════════════════════════════════════════════
local activeFishing = {}  -- userId → true (защита от двойных запросов)

RequestFishing.OnServerEvent:Connect(function(player)
    local userId = tostring(player.UserId)
    if activeFishing[userId] then return end

    -- Проверить удочку
    local char = player.Character
    if not char then return end
    local hasRod = false
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and RodData:GetRod(item.Name) then
            hasRod = true; break
        end
    end
    if not hasRod then
        -- Нет удочки — можно отправить тост, пока просто игнор
        return
    end

    -- Определить зону
    local zoneName = getPlayerZone(player)
    if not zoneName then return end

    -- Проверить разблокировку
    if not DataService:IsZoneUnlocked(player, zoneName) then return end

    -- Запустить мини-игру у клиента
    activeFishing[userId] = true
    StartFishing:FireClient(player, { zone = zoneName })

    -- Разблокировать после таймаута (15 сек)
    task.delay(15, function()
        activeFishing[userId] = nil
    end)
end)

-- Сбросить флаг когда сервер обработал CatchResult
Remotes:WaitForChild("CatchResult").OnServerEvent:Connect(function(player)
    activeFishing[tostring(player.UserId)] = nil
end)

-- Сбросить при выходе игрока
Players.PlayerRemoving:Connect(function(player)
    activeFishing[tostring(player.UserId)] = nil
end)

print("[ReefDiver] WorldSetup: зоны, рыбы AI, рыбалка ✓")

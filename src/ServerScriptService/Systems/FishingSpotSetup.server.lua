-- ServerScriptService/Systems/FishingSpotSetup.server.lua
-- Reef Diver — Мир, зоны, рыбы-AI, обработка начала рыбалки
-- Рыбы плавают свободно в зонах. Лунок нет.
-- Рыбалка: подплыть к рыбе → ProximityPrompt (E) → StartFishing → мини-игра.
-- F-клавиша (RequestFishing) оставлена как fallback: ловит ближайшую свободную рыбу.
--
-- ВАЖНО: игрок НЕ знает, какую рыбу вытянет — вид/редкость/мутация
-- роллятся на сервере только в момент CatchResult (см. ServerMain + FishingService).
-- Рыбы в мире — анонимные силуэты с "?" над головой.
--
-- ══ КАК ЗАМЕНИТЬ МОДЕЛЬ РЫБЫ ══
-- Чтобы заменить модель рыбы: положи Model с заданным PrimaryPart в
-- ReplicatedStorage/FishModels с именем зоны (SunnyReef, CoralTrench,
-- OpenOcean, DarkWaters, Abyss) или Default.
-- Сервер клонирует шаблон и двигает его через model:PivotTo() —
-- любая модель с PrimaryPart будет работать без правки кода.
-- Если шаблонов нет — строится плейсхолдер-силуэт (Part + Fin).

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
    },
    {
        id    = "CoralTrench",
        pos   = Vector3.new(0, 2, 360),
        size  = Vector3.new(220, 36, 220),
        color = Color3.fromRGB(0, 160, 140),
        fishCount = 8,
    },
    {
        id    = "OpenOcean",
        pos   = Vector3.new(0, 2, 640),
        size  = Vector3.new(280, 40, 280),
        color = Color3.fromRGB(30, 80, 180),
        fishCount = 8,
    },
    {
        id    = "DarkWaters",
        pos   = Vector3.new(0, 2, 960),
        size  = Vector3.new(320, 44, 320),
        color = Color3.fromRGB(60, 20, 120),
        fishCount = 6,
    },
    {
        id    = "Abyss",
        pos   = Vector3.new(0, 2, 1320),
        size  = Vector3.new(400, 50, 400),
        color = Color3.fromRGB(20, 5, 50),
        fishCount = 6,
    },
}

-- Силуэт рыбы (плейсхолдер): тёмный, без подсказок о виде
local SILHOUETTE_COLOR        = Color3.fromRGB(18, 26, 38)
local SILHOUETTE_TRANSPARENCY = 0.15

-- "Большая рыба" — намёк на качество (бонус удачи на сервере)
local BIG_CATCH_CHANCE    = 0.22  -- 20-25% рыб
local BIG_CATCH_SCALE_MIN = 1.4
local BIG_CATCH_SCALE_MAX = 1.8

local PROMPT_DISTANCE = 14  -- дистанция промпта и fallback-поиска (F)

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
    lbl.Text                  = "🌊 " .. z.id:gsub("(%u)", " %1"):gsub("^ ","")  -- split camelCase
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

local allFish = {}  -- { model, primary, prompt, zoneData, target, ... }

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

-- Найти пользовательский шаблон модели рыбы:
-- ReplicatedStorage/FishModels/<zoneId> или /Default (Model с PrimaryPart)
local function findFishTemplate(zoneId)
    local folder = ReplicatedStorage:FindFirstChild("FishModels")
    if not folder then return nil end
    local template = folder:FindFirstChild(zoneId) or folder:FindFirstChild("Default")
    if template and template:IsA("Model") and template.PrimaryPart then
        return template
    end
    return nil
end

-- Построить плейсхолдер-силуэт (Part + Fin) внутри Model с PrimaryPart
local function buildPlaceholderModel()
    local model = Instance.new("Model")

    local body = Instance.new("Part")
    body.Name         = "Body"
    body.Size         = Vector3.new(2.5, 1, 1.2)
    body.Anchored     = true
    body.CanCollide   = false
    body.CastShadow   = false
    body.Color        = SILHOUETTE_COLOR
    body.Transparency = SILHOUETTE_TRANSPARENCY
    body.Material     = Enum.Material.SmoothPlastic
    body.Parent       = model

    -- Плавник: приварен к телу — двигается вместе с PivotTo
    local fin = Instance.new("WedgePart")
    fin.Name         = "Fin"
    fin.Size         = Vector3.new(0.3, 0.8, 1)
    fin.Anchored     = false
    fin.CanCollide   = false
    fin.CastShadow   = false
    fin.Color        = SILHOUETTE_COLOR
    fin.Transparency = SILHOUETTE_TRANSPARENCY
    fin.Material     = Enum.Material.SmoothPlastic
    fin.CFrame       = body.CFrame * CFrame.new(0, 0.9, 0)
    fin.Parent       = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0  = body
    weld.Part1  = fin
    weld.Parent = body

    model.PrimaryPart = body
    return model
end

-- Заякорить все части модели (шаблон пользователя может быть не заякорен)
local function anchorModel(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.Anchored   = (d == model.PrimaryPart)  -- primary якорь, остальное на сварках
            d.CanCollide = false
        end
    end
    -- Если у шаблона нет сварок — заякорить всё, чтобы части не падали
    local hasWelds = model:FindFirstChildWhichIsA("WeldConstraint", true)
        or model:FindFirstChildWhichIsA("Weld", true)
        or model:FindFirstChildWhichIsA("Motor6D", true)
    if not hasWelds then
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then d.Anchored = true end
        end
    end
end

-- forward declaration (prompt → старт рыбалки)
local tryStartFishing

-- Создать рыбу (модель + промпт + AI-запись). Используется и для респауна.
local function spawnFish(z, index)
    -- Модель: пользовательский шаблон или плейсхолдер
    local template = findFishTemplate(z.id)
    local model
    if template then
        model = template:Clone()
    else
        model = buildPlaceholderModel()
    end
    model.Name = z.id .. "_Fish_" .. index
    anchorModel(model)

    -- Намёк на качество: 20-25% рыб крупнее и слегка светятся
    local isBigCatch = rng:NextNumber() < BIG_CATCH_CHANCE
    if isBigCatch then
        local scale = rng:NextNumber(BIG_CATCH_SCALE_MIN, BIG_CATCH_SCALE_MAX)
        local ok = pcall(function() model:ScaleTo(scale) end)
        if not ok and model.PrimaryPart then
            -- Фоллбэк: масштабируем хотя бы PrimaryPart плейсхолдера
            model.PrimaryPart.Size = model.PrimaryPart.Size * scale
        end
        model:SetAttribute("BigCatch", true)

        local light = Instance.new("PointLight")
        light.Brightness = 1.2
        light.Range      = 10
        light.Color      = Color3.fromRGB(255, 210, 80)
        light.Parent     = model.PrimaryPart

        -- Highlight виден всем клиентам без LocalScript (replicated)
        local hl = Instance.new("Highlight")
        hl.FillColor           = Color3.fromRGB(255, 200, 50)
        hl.FillTransparency    = 0.55
        hl.OutlineColor        = Color3.fromRGB(255, 220, 80)
        hl.OutlineTransparency = 0
        hl.Parent              = model
    end

    local startPos = randomPosInZone(z)
    model:PivotTo(CFrame.new(startPos))
    model.Parent = fishFolder

    local primary = model.PrimaryPart

    -- "?" над рыбой — игрок не знает, что вытянет
    local bb = Instance.new("BillboardGui")
    bb.Size           = UDim2.fromOffset(40, 40)
    bb.StudsOffset    = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop    = false
    bb.LightInfluence = 0.1
    bb.MaxDistance    = 15
    bb.Parent         = primary

    local qLbl = Instance.new("TextLabel")
    qLbl.Size                   = UDim2.fromScale(1, 1)
    qLbl.BackgroundTransparency = 1
    qLbl.Text                   = "?"
    qLbl.TextScaled             = true
    qLbl.Font                   = Enum.Font.GothamBold
    qLbl.TextColor3             = Color3.fromRGB(170, 175, 185)
    qLbl.TextTransparency       = 0.25
    qLbl.Parent                 = bb

    -- ProximityPrompt: ловля конкретной рыбы (E)
    -- Style=Custom → кастомный UI из CustomProximityPrompt.client.lua (PromptKind="Fishing")
    -- RequiresLineOfSight = false — игрок плавает в 3D, промпт работает с любой стороны
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText            = "Fish"
    prompt.ObjectText            = "?"
    prompt.KeyboardKeyCode       = Enum.KeyCode.E
    prompt.MaxActivationDistance = PROMPT_DISTANCE
    prompt.RequiresLineOfSight   = false
    prompt.HoldDuration          = 0
    prompt.Style                 = Enum.ProximityPromptStyle.Custom
    prompt:SetAttribute("PromptKind", "Fishing")
    prompt.Parent                = primary

    local fish = {
        model        = model,
        primary      = primary,
        prompt       = prompt,
        zoneData     = z,
        index        = index,
        target       = randomPosInZone(z),
        moveTimer    = rng:NextNumber(0, 3),  -- разный старт
        currentCFrame = model:GetPivot(),
        bobPhase     = rng:NextNumber(0, math.pi * 2),
        frozen       = false,
        frozenUntil  = 0,
        frozenPlayer = nil,
        busy         = false,   -- рыбу уже кто-то ловит / она "уплывает"
    }

    prompt.Triggered:Connect(function(player)
        tryStartFishing(player, fish)
    end)

    return fish
end

for _, z in ipairs(ZONE_DATA) do
    for i = 1, z.fishCount do
        table.insert(allFish, spawnFish(z, i))
    end
end

-- ══ AI: плавание рыб ══
local FISH_SPEED_MIN = 4   -- ступени/сек
local FISH_SPEED_MAX = 9

RunService.Heartbeat:Connect(function(dt)
    for _, fish in ipairs(allFish) do
        local model = fish.model
        if not model or not model.Parent then continue end
        -- busy без frozen = рыба "уплывает"/респаунится — AI не трогаем
        if fish.busy and not fish.frozen then continue end

        local bob = math.sin(tick() * 1.5 + fish.bobPhase) * 0.3
        local targetCF = nil

        if fish.frozen then
            -- Заморожена для мини-игры — смотрим на игрока
            local player = fish.frozenPlayer
            local hrp = nil
            if player and player.Character then
                hrp = player.Character:FindFirstChild("HumanoidRootPart")
            end

            if tick() >= fish.frozenUntil then
                fish.frozen = false
                fish.busy = false
                fish.frozenPlayer = nil
                fish.prompt.Enabled = true
                fish.target = randomPosInZone(fish.zoneData)
                fish.moveTimer = rng:NextNumber(2, 5)
            elseif hrp then
                local pos = fish.currentCFrame.Position
                targetCF = CFrame.lookAt(pos, hrp.Position) * CFrame.Angles(0, math.rad(90), 0)
            end
            -- если hrp == nil (игрок ушёл) — fall through к обычному поведению ниже
        end

        if not fish.frozen and targetCF == nil then
            fish.moveTimer = fish.moveTimer - dt
            if fish.moveTimer <= 0 then
                -- Новая цель внутри зоны
                fish.target = randomPosInZone(fish.zoneData)
                fish.moveTimer = rng:NextNumber(2, 5)
            end

            -- Плавно двигаться к цели
            local current = fish.currentCFrame.Position
            local dir = fish.target - current
            local dist = dir.Magnitude
            if dist > 0.2 then
                local speed = rng:NextNumber(FISH_SPEED_MIN, FISH_SPEED_MAX)
                local move  = math.min(dist, speed * dt)
                local newPos = current + dir.Unit * move
                local bobbedPos = Vector3.new(newPos.X, newPos.Y + bob, newPos.Z)
                targetCF = CFrame.lookAt(bobbedPos, bobbedPos + dir.Unit) * CFrame.Angles(0, math.rad(90), 0)
            else
                local bobbedPos = Vector3.new(current.X, current.Y + bob, current.Z)
                targetCF = fish.currentCFrame - fish.currentCFrame.Position + bobbedPos
            end
        end

        if targetCF then
            fish.currentCFrame = fish.currentCFrame:Lerp(targetCF, math.min(1, dt * 4))
            -- Вся модель двигается через PivotTo — любая заменённая модель работает
            model:PivotTo(fish.currentCFrame)
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
-- ЗАПУСК РЫБАЛКИ (ProximityPrompt / F-fallback)
-- ══════════════════════════════════════════════════════════════
local activeFishing = {}     -- userId → true (защита от двойных запросов)
local playerFrozenFish = {}  -- userId → fish entry

local function unfreezeFish(fish)
    fish.frozen = false
    fish.frozenPlayer = nil
    fish.busy = false
    if fish.prompt then fish.prompt.Enabled = true end
    fish.target = randomPosInZone(fish.zoneData)
    fish.moveTimer = rng:NextNumber(2, 5)
end

-- Рыба сорвалась / рыбалка отменена → возобновить плавание
local function unfreezeForPlayer(userId)
    local prev = playerFrozenFish[userId]
    if prev then
        unfreezeFish(prev)
        playerFrozenFish[userId] = nil
    end
end

-- Рыба поймана → "уплывает" (твин вниз + прозрачность) и респаунится через 5-10 сек
local function despawnAndRespawn(fish)
    fish.frozen = false
    fish.frozenPlayer = nil
    fish.busy = true  -- AI не трогает, промпт выключен
    if fish.prompt then fish.prompt.Enabled = false end

    local model = fish.model
    local z = fish.zoneData
    local index = fish.index

    task.spawn(function()
        -- Растворение всех частей
        if model and model.Parent then
            for _, d in ipairs(model:GetDescendants()) do
                if d:IsA("BasePart") then
                    TweenService:Create(d,
                        TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                        { Transparency = 1 }
                    ):Play()
                elseif d:IsA("BillboardGui") or d:IsA("ProximityPrompt") or d:IsA("PointLight") then
                    d.Enabled = false
                end
            end
            -- Быстрый "нырок" вниз через PivotTo
            local startCF = model:GetPivot()
            local t0 = os.clock()
            while os.clock() - t0 < 0.8 do
                local a = (os.clock() - t0) / 0.8
                if not model.Parent then break end
                model:PivotTo(startCF * CFrame.new(0, -a * a * 8, -a * 4))
                task.wait()
            end
            model:Destroy()
        end

        -- Респаун в случайной точке зоны с новым роллом размера/BigCatch
        task.wait(rng:NextNumber(5, 10))
        local newFish = spawnFish(z, index)
        local pos = table.find(allFish, fish)
        if pos then
            allFish[pos] = newFish
        else
            table.insert(allFish, newFish)
        end
    end)
end

-- Общая точка входа: валидация + заморозка рыбы + StartFishing
-- fish == nil → fallback (F): найти ближайшую свободную рыбу в радиусе PROMPT_DISTANCE
tryStartFishing = function(player, fish)
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

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Fallback (F-клавиша): ближайшая свободная рыба в радиусе
    if fish == nil then
        local zoneName = getPlayerZone(player)
        if not zoneName then return end
        local nearest, nearestDist = nil, PROMPT_DISTANCE
        for _, f in ipairs(allFish) do
            if f.zoneData and f.zoneData.id == zoneName and not f.busy and not f.frozen
            and f.model and f.model.Parent and f.primary then
                local d = (f.primary.Position - hrp.Position).Magnitude
                if d < nearestDist then
                    nearest = f
                    nearestDist = d
                end
            end
        end
        fish = nearest
        if not fish then return end
    end

    -- Валидация рыбы
    if fish.busy or fish.frozen then return end
    if not fish.model or not fish.model.Parent then return end

    local zoneName = fish.zoneData.id

    -- Проверить разблокировку зоны
    if not DataService:IsZoneUnlocked(player, zoneName) then return end

    -- Дистанция (анти-чит для промпта/фоллбэка)
    if (fish.primary.Position - hrp.Position).Magnitude > PROMPT_DISTANCE + 6 then return end

    -- Занять рыбу: заморозить AI, выключить промпт (двое не ловят одну рыбу)
    unfreezeForPlayer(userId)
    fish.busy = true
    fish.frozen = true
    fish.frozenUntil = tick() + 15
    fish.frozenPlayer = player
    fish.prompt.Enabled = false
    playerFrozenFish[userId] = fish

    -- BigCatch-сессия: атрибут на игроке читает ServerMain при CatchResult
    -- (валидация по атрибуту МОДЕЛИ на сервере — клиенту не доверяем)
    local isBig = fish.model:GetAttribute("BigCatch") == true
    player:SetAttribute("FishingBigCatch", isBig)

    activeFishing[userId] = true
    StartFishing:FireClient(player, { zone = zoneName })

    -- Разблокировать после таймаута (15 сек)
    task.delay(15, function()
        activeFishing[userId] = nil
    end)
end

-- F-клавиша — fallback без промпта
RequestFishing.OnServerEvent:Connect(function(player)
    tryStartFishing(player, nil)
end)

-- Рыба поймана (клиент сообщает только успех; вид рыбы роллит сервер в ServerMain)
Remotes:WaitForChild("CatchResult").OnServerEvent:Connect(function(player)
    local userId = tostring(player.UserId)
    activeFishing[userId] = nil
    player:SetAttribute("FishingBigCatch", nil)

    local fish = playerFrozenFish[userId]
    playerFrozenFish[userId] = nil
    if fish then
        despawnAndRespawn(fish)
    end
end)

-- Промах в Hook Phase (клиент шлёт result = "miss") → рыба возобновляет плавание
Remotes:WaitForChild("HookResult").OnServerEvent:Connect(function(player, payload)
    if type(payload) == "table" and payload.result == "miss" then
        local userId = tostring(player.UserId)
        activeFishing[userId] = nil
        player:SetAttribute("FishingBigCatch", nil)
        unfreezeForPlayer(userId)
    end
end)

-- Сбросить при выходе игрока
Players.PlayerRemoving:Connect(function(player)
    local userId = tostring(player.UserId)
    activeFishing[userId] = nil
    unfreezeForPlayer(userId)
end)

print("[ReefDiver] WorldSetup: зоны, рыбы AI, ProximityPrompt-рыбалка ✓")

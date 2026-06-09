-- ServerScriptService/Systems/FishingSpotSetup.server.lua
-- Reef Diver — Точки рыбалки с кастомными ProximityPrompt
-- Игрок подходит к воде → видит красивый промпт → забрасывает удочку
-- PLACEHOLDER: Part-площадки воды; замени на реальные модели воды/лунок

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RodData = require(ReplicatedStorage.Modules.RodData)
local DataService = require(script.Parent.Parent.Services.DataService)

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local StartFishing  = RemotesFolder:WaitForChild("StartFishing")

-- Папка точек рыбалки
local spotsFolder = workspace:FindFirstChild("FishingSpots")
if not spotsFolder then
    spotsFolder = Instance.new("Folder")
    spotsFolder.Name = "FishingSpots"
    spotsFolder.Parent = workspace
end

-- Позиции точек рыбалки рядом с каждой зоной
-- PLACEHOLDER: координаты примерные, подгони под карту
local SPOT_DATA = {
    { zone = "SunnyReef",   pos = CFrame.new(8, 0.5, 0),   color = Color3.fromRGB(0, 200, 255)  },
    { zone = "CoralTrench", pos = CFrame.new(8, -20, 0),   color = Color3.fromRGB(0, 180, 150)  },
    { zone = "OpenOcean",   pos = CFrame.new(8, -50, 0),   color = Color3.fromRGB(50, 100, 200) },
    { zone = "DarkWaters",  pos = CFrame.new(8, -100, 0),  color = Color3.fromRGB(120, 40, 200) },
    { zone = "Abyss",       pos = CFrame.new(8, -200, 0),  color = Color3.fromRGB(80, 10, 110)  },
}

-- ══ ПРОВЕРКА: НАДЕТА ЛИ УДОЧКА ══
local function hasRodEquipped(player)
    local char = player.Character
    if not char then return false end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and RodData:GetRod(item.Name) then
            return true
        end
    end
    return false
end

-- ══ СОЗДАТЬ ТОЧКУ РЫБАЛКИ ══
for _, spot in ipairs(SPOT_DATA) do
    -- PLACEHOLDER: круглая площадка-лунка для заброса
    local pad = Instance.new("Part")
    pad.Name        = "FishingSpot_" .. spot.zone
    pad.Shape       = Enum.PartType.Cylinder
    pad.Size        = Vector3.new(0.5, 8, 8)
    pad.CFrame      = spot.pos * CFrame.Angles(0, 0, math.rad(90))
    pad.Anchored    = true
    pad.CanCollide  = false
    pad.Transparency= 0.4
    pad.Material    = Enum.Material.Neon
    pad.BrickColor  = BrickColor.new(spot.color)
    pad.Parent      = spotsFolder

    -- ProximityPrompt со стилем Custom (рисуется на клиенте)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name            = "FishPrompt"
    prompt.ObjectText      = "Рыбалка"
    prompt.ActionText      = "Забросить удочку"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode  = Enum.KeyCode.ButtonX
    prompt.HoldDuration    = 0.3
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight   = false
    prompt.Style           = Enum.ProximityPromptStyle.Custom  -- кастомный UI на клиенте
    prompt:SetAttribute("Zone", spot.zone)  -- чтобы клиент знал зону
    prompt:SetAttribute("PromptKind", "Fishing")
    prompt.Parent          = pad

    -- Триггер заброса
    local zoneName = spot.zone
    prompt.Triggered:Connect(function(player)
        -- Проверить удочку
        if not hasRodEquipped(player) then
            -- Можно отправить тост "надень удочку" — пока просто игнор
            return
        end

        -- Проверить что зона разблокирована (точка может стоять в закрытой зоне)
        if not DataService:IsZoneUnlocked(player, zoneName) then
            return
        end

        -- Запустить мини-игру у клиента
        StartFishing:FireClient(player, { zone = zoneName })
    end)
end

print("[ReefDiver] FishingSpotSetup готов ✓")
print("[ReefDiver] ⚠ PLACEHOLDER: замени Part-лунки на реальные модели воды")

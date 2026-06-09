-- ServerScriptService/Systems/NPCStubs.server.lua
-- Reef Diver — Заглушки NPC для деревни
-- PLACEHOLDER: Все модели NPC = Part-заглушки с именами
-- При добавлении реальных моделей замени Part на модель и подключи правильные ProximityPrompt

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Strings = require(ReplicatedStorage.Modules.Strings)

-- Дождаться папки Remotes (создаётся RemoteSetup в ServerMain)
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local OpenNPC      = RemotesFolder and RemotesFolder:WaitForChild("OpenNPC", 10)
local OpenZoneMenu = RemotesFolder and RemotesFolder:WaitForChild("OpenZoneMenu", 10)

-- ══ КОНФИГУРАЦИЯ ПОЗИЦИЙ NPC ══
-- PLACEHOLDER: Замените CFrame на реальные позиции в деревне
local NPC_CONFIG = {
    {
        id      = "RodMaster",
        name    = Strings.NPC_RodMaster,
        dialog  = Strings.Dialog_RodMaster,
        -- PLACEHOLDER позиция
        position= CFrame.new(0, 3, -20),
        color   = Color3.fromRGB(200, 150, 50),   -- жёлтый = торговец
    },
    {
        id      = "FishMerchant",
        name    = Strings.NPC_FishMerchant,
        dialog  = Strings.Dialog_FishMerchant,
        position= CFrame.new(15, 3, -20),
        color   = Color3.fromRGB(50, 150, 200),   -- синий = рыбный торговец
    },
    {
        id      = "ElderDiver",
        name    = Strings.NPC_ElderDiver,
        dialog  = Strings.Dialog_ElderDiver,
        position= CFrame.new(-15, 3, -20),
        color   = Color3.fromRGB(150, 50, 200),   -- фиолетовый = rebirth
    },
    {
        id      = "ResearchSubmarine",
        name    = Strings.NPC_ResearchSub,
        dialog  = Strings.Dialog_ResearchSub,
        position= CFrame.new(0, 3, -40),
        color   = Color3.fromRGB(50, 200, 150),   -- бирюзовый = экспедиции
    },
    {
        id      = "Collector",
        name    = Strings.NPC_Collector,
        dialog  = Strings.Dialog_Collector,
        position= CFrame.new(25, 3, -35),
        color   = Color3.fromRGB(200, 100, 100),  -- красный = FishDex
    },
}

-- ══ СОЗДАНИЕ ЗАГЛУШЕК ══
local villageFolder = workspace:FindFirstChild("Village")
if not villageFolder then
    villageFolder = Instance.new("Folder")
    villageFolder.Name = "Village"
    villageFolder.Parent = workspace
end

for _, cfg in ipairs(NPC_CONFIG) do
    -- PLACEHOLDER NPC = цветной Part с именем
    -- Заменить на реальную модель: local model = game:GetService("InsertService"):LoadAsset(ASSET_ID)
    local npcPart = Instance.new("Part")
    npcPart.Name        = cfg.id
    npcPart.Size        = Vector3.new(2, 5, 2)
    npcPart.CFrame      = cfg.position
    npcPart.Anchored    = true
    npcPart.BrickColor  = BrickColor.new(cfg.color)
    npcPart.Material    = Enum.Material.SmoothPlastic
    npcPart.Parent      = villageFolder

    -- Лейбл с именем над NPC
    local billboard = Instance.new("BillboardGui")
    billboard.Name        = "NameTag"
    billboard.Size        = UDim2.new(0, 160, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = false
    billboard.Parent      = npcPart

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size                = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text                = cfg.name
    nameLabel.TextColor3          = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3    = Color3.new(0, 0, 0)
    nameLabel.Font                = Enum.Font.GothamBold
    nameLabel.TextScaled          = true
    nameLabel.Parent              = billboard

    -- ProximityPrompt для взаимодействия
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name            = "InteractPrompt"
    prompt.ObjectText      = cfg.name
    prompt.ActionText      = "Поговорить"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode  = Enum.KeyCode.ButtonX
    prompt.HoldDuration    = 0.2
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight   = false
    prompt.Style           = Enum.ProximityPromptStyle.Custom
    prompt:SetAttribute("PromptKind", "NPC")
    prompt:SetAttribute("NPCId", cfg.id)
    prompt.Parent          = npcPart

    -- Обработка взаимодействия — сигнал клиенту открыть нужный UI
    local npcId = cfg.id
    prompt.Triggered:Connect(function(player)
        if OpenNPC then
            OpenNPC:FireClient(player, npcId)
        end
    end)
end

-- ══ ВХОД В ТРЕЩИНУ (ЗАГЛУШКА ЗОНЫ) ══
-- PLACEHOLDER: создать Part для входа в каждую зону
local zonesFolder = workspace:FindFirstChild("Zones")
if not zonesFolder then
    zonesFolder = Instance.new("Folder")
    zonesFolder.Name = "Zones"
    zonesFolder.Parent = workspace
end

local zoneData = {
    { id = "SunnyReef",   pos = CFrame.new(0, 0, 0),   color = Color3.fromRGB(0, 200, 255)  },
    { id = "CoralTrench", pos = CFrame.new(0, -20, 0),  color = Color3.fromRGB(0, 180, 150)  },
    { id = "OpenOcean",   pos = CFrame.new(0, -50, 0),  color = Color3.fromRGB(50, 100, 200) },
    { id = "DarkWaters",  pos = CFrame.new(0, -100, 0), color = Color3.fromRGB(80, 30, 150)  },
    { id = "Abyss",       pos = CFrame.new(0, -200, 0), color = Color3.fromRGB(50, 5, 80)    },
}

for _, z in ipairs(zoneData) do
    local zonePart = Instance.new("Part")
    zonePart.Name        = z.id .. "_Zone"
    zonePart.Size        = Vector3.new(30, 2, 30)
    zonePart.CFrame      = z.pos
    zonePart.Anchored    = true
    zonePart.Transparency= 0.7
    zonePart.BrickColor  = BrickColor.new(z.color)
    zonePart.CanCollide  = false
    zonePart.Parent      = zonesFolder

    -- PLACEHOLDER: написать текст зоны над Part
    local label = Instance.new("BillboardGui")
    label.Size = UDim2.new(0, 200, 0, 30)
    label.StudsOffset = Vector3.new(0, 2, 0)
    label.AlwaysOnTop = false
    label.Parent = zonePart

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1,0,1,0)
    txt.BackgroundTransparency = 1
    txt.Text = z.id
    txt.TextColor3 = Color3.new(1,1,1)
    txt.Font = Enum.Font.GothamBold
    txt.TextScaled = true
    txt.Parent = label

    -- ══ ZONE KEEPER (NPC-телепортёр у щели) ══
    -- PLACEHOLDER: цветной Part, замени на реальную модель смотрителя
    local keeper = Instance.new("Part")
    keeper.Name       = "ZoneKeeper_" .. z.id
    keeper.Size       = Vector3.new(2, 5, 2)
    keeper.CFrame     = z.pos * CFrame.new(5, 2.5, 0)  -- рядом со щелью
    keeper.Anchored   = true
    keeper.BrickColor = BrickColor.new(z.color)
    keeper.Material   = Enum.Material.Neon
    keeper.CanCollide = false
    keeper.Parent     = zonesFolder

    local kbLabel = Instance.new("BillboardGui")
    kbLabel.Size = UDim2.new(0, 180, 0, 40)
    kbLabel.StudsOffset = Vector3.new(0, 3.5, 0)
    kbLabel.Parent = keeper
    local kTxt = Instance.new("TextLabel")
    kTxt.Size = UDim2.new(1,0,1,0)
    kTxt.BackgroundTransparency = 1
    kTxt.Text = "🌀 Zone Keeper"
    kTxt.TextColor3 = Color3.new(1,1,1)
    kTxt.TextStrokeTransparency = 0
    kTxt.Font = Enum.Font.GothamBold
    kTxt.TextScaled = true
    kTxt.Parent = kbLabel

    local kPrompt = Instance.new("ProximityPrompt")
    kPrompt.Name            = "ZonePrompt"
    kPrompt.ObjectText      = "Zone Keeper"
    kPrompt.ActionText      = "Путешествовать"
    kPrompt.KeyboardKeyCode = Enum.KeyCode.E
    kPrompt.GamepadKeyCode  = Enum.KeyCode.ButtonX
    kPrompt.HoldDuration    = 0.2
    kPrompt.MaxActivationDistance = 8
    kPrompt.RequiresLineOfSight   = false
    kPrompt.Style           = Enum.ProximityPromptStyle.Custom
    kPrompt:SetAttribute("PromptKind", "ZoneKeeper")
    kPrompt.Parent          = keeper

    -- При взаимодействии — открыть UI зон у клиента
    kPrompt.Triggered:Connect(function(plr)
        if OpenZoneMenu then
            OpenZoneMenu:FireClient(plr)
        end
    end)
end

print("[ReefDiver] NPC Stubs инициализированы ✓")
print("[ReefDiver] ⚠ PLACEHOLDER: Замени Part-модели на реальные модели NPC")

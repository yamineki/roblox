-- ServerScriptService/Systems/NPCStubs.server.lua
-- Reef Diver — Заглушки NPC для деревни
-- PLACEHOLDER: Все модели NPC = Part-заглушки с именами
-- При добавлении реальных моделей замени Part на модель и подключи правильные ProximityPrompt

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
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
    CollectionService:AddTag(billboard, "FixedSizeBillboard")

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

-- Зоны теперь создаются WorldSetup (FishingSpotSetup.server.lua).
-- Здесь только Zone Keeper NPC рядом с каждой зоной.
local zoneKeeperData = {
    { id = "SunnyReef",   pos = CFrame.new(90,  3,  100), color = Color3.fromRGB(0, 200, 255)  },
    { id = "CoralTrench", pos = CFrame.new(90,  3,  360), color = Color3.fromRGB(0, 180, 150)  },
    { id = "OpenOcean",   pos = CFrame.new(110, 3,  640), color = Color3.fromRGB(50, 100, 200) },
    { id = "DarkWaters",  pos = CFrame.new(130, 3,  960), color = Color3.fromRGB(80, 30, 150)  },
    { id = "Abyss",       pos = CFrame.new(160, 3, 1320), color = Color3.fromRGB(50, 5, 80)    },
}

for _, z in ipairs(zoneKeeperData) do
    local keeper = Instance.new("Part")
    keeper.Name       = "ZoneKeeper_" .. z.id
    keeper.Size       = Vector3.new(2, 5, 2)
    keeper.CFrame     = z.pos
    keeper.Anchored   = true
    keeper.Color      = z.color
    keeper.Material   = Enum.Material.Neon
    keeper.CanCollide = true
    keeper.Parent     = zonesFolder

    local kbLabel = Instance.new("BillboardGui")
    kbLabel.Size = UDim2.fromOffset(180, 50)
    kbLabel.StudsOffset = Vector3.new(0, 3.5, 0)
    kbLabel.AlwaysOnTop = false
    kbLabel.Parent = keeper
    CollectionService:AddTag(kbLabel, "FixedSizeBillboard")

    local kTxt = Instance.new("TextLabel")
    kTxt.Size = UDim2.fromScale(1, 1)
    kTxt.BackgroundTransparency = 1
    kTxt.Text = "🌀 Zone Keeper\n" .. z.id
    kTxt.TextColor3 = Color3.new(1,1,1)
    kTxt.TextStrokeTransparency = 0.2
    kTxt.Font = Enum.Font.GothamBold
    kTxt.TextScaled = true
    kTxt.Parent = kbLabel

    local kPrompt = Instance.new("ProximityPrompt")
    kPrompt.Name            = "ZonePrompt"
    kPrompt.ObjectText      = "Zone Keeper"
    kPrompt.ActionText      = "Путешествовать"
    kPrompt.KeyboardKeyCode = Enum.KeyCode.E
    kPrompt.HoldDuration    = 0.2
    kPrompt.MaxActivationDistance = 8
    kPrompt.RequiresLineOfSight   = false
    kPrompt.Style           = Enum.ProximityPromptStyle.Custom
    kPrompt:SetAttribute("PromptKind", "ZoneKeeper")
    kPrompt.Parent          = keeper

    kPrompt.Triggered:Connect(function(plr)
        if OpenZoneMenu then
            OpenZoneMenu:FireClient(plr)
        end
    end)
end

print("[ReefDiver] NPC Stubs инициализированы ✓")
print("[ReefDiver] ⚠ PLACEHOLDER: Замени Part-модели на реальные модели NPC")

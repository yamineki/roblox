-- StarterPlayerScripts/NPCDialog.client.lua
-- Reef Diver — Диалоговое окно NPC (стиль Grow a Garden)
-- Печатная машинка + варианты ответа + интеграция с магазинами через ShopBridge

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Strings    = require(ReplicatedStorage.Modules.Strings)
local ShopBridge = require(ReplicatedStorage.Modules.ShopBridge)
local okSound, SoundFX = pcall(function() return require(ReplicatedStorage.Modules.SoundFX) end)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OpenNPC = Remotes:WaitForChild("OpenNPC")

local function playSound(name)
    if okSound and SoundFX then
        SoundFX.Play(name)
    end
end

-- ══ GUI (создан UIBuilder.lua) ══
local gui   = PlayerGui:WaitForChild("NPCDialogGui", 15)

local panel, dim, portrait, portraitIcon, nameLabel, dialogText, choicesRow, choice1, choice2

if gui then
    dim          = gui:WaitForChild("Dim")
    panel        = gui:WaitForChild("Panel")
    portrait     = panel:WaitForChild("Portrait")
    portraitIcon = portrait:WaitForChild("PortraitIcon")
    nameLabel    = panel:WaitForChild("NameLabel")
    dialogText   = panel:WaitForChild("DialogText")
    choicesRow   = panel:WaitForChild("ChoicesRow")
    choice1      = choicesRow:WaitForChild("Choice1")
    choice2      = choicesRow:WaitForChild("Choice2")
end

-- ══ КОНФИГУРАЦИЯ ДИАЛОГОВ ПО NPC ══
local DIALOG_CONFIG = {
    RodMaster = {
        name = Strings.NPC_RodMaster,
        icon = "🎣",
        lines = {
            Strings.Dialog_RodMaster,
            "У меня есть удочки на любой вкус — от простых до самых прочных!",
            "Загляни в мой магазин, не пожалеешь.",
        },
        positiveChoice = "Да, покажи!",
        negativeChoice = "Может позже",
        action = function()
            ShopBridge.OpenRodShop()
        end,
    },
    FishMerchant = {
        name = Strings.NPC_FishMerchant,
        icon = "🐟",
        lines = {
            Strings.Dialog_FishMerchant,
            "Свежий улов всегда в цене, неси сюда самое интересное!",
        },
        positiveChoice = "Хорошо!",
        negativeChoice = "Пока нет",
        action = function()
            -- Продажа рыбы происходит через отдельный интерфейс инвентаря
        end,
    },
    ElderDiver = {
        name = Strings.NPC_ElderDiver,
        icon = "🧙",
        lines = {
            Strings.Dialog_ElderDiver,
            "Перерождение откроет тебе новые горизонты, но путь назад будет закрыт.",
            "Подумай хорошенько, прежде чем решаться.",
        },
        positiveChoice = "Да!",
        negativeChoice = "Ещё не готов",
        action = function()
            ShopBridge.OpenMonetizationShop()
        end,
    },
    ResearchSubmarine = {
        name = Strings.NPC_ResearchSub,
        icon = "🚤",
        lines = {
            Strings.Dialog_ResearchSub,
            "Отправь меня в плавание — а пока занимайся своими делами.",
        },
        positiveChoice = "Отправить!",
        negativeChoice = "Не сейчас",
        action = function()
            -- Интерфейс AFK-экспедиций откроется отдельно
        end,
    },
    Collector = {
        name = Strings.NPC_Collector,
        icon = "📖",
        lines = {
            Strings.Dialog_Collector,
            "Каждая редкая находка остаётся в твоей коллекции навсегда!",
        },
        positiveChoice = "Покажи!",
        negativeChoice = "Позже",
        action = function()
            -- FishDex откроется отдельно
        end,
    },
}

-- ══ СОСТОЯНИЕ ══
local isOpen = false
local currentConfig = nil
local currentLineIndex = 1
local typing = false
local skipRequested = false
local typeToken = 0

-- ══ ПЕЧАТНАЯ МАШИНКА ══
local function typeLine(text)
    typing = true
    skipRequested = false
    typeToken = typeToken + 1
    local myToken = typeToken

    dialogText.Text = ""
    choicesRow.Visible = false

    for i = 1, #text do
        if myToken ~= typeToken then return end
        if skipRequested then
            dialogText.Text = text
            break
        end
        dialogText.Text = text:sub(1, i)
        if i % 3 == 0 then
            playSound("TypeBlip")
        end
        task.wait(0.025)
    end

    if myToken ~= typeToken then return end
    dialogText.Text = text
    typing = false

    if currentLineIndex >= #currentConfig.lines then
        choicesRow.Visible = true
    end
end

local function showLine(index)
    currentLineIndex = index
    typeLine(currentConfig.lines[index])
end

local function advance()
    if typing then
        skipRequested = true
        return
    end
    if currentLineIndex < #currentConfig.lines then
        showLine(currentLineIndex + 1)
    end
end

-- ══ ОТКРЫТЬ / ЗАКРЫТЬ ══
local function closeDialog(callback)
    if not gui then return end
    isOpen = false
    typeToken = typeToken + 1
    playSound("Close")

    TweenService:Create(panel,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5, 0, 1.6, 0) }):Play()

    task.delay(0.3, function()
        gui.Enabled = false
        panel.Position = UDim2.new(0.5, 0, 1, -40)
        if callback then callback() end
    end)
end

local function openDialog(npcId)
    local config = DIALOG_CONFIG[npcId]
    if not gui or not config then return end

    currentConfig = config
    isOpen = true
    gui.Enabled = true
    playSound("Open")

    nameLabel.Text = config.name
    portraitIcon.Text = config.icon
    choice1.Text = config.positiveChoice or "Да"
    choice2.Text = config.negativeChoice or "Может позже"
    choicesRow.Visible = false

    panel.Position = UDim2.new(0.5, 0, 1.6, 0)
    TweenService:Create(panel,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, 0, 1, -40) }):Play()

    showLine(1)
end

-- ══ ВЗАИМОДЕЙСТВИЯ ══
if gui then
    -- Клик по диалоговой области — пропустить печать или продолжить
    dialogText.Active = true
    dialogText.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            advance()
        end
    end)

    -- Клик по портрету тоже продолжает диалог
    portrait.Active = true
    portrait.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            advance()
        end
    end)

    choice1.MouseButton1Click:Connect(function()
        playSound("Click")
        local action = currentConfig and currentConfig.action
        closeDialog(function()
            if action then action() end
        end)
    end)

    choice2.MouseButton1Click:Connect(function()
        playSound("Click")
        closeDialog()
    end)

    if dim then
        dim.MouseButton1Click:Connect(function()
            closeDialog()
        end)
    end
end

-- ══ ОТКРЫТЬ ПО СОБЫТИЮ NPC ══
OpenNPC.OnClientEvent:Connect(function(npcId)
    if DIALOG_CONFIG[npcId] then
        openDialog(npcId)
    end
end)

print("[ReefDiver] NPCDialog инициализирован ✓")

-- StarterPlayerScripts/NPCDialog.client.lua
-- Reef Diver — NPC Dialog (Grow a Garden style)
-- Typewriter text + choice buttons + shop integration via ShopBridge

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopBridge = require(ReplicatedStorage.Modules.ShopBridge)
local okSound, SoundFX = pcall(function() return require(ReplicatedStorage.Modules.SoundFX) end)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OpenNPC = Remotes:WaitForChild("OpenNPC")

local function playSound(name)
    if okSound and SoundFX then SoundFX.Play(name) end
end

-- ══ GUI (created by UIBuilder.lua) ══
local gui = PlayerGui:WaitForChild("NPCDialogGui", 15)

local panel, dim, clickArea, portrait, portraitIcon, nameLabel, dialogText, choicesRow, choice1, choice2

if gui then
    dim          = gui:WaitForChild("Dim")
    panel        = gui:WaitForChild("Panel")
    clickArea    = panel:FindFirstChild("ClickArea")   -- transparent advance button
    portrait     = panel:WaitForChild("Portrait")
    portraitIcon = portrait:WaitForChild("PortraitIcon")
    nameLabel    = panel:WaitForChild("NameLabel")
    dialogText   = panel:WaitForChild("DialogText")
    choicesRow   = panel:WaitForChild("ChoicesRow")
    choice1      = choicesRow:WaitForChild("Choice1")
    choice2      = choicesRow:WaitForChild("Choice2")
end

-- ══ DIALOG CONFIG ══
local DIALOG_CONFIG = {
    RodMaster = {
        name = "Rod Master",
        icon = "🎣",
        lines = {
            "Ahoy there, diver! Looking for a better rod?",
            "I stock everything from basic poles to deep-sea beasts.",
            "Step into my shop — you won't be disappointed!",
        },
        positiveChoice = "Show me!",
        negativeChoice = "Maybe later",
        action = function() ShopBridge.OpenRodShop() end,
    },
    FishMerchant = {
        name = "Fish Merchant",
        icon = "🐟",
        lines = {
            "Fresh catch always fetches a good price!",
            "Bring me your rarest finds — I pay top coin.",
        },
        positiveChoice = "Got it!",
        negativeChoice = "Not right now",
        action = function() end,
    },
    ElderDiver = {
        name = "Elder Diver",
        icon = "🧙",
        lines = {
            "You've ventured far, young diver...",
            "Rebirth will unlock new horizons, but there's no turning back.",
            "Think carefully before you decide.",
        },
        positiveChoice = "Rebirth!",
        negativeChoice = "Not yet",
        action = function() ShopBridge.OpenMonetizationShop() end,
    },
    ResearchSubmarine = {
        name = "Research Sub",
        icon = "🚤",
        lines = {
            "Send me out on a voyage while you explore!",
            "I'll bring back treasures from the deep.",
        },
        positiveChoice = "Set sail!",
        negativeChoice = "Not now",
        action = function() end,
    },
    Collector = {
        name = "Collector",
        icon = "📖",
        lines = {
            "Every rare catch is logged in your collection forever!",
            "Complete your FishDex and unlock exclusive rewards.",
        },
        positiveChoice = "Show me!",
        negativeChoice = "Later",
        action = function() end,
    },
}

-- ══ STATE ══
local isOpen = false
local currentConfig = nil
local currentLineIndex = 1
local typing = false
local skipRequested = false
local typeToken = 0

-- ══ TYPEWRITER ══
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
        if i % 3 == 0 then playSound("TypeBlip") end
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

-- Advance: skip typewriter OR go to next line
local function advance()
    if typing then
        skipRequested = true
        return
    end
    if currentLineIndex < #currentConfig.lines then
        showLine(currentLineIndex + 1)
    end
    -- If on last line and choices are visible, do nothing (player clicks Choice1/Choice2)
end

-- ══ OPEN / CLOSE ══
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
    currentLineIndex = 1
    isOpen = true
    gui.Enabled = true
    playSound("Open")

    nameLabel.Text = config.name
    portraitIcon.Text = config.icon
    choice1.Text = config.positiveChoice or "Yes"
    choice2.Text = config.negativeChoice or "Maybe later"
    choicesRow.Visible = false

    panel.Position = UDim2.new(0.5, 0, 1.6, 0)
    TweenService:Create(panel,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, 0, 1, -40) }):Play()

    showLine(1)
end

-- ══ INTERACTIONS ══
if gui then
    -- ClickArea (transparent button covering panel) — advance dialog on click
    if clickArea then
        clickArea.MouseButton1Click:Connect(function()
            advance()
        end)
    end

    -- Choice buttons
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

    -- Dim only closes when choices are showing (player pressed outside panel)
    if dim then
        dim.MouseButton1Click:Connect(function()
            if choicesRow.Visible then
                closeDialog()
            else
                advance()
            end
        end)
    end
end

-- ══ SERVER EVENT ══
OpenNPC.OnClientEvent:Connect(function(npcId)
    if not npcId then return end
    openDialog(npcId)
end)

print("[ReefDiver] NPCDialog initialised ✓")

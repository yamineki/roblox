-- StarterPlayerScripts/FishingMinigame.client.lua
-- Reef Diver — Клиентская мини-игра рыбалки
-- Три этапа: Hook Phase → Catching Phase → Result Phase

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local SoundService       = game:GetService("SoundService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Strings    = require(ReplicatedStorage.Modules.Strings)
local FishData   = require(ReplicatedStorage.Modules.FishData)

local Player     = Players.LocalPlayer
local PlayerGui  = Player.PlayerGui

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartFishing = Remotes:WaitForChild("StartFishing")
local HookResultEvent = Remotes:WaitForChild("HookResult")
local CatchResultEvent = Remotes:WaitForChild("CatchResult")
local FishCaughtEvent  = Remotes:WaitForChild("FishCaught")
local FishEscapedEvent = Remotes:WaitForChild("FishEscaped")

-- ══ ПЕРЕМЕННЫЕ СОСТОЯНИЯ ══
local isMinigameActive = false
local currentPhase     = nil   -- "hook" | "catching" | "result"
local currentZone      = "SunnyReef"
local hookResult       = "good"

-- Catching Phase
local catchProgress    = 0      -- 0–100
local isPerfectCatch   = true   -- true пока рыба ни разу не выходила из зоны
local fishPos          = 200    -- позиция рыбы (0 = низ, 400 = верх)
local fishVelocity     = 0
local greenZonePos     = 200    -- позиция центра зелёной зоны
local greenZoneVel     = 0
local isHolding        = false
local stressElapsed    = 0
local stressMultiplier = 1.0

-- Поведение текущей рыбы (определяет паттерн движения в мини-игре)
local currentBehavior  = nil   -- таблица из GameConfig.FishBehavior
local fishTargetDir    = 1     -- текущее направление (-1 вниз, 1 вверх)
local dirChangeTimer   = 0     -- таймер до следующей смены направления
local rng              = Random.new()
local catchElapsed     = 0

-- Hook Phase
local arrowAngle       = 0      -- градусы
local hookArrowSpeed   = GameConfig.Fishing.HookArrowBaseSpeed

-- ══ ЗАГЛУШКИ ЗВУКОВ ══
-- PLACEHOLDER: заменить SoundId на реальные
local function playSound(name)
    -- TODO: SoundService:FindFirstChild(name) и :Play()
    -- Пример: local snd = SoundService:FindFirstChild("Click"); if snd then snd:Play() end
end

-- ══ UI ЭЛЕМЕНТЫ ══
-- Все ImageLabel.Image = "" — плейсхолдеры
-- Реальная структура UI подключается через StarterGui скрипты

local FishingGui = PlayerGui:WaitForChild("FishingGui", 10)
local hookGui, catchGui, resultGui

if FishingGui then
    hookGui   = FishingGui:FindFirstChild("HookPhase")
    catchGui  = FishingGui:FindFirstChild("CatchPhase")
    resultGui = FishingGui:FindFirstChild("ResultPhase")
end

local function setGuiVisible(name, visible)
    if not FishingGui then return end
    local g = FishingGui:FindFirstChild(name)
    if g then g.Visible = visible end
end

-- ══ FORWARD DECLARATIONS (функции ссылаются друг на друга) ══
local startHookPhase
local updateHookPhase
local onHookInput
local startCatchPhase
local updateCatchPhase
local finishCatch

-- ══ ФАЗА 1: ПОДСЕЧКА ══
function startHookPhase()
    currentPhase = "hook"
    arrowAngle = 0
    hookResult = "good"

    setGuiVisible("HookPhase", true)
    setGuiVisible("CatchPhase", false)
    setGuiVisible("ResultPhase", false)

    -- Подсказка игроку
    if hookGui then
        local label = hookGui:FindFirstChild("HintLabel")
        if label then label.Text = Strings.Hook_Press end
    end

    playSound("onHover")
end

function updateHookPhase(dt)
    arrowAngle = (arrowAngle + hookArrowSpeed * dt) % 360

    -- Обновить визуал стрелки
    if hookGui then
        local arrow = hookGui:FindFirstChild("Arrow")
        if arrow then
            arrow.Rotation = arrowAngle
        end
    end
end

function onHookInput()
    if currentPhase ~= "hook" then return end

    local halfZone = GameConfig.Fishing.HookZoneAngle / 2
    -- Предполагаем, что зелёная зона центрирована в районе 90°
    local zoneCenter = 90
    local diff = math.abs(((arrowAngle - zoneCenter) + 180) % 360 - 180)

    if diff <= GameConfig.Fishing.HookPerfectWindow then
        hookResult = "perfect"
        if hookGui then
            local lbl = hookGui:FindFirstChild("HintLabel")
            if lbl then lbl.Text = Strings.Hook_Perfect end
        end
        playSound("onButtonClick")
    elseif diff <= halfZone then
        hookResult = "good"
        if hookGui then
            local lbl = hookGui:FindFirstChild("HintLabel")
            if lbl then lbl.Text = Strings.Hook_Good end
        end
        playSound("onButtonClick")
    else
        hookResult = "miss"
        if hookGui then
            local lbl = hookGui:FindFirstChild("HintLabel")
            if lbl then lbl.Text = Strings.Hook_Miss end
        end
        playSound("onClose")
        -- Небольшая задержка и завершить мини-игру
        task.delay(0.8, function()
            HookResultEvent:FireServer({ result = "miss", zone = currentZone })
            isMinigameActive = false
            setGuiVisible("HookPhase", false)
        end)
        return
    end

    -- Сообщить серверу (только perfect/good — серверу не нужно, процесс идёт дальше)
    task.delay(0.5, function()
        startCatchPhase()
    end)
end

-- ══ ФАЗА 2: CATCHING ══
function startCatchPhase()
    currentPhase   = "catching"
    catchProgress  = 0
    isPerfectCatch = true
    fishPos        = 200
    fishVelocity   = 0
    greenZonePos   = 200
    greenZoneVel   = 0
    stressElapsed  = 0
    stressMultiplier = 1.0
    catchElapsed   = 0
    isHolding      = false
    fishTargetDir  = (rng:NextInteger(0,1) == 0) and -1 or 1
    dirChangeTimer = 0

    -- Выбрать поведение по случайной рыбе из текущей зоны.
    -- (Тип влияет ТОЛЬКО на сложность мини-игры; реальная рыба = серверный ролл.)
    local zoneFish = FishData:GetFishInZone(currentZone)
    if #zoneFish > 0 then
        local pick = zoneFish[rng:NextInteger(1, #zoneFish)]
        currentBehavior = GameConfig.FishBehavior[pick.behavior] or GameConfig.FishBehavior.Lazy
        -- Показать имя поведения игроку (подсказка о сложности)
        if catchGui then
            local bl = catchGui:FindFirstChild("BehaviorLabel")
            if bl then bl.Text = pick.behavior end
        end
    else
        currentBehavior = GameConfig.FishBehavior.Lazy
    end

    setGuiVisible("HookPhase", false)
    setGuiVisible("CatchPhase", true)

    playSound("onButtonClick")
end

function updateCatchPhase(dt)
    catchElapsed = catchElapsed + dt

    -- Stress Meter
    if catchElapsed > GameConfig.Fishing.StressStartDelay then
        stressElapsed = stressElapsed + dt
        if stressElapsed >= GameConfig.Fishing.StressInterval then
            stressElapsed = 0
            stressMultiplier = stressMultiplier + GameConfig.Fishing.StressSpeedBonus
        end
    end

    -- ══ ДВИЖЕНИЕ РЫБЫ ПО ПОВЕДЕНИЮ ══
    local b = currentBehavior or GameConfig.FishBehavior.Lazy
    local scaleH = GameConfig.Fishing.ScaleHeight

    -- Таймер смены направления
    dirChangeTimer = dirChangeTimer - dt
    if dirChangeTimer <= 0 then
        -- Сменить направление
        fishTargetDir = (rng:NextInteger(0,1) == 0) and -1 or 1
        dirChangeTimer = b.dirCooldown * (0.6 + rng:NextNumber() * 0.8)

        -- Шанс резкого рывка (jump)
        if b.jumpChance > 0 and rng:NextNumber() < b.jumpChance then
            fishPos = math.clamp(
                fishPos + fishTargetDir * b.jumpDistance,
                0, scaleH
            )
            playSound("onHover")
        end
    end

    -- Целевая скорость в направлении (с учётом stress и gravityBias)
    local targetVel = fishTargetDir * b.speed * stressMultiplier
    targetVel = targetVel - (b.gravityBias or 0) * b.speed  -- Sinker тонет, Floater всплывает

    -- Плавное приближение к целевой скорости (accel = резкость)
    fishVelocity = fishVelocity + (targetVel - fishVelocity) * math.min(1, b.accel * dt)

    fishPos = fishPos + fishVelocity * dt

    -- Отскок от границ шкалы
    if fishPos <= 0 then
        fishPos = 0
        fishTargetDir = 1
        fishVelocity = math.abs(fishVelocity) * 0.5
    elseif fishPos >= scaleH then
        fishPos = scaleH
        fishTargetDir = -1
        fishVelocity = -math.abs(fishVelocity) * 0.5
    end

    -- Движение зелёной зоны
    local halfZone = GameConfig.GreenZone.Height / 2
    if isHolding then
        greenZoneVel = greenZoneVel + GameConfig.GreenZone.Acceleration * dt
    else
        greenZoneVel = greenZoneVel - GameConfig.GreenZone.Gravity * dt
    end
    greenZoneVel = math.clamp(greenZoneVel, -GameConfig.GreenZone.MaxSpeed, GameConfig.GreenZone.MaxSpeed)
    greenZonePos = math.clamp(
        greenZonePos + greenZoneVel * dt,
        halfZone,
        GameConfig.Fishing.ScaleHeight - halfZone
    )

    -- Проверить попадание рыбы в зону
    local fishInZone = math.abs(fishPos - greenZonePos) <= halfZone

    if fishInZone then
        catchProgress = math.clamp(
            catchProgress + GameConfig.Fishing.CatchRate * dt,
            0, GameConfig.Fishing.MaxProgress
        )
    else
        catchProgress = math.clamp(
            catchProgress - GameConfig.Fishing.EscapeRate * dt,
            0, GameConfig.Fishing.MaxProgress
        )
        isPerfectCatch = false
    end

    -- Обновить UI
    if catchGui then
        local progressBar = catchGui:FindFirstChild("ProgressBar")
        local fishIndicator = catchGui:FindFirstChild("FishIndicator")
        local greenZoneFrame = catchGui:FindFirstChild("GreenZone")

        if progressBar then
            local fill = progressBar:FindFirstChild("Fill")
            if fill then
                fill.Size = UDim2.new(catchProgress / 100, 0, 1, 0)
            end
        end

        -- Позиционирование (UDim2 относительно шкалы)
        if fishIndicator then
            fishIndicator.Position = UDim2.new(0.5, 0, 1 - fishPos / GameConfig.Fishing.ScaleHeight, 0)
        end
        if greenZoneFrame then
            greenZoneFrame.Position = UDim2.new(0, 0, 1 - greenZonePos / GameConfig.Fishing.ScaleHeight, 0)
        end

        -- Stress предупреждение
        local stressLabel = catchGui:FindFirstChild("StressLabel")
        if stressLabel then
            stressLabel.Visible = stressMultiplier > 1.2
            if stressLabel.Visible then
                stressLabel.Text = Strings.Stress_Warning
            end
        end

        -- Perfect Catch статус
        local perfectLabel = catchGui:FindFirstChild("PerfectLabel")
        if perfectLabel then
            perfectLabel.Visible = isPerfectCatch
            if isPerfectCatch then
                perfectLabel.Text = Strings.Catching_Perfect
            end
        end
    end

    -- Победа
    if catchProgress >= GameConfig.Fishing.MaxProgress then
        finishCatch(true)
    end

    -- Поражение
    if catchProgress <= GameConfig.Fishing.MinProgress then
        finishCatch(false)
    end
end

-- ══ ЗАВЕРШЕНИЕ ПОИМКИ ══
finishCatch = function(success)
    currentPhase = "result"
    setGuiVisible("CatchPhase", false)

    if success then
        -- Отправить результат на сервер
        CatchResultEvent:FireServer({
            zone          = currentZone,
            hookResult    = hookResult,
            isPerfectCatch= isPerfectCatch,
        })
        playSound("onButtonClick")
        -- Защита от зависания: если сервер не ответил FishCaught за 10 сек — разблокировать
        task.delay(10, function()
            if isMinigameActive and currentPhase == "result" then
                isMinigameActive = false
                setGuiVisible("ResultPhase", false)
            end
        end)
    else
        -- Рыба сбежала
        isMinigameActive = false
        playSound("onClose")
        if catchGui then
            local hint = catchGui:FindFirstChild("EscapeLabel")
            if hint then
                hint.Visible = true
                hint.Text = Strings.Catching_Escaped
            end
        end
        task.delay(1.5, function()
            if catchGui then
                local hint = catchGui:FindFirstChild("EscapeLabel")
                if hint then hint.Visible = false end
            end
            setGuiVisible("CatchPhase", false)
        end)
    end
end

-- ══ ФАЗА 3: РЕЗУЛЬТАТ ══
FishCaughtEvent.OnClientEvent:Connect(function(catchEntry)
    isMinigameActive = false
    currentPhase = "result"

    setGuiVisible("ResultPhase", true)

    if resultGui then
        -- PLACEHOLDER: все Image = "" — заменить на реальные asset ID
        local fishImage   = resultGui:FindFirstChild("FishImage")
        local nameLabel   = resultGui:FindFirstChild("FishName")
        local rarityLabel = resultGui:FindFirstChild("FishRarity")
        local sizeLabel   = resultGui:FindFirstChild("FishSize")
        local mutLabel    = resultGui:FindFirstChild("FishMutation")
        local valueLabel  = resultGui:FindFirstChild("FishValue")
        local perfectLabel= resultGui:FindFirstChild("PerfectBonus")

        if fishImage  then fishImage.Image  = catchEntry.image or "" end  -- PLACEHOLDER
        if nameLabel  then nameLabel.Text   = catchEntry.displayName end
        if rarityLabel then rarityLabel.Text = catchEntry.rarity end
        if sizeLabel  then sizeLabel.Text   = catchEntry.size end
        if mutLabel   then
            mutLabel.Text    = catchEntry.mutation and Strings["Mutation_" .. catchEntry.mutation] or Strings.Mutation_None
            mutLabel.Visible = catchEntry.mutation ~= nil
        end
        if valueLabel then valueLabel.Text = tostring(catchEntry.value) .. " 🪙" end
        if perfectLabel then
            perfectLabel.Visible = catchEntry.isPerfectCatch
            if catchEntry.isPerfectCatch then
                perfectLabel.Text = Strings.Catch_PerfectBonus
            end
        end
    end

    -- Анимация появления
    if resultGui then
        resultGui.BackgroundTransparency = 1
        local tween = TweenService:Create(
            resultGui,
            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = 0.1 }
        )
        tween:Play()
    end

    playSound("onButtonClick")

    -- Закрыть через 3 секунды или по нажатию
    task.delay(3, function()
        if currentPhase == "result" then
            setGuiVisible("ResultPhase", false)
        end
    end)
end)

-- ══ ЗАПУСК МИНИ-ИГРЫ ══
local function beginFishing()
    if isMinigameActive then return end
    isMinigameActive = true
    hookArrowSpeed = GameConfig.Fishing.HookArrowBaseSpeed
    startHookPhase()
end

-- Сервер может явно запустить рыбалку (например по ProximityPrompt у воды)
StartFishing.OnClientEvent:Connect(function(data)
    if data and data.zone then currentZone = data.zone end
    beginFishing()
end)

-- Синхронизация текущей зоны: при входе в зону через Zone Keeper
local ZoneEnteredEvent = Remotes:WaitForChild("ZoneEntered")
ZoneEnteredEvent.OnClientEvent:Connect(function(payload)
    if payload and payload.success and payload.zoneName then
        currentZone = payload.zoneName
    end
end)

-- Узнать стартовую зону при загрузке
task.spawn(function()
    local GetZoneStatus = Remotes:WaitForChild("GetZoneStatus")
    local ok, status = pcall(function() return GetZoneStatus:InvokeServer() end)
    if ok and status and status.currentZone then
        currentZone = status.currentZone
    end
end)

-- ══ INPUT ══
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E and currentPhase == "hook" then
        onHookInput()
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if currentPhase ~= "catching" then return end
    if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isHolding = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isHolding = false
    end
end)

-- ══ GAME LOOP ══
RunService.RenderStepped:Connect(function(dt)
    if not isMinigameActive then return end
    if currentPhase == "hook" then
        updateHookPhase(dt)
    elseif currentPhase == "catching" then
        updateCatchPhase(dt)
    end
end)

-- Заброс удочки происходит через ProximityPrompt у воды (FishingSpotSetup на сервере).
-- Сервер проверяет удочку и шлёт StartFishing → beginFishing() выше.

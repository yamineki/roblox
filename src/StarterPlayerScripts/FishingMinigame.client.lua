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
local SoundFX    = require(ReplicatedStorage.Modules.SoundFX)

local Player     = Players.LocalPlayer
local PlayerGui  = Player.PlayerGui

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartFishing = Remotes:WaitForChild("StartFishing")
local RequestFishing = Remotes:WaitForChild("RequestFishing")
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
local rodShakeTween    = nil

-- Catch Phase juice
local fishInZonePrev   = false
local lastRippleTime   = 0
local zoneTintTween    = nil

-- ══ ЗВУКИ ══
local function playSound(name)
    SoundFX.Play(name)
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
    arrowAngle   = 0
    hookResult   = "good"

    setGuiVisible("HookPhase",  true)
    setGuiVisible("CatchPhase", false)
    setGuiVisible("ResultPhase",false)

    if hookGui then
        local label = hookGui:FindFirstChild("HintLabel")
        if label then label.Text = Strings.Hook_Press end
        -- Сбросить позицию индикатора (SliderIndicator лежит внутри SliderBG)
        local sliderBG  = hookGui:FindFirstChild("SliderBG")
        local indicator = sliderBG and sliderBG:FindFirstChild("SliderIndicator")
        if indicator then
            indicator.Position = UDim2.new(0.5, -15, 0, 0)
        end
    end

    -- "Тряска удочки" — лёгкое покачивание HookPhase для ощущения натяжения
    if rodShakeTween then
        rodShakeTween:Cancel()
        rodShakeTween = nil
    end
    if hookGui then
        hookGui.Rotation = -1
        rodShakeTween = TweenService:Create(
            hookGui,
            TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { Rotation = 1 }
        )
        rodShakeTween:Play()
    end

    playSound("CastRod")
end

function updateHookPhase(dt)
    arrowAngle = (arrowAngle + hookArrowSpeed * dt) % 360

    -- Индикатор движется по горизонтали (сinус → -1..1 → позиция по бару)
    -- Переводим угол в позицию по горизонтальному бару
    local t = (math.sin(math.rad(arrowAngle)) + 1) / 2  -- 0..1

    if hookGui then
        -- Новый горизонтальный слайдер (SliderIndicator лежит внутри SliderBG)
        local sliderBG  = hookGui:FindFirstChild("SliderBG")
        local indicator = sliderBG and sliderBG:FindFirstChild("SliderIndicator")
        if indicator then
            indicator.Position = UDim2.new(t, -15, 0, 0)
        end
        -- Старый вращающийся Arrow (если ещё в GUI)
        local arrow = hookGui:FindFirstChild("Arrow")
        if arrow then
            arrow.Rotation = arrowAngle
        end
    end
end

function onHookInput()
    if currentPhase ~= "hook" then return end

    -- БАГФИКС: раньше проверка шла по углу (центр 90°), а визуально зелёная зона
    -- находится в ЦЕНТРЕ горизонтального бара (t = 0.5, что соответствует sin = 0).
    -- Теперь логика совпадает с тем, что видит игрок: считаем позицию индикатора
    -- по бару и сравниваем с центром в тех же "градусных" единицах, что и зоны.
    local t = (math.sin(math.rad(arrowAngle)) + 1) / 2  -- 0..1 позиция индикатора
    local diff = math.abs(t - 0.5) * 360                -- расстояние от центра зоны в ед. HookZoneAngle
    local halfZone = GameConfig.Fishing.HookZoneAngle / 2

    -- Вспышка цвета индикатора по результату подсечки
    local function flashIndicator(flashColor)
        if not hookGui then return end
        local sliderBG  = hookGui:FindFirstChild("SliderBG")
        local indicator = sliderBG and sliderBG:FindFirstChild("SliderIndicator")
        if not indicator then return end
        local original = indicator.BackgroundColor3
        indicator.BackgroundColor3 = flashColor
        TweenService:Create(
            indicator,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = Color3.fromRGB(235,235,235) }
        ):Play()
    end

    if diff <= GameConfig.Fishing.HookPerfectWindow then
        hookResult = "perfect"
        if hookGui then
            local lbl = hookGui:FindFirstChild("HintLabel")
            if lbl then lbl.Text = Strings.Hook_Perfect end
        end
        playSound("HookHit")
        flashIndicator(Color3.fromRGB(90,200,110))
    elseif diff <= halfZone then
        hookResult = "good"
        if hookGui then
            local lbl = hookGui:FindFirstChild("HintLabel")
            if lbl then lbl.Text = Strings.Hook_Good end
        end
        playSound("HookHit")
        flashIndicator(Color3.fromRGB(90,200,110))
    else
        hookResult = "miss"
        if hookGui then
            local lbl = hookGui:FindFirstChild("HintLabel")
            if lbl then lbl.Text = Strings.Hook_Miss end
        end
        playSound("HookMiss")
        flashIndicator(Color3.fromRGB(220,90,80))
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

    -- Остановить тряску удочки при выходе из фазы подсечки
    if rodShakeTween then
        rodShakeTween:Cancel()
        rodShakeTween = nil
        if hookGui then hookGui.Rotation = 0 end
    end

    fishInZonePrev = false
    lastRippleTime = 0

    setGuiVisible("HookPhase", false)
    setGuiVisible("CatchPhase", true)

    playSound("Splash")
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
            playSound("Splash")
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
        local scaleFrame    = catchGui:FindFirstChild("ScaleFrame")
        local progressBar   = catchGui:FindFirstChild("ProgressBar")
        local fishIndicator = scaleFrame and scaleFrame:FindFirstChild("FishIndicator")
        local greenZoneFrame= scaleFrame and scaleFrame:FindFirstChild("GreenZone")

        if progressBar then
            local fill = progressBar:FindFirstChild("Fill")
            if fill then
                local pct = math.clamp(catchProgress / GameConfig.Fishing.MaxProgress, 0, 1)
                fill.Size     = UDim2.new(1, 0, pct, 0)
                fill.Position = UDim2.new(0, 0, 1 - pct, 0)
            end
        end

        -- Позиционирование относительно ScaleFrame (400px высота)
        local scaleH = GameConfig.Fishing.ScaleHeight
        if fishIndicator then
            -- fishPos = 0 (низ) .. scaleH (верх); AnchorPoint=(0,0)
            local yScale = 1 - (fishPos + 15) / scaleH  -- +15 = половина высоты индикатора
            fishIndicator.Position = UDim2.new(-1, 0, math.clamp(yScale, 0, 1), 0)
        end
        if greenZoneFrame then
            local halfZone = GameConfig.GreenZone.Height / 2
            local yScale = 1 - (greenZonePos + halfZone) / scaleH
            greenZoneFrame.Position = UDim2.new(0, 0, math.clamp(yScale, 0, 1), 0)
        end

        -- Тонировка индикатора рыбы / заполнения шкалы при входе/выходе из зоны
        if fishInZone ~= fishInZonePrev then
            if zoneTintTween then zoneTintTween:Cancel() end
            local targetColor = fishInZone and Color3.fromRGB(255,210,90) or Color3.fromRGB(230,150,70)
            if fishIndicator then
                zoneTintTween = TweenService:Create(
                    fishIndicator,
                    TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { BackgroundColor3 = targetColor }
                )
                zoneTintTween:Play()
            end

            -- Эффект ряби при входе в зону (троттлинг ~раз в 0.3с)
            if fishInZone and not fishInZonePrev then
                local now = os.clock()
                if now - lastRippleTime >= 0.3 then
                    lastRippleTime = now
                    local effectsLayer = catchGui:FindFirstChild("EffectsLayer")
                    if effectsLayer and fishIndicator then
                        local ripple = Instance.new("Frame")
                        ripple.Name = "Ripple"
                        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
                        ripple.BackgroundColor3 = Color3.fromRGB(160,255,180)
                        ripple.BackgroundTransparency = 0.2
                        ripple.BorderSizePixel = 0
                        ripple.Size = UDim2.fromOffset(20, 20)
                        local fishAbsPos = fishIndicator.AbsolutePosition
                        local fishAbsSize = fishIndicator.AbsoluteSize
                        local layerAbsPos = effectsLayer.AbsolutePosition
                        ripple.Position = UDim2.fromOffset(
                            fishAbsPos.X - layerAbsPos.X + fishAbsSize.X/2,
                            fishAbsPos.Y - layerAbsPos.Y + fishAbsSize.Y/2
                        )
                        local corner = Instance.new("UICorner")
                        corner.CornerRadius = UDim.new(1, 0)
                        corner.Parent = ripple
                        ripple.Parent = effectsLayer

                        local tween = TweenService:Create(
                            ripple,
                            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            { Size = UDim2.fromOffset(80, 80), BackgroundTransparency = 1 }
                        )
                        tween:Play()
                        tween.Completed:Connect(function()
                            ripple:Destroy()
                        end)
                        playSound("Splash")
                    end
                end
            end

            fishInZonePrev = fishInZone
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
        playSound("CatchSuccess")
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
        playSound("CatchFail")
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

        -- Цвет по редкости
        local RARITY_COLORS = {
            Common    = Color3.fromRGB(160,165,175),
            Uncommon  = Color3.fromRGB(120,200,120),
            Rare      = Color3.fromRGB(90,160,230),
            Epic      = Color3.fromRGB(170,110,220),
            Legendary = Color3.fromRGB(255,180,60),
            Mythical  = Color3.fromRGB(255,210,90),
        }
        local rarityColor = RARITY_COLORS[catchEntry.rarity] or Color3.fromRGB(160,165,175)
        if nameLabel then nameLabel.TextColor3 = rarityColor end
        if rarityLabel then rarityLabel.TextColor3 = rarityColor end
        local rarityBanner = resultGui:FindFirstChild("RarityBanner")
        if rarityBanner then rarityBanner.BackgroundColor3 = rarityColor end

        local newBadge = resultGui:FindFirstChild("NewBadge")
        if newBadge then
            newBadge.Visible = catchEntry.isNew == true
        end
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

        -- "Pop" масштаб: появление с 90% до 100%
        local targetSize = resultGui.Size
        local startSize = UDim2.new(
            targetSize.X.Scale * 0.9, targetSize.X.Offset * 0.9,
            targetSize.Y.Scale * 0.9, targetSize.Y.Offset * 0.9
        )
        resultGui.Size = startSize
        TweenService:Create(
            resultGui,
            TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = targetSize }
        ):Play()
    end

    playSound("CatchSuccess")

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

-- ══ F КЛАВИША — НАЧАТЬ РЫБАЛКУ ══
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if isMinigameActive then return end
    if input.KeyCode == Enum.KeyCode.F then
        RequestFishing:FireServer()
    end
end)

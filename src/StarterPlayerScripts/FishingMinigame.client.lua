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
local RodData    = require(ReplicatedStorage.Modules.RodData)

local Player     = Players.LocalPlayer
local PlayerGui  = Player.PlayerGui

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartFishing = Remotes:WaitForChild("StartFishing")
local RequestFishing = Remotes:WaitForChild("RequestFishing")
local HookResultEvent = Remotes:WaitForChild("HookResult")
local CatchResultEvent = Remotes:WaitForChild("CatchResult")
local FishCaughtEvent  = Remotes:WaitForChild("FishCaught")
local FishEscapedEvent = Remotes:WaitForChild("FishEscaped")
local GetRods          = Remotes:WaitForChild("GetRods")
local RodEquippedEvent = Remotes:WaitForChild("RodEquipped")

-- ══ СЛОЖНОСТЬ: ТЕКУЩАЯ УДОЧКА ══
-- Лучшая удочка (greenZoneBonus/catchRateBonus) делает мини-игру легче —
-- удочка влияет на сложность напрямую (см. GameConfig.GetCatchDifficulty)
local equippedRodId = "WoodenRod"
local catchDifficulty = 1  -- пересчитывается в начале каждой Catch Phase

task.spawn(function()
    local ok, rodsData = pcall(function() return GetRods:InvokeServer() end)
    if ok and rodsData and rodsData.equipped then
        equippedRodId = rodsData.equipped
    end
end)
RodEquippedEvent.OnClientEvent:Connect(function(rodId)
    equippedRodId = rodId
end)

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
local pulseTweens      = {}  -- зацикленные "дыхание"-твины зон, очищаются между поклёвками

-- ══ ВАРИАНТЫ CATCH PHASE ══
-- Каждая поклёвка случайно выбирает один из вариантов мини-игры вытягивания —
-- так одна и та же рыба не всегда играется одинаково.
local CATCH_VARIANTS = {
    { id = "Classic",   weight = 55 },  -- держи рыбу в зелёной зоне (текущая механика)
    { id = "Rhythm",    weight = 25 },  -- тапай в такт колеблющемуся индикатору
    { id = "SkillCheck",weight = 20 },  -- Dead by Daylight-style: держи + внезапные проверки
}
local currentVariant = "Classic"

local function pickVariant()
    local total = 0
    for _, v in ipairs(CATCH_VARIANTS) do total = total + v.weight end
    local roll = rng:NextNumber() * total
    local acc = 0
    for _, v in ipairs(CATCH_VARIANTS) do
        acc = acc + v.weight
        if roll <= acc then return v.id end
    end
    return CATCH_VARIANTS[1].id
end

-- Rhythm variant
local tapBarPos    = 0       -- 0..1 позиция индикатора по бару
local tapBarAngle  = 0       -- "градусы" для синусоиды (как Hook Phase)
local tapBarSpeed  = 140

-- SkillCheck (DBD-style) variant
local skillCheckActive  = false
local skillCheckPos     = 0.5   -- 0..1 позиция зоны проверки на баре
local skillCheckProgress= 0     -- 0..1 прогресс прохода индикатора через бар во время проверки
local skillCheckCooldown= 0     -- сек до следующей проверки
local skillCheckResolved= true  -- успели ли тапнуть в этом раунде проверки

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
local updateClassicCatch
local updateRhythmCatch
local updateSkillCheckCatch
local onCatchTap
local finishCatch
local applyCatchResult

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

    -- "Тряска удочки" — лёгкое покачивание только SliderBG (не весь HookPhase)
    if rodShakeTween then
        rodShakeTween:Cancel()
        rodShakeTween = nil
    end
    if hookGui then
        hookGui.Rotation = 0  -- сброс ротации всего фрейма
        local sliderBG = hookGui:FindFirstChild("SliderBG")
        if sliderBG then
            sliderBG.Rotation = -1
            rodShakeTween = TweenService:Create(
                sliderBG,
                TweenInfo.new(0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                { Rotation = 1 }
            )
            rodShakeTween:Play()
        end
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
    -- Старт с середины шкалы, а не с MinProgress — иначе первая же доля секунды
    -- "рыба вне зоны" (пока игрок не успел зажать кнопку) сразу триггерит проигрыш,
    -- потому что catchProgress <= MinProgress было true с самого первого кадра.
    catchProgress  = (GameConfig.Fishing.MaxProgress + GameConfig.Fishing.MinProgress) / 2
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

    -- Сложность зависит от зоны (глубже = резвее рыба) и от текущей удочки
    -- (лучше удочка = легче) — пересчитывается на каждую поклёвку
    local rod = RodData:GetRod(equippedRodId)
    catchDifficulty = GameConfig.GetCatchDifficulty(currentZone, rod)

    -- Случайный вариант мини-игры вытягивания — разнообразие на каждой поклёвке
    currentVariant   = pickVariant()
    tapBarAngle       = 0
    tapBarPos         = 0.5
    skillCheckActive  = false
    skillCheckResolved= true
    skillCheckPos     = 0.5
    skillCheckProgress= 0
    skillCheckCooldown= 1.0 + rng:NextNumber() * 1.2

    -- Сбросить позицию зон тапа в центр — иначе они могут остаться там,
    -- где их оставил предыдущий SkillCheck-раунд, даже если выпал Rhythm
    if catchGui then
        local tapWidget = catchGui:FindFirstChild("TapCheckWidget")
        local tapBar = tapWidget and tapWidget:FindFirstChild("TapBar")
        local greenZone = tapBar and tapBar:FindFirstChild("TapGreenZone")
        local perfectZone = tapBar and tapBar:FindFirstChild("TapPerfectZone")
        if greenZone then greenZone.Position = UDim2.new(0.5,-55,0,0) end
        if perfectZone then perfectZone.Position = UDim2.new(0.5,-23,0,0) end
    end

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

    -- Показать/скрыть виджеты под выбранный вариант
    if catchGui then
        local scaleFrame = catchGui:FindFirstChild("ScaleFrame")
        local tapWidget   = catchGui:FindFirstChild("TapCheckWidget")
        local variantLbl  = catchGui:FindFirstChild("VariantLabel")
        if scaleFrame then scaleFrame.Visible = (currentVariant == "Classic") end
        if tapWidget then
            tapWidget.Visible = (currentVariant == "Rhythm")  -- SkillCheck показывает его сам по событию
            local tapHint = tapWidget:FindFirstChild("TapHint")
            if tapHint then tapHint.Text = "Tap to the rhythm!" end
        end
        if variantLbl then
            if currentVariant == "Classic" then
                variantLbl.Text = "Hold to keep the fish in the green zone!"
            elseif currentVariant == "Rhythm" then
                variantLbl.Text = "🎵 Rhythm — tap when the bar hits the zone!"
            else
                variantLbl.Text = "🔧 Hold to reel — watch for Skill Checks!"
            end
        end
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

    -- "Дыхание" зон — лёгкая зацикленная пульсация прозрачности, чтобы поле
    -- ловли не выглядело статичным даже когда игрок ничего не нажимает
    for _, t in ipairs(pulseTweens) do t:Cancel() end
    pulseTweens = {}
    if catchGui then
        local targets = {}
        local sf2 = catchGui:FindFirstChild("ScaleFrame")
        if sf2 then
            local gz = sf2:FindFirstChild("GreenZone")
            if gz then table.insert(targets, { gz, gz.BackgroundTransparency }) end
        end
        local tcw2 = catchGui:FindFirstChild("TapCheckWidget")
        local tapBar2 = tcw2 and tcw2:FindFirstChild("TapBar")
        local tpz = tapBar2 and tapBar2:FindFirstChild("TapPerfectZone")
        if tpz then table.insert(targets, { tpz, tpz.BackgroundTransparency }) end

        for _, pair in ipairs(targets) do
            local inst, baseTransparency = pair[1], pair[2]
            local tw = TweenService:Create(
                inst,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                { BackgroundTransparency = math.clamp(baseTransparency + 0.25, 0, 1) }
            )
            tw:Play()
            table.insert(pulseTweens, tw)
        end
    end

    playSound("Splash")
end

function updateCatchPhase(dt)
    dt = math.min(dt, 0.05)  -- cap dt to prevent lag spikes freezing green zone
    catchElapsed = catchElapsed + dt

    -- Stress Meter
    if catchElapsed > GameConfig.Fishing.StressStartDelay then
        stressElapsed = stressElapsed + dt
        if stressElapsed >= GameConfig.Fishing.StressInterval then
            stressElapsed = 0
            stressMultiplier = stressMultiplier + GameConfig.Fishing.StressSpeedBonus
        end
    end

    if currentVariant == "Rhythm" then
        updateRhythmCatch(dt)
    elseif currentVariant == "SkillCheck" then
        updateSkillCheckCatch(dt)
    else
        updateClassicCatch(dt)
    end

    -- Обновить общий прогресс-бар + статусные лейблы (общие для всех вариантов)
    if catchGui then
        local progressBar = catchGui:FindFirstChild("ProgressBar")
        if progressBar then
            local fill = progressBar:FindFirstChild("Fill")
            if fill then
                local pct = math.clamp(catchProgress / GameConfig.Fishing.MaxProgress, 0, 1)
                fill.Size     = UDim2.new(1, 0, pct, 0)
                fill.Position = UDim2.new(0, 0, 1 - pct, 0)
            end
        end

        local stressLabel = catchGui:FindFirstChild("StressLabel")
        if stressLabel then
            stressLabel.Visible = stressMultiplier > 1.2
            if stressLabel.Visible then
                stressLabel.Text = Strings.Stress_Warning
            end
        end

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

-- ══ ВАРИАНТ: CLASSIC (держи рыбу в зелёной зоне) ══
function updateClassicCatch(dt)
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

    -- Целевая скорость в направлении (с учётом stress, сложности зоны/удочки и gravityBias)
    local targetVel = fishTargetDir * b.speed * stressMultiplier * catchDifficulty
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

    -- Движение зелёной зоны (удочка с greenZoneBonus делает её шире = легче)
    local rodGreenBonus = (RodData:GetRod(equippedRodId) or {}).greenZoneBonus or 0
    local halfZone = (GameConfig.GreenZone.Height * (1 + rodGreenBonus)) / 2
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
        local fishIndicator = scaleFrame and scaleFrame:FindFirstChild("FishIndicator")
        local greenZoneFrame= scaleFrame and scaleFrame:FindFirstChild("GreenZone")

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
    end
end

-- ══ ОБЩИЙ ВИДЖЕТ TapCheckWidget (Rhythm/SkillCheck) ══
local function getTapWidget()
    if not catchGui then return nil end
    local widget = catchGui:FindFirstChild("TapCheckWidget")
    if not widget then return nil end
    local bar = widget:FindFirstChild("TapBar")
    return widget, bar, bar and bar:FindFirstChild("TapIndicator"),
        bar and bar:FindFirstChild("TapGreenZone"), bar and bar:FindFirstChild("TapPerfectZone")
end

local function flashTapIndicator(color)
    local _, _, indicator = getTapWidget()
    if not indicator then return end
    indicator.BackgroundColor3 = color
    TweenService:Create(
        indicator,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundColor3 = Color3.new(1,1,1) }
    ):Play()
end

-- ══ ВАРИАНТ: RHYTHM (тапай в такт колеблющемуся индикатору) ══
function updateRhythmCatch(dt)
    -- Индикатор непрерывно колеблется по баре, как стрелка в Hook Phase.
    -- Темп растёт вместе со stress-мультипликатором — сложнее со временем.
    tapBarSpeed = GameConfig.Fishing.HookArrowBaseSpeed * stressMultiplier * catchDifficulty
    tapBarAngle = (tapBarAngle + tapBarSpeed * dt) % 360
    tapBarPos = (math.sin(math.rad(tapBarAngle)) + 1) / 2  -- 0..1

    -- Без тапов прогресс медленно утекает — нужно реально тапать в ритм
    catchProgress = math.clamp(
        catchProgress - GameConfig.Fishing.EscapeRate * 0.25 * dt,
        0, GameConfig.Fishing.MaxProgress
    )

    local widget, bar, indicator = getTapWidget()
    if bar and indicator then
        indicator.Position = UDim2.new(tapBarPos, -4, 0, 0)
    end
end

-- ══ ВАРИАНТ: SKILL CHECK (Dead by Daylight-style) ══
function updateSkillCheckCatch(dt)
    -- Базовое вытягивание: держишь — тащишь рыбу, отпустил — она тянет назад
    if isHolding then
        catchProgress = math.clamp(
            catchProgress + GameConfig.Fishing.CatchRate * 0.6 * dt,
            0, GameConfig.Fishing.MaxProgress
        )
    else
        catchProgress = math.clamp(
            catchProgress - GameConfig.Fishing.EscapeRate * 0.5 * dt,
            0, GameConfig.Fishing.MaxProgress
        )
    end

    local widget, bar, indicator, greenZone, perfectZone = getTapWidget()

    if not skillCheckActive then
        skillCheckCooldown = skillCheckCooldown - dt
        if skillCheckCooldown <= 0 then
            -- Запустить новую внезапную проверку
            skillCheckActive   = true
            skillCheckResolved = false
            skillCheckProgress = 0
            skillCheckPos = 0.2 + rng:NextNumber() * 0.6  -- случайная зона на баре
            if widget then widget.Visible = true end
            local tapHint = widget and widget:FindFirstChild("TapHint")
            if tapHint then tapHint.Text = "Check!" end
            if greenZone then greenZone.Position = UDim2.new(skillCheckPos, -55, 0, 0) end
            if perfectZone then perfectZone.Position = UDim2.new(skillCheckPos, -23, 0, 0) end
            playSound("HookHit")
        end
    else
        -- Игла один раз быстро проходит бар слева направо (быстрее = сложнее)
        skillCheckProgress = math.clamp(skillCheckProgress + (dt * catchDifficulty) / 0.7, 0, 1)
        if indicator then indicator.Position = UDim2.new(skillCheckProgress, -4, 0, 0) end

        if skillCheckProgress >= 1 and not skillCheckResolved then
            -- Не успел тапнуть вовремя — провал проверки
            skillCheckResolved = true
            isPerfectCatch = false
            catchProgress = math.clamp(catchProgress - 14, 0, GameConfig.Fishing.MaxProgress)
            flashTapIndicator(Color3.fromRGB(220,90,80))
            playSound("HookMiss")
            stressMultiplier = stressMultiplier + GameConfig.Fishing.StressSpeedBonus
        end

        if skillCheckProgress >= 1 then
            skillCheckActive = false
            skillCheckCooldown = 1.4 + rng:NextNumber() * 1.8
            if widget then widget.Visible = false end
        end
    end
end

-- ══ ВВОД В CATCH PHASE: тап для Rhythm / SkillCheck ══
function onCatchTap()
    if currentPhase ~= "catching" then return end

    if currentVariant == "Rhythm" then
        local diff = math.abs(tapBarPos - 0.5) * 360
        local halfZone = GameConfig.Fishing.HookZoneAngle / 2
        if diff <= GameConfig.Fishing.HookPerfectWindow then
            catchProgress = math.clamp(catchProgress + 18, 0, GameConfig.Fishing.MaxProgress)
            flashTapIndicator(Color3.fromRGB(90,200,110))
            playSound("HookHit")
        elseif diff <= halfZone then
            catchProgress = math.clamp(catchProgress + 10, 0, GameConfig.Fishing.MaxProgress)
            flashTapIndicator(Color3.fromRGB(90,200,110))
            playSound("HookHit")
        else
            catchProgress = math.clamp(catchProgress - 8, 0, GameConfig.Fishing.MaxProgress)
            isPerfectCatch = false
            flashTapIndicator(Color3.fromRGB(220,90,80))
            playSound("HookMiss")
        end

    elseif currentVariant == "SkillCheck" then
        if not skillCheckActive or skillCheckResolved then return end
        skillCheckResolved = true
        local diff = math.abs(skillCheckProgress - skillCheckPos)
        if diff <= 0.04 then
            catchProgress = math.clamp(catchProgress + 25, 0, GameConfig.Fishing.MaxProgress)
            flashTapIndicator(Color3.fromRGB(90,200,110))
            playSound("CatchSuccess")
        elseif diff <= 0.12 then
            catchProgress = math.clamp(catchProgress + 14, 0, GameConfig.Fishing.MaxProgress)
            flashTapIndicator(Color3.fromRGB(90,200,110))
            playSound("HookHit")
        else
            catchProgress = math.clamp(catchProgress - 10, 0, GameConfig.Fishing.MaxProgress)
            isPerfectCatch = false
            flashTapIndicator(Color3.fromRGB(220,90,80))
            playSound("HookMiss")
        end
    end
end

-- ══ ЗАВЕРШЕНИЕ ПОИМКИ ══
finishCatch = function(success)
    currentPhase = "result"

    for _, t in ipairs(pulseTweens) do t:Cancel() end
    pulseTweens = {}

    if success then
        -- CatchPhase скрывается сразу — её сменяет ResultPhase
        setGuiVisible("CatchPhase", false)
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

-- ══ EGG HATCH REVEAL (Pet Simulator-style) — рыба не показывается мгновенно:
-- сначала чёрное "яйцо" трясётся, клики ускоряют трещину, затем оно лопается ══
local hatchActive  = false
local hatchProgress= 0
local hatchRenderConn
local hatchClickConn

local function startHatchReveal(onComplete)
    local hatchOverlay = resultGui and resultGui:FindFirstChild("HatchOverlay")
    if not hatchOverlay then onComplete(); return end

    local eggIcon    = hatchOverlay:FindFirstChild("EggIcon")
    local burstFlash = hatchOverlay:FindFirstChild("BurstFlash")
    local crackBar   = hatchOverlay:FindFirstChild("CrackBar")
    local crackFill  = crackBar and crackBar:FindFirstChild("Fill")
    local hatchHint  = hatchOverlay:FindFirstChild("HatchHint")

    hatchOverlay.Visible = true
    hatchOverlay.BackgroundTransparency = 0
    if eggIcon then
        eggIcon.Rotation = 0; eggIcon.TextTransparency = 0
        eggIcon.Size = UDim2.fromScale(0.7,0.7)
    end
    if burstFlash then burstFlash.BackgroundTransparency = 1; burstFlash.Size = UDim2.fromOffset(20,20) end
    if hatchHint then hatchHint.Visible = true end
    if crackFill then crackFill.Size = UDim2.new(0,0,1,0) end

    hatchActive   = true
    hatchProgress = 0
    local shakeT  = 0

    local function finishHatch()
        hatchActive = false
        if hatchRenderConn then hatchRenderConn:Disconnect(); hatchRenderConn = nil end
        if hatchClickConn  then hatchClickConn:Disconnect();  hatchClickConn  = nil end
        playSound("CatchSuccess")
        if hatchHint then hatchHint.Visible = false end

        -- Вспышка-разлом: белый круг резко расширяется и гаснет в момент раскрытия
        if burstFlash then
            burstFlash.BackgroundTransparency = 0
            TweenService:Create(burstFlash, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Size = UDim2.fromOffset(420,420), BackgroundTransparency = 1 }):Play()
        end
        if eggIcon then
            -- "Лопается" наружу с поворотом, как при разлёте осколков скорлупы
            TweenService:Create(eggIcon, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                { TextTransparency = 1, Size = UDim2.fromScale(1.15,1.15), Rotation = 35 }):Play()
        end
        TweenService:Create(hatchOverlay, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = 1 }):Play()
        task.delay(0.22, function()
            hatchOverlay.Visible = false
            hatchOverlay.BackgroundTransparency = 0
            if eggIcon then eggIcon.TextTransparency = 0; eggIcon.Rotation = 0; eggIcon.Size = UDim2.fromScale(0.7,0.7) end
            onComplete()
        end)
    end

    if hatchRenderConn then hatchRenderConn:Disconnect() end
    hatchRenderConn = RunService.RenderStepped:Connect(function(dt)
        if not hatchActive then return end
        -- Пассивный прирост трещины + "тряска" усиливается по мере прогресса
        hatchProgress = math.min(hatchProgress + dt * 0.12, 1)
        shakeT = shakeT + dt * (8 + hatchProgress * 30)
        if eggIcon then
            -- Резкая тряска влево-вправо (как в референсе с CFrame.Angles), а не плавный синус
            local wobble = (shakeT % 1 < 0.5) and 1 or -1
            eggIcon.Rotation = wobble * (5 + hatchProgress * 18) * math.abs(math.sin(shakeT))
        end
        if crackFill then
            crackFill.Size = UDim2.new(hatchProgress, 0, 1, 0)
        end
        if hatchProgress >= 1 then
            finishHatch()
        end
    end)

    if hatchClickConn then hatchClickConn:Disconnect() end
    hatchClickConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not hatchActive or gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            hatchProgress = math.min(hatchProgress + 0.07, 1)
            playSound("HookHit")
        end
    end)
end

-- ══ ФАЗА 3: РЕЗУЛЬТАТ ══
FishCaughtEvent.OnClientEvent:Connect(function(catchEntry)
    isMinigameActive = false
    currentPhase = "result"

    setGuiVisible("ResultPhase", true)
    startHatchReveal(function()
        applyCatchResult(catchEntry)
    end)
end)

applyCatchResult = function(catchEntry)
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

    -- Закрыть через 3 секунды или по нажатию
    task.delay(3, function()
        if currentPhase == "result" then
            setGuiVisible("ResultPhase", false)
        end
    end)
end

-- ══ ЗАПУСК МИНИ-ИГРЫ ══
local function beginFishing()
    if isMinigameActive then return end
    isMinigameActive = true
    hookArrowSpeed = GameConfig.Fishing.HookArrowBaseSpeed
    startHookPhase()
end

-- Server starts fishing session (via ProximityPrompt or fallback F key)
-- Small delay ensures the E-key press that triggered the prompt is fully consumed
-- before we start listening for hook input (prevents instant auto-hook)
StartFishing.OnClientEvent:Connect(function(data)
    if data and data.zone then currentZone = data.zone end
    task.wait(0.12)   -- let ProximityPrompt E-press finish processing
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
-- Hook phase: click (LMB) or tap to hook — avoids conflict with ProximityPrompt E key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if currentPhase ~= "hook" then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        onHookInput()
    end
end)

-- Catch phase: hold Space or LMB to reel in
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if currentPhase ~= "catching" then return end
    if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isHolding = true
        onCatchTap()
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

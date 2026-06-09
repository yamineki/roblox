-- ServerScriptService/Services/EventService.lua
-- Reef Diver — Случайные серверные события (каждые 10–20 мин)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local EventService = {}

-- Текущее активное событие
local currentEvent = nil
local eventEndTime = 0
local nextEventTime = 0

-- Список событий в порядке
local eventNames = {"MutationSwarm", "GoldenTide", "BloodMoon", "LeviathanMigration"}

local function getRemotes()
    return game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
end

-- ══ ЗАПУСТИТЬ СОБЫТИЕ ══
local function startEvent(eventName)
    local cfg = GameConfig.Events[eventName]
    if not cfg then return end

    currentEvent = eventName
    eventEndTime = os.time() + cfg.durationSecs

    print("[EventService] Начато событие:", eventName, "на", cfg.durationSecs, "сек")

    local Remotes = getRemotes()
    local WorldEventStarted = Remotes:WaitForChild("WorldEventStarted")
    WorldEventStarted:FireAllClients({
        eventName   = eventName,
        durationSecs= cfg.durationSecs,
        endTime     = eventEndTime,
    })
end

-- ══ ЗАВЕРШИТЬ СОБЫТИЕ ══
local function endEvent()
    if not currentEvent then return end

    print("[EventService] Завершено событие:", currentEvent)

    local Remotes = getRemotes()
    local WorldEventEnded = Remotes:WaitForChild("WorldEventEnded")
    WorldEventEnded:FireAllClients({ eventName = currentEvent })

    currentEvent = nil
    eventEndTime = 0

    -- Следующее событие через случайный интервал
    local minInterval = 600  -- 10 мин
    local maxInterval = 1200 -- 20 мин
    nextEventTime = os.time() + math.random(minInterval, maxInterval)
end

-- ══ ПОЛУЧИТЬ АКТИВНОЕ СОБЫТИЕ ══
function EventService:GetActiveEvent()
    return currentEvent
end

-- ══ ПРОВЕРИТЬ МОДИФИКАТОР ДЛЯ РЫБАЛКИ ══
function EventService:GetActiveModifiers()
    if not currentEvent then return {} end
    return GameConfig.Events[currentEvent] or {}
end

-- ══ ЦИКЛ СОБЫТИЙ (раз в секунду, не каждый кадр) ══
task.spawn(function()
    while true do
        task.wait(1)
        local now = os.time()

        if currentEvent and now >= eventEndTime then
            endEvent()
        end

        if not currentEvent and now >= nextEventTime then
            local eventName = eventNames[math.random(#eventNames)]
            startEvent(eventName)
        end
    end
end)

-- Инициализация: первое событие через 5–10 мин после старта сервера
nextEventTime = os.time() + math.random(300, 600)

return EventService

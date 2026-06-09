-- ServerScriptService/Services/AnnouncementService.lua
-- Reef Diver — Серверные объявления о редких уловах

local Players           = game:GetService("Players")
local MessagingService  = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local Strings    = require(ReplicatedStorage.Modules.Strings)

local AnnouncementService = {}

-- Кулдаун объявлений per player (userId → os.time() последнего объявления)
local cooldowns = {}

-- ══ ФОРМАТИРОВАТЬ СООБЩЕНИЕ ══
local function formatMessage(catchEntry, announceType)
    local p = catchEntry.playerName
    local f = catchEntry.displayName
    local m = catchEntry.mutation or ""

    if announceType == "Mythic" then
        return Strings:Format("Announce_Mythic", p, f)
    elseif announceType == "Secret" then
        return Strings:Format("Announce_Secret", p, f)
    elseif announceType == "LeviathanSize" then
        return Strings:Format("Announce_LeviathanSize", p, f)
    elseif announceType == "Prismatic" then
        -- Проверить комбо Prismatic + Leviathan size
        if catchEntry.size == "Leviathan" then
            return Strings:Format("Announce_PrismaticLevi", p)
        end
        return Strings:Format("Announce_Prismatic", p, f)
    end
    return ("🎣 " .. p .. " поймал " .. f .. "!")
end

-- ══ ОТПРАВИТЬ ОБЪЯВЛЕНИЕ ══
function AnnouncementService:Announce(player, catchEntry, announceType)
    local userId = tostring(player.UserId)
    local now = os.time()
    local cfg = GameConfig.Announcements

    -- Проверка кулдауна
    if cooldowns[userId] and (now - cooldowns[userId]) < cfg.PlayerCooldown then
        return
    end
    cooldowns[userId] = now

    local message = formatMessage(catchEntry, announceType)
    local payload = {
        message     = message,
        announceType= announceType,
        fishId      = catchEntry.id,
        fishImage   = catchEntry.image,  -- PLACEHOLDER ""
        rarity      = catchEntry.rarity,
        mutation    = catchEntry.mutation,
        value       = catchEntry.value,
    }

    -- Локально показать сразу (мгновенный отклик для игроков этого сервера)
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local ServerAnnouncementEvent = Remotes:WaitForChild("ServerAnnouncement")
    ServerAnnouncementEvent:FireAllClients(payload)

    -- Кросс-серверное оповещение. Помечаем JobId чтобы подписчик
    -- не показал баннер повторно на сервере-источнике.
    payload.originJobId = game.JobId
    local ok, err = pcall(function()
        MessagingService:PublishAsync("ReefDiverAnnounce", payload)
    end)
    if not ok then
        warn("[AnnouncementService] MessagingService ошибка:", err)
    end
end

return AnnouncementService

-- ReplicatedStorage/Modules/SoundFX.lua
-- Reef Diver — Общий модуль звуковых эффектов UI/геймплея
-- Использование: SoundFX.Play("Click")

local SoundFX = {}

local SoundService = game:GetService("SoundService")
local Debris       = game:GetService("Debris")

local SOUND_IDS = {
    Click        = { id = "rbxassetid://6895079853", volume = 0.4, allowOverlap = true },
    Open         = { id = "rbxassetid://6895079802", volume = 0.5 },
    Close        = { id = "rbxassetid://6895079853", volume = 0.4, pitch = 0.85 },
    CastRod      = { id = "rbxassetid://9118823104", volume = 0.5 },
    Splash       = { id = "rbxassetid://9116367412", volume = 0.5 },
    HookHit      = { id = "rbxassetid://6895079731", volume = 0.5 },
    HookMiss     = { id = "rbxassetid://6895079853", volume = 0.4, pitch = 0.6 },
    CatchSuccess = { id = "rbxassetid://9117832001", volume = 0.6 },
    CatchFail    = { id = "rbxassetid://9118962757", volume = 0.5 },
    ZoneEnter    = { id = "rbxassetid://6895079731", volume = 0.4, pitch = 0.8 },
    Reward       = { id = "rbxassetid://9126240909", volume = 0.6 },
    Purchase     = { id = "rbxassetid://9120386789", volume = 0.6 },
    TypeBlip     = { id = "rbxassetid://6895079853", volume = 0.15, pitch = 1.4, allowOverlap = true },
}

local cache = {}

-- Воспроизвести звук по имени из SOUND_IDS
function SoundFX.Play(name, overrides)
    local def = SOUND_IDS[name]
    if not def then return end

    local snd = cache[name]
    if not snd then
        snd = Instance.new("Sound")
        snd.Name = name
        snd.SoundId = def.id
        snd.Volume = def.volume or 0.5
        snd.PlaybackSpeed = def.pitch or 1
        snd.Parent = SoundService
        cache[name] = snd
    end

    if overrides then
        if overrides.volume then snd.Volume = overrides.volume end
        if overrides.pitch then snd.PlaybackSpeed = overrides.pitch end
    end

    -- Для перекрывающихся звуков (например, печатной машинки) клонируем
    if def.allowOverlap then
        local c = snd:Clone()
        c.Parent = SoundService
        c:Play()
        Debris:AddItem(c, 2)
    else
        snd:Play()
    end
end

return SoundFX

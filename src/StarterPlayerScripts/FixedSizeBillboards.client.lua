-- StarterPlayerScripts/FixedSizeBillboards.client.lua
-- Reef Diver — держит BillboardGui-теги ("FixedSizeBillboard") одного и того же
-- размера на экране независимо от расстояния камеры (без этого Roblox рисует
-- BillboardGui как обычный 3D-объект, который растёт при приближении камеры
-- и съёживается при отдалении — что и выглядело "вырастающим" над NPC).

local CollectionService = game:GetService("CollectionService")
local RunService         = game:GetService("RunService")
local Workspace           = game:GetService("Workspace")

-- Расстояние (в стадах), на котором исходный Size billboard'а был "авторски" задан.
-- На этой дистанции коэффициент масштабирования = 1 (без изменений).
local REFERENCE_DISTANCE = 16

local function getBaseSize(bb)
    local bx = bb:GetAttribute("BaseSizeX")
    local by = bb:GetAttribute("BaseSizeY")
    if not bx or not by then
        bx, by = bb.Size.X.Offset, bb.Size.Y.Offset
        bb:SetAttribute("BaseSizeX", bx)
        bb:SetAttribute("BaseSizeY", by)
    end
    return bx, by
end

RunService.Heartbeat:Connect(function()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local camPos = camera.CFrame.Position

    for _, bb in ipairs(CollectionService:GetTagged("FixedSizeBillboard")) do
        if bb.Enabled then
            local part = bb.Parent
            if part and part:IsA("BasePart") then
                local distance = (camPos - part.Position).Magnitude
                local scale = math.clamp(distance / REFERENCE_DISTANCE, 0.5, 6)
                local bx, by = getBaseSize(bb)
                bb.Size = UDim2.fromOffset(bx * scale, by * scale)
            end
        end
    end
end)

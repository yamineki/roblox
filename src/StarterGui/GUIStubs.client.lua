-- StarterGui/GUIStubs.client.lua
-- Reef Diver — отключает стандартный Roblox Backpack
-- Все GUI создаются через UIBuilder.lua (запускается из Command Bar в Studio)

local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

print("[ReefDiver] GUIStubs ✓")

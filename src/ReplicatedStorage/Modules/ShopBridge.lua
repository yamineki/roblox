-- ReplicatedStorage/Modules/ShopBridge.lua
-- Reef Diver — Маленький мост между NPCDialog и контроллерами магазинов.
-- ShopController.client.lua и MonetizationShop.client.lua присваивают
-- свои функции открытия сюда; NPCDialog.client.lua вызывает их.

local ShopBridge = {}

-- Each panel's client script calls ShopBridge.Register(name, fn) on init
local openers = {}

function ShopBridge.Register(name, fn)
    openers[name] = fn
end

local function open(name)
    if openers[name] then
        openers[name]()
    else
        warn("[ShopBridge] No opener registered for:", name)
    end
end

ShopBridge.OpenRodShop          = function() open("RodShop") end
ShopBridge.OpenMonetizationShop = function() open("MonetizationShop") end
ShopBridge.OpenSellPanel        = function() open("SellPanel") end
ShopBridge.OpenExpedition       = function() open("ExpeditionPanel") end
ShopBridge.OpenRebirth          = function() open("RebirthPanel") end
ShopBridge.OpenFishDex          = function() open("FishDexPanel") end

return ShopBridge

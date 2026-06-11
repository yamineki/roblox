-- ReplicatedStorage/Modules/ShopBridge.lua
-- Reef Diver — Маленький мост между NPCDialog и контроллерами магазинов.
-- ShopController.client.lua и MonetizationShop.client.lua присваивают
-- свои функции открытия сюда; NPCDialog.client.lua вызывает их.

local ShopBridge = {}

ShopBridge.OpenRodShop = function() end
ShopBridge.OpenMonetizationShop = function() end

return ShopBridge

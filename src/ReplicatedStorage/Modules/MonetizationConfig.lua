-- ReplicatedStorage/Modules/MonetizationConfig.lua
-- Reef Diver — Конфиг монетизации (геймпассы + developer products)
--
-- КАК ПОДКЛЮЧИТЬ:
--   1. Создай геймпассы/продукты в Roblox Creator Dashboard (твой опыт → Monetization)
--   2. Скопируй их ID и вставь в поля id ниже (заменив 0)
--   3. Цены (priceRobux) — справочно, реальная цена ставится в Dashboard
--
-- ⚠ Пока id = 0 — покупка не сработает (защита от ошибок).

local MonetizationConfig = {}

-- ══ ГЕЙМПАССЫ (разовая покупка, постоянный эффект) ══
MonetizationConfig.GamePasses = {
    Coins2x = {
        id          = 0,            -- PLACEHOLDER: вставь Gamepass ID
        displayName = "2x Coins",
        description = "Удваивает все монеты навсегда",
        priceRobux  = 199,
        icon        = "",           -- PLACEHOLDER: rbxassetid://
        effect      = { type = "coinMult", value = 2.0 },
    },
    Luck2x = {
        id          = 0,
        displayName = "2x Luck",
        description = "×2 шанс редких рыб навсегда",
        priceRobux  = 249,
        icon        = "",
        effect      = { type = "luckMult", value = 2.0 },
    },
    Mutation2x = {
        id          = 0,
        displayName = "2x Mutation",
        description = "×2 шанс мутаций навсегда",
        priceRobux  = 299,
        icon        = "",
        effect      = { type = "mutationMult", value = 2.0 },
    },
    CatchSpeed2x = {
        id          = 0,
        displayName = "2x Catch Speed",
        description = "Рыба ловится в 2 раза быстрее",
        priceRobux  = 149,
        icon        = "",
        effect      = { type = "catchSpeedMult", value = 2.0 },
    },
    AutoSell = {
        id          = 0,
        displayName = "Auto-Sell",
        description = "Авто-продажа пойманной рыбы (с тоглом)",
        priceRobux  = 199,
        icon        = "",
        effect      = { type = "autoSell" },
    },
    ExtraAFKSlots = {
        id          = 0,
        displayName = "+2 AFK слота",
        description = "Две дополнительные AFK-экспедиции",
        priceRobux  = 249,
        icon        = "",
        effect      = { type = "extraAFKSlots", value = 2 },
    },
    ExtraInventory = {
        id          = 0,
        displayName = "Extra Inventory",
        description = "+100 слотов под рыбу",
        priceRobux  = 149,
        icon        = "",
        effect      = { type = "extraInventory", value = 100 },
    },
    FastRebirth = {
        id          = 0,
        displayName = "Fast Rebirth",
        description = "Снижает требования перерождения на 30%",
        priceRobux  = 299,
        icon        = "",
        effect      = { type = "fastRebirth", value = 0.30 },
    },
    StarterRodPack = {
        id          = 0,
        displayName = "Starter Rod Pack",
        description = "Мощная удочка сразу на старте",
        priceRobux  = 79,
        icon        = "",
        effect      = { type = "grantRod", value = "HunterRod" },
    },
    ExclusiveMutations = {
        id          = 0,
        displayName = "Exclusive Mutations",
        description = "Доступ к эксклюзивным косметическим мутациям",
        priceRobux  = 349,
        icon        = "",
        effect      = { type = "exclusiveMutations" },
    },
    VIP = {
        id          = 0,
        displayName = "VIP",
        description = "Чат-тег, цвет ника, ежедневный VIP-бонус",
        priceRobux  = 499,
        icon        = "",
        effect      = { type = "vip" },
        vipChatColor = Color3.fromRGB(255, 215, 0),
        vipDailyCoins = 1000,
    },
}

-- Порядок отображения в магазине
MonetizationConfig.GamePassOrder = {
    "Coins2x", "Luck2x", "Mutation2x", "CatchSpeed2x",
    "AutoSell", "ExtraAFKSlots", "ExtraInventory", "FastRebirth",
    "StarterRodPack", "ExclusiveMutations", "VIP",
}

-- ══ DEVELOPER PRODUCTS (повторяемые покупки) ══
MonetizationConfig.Products = {
    -- Пакеты монет
    Coins1k = {
        id          = 0,            -- PLACEHOLDER: Developer Product ID
        displayName = "1,000 Coins",
        priceRobux  = 25,
        icon        = "",
        effect      = { type = "grantCoins", value = 1000 },
    },
    Coins10k = {
        id          = 0,
        displayName = "10,000 Coins",
        priceRobux  = 99,
        icon        = "",
        effect      = { type = "grantCoins", value = 10000 },
    },
    Coins100k = {
        id          = 0,
        displayName = "100,000 Coins",
        priceRobux  = 499,
        icon        = "",
        effect      = { type = "grantCoins", value = 100000 },
    },
    Coins1m = {
        id          = 0,
        displayName = "1,000,000 Coins",
        priceRobux  = 1999,
        icon        = "",
        effect      = { type = "grantCoins", value = 1000000 },
    },

    -- Временные бусты
    LuckBoost30 = {
        id          = 0,
        displayName = "Luck Boost 30 мин",
        priceRobux  = 49,
        icon        = "",
        effect      = { type = "tempBoost", boost = "LuckBoost", mult = 2.0, duration = 1800 },
    },
    MutationBoost30 = {
        id          = 0,
        displayName = "Mutation Boost 30 мин",
        priceRobux  = 59,
        icon        = "",
        effect      = { type = "tempBoost", boost = "MutationBoost", mult = 2.0, duration = 1800 },
    },

    -- Утилиты
    InstantExpedition = {
        id          = 0,
        displayName = "Instant Expedition",
        priceRobux  = 39,
        icon        = "",
        effect      = { type = "instantExpedition" },
    },
    RebirthToken = {
        id          = 0,
        displayName = "Rebirth Token",
        priceRobux  = 99,
        icon        = "",
        effect      = { type = "rebirthToken" },
    },
}

MonetizationConfig.ProductOrder = {
    "Coins1k", "Coins10k", "Coins100k", "Coins1m",
    "LuckBoost30", "MutationBoost30",
    "InstantExpedition", "RebirthToken",
}

-- ══ ВСПОМОГАТЕЛЬНЫЕ ══
-- Найти геймпасс по Roblox ID (для ProcessReceipt/PromptPurchaseFinished)
function MonetizationConfig:GetGamePassById(robloxId)
    for key, gp in pairs(self.GamePasses) do
        if gp.id == robloxId and robloxId ~= 0 then
            return key, gp
        end
    end
    return nil
end

function MonetizationConfig:GetProductById(robloxId)
    for key, prod in pairs(self.Products) do
        if prod.id == robloxId and robloxId ~= 0 then
            return key, prod
        end
    end
    return nil
end

return MonetizationConfig

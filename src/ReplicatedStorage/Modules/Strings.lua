-- ReplicatedStorage/Modules/Strings.lua
-- Reef Diver — Все строки интерфейса (для локализации)
-- Заменяй значения здесь для перевода на другие языки

local Strings = {}

-- ══ ОБЩЕЕ ══
Strings.GameTitle   = "REEF DIVER"
Strings.Loading     = "Загрузка..."
Strings.LoadingHint = "Нырни глубже…"
Strings.Close       = "Закрыть"
Strings.Buy         = "Купить"
Strings.Sell        = "Продать"
Strings.SellAll     = "Продать всё"
Strings.Equipped    = "Надето"
Strings.Locked      = "Заблокировано"
Strings.Confirm     = "Подтвердить"
Strings.Cancel      = "Отмена"
Strings.Back        = "Назад"

-- ══ HUD ══
Strings.HUD_Coins       = "Монеты"
Strings.HUD_Zone        = "Зона"
Strings.HUD_Depth       = "Глубина"
Strings.HUD_Rod         = "Удочка"
Strings.HUD_Inventory   = "Инвентарь"

-- ══ МИНИ-ИГРА ══
Strings.Hook_Press      = "Нажми [E] для подсечки!"
Strings.Hook_Perfect    = "PERFECT HOOK!"
Strings.Hook_Good       = "Good Hook"
Strings.Hook_Miss       = "ПРОМАХ!"
Strings.Catching_Hold   = "Удерживай для ловли"
Strings.Catching_Perfect= "PERFECT CATCH!"
Strings.Catching_Escaped= "Рыба сбежала..."
Strings.Stress_Warning  = "⚠ Рыба злится!"

-- ══ РЕЗУЛЬТАТ ПОИМКИ ══
Strings.Catch_Result    = "ПОЙМАНО!"
Strings.Catch_Rarity    = "Редкость"
Strings.Catch_Size      = "Размер"
Strings.Catch_Mutation  = "Мутация"
Strings.Catch_Value     = "Стоимость"
Strings.Catch_PerfectBonus = "+25% Perfect Catch!"
Strings.Catch_HookBonus    = "+10% Perfect Hook!"

-- ══ NPC ══
Strings.NPC_RodMaster       = "Rod Master"
Strings.NPC_FishMerchant    = "Fish Merchant"
Strings.NPC_ElderDiver      = "Elder Diver"
Strings.NPC_ResearchSub     = "Research Submarine"
Strings.NPC_Collector       = "Collector"

-- Диалоги NPC (PLACEHOLDER — заменить на финальные тексты)
Strings.Dialog_RodMaster    = "Привет, ныряльщик! Хочешь удочку получше?"
Strings.Dialog_FishMerchant = "Покажи улов! Куплю всё по честной цене."
Strings.Dialog_ElderDiver   = "Ты готов пройти Перерождение? Это изменит тебя навсегда."
Strings.Dialog_ResearchSub  = "Отправляю экспедицию в бездну. Вернусь с добычей."
Strings.Dialog_Collector    = "FishDex — вся история твоих уловов."

-- ══ МАГАЗИН ══
Strings.Shop_RodShop        = "Магазин удочек"
Strings.Shop_NotEnoughCoins = "Недостаточно монет!"
Strings.Shop_BuySuccess     = "Куплено!"

-- ══ FISHДEX ══
Strings.FishDex_Title       = "FishDex"
Strings.FishDex_Tab_Fish    = "Рыбы"
Strings.FishDex_Tab_Mutations= "Мутации"
Strings.FishDex_Tab_Rods    = "Удочки"
Strings.FishDex_Tab_Events  = "События"
Strings.FishDex_Unknown     = "???"
Strings.FishDex_NotCaught   = "Ещё не поймано"

-- ══ ЗОНЫ ══
Strings.Zone_SunnyReef      = "Sunny Reef"
Strings.Zone_CoralTrench    = "Coral Trench"
Strings.Zone_OpenOcean      = "Open Ocean"
Strings.Zone_DarkWaters     = "Dark Waters"
Strings.Zone_Abyss          = "Abyss"
Strings.Zone_Locked         = "Заблокировано"
Strings.Zone_DepthLabel     = "%d – %d м"

-- ══ РЕДКОСТЬ ══
Strings.Rarity_Common       = "Common"
Strings.Rarity_Uncommon     = "Uncommon"
Strings.Rarity_Rare         = "Rare"
Strings.Rarity_Epic         = "Epic"
Strings.Rarity_Legendary    = "Legendary"
Strings.Rarity_Mythic       = "Mythic"
Strings.Rarity_Secret       = "Secret"

-- ══ РАЗМЕРЫ ══
Strings.Size_Tiny            = "Tiny"
Strings.Size_Small           = "Small"
Strings.Size_Normal          = "Normal"
Strings.Size_Large           = "Large"
Strings.Size_Huge            = "Huge"
Strings.Size_Giant           = "Giant"
Strings.Size_Titanic         = "Titanic"
Strings.Size_Colossal        = "Colossal"
Strings.Size_Leviathan       = "Leviathan"

-- ══ МУТАЦИИ ══
Strings.Mutation_Golden         = "Golden"
Strings.Mutation_Frozen         = "Frozen"
Strings.Mutation_Crystal        = "Crystal"
Strings.Mutation_Shadow         = "Shadow"
Strings.Mutation_Toxic          = "Toxic"
Strings.Mutation_Infernal       = "Infernal"
Strings.Mutation_Lunar          = "Lunar"
Strings.Mutation_Solar          = "Solar"
Strings.Mutation_Cosmic         = "Cosmic"
Strings.Mutation_Prismatic      = "Prismatic"
Strings.Mutation_Ancient        = "Ancient"
Strings.Mutation_Primordial     = "Primordial"
Strings.Mutation_LeviathanTouched = "Leviathan-Touched"
Strings.Mutation_None           = "Нет мутации"

-- ══ СОБЫТИЯ ══
Strings.Event_MutationSwarm     = "🌀 Mutation Swarm!"
Strings.Event_GoldenTide        = "🌊 Golden Tide!"
Strings.Event_BloodMoon         = "🌕 Blood Moon!"
Strings.Event_LeviathanMigration= "🐋 Leviathan Migration!"
Strings.Event_Ends              = "Заканчивается через: %ds"

-- ══ СЕРВЕРНЫЕ ОБЪЯВЛЕНИЯ ══
Strings.Announce_Mythic         = "🔥 %s caught a MYTHIC %s!"
Strings.Announce_Secret         = "🌟 %s found a SECRET %s! First on server?"
Strings.Announce_Prismatic      = "🌈 %s caught a PRISMATIC %s! Insane luck!"
Strings.Announce_LeviathanSize  = "🐋 %s caught a LEVIATHAN-sized %s!"
Strings.Announce_PrismaticLevi  = "🔥🌈 %s caught a PRISMATIC LEVIATHAN! LEGENDARY CATCH!"

-- ══ AFK ЭКСПЕДИЦИИ ══
Strings.AFK_Title       = "Research Submarine"
Strings.AFK_Short       = "1 час"
Strings.AFK_Medium      = "4 часа"
Strings.AFK_Long        = "8 часов"
Strings.AFK_Send        = "Отправить"
Strings.AFK_InProgress  = "В экспедиции..."
Strings.AFK_Return      = "Вернуть!"
Strings.AFK_TimeLeft    = "Осталось: %s"

-- ══ REBIRTH ══
Strings.Rebirth_Title   = "Перерождение"
Strings.Rebirth_Confirm = "Ты потеряешь все монеты и рыбу, но получишь постоянный бонус. Подтвердить?"
Strings.Rebirth_Done    = "Перерождение %d завершено!"
Strings.Rebirth_Max     = "Максимальный уровень Rebirth достигнут!"

-- ══ DAILY REWARDS ══
Strings.Daily_Title     = "Ежедневные награды"
Strings.Daily_Day       = "День %d"
Strings.Daily_Claimed   = "Получено"
Strings.Daily_Available = "Получить!"
Strings.Daily_Locked    = "Заблокировано"
Strings.Daily_NextIn    = "Следующая награда через: %s"

-- Вспомогательная функция форматирования
function Strings:Format(key, ...)
    local template = self[key]
    if template then
        return string.format(template, ...)
    end
    return key
end

return Strings

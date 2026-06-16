-- UIBuilder.lua
-- ReefDiver — Генератор всех GUI (стиль Fisch: квадратные тёмные панели)
--
-- КАК ИСПОЛЬЗОВАТЬ:
--   1. Открой Roblox Studio
--   2. View → Command Bar (или Ctrl+Shift+X)
--   3. Вставь содержимое этого файла и нажми Enter
--   4. Все ScreenGui появятся в StarterGui → редактируй там
--   5. ImageLabel с пометкой [REPLACE IMAGE] — загружай свои картинки через кнопку Image
--
-- Если запустить повторно — старые GUI удаляются и создаются заново.

local StarterGui = game:GetService("StarterGui")

-- ══════════════════════════════════════════════════════════════
--  ПАЛИТРА (Fisch-стиль)
-- ══════════════════════════════════════════════════════════════
local C = {
	PanelBG    = Color3.fromRGB(38, 40, 46),   -- основной фон панелей
	PanelDark  = Color3.fromRGB(32, 32, 38),   -- тёмный фон (HUD-плитки, слоты)
	TitleBar   = Color3.fromRGB(30, 31, 36),   -- полоса заголовка
	Stroke     = Color3.fromRGB(70, 75, 85),   -- тонкая обводка
	Text       = Color3.fromRGB(235, 235, 235),-- основной текст
	TextDim    = Color3.fromRGB(160, 165, 175),-- вторичный текст
	Btn        = Color3.fromRGB(50, 52, 60),   -- обычная кнопка
	BtnGreen   = Color3.fromRGB(70, 160, 90),  -- купить / подтвердить
	BtnRed     = Color3.fromRGB(170, 60, 60),  -- закрыть / опасное
	Gold       = Color3.fromRGB(255, 210, 90), -- монеты
	Green      = Color3.fromRGB(90, 200, 110), -- успех / зелёная зона
	Red        = Color3.fromRGB(220, 90, 80),  -- ошибка / стресс
}
local RADIUS = 4

-- ══════════════════════════════════════════════════════════════
--  ХЕЛПЕРЫ
-- ══════════════════════════════════════════════════════════════
local function corner(o, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or RADIUS); c.Parent = o; return c
end
local function stroke(o, col, t, tr)
	local s = Instance.new("UIStroke"); s.Color = col or C.Stroke; s.Thickness = t or 1
	s.Transparency = tr or 0; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o; return s
end
local function lbl(name, parent, text, size, pos, color, bold, textSize)
	local l = Instance.new("TextLabel"); l.Name = name; l.Text = text or ""
	l.Size = size; l.Position = pos or UDim2.new(0,0,0,0); l.BackgroundTransparency = 1
	l.TextColor3 = color or C.Text; l.TextScaled = (textSize == nil)
	l.TextSize = textSize or 14; l.TextWrapped = true
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.Parent = parent; return l
end
local function btn(name, parent, text, size, pos, bg, textColor, textSize)
	local b = Instance.new("TextButton"); b.Name = name; b.Text = text or ""
	b.Size = size; b.Position = pos or UDim2.new(0,0,0,0)
	b.BackgroundColor3 = bg or C.Btn
	b.TextColor3 = textColor or C.Text; b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold; b.TextSize = textSize or 14
	b.Parent = parent; return b
end
local function img(name, parent, size, pos)
	local i = Instance.new("ImageLabel"); i.Name = name; i.Image = ""
	i.Size = size; i.Position = pos or UDim2.new(0,0,0,0)
	i.BackgroundTransparency = 1; i.ScaleType = Enum.ScaleType.Fit
	i.Parent = parent; return i
end
local function scrGui(name, order)
	local existing = StarterGui:FindFirstChild(name)
	if existing then existing:Destroy() end
	local g = Instance.new("ScreenGui"); g.Name = name
	g.DisplayOrder = order or 120; g.ResetOnSpawn = false
	g.IgnoreGuiInset = true; g.Parent = StarterGui; return g
end
local function frame(name, parent, size, pos, bg, transp, r)
	local f = Instance.new("Frame"); f.Name = name
	f.Size = size; f.Position = pos or UDim2.new(0,0,0,0)
	f.BackgroundColor3 = bg or C.PanelBG
	f.BackgroundTransparency = transp or 0; f.BorderSizePixel = 0
	f.Parent = parent; if r then corner(f, r) end; return f
end
-- Заголовочная полоса в стиле Fisch (новый child "TitleBar", имена существующих не трогаем)
local function titleBar(parent, height)
	local tb = frame("TitleBar", parent, UDim2.new(1,0,0,height or 40), UDim2.new(0,0,0,0), C.TitleBar, 0, RADIUS)
	-- закрыть нижние скругления полосы
	local fix = frame("BottomFix", tb, UDim2.new(1,0,0,RADIUS), UDim2.new(0,0,1,-RADIUS), C.TitleBar, 0)
	fix.ZIndex = tb.ZIndex
	return tb
end

-- ══════════════════════════════════════════════════════════════
--  1. MAIN HUD
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("MainHUD", 120)

	local bl = frame("BottomLeft", g, UDim2.fromOffset(200,50), UDim2.new(0,10,1,-60), C.PanelDark, 0.05, RADIUS)
	stroke(bl)
	lbl("CoinsLabel", bl, "🪙 0", UDim2.fromScale(1,1), UDim2.new(0,0,0,0), C.Gold, true)

	-- HUD-кнопки: квадратные тёмные плитки
	local dailyBtn = btn("DailyBtn", g, "🗓", UDim2.fromOffset(44,44), UDim2.new(1,-58,0,10), C.PanelDark)
	dailyBtn.TextScaled = true
	corner(dailyBtn, RADIUS); stroke(dailyBtn)
	local dot = frame("NotifDot", dailyBtn, UDim2.fromOffset(12,12), UDim2.new(1,-3,0,-3), Color3.fromRGB(220,70,60), 0, 6)
	dot.AnchorPoint = Vector2.new(0,0); dot.Visible = false

	local monBtn = btn("MonetizationBtn", g, "💎", UDim2.fromOffset(44,44), UDim2.new(1,-110,0,10), C.PanelDark)
	monBtn.TextScaled = true; corner(monBtn, RADIUS); stroke(monBtn)
end

-- ══════════════════════════════════════════════════════════════
--  2. FISHING GUI
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("FishingGui", 130)

	-- Hook Phase — горизонтальный слайдер
	local hp = frame("HookPhase", g, UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0), 0.5)
	hp.Visible = false
	-- Фоновый бар слайдера
	local sliderBG = frame("SliderBG", hp, UDim2.fromOffset(520,58), UDim2.new(0.5,-260,0.5,-29), C.PanelDark, 0, RADIUS)
	stroke(sliderBG)
	-- Зелёная зона (центр бара, ширина = HookZoneAngle/360 * 500 ≈ 104px)
	frame("GreenZone", sliderBG, UDim2.fromOffset(104,58), UDim2.new(0.5,-52,0,0), C.Green, 0.35, RADIUS)
	-- Perfect зона (центр, уже; ширина = HookPerfectWindow*2/360 * 500 ≈ 42px)
	frame("PerfectZone", sliderBG, UDim2.fromOffset(42,58), UDim2.new(0.5,-21,0,0), Color3.fromRGB(120,230,140), 0.1, RADIUS)
	-- Индикатор (прыгает по бару)
	local si = frame("SliderIndicator", sliderBG, UDim2.fromOffset(30,58), UDim2.new(0.5,-15,0,0), C.Text, 0, RADIUS)
	stroke(si, Color3.fromRGB(20,20,24), 1, 0)
	-- Дополнительный пульсирующий блеск вокруг индикатора
	local glowStroke = stroke(si, C.Green, 3, 0.5)
	glowStroke.Name = "GlowStroke"
	-- Разделитель в центре
	frame("CenterLine", sliderBG, UDim2.fromOffset(2,58), UDim2.new(0.5,-1,0,0), Color3.fromRGB(255,255,255), 0.6)
	lbl("HintLabel", hp, "Click when the cursor is in the green zone!", UDim2.fromOffset(480,36), UDim2.new(0.5,-240,0.5,46), C.Text, true)
	local zoneLabel = lbl("ZoneLabel", hp, "🎣  CAST!", UDim2.fromOffset(340,54), UDim2.new(0.5,-170,0.5,-110), C.Text, true)
	zoneLabel.TextStrokeTransparency = 0.5

	-- Catch Phase
	local cp = frame("CatchPhase", g, UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0), 0.5)
	cp.Visible = false
	local sf = frame("ScaleFrame", cp, UDim2.fromOffset(60,400), UDim2.new(0.5,-30,0.5,-200), C.PanelDark, 0, RADIUS)
	stroke(sf)
	-- "Водяной" фон позади шкалы — две полупрозрачные подложки для глубины
	local waterBack = frame("WaterBack", sf, UDim2.new(1,4,1,4), UDim2.new(0,-2,0,-2), Color3.fromRGB(40,90,120), 0.75, RADIUS)
	waterBack.ZIndex = 0
	local waterMid = frame("WaterMid", sf, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(50,110,150), 0.85, RADIUS)
	waterMid.ZIndex = 0
	frame("GreenZone", sf, UDim2.new(1,0,0,80), UDim2.new(0,0,0.5,-40), C.Green, 0.3, RADIUS)
	local fi = img("FishIndicator", sf, UDim2.fromOffset(50,30), UDim2.new(-1,0,0.5,-15))
	fi.BackgroundColor3 = Color3.fromRGB(230,150,70); fi.BackgroundTransparency = 0; corner(fi, RADIUS)
	local pb = frame("ProgressBar", cp, UDim2.fromOffset(20,400), UDim2.new(0.5,35,0.5,-200), C.PanelDark, 0, RADIUS)
	stroke(pb)
	local fill = frame("Fill", pb, UDim2.new(1,0,0,0), UDim2.new(0,0,1,0), C.Green, 0)
	local fillGrad = Instance.new("UIGradient")
	fillGrad.Color = ColorSequence.new(C.Green, Color3.fromRGB(160,255,180))
	fillGrad.Rotation = 90
	fillGrad.Parent = fill
	local sl = lbl("StressLabel", cp, "⚠ Fish is angry!", UDim2.fromOffset(300,40), UDim2.new(0.5,-150,0.15,0), C.Red, true)
	sl.Visible = false
	local pl = lbl("PerfectLabel", cp, "PERFECT CATCH!", UDim2.fromOffset(300,40), UDim2.new(0.5,-150,0.08,0), Color3.fromRGB(120,230,140), true)
	pl.Visible = false
	lbl("BehaviorLabel", cp, "Lazy", UDim2.fromOffset(200,30), UDim2.new(0.5,-100,0.22,0), C.TextDim, false)
	local el = lbl("EscapeLabel", cp, "Fish got away...", UDim2.fromOffset(400,50), UDim2.new(0.5,-200,0.45,0), C.Red, true)
	el.Visible = false

	-- Слой эффектов (рябь/частицы), на весь экран, поверх остального
	local effectsLayer = frame("EffectsLayer", cp, UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0), 1)
	effectsLayer.ClipsDescendants = false
	effectsLayer.ZIndex = 50

	-- Result Phase
	local rp = frame("ResultPhase", g, UDim2.fromOffset(400,550), UDim2.new(0.5,-200,0.5,-275), C.PanelBG, 0.1, 6)
	rp.Visible = false
	stroke(rp)
	-- Цветная полоса-баннер сверху (тонируется клиентом по редкости рыбы)
	local rarityBanner = frame("RarityBanner", rp, UDim2.new(1,0,0,8), UDim2.new(0,0,0,0), C.TextDim, 0, RADIUS)
	rarityBanner.Name = "RarityBanner"
	local fi2 = img("FishImage", rp, UDim2.new(0.8,0,0.38,0), UDim2.new(0.1,0,0.04,0))
	fi2.BackgroundColor3 = C.PanelDark; fi2.BackgroundTransparency = 0.2; corner(fi2, RADIUS)
	local nb = lbl("NewBadge", rp, "✨ NEW!", UDim2.fromOffset(90,30), UDim2.new(1,-100,0,12), Color3.fromRGB(255,210,90), true)
	nb.Visible = false; nb.TextStrokeTransparency = 0.4; nb.ZIndex = 5
	lbl("FishName",    rp, "???",          UDim2.new(1,0,0.10,0), UDim2.new(0,0,0.44,0), C.Text, true, 26)
	lbl("FishRarity",  rp, "Common",       UDim2.new(0.5,0,0.07,0), UDim2.new(0.1,0,0.52,0), C.TextDim, false)
	lbl("FishSize",    rp, "Normal",       UDim2.new(0.5,0,0.07,0), UDim2.new(0.5,0,0.52,0), C.TextDim, false)
	local fm = lbl("FishMutation", rp, "", UDim2.new(1,0,0.07,0), UDim2.new(0,0,0.60,0), Color3.fromRGB(200,140,230), false)
	fm.Visible = false
	lbl("FishValue",   rp, "0 🪙",         UDim2.new(1,0,0.08,0), UDim2.new(0,0,0.68,0), C.Gold, true)
	local pb2 = lbl("PerfectBonus", rp, "+25% Perfect!", UDim2.new(1,0,0.06,0), UDim2.new(0,0,0.77,0), Color3.fromRGB(120,230,140), false)
	pb2.Visible = false
end

-- ══════════════════════════════════════════════════════════════
--  3. EVENT BANNER
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("EventBanner", 126)
	local banner = frame("Banner", g, UDim2.fromOffset(500,60), UDim2.new(0.5,-250,-0.15,0), C.PanelBG, 0.05, RADIUS)
	banner.Visible = false
	stroke(banner)
	local en = lbl("EventName", banner, "🌀 Event", UDim2.new(0.6,-15,1,0), UDim2.new(0,15,0,0), C.Text, true)
	en.TextXAlignment = Enum.TextXAlignment.Left
	local et = lbl("EventTimer", banner, "...", UDim2.new(0.38,-15,1,0), UDim2.new(0.6,0,0,0), C.TextDim, false)
	et.TextXAlignment = Enum.TextXAlignment.Right
end

-- ══════════════════════════════════════════════════════════════
--  4. ANNOUNCE BANNER
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("AnnounceBanner", 126)
	local banner = frame("Banner", g, UDim2.fromOffset(700,80), UDim2.new(0.5,-350,0,10), C.PanelBG, 0.05, RADIUS)
	banner.Visible = false
	stroke(banner)
	local fi = img("FishImage", banner, UDim2.fromOffset(70,70), UDim2.fromOffset(5,5))
	fi.BackgroundTransparency = 1
	local ml = lbl("MessageLabel", banner, "", UDim2.new(0.85,0,1,0), UDim2.new(0,85,0,0), C.Text, true)
	ml.TextXAlignment = Enum.TextXAlignment.Left
end

-- ══════════════════════════════════════════════════════════════
--  5. COMBO DISPLAY
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("ComboDisplay", 131)
	local cl = lbl("ComboLabel", g, "", UDim2.fromOffset(400,40), UDim2.new(0.5,-200,0.28,0), Color3.fromRGB(255,180,60), true, 22)
	cl.TextScaled = false; cl.Visible = false; cl.TextStrokeTransparency = 0.4
end

-- ══════════════════════════════════════════════════════════════
--  6. SHOP GUI (магазин удочек)
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("ShopGui", 128); g.Enabled = false
	local panel = frame("ShopPanel", g, UDim2.fromOffset(700,600), UDim2.new(0.5,0,1.5,0), C.PanelBG, 0, 6)
	panel.AnchorPoint = Vector2.new(0.5,0.5)
	stroke(panel)
	titleBar(panel, 44)
	lbl("Title", panel, "🎣 Rod Shop", UDim2.new(0.7,0,0,44), UDim2.new(0,0,0,0), C.Text, true, 18)
	local coinsLbl = lbl("ShopCoinsLabel", panel, "🪙 ---", UDim2.new(0.28,0,0,44), UDim2.new(0.72,0,0,0), C.Gold, true, 16)
	coinsLbl.TextXAlignment = Enum.TextXAlignment.Right
	local grid = Instance.new("ScrollingFrame"); grid.Name = "RodGrid"
	grid.Size = UDim2.new(0.95,0,1,-110); grid.Position = UDim2.new(0.025,0,0,54)
	grid.BackgroundTransparency = 1; grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 4; grid.ScrollBarImageColor3 = C.Stroke
	grid.CanvasSize = UDim2.new(0,0,0,0); grid.Parent = panel
	local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.new(0.48,0,0,120)
	gl.CellPadding = UDim2.new(0.02,0,0,12); gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Parent = grid
	local cb = btn("CloseButton", panel, "✕ Close", UDim2.new(0.3,0,0,40), UDim2.new(0.35,0,1,-48), C.Btn, C.Text, 15)
	corner(cb, RADIUS); stroke(cb)
end

-- ══════════════════════════════════════════════════════════════
--  7. DAILY REWARD GUI
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("DailyRewardGui", 150); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.45; dim.AutoButtonColor = false

	local panel = frame("Panel", g, UDim2.fromOffset(760,440), UDim2.new(0.5,0,0.5,0), C.PanelBG, 0, 6)
	panel.AnchorPoint = Vector2.new(0.5,0.5)
	stroke(panel)

	-- Header (имя сохранено для совместимости) — плоская заголовочная полоса
	frame("Header", panel, UDim2.new(1,0,0,44), UDim2.new(0,0,0,0), C.TitleBar, 0, 6)
	frame("HeaderFill", panel:FindFirstChild("Header"), UDim2.new(1,0,0.5,0), UDim2.new(0,0,0.5,0), C.TitleBar, 0)

	lbl("Title", panel, "🗓  DAILY REWARDS", UDim2.new(1,-80,0,44), UDim2.new(0,0,0,0), C.Text, true, 18)
	local closeBtn = btn("CloseBtn", panel, "✕", UDim2.fromOffset(32,32), UDim2.new(1,-40,0,6), C.Btn, C.Text, 16)
	corner(closeBtn, RADIUS); stroke(closeBtn)
	local sl = lbl("StreakLabel", panel, "Streak: 0 days", UDim2.new(1,-20,0,28), UDim2.new(0,10,0,50), C.Gold, false, 15)
	sl.TextXAlignment = Enum.TextXAlignment.Left
	local tl = lbl("TimerLabel", panel, "", UDim2.new(0.5,0,0,28), UDim2.new(0.5,0,0,50), C.TextDim, false, 14)
	tl.AnchorPoint = Vector2.new(0.5,0); tl.TextXAlignment = Enum.TextXAlignment.Center

	-- 7 карточек дней
	local TINTS = {
		Color3.fromRGB(255,210,90), Color3.fromRGB(90,200,110), Color3.fromRGB(200,140,230),
		Color3.fromRGB(110,180,230), Color3.fromRGB(170,110,220), Color3.fromRGB(110,150,220), Color3.fromRGB(255,180,60)
	}
	local EMOJIS = {"🪙","🍀","✨","⏱","📦","🐠","🌟"}
	local TITLES = {
		"🪙 500 coins", "🍀 Luck ×1.5\n30 min", "✨ Mutations ×2\n30 min",
		"⏱ AFK ticket ×1","📦 Chest ×3","🐠 Rare+ chest","🌟 Special mutation"
	}
	local CARD_W, CARD_H, CARD_GAP = 90, 250, 10
	local startX = (760 - 7*CARD_W - 6*CARD_GAP) / 2

	for day = 1, 7 do
		local x = startX + (day-1)*(CARD_W+CARD_GAP)
		local card = frame("Day"..day, panel, UDim2.fromOffset(CARD_W,CARD_H), UDim2.fromOffset(x,100), C.PanelDark, 0.1, RADIUS)

		local cs = stroke(card, C.Stroke, 1, 0); cs.Name = "CardStroke"
		local gs = stroke(card, Color3.fromRGB(235,235,235), 2, 1); gs.Name = "GlowStroke"

		lbl("DayNum", card, "Day "..day, UDim2.new(1,0,0,22), UDim2.new(0,0,0,6), C.TextDim, false, 12)

		local ic = frame("IconContainer", card, UDim2.fromOffset(68,68), UDim2.new(0.5,-34,0,32), TINTS[day], 0.82, RADIUS)
		stroke(ic, C.Stroke, 1, 0.3)
		local ri = img("RewardIcon", ic, UDim2.fromOffset(56,56), UDim2.new(0.5,-28,0.5,-28))
		local ei = lbl("EmojiIcon", ri, EMOJIS[day], UDim2.fromScale(1,1), UDim2.new(0,0,0,0), C.Text, true)
		ei.TextScaled = true; ei.BackgroundTransparency = 1

		local rt = lbl("RewardTitle", card, TITLES[day], UDim2.new(1,-8,0,80), UDim2.fromOffset(4,106), C.Text, false, 11)
		rt.TextXAlignment = Enum.TextXAlignment.Center

		local ck = frame("Checkmark", card, UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.fromRGB(26,36,28), 0.25, RADIUS)
		ck.Visible = false; ck.ZIndex = 4
		local ci = lbl("CheckIcon", ck, "✓", UDim2.fromScale(1,1), UDim2.new(0,0,0,0), C.Green, true)
		ci.ZIndex = 5
	end

	-- Кнопка "Забрать"
	local cb = btn("ClaimButton", panel, "🎁  Claim Reward", UDim2.fromOffset(240,50), UDim2.new(0.5,-120,1,-66), C.BtnGreen, C.Text, 18)
	corner(cb, RADIUS); stroke(cb)

	-- Попап результата (дочерний ScreenGui, не Panel)
	local rp = frame("ResultPopup", g, UDim2.fromOffset(320,110), UDim2.new(0.5,-160,0.5,-55), C.PanelBG, 0.05, 6)
	rp.Visible = false; rp.ZIndex = 10
	stroke(rp)
	lbl("ResultTitle", rp, "🎉 Reward claimed!", UDim2.new(1,0,0,40), UDim2.new(0,0,0,8), C.Text, true, 18)
	lbl("ResultBody",  rp, "", UDim2.new(1,-20,0,50), UDim2.new(0,10,0,50), C.TextDim, false, 15)
end

-- ══════════════════════════════════════════════════════════════
--  8. ZONE MENU
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("ZoneMenu", 127); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.5; dim.AutoButtonColor = false

	local panel = frame("Panel", g, UDim2.fromOffset(560,480), UDim2.new(0.5,0,0.5,0), C.PanelBG, 0, 6)
	panel.AnchorPoint = Vector2.new(0.5,0.5)
	stroke(panel)
	titleBar(panel, 44)
	lbl("Title", panel, "🌀 Zone Travel", UDim2.new(1,0,0,44), UDim2.new(0,0,0,0), C.Text, true, 18)

	local list = frame("List", panel, UDim2.new(1,-32,1,-114), UDim2.fromOffset(16,54), Color3.new(0,0,0), 1)
	local ul = Instance.new("UIListLayout"); ul.Padding = UDim.new(0,8); ul.SortOrder = Enum.SortOrder.LayoutOrder; ul.Parent = list

	local cb = btn("CloseBtn", panel, "✕ Close", UDim2.fromOffset(200,40), UDim2.new(0.5,0,1,-50), C.Btn, C.Text, 15)
	cb.AnchorPoint = Vector2.new(0.5,0); corner(cb, RADIUS); stroke(cb)
end

-- ══════════════════════════════════════════════════════════════
--  9. MONETIZATION SHOP
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("MonetizationShop", 129); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.5; dim.AutoButtonColor = false

	local panel = frame("Panel", g, UDim2.fromOffset(640,520), UDim2.new(0.5,0,0.5,0), C.PanelBG, 0, 6)
	panel.AnchorPoint = Vector2.new(0.5,0.5)
	stroke(panel)
	titleBar(panel, 44)
	lbl("Title", panel, "💎 Shop", UDim2.new(1,0,0,44), UDim2.new(0,0,0,0), C.Text, true, 18)

	local tabRow = frame("TabRow", panel, UDim2.new(1,-32,0,36), UDim2.fromOffset(16,52), Color3.new(0,0,0), 1)
	local tgp = btn("TabGP", tabRow, "Game Passes", UDim2.fromOffset(150,36), UDim2.new(0,0,0,0), C.Btn, C.Text, 14)
	corner(tgp, RADIUS); stroke(tgp)
	local tprod = btn("TabProd", tabRow, "Coins & Boosts", UDim2.fromOffset(150,36), UDim2.fromOffset(158,0), C.Btn, C.Text, 14)
	corner(tprod, RADIUS); stroke(tprod)

	local scroll = Instance.new("ScrollingFrame"); scroll.Name = "Items"
	scroll.Size = UDim2.new(1,-32,1,-156); scroll.Position = UDim2.fromOffset(16,96)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = C.Stroke
	scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.Parent = panel
	local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(290,92)
	gl.CellPadding = UDim2.fromOffset(12,12); gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Parent = scroll

	local cb = btn("CloseBtn", panel, "✕ Close", UDim2.fromOffset(200,40), UDim2.new(0.5,0,1,-48), C.Btn, C.Text, 15)
	cb.AnchorPoint = Vector2.new(0.5,0); corner(cb, RADIUS); stroke(cb)
end

-- ══════════════════════════════════════════════════════════════
--  10. BOOST INDICATOR
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("BoostIndicator", 122)
	local row = frame("BoostRow", g, UDim2.fromOffset(400,36), UDim2.new(0,10,1,-104), Color3.new(0,0,0), 1)
	local ul = Instance.new("UIListLayout"); ul.FillDirection = Enum.FillDirection.Horizontal
	ul.Padding = UDim.new(0,6); ul.SortOrder = Enum.SortOrder.LayoutOrder
	ul.VerticalAlignment = Enum.VerticalAlignment.Center; ul.Parent = row
end

-- ══════════════════════════════════════════════════════════════
--  11. REEF DIVER INVENTORY
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("ReefDiverInventory", 125)
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local mf = frame("MainFrame", g, UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0), 1)

	-- Константы (должны совпадать с CustomInventory.client.lua)
	local SS, SG, SP, HRC = 70, 8, 10, 5
	local hotbarW = SP*2 + HRC*SS + (HRC-1)*SG  -- 402
	local hotbarH = SP*2 + SS                    -- 90

	local hbg = frame("HotbarBG", mf, UDim2.fromOffset(hotbarW, hotbarH),
		UDim2.new(0.5, -hotbarW/2, 1, -(hotbarH+12)), C.PanelDark, 0.05, RADIUS)
	stroke(hbg)

	for i = 1, HRC do
		local x = SP + (i-1)*(SS+SG)
		local sl = frame("RodSlot_"..i, hbg, UDim2.fromOffset(SS,SS), UDim2.fromOffset(x,SP), Color3.fromRGB(44,46,53), 0.1, RADIUS)
		local ic = img("Icon", sl, UDim2.new(0.75,0,0.75,0), UDim2.fromScale(0.5,0.4))
		ic.AnchorPoint = Vector2.new(0.5,0.5); ic.Visible = false
		local nl = lbl("NameLabel", sl, "", UDim2.new(1,-4,0.5,0), UDim2.fromScale(0.5,0.55), C.Text, true)
		nl.AnchorPoint = Vector2.new(0.5,0.5); nl.Visible = false
		local num = lbl("Number", sl, tostring(i), UDim2.fromOffset(18,18), UDim2.fromOffset(4,4), C.TextDim, true)
		num.TextScaled = true; num.ZIndex = 3
		local eb = frame("EquipBar", sl, UDim2.new(0.7,0,0,3), UDim2.new(0.15,0,1,-5), C.Text, 0, 2)
		eb.Visible = false
		local b = btn("Button", sl, "", UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0))
		b.BackgroundTransparency = 1; b.ZIndex = 5
	end

	-- Кнопка переключения инвентаря рыб
	local fbtn = btn("FishInventoryToggle", mf, "🐠 ▲",
		UDim2.fromOffset(72, 42), UDim2.new(0.5, hotbarW/2+12, 1, -(hotbarH/2+21+12)),
		C.PanelDark, C.Text, 14)
	corner(fbtn, RADIUS); stroke(fbtn)

	-- Fish Panel
	local FSS = 80
	local FCOLS, FROWS = 5, 3
	local fpW = FCOLS*(FSS+SG)+SG + 220  -- 668
	local fpH = FROWS*(FSS+SG)+SG + 60   -- 332
	local fpCloseY = -(hotbarH+8)

	local fp = frame("FishPanel", mf, UDim2.fromOffset(fpW,fpH),
		UDim2.new(0.5,-fpW/2, 1, fpCloseY), C.PanelBG, 0, RADIUS)
	fp.ClipsDescendants = false; fp.Visible = false
	stroke(fp)

	local fh = frame("Header", fp, UDim2.new(1,0,0,52), UDim2.new(0,0,0,0), C.TitleBar, 0, RADIUS)
	lbl("FishCount", fh, "0 fish", UDim2.new(0.45,0,1,0), UDim2.new(0.5,0,0,0), C.Text, false, 13)
	local sh = lbl("SellHint", fh, "💬 Sell at Fish Merchant", UDim2.new(0.45,-10,1,0), UDim2.new(0.55,0,0,0), C.TextDim, false, 11)
	sh.TextXAlignment = Enum.TextXAlignment.Right

	local fgW = FCOLS*(FSS+SG)+SG  -- 448
	local fgH = fpH - 52            -- 280
	local fgf = Instance.new("ScrollingFrame"); fgf.Name = "FishGrid"
	fgf.Size = UDim2.fromOffset(fgW, fgH); fgf.Position = UDim2.fromOffset(0,52)
	fgf.BackgroundTransparency = 1; fgf.BorderSizePixel = 0
	fgf.ScrollBarThickness = 4; fgf.ScrollBarImageColor3 = C.Stroke
	fgf.ScrollBarImageTransparency = 0.2; fgf.CanvasSize = UDim2.new(0,0,0,0)
	fgf.ScrollingDirection = Enum.ScrollingDirection.Y; fgf.ClipsDescendants = true
	fgf.Parent = fp
	local grid = frame("Grid", fgf, UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0), 1)
	local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(FSS,FSS)
	gl.CellPadding = UDim2.fromOffset(SG,SG); gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.HorizontalAlignment = Enum.HorizontalAlignment.Left; gl.Parent = grid
	local gp = Instance.new("UIPadding"); gp.PaddingLeft = UDim.new(0,SG); gp.PaddingTop = UDim.new(0,SG); gp.Parent = grid

	-- Detail Panel
	local dpW = fpW - fgW - 8  -- 212
	local dp = frame("DetailPanel", fp, UDim2.fromOffset(dpW-8, fgH-8), UDim2.fromOffset(fgW+4, 56), C.PanelDark, 0, RADIUS)
	stroke(dp)

	local iconSize = 72  -- fixed smaller size so rows fit without overflow
	local dIcon = img("Icon", dp, UDim2.fromOffset(iconSize, iconSize), UDim2.new(0.5,0,0,10))
	dIcon.AnchorPoint = Vector2.new(0.5,0)
	local dPlaceholder = frame("IconPlaceholder", dp, UDim2.fromOffset(iconSize,iconSize), UDim2.new(0.5,0,0,10), Color3.fromRGB(44,46,53), 0.1, RADIUS)
	dPlaceholder.AnchorPoint = Vector2.new(0.5,0)
	lbl("PlaceholderText", dPlaceholder, "🐟", UDim2.fromScale(1,1), UDim2.new(0,0,0,0), C.Text, true)

	local rowY = iconSize + 16  -- 88 — fits 6 rows × 24px = 144px, total 232 < panel height 272
	local ROW_DEFS = {
		{"RowName",     "Name",     C.Text},
		{"RowRarity",   "Rarity",   C.Text},
		{"RowSize",     "Size",     C.Text},
		{"RowMutation", "Mutation", Color3.fromRGB(200,140,230)},
		{"RowValue",    "Value",    C.Gold},
		{"RowZone",     "Zone",     C.TextDim},
	}
	for ri, rd in ipairs(ROW_DEFS) do
		local row = frame(rd[1], dp, UDim2.new(1,-16,0,20), UDim2.fromOffset(8, rowY + (ri-1)*24), Color3.new(0,0,0), 1)
		lbl("Label", row, rd[2], UDim2.fromScale(0.45,1), UDim2.new(0,0,0,0), C.TextDim, false, 11)
		local vl = lbl("Value", row, "—", UDim2.fromScale(0.55,1), UDim2.fromScale(0.45,0), rd[3], true, 11)
		vl.TextXAlignment = Enum.TextXAlignment.Right
	end
	local dph = lbl("Placeholder", dp, "Select a fish\nto see details", UDim2.fromScale(1,0.3), UDim2.fromScale(0,0.35), C.TextDim, false, 12)
	dph.TextWrapped = true
end

-- ══════════════════════════════════════════════════════════════
--  12. NPC DIALOG GUI (Grow a Garden style)
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("NPCDialogGui", 135); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.45; dim.AutoButtonColor = false

	local panel = frame("Panel", g, UDim2.fromOffset(600,180), UDim2.new(0.5,0,1,-40), C.PanelBG, 0, 6)
	panel.AnchorPoint = Vector2.new(0.5,1)
	stroke(panel)

	-- Portrait
	local portrait = frame("Portrait", panel, UDim2.fromOffset(150,150), UDim2.fromOffset(15,15), C.PanelDark, 0, RADIUS)
	stroke(portrait)
	local pIcon = lbl("PortraitIcon", portrait, "🧑", UDim2.fromScale(1,1), UDim2.new(0,0,0,0), C.Text, true)
	pIcon.TextScaled = true

	-- Name label above portrait
	local nameLabel = lbl("NameLabel", panel, "NPC", UDim2.new(0,150,0,28), UDim2.fromOffset(15,-32), C.Text, true, 16)
	nameLabel.BackgroundTransparency = 1

	-- Dialog text (right of portrait)
	local dialogText = lbl("DialogText", panel, "", UDim2.new(1,-190,0,100), UDim2.fromOffset(180,15), C.Text, false, 16)
	dialogText.TextXAlignment = Enum.TextXAlignment.Left
	dialogText.TextYAlignment = Enum.TextYAlignment.Top
	dialogText.TextScaled = false

	-- Transparent click-to-advance area covering the whole panel (sits behind portrait/text)
	-- ClickArea intercepts clicks on panel so they advance dialog instead of leaking to Dim
	local ca = btn("ClickArea", panel, "", UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0))
	ca.BackgroundTransparency = 1; ca.ZIndex = 1

	-- Choices row (bottom-right of panel)
	local choicesRow = frame("ChoicesRow", panel, UDim2.new(1,-190,0,40), UDim2.new(0,180,1,-55), Color3.new(0,0,0), 1)
	local c1 = btn("Choice1", choicesRow, "Yes!", UDim2.new(0.48,0,1,0), UDim2.new(0,0,0,0), C.BtnGreen, C.Text, 15)
	corner(c1, RADIUS); stroke(c1)
	local c2 = btn("Choice2", choicesRow, "Maybe later", UDim2.new(0.48,0,1,0), UDim2.new(0.52,0,0,0), C.Btn, C.Text, 15)
	corner(c2, RADIUS); stroke(c2)
	choicesRow.Visible = false
end

-- Remove leftover TestButtons GUI if it exists
do
	local old = StarterGui:FindFirstChild("TestButtons")
	if old then old:Destroy() end
end

-- ══════════════════════════════════════════════════════════════
print("✅ ReefDiver UIBuilder complete!")
print("   GUIs in StarterGui:")
local names = {"MainHUD","FishingGui","EventBanner","AnnounceBanner","ComboDisplay",
	"ShopGui","DailyRewardGui","ZoneMenu","MonetizationShop","BoostIndicator",
	"ReefDiverInventory","NPCDialogGui"}
for _, n in ipairs(names) do
	local exists = StarterGui:FindFirstChild(n) ~= nil
	print("   " .. (exists and "✓" or "✗") .. " " .. n)
end
print("   Find ImageLabel with Image=\"\" and upload your images (rbxassetid://...)")

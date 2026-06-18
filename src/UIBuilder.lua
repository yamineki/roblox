-- UIBuilder.lua
-- ReefDiver — Генератор всех GUI (яркий мультяшный стиль)
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
--  ПАЛИТРА (яркий мультяшный стиль)
-- ══════════════════════════════════════════════════════════════
local C = {
	-- Общие цвета
	White      = Color3.fromRGB(255, 255, 255),
	Card       = Color3.fromRGB(22, 24, 30),     -- тёмная стеклянная карточка
	CardStroke = Color3.fromRGB(80, 200, 190),   -- светящаяся teal-обводка
	Text       = Color3.fromRGB(235, 238, 245),  -- светлый текст на тёмном фоне
	TextDim    = Color3.fromRGB(150, 158, 175),  -- приглушённый светло-серо-синий
	TextLight  = Color3.fromRGB(240, 245, 255),  -- светлый текст на цветном фоне
	CloseBtn   = Color3.fromRGB(220, 70, 70),    -- кнопка закрытия

	-- Акцентные цвета панелей
	Teal       = Color3.fromRGB(50, 165, 180),   -- SellPanel, MainHUD coins
	TealDark   = Color3.fromRGB(35, 140, 160),
	TealDarker = Color3.fromRGB(25, 110, 130),

	Blue       = Color3.fromRGB(65, 110, 215),   -- ExpeditionPanel, ZoneMenu
	BlueDark   = Color3.fromRGB(45, 80, 180),
	BlueDarker = Color3.fromRGB(30, 55, 150),

	Purple     = Color3.fromRGB(125, 70, 195),   -- RebirthPanel, MonetizationShop
	PurpleDark = Color3.fromRGB(95, 45, 160),

	Navy       = Color3.fromRGB(30, 55, 115),    -- FishDexPanel
	NavyDark   = Color3.fromRGB(20, 40, 90),

	Green      = Color3.fromRGB(50, 175, 100),   -- ShopGui, confirm buttons
	GreenDark  = Color3.fromRGB(35, 145, 75),

	Orange     = Color3.fromRGB(220, 150, 50),   -- DailyRewardGui
	OrangeDark = Color3.fromRGB(185, 120, 30),

	Coral      = Color3.fromRGB(215, 90, 80),    -- danger / stress
	Gold       = Color3.fromRGB(235, 190, 80),   -- монеты (слегка приглушено)

	-- Цвета игрового процесса (минигра остаётся тёмной)
	GreenZone  = Color3.fromRGB(90, 200, 110),
	PanelDark  = Color3.fromRGB(32, 32, 38),
	PanelBG    = Color3.fromRGB(38, 40, 46),
	Stroke     = Color3.fromRGB(70, 75, 85),
}
local RADIUS = 10   -- pill-style corners for all main panels (already in 8-12px range)
local BRAD   = 8    -- button corner radius

-- ══════════════════════════════════════════════════════════════
--  ХЕЛПЕРЫ
-- ══════════════════════════════════════════════════════════════
local function corner(o, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or RADIUS); c.Parent = o; return c
end
local function stroke(o, col, t, tr)
	local s = Instance.new("UIStroke"); s.Color = col or C.CardStroke; s.Thickness = t or 1.5
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
	b.BackgroundColor3 = bg or C.Teal
	b.TextColor3 = textColor or C.TextLight; b.BorderSizePixel = 0
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
	f.BackgroundColor3 = bg or C.Card
	f.BackgroundTransparency = transp or 0; f.BorderSizePixel = 0
	f.Parent = parent; if r then corner(f, r) end; return f
end

-- Яркая заголовочная полоса панели
local function brightHeader(parent, h, accentColor, darkerColor)
	h = h or 50
	local hdr = frame("Header", parent, UDim2.new(1,0,0,h), UDim2.new(), accentColor, 0, RADIUS)
	frame("HdrFix", hdr, UDim2.new(1,0,0.5,0), UDim2.new(0,0,0.5,0), accentColor, 0)
	return hdr
end

-- Кнопка закрытия (красная ✕ справа в хедере)
local function closeX(parent, offsetX, offsetY)
	offsetX = offsetX or -42
	offsetY = offsetY or 8
	local cx = btn("CloseBtn", parent, "✕",
		UDim2.fromOffset(34,34), UDim2.new(1,offsetX,0,offsetY),
		C.CloseBtn, C.White, 16)
	corner(cx, 8)
	return cx
end

-- ══════════════════════════════════════════════════════════════
--  1. MAIN HUD
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("MainHUD", 120)

	-- Монеты — яркая тeal-плашка внизу слева
	local bl = frame("BottomLeft", g, UDim2.fromOffset(180,46), UDim2.new(0,10,1,-62), C.Teal, 0, RADIUS)
	stroke(bl, C.TealDark, 2, 0)
	lbl("CoinsLabel", bl, "🪙 0", UDim2.fromScale(1,1), UDim2.new(0,0,0,0), C.White, true, 18)

	-- Кнопки HUD (pill-style)
	local dailyBtn = btn("DailyBtn", g, "🗓", UDim2.fromOffset(44,44), UDim2.new(1,-58,0,10), C.Orange)
	dailyBtn.TextScaled = true; corner(dailyBtn, RADIUS); stroke(dailyBtn, C.OrangeDark, 2, 0)
	local dot = frame("NotifDot", dailyBtn, UDim2.fromOffset(12,12), UDim2.new(1,-3,0,-3), C.Coral, 0, 6)
	dot.AnchorPoint = Vector2.new(0,0); dot.Visible = false

	local monBtn = btn("MonetizationBtn", g, "💎", UDim2.fromOffset(44,44), UDim2.new(1,-110,0,10), C.Purple)
	monBtn.TextScaled = true; corner(monBtn, RADIUS); stroke(monBtn, C.PurpleDark, 2, 0)
end

-- ══════════════════════════════════════════════════════════════
--  2. FISHING GUI  (тёмная — игровой оверлей, яркое не подходит)
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("FishingGui", 130)

	-- Hook Phase — горизонтальный слайдер (без затемнения фона — видна вода/мир)
	local hp = frame("HookPhase", g, UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0), 1)
	hp.Visible = false
	local sliderBG = frame("SliderBG", hp, UDim2.fromOffset(520,58), UDim2.new(0.5,-260,0.5,-29), C.PanelDark, 0, 8)
	stroke(sliderBG, C.Stroke, 1.5, 0)
	frame("GreenZone", sliderBG, UDim2.fromOffset(104,58), UDim2.new(0.5,-52,0,0), C.GreenZone, 0.35, 8)
	frame("PerfectZone", sliderBG, UDim2.fromOffset(42,58), UDim2.new(0.5,-21,0,0), Color3.fromRGB(120,230,140), 0.1, 8)
	local si = frame("SliderIndicator", sliderBG, UDim2.fromOffset(30,58), UDim2.new(0.5,-15,0,0), C.White, 0, 8)
	stroke(si, Color3.fromRGB(20,20,24), 1, 0)
	local glowStroke = stroke(si, C.GreenZone, 3, 0.5); glowStroke.Name = "GlowStroke"
	frame("CenterLine", sliderBG, UDim2.fromOffset(2,58), UDim2.new(0.5,-1,0,0), Color3.fromRGB(255,255,255), 0.6)
	lbl("HintLabel", hp, "Click when the cursor is in the green zone!", UDim2.fromOffset(480,36), UDim2.new(0.5,-240,0.5,46), C.White, true)
	local zoneLabel = lbl("ZoneLabel", hp, "🎣  CAST!", UDim2.fromOffset(340,54), UDim2.new(0.5,-170,0.5,-110), C.White, true)
	zoneLabel.TextStrokeTransparency = 0.5

	-- Catch Phase (без затемнения фона; все элементы выровнены вокруг
	-- вертикального центра экрана отступами в офсетах, чтобы ничего не наезжало
	-- друг на друга независимо от разрешения экрана)
	local cp = frame("CatchPhase", g, UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0), 1)
	cp.Visible = false
	local sf = frame("ScaleFrame", cp, UDim2.fromOffset(60,400), UDim2.new(0.5,-30,0.5,-200), C.PanelDark, 0, 8)
	stroke(sf, C.Stroke, 1.5, 0)
	local waterBack = frame("WaterBack", sf, UDim2.new(1,4,1,4), UDim2.new(0,-2,0,-2), Color3.fromRGB(40,90,120), 0.75, 8)
	waterBack.ZIndex = 0
	local waterMid = frame("WaterMid", sf, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(50,110,150), 0.85, 8)
	waterMid.ZIndex = 0
	frame("GreenZone", sf, UDim2.new(1,0,0,80), UDim2.new(0,0,0.5,-40), C.GreenZone, 0.3, 8)
	local fi = img("FishIndicator", sf, UDim2.fromOffset(50,30), UDim2.new(-1,0,0.5,-15))
	fi.BackgroundColor3 = Color3.fromRGB(230,150,70); fi.BackgroundTransparency = 0; corner(fi, 8)
	local pb = frame("ProgressBar", cp, UDim2.fromOffset(20,400), UDim2.new(0.5,35,0.5,-200), C.PanelDark, 0, 8)
	stroke(pb, C.Stroke, 1.5, 0)
	local fill = frame("Fill", pb, UDim2.new(1,0,0,0), UDim2.new(0,0,1,0), C.GreenZone, 0)
	local fillGrad = Instance.new("UIGradient")
	fillGrad.Color = ColorSequence.new(C.GreenZone, Color3.fromRGB(160,255,180))
	fillGrad.Rotation = 90; fillGrad.Parent = fill

	-- Статусные подсказки — стопкой НАД игровым полем, не наезжают на бар
	local pl = lbl("PerfectLabel", cp, "PERFECT CATCH!", UDim2.fromOffset(300,32), UDim2.new(0.5,-150,0.5,-300), Color3.fromRGB(120,230,140), true)
	pl.Visible = false
	local sl = lbl("StressLabel", cp, "⚠ Fish is angry!", UDim2.fromOffset(300,32), UDim2.new(0.5,-150,0.5,-258), C.Coral, true)
	sl.Visible = false

	-- Behavior/Variant — стопкой ПОД игровым полем
	lbl("BehaviorLabel", cp, "Lazy", UDim2.fromOffset(200,24), UDim2.new(0.5,-100,0.5,212), Color3.fromRGB(160,165,175), false)
	lbl("VariantLabel", cp, "", UDim2.fromOffset(300,24), UDim2.new(0.5,-150,0.5,240), Color3.fromRGB(200,210,230), false, 13)

	local el = lbl("EscapeLabel", cp, "Fish got away...", UDim2.fromOffset(400,50), UDim2.new(0.5,-200,0.5,-25), C.Coral, true)
	el.Visible = false

	local effectsLayer = frame("EffectsLayer", cp, UDim2.fromScale(1,1), UDim2.new(0,0,0,0), Color3.new(0,0,0), 1)
	effectsLayer.ClipsDescendants = false; effectsLayer.ZIndex = 50

	-- ══ TapCheckWidget — общий горизонтальный слайдер для вариантов Rhythm и SkillCheck ══
	-- (Rhythm: индикатор колеблется непрерывно, тапай в такт.
	--  SkillCheck (Dead by Daylight-style): виджет невидим до случайного "Check!",
	--  затем индикатор быстро проходит бар один раз — тапни в зоне.)
	-- Выровнен по правому краю с ScaleFrame (а не по центру экрана), чтобы не
	-- наезжать на всегда видимый ProgressBar справа от игрового поля
	local tcw = frame("TapCheckWidget", cp, UDim2.fromOffset(360,86), UDim2.new(0.5,-330,0.5,-43), C.PanelDark, 0, 8)
	tcw.Visible = false
	stroke(tcw, C.Stroke, 1.5, 0)
	local tapHint = lbl("TapHint", tcw, "Tap to the rhythm!", UDim2.fromOffset(320,20), UDim2.fromOffset(20,4), C.White, true, 13)
	local tapBar = frame("TapBar", tcw, UDim2.fromOffset(320,40), UDim2.fromOffset(20,30), C.PanelBG, 0, 6)
	frame("TapGreenZone", tapBar, UDim2.fromOffset(110,40), UDim2.new(0.5,-55,0,0), C.GreenZone, 0.35, 6)
	frame("TapPerfectZone", tapBar, UDim2.fromOffset(46,40), UDim2.new(0.5,-23,0,0), Color3.fromRGB(120,230,140), 0.1, 6)
	local tapInd = frame("TapIndicator", tapBar, UDim2.fromOffset(8,40), UDim2.new(0,0,0,0), C.White, 0, 4)
	stroke(tapInd, Color3.fromRGB(20,20,24), 1, 0)
	frame("TapCenterLine", tapBar, UDim2.fromOffset(2,40), UDim2.new(0.5,-1,0,0), Color3.fromRGB(255,255,255), 0.6)

	-- Result Phase
	local rp = frame("ResultPhase", g, UDim2.fromOffset(400,550), UDim2.new(0.5,-200,0.5,-275), C.Card, 0.08, RADIUS)
	rp.Visible = false; stroke(rp, C.CardStroke, 2, 0)
	local rarityBanner = frame("RarityBanner", rp, UDim2.new(1,0,0,8), UDim2.new(0,0,0,0), C.Teal, 0, RADIUS)
	rarityBanner.Name = "RarityBanner"
	local fi2 = img("FishImage", rp, UDim2.new(0.8,0,0.38,0), UDim2.new(0.1,0,0.04,0))
	fi2.BackgroundColor3 = C.CardStroke; fi2.BackgroundTransparency = 0.3; corner(fi2, 8)

	-- ══ HATCH OVERLAY (Pet Simulator-style reveal) ══
	-- Закрывает FishImage силуэтом чёрной рыбы, которая трясётся и трескается
	-- перед тем как показать настоящую рыбу — клик ускоряет процесс.
	local hatchOverlay = frame("HatchOverlay", rp, UDim2.new(0.8,0,0.38,0), UDim2.new(0.1,0,0.04,0), Color3.fromRGB(14,14,18), 0, 8)
	hatchOverlay.ZIndex = 6
	local eggIcon = lbl("EggIcon", hatchOverlay, "🐟", UDim2.fromScale(0.7,0.7), UDim2.fromScale(0.15,0.06), Color3.fromRGB(8,8,10), true)
	eggIcon.TextScaled = true; eggIcon.ZIndex = 7
	eggIcon.TextStrokeColor3 = Color3.fromRGB(60,60,70); eggIcon.TextStrokeTransparency = 0.5
	-- Вспышка-разлом в момент полного раскрытия — белый круг, расширяется и гаснет
	local burstFlash = frame("BurstFlash", hatchOverlay, UDim2.fromOffset(20,20), UDim2.fromScale(0.5,0.5), Color3.fromRGB(255,255,255), 1, 200)
	burstFlash.AnchorPoint = Vector2.new(0.5,0.5); burstFlash.ZIndex = 8
	local hatchHint = lbl("HatchHint", hatchOverlay, "Click to crack it open!", UDim2.new(1,0,0,18), UDim2.new(0,0,0.78,0), C.TextDim, true, 12)
	hatchHint.ZIndex = 7
	local crackBar = frame("CrackBar", hatchOverlay, UDim2.new(0.7,0,0,8), UDim2.new(0.15,0,0.9,0), Color3.fromRGB(40,40,50), 0, 4)
	crackBar.ZIndex = 7
	local crackFill = frame("Fill", crackBar, UDim2.new(0,0,1,0), UDim2.new(), Color3.fromRGB(255,200,60), 0, 4)
	crackFill.Name = "Fill"; crackFill.ZIndex = 7

	local nb = lbl("NewBadge", rp, "✨ NEW!", UDim2.fromOffset(90,30), UDim2.new(1,-100,0,12), C.Gold, true)
	nb.Visible = false; nb.TextStrokeTransparency = 0.4; nb.ZIndex = 5
	lbl("FishName",    rp, "???",     UDim2.new(1,0,0.10,0), UDim2.new(0,0,0.44,0), C.Text, true, 26)
	lbl("FishRarity",  rp, "Common",  UDim2.new(0.5,0,0.07,0), UDim2.new(0.1,0,0.52,0), C.TextDim, false)
	lbl("FishSize",    rp, "Normal",  UDim2.new(0.5,0,0.07,0), UDim2.new(0.5,0,0.52,0), C.TextDim, false)
	local fm = lbl("FishMutation", rp, "", UDim2.new(1,0,0.07,0), UDim2.new(0,0,0.60,0), Color3.fromRGB(130,70,200), false)
	fm.Visible = false
	lbl("FishValue",   rp, "0 🪙",    UDim2.new(1,0,0.08,0), UDim2.new(0,0,0.68,0), C.Gold, true)
	local pb2 = lbl("PerfectBonus", rp, "+25% Perfect!", UDim2.new(1,0,0.06,0), UDim2.new(0,0,0.77,0), Color3.fromRGB(50,175,100), false)
	pb2.Visible = false
end

-- ══════════════════════════════════════════════════════════════
--  3. EVENT BANNER
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("EventBanner", 126)
	local banner = frame("Banner", g, UDim2.fromOffset(500,54), UDim2.new(0.5,-250,-0.15,0), C.Teal, 0.05, RADIUS)
	banner.Visible = false; stroke(banner, C.TealDark, 2, 0)
	local en = lbl("EventName", banner, "🌀 Event", UDim2.new(0.6,-15,1,0), UDim2.new(0,15,0,0), C.White, true)
	en.TextXAlignment = Enum.TextXAlignment.Left
	local et = lbl("EventTimer", banner, "...", UDim2.new(0.38,-15,1,0), UDim2.new(0.6,0,0,0), Color3.fromRGB(220,245,255), false)
	et.TextXAlignment = Enum.TextXAlignment.Right
end

-- ══════════════════════════════════════════════════════════════
--  4. ANNOUNCE BANNER
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("AnnounceBanner", 126)
	local banner = frame("Banner", g, UDim2.fromOffset(700,72), UDim2.new(0.5,-350,0,10), C.Navy, 0.05, RADIUS)
	banner.Visible = false; stroke(banner, C.Blue, 2, 0)
	local fi = img("FishImage", banner, UDim2.fromOffset(64,64), UDim2.fromOffset(4,4))
	fi.BackgroundTransparency = 1
	local ml = lbl("MessageLabel", banner, "", UDim2.new(0.85,0,1,0), UDim2.new(0,78,0,0), C.White, true)
	ml.TextXAlignment = Enum.TextXAlignment.Left
end

-- ══════════════════════════════════════════════════════════════
--  5. COMBO DISPLAY
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("ComboDisplay", 131)
	local cl = lbl("ComboLabel", g, "", UDim2.fromOffset(400,40), UDim2.new(0.5,-200,0.28,0), C.Gold, true, 22)
	cl.TextScaled = false; cl.Visible = false; cl.TextStrokeTransparency = 0.4
end

-- ══════════════════════════════════════════════════════════════
--  6. SHOP GUI (магазин удочек) — зелёный акцент
-- ══════════════════════════════════════════════════════════════
do
	local AC = C.Green
	local g = scrGui("ShopGui", 128); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.5; dim.AutoButtonColor = false

	local panel = frame("ShopPanel", g, UDim2.fromOffset(700,580), UDim2.new(0.5,0,1.5,0), AC, 0, RADIUS)
	panel.AnchorPoint = Vector2.new(0.5,0.5); stroke(panel, C.GreenDark, 2, 0)

	local hdr = brightHeader(panel, 50, AC, C.GreenDark)
	lbl("Title", hdr, "🎣  Rod Shop", UDim2.new(0.7,0,1,0), UDim2.new(0,14,0,0), C.White, true, 20)
	lbl("ShopCoinsLabel", hdr, "🪙 ---", UDim2.new(0.28,0,1,0), UDim2.new(0.68,0,0,0), C.Gold, true, 16)
	closeX(hdr)

	-- Превью выбранной удочки (увеличенная иконка + описание)
	local preview = frame("RodPreview", panel, UDim2.new(1,-16,0,84), UDim2.fromOffset(8,58), C.Card, 0.08, 8)
	stroke(preview, C.CardStroke, 1.5, 0)
	local pvIconHolder = frame("IconHolder", preview, UDim2.fromOffset(72,72), UDim2.fromOffset(6,6), Color3.fromRGB(40,44,52), 0, 8)
	local pvIcon = img("Icon", pvIconHolder, UDim2.fromScale(0.85,0.85), UDim2.fromScale(0.075,0.075))
	local pvName = lbl("PreviewName", preview, "Select a rod", UDim2.new(1,-90,0,24), UDim2.fromOffset(86,8), C.Text, true, 17)
	pvName.TextXAlignment = Enum.TextXAlignment.Left
	local pvDesc = lbl("PreviewDesc", preview, "Hover or buy a rod to see its bonus here.", UDim2.new(1,-90,0,40), UDim2.fromOffset(86,32), C.TextDim, false, 12)
	pvDesc.TextXAlignment = Enum.TextXAlignment.Left; pvDesc.TextYAlignment = Enum.TextYAlignment.Top; pvDesc.TextWrapped = true

	-- Белая область карточек
	local content = frame("Content", panel, UDim2.new(1,-16,1,-198), UDim2.fromOffset(8,150), C.Card, 0.08, 8)
	stroke(content, C.CardStroke, 1.5, 0)

	local grid = Instance.new("ScrollingFrame"); grid.Name = "RodGrid"
	grid.Size = UDim2.fromScale(1,1); grid.Position = UDim2.new()
	grid.BackgroundTransparency = 1; grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 4; grid.ScrollBarImageColor3 = C.GreenDark
	grid.ScrollingDirection = Enum.ScrollingDirection.X
	grid.CanvasSize = UDim2.new(0,0,0,0); grid.Parent = content
	local gl = Instance.new("UIListLayout"); gl.FillDirection = Enum.FillDirection.Horizontal
	gl.Padding = UDim.new(0,10); gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.VerticalAlignment = Enum.VerticalAlignment.Center
	local gpad = Instance.new("UIPadding"); gpad.PaddingLeft = UDim.new(0,6); gpad.PaddingTop = UDim.new(0,6)
	gpad.Parent = grid; gl.Parent = grid

	-- Кнопки навигации карусели (поверх RodGrid, по центру области Content)
	local navLeft = btn("NavLeft", panel, "◀", UDim2.fromOffset(34,46), UDim2.new(0,10,0,150), AC, C.White, 18)
	navLeft.AnchorPoint = Vector2.new(0,0); navLeft.Position = UDim2.new(0,10,0,150) + UDim2.new(0,0,0,(580-198)/2 - 23)
	navLeft.ZIndex = 10
	corner(navLeft, BRAD); stroke(navLeft, C.GreenDark, 1.5, 0)
	local navRight = btn("NavRight", panel, "▶", UDim2.fromOffset(34,46), UDim2.new(1,-44,0,150), AC, C.White, 18)
	navRight.Position = UDim2.new(1,-44,0,150) + UDim2.new(0,0,0,(580-198)/2 - 23)
	navRight.ZIndex = 10
	corner(navRight, BRAD); stroke(navRight, C.GreenDark, 1.5, 0)

	local cb = btn("CloseButton", panel, "✕  Close", UDim2.fromOffset(200,40), UDim2.new(0.5,0,1,-50), C.CloseBtn, C.White, 15)
	cb.AnchorPoint = Vector2.new(0.5,0); corner(cb, BRAD); stroke(cb, Color3.fromRGB(170,40,40), 1.5, 0)
end

-- ══════════════════════════════════════════════════════════════
--  7. DAILY REWARD GUI — оранжевый акцент
-- ══════════════════════════════════════════════════════════════
do
	local AC = C.Orange
	local g = scrGui("DailyRewardGui", 150); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.45; dim.AutoButtonColor = false

	local panel = frame("Panel", g, UDim2.fromOffset(760,430), UDim2.new(0.5,0,0.5,0), AC, 0, RADIUS)
	panel.AnchorPoint = Vector2.new(0.5,0.5); stroke(panel, C.OrangeDark, 2, 0)

	local hdr = brightHeader(panel, 50, AC, C.OrangeDark)
	lbl("Title", panel, "🗓  DAILY REWARDS", UDim2.new(0.75,0,0,50), UDim2.new(0,14,0,0), C.White, true, 20)
	local sl = lbl("StreakLabel", panel, "Streak: 0 days", UDim2.new(0.35,0,0,50), UDim2.new(0.55,0,0,0), C.White, false, 14)
	sl.TextXAlignment = Enum.TextXAlignment.Right
	closeX(panel)

	local tl = lbl("TimerLabel", panel, "", UDim2.new(0.6,0,0,26), UDim2.new(0.2,0,0,58), Color3.fromRGB(80,60,20), false, 13)
	tl.TextXAlignment = Enum.TextXAlignment.Center

	-- 7 карточек дней (белые)
	local TINTS = {
		Color3.fromRGB(255,210,90), Color3.fromRGB(90,200,110), Color3.fromRGB(200,140,230),
		Color3.fromRGB(110,180,230), Color3.fromRGB(170,110,220), Color3.fromRGB(110,150,220), Color3.fromRGB(255,180,60)
	}
	local EMOJIS = {"🪙","🍀","✨","⏱","📦","🐠","🌟"}
	local TITLES = {
		"🪙 500 coins", "🍀 Luck ×1.5\n30 min", "✨ Mutations ×2\n30 min",
		"⏱ AFK ticket ×1","📦 Chest ×3","🐠 Rare+ chest","🌟 Special mutation"
	}
	local CARD_W, CARD_H, CARD_GAP = 90, 240, 8
	local startX = (760 - 7*CARD_W - 6*CARD_GAP) / 2

	for day = 1, 7 do
		local x = startX + (day-1)*(CARD_W+CARD_GAP)
		local card = frame("Day"..day, panel, UDim2.fromOffset(CARD_W,CARD_H), UDim2.fromOffset(x,90), C.Card, 0.08, 8)
		local cs = stroke(card, C.CardStroke, 1.5, 0); cs.Name = "CardStroke"
		local gs = stroke(card, C.White, 2, 1); gs.Name = "GlowStroke"

		lbl("DayNum", card, "Day "..day, UDim2.new(1,0,0,20), UDim2.new(0,0,0,4), C.TextDim, false, 11)

		local ic = frame("IconContainer", card, UDim2.fromOffset(60,60), UDim2.new(0.5,-30,0,26), TINTS[day], 0.3, 8)
		stroke(ic, TINTS[day], 2, 0.5)
		local ri = img("RewardIcon", ic, UDim2.fromOffset(48,48), UDim2.new(0.5,-24,0.5,-24))
		lbl("EmojiIcon", ri, EMOJIS[day], UDim2.fromScale(1,1), UDim2.new(), C.Text, true).TextScaled = true

		local rt = lbl("RewardTitle", card, TITLES[day], UDim2.new(1,-8,0,70), UDim2.fromOffset(4,92), C.Text, false, 11)
		rt.TextXAlignment = Enum.TextXAlignment.Center

		local ck = frame("Checkmark", card, UDim2.fromScale(1,1), UDim2.new(), C.Green, 0.35, 8)
		ck.Visible = false; ck.ZIndex = 4
		local ci = lbl("CheckIcon", ck, "✓", UDim2.fromScale(1,1), UDim2.new(), C.White, true)
		ci.ZIndex = 5; ci.TextScaled = true
	end

	-- Кнопка "Забрать"
	local cb = btn("ClaimButton", panel, "🎁  Claim Reward", UDim2.fromOffset(240,46), UDim2.new(0.5,-120,1,-62), C.Green, C.White, 17)
	corner(cb, BRAD); stroke(cb, C.GreenDark, 1.5, 0)

	-- Попап результата
	local rp = frame("ResultPopup", g, UDim2.fromOffset(320,110), UDim2.new(0.5,-160,0.5,-55), C.Card, 0.05, RADIUS)
	rp.Visible = false; rp.ZIndex = 10; stroke(rp, C.CardStroke, 2, 0)
	lbl("ResultTitle", rp, "🎉 Reward claimed!", UDim2.new(1,0,0,40), UDim2.new(0,0,0,8), C.Text, true, 18)
	lbl("ResultBody",  rp, "", UDim2.new(1,-20,0,50), UDim2.new(0,10,0,50), C.TextDim, false, 15)
end

-- ══════════════════════════════════════════════════════════════
--  8. ZONE MENU — синий акцент
-- ══════════════════════════════════════════════════════════════
do
	local AC = C.Blue
	local g = scrGui("ZoneMenu", 127); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.5; dim.AutoButtonColor = false

	local panel = frame("Panel", g, UDim2.fromOffset(560,480), UDim2.new(0.5,0,0.5,0), AC, 0, RADIUS)
	panel.AnchorPoint = Vector2.new(0.5,0.5); stroke(panel, C.BlueDark, 2, 0)

	local hdr = brightHeader(panel, 50, AC, C.BlueDark)
	lbl("Title", panel, "🌀  Zone Travel", UDim2.new(0.8,0,0,50), UDim2.new(0,14,0,0), C.White, true, 20)
	closeX(panel)

	local list = frame("List", panel, UDim2.new(1,-16,1,-106), UDim2.fromOffset(8,58), C.Card, 0.08, 8)
	stroke(list, C.CardStroke, 1.5, 0)
	local ul = Instance.new("UIListLayout"); ul.Padding = UDim.new(0,6); ul.SortOrder = Enum.SortOrder.LayoutOrder
	local lpad = Instance.new("UIPadding"); lpad.PaddingLeft = UDim.new(0,6); lpad.PaddingTop = UDim.new(0,6)
	lpad.Parent = list; ul.Parent = list
end

-- ══════════════════════════════════════════════════════════════
--  9. MONETIZATION SHOP — фиолетовый акцент
-- ══════════════════════════════════════════════════════════════
do
	local AC = C.Purple
	local g = scrGui("MonetizationShop", 129); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.5; dim.AutoButtonColor = false

	local panel = frame("Panel", g, UDim2.fromOffset(640,520), UDim2.new(0.5,0,0.5,0), AC, 0, RADIUS)
	panel.AnchorPoint = Vector2.new(0.5,0.5); stroke(panel, C.PurpleDark, 2, 0)

	local hdr = brightHeader(panel, 50, AC, C.PurpleDark)
	lbl("Title", panel, "💎  Shop", UDim2.new(0.4,0,0,50), UDim2.new(0,14,0,0), C.White, true, 20)
	local mCoins = lbl("BalanceLabel", panel, "🪙 ---", UDim2.new(0.3,0,0,50), UDim2.new(0.42,0,0,0), C.Gold, true, 16)
	mCoins.TextXAlignment = Enum.TextXAlignment.Right
	closeX(panel)

	-- Таб-строка
	local tabRow = frame("TabRow", panel, UDim2.new(1,-16,0,38), UDim2.fromOffset(8,58), C.PurpleDark, 0, 8)
	local tgp = btn("TabGP", tabRow, "Game Passes", UDim2.fromOffset(150,34), UDim2.fromOffset(2,2), C.Purple, C.White, 14)
	corner(tgp, 6); stroke(tgp, Color3.fromRGB(180,130,230), 1.5, 0)
	local tprod = btn("TabProd", tabRow, "Coins & Boosts", UDim2.fromOffset(150,34), UDim2.fromOffset(156,2), Color3.fromRGB(80,50,120), C.TextLight, 14)
	corner(tprod, 6)

	-- Область со списком (белый фон применён прямо на скролл, без лишней обёртки)
	local scroll = Instance.new("ScrollingFrame"); scroll.Name = "Items"
	scroll.Size = UDim2.new(1,-16,1,-172); scroll.Position = UDim2.fromOffset(8,104)
	scroll.BackgroundColor3 = C.Card; scroll.BackgroundTransparency = 0.08; scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = C.PurpleDark
	scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.Parent = panel
	corner(scroll, 8); stroke(scroll, C.CardStroke, 1.5, 0)
	local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(280,90)
	gl.CellPadding = UDim2.fromOffset(10,10); gl.SortOrder = Enum.SortOrder.LayoutOrder
	local gpad = Instance.new("UIPadding"); gpad.PaddingLeft = UDim.new(0,8); gpad.PaddingTop = UDim.new(0,8)
	gpad.Parent = scroll; gl.Parent = scroll
end

-- ══════════════════════════════════════════════════════════════
--  10. BOOST INDICATOR
-- ══════════════════════════════════════════════════════════════
do
	local g = scrGui("BoostIndicator", 122)
	local row = frame("BoostRow", g, UDim2.fromOffset(400,36), UDim2.new(0,10,1,-114), Color3.new(0,0,0), 1)
	local ul = Instance.new("UIListLayout"); ul.FillDirection = Enum.FillDirection.Horizontal
	ul.Padding = UDim.new(0,6); ul.SortOrder = Enum.SortOrder.LayoutOrder
	ul.VerticalAlignment = Enum.VerticalAlignment.Center; ul.Parent = row
end

-- ══════════════════════════════════════════════════════════════
--  11. REEF DIVER INVENTORY — синий акцент
-- ══════════════════════════════════════════════════════════════
do
	local AC = C.Blue
	local g = scrGui("ReefDiverInventory", 125)
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local mf = frame("MainFrame", g, UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0), 1)

	-- Константы (должны совпадать с CustomInventory.client.lua)
	-- HRC теперь = 8 — единый хотбар (удочки + рыбы), не только удочки
	local SS, SG, SP, HRC = 60, 6, 8, 8
	local hotbarW = SP*2 + HRC*SS + (HRC-1)*SG
	local hotbarH = SP*2 + SS

	local hbg = frame("HotbarBG", mf, UDim2.fromOffset(hotbarW, hotbarH),
		UDim2.new(0.5, -hotbarW/2, 1, -(hotbarH+12)), AC, 0, RADIUS)
	stroke(hbg, C.BlueDark, 2, 0)

	for i = 1, HRC do
		local x = SP + (i-1)*(SS+SG)
		local sl = frame("Slot_"..i, hbg, UDim2.fromOffset(SS,SS), UDim2.fromOffset(x,SP), C.Card, 0.05, 8)
		stroke(sl, C.BlueDark, 1.5, 0.3)
		local ic = img("Icon", sl, UDim2.new(0.75,0,0.75,0), UDim2.fromScale(0.5,0.4))
		ic.AnchorPoint = Vector2.new(0.5,0.5); ic.Visible = false
		local nl = lbl("NameLabel", sl, "", UDim2.new(1,-4,0.5,0), UDim2.fromScale(0.5,0.55), C.Text, true)
		nl.AnchorPoint = Vector2.new(0.5,0.5); nl.Visible = false
		local num = lbl("Number", sl, tostring(i), UDim2.fromOffset(18,18), UDim2.fromOffset(4,4), C.TextDim, true)
		num.TextScaled = true; num.ZIndex = 3
		local eb = frame("EquipBar", sl, UDim2.new(0.7,0,0,3), UDim2.new(0.15,0,1,-5), AC, 0, 2)
		eb.Visible = false
		local b = btn("Button", sl, "", UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0))
		b.BackgroundTransparency = 1; b.ZIndex = 5
	end

	-- Кнопка переключения рюкзака (overflow-слотов)
	local fbtn = btn("BackpackToggle", mf, "🎒 ▲",
		UDim2.fromOffset(72, 42), UDim2.new(0.5, hotbarW/2+12, 1, -(hotbarH/2+21+12)),
		AC, C.White, 14)
	corner(fbtn, RADIUS); stroke(fbtn, C.BlueDark, 2, 0)

	-- Backpack Panel (overflow) — в v1 показывает только избыточных рыб (8+)
	local FSS = 66
	local FCOLS, FROWS = 5, 3
	local fpW = FCOLS*(FSS+SG)+SG + 200
	local fpH = FROWS*(FSS+SG)+SG + 52
	local fpCloseY = -(hotbarH+8)

	local fp = frame("BackpackPanel", mf, UDim2.fromOffset(fpW,fpH),
		UDim2.new(0.5,-fpW/2, 1, fpCloseY), AC, 0, RADIUS)
	fp.ClipsDescendants = false; fp.Visible = false
	stroke(fp, C.BlueDark, 2, 0)

	local fh = frame("Header", fp, UDim2.new(1,0,0,52), UDim2.new(), AC, 0, RADIUS)
	frame("HdrFix", fh, UDim2.new(1,0,0.5,0), UDim2.new(0,0,0.5,0), AC, 0)
	lbl("FishCount", fh, "0 fish", UDim2.new(0.45,0,1,0), UDim2.new(0.5,0,0,0), C.White, false, 13)
	local sh = lbl("SellHint", fh, "💬 Sell at Fish Merchant", UDim2.new(0.45,-10,1,0), UDim2.new(0.55,0,0,0), Color3.fromRGB(180,210,255), false, 11)
	sh.TextXAlignment = Enum.TextXAlignment.Right

	-- Сетка рыб
	local fgW = FCOLS*(FSS+SG)+SG
	local fgH = fpH - 52
	local fgf = Instance.new("ScrollingFrame"); fgf.Name = "FishGrid"
	fgf.Size = UDim2.fromOffset(fgW, fgH); fgf.Position = UDim2.fromOffset(0,52)
	fgf.BackgroundTransparency = 1; fgf.BorderSizePixel = 0
	fgf.ScrollBarThickness = 4; fgf.ScrollBarImageColor3 = C.BlueDark
	fgf.ScrollBarImageTransparency = 0.2; fgf.CanvasSize = UDim2.new(0,0,0,0)
	fgf.ScrollingDirection = Enum.ScrollingDirection.Y; fgf.ClipsDescendants = true
	fgf.Parent = fp
	local grid = frame("Grid", fgf, UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0), 1)
	local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(FSS,FSS)
	gl.CellPadding = UDim2.fromOffset(SG,SG); gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.HorizontalAlignment = Enum.HorizontalAlignment.Left; gl.Parent = grid
	local gp = Instance.new("UIPadding"); gp.PaddingLeft = UDim.new(0,SG); gp.PaddingTop = UDim.new(0,SG); gp.Parent = grid

	-- Detail Panel
	local dpW = fpW - fgW - 8
	local dp = frame("DetailPanel", fp, UDim2.fromOffset(dpW-8, fgH-8), UDim2.fromOffset(fgW+4, 56), C.Card, 0.08, 8)
	stroke(dp, C.CardStroke, 1.5, 0)

	local iconSize = 72
	local dIcon = img("Icon", dp, UDim2.fromOffset(iconSize, iconSize), UDim2.new(0.5,0,0,10))
	dIcon.AnchorPoint = Vector2.new(0.5,0)
	local dPlaceholder = frame("IconPlaceholder", dp, UDim2.fromOffset(iconSize,iconSize), UDim2.new(0.5,0,0,10), C.CardStroke, 0.3, 8)
	dPlaceholder.AnchorPoint = Vector2.new(0.5,0)
	lbl("PlaceholderText", dPlaceholder, "🐟", UDim2.fromScale(1,1), UDim2.new(), C.TextDim, true)

	local rowY = iconSize + 16
	local ROW_DEFS = {
		{"RowName",     "Name",     C.Text},
		{"RowRarity",   "Rarity",   C.Text},
		{"RowSize",     "Size",     C.Text},
		{"RowMutation", "Mutation", Color3.fromRGB(125,70,195)},
		{"RowValue",    "Value",    C.Gold},
		{"RowZone",     "Zone",     C.TextDim},
	}
	for ri, rd in ipairs(ROW_DEFS) do
		local row = frame(rd[1], dp, UDim2.new(1,-16,0,20), UDim2.fromOffset(8, rowY + (ri-1)*24), Color3.new(0,0,0), 1)
		lbl("Label", row, rd[2], UDim2.fromScale(0.45,1), UDim2.new(), C.TextDim, false, 11)
		local vl = lbl("Value", row, "—", UDim2.fromScale(0.55,1), UDim2.fromScale(0.45,0), rd[3], true, 11)
		vl.TextXAlignment = Enum.TextXAlignment.Right
	end
	lbl("Placeholder", dp, "Select a fish\nto see details", UDim2.fromScale(1,0.3), UDim2.fromScale(0,0.35), C.TextDim, false, 12).TextWrapped = true
end

-- ══════════════════════════════════════════════════════════════
--  12. NPC DIALOG GUI — тeal-акцент, Grow a Garden стиль
-- ══════════════════════════════════════════════════════════════
do
	local AC = C.Teal
	local g = scrGui("NPCDialogGui", 135); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.45; dim.AutoButtonColor = false

	-- Вертикальная панель по центру экрана, тёмное стекло
	local panel = frame("Panel", g, UDim2.fromOffset(320,420), UDim2.new(0.5,0,0.5,0), C.Card, 0.08, 12)
	panel.AnchorPoint = Vector2.new(0.5,0.5); stroke(panel, C.CardStroke, 1.5, 0.2)

	-- Portrait (вверху, по центру)
	local portrait = frame("Portrait", panel, UDim2.fromOffset(120,120), UDim2.new(0.5,-60,0,16), C.Card, 0.08, 8)
	stroke(portrait, C.CardStroke, 2, 0.1)
	local pIcon = lbl("PortraitIcon", portrait, "🧑", UDim2.fromScale(1,1), UDim2.new(), C.Text, true)
	pIcon.TextScaled = true

	-- Name label (под портретом)
	local nameLabel = lbl("NameLabel", panel, "NPC", UDim2.new(1,-24,0,28), UDim2.fromOffset(12,144), C.Text, true, 17)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center

	-- Dialog text (под именем)
	local dialogText = lbl("DialogText", panel, "", UDim2.new(1,-24,0,110), UDim2.fromOffset(12,178), C.Text, false, 15)
	dialogText.TextXAlignment = Enum.TextXAlignment.Left
	dialogText.TextYAlignment = Enum.TextYAlignment.Top
	dialogText.TextScaled = false

	-- ClickArea прозрачный поверх панели для продвижения диалога
	local ca = btn("ClickArea", panel, "", UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0))
	ca.BackgroundTransparency = 1; ca.ZIndex = 1

	-- Кнопки выбора — вертикальный стек крупных кнопок внизу панели
	local choicesRow = frame("ChoicesRow", panel, UDim2.new(1,-24,0,96), UDim2.new(0,12,1,-108), Color3.new(0,0,0), 1)
	local c1 = btn("Choice1", choicesRow, "Yes!", UDim2.new(1,0,0,42), UDim2.new(0,0,0,0), C.Green, C.White, 15)
	corner(c1, BRAD); stroke(c1, C.GreenDark, 1.5, 0)
	local c2 = btn("Choice2", choicesRow, "Maybe later", UDim2.new(1,0,0,42), UDim2.new(0,0,0,54), C.CloseBtn, C.White, 15)
	corner(c2, BRAD); stroke(c2, Color3.fromRGB(170,40,40), 1.5, 0)
	choicesRow.Visible = false
end

-- ══════════════════════════════════════════════════════════════
--  13. SELL PANEL — teal
-- ══════════════════════════════════════════════════════════════
do
	local AC = C.Teal
	local g = scrGui("SellPanel", 140); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.5; dim.AutoButtonColor = false

	local panel = frame("Panel", g, UDim2.fromOffset(480,420), UDim2.new(0.5,0,0.5,0), AC, 0, RADIUS)
	panel.AnchorPoint = Vector2.new(0.5,0.5); stroke(panel, C.TealDark, 2, 0)

	local hdr = brightHeader(panel, 50, AC, C.TealDark)
	lbl("Title", panel, "🐟  Sell Fish", UDim2.new(0.5,0,0,50), UDim2.new(0,14,0,0), C.White, true, 20)
	local bal = lbl("BalanceLabel", panel, "🪙 ---", UDim2.new(0.3,0,0,50), UDim2.new(0.52,0,0,0), C.Gold, true, 16)
	bal.TextXAlignment = Enum.TextXAlignment.Right
	closeX(panel)

	-- Подсказка: продать всё или только рыбу в руке
	lbl("SellHint2", panel, "Select a fish to sell it alone, or sell everything at once.",
		UDim2.new(1,-16,0,18), UDim2.fromOffset(8,58), C.TextDim, false, 11)

	local fl = Instance.new("ScrollingFrame"); fl.Name = "FishList"
	fl.Size = UDim2.new(1,-16,1,-134); fl.Position = UDim2.fromOffset(8,78)
	fl.BackgroundColor3 = C.Card; fl.BackgroundTransparency = 0.08; fl.BorderSizePixel = 0
	fl.ScrollBarThickness = 4; fl.ScrollBarImageColor3 = C.TealDark
	fl.CanvasSize = UDim2.new(0,0,0,0); fl.ScrollingDirection = Enum.ScrollingDirection.Y
	fl.Parent = panel
	corner(fl, 8); stroke(fl, C.CardStroke, 1.5, 0)
	local ul = Instance.new("UIListLayout"); ul.Padding = UDim.new(0,4)
	ul.SortOrder = Enum.SortOrder.LayoutOrder
	local lpad = Instance.new("UIPadding"); lpad.PaddingLeft = UDim.new(0,6); lpad.PaddingTop = UDim.new(0,6)
	lpad.Parent = fl; ul.Parent = fl

	local sb = frame("SummaryBar", panel, UDim2.new(1,-16,0,52), UDim2.new(0,8,1,-60), C.TealDark, 0, 8)
	stroke(sb, C.TealDarker, 1.5, 0)
	lbl("TotalValue", sb, "Selected: 🪙 0", UDim2.fromScale(0.42,1), UDim2.new(), C.White, true, 15)
	local ss = btn("SellSelected", sb, "✓ Sell Held Fish", UDim2.fromOffset(148,38), UDim2.fromOffset(2,7), C.Green, C.White, 13)
	corner(ss, BRAD); stroke(ss, C.GreenDark, 1.5, 0)
	local sa = btn("SellAll", sb, "⚡ Sell All", UDim2.fromOffset(110,38), UDim2.fromOffset(154,7), C.Orange, C.White, 13)
	corner(sa, BRAD)
end

-- ══════════════════════════════════════════════════════════════
--  14. EXPEDITION PANEL — синий
-- ══════════════════════════════════════════════════════════════
do
	local AC = C.Blue
	local g = scrGui("ExpeditionPanel", 141); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.45; dim.AutoButtonColor = false

	-- Тёмное стекло вместо сплошной синей плашки — в стиле остального UI
	local panel = frame("Panel", g, UDim2.fromOffset(580,460), UDim2.new(0.5,0,0.5,0), C.Card, 0.06, RADIUS)
	panel.AnchorPoint = Vector2.new(0.5,0.5); stroke(panel, C.CardStroke, 1.5, 0.15)

	local hdr = brightHeader(panel, 50, AC, C.BlueDark)
	lbl("Title", panel, "🚤  Expeditions", UDim2.new(0.5,0,0,50), UDim2.new(0,14,0,0), C.White, true, 20)
	local bal = lbl("BalanceLabel", panel, "🪙 ---", UDim2.new(0.3,0,0,50), UDim2.new(0.52,0,0,0), C.Gold, true, 16)
	bal.TextXAlignment = Enum.TextXAlignment.Right
	closeX(panel)

	-- Три вертикальные карточки в стиле карточек удочек из магазина (RodGrid)
	local sc = frame("SlotContainer", panel, UDim2.new(1,-16,1,-118), UDim2.fromOffset(8,58), Color3.fromRGB(14,16,22), 0.15, 8)
	stroke(sc, C.CardStroke, 1.5, 0.2)
	local hl = Instance.new("UIListLayout")
	hl.FillDirection = Enum.FillDirection.Horizontal
	hl.Padding = UDim.new(0,14)
	hl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hl.VerticalAlignment = Enum.VerticalAlignment.Center
	hl.SortOrder = Enum.SortOrder.LayoutOrder
	hl.Parent = sc

	local SLOT_INFO = {
		{ icon = "🐠", title = "Short Voyage",  duration = "1 hour",
		  desc = "A quick dive just offshore. Low risk, modest haul — perfect for a fast top-up between sessions.",
		  reward = "2-4 fish · ×1 coins · up to Common" },
		{ icon = "🐟", title = "Medium Voyage", duration = "4 hours",
		  desc = "Your sub ventures into deeper currents. More fish, better coins, and a real shot at a mutation.",
		  reward = "4-8 fish · ×3 coins · up to Rare" },
		{ icon = "🐡", title = "Long Voyage 🔒", duration = "8 hours",
		  desc = "An extended deep-sea expedition with the richest haul. Requires the Extra AFK Slot gamepass.",
		  reward = "6-12 fish · ×8 coins · up to Epic" },
	}
	for i = 1, 3 do
		local info = SLOT_INFO[i]
		local sl = frame("Slot"..i, sc, UDim2.fromOffset(168, 340), UDim2.new(), C.Card, 0.05, 10)
		sl.Name = "Slot"..i
		sl.LayoutOrder = i
		stroke(sl, C.Blue, 1.5, 0.35)

		-- Иконка-плейсхолдер сверху (карточка как у удочек) — крупный эмодзи,
		-- заменяемый позже на реальный рендер субмарины/маршрута
		local iconHolder = frame("IconHolder", sl, UDim2.new(1,-16,0,72), UDim2.fromOffset(8,10), Color3.fromRGB(22,26,34), 0, 8)
		local iconLbl = lbl("SlotIcon", iconHolder, info.icon, UDim2.fromScale(1,1), UDim2.new(), C.Text, true)
		iconLbl.TextScaled = true

		lbl("SlotTitle", sl, info.title, UDim2.new(1,-16,0,18), UDim2.fromOffset(8,86), C.White, true, 14)
		lbl("SlotDuration", sl, "⏱ "..info.duration, UDim2.new(1,-16,0,14), UDim2.fromOffset(8,104), Color3.fromRGB(140,200,255), false, 11)

		-- Описание того, что делает экспедиция — флейвор-текст, не только цифры
		local descLbl = lbl("SlotDesc", sl, info.desc, UDim2.new(1,-16,0,80), UDim2.fromOffset(8,120), Color3.fromRGB(190,205,225), false, 10)
		descLbl.TextWrapped = true; descLbl.TextYAlignment = Enum.TextYAlignment.Top; descLbl.TextScaled = false

		lbl("SlotReward", sl, info.reward, UDim2.new(1,-16,0,28), UDim2.fromOffset(8,202), Color3.fromRGB(255,210,90), false, 10).TextWrapped = true

		lbl("SlotStatus", sl, "Ready", UDim2.new(1,-16,0,16), UDim2.fromOffset(8,234), Color3.fromRGB(140,200,255), false, 11)

		local stb = btn("StartBtn", sl, "▶ Send", UDim2.new(1,-16,0,30), UDim2.new(0,8,1,-40), C.Green, C.White, 13)
		corner(stb, BRAD); stroke(stb, C.GreenDark, 1, 0)
		local ctb = btn("CollectBtn", sl, "⬇ Collect", UDim2.new(1,-16,0,30), UDim2.new(0,8,1,-40), C.Orange, C.White, 13)
		corner(ctb, BRAD); ctb.Visible = false
		-- Подсветка активной экспедиции (цвет/фон меняется скриптом при старте)
		local glow = stroke(sl, Color3.fromRGB(255,210,90), 3, 1); glow.Name = "ActiveGlow"
	end

	lbl("TimerLabel", panel, "", UDim2.new(1,-16,0,32), UDim2.new(0,8,1,-44), Color3.fromRGB(200,220,255), false, 14)
end

-- ══════════════════════════════════════════════════════════════
--  15. REBIRTH PANEL — фиолетовый
-- ══════════════════════════════════════════════════════════════
do
	local AC = C.Purple
	local g = scrGui("RebirthPanel", 142); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.45; dim.AutoButtonColor = false

	-- Тёмное стекло вместо сплошной фиолетовой плашки — в стиле остального UI
	local panel = frame("Panel", g, UDim2.fromOffset(460,400), UDim2.new(0.5,0,0.5,0), C.Card, 0.06, RADIUS)
	panel.AnchorPoint = Vector2.new(0.5,0.5); stroke(panel, AC, 1.5, 0.15)

	local hdr = brightHeader(panel, 50, AC, C.PurpleDark)
	lbl("Title", panel, "🌀  Rebirth", UDim2.new(0.75,0,0,50), UDim2.new(0,14,0,0), C.White, true, 20)
	closeX(panel)

	local desc = lbl("RebirthDesc", panel,
		"Reset your progress and start again — but this time you'll be stronger.\nEach rebirth multiplies your fish value permanently.",
		UDim2.new(1,-24,0,40), UDim2.fromOffset(12,58), C.TextDim, false, 13)
	desc.TextWrapped = true; desc.TextYAlignment = Enum.TextYAlignment.Top

	-- Тёмная карточка со статистикой
	local rs = frame("RebirthStats", panel, UDim2.new(1,-24,0,86), UDim2.fromOffset(12,102), Color3.fromRGB(14,16,22), 0.15, 8)
	stroke(rs, C.CardStroke, 1.5, 0.2)
	local statNames = {"CurrentCoins","TotalCatch","RebirthCount"}
	local statLabels = {"🪙 Coins","🐟 Total Caught","🌀 Rebirths"}
	for i, sn in ipairs(statNames) do
		local row = frame(sn, rs, UDim2.new(1,-12,0,24), UDim2.fromOffset(6,(i-1)*28+4), Color3.new(0,0,0), 1)
		lbl("Label", row, statLabels[i], UDim2.fromScale(0.55,1), UDim2.new(), C.TextDim, false, 12)
		local v = lbl("Value", row, "—", UDim2.fromScale(0.45,1), UDim2.fromScale(0.55,0), C.Text, true, 12)
		v.TextXAlignment = Enum.TextXAlignment.Right
	end

	-- Карточка с условиями для следующего rebirth
	local rq = frame("Requirements", panel, UDim2.new(1,-24,0,58), UDim2.fromOffset(12,192), Color3.fromRGB(40,24,64), 0.08, 8)
	stroke(rq, Color3.fromRGB(160,100,230), 1.5, 0.2)
	lbl("ReqTitle", rq, "Requirement for next Rebirth", UDim2.new(1,-12,0,18), UDim2.fromOffset(6,4), Color3.fromRGB(220,200,255), true, 11)
	local rqv = lbl("ReqValue", rq, "🪙 Need 50,000 coins", UDim2.new(1,-12,0,22), UDim2.fromOffset(6,24), C.White, true, 14)
	local rqr = lbl("ReqReward", rq, "Reward: ...", UDim2.new(1,-12,0,14), UDim2.fromOffset(6,44), Color3.fromRGB(200,180,255), false, 10)

	local rb = btn("ConfirmRebirth", panel, "⚡ Rebirth Now!", UDim2.fromOffset(220,46), UDim2.new(0.5,-110,1,-102), C.Green, C.White, 17)
	corner(rb, BRAD); stroke(rb, C.GreenDark, 2, 0)
	local cb = btn("CancelBtn", panel, "Cancel", UDim2.fromOffset(120,36), UDim2.new(0.5,-60,1,-50), C.CloseBtn, C.White, 14)
	corner(cb, BRAD); stroke(cb, Color3.fromRGB(170,40,40), 1.5, 0)
end

-- ══════════════════════════════════════════════════════════════
--  16. FISH DEX PANEL — тёмно-синий
-- ══════════════════════════════════════════════════════════════
do
	local AC = C.Navy
	local g = scrGui("FishDexPanel", 143); g.Enabled = false

	local dim = btn("Dim", g, "", UDim2.fromScale(1,1), UDim2.new(), Color3.new(0,0,0))
	dim.BackgroundTransparency = 0.5; dim.AutoButtonColor = false

	local panel = frame("Panel", g, UDim2.fromOffset(580,460), UDim2.new(0.5,0,0.5,0), AC, 0, RADIUS)
	panel.AnchorPoint = Vector2.new(0.5,0.5); stroke(panel, C.NavyDark, 2, 0)

	local hdr = brightHeader(panel, 50, AC, C.NavyDark)
	lbl("Title", panel, "📖  Fish Collection", UDim2.new(0.55,0,0,50), UDim2.new(0,14,0,0), C.White, true, 20)
	lbl("ProgressLabel", panel, "0 / 0", UDim2.new(0.22,0,0,50), UDim2.new(0.58,0,0,0), Color3.fromRGB(180,200,255), true, 14)
	closeX(panel)

	local pb = frame("ProgressBar", panel, UDim2.new(1,-16,0,12), UDim2.fromOffset(8,58), Color3.fromRGB(20,40,90), 0, 6)
	stroke(pb, C.NavyDark, 1, 0)
	local pbf = frame("Fill", pb, UDim2.new(0,0,1,0), UDim2.new(), Color3.fromRGB(80,160,255), 0, 6)
	pbf.Name = "Fill"

	local dg = Instance.new("ScrollingFrame"); dg.Name = "DexGrid"
	dg.Size = UDim2.new(1,-16,1,-84); dg.Position = UDim2.fromOffset(8,76)
	dg.BackgroundColor3 = C.Card; dg.BackgroundTransparency = 0.08; dg.BorderSizePixel = 0
	dg.ScrollBarThickness = 4; dg.ScrollBarImageColor3 = Color3.fromRGB(80,120,200)
	dg.CanvasSize = UDim2.new(0,0,0,0); dg.ScrollingDirection = Enum.ScrollingDirection.Y
	dg.Parent = panel
	corner(dg, 8); stroke(dg, C.CardStroke, 1.5, 0)
	local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(120,100)
	gl.CellPadding = UDim2.fromOffset(8,8); gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.HorizontalAlignment = Enum.HorizontalAlignment.Left; gl.Parent = dg
	local gp = Instance.new("UIPadding"); gp.PaddingLeft = UDim.new(0,8); gp.PaddingTop = UDim.new(0,8); gp.Parent = dg
end

-- Удаляем тестовые GUI если остались
do
	local old = StarterGui:FindFirstChild("TestButtons")
	if old then old:Destroy() end
end

-- ══════════════════════════════════════════════════════════════
print("✅ ReefDiver UIBuilder complete!")
print("   GUIs in StarterGui:")
local names = {"MainHUD","FishingGui","EventBanner","AnnounceBanner","ComboDisplay",
	"ShopGui","DailyRewardGui","ZoneMenu","MonetizationShop","BoostIndicator",
	"ReefDiverInventory","NPCDialogGui",
	"SellPanel","ExpeditionPanel","RebirthPanel","FishDexPanel"}
for _, n in ipairs(names) do
	local exists = StarterGui:FindFirstChild(n) ~= nil
	print("   " .. (exists and "✓" or "✗") .. " " .. n)
end
print("   Find ImageLabel with Image=\"\" and upload your images (rbxassetid://...)")

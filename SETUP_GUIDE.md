# 🌊 Reef Diver — Гайд по установке и запуску через Rojo

## Что такое Rojo и зачем он нужен

Rojo — инструмент синхронизации: ты пишешь Lua-код в любом редакторе (VS Code, Sublime), а Rojo автоматически отображает папки и файлы в иерархию Roblox Studio в реальном времени. Никакого copy-paste скриптов вручную.

---

## Часть 1 — Установка Rojo

### 1.1 Установить Rojo CLI (инструмент командной строки)

**Способ A — через Foreman (рекомендуется):**
```bash
# Установить Foreman (менеджер Roblox-инструментов)
# https://github.com/Roblox/foreman/releases
# Скачай foreman-win64.zip (Windows) или foreman-macos (macOS)
# Добавь в PATH

# Создай файл foreman.toml в корне проекта:
[tools]
rojo = { source = "rojo-rbx/rojo", version = "7" }

# Установить:
foreman install
```

**Способ B — прямой скачать:**
```
https://github.com/rojo-rbx/rojo/releases
```
Скачай `rojo-win64.exe` (Windows) или `rojo-macos` (macOS).  
Переименуй в `rojo` и добавь папку в PATH.

**Проверка установки:**
```bash
rojo --version
# Должно вывести: rojo 7.x.x
```

### 1.2 Установить плагин Rojo в Roblox Studio

1. Открой Roblox Studio
2. Перейди: **Plugins → Manage Plugins → Search**
3. Найди **"Rojo"** (автор: Roblox)
4. Нажми **Install**

Или установить вручную через `.rbxm`:
```
https://github.com/rojo-rbx/rojo/releases
# Скачай rojo.rbxm → перетащи в Studio
```

---

## Часть 2 — Структура проекта

```
ReefDiver/
├── default.project.json          ← Главный конфиг Rojo
└── src/
    ├── ReplicatedStorage/
    │   ├── Modules/
    │   │   ├── GameConfig.lua     ← Все числовые константы
    │   │   ├── FishData.lua       ← 20 видов рыб
    │   │   ├── RodData.lua        ← 10 удочек
    │   │   └── Strings.lua        ← Все строки UI
    │   └── Remotes/
    │       └── RemoteSetup.lua    ← Создание RemoteEvent/Function
    │
    ├── ServerScriptService/
    │   ├── ServerMain.server.lua  ← Главный сервер-скрипт
    │   ├── Services/
    │   │   ├── DataService.lua    ← DataStore (сохранение)
    │   │   ├── FishingService.lua ← Логика рыбалки
    │   │   ├── AnnouncementService.lua
    │   │   └── EventService.lua   ← Случайные события
    │   └── Systems/
    │       └── NPCStubs.server.lua ← Заглушки NPC
    │
    ├── StarterGui/
    │   └── GUIStubs.client.lua    ← Все GUI заглушки
    │
    └── StarterPlayerScripts/
        ├── FishingMinigame.client.lua ← Мини-игра рыбалки
        ├── HUDController.client.lua   ← HUD (монеты, зона, удочка)
        └── ShopController.client.lua  ← Магазин удочек
```

### Как Rojo читает файлы

| Файл / папка | Что создаётся в Roblox |
|---|---|
| `foo.server.lua` | Script (ServerScript) |
| `foo.client.lua` | LocalScript |
| `foo.lua` | ModuleScript |
| `папка/` | Folder или соответствующий Service |

---

## Часть 3 — Запуск синхронизации

### 3.1 Запустить Rojo-сервер

```bash
# Перейти в папку проекта
cd /путь/к/ReefDiver

# Запустить сервер (оставь терминал открытым)
rojo serve
```

Ты увидишь:
```
Rojo server started!
Listening on port 34872
```

### 3.2 Подключиться из Roblox Studio

1. Открой Roblox Studio (создай пустой Place)
2. Нажми **Plugins → Rojo** (кнопка в тулбаре)
3. Нажми **Connect** (порт 34872 по умолчанию)
4. Studio скажет **"Connected"**

Теперь все файлы из `src/` автоматически появятся в Studio.

### 3.3 Автосинхронизация

После подключения любое сохранение файла (Ctrl+S) мгновенно обновляет Studio. Перезапускать Rojo не нужно.

---

## Часть 4 — Первый запуск игры

### 4.1 Проверь структуру в Studio

После подключения Rojo ты должен увидеть:
```
ServerScriptService/
  ServerMain          ← Script
  Services/
    DataService       ← ModuleScript
    FishingService    ← ModuleScript
    AnnouncementService ← ModuleScript
    EventService      ← ModuleScript
  Systems/
    NPCStubs          ← Script

ReplicatedStorage/
  Modules/
    GameConfig        ← ModuleScript
    FishData          ← ModuleScript
    RodData           ← ModuleScript
    Strings           ← ModuleScript
  Remotes/
    RemoteSetup       ← ModuleScript

StarterGui/
  GUIStubs            ← LocalScript

StarterPlayer/
  StarterPlayerScripts/
    FishingMinigame   ← LocalScript
    HUDController     ← LocalScript
    ShopController    ← LocalScript
```

### 4.2 Нажми Play (F5)

При первом запуске в Output должно появиться:
```
[ReefDiver] ServerMain инициализирован ✓
[ReefDiver] NPC Stubs инициализированы ✓
[ReefDiver] GUI Stubs созданы ✓
[ReefDiver] ⚠ PLACEHOLDER: Замени Part-модели на реальные модели NPC
[ReefDiver] ⚠ PLACEHOLDER: Замени Image='' на реальные rbxassetid://
```

Предупреждения ⚠ — это нормально. Это напоминания о заглушках.

---

## Часть 5 — Заглушки и что заменять

### 5.1 Модели NPC (заглушки = цветные Part)

Сейчас NPC — это просто цветные прямоугольники в `workspace/Village/`:
- 🟡 **RodMaster** — жёлтый
- 🔵 **FishMerchant** — синий
- 🟣 **ElderDiver** — фиолетовый
- 🟢 **ResearchSubmarine** — бирюзовый
- 🔴 **Collector** — красный

**Когда будет готова реальная модель:**
1. Открой `NPCStubs.server.lua`
2. Найди секцию с нужным NPC
3. Замени создание `Instance.new("Part")` на загрузку модели:
```lua
-- Было (заглушка):
local npcPart = Instance.new("Part")

-- Стало (реальная модель):
local model = game:GetService("InsertService"):LoadAsset(ASSET_ID):GetChildren()[1]
model.Name = cfg.id
model:SetPrimaryPartCFrame(cfg.position)
model.Parent = villageFolder
local npcPart = model.PrimaryPart  -- подключи ProximityPrompt к PrimaryPart
```

### 5.2 Изображения рыб

В `FishData.lua` у каждой рыбы поле `image = ""`.

**Когда загрузишь спрайт рыбы:**
```lua
-- Было:
image = "",

-- Стало:
image = "rbxassetid://1234567890",
```

### 5.3 Иконки удочек

В `RodData.lua` у каждой удочки поле `icon = ""`.

Замени на `icon = "rbxassetid://XXXXXX"` после загрузки иконки.

### 5.4 GUI ImageLabel (фоны и кнопки)

В `GUIStubs.client.lua` все `makeImageLabel()` создают `Image = ""`.

Когда будет готов артворк:
```lua
-- Найди в GUIStubs.client.lua нужный элемент по имени
-- и замени Image через Studio или напрямую в коде:
img.Image = "rbxassetid://XXXXXX"
```

### 5.5 Звуки

В `FishingMinigame.client.lua` функция `playSound(name)` — заглушка.  
После добавления звуков в SoundService:
```lua
-- Замени тело функции:
local function playSound(name)
    local snd = SoundService:FindFirstChild(name)
    if snd then snd:Play() end
end
```

### 5.6 Позиции NPC в мире

В `NPCStubs.server.lua` все `position = CFrame.new(X, Y, Z)` — примерные.  
После постройки карты деревни — обнови координаты.

---

## Часть 6 — Рабочий процесс (ежедневно)

```bash
# 1. Открыть терминал в папке проекта
cd /путь/к/ReefDiver

# 2. Запустить Rojo
rojo serve

# 3. Открыть Roblox Studio → Plugins → Rojo → Connect

# 4. Редактировать .lua файлы в VS Code / любом редакторе

# 5. Ctrl+S → изменения мгновенно в Studio

# 6. F5 в Studio для тестирования
```

**Рекомендуемые расширения для VS Code:**
- `Rojo` (официальное) — подсветка синхронизации
- `Luau LSP` — автодополнение Roblox API
- `Selene` — линтер Lua

---

## Часть 7 — Публикация

### Перед публикацией:
1. Отключи Rojo (нажми Disconnect в Studio)
2. Проверь Output на ошибки
3. Убедись что все DataStore тестированы
4. Удали или скрой `TestButtons` GUI (в `GUIStubs.client.lua`)

### Публикация:
```
File → Publish to Roblox
```

---

## Часть 8 — Частые ошибки

| Ошибка | Решение |
|---|---|
| `rojo serve` не запускается | Проверь PATH, перезапусти терминал |
| Studio не видит порт | Убедись rojo запущен, попробуй перезайти в Studio |
| Скрипты дублируются | Не добавляй скрипты вручную если Rojo их уже синхронизирует |
| `require` не находит модуль | Проверь путь: `ReplicatedStorage.Modules.GameConfig` |
| DataStore ошибки при тесте | Включи `API Services` в Game Settings → Security |
| MessagingService ошибки | Работает только в Published game, в Studio — нормально игнорировать |

---

## Чеклист готовности к MVP

- [ ] Rojo синхронизирован, все скрипты видны в Studio
- [ ] F5 — нет красных ошибок в Output
- [ ] NPC появляются в деревне (заглушки Part)
- [ ] Мини-игра запускается (через TestButtons → OpenShop)
- [ ] DataStore работает (включён API Services)
- [ ] Серверные объявления видны в Chat
- [ ] Заменить: image в FishData на реальные Asset ID
- [ ] Заменить: icon в RodData на реальные Asset ID  
- [ ] Заменить: Part-заглушки NPC на реальные модели
- [ ] Удалить TestButtons перед публикацией

---

*Reef Diver — GDD v1.0 | Rojo Setup Guide*

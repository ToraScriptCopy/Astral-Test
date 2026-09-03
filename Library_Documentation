# Astral UI Library - Documentation
## Русская документация + English Documentation

Версия: **1.5**

---

# 🇷🇺 РУССКАЯ ДОКУМЕНТАЦИЯ

## 1. О библиотеке

**Astral UI Library** - это Lua UI-библиотека для Roblox с интерфейсом в стиле Wind UI / Astral Hub.

Библиотека отвечает только за пользовательский интерфейс. Она не содержит готовых игровых функций, ESP, silent aim, aimbot и т.п. Любую игровую логику разработчик подключает самостоятельно через `Callback`.

Главные особенности:

- компактные боковые вкладки, которые в неактивном состоянии показывают только иконку;
- активная вкладка плавно раскрывается и показывает название;
- верхние subtabs / категории внутри вкладки;
- секции в две колонки;
- автоматический scrolling без видимого scrollbar;
- Toggle, Button, Slider, ColorPicker, Dropdown, MultiDropdown, Bind;
- дополнительные элементы Input, Paragraph, Divider;
- Popup / modal dialogs;
- красивые уведомления Notify;
- Red, Blue и Green темы;
- полностью пользовательские темы;
- наборы Lucide-style, Roblox, Material и Symbols иконок;
- configurable menu key;
- отдельный Mouse Unlock bind;
- Config API с памятью процесса и executor file API, когда он доступен.

---

## 2. Подключение библиотеки

Библиотека рассчитана на классический стиль загрузки:

```lua
local Library = loadstring(game:HttpGet("YOUR_RAW_MAIN_LUA_URL"))()
```

После загрузки создаётся Window:

```lua
local Window = Library:CreateWindow({
    Name = "My Script",
    Author = "YourName",
})
```

---

## 3. CreateWindow

### Синтаксис

```lua
local Window = Library:CreateWindow({
    Name = "Astral",
    Author = "YourName",
    Size = UDim2.fromOffset(760, 500),

    ToggleKey = Enum.KeyCode.KeypadSeven,
    UnlockMouseKey = Enum.KeyCode.LeftAlt,

    -- Можно отключить bind:
    -- ToggleKey = nil,
    -- UnlockMouseKey = nil,

    ShowBindHint = true,
    Language = "ENG",
})
```

### Основные параметры

| Параметр | Тип | Описание |
|---|---|---|
| `Name` | string | Название GUI |
| `Author` | string | Подпись справа сверху |
| `Size` | UDim2 | Размер окна |
| `ToggleKey` | Enum.KeyCode / nil | Открытие/закрытие GUI |
| `UnlockMouseKey` | Enum.KeyCode / nil | Временное освобождение мыши |
| `ShowBindHint` | boolean | Показывать подсказку bind |
| `Language` | string | Текст языкового индикатора |

По умолчанию:

```lua
ToggleKey = Enum.KeyCode.KeypadSeven
UnlockMouseKey = Enum.KeyCode.LeftAlt
```

`nil` полностью отключает соответствующий bind.

---

# 4. Window API

### Toggle

```lua
Window:Toggle()
```

Переключает видимость окна.

### SetVisible

```lua
Window:SetVisible(true)
Window:SetVisible(false)
```

### Уничтожение

```lua
Window:Destroy()
```

### Работа с флагами

```lua
Window:SetFlag("MyFlag", true)

local value = Window:GetFlag("MyFlag")
```

### Уведомление

```lua
Window:Notify({
    Title = "Success",
    Content = "Настройка сохранена",
    Icon = Library:GetIcon("Lucide", "Check"),
    Duration = 3.5,
})
```

### Popup

```lua
local Popup = Window:Popup({
    Title = "Confirm",
    Content = "Продолжить?",
    Width = 360,
    Height = 190,

    Buttons = {
        {
            Name = "Yes",
            Value = true,
            Primary = true,
        },
        {
            Name = "No",
            Value = false,
        },
    },

    Callback = function(result)
        print("Result:", result)
    end,
})
```

Закрытие программно:

```lua
Popup:Close()
```

---

# 5. Tabs

Создание основной вкладки:

```lua
local Visuals = Window:CreateTab({
    Name = "Visuals",
    Icon = Library:GetIcon("Lucide", "Visuals"),
})
```

Иконка может быть:

```lua
Icon = "◉"
```

либо:

```lua
Icon = "rbxassetid://1234567890"
```

Внутри вкладки рекомендуется использовать subtabs.

---

# 6. Subtabs

```lua
local ESP = Visuals:CreateSubtab({
    Name = "ESP",
    Icon = Library:GetIcon("Lucide", "Eye"),
})

local Tracers = Visuals:CreateSubtab({
    Name = "Tracers",
    Icon = Library:GetIcon("Lucide", "Target"),
})
```

Неактивная subtab визуально сжимается до иконки, а активная раскрывается.

---

# 7. Sections

Секции автоматически строятся в две колонки.

```lua
local General = ESP:CreateSection({
    Name = "General",
    Side = "Left",
})

local VisualSettings = ESP:CreateSection({
    Name = "Visual",
    Side = "Right",
})
```

Доступны:

```lua
Side = "Left"
```

и:

```lua
Side = "Right"
```

---

# 8. Button

```lua
General:CreateButton({
    Name = "Test Button",

    Callback = function()
        print("Clicked")
    end,
})
```

Можно отключить стрелку:

```lua
General:CreateButton({
    Name = "Action",
    Arrow = false,
    Callback = function()
        print("Action")
    end,
})
```

---

# 9. Toggle

```lua
General:CreateToggle({
    Name = "Enabled",
    Flag = "Enabled",
    Default = false,

    Callback = function(value)
        print("Enabled:", value)
    end,
})
```

API:

```lua
local Toggle = General:CreateToggle(...)

Toggle:Set(true)
Toggle:Set(false)

local state = Toggle:Get()
```

---

# 10. Slider

```lua
General:CreateSlider({
    Name = "Speed",
    Flag = "Speed",
    Min = 0,
    Max = 100,
    Default = 25,
    Step = 1,
    Suffix = "%",
    Callback = function(value)
        print("Speed:", value)
    end,
})
```

Дробные значения:

```lua
General:CreateSlider({
    Name = "Multiplier",
    Min = 0.1,
    Max = 5,
    Default = 1,
    Step = 0.1,
    Decimals = 1,
    Suffix = "x",
})
```

API:

```lua
Slider:Set(50)
print(Slider:Get())
```

Можно использовать свой формат:

```lua
Format = function(value)
    return string.format("%.1fx", value)
end
```

---

# 11. ColorPicker

```lua
General:CreateColorPicker({
    Name = "Color",
    Flag = "Color",
    Default = Color3.fromRGB(255, 25, 92),

    Callback = function(color)
        print(color)
    end,
})
```

API:

```lua
Color:Set(Color3.fromRGB(0, 170, 255))

local current = Color:Get()
```

---

# 12. Dropdown

```lua
General:CreateDropdown({
    Name = "Mode",
    Flag = "Mode",

    Options = {
        "First",
        "Second",
        "Third",
    },

    Default = "First",

    Callback = function(value)
        print("Selected:", value)
    end,
})
```

API:

```lua
Dropdown:Set("Second")

local selected = Dropdown:Get()
```

---

# 13. MultiDropdown

```lua
General:CreateMultiDropdown({
    Name = "Features",
    Flag = "Features",

    Options = {
        "A",
        "B",
        "C",
    },

    Default = {
        "A",
        "C",
    },

    Callback = function(values)
        for _, value in ipairs(values) do
            print(value)
        end
    end,
})
```

API:

```lua
Multi:Set({"A", "B"})
local values = Multi:Get()
```

---

# 14. Bind

```lua
General:CreateBind({
    Name = "Test Bind",
    Flag = "TestBind",
    Default = Enum.KeyCode.F,

    Callback = function(binding)
        print("Pressed:", binding)
    end,
})
```

Bind поддерживает клавиши и mouse buttons.

Получение состояния:

```lua
local Bind = ...
print(Bind:IsDown())
```

Изменение:

```lua
Bind:Set(Enum.KeyCode.G)
```

---

# 15. Input

Новый текстовый элемент:

```lua
General:CreateInput({
    Name = "Username",
    Flag = "Username",
    Placeholder = "Enter username...",

    Callback = function(value)
        print(value)
    end,
})
```

---

# 16. Paragraph

Для описаний и небольших информационных блоков:

```lua
General:CreateParagraph({
    Title = "Information",
    Content = "Это описание секции или функции.",
})
```

---

# 17. Divider

```lua
General:CreateDivider()
```

---

# 18. Notify

Уведомления используют отдельный контейнер справа сверху.

```lua
Window:Notify({
    Title = "Saved",
    Content = "Config successfully saved",
    Icon = Library:GetIcon("Lucide", "Check"),
    Duration = 3,
})
```

Поддерживается:

```lua
Icon = "★"
```

или image asset.

---

# 19. Popup

Popup предназначен для подтверждений, предупреждений и небольших modal-окон.

```lua
Window:Popup({
    Title = "Warning",
    Content = "Этот параметр может изменить состояние вашего интерфейса.",

    Buttons = {
        {
            Name = "Continue",
            Value = "continue",
            Primary = true,
        },
        {
            Name = "Cancel",
            Value = "cancel",
        },
    },

    Callback = function(result)
        if result == "continue" then
            print("Continue")
        end
    end,
})
```

---

# 20. Иконки

Встроенные наборы:

```lua
Library.Icons.Lucide
Library.Icons.Roblox
Library.Icons.Material
Library.Icons.Symbols
```

Получение:

```lua
Library:GetIcon("Lucide", "Settings")
Library:GetIcon("Roblox", "Camera")
Library:GetIcon("Material", "Search")
Library:GetIcon("Symbols", "Star")
```

Можно передавать свои Unicode-символы:

```lua
Icon = "✦"
```

или image asset:

```lua
Icon = "rbxassetid://123456789"
```

---

# 21. Темы

Встроенные темы:

```lua
Library:SetTheme("Red")
Library:SetTheme("Blue")
Library:SetTheme("Green")
```

Red является основной темой библиотеки.

Можно применять тему через Window:

```lua
Window:SetTheme("Blue")
```

---

# 22. Custom Theme

Можно полностью изменить цвета.

```lua
Library:CreateTheme("Purple", {
    Background = Color3.fromRGB(12, 9, 18),
    Surface = Color3.fromRGB(20, 15, 28),
    Surface2 = Color3.fromRGB(27, 20, 38),
    Stroke = Color3.fromRGB(50, 38, 64),

    Text = Color3.fromRGB(245, 240, 255),
    SubText = Color3.fromRGB(170, 155, 190),
    Muted = Color3.fromRGB(105, 92, 120),

    Accent = Color3.fromRGB(185, 65, 255),
    Accent2 = Color3.fromRGB(210, 110, 255),
})

Library:SetTheme("Purple")
```

Либо можно быстро заменить только accent:

```lua
Library:SetAccentColor(Color3.fromRGB(255, 0, 200))
```

---

# 23. Hex colors

Есть helper:

```lua
local Red = Library:Hex("#ff195c")
local Blue = Library:Hex("3a84ff")
```

После этого:

```lua
Library:SetAccentColor(Red)
```

---

# 24. Menu bind

По умолчанию меню открывается/закрывается через Num7:

```lua
Enum.KeyCode.KeypadSeven
```

Изменение:

```lua
Window:SetToggleKey(Enum.KeyCode.F4)
```

Отключение:

```lua
Window:SetToggleKey(nil)
```

Также:

```lua
Window:SetToggleEnabled(false)
Window:SetToggleEnabled(true)
```

---

# 25. Mouse Unlock

По умолчанию:

```lua
Enum.KeyCode.LeftAlt
```

Установка собственного keybind:

```lua
Window:SetMouseUnlockKey(Enum.KeyCode.LeftControl)
```

Отключение:

```lua
Window:SetMouseUnlockKey(nil)
```

или:

```lua
Window:DisableMouseUnlock()
```

Система сохраняет текущее:

- `UserInputService.MouseBehavior`
- `UserInputService.MouseIconEnabled`

при начале unlock и восстанавливает значения после отпускания клавиши.

Это сделано для того, чтобы библиотека не держала камеру в принудительном состоянии постоянно.

---

# 26. Config

Config работает через Flags.

Пример:

```lua
General:CreateToggle({
    Name = "Enabled",
    Flag = "Enabled",
})

General:CreateSlider({
    Name = "Speed",
    Flag = "Speed",
    Min = 0,
    Max = 100,
    Default = 25,
})
```

Сохранение:

```lua
Library.Config:Save("default")
```

Загрузка:

```lua
Library.Config:Load("default")
```

Удаление:

```lua
Library.Config:Delete("default")
```

Список:

```lua
local configs = Library.Config:List()

for _, name in ipairs(configs) do
    print(name)
end
```

Логика хранения:

1. библиотека сохраняет config в memory;
2. если executor предоставляет file API, используется папка `AstralHub`;
3. формат файла - JSON.

---

# 27. Полезные значения Flags

Любой control с `Flag` автоматически добавляет значение:

```lua
Library.Flags["Enabled"]
Library.Flags["Speed"]
Library.Flags["Color"]
Library.Flags["Mode"]
```

Можно читать напрямую:

```lua
print(Library.Flags.Speed)
```

---

# 28. Полная структура интерфейса

Рекомендуемая архитектура:

```text
Window
 ├─ Tab
 │   ├─ Subtab
 │   │   ├─ Section Left
 │   │   │   ├─ Toggle
 │   │   │   ├─ Button
 │   │   │   └─ Slider
 │   │   └─ Section Right
 │   │       ├─ Dropdown
 │   │       ├─ ColorPicker
 │   │       └─ Bind
 │   └─ Subtab
 └─ Tab
     └─ Subtab
```

Такой подход лучше всего соответствует визуальной концепции библиотеки.

---

# 🇬🇧 ENGLISH DOCUMENTATION

## 1. About

**Astral UI Library** is a Roblox Lua UI framework inspired by Wind UI and the provided Astral-style layout.

The library is UI-only. It does not implement ESP, aimbot, silent aim or other gameplay logic. Developers connect their own logic through callbacks.

Main features:

- compact icon-first sidebar tabs;
- animated expansion for active tabs;
- subtabs / categories;
- two-column sections;
- invisible scrolling;
- Toggle, Button, Slider, ColorPicker, Dropdown, MultiDropdown and Bind;
- Input, Paragraph and Divider;
- notification system;
- modal popups;
- Red, Blue and Green themes;
- custom themes;
- Lucide-style, Roblox, Material and Symbols icon packs;
- configurable menu hotkey;
- configurable mouse-unlock bind;
- memory + executor-file config support.

---

## 2. Loading

```lua
local Library = loadstring(game:HttpGet("YOUR_RAW_MAIN_LUA_URL"))()
```

Create a window:

```lua
local Window = Library:CreateWindow({
    Name = "My Script",
    Author = "YourName",
})
```

---

## 3. CreateWindow

```lua
local Window = Library:CreateWindow({
    Name = "Astral",
    Author = "YourName",
    Size = UDim2.fromOffset(760, 500),

    ToggleKey = Enum.KeyCode.KeypadSeven,
    UnlockMouseKey = Enum.KeyCode.LeftAlt,

    ShowBindHint = true,
    Language = "ENG",
})
```

Main options:

| Option | Type | Description |
|---|---|---|
| `Name` | string | GUI title |
| `Author` | string | Header author text |
| `Size` | UDim2 | Window size |
| `ToggleKey` | Enum.KeyCode / nil | Menu toggle bind |
| `UnlockMouseKey` | Enum.KeyCode / nil | Temporary mouse-unlock bind |
| `ShowBindHint` | boolean | Shows bind hint in header |
| `Language` | string | Footer language label |

Default keys:

```lua
ToggleKey = Enum.KeyCode.KeypadSeven
UnlockMouseKey = Enum.KeyCode.LeftAlt
```

Use `nil` to disable either bind.

---

## 4. Window API

```lua
Window:Toggle()
Window:SetVisible(true)
Window:SetVisible(false)
Window:Destroy()
```

Flags:

```lua
Window:SetFlag("Enabled", true)

local value = Window:GetFlag("Enabled")
```

Notifications:

```lua
Window:Notify({
    Title = "Saved",
    Content = "Config saved successfully",
    Icon = Library:GetIcon("Lucide", "Check"),
    Duration = 3.5,
})
```

Popup:

```lua
local Popup = Window:Popup({
    Title = "Confirm",
    Content = "Continue?",

    Buttons = {
        {
            Name = "Yes",
            Value = true,
            Primary = true,
        },
        {
            Name = "No",
            Value = false,
        },
    },

    Callback = function(result)
        print(result)
    end,
})
```

---

## 5. Tabs and Subtabs

```lua
local Visuals = Window:CreateTab({
    Name = "Visuals",
    Icon = Library:GetIcon("Lucide", "Visuals"),
})

local ESP = Visuals:CreateSubtab({
    Name = "ESP",
    Icon = Library:GetIcon("Lucide", "Eye"),
})
```

Active tabs expand with animation. Inactive tabs collapse to their icon.

---

## 6. Sections

```lua
local Left = ESP:CreateSection({
    Name = "General",
    Side = "Left",
})

local Right = ESP:CreateSection({
    Name = "Visual",
    Side = "Right",
})
```

Both sides are automatically laid out in parallel columns.

---

## 7. Button

```lua
Left:CreateButton({
    Name = "Action",
    Callback = function()
        print("clicked")
    end,
})
```

Disable arrow:

```lua
Left:CreateButton({
    Name = "Action",
    Arrow = false,
})
```

---

## 8. Toggle

```lua
local Toggle = Left:CreateToggle({
    Name = "Enabled",
    Flag = "Enabled",
    Default = false,

    Callback = function(value)
        print(value)
    end,
})

Toggle:Set(true)
print(Toggle:Get())
```

---

## 9. Slider

```lua
local Slider = Left:CreateSlider({
    Name = "Speed",
    Flag = "Speed",

    Min = 0,
    Max = 100,
    Default = 25,

    Step = 1,
    Suffix = "%",

    Callback = function(value)
        print(value)
    end,
})
```

Decimal slider:

```lua
local Slider = Left:CreateSlider({
    Name = "Multiplier",
    Min = 0.1,
    Max = 5,
    Default = 1,
    Step = 0.1,
    Decimals = 1,
    Suffix = "x",
})
```

Custom display:

```lua
Format = function(value)
    return string.format("%.1fx", value)
end
```

---

## 10. ColorPicker

```lua
local Color = Left:CreateColorPicker({
    Name = "Accent",
    Flag = "Accent",
    Default = Color3.fromRGB(255, 25, 92),

    Callback = function(color)
        print(color)
    end,
})

Color:Set(Color3.fromRGB(0, 170, 255))
print(Color:Get())
```

---

## 11. Dropdown

```lua
local Mode = Left:CreateDropdown({
    Name = "Mode",
    Flag = "Mode",

    Options = {
        "First",
        "Second",
        "Third",
    },

    Default = "First",

    Callback = function(value)
        print(value)
    end,
})
```

API:

```lua
Mode:Set("Second")
print(Mode:Get())
```

---

## 12. MultiDropdown

```lua
local Features = Left:CreateMultiDropdown({
    Name = "Features",
    Flag = "Features",

    Options = {
        "A",
        "B",
        "C",
    },

    Default = {
        "A",
        "C",
    },
})
```

API:

```lua
Features:Set({"A", "B"})

local values = Features:Get()
```

---

## 13. Bind

```lua
local Bind = Left:CreateBind({
    Name = "Trigger",
    Flag = "Trigger",
    Default = Enum.KeyCode.F,

    Callback = function(binding)
        print(binding)
    end,
})
```

Change bind:

```lua
Bind:Set(Enum.KeyCode.G)
```

Read:

```lua
local current = Bind:Get()
```

Check held state:

```lua
print(Bind:IsDown())
```

---

## 14. Input

```lua
Left:CreateInput({
    Name = "Username",
    Flag = "Username",
    Placeholder = "Enter username...",

    Callback = function(value)
        print(value)
    end,
})
```

---

## 15. Paragraph

```lua
Left:CreateParagraph({
    Title = "Information",
    Content = "Description text goes here.",
})
```

---

## 16. Divider

```lua
Left:CreateDivider()
```

---

## 17. Icons

Available packs:

```lua
Library.Icons.Lucide
Library.Icons.Roblox
Library.Icons.Material
Library.Icons.Symbols
```

Examples:

```lua
Library:GetIcon("Lucide", "Settings")
Library:GetIcon("Roblox", "Camera")
Library:GetIcon("Material", "Search")
Library:GetIcon("Symbols", "Star")
```

Custom text icons are supported:

```lua
Icon = "✦"
```

Image assets are also supported:

```lua
Icon = "rbxassetid://123456789"
```

---

## 18. Themes

Built-in themes:

```lua
Library:SetTheme("Red")
Library:SetTheme("Blue")
Library:SetTheme("Green")
```

Red is the primary/default visual identity.

Window-level shortcut:

```lua
Window:SetTheme("Blue")
```

---

## 19. Custom Themes

Create a new theme:

```lua
Library:CreateTheme("Purple", {
    Background = Color3.fromRGB(12, 9, 18),
    Surface = Color3.fromRGB(20, 15, 28),
    Surface2 = Color3.fromRGB(27, 20, 38),
    Stroke = Color3.fromRGB(50, 38, 64),

    Text = Color3.fromRGB(245, 240, 255),
    SubText = Color3.fromRGB(170, 155, 190),
    Muted = Color3.fromRGB(105, 92, 120),

    Accent = Color3.fromRGB(185, 65, 255),
    Accent2 = Color3.fromRGB(210, 110, 255),
})

Library:SetTheme("Purple")
```

Quick accent change:

```lua
Library:SetAccentColor(Color3.fromRGB(255, 0, 200))
```

---

## 20. Hex Helper

```lua
local Red = Library:Hex("#ff195c")
local Blue = Library:Hex("3a84ff")
```

Then:

```lua
Library:SetAccentColor(Red)
```

---

## 21. Menu Toggle Bind

Default:

```lua
Enum.KeyCode.KeypadSeven
```

Change:

```lua
Window:SetToggleKey(Enum.KeyCode.F4)
```

Disable:

```lua
Window:SetToggleKey(nil)
```

Or:

```lua
Window:SetToggleEnabled(false)
Window:SetToggleEnabled(true)
```

---

## 22. Mouse Unlock

Default:

```lua
Enum.KeyCode.LeftAlt
```

Change:

```lua
Window:SetMouseUnlockKey(Enum.KeyCode.LeftControl)
```

Disable:

```lua
Window:SetMouseUnlockKey(nil)
```

or:

```lua
Window:DisableMouseUnlock()
```

The library stores the previous mouse state and restores it after release:

```text
MouseBehavior
MouseIconEnabled
```

The unlock mechanism is intentionally temporary so it does not continuously override a game's camera/controller state.

---

## 23. Config

Controls become persistent config values by assigning a `Flag`.

```lua
Left:CreateToggle({
    Name = "Enabled",
    Flag = "Enabled",
})

Left:CreateSlider({
    Name = "Speed",
    Flag = "Speed",
    Min = 0,
    Max = 100,
    Default = 25,
})
```

Save:

```lua
Library.Config:Save("default")
```

Load:

```lua
Library.Config:Load("default")
```

Delete:

```lua
Library.Config:Delete("default")
```

List:

```lua
local configs = Library.Config:List()

for _, name in ipairs(configs) do
    print(name)
end
```

The library uses in-memory storage first. When supported by the executor, it also writes JSON config files inside:

```text
AstralHub/
```

---

## 24. Flags

Any control with a `Flag` is available through:

```lua
Library.Flags
```

Example:

```lua
print(Library.Flags.Enabled)
print(Library.Flags.Speed)
print(Library.Flags.Color)
```

---

# 25. COMPLETE EXAMPLE / ПОЛНЫЙ ПРИМЕР

```lua
local Library = loadstring(game:HttpGet(
    "YOUR_RAW_MAIN_LUA_URL"
))()

-- Use the main Red identity.
Library:SetTheme("Red")

local Window = Library:CreateWindow({
    Name = "Astral",
    Author = "Example",
    Size = UDim2.fromOffset(780, 520),

    -- Num7 / Keypad7 opens and closes the menu.
    ToggleKey = Enum.KeyCode.KeypadSeven,

    -- Hold LeftAlt to temporarily release the mouse.
    UnlockMouseKey = Enum.KeyCode.LeftAlt,

    ShowBindHint = true,
    Language = "ENG",
})

----------------------------------------------------------------------
-- VISUALS
----------------------------------------------------------------------

local Visuals = Window:CreateTab({
    Name = "Visuals",
    Icon = Library:GetIcon("Lucide", "Visuals"),
})

local ESP = Visuals:CreateSubtab({
    Name = "ESP",
    Icon = Library:GetIcon("Lucide", "Eye"),
})

local ESPGeneral = ESP:CreateSection({
    Name = "General",
    Side = "Left",
})

local ESPVisual = ESP:CreateSection({
    Name = "Visual",
    Side = "Right",
})

ESPGeneral:CreateToggle({
    Name = "Enabled",
    Flag = "ESPEnabled",
    Default = true,

    Callback = function(value)
        print("ESP Enabled:", value)
    end,
})

ESPGeneral:CreateToggle({
    Name = "Show Name",
    Flag = "ShowName",
    Default = true,
})

ESPGeneral:CreateSlider({
    Name = "Max Distance",
    Flag = "MaxDistance",
    Min = 50,
    Max = 5000,
    Default = 1000,
    Step = 50,
    Suffix = " studs",
})

ESPGeneral:CreateDropdown({
    Name = "Mode",
    Flag = "Mode",
    Options = {
        "Box",
        "Corner",
        "Highlight",
    },
    Default = "Box",

    Callback = function(value)
        print("Mode:", value)
    end,
})

ESPVisual:CreateColorPicker({
    Name = "Box Color",
    Flag = "BoxColor",
    Default = Color3.fromRGB(255, 255, 255),

    Callback = function(color)
        print("Box color:", color)
    end,
})

ESPVisual:CreateMultiDropdown({
    Name = "Elements",
    Flag = "Elements",
    Options = {
        "Name",
        "Distance",
        "Health",
        "Tracer",
    },
    Default = {
        "Name",
        "Distance",
    },
})

ESPVisual:CreateBind({
    Name = "Toggle ESP",
    Flag = "ToggleESPBind",
    Default = Enum.KeyCode.F6,

    Callback = function(binding)
        print("ESP bind pressed:", binding)
    end,
})

ESPVisual:CreateParagraph({
    Title = "ESP Settings",
    Content = "All gameplay behavior is external to the UI library.",
})

----------------------------------------------------------------------
-- MOVEMENT
----------------------------------------------------------------------

local Movement = Window:CreateTab({
    Name = "Movement",
    Icon = Library:GetIcon("Lucide", "Movement"),
})

local MainMovement = Movement:CreateSubtab({
    Name = "Main",
    Icon = Library:GetIcon("Lucide", "Speed"),
})

local MoveLeft = MainMovement:CreateSection({
    Name = "Movement",
    Side = "Left",
})

local MoveRight = MainMovement:CreateSection({
    Name = "Utilities",
    Side = "Right",
})

MoveLeft:CreateToggle({
    Name = "Feature Enabled",
    Flag = "MovementEnabled",
    Default = false,
})

MoveLeft:CreateSlider({
    Name = "Multiplier",
    Flag = "MovementMultiplier",
    Min = 0.5,
    Max = 5,
    Default = 1,
    Step = 0.1,
    Decimals = 1,

    Format = function(value)
        return string.format("%.1fx", value)
    end,
})

MoveLeft:CreateInput({
    Name = "Preset Name",
    Flag = "PresetName",
    Placeholder = "Enter preset...",
})

MoveRight:CreateButton({
    Name = "Test Callback",

    Callback = function()
        Window:Notify({
            Title = "Callback",
            Content = "The button callback was executed.",
            Icon = Library:GetIcon("Lucide", "Check"),
            Duration = 3,
        })
    end,
})

MoveRight:CreateDivider()

MoveRight:CreateParagraph({
    Title = "Tip",
    Content = "You can use invisible scrolling when a section contains many controls.",
})

----------------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------------

local Settings = Window:CreateTab({
    Name = "Settings",
    Icon = Library:GetIcon("Lucide", "Settings"),
})

local Interface = Settings:CreateSubtab({
    Name = "Interface",
    Icon = Library:GetIcon("Lucide", "Palette"),
})

local ThemeSection = Interface:CreateSection({
    Name = "Theme",
    Side = "Left",
})

ThemeSection:CreateDropdown({
    Name = "Accent Theme",
    Options = {
        "Red",
        "Blue",
        "Green",
    },
    Default = "Red",

    Callback = function(value)
        Library:SetTheme(value)
    end,
})

ThemeSection:CreateButton({
    Name = "Custom Purple",
    Callback = function()
        Library:CreateTheme("Purple", {
            Background = Color3.fromRGB(12, 9, 18),
            Surface = Color3.fromRGB(20, 15, 28),
            Surface2 = Color3.fromRGB(27, 20, 38),
            Stroke = Color3.fromRGB(50, 38, 64),

            Text = Color3.fromRGB(245, 240, 255),
            SubText = Color3.fromRGB(170, 155, 190),
            Muted = Color3.fromRGB(105, 92, 120),

            Accent = Color3.fromRGB(185, 65, 255),
            Accent2 = Color3.fromRGB(210, 110, 255),
        })

        Library:SetTheme("Purple")
    end,
})

ThemeSection:CreateColorPicker({
    Name = "Custom Accent",
    Default = Library.Theme.Accent,

    Callback = function(color)
        Library:SetAccentColor(color)
    end,
})

local ConfigSection = Interface:CreateSection({
    Name = "Config",
    Side = "Right",
})

ConfigSection:CreateButton({
    Name = "Save Config",

    Callback = function()
        Library.Config:Save("default")

        Window:Notify({
            Title = "Config",
            Content = "Configuration saved.",
            Icon = Library:GetIcon("Lucide", "Save"),
        })
    end,
})

ConfigSection:CreateButton({
    Name = "Load Config",

    Callback = function()
        local ok, err = Library.Config:Load("default")

        Window:Notify({
            Title = "Config",
            Content = ok and "Configuration loaded." or tostring(err),
            Icon = ok
                and Library:GetIcon("Lucide", "Check")
                or Library:GetIcon("Lucide", "Warning"),
        })
    end,
})

ConfigSection:CreateButton({
    Name = "Delete Config",

    Callback = function()
        Library.Config:Delete("default")

        Window:Notify({
            Title = "Config",
            Content = "Configuration deleted.",
            Icon = Library:GetIcon("Lucide", "Trash"),
        })
    end,
})

ConfigSection:CreateBind({
    Name = "Menu Toggle",
    Default = Enum.KeyCode.KeypadSeven,

    Changed = function(binding)
        Window:SetToggleKey(binding.KeyCode)
    end,
})

ConfigSection:CreateBind({
    Name = "Mouse Unlock",
    Default = Enum.KeyCode.LeftAlt,

    Changed = function(binding)
        Window:SetMouseUnlockKey(binding.KeyCode)
    end,
})

----------------------------------------------------------------------
-- POPUP EXAMPLE
----------------------------------------------------------------------

Window:Popup({
    Title = "Astral UI",
    Content = "Library initialized successfully.",

    Buttons = {
        {
            Name = "OK",
            Value = true,
            Primary = true,
        },
    },

    Callback = function(result)
        print("Popup result:", result)
    end,
})
```

---

# 26. Minimal Example / Минимальный пример

```lua
local Library = loadstring(game:HttpGet(
    "YOUR_RAW_MAIN_LUA_URL"
))()

local Window = Library:CreateWindow({
    Name = "Example",
})

local Tab = Window:CreateTab({
    Name = "Main",
    Icon = Library:GetIcon("Lucide", "Home"),
})

local Subtab = Tab:CreateSubtab({
    Name = "General",
    Icon = Library:GetIcon("Lucide", "Settings"),
})

local Section = Subtab:CreateSection({
    Name = "Controls",
    Side = "Left",
})

Section:CreateToggle({
    Name = "Enabled",
    Flag = "Enabled",
    Default = false,
})

Section:CreateButton({
    Name = "Notify",
    Callback = function()
        Window:Notify({
            Title = "Hello",
            Content = "Button clicked.",
        })
    end,
})
```

---

# 27. Design philosophy / Принцип дизайна

Astral UI is intended to be used as a **UI layer**:

```text
Library
  ↓
Window
  ↓
Tabs
  ↓
Subtabs
  ↓
Sections
  ↓
Controls
  ↓
Callbacks
  ↓
Your own logic
```

The library provides presentation, interaction, state and configuration. The actual application/game logic remains in the script using the library.

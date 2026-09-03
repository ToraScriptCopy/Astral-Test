--[[
    Astral / Wind-inspired GUI Library
    Main.lua
    --------------------------------------------------------------------
    Purpose:
      UI library only. No gameplay/ESP/aimbot/etc. functionality is included.

    Example bootstrap:
      local Library = loadstring(game:HttpGet("YOUR_RAW_MAIN_LUA_URL"))()

      local Window = Library:CreateWindow({
          Name = "My UI",
          Icon = "✦",
          Size = UDim2.fromOffset(760, 500),
          ToggleKey = Enum.KeyCode.RightShift,
      })

      local Visuals = Window:CreateTab({
          Name = "Visuals",
          Icon = "◉",
      })

      local ESP = Visuals:CreateSubtab({
          Name = "ESP",
          Icon = "◎",
      })

      local Section = ESP:CreateSection({
          Name = "General",
          Side = "Left",
      })

      Section:CreateToggle({
          Name = "Enabled",
          Default = false,
          Callback = function(Value)
              print("Enabled:", Value)
          end,
      })

    Supported controls:
      CreateButton
      CreateToggle
      CreateSlider
      CreateColorPicker
      CreateDropdown
      CreateMultiDropdown
      CreateBind

    Also:
      Config:Save(name)
      Config:Load(name)
      Config:Delete(name)
      Config:List()
      Window:SetVisible(bool)
      Window:Toggle()
      Window:Destroy()

    Notes:
      * Icon can be an Image asset string (rbxassetid://...) or a short
        text glyph. This keeps the library independent from a third-party
        icon package while still supporting Lucide-style icon assets.
      * Scrolling is intentionally scrollbar-free for a clean Wind-style UI.
      * File-backed config uses executor file APIs when available:
          isfolder / makefolder / isfile / writefile / readfile / delfile
        and falls back to in-memory configs.
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Library = {
    Version = "1.0.0",
    Theme = {
        Background = Color3.fromRGB(13, 13, 17),
        Surface = Color3.fromRGB(18, 18, 24),
        Surface2 = Color3.fromRGB(22, 22, 29),
        Stroke = Color3.fromRGB(35, 35, 44),
        Text = Color3.fromRGB(240, 240, 246),
        SubText = Color3.fromRGB(155, 155, 168),
        Muted = Color3.fromRGB(96, 96, 110),
        Accent = Color3.fromRGB(255, 25, 94),
        Accent2 = Color3.fromRGB(255, 58, 118),
        White = Color3.fromRGB(255, 255, 255),
        Black = Color3.fromRGB(0, 0, 0),
    },
    Flags = {},
    _windows = {},
    _configCache = {},
}

local ActiveTweens = {}
local function Tween(instance, info, props)
    local old = ActiveTweens[instance]
    if old then
        pcall(function()
            old:Cancel()
        end)
    end

    local tween = TweenService:Create(instance, info, props)
    ActiveTweens[instance] = tween
    tween:Play()
    return tween
end

local TI_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_SPRING = TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TI_COLOR = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function New(className, props)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    return obj
end

local function AddCorner(parent, radius)
    return New("UICorner", {
        Parent = parent,
        CornerRadius = UDim.new(0, radius or 6),
    })
end

local function AddStroke(parent, color, transparency, thickness)
    return New("UIStroke", {
        Parent = parent,
        Color = color or Library.Theme.Stroke,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
    })
end

local function AddPadding(parent, left, top, right, bottom)
    return New("UIPadding", {
        Parent = parent,
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    })
end

local function AddList(parent, padding, horizontal, sortOrder)
    return New("UIListLayout", {
        Parent = parent,
        FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or 0),
        HorizontalAlignment = horizontal and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Left,
        VerticalAlignment = horizontal and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top,
    })
end

local function MakeDraggable(handle, object)
    local dragging = false
    local dragInput
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            object.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

local function IsImageAsset(value)
    return typeof(value) == "string"
        and (
            string.find(value, "rbxassetid://", 1, true) ~= nil
            or string.find(value, "rbxthumb://", 1, true) ~= nil
            or tonumber(value) ~= nil
        )
end

local function SetIcon(gui, icon)
    if icon == nil then
        return
    end

    if IsImageAsset(icon) then
        gui.Image = tonumber(icon) and ("rbxassetid://" .. icon) or icon
        gui.ImageTransparency = 0
        gui.Text = ""
    else
        gui.Image = ""
        gui.Text = tostring(icon)
    end
end

local function NormalizeIconForText(icon)
    if icon == nil then
        return "•"
    end
    if IsImageAsset(icon) then
        return ""
    end
    return tostring(icon)
end

local function MakeLabel(parent, text, size, color, font)
    return New("TextLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or Library.Theme.Text,
        Font = font or Enum.Font.GothamMedium,
        TextSize = size or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 1, 0),
    })
end

local function SetText(label, text)
    if label and label.Parent then
        label.Text = tostring(text)
    end
end

local function ClampNumber(value, minValue, maxValue)
    value = tonumber(value) or minValue
    return math.clamp(value, minValue, maxValue)
end

local function RoundNumber(value, decimals)
    local power = 10 ^ (decimals or 0)
    return math.floor(value * power + 0.5) / power
end

local function ColorToTable(color)
    return {
        R = color.R,
        G = color.G,
        B = color.B,
    }
end

local function TableToColor(data)
    if type(data) ~= "table" then
        return Library.Theme.Accent
    end

    return Color3.new(
        tonumber(data.R) or 1,
        tonumber(data.G) or 1,
        tonumber(data.B) or 1
    )
end

local function EncodeValue(value)
    local valueType = typeof(value)

    if valueType == "Color3" then
        return {
            __type = "Color3",
            value = ColorToTable(value),
        }
    elseif valueType == "EnumItem" then
        return {
            __type = "EnumItem",
            enumType = tostring(value.EnumType),
            name = value.Name,
        }
    elseif valueType == "Vector2" then
        return {
            __type = "Vector2",
            X = value.X,
            Y = value.Y,
        }
    elseif type(value) == "table" then
        local result = {}
        for k, v in pairs(value) do
            result[k] = EncodeValue(v)
        end
        return result
    end

    return value
end

local function DecodeValue(value)
    if type(value) ~= "table" then
        return value
    end

    if value.__type == "Color3" then
        return TableToColor(value.value)
    elseif value.__type == "EnumItem" then
        local enumName = string.match(value.enumType or "", "Enum%.(.+)")
        if enumName and Enum[enumName] and Enum[enumName][value.name] then
            return Enum[enumName][value.name]
        end
        return value.name
    elseif value.__type == "Vector2" then
        return Vector2.new(value.X or 0, value.Y or 0)
    end

    local result = {}
    for k, v in pairs(value) do
        result[k] = DecodeValue(v)
    end
    return result
end

local function GetConfigFolder()
    return "AstralHub"
end

local function HasFileApi()
    return type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
end

local function EnsureConfigFolder()
    if not HasFileApi() then
        return false
    end

    local folder = GetConfigFolder()

    if type(isfolder) == "function" and type(makefolder) == "function" then
        if not isfolder(folder) then
            pcall(makefolder, folder)
        end
    end

    return true
end

local function SanitizeFileName(name)
    name = tostring(name or "config")
    name = name:gsub("[^%w%-%_ ]", "_")
    return name .. ".json"
end

local Config = {
    _flags = Library.Flags,
}

function Config:_Snapshot()
    local snapshot = {}
    for flag, value in pairs(self._flags) do
        snapshot[flag] = EncodeValue(value)
    end
    return snapshot
end

function Config:Save(name)
    name = tostring(name or "default")

    local data = HttpService:JSONEncode(self:_Snapshot())
    Library._configCache[name] = data

    if EnsureConfigFolder() then
        local path = GetConfigFolder() .. "/" .. SanitizeFileName(name)
        pcall(writefile, path, data)
    end

    return true
end

function Config:Load(name)
    name = tostring(name or "default")

    local data = Library._configCache[name]

    if not data and HasFileApi() then
        EnsureConfigFolder()
        local path = GetConfigFolder() .. "/" .. SanitizeFileName(name)

        if isfile(path) then
            local ok, result = pcall(readfile, path)
            if ok then
                data = result
                Library._configCache[name] = data
            end
        end
    end

    if not data then
        return false, "Config not found"
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(data)
    end)

    if not ok or type(decoded) ~= "table" then
        return false, "Invalid config data"
    end

    for flag, value in pairs(decoded) do
        local control = Library._controls and Library._controls[flag]
        if control and control.Set then
            pcall(control.Set, control, DecodeValue(value), true)
        else
            Library.Flags[flag] = DecodeValue(value)
        end
    end

    return true
end

function Config:Delete(name)
    name = tostring(name or "default")
    Library._configCache[name] = nil

    if HasFileApi() then
        EnsureConfigFolder()
        local path = GetConfigFolder() .. "/" .. SanitizeFileName(name)

        if isfile(path) and type(delfile) == "function" then
            pcall(delfile, path)
        end
    end

    return true
end

function Config:List()
    local names = {}

    for name in pairs(Library._configCache) do
        table.insert(names, name)
    end

    if HasFileApi() and type(listfiles) == "function" then
        EnsureConfigFolder()

        local ok, files = pcall(listfiles, GetConfigFolder())
        if ok and type(files) == "table" then
            for _, path in ipairs(files) do
                local filename = path:match("([^\\/]+)%.json$")
                if filename then
                    local exists = false
                    for _, current in ipairs(names) do
                        if current == filename then
                            exists = true
                            break
                        end
                    end
                    if not exists then
                        table.insert(names, filename)
                    end
                end
            end
        end
    end

    table.sort(names)
    return names
end

Library.Config = Config
Library._controls = {}

local function RegisterControl(flag, control)
    if not flag then
        return
    end

    Library._controls[flag] = control
end

local function UpdateCanvas(scroller)
    local layout = scroller:FindFirstChildOfClass("UIListLayout")
    if layout then
        scroller.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
    end
end

local function HookCanvasUpdate(scroller)
    local layout = scroller:FindFirstChildOfClass("UIListLayout")
    if layout then
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            UpdateCanvas(scroller)
        end)
    end
    task.defer(function()
        UpdateCanvas(scroller)
    end)
end

local function NewScrollingFrame(parent)
    local scroll = New("ScrollingFrame", {
        Parent = parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
    })

    AddList(scroll, 8, false)
    return scroll
end

local function CreateTooltip(parent, text)
    local tooltip = New("TextLabel", {
        Parent = parent,
        BackgroundColor3 = Library.Theme.Surface2,
        TextColor3 = Library.Theme.Text,
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        Size = UDim2.fromOffset(math.max(70, #tostring(text) * 7), 24),
        Position = UDim2.new(0, 0, 1, 5),
        Visible = false,
        ZIndex = 50,
    })
    AddCorner(tooltip, 5)
    AddStroke(tooltip, Library.Theme.Stroke, 0, 1)
    AddPadding(8, 0, 8, 0)

    return tooltip
end

local function AttachTooltip(button, tooltip)
    button.MouseEnter:Connect(function()
        tooltip.Visible = true
        Tween(tooltip, TI_FAST, {TextTransparency = 0})
    end)
    button.MouseLeave:Connect(function()
        Tween(tooltip, TI_FAST, {TextTransparency = 1})
        task.delay(0.15, function()
            tooltip.Visible = false
        end)
    end)
end

local WindowMethods = {}
local TabMethods = {}
local SubtabMethods = {}
local SectionMethods = {}

function SectionMethods:_CreateRow(height)
    local row = New("Frame", {
        Parent = self._content,
        BackgroundColor3 = Library.Theme.Surface2,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 40),
    })

    AddCorner(row, 6)
    return row
end

function SectionMethods:CreateLabel(options)
    options = options or {}

    local row = self:_CreateRow(options.Height or 32)
    local label = MakeLabel(
        row,
        options.Name or options.Text or "",
        options.TextSize or 12,
        options.Color or Library.Theme.SubText,
        options.Font or Enum.Font.GothamMedium
    )
    AddPadding(label, 12, 0, 12, 0)

    return {
        Instance = row,
        Set = function(_, text)
            label.Text = tostring(text)
        end,
    }
end

function SectionMethods:CreateButton(options)
    options = options or {}

    local row = self:_CreateRow(options.Height or 38)
    local label = MakeLabel(row, options.Name or "Button", 12, Library.Theme.Text)
    label.Size = UDim2.new(1, -54, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)

    local click = New("TextButton", {
        Parent = row,
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.fromScale(1, 1),
    })

    local arrow = New("TextLabel", {
        Parent = row,
        BackgroundTransparency = 1,
        Text = options.Arrow == false and "" or "›",
        TextColor3 = Library.Theme.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -38, 0, 3),
    })

    click.MouseEnter:Connect(function()
        Tween(row, TI_FAST, {BackgroundColor3 = Library.Theme.Stroke})
    end)

    click.MouseLeave:Connect(function()
        Tween(row, TI_FAST, {BackgroundColor3 = Library.Theme.Surface2})
    end)

    click.MouseButton1Click:Connect(function()
        if options.Callback then
            options.Callback()
        end
    end)

    return {
        Instance = row,
        Button = click,
        SetText = function(_, text)
            label.Text = tostring(text)
        end,
        Set = function(_, callback)
            options.Callback = callback
        end,
    }
end

function SectionMethods:CreateToggle(options)
    options = options or {}

    local flag = options.Flag
    local state = options.Default == true

    local row = self:_CreateRow(options.Height or 40)

    local label = MakeLabel(row, options.Name or "Toggle", 12, Library.Theme.Text)
    label.Size = UDim2.new(1, -62, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)

    local hit = New("TextButton", {
        Parent = row,
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.fromScale(1, 1),
    })

    local switch = New("Frame", {
        Parent = row,
        BackgroundColor3 = Library.Theme.Stroke,
        Size = UDim2.fromOffset(28, 16),
        Position = UDim2.new(1, -40, 0.5, -8),
    })
    AddCorner(switch, 10)

    local knob = New("Frame", {
        Parent = switch,
        BackgroundColor3 = Library.Theme.Muted,
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.fromOffset(2, 2),
    })
    AddCorner(knob, 10)

    local api = {}

    local function Render(value, instant)
        state = value == true
        if flag then
            Library.Flags[flag] = state
        end

        local color = state and Library.Theme.Accent or Library.Theme.Stroke
        local pos = state and UDim2.new(1, -14, 0, 2) or UDim2.fromOffset(2, 2)
        local knobColor = state and Library.Theme.White or Library.Theme.Muted

        if instant then
            switch.BackgroundColor3 = color
            knob.Position = pos
            knob.BackgroundColor3 = knobColor
        else
            Tween(switch, TI_FAST, {BackgroundColor3 = color})
            Tween(knob, TI_FAST, {Position = pos, BackgroundColor3 = knobColor})
        end
    end

    function api:Set(value, silent)
        Render(value)
        if not silent and options.Callback then
            options.Callback(state)
        end
    end

    function api:Get()
        return state
    end

    hit.MouseEnter:Connect(function()
        Tween(row, TI_FAST, {BackgroundColor3 = Library.Theme.Stroke})
    end)

    hit.MouseLeave:Connect(function()
        Tween(row, TI_FAST, {BackgroundColor3 = Library.Theme.Surface2})
    end)

    hit.MouseButton1Click:Connect(function()
        api:Set(not state)
    end)

    Render(state, true)
    RegisterControl(flag, api)

    if flag then
        Library.Flags[flag] = state
    end

    return api
end

function SectionMethods:CreateSlider(options)
    options = options or {}

    local minValue = tonumber(options.Min) or 0
    local maxValue = tonumber(options.Max) or 100
    local defaultValue = ClampNumber(options.Default or minValue, minValue, maxValue)
    local step = tonumber(options.Step) or 1
    local decimals = tonumber(options.Decimals)
    if decimals == nil then
        decimals = step < 1 and 2 or 0
    end

    local flag = options.Flag
    local value = defaultValue

    local row = self:_CreateRow(options.Height or 54)

    local label = MakeLabel(row, options.Name or "Slider", 12, Library.Theme.Text)
    label.Position = UDim2.fromOffset(12, 4)
    label.Size = UDim2.new(0.7, 0, 0, 18)

    local valueLabel = MakeLabel(row, "", 11, Library.Theme.SubText)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Position = UDim2.new(0.7, 0, 4, 0)
    valueLabel.Size = UDim2.new(0.3, -12, 0, 18)

    local track = New("Frame", {
        Parent = row,
        BackgroundColor3 = Library.Theme.Stroke,
        Position = UDim2.new(0, 12, 1, -17),
        Size = UDim2.new(1, -24, 0, 5),
    })
    AddCorner(track, 4)

    local fill = New("Frame", {
        Parent = track,
        BackgroundColor3 = Library.Theme.Accent,
        Size = UDim2.new(0, 0, 1, 0),
    })
    AddCorner(fill, 4)

    local dragging = false
    local api = {}

    local function SetFromInput(x)
        local alpha = math.clamp(
            (x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1),
            0,
            1
        )

        local raw = minValue + (maxValue - minValue) * alpha
        local stepped = minValue + math.floor(((raw - minValue) / step) + 0.5) * step
        stepped = ClampNumber(stepped, minValue, maxValue)
        stepped = RoundNumber(stepped, decimals)

        api:Set(stepped)
    end

    local function Render(newValue, instant)
        value = ClampNumber(newValue, minValue, maxValue)

        local alpha = (value - minValue) / math.max(maxValue - minValue, 0.00001)
        local size = UDim2.new(alpha, 0, 1, 0)
        local display = options.Format
            and options.Format(value)
            or (tostring(value) .. (options.Suffix or ""))

        if flag then
            Library.Flags[flag] = value
        end

        valueLabel.Text = display

        if instant then
            fill.Size = size
        else
            Tween(fill, TI_FAST, {Size = size})
        end
    end

    function api:Set(newValue, silent)
        Render(newValue)
        if not silent and options.Callback then
            options.Callback(value)
        end
    end

    function api:Get()
        return value
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            SetFromInput(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging
            and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then
            SetFromInput(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    Render(value, true)
    RegisterControl(flag, api)

    return api
end

function SectionMethods:CreateColorPicker(options)
    options = options or {}

    local flag = options.Flag
    local currentColor = options.Default or Color3.fromRGB(255, 255, 255)
    local popupOpen = false

    local row = self:_CreateRow(options.Height or 40)

    local label = MakeLabel(row, options.Name or "Color", 12, Library.Theme.Text)
    label.Position = UDim2.fromOffset(12, 0)
    label.Size = UDim2.new(1, -64, 1, 0)

    local preview = New("TextButton", {
        Parent = row,
        BackgroundColor3 = currentColor,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.fromOffset(28, 18),
        Position = UDim2.new(1, -40, 0.5, -9),
    })
    AddCorner(preview, 5)
    AddStroke(preview, Library.Theme.Stroke, 0, 1)

    local popup = New("Frame", {
        Parent = row,
        BackgroundColor3 = Library.Theme.Surface,
        Size = UDim2.fromOffset(250, 194),
        Position = UDim2.new(1, -250, 1, 6),
        Visible = false,
        ZIndex = 20,
    })
    AddCorner(popup, 7)
    AddStroke(popup, Library.Theme.Stroke, 0, 1)
    AddPadding(popup, 10, 10, 10, 10)

    local popupTitle = MakeLabel(popup, "Color Picker", 11, Library.Theme.SubText)
    popupTitle.Size = UDim2.new(1, 0, 0, 20)

    local saturation = New("ImageButton", {
        Parent = popup,
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromHSV(0, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, 34),
        Size = UDim2.fromOffset(170, 128),
        Image = "rbxassetid://4155801252",
        ScaleType = Enum.ScaleType.Stretch,
    })
    AddCorner(saturation, 5)

    local hue = New("Frame", {
        Parent = popup,
        BackgroundColor3 = Library.Theme.White,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(189, 34),
        Size = UDim2.fromOffset(16, 128),
        ZIndex = 21,
    })
    AddCorner(hue, 5)

    local hueHandle = New("Frame", {
        Parent = hue,
        BackgroundColor3 = Library.Theme.White,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 4, 0, 4),
        Position = UDim2.new(0, -2, 0, 0),
        ZIndex = 22,
    })
    AddCorner(hueHandle, 4)
    AddStroke(hueHandle, Library.Theme.Black, 0, 1)

    local svHandle = New("Frame", {
        Parent = saturation,
        BackgroundColor3 = Library.Theme.White,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(8, 8),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 22,
    })
    AddCorner(svHandle, 10)
    AddStroke(svHandle, Library.Theme.Black, 0, 1)

    local copy = MakeLabel(popup, "", 11, Library.Theme.SubText)
    copy.Position = UDim2.fromOffset(10, 166)
    copy.Size = UDim2.fromOffset(205, 18)

    local hueValue, saturationValue, valueValue =
        Color3.toHSV(currentColor)

    local api = {}

    local function Render()
        local color = Color3.fromHSV(hueValue, saturationValue, valueValue)
        currentColor = color
        preview.BackgroundColor3 = color
        saturation.BackgroundColor3 = Color3.fromHSV(hueValue, 1, 1)
        hueHandle.Position = UDim2.new(0, -2, math.clamp(hueValue, 0, 1), -2)
        svHandle.Position = UDim2.new(saturationValue, 0, 1 - valueValue, 0)
        copy.Text = string.format(
            "RGB  %d, %d, %d",
            math.floor(color.R * 255 + 0.5),
            math.floor(color.G * 255 + 0.5),
            math.floor(color.B * 255 + 0.5)
        )

        if flag then
            Library.Flags[flag] = color
        end
    end

    function api:Set(color, silent)
        if typeof(color) ~= "Color3" then
            return
        end

        hueValue, saturationValue, valueValue = Color3.toHSV(color)
        Render()

        if not silent and options.Callback then
            options.Callback(color)
        end
    end

    function api:Get()
        return currentColor
    end

    local function TogglePopup()
        popupOpen = not popupOpen
        popup.Visible = popupOpen
        if popupOpen then
            popup.Size = UDim2.fromOffset(250, 186)
            popup.BackgroundTransparency = 1
            Tween(popup, TI_MED, {
                BackgroundTransparency = 0,
            })
        end
    end

    preview.MouseButton1Click:Connect(TogglePopup)

    local svDragging = false
    local hueDragging = false

    saturation.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = true
        end
    end)

    hue.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if svDragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local x = math.clamp(
                (input.Position.X - saturation.AbsolutePosition.X)
                    / math.max(saturation.AbsoluteSize.X, 1),
                0,
                1
            )
            local y = math.clamp(
                (input.Position.Y - saturation.AbsolutePosition.Y)
                    / math.max(saturation.AbsoluteSize.Y, 1),
                0,
                1
            )

            saturationValue = x
            valueValue = 1 - y
            api:Set(Color3.fromHSV(hueValue, saturationValue, valueValue))
        elseif hueDragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            hueValue = math.clamp(
                (input.Position.Y - hue.AbsolutePosition.Y)
                    / math.max(hue.AbsoluteSize.Y, 1),
                0,
                1
            )
            api:Set(Color3.fromHSV(hueValue, saturationValue, valueValue))
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
            hueDragging = false
        end
    end)

    Render()
    RegisterControl(flag, api)

    return api
end

local function CreateDropdownInternal(section, options, isMulti)
    options = options or {}

    local flag = options.Flag
    local items = options.Options or {}
    local opened = false
    local selected = isMulti and {} or options.Default

    if isMulti then
        if type(options.Default) == "table" then
            for _, item in ipairs(options.Default) do
                selected[item] = true
            end
        end
    elseif selected == nil and #items > 0 then
        selected = options.Default or items[1]
    end

    local height = isMulti and 42 or 40
    local row = section:_CreateRow(height)

    local label = MakeLabel(row, options.Name or (isMulti and "Multi Dropdown" or "Dropdown"), 12, Library.Theme.Text)
    label.Size = UDim2.new(0.45, 0, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)

    local selectedLabel = MakeLabel(row, "", 11, Library.Theme.SubText)
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
    selectedLabel.Position = UDim2.new(0.45, 0, 0, 0)
    selectedLabel.Size = UDim2.new(0.45, -42, 1, 0)

    local chevron = MakeLabel(row, "⌄", 14, Library.Theme.Muted)
    chevron.TextXAlignment = Enum.TextXAlignment.Center
    chevron.Position = UDim2.new(1, -32, 0, 0)
    chevron.Size = UDim2.fromOffset(28, 40)

    local click = New("TextButton", {
        Parent = row,
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 3,
    })

    local listFrame = New("Frame", {
        Parent = row,
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 6),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ZIndex = 30,
        ClipsDescendants = true,
    })
    AddCorner(listFrame, 6)
    AddStroke(listFrame, Library.Theme.Stroke, 0, 1)

    local list = NewScrollingFrame(listFrame)
    list.Size = UDim2.new(1, 0, 1, 0)
    list.ZIndex = 31

    local rows = {}

    local api = {}

    local function SelectionText()
        if not isMulti then
            return selected and tostring(selected) or "Select..."
        end

        local names = {}
        for item, enabled in pairs(selected) do
            if enabled then
                table.insert(names, tostring(item))
            end
        end
        table.sort(names)

        if #names == 0 then
            return "Select..."
        elseif #names == 1 then
            return names[1]
        else
            return tostring(#names) .. " selected"
        end
    end

    local function RefreshSelectionText()
        selectedLabel.Text = SelectionText()
    end

    local function Choose(item)
        if isMulti then
            selected[item] = not selected[item]
            if options.Callback then
                options.Callback(selected)
            end
        else
            selected = item
            opened = false
            listFrame.Visible = false
            listFrame.Size = UDim2.new(1, 0, 0, 0)
            if options.Callback then
                options.Callback(selected)
            end
        end

        if flag then
            if isMulti then
                local out = {}
                for name, enabled in pairs(selected) do
                    if enabled then
                        table.insert(out, name)
                    end
                end
                Library.Flags[flag] = out
            else
                Library.Flags[flag] = selected
            end
        end

        RefreshSelectionText()
        for item, rowButton in pairs(rows) do
            if rowButton and rowButton.Parent then
                local active = isMulti and selected[item] or selected == item
                local accent = active and Library.Theme.Accent or Library.Theme.SubText
                rowButton.TextColor3 = accent
            end
        end
    end

    for index, item in ipairs(items) do
        local itemButton = New("TextButton", {
            Parent = list,
            BackgroundColor3 = index % 2 == 0
                and Library.Theme.Surface2
                or Library.Theme.Surface,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            Text = tostring(item),
            TextColor3 = Library.Theme.SubText,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            Size = UDim2.new(1, -8, 0, 30),
            AutoButtonColor = false,
            ZIndex = 32,
        })

        AddCorner(itemButton, 5)
        rows[item] = itemButton

        itemButton.MouseEnter:Connect(function()
            Tween(itemButton, TI_FAST, {
                BackgroundColor3 = Library.Theme.Stroke,
            })
        end)

        itemButton.MouseLeave:Connect(function()
            local base = index % 2 == 0
                and Library.Theme.Surface2
                or Library.Theme.Surface
            Tween(itemButton, TI_FAST, {BackgroundColor3 = base})
        end)

        itemButton.MouseButton1Click:Connect(function()
            Choose(item)
            if not isMulti then
                RefreshSelectionText()
            end
        end)
    end

    click.MouseButton1Click:Connect(function()
        opened = not opened
        listFrame.Visible = opened

        if opened then
            local itemCount = #items
            local targetHeight = math.clamp(itemCount * 32 + 12, 42, 170)

            if isMulti then
                targetHeight = math.clamp(itemCount * 32 + 12, 42, 170)
            end

            listFrame.Size = UDim2.new(1, 0, 0, 0)
            Tween(listFrame, TI_MED, {
                Size = UDim2.new(1, 0, 0, targetHeight),
            })
        else
            Tween(listFrame, TI_FAST, {
                Size = UDim2.new(1, 0, 0, 0),
            })
            task.delay(0.15, function()
                if not opened then
                    listFrame.Visible = false
                end
            end)
        end
    end)

    function api:Set(value, silent)
        if isMulti then
            selected = {}
            if type(value) == "table" then
                for _, item in ipairs(value) do
                    selected[item] = true
                end
            end
        else
            selected = value
        end

        RefreshSelectionText()

        if flag then
            if isMulti then
                local out = {}
                for name, enabled in pairs(selected) do
                    if enabled then
                        table.insert(out, name)
                    end
                end
                Library.Flags[flag] = out
            else
                Library.Flags[flag] = selected
            end
        end

        for item, rowButton in pairs(rows) do
            if rowButton and rowButton.Parent then
                local active = isMulti and selected[item] or selected == item
                rowButton.TextColor3 = active and Library.Theme.Accent or Library.Theme.SubText
            end
        end

        if not silent and options.Callback then
            options.Callback(isMulti and value or selected)
        end
    end

    function api:Get()
        if isMulti then
            local out = {}
            for item, enabled in pairs(selected) do
                if enabled then
                    table.insert(out, item)
                end
            end
            return out
        end
        return selected
    end

    RefreshSelectionText()

    if flag then
        if isMulti then
            local out = {}
            for item, enabled in pairs(selected) do
                if enabled then
                    table.insert(out, item)
                end
            end
            Library.Flags[flag] = out
        else
            Library.Flags[flag] = selected
        end
    end

    RegisterControl(flag, api)

    return api
end

function SectionMethods:CreateDropdown(options)
    return CreateDropdownInternal(self, options, false)
end

function SectionMethods:CreateMultiDropdown(options)
    return CreateDropdownInternal(self, options, true)
end

local KeyAliases = {
    Mouse1 = Enum.UserInputType.MouseButton1,
    Mouse2 = Enum.UserInputType.MouseButton2,
    Mouse3 = Enum.UserInputType.MouseButton3,
}

local function InputMatchesBinding(input, binding)
    if not binding then
        return false
    end

    if binding.Type == "KeyCode" then
        return input.KeyCode == binding.KeyCode
    elseif binding.Type == "UserInputType" then
        return input.UserInputType == binding.UserInputType
    end

    return false
end

function SectionMethods:CreateBind(options)
    options = options or {}

    local flag = options.Flag
    local binding = {
        Type = "KeyCode",
        KeyCode = options.Default or Enum.KeyCode.Unknown,
        UserInputType = nil,
    }

    if typeof(options.Default) == "EnumItem" then
        if options.Default.EnumType == Enum.KeyCode then
            binding.Type = "KeyCode"
            binding.KeyCode = options.Default
        elseif options.Default.EnumType == Enum.UserInputType then
            binding.Type = "UserInputType"
            binding.UserInputType = options.Default
        end
    end

    local listening = false

    local row = self:_CreateRow(options.Height or 40)

    local label = MakeLabel(row, options.Name or "Bind", 12, Library.Theme.Text)
    label.Position = UDim2.fromOffset(12, 0)
    label.Size = UDim2.new(1, -112, 1, 0)

    local bindButton = New("TextButton", {
        Parent = row,
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0,
        TextColor3 = Library.Theme.SubText,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        Text = "None",
        Size = UDim2.fromOffset(88, 24),
        Position = UDim2.new(1, -100, 0.5, -12),
        AutoButtonColor = false,
    })
    AddCorner(bindButton, 5)
    AddStroke(bindButton, Library.Theme.Stroke, 0, 1)

    local function BindingText()
        if binding.Type == "KeyCode" and binding.KeyCode then
            return binding.KeyCode.Name
        elseif binding.Type == "UserInputType" and binding.UserInputType then
            return binding.UserInputType.Name:gsub("MouseButton", "Mouse ")
        end
        return "None"
    end

    local api = {}

    local function Fire()
        if options.Callback then
            options.Callback(binding)
        end
    end

    local function Render()
        bindButton.Text = listening and "Press a key..." or BindingText()

        if flag then
            Library.Flags[flag] = binding
        end
    end

    function api:Set(value, silent)
        if typeof(value) == "EnumItem" then
            if value.EnumType == Enum.KeyCode then
                binding.Type = "KeyCode"
                binding.KeyCode = value
                binding.UserInputType = nil
            elseif value.EnumType == Enum.UserInputType then
                binding.Type = "UserInputType"
                binding.UserInputType = value
                binding.KeyCode = nil
            end
        elseif type(value) == "table" then
            binding.Type = value.Type or "KeyCode"
            binding.KeyCode = value.KeyCode
            binding.UserInputType = value.UserInputType
        end

        Render()

        if not silent and options.Changed then
            options.Changed(binding)
        end
    end

    function api:Get()
        return binding
    end

    function api:IsDown()
        if binding.Type == "KeyCode" then
            return UserInputService:IsKeyDown(binding.KeyCode)
        elseif binding.Type == "UserInputType" then
            return UserInputService:IsMouseButtonPressed(binding.UserInputType)
        end
        return false
    end

    bindButton.MouseButton1Click:Connect(function()
        listening = not listening
        Render()
        if listening then
            bindButton.TextColor3 = Library.Theme.Accent
        else
            bindButton.TextColor3 = Library.Theme.SubText
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    api:Set(input.KeyCode)
                    listening = false
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                api:Set(input.UserInputType)
                listening = false
            end

            bindButton.TextColor3 = Library.Theme.SubText
            Render()
            return
        end

        if InputMatchesBinding(input, binding) and not gameProcessed then
            Fire()
        end
    end)

    Render()
    RegisterControl(flag, api)

    return api
end

function SubtabMethods:CreateSection(options)
    options = options or {}

    local side = options.Side or "Left"
    local column = side == "Right" and self._rightColumn or self._leftColumn

    local sectionFrame = New("Frame", {
        Parent = column,
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })

    AddCorner(sectionFrame, 7)
    AddStroke(sectionFrame, Library.Theme.Stroke, 0, 1)

    local title = MakeLabel(sectionFrame, options.Name or "Section", 11, Library.Theme.SubText)
    title.Position = UDim2.fromOffset(12, 0)
    title.Size = UDim2.new(1, -24, 0, 30)

    local content = New("Frame", {
        Parent = sectionFrame,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 30),
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    AddList(content, 7, false)

    local obj = {
        Instance = sectionFrame,
        _content = content,
    }

    setmetatable(obj, {__index = SectionMethods})

    return obj
end

function SubtabMethods:_ClearSections()
    for _, child in ipairs(self._leftColumn:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    for _, child in ipairs(self._rightColumn:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

function SubtabMethods:Activate()
    if self._window._activeSubtab == self then
        return
    end

    for _, other in ipairs(self._tab._subtabs) do
        if other == self then
            other._button.BackgroundColor3 = Library.Theme.Surface2
            other._nameLabel.TextTransparency = 0
            other._nameLabel.Size = UDim2.new(0, other._nameWidth, 1, 0)
        else
            other._button.BackgroundColor3 = Library.Theme.Background
            other._nameLabel.TextTransparency = 1
            other._nameLabel.Size = UDim2.fromOffset(0, 0)
        end
    end

    self._window._activeSubtab = self

    for _, other in ipairs(self._tab._subtabs) do
        if other ~= self then
            other._content.Visible = false
        end
    end

    self._content.Visible = true
    self._content.Position = UDim2.new(0, 0, 0, 8)
    Tween(self._content, TI_SPRING, {
        Position = UDim2.new(0, 0, 0, 0),
    })
end

function TabMethods:CreateSubtab(options)
    options = options or {}

    local button = New("TextButton", {
        Parent = self._subtabBar,
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.fromOffset(44, 30),
    })
    AddCorner(button, 6)

    local icon = New("TextLabel", {
        Parent = button,
        BackgroundTransparency = 1,
        TextColor3 = Library.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Text = NormalizeIconForText(options.Icon),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.fromOffset(2, 0),
    })

    if IsImageAsset(options.Icon) then
        local image = New("ImageLabel", {
            Parent = button,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.fromOffset(8, 6),
        })
        SetIcon(image, options.Icon)
        image.ImageColor3 = Library.Theme.Text
        icon.Visible = false
    end

    local textName = tostring(options.Name or "Subtab")
    local nameWidth = math.clamp(#textName * 7 + 24, 54, 108)

    local nameLabel = MakeLabel(button, textName, 11, Library.Theme.Text)
    nameLabel.Position = UDim2.fromOffset(31, 0)
    nameLabel.Size = UDim2.fromOffset(0, 30)
    nameLabel.TextTransparency = 1
    nameLabel.ClipsDescendants = true

    button.MouseButton1Click:Connect(function()
        self._window:SetTab(self)
        local found = false
        for _, item in ipairs(self._subtabs) do
            if item._button == button then
                found = item
                break
            end
        end
        if found then
            found:Activate()
        end
    end)

    button.MouseEnter:Connect(function()
        if self._window._activeSubtab ~= nil and self._window._activeSubtab._button ~= button then
            Tween(button, TI_FAST, {BackgroundColor3 = Library.Theme.Surface})
        end
    end)

    button.MouseLeave:Connect(function()
        if self._window._activeSubtab ~= nil and self._window._activeSubtab._button ~= button then
            Tween(button, TI_FAST, {BackgroundColor3 = Library.Theme.Background})
        end
    end)

    local content = New("Frame", {
        Parent = self._contentHost,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    })

    local body = New("ScrollingFrame", {
        Parent = content,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    AddPadding(body, 2, 2, 2, 12)

    local columns = New("Frame", {
        Parent = body,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })

    local left = New("Frame", {
        Parent = columns,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    AddList(left, 8, false)

    local right = New("Frame", {
        Parent = columns,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 5, 0, 0),
        Size = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    AddList(right, 8, false)

    local obj = {
        _tab = self,
        _window = self._window,
        _button = button,
        _nameLabel = nameLabel,
        _nameWidth = nameWidth,
        _content = content,
        _leftColumn = left,
        _rightColumn = right,
    }

    setmetatable(obj, {__index = SubtabMethods})
    table.insert(self._subtabs, obj)

    local function UpdateSubtabWidths()
        for _, item in ipairs(self._subtabs) do
            local active = self._window._activeSubtab == item
            local width = active and (31 + item._nameWidth) or 36
            Tween(item._button, TI_MED, {
                Size = UDim2.fromOffset(width, 30),
            })
            Tween(item._nameLabel, TI_MED, {
                Size = active
                    and UDim2.fromOffset(item._nameWidth, 30)
                    or UDim2.fromOffset(0, 30),
                TextTransparency = active and 0 or 1,
            })
        end
    end

    obj.Activate = function(item)
        if self._window._activeSubtab == item then
            return
        end

        for _, other in ipairs(self._subtabs) do
            local active = other == item
            Tween(other._button, TI_MED, {
                BackgroundColor3 = active and Library.Theme.Surface2 or Library.Theme.Background,
                Size = UDim2.fromOffset(
                    active and (31 + other._nameWidth) or 36,
                    30
                ),
            })
            Tween(other._nameLabel, TI_MED, {
                Size = active
                    and UDim2.fromOffset(other._nameWidth, 30)
                    or UDim2.fromOffset(0, 30),
                TextTransparency = active and 0 or 1,
            })
            other._content.Visible = active
        end

        self._window._activeSubtab = item
        item._content.Position = UDim2.new(0, 0, 0, 8)
        Tween(item._content, TI_SPRING, {
            Position = UDim2.new(0, 0, 0, 0),
        })
    end

    HookCanvasUpdate(body)

    if #self._subtabs == 1 then
        obj:Activate()
    end

    return obj
end

function TabMethods:CreateSection(options)
    if not self._activeSubtab then
        local subtab = self:CreateSubtab({
            Name = self._name,
            Icon = self._icon,
        })
        self._activeSubtab = subtab
    end
    return self._activeSubtab:CreateSection(options)
end

function WindowMethods:SetVisible(visible)
    visible = visible == true
    if self._destroyed then
        return
    end

    self._visible = visible

    if visible then
        self._gui.Enabled = true
        self._main.BackgroundTransparency = 1
        self._main.Size = UDim2.fromOffset(0, 0)
        Tween(self._main, TI_SPRING, {
            Size = self._size,
            BackgroundTransparency = 0,
        })
    else
        local tween = Tween(self._main, TI_MED, {
            Size = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1,
        })
        tween.Completed:Connect(function()
            if not self._visible and self._gui then
                self._gui.Enabled = false
            end
        end)
    end
end

function WindowMethods:Toggle()
    self:SetVisible(not self._visible)
end

function WindowMethods:SetTab(tab)
    if self._activeTab == tab then
        return
    end

    for _, item in ipairs(self._tabs) do
        local active = item == tab

        if active then
            Tween(item._button, TI_MED, {
                Size = UDim2.fromOffset(item._expandedWidth, 34),
                BackgroundColor3 = Library.Theme.Surface2,
            })
            item._nameLabel.TextTransparency = 0
            item._content.Visible = true
        else
            Tween(item._button, TI_MED, {
                Size = UDim2.fromOffset(36, 34),
                BackgroundColor3 = Library.Theme.Background,
            })
            item._nameLabel.TextTransparency = 1
            item._content.Visible = false
        end
    end

    self._activeTab = tab

    tab._content.Position = UDim2.new(0, 0, 0, 10)
    Tween(tab._content, TI_SPRING, {
        Position = UDim2.new(0, 0, 0, 0),
    })

    if tab._activeSubtab then
        tab._activeSubtab:Activate()
    end
end

function WindowMethods:CreateTab(options)
    options = options or {}

    local name = tostring(options.Name or "Tab")
    local icon = options.Icon or "•"
    local expandedWidth = math.clamp(#name * 7 + 44, 72, 142)

    local button = New("TextButton", {
        Parent = self._tabBar,
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.fromOffset(36, 34),
    })
    AddCorner(button, 7)

    local imageHolder = New("TextLabel", {
        Parent = button,
        BackgroundTransparency = 1,
        TextColor3 = Library.Theme.SubText,
        Text = NormalizeIconForText(icon),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.fromOffset(30, 34),
        Position = UDim2.fromOffset(3, 0),
    })

    if IsImageAsset(icon) then
        local image = New("ImageLabel", {
            Parent = button,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(17, 17),
            Position = UDim2.fromOffset(9, 8),
        })
        SetIcon(image, icon)
        image.ImageColor3 = Library.Theme.SubText
        imageHolder.Visible = false
    end

    local nameLabel = MakeLabel(button, name, 11, Library.Theme.Text)
    nameLabel.Position = UDim2.fromOffset(32, 0)
    nameLabel.Size = UDim2.fromOffset(expandedWidth - 32, 34)
    nameLabel.TextTransparency = 1
    nameLabel.ClipsDescendants = true

    local content = New("Frame", {
        Parent = self._contentContainer,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
    })

    local subBar = New("Frame", {
        Parent = content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
    })
    AddList(subBar, 6, true)

    local contentHost = New("Frame", {
        Parent = content,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 40),
        Size = UDim2.new(1, 0, 1, -40),
        ClipsDescendants = true,
    })

    local obj = {
        _window = self,
        _button = button,
        _nameLabel = nameLabel,
        _name = name,
        _icon = icon,
        _expandedWidth = expandedWidth,
        _content = content,
        _subtabBar = subBar,
        _contentHost = contentHost,
        _subtabs = {},
    }

    setmetatable(obj, {__index = TabMethods})
    table.insert(self._tabs, obj)

    button.MouseButton1Click:Connect(function()
        self:SetTab(obj)
    end)

    button.MouseEnter:Connect(function()
        if self._activeTab ~= obj then
            Tween(button, TI_FAST, {BackgroundColor3 = Library.Theme.Surface})
        end
    end)

    button.MouseLeave:Connect(function()
        if self._activeTab ~= obj then
            Tween(button, TI_FAST, {BackgroundColor3 = Library.Theme.Background})
        end
    end)

    if #self._tabs == 1 then
        local firstSub = obj:CreateSubtab({
            Name = name,
            Icon = icon,
        })
        obj._activeSubtab = firstSub
        self._activeTab = obj

        button.Size = UDim2.fromOffset(expandedWidth, 34)
        button.BackgroundColor3 = Library.Theme.Surface2
        nameLabel.TextTransparency = 0
        content.Visible = true
    end

    return obj
end

function WindowMethods:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true

    for _, window in ipairs(Library._windows) do
        if window == self then
            table.remove(Library._windows, table.find(Library._windows, self))
            break
        end
    end

    if self._gui then
        self._gui:Destroy()
    end
end

function WindowMethods:GetFlag(flag)
    return Library.Flags[flag]
end

function WindowMethods:SetFlag(flag, value)
    local control = Library._controls[flag]
    if control and control.Set then
        control:Set(value)
    else
        Library.Flags[flag] = value
    end
end

function WindowMethods:Notify(options)
    options = options or {}

    local text = tostring(options.Content or options.Text or "Notification")
    local title = tostring(options.Title or "Astral")

    local holder = self._notifications

    local card = New("Frame", {
        Parent = holder,
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 66),
    })
    AddCorner(card, 7)
    AddStroke(card, Library.Theme.Stroke, 0, 1)

    local titleLabel = MakeLabel(card, title, 11, Library.Theme.Text)
    titleLabel.Position = UDim2.fromOffset(12, 7)
    titleLabel.Size = UDim2.new(1, -24, 0, 18)

    local textLabel = MakeLabel(card, text, 10, Library.Theme.SubText)
    textLabel.Position = UDim2.fromOffset(12, 27)
    textLabel.Size = UDim2.new(1, -24, 0, 28)
    textLabel.TextWrapped = true

    card.BackgroundTransparency = 1
    card.Position = UDim2.fromOffset(24, 0)

    Tween(card, TI_SPRING, {
        BackgroundTransparency = 0,
        Position = UDim2.fromOffset(0, 0),
    })

    task.delay(options.Duration or 3, function()
        if card and card.Parent then
            local out = Tween(card, TI_MED, {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(24, 0),
            })
            out.Completed:Connect(function()
                if card then
                    card:Destroy()
                end
            end)
        end
    end)
end

function WindowMethods:BindToggle(keyCode)
    self._toggleKey = keyCode

    if self._toggleConnection then
        self._toggleConnection:Disconnect()
    end

    self._toggleConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.KeyCode == self._toggleKey then
            self:Toggle()
        end
    end)
end

function Library:CreateWindow(options)
    options = options or {}

    local parent = options.Parent

    local guiParent
    if parent and parent:IsA("PlayerGui") then
        guiParent = parent
    else
        guiParent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local gui = New("ScreenGui", {
        Name = options.Name or "AstralHub",
        Parent = guiParent,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = options.DisplayOrder or 999,
    })

    local backdrop = New("Frame", {
        Parent = gui,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    })

    local main = New("Frame", {
        Parent = backdrop,
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(760, 500),
        Position = UDim2.new(0.5, -380, 0.5, -250),
    })
    AddCorner(main, 9)
    AddStroke(main, Library.Theme.Stroke, 0, 1)

    local top = New("Frame", {
        Parent = main,
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
    })
    AddCorner(top, 9)

    local title = MakeLabel(top, options.Name or "Astral Hub", 12, Library.Theme.Accent, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(14, 0)
    title.Size = UDim2.new(0.5, -14, 1, 0)

    local author = MakeLabel(top, options.Author or "UI Library", 10, Library.Theme.Muted)
    author.TextXAlignment = Enum.TextXAlignment.Right
    author.Position = UDim2.new(0.5, 0, 0, 0)
    author.Size = UDim2.new(0.5, -14, 1, 0)

    local dragHandle = New("TextButton", {
        Parent = top,
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.new(1, -110, 1, 0),
        Position = UDim2.fromOffset(55, 0),
        ZIndex = 3,
    })
    MakeDraggable(dragHandle, main)

    local contentFrame = New("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(7, 45),
        Size = UDim2.new(1, -14, 1, -92),
    })

    local sidebar = New("Frame", {
        Parent = contentFrame,
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(150, 1),
        Position = UDim2.new(0, 0, 0, 0),
    })
    AddCorner(sidebar, 8)

    local tabBar = NewScrollingFrame(sidebar)
    tabBar.Position = UDim2.fromOffset(7, 7)
    tabBar.Size = UDim2.new(1, -14, 1, -14)
    tabBar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local tabLayout = tabBar:FindFirstChildOfClass("UIListLayout")
    tabLayout.Padding = UDim.new(0, 6)

    local contentContainer = New("Frame", {
        Parent = contentFrame,
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(158, 0),
        Size = UDim2.new(1, -158, 1, 0),
        ClipsDescendants = true,
    })
    AddCorner(contentContainer, 8)

    local footer = New("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 7, 1, -42),
        Size = UDim2.new(1, -14, 0, 34),
    })

    local footerLeft = New("Frame", {
        Parent = footer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -110, 1, 0),
    })
    AddList(footerLeft, 6, true)

    local footerRight = New("Frame", {
        Parent = footer,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -102, 0, 0),
        Size = UDim2.fromOffset(102, 34),
    })
    AddList(footerRight, 5, true, Enum.SortOrder.LayoutOrder)

    local configButton = New("TextButton", {
        Parent = footerRight,
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0,
        Text = "CFG",
        TextColor3 = Library.Theme.SubText,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        Size = UDim2.fromOffset(46, 30),
        AutoButtonColor = false,
        LayoutOrder = 1,
    })
    AddCorner(configButton, 6)

    local languageButton = New("TextButton", {
        Parent = footerRight,
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0,
        Text = options.Language or "ENG",
        TextColor3 = Library.Theme.SubText,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        Size = UDim2.fromOffset(46, 30),
        AutoButtonColor = false,
        LayoutOrder = 2,
    })
    AddCorner(languageButton, 6)

    local notifications = New("Frame", {
        Parent = gui,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -280, 0, 15),
        Size = UDim2.fromOffset(260, 300),
        ZIndex = 100,
    })
    AddList(notifications, 8, false)

    local window = {
        _gui = gui,
        _main = main,
        _size = options.Size or UDim2.fromOffset(760, 500),
        _visible = true,
        _tabs = {},
        _tabBar = tabBar,
        _contentContainer = contentContainer,
        _notifications = notifications,
        _activeTab = nil,
        _activeSubtab = nil,
        _toggleKey = options.ToggleKey or Enum.KeyCode.RightShift,
    }

    setmetatable(window, {__index = WindowMethods})
    table.insert(Library._windows, window)

    main.Size = window._size
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)

    -- Re-center the frame when the size changes at runtime.
    window._size = main.Size

    WindowMethods.BindToggle(window, window._toggleKey)

    configButton.MouseButton1Click:Connect(function()
        local configs = Library.Config:List()
        window:Notify({
            Title = "Config",
            Content = #configs == 0
                and "No saved configs"
                or ("Saved: " .. table.concat(configs, ", ")),
            Duration = 4,
        })
    end)

    return window
end

function Library:SetTheme(theme)
    for key, color in pairs(theme or {}) do
        if typeof(color) == "Color3" then
            Library.Theme[key] = color
        end
    end

    -- Rebuild windows so theme changes are applied consistently.
    for _, window in ipairs(Library._windows) do
        if window and window._gui then
            for _, descendant in ipairs(window._gui:GetDescendants()) do
                if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                    if descendant.TextColor3 == Color3.fromRGB(240, 240, 246) then
                        descendant.TextColor3 = Library.Theme.Text
                    end
                end
            end
        end
    end
end

function Library:Unload()
    for _, window in ipairs(Library._windows) do
        if window and not window._destroyed then
            window:Destroy()
        end
    end
    Library._windows = {}
    Library._controls = {}
end

return Library

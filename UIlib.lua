local Library = {}

local theme = {
    Main = Color3.fromRGB(29, 32, 33),
    Panel = Color3.fromRGB(50, 48, 47),
    Hover = Color3.fromRGB(62, 59, 57),
    Off = Color3.fromRGB(80, 73, 69),
    Accent = Color3.fromRGB(181, 148, 255),
    AccentBright = Color3.fromRGB(206, 184, 255),
    Text = Color3.fromRGB(235, 219, 178),
    Sub = Color3.fromRGB(168, 153, 132),
    Disabled = Color3.fromRGB(102, 92, 84),
    Red = Color3.fromRGB(251, 73, 52),
    Green = Color3.fromRGB(184, 187, 38),
    Blue = Color3.fromRGB(131, 165, 152),
}
Library.Theme = theme

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local keyNames = {
    [0x01] = "Mouse1", [0x02] = "Mouse2", [0x04] = "Mouse3", [0x05] = "XButton1", [0x06] = "XButton2",
    [0x08] = "Backspace", [0x09] = "Tab", [0x0D] = "Enter", [0x14] = "CapsLock", [0x1B] = "Escape", [0x20] = "Space",
    [0x21] = "PageUp", [0x22] = "PageDown", [0x23] = "End", [0x24] = "Home", [0x25] = "Left", [0x26] = "Up",
    [0x27] = "Right", [0x28] = "Down", [0x2D] = "Insert", [0x2E] = "Delete",
    [0xA0] = "LShift", [0xA1] = "RShift", [0xA2] = "LCtrl", [0xA3] = "RCtrl", [0xA4] = "LAlt", [0xA5] = "RAlt",
    [0xC0] = "`", [0xBA] = ";", [0xBB] = "=", [0xBC] = ",", [0xBD] = "-", [0xBE] = ".", [0xBF] = "/",
    [0xDB] = "[", [0xDC] = "\\", [0xDD] = "]", [0xDE] = "'",
}
for vk = 0x30, 0x39 do keyNames[vk] = string.char(vk) end
for vk = 0x41, 0x5A do keyNames[vk] = string.char(vk) end
for i = 1, 12 do keyNames[0x6F + i] = "F" .. i end
for i = 0, 9 do keyNames[0x60 + i] = "Num" .. i end

local genericModifiers = {[0x10] = true, [0x11] = true, [0x12] = true}

function Library.KeyName(vk)
    if not vk or vk == 0 then return "None" end
    return keyNames[vk] or string.format("0x%02X", vk)
end

local narrowChars = {i = true, l = true, j = true, I = true, ["."] = true, [","] = true, ["'"] = true, ["!"] = true, ["|"] = true, [":"] = true, [";"] = true, ["("] = true, [")"] = true}
local widthCache = {}

local function TextWidth(text, size)
    local key = size .. "|" .. text
    local width = widthCache[key]
    if width then return width end
    local units = 0
    for i = 1, #text do
        local ch = string.sub(text, i, i)
        if narrowChars[ch] then
            units += .28
        elseif ch == " " then
            units += .3
        elseif string.find(ch, "[MW]") then
            units += .71
        elseif string.find(ch, "[A-Z0-9]") then
            units += .54
        else
            units += .49
        end
    end
    width = units * size
    widthCache[key] = width
    return width
end

local function Round(value)
    return math.floor(value + .5)
end

local function Approach(current, target, dt, speed)
    if current == nil then return target end
    local value = current + (target - current) * (1 - math.exp(-speed * dt))
    if math.abs(target - value) < .002 then return target end
    return value
end

local function LerpColor(a, b, t)
    if t <= 0 then return a end
    if t >= 1 then return b end
    return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local function EaseOut(t)
    t = math.clamp(t, 0, 1)
    return 1 - (1 - t) ^ 3
end

local function EncodeValue(value)
    if typeof(value) == "Color3" then
        return {Color = {Round(value.R * 255), Round(value.G * 255), Round(value.B * 255)}}
    end
    return value
end

local function DecodeValue(value, default)
    if typeof(default) == "Color3" then
        if type(value) == "table" and type(value.Color) == "table" then
            local c = value.Color
            return Color3.fromRGB(tonumber(c[1]) or 0, tonumber(c[2]) or 0, tonumber(c[3]) or 0)
        end
        return nil
    end
    if type(default) == "number" then return tonumber(value) end
    if type(default) == "boolean" then
        if type(value) == "boolean" then return value end
        return nil
    end
    return value
end

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

local sidebarWidth = 160
local headerHeight = 78
local footerHeight = 30

function Library.new(options)
    options = options or {}
    local folder = options.Folder or "MatchaUI"
    _G.MatchaUIWindows = _G.MatchaUIWindows or {}
    local old = _G.MatchaUIWindows[folder]
    if old then old:destroy() end

    local self = setmetatable({
        Title = options.Title or "Matcha",
        Subtitle = options.Subtitle or "",
        Version = options.Version or "1.0",
        Footer = options.Footer or "",
        Folder = folder,
        MenuKey = options.Keybind or 0xA1,
        BlockInput = options.BlockInput == true,
        Font = options.Font or (Drawing.Fonts and (Drawing.Fonts.SystemBold or Drawing.Fonts.System)),
        X = 140, Y = 120,
        Width = options.Width or 680,
        Height = options.Height or 500,
        Visible = true,
        Alive = true,
        Fade = 0,
        Alpha = 0,
        Scale = 1,
        DrawAlpha = 1,
        Dt = 0,
        SwitchAt = 0,
        Tabs = {},
        Flags = {},
        Saved = {},
        Listeners = {},
        Loaded = {},
        Pools = {Square = {}, Text = {}},
        Used = {Square = 0, Text = 0},
        Mouse = {X = 0, Y = 0, Down = false, Clicked = false},
        MenuKeyDown = false,
    }, Window)
    _G.MatchaUIWindows[folder] = self
    self:LoadConfig()
    local saved = self.Loaded.__window
    if type(saved) == "table" then
        self.X = tonumber(saved[1]) or self.X
        self.Y = tonumber(saved[2]) or self.Y
        self.Width = math.max(tonumber(saved[3]) or self.Width, 520)
        self.Height = math.max(tonumber(saved[4]) or self.Height, 340)
    end
    return self
end

function Window:LoadConfig()
    local path = self.Folder .. "/config.json"
    if not isfile(path) then return end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
    if ok and type(data) == "table" then self.Loaded = data end
end

function Window:SaveConfig()
    self.Dirty = nil
    local data = {__window = {self.X, self.Y, self.Width, self.Height}}
    for name in self.Saved do data[name] = EncodeValue(self.Flags[name]) end
    if not isfolder(self.Folder) then makefolder(self.Folder) end
    local ok, text = pcall(HttpService.JSONEncode, HttpService, data)
    if ok then writefile(self.Folder .. "/config.json", text) end
end

function Window:Register(name, default, save)
    local loaded = self.Loaded[name]
    local value = default
    if loaded ~= nil then
        local decoded = DecodeValue(loaded, default)
        if decoded ~= nil then value = decoded end
    end
    self.Flags[name] = value
    if save ~= false then self.Saved[name] = true end
    return value
end

function Window:flag(name, default, save)
    return self:Register(name, default, save)
end

function Window:get(name)
    return self.Flags[name]
end

function Window:set(name, value)
    if self.Flags[name] == value then return end
    self.Flags[name] = value
    for _, callback in self.Listeners[name] or {} do
        local ok, err = pcall(callback, value)
        if not ok then print("[MatchaUI] callback for " .. tostring(name) .. " failed: " .. tostring(err)) end
    end
    if self.Saved[name] then self.Dirty = os.clock() end
end

function Window:Listen(name, callback)
    if not callback then return end
    self.Listeners[name] = self.Listeners[name] or {}
    table.insert(self.Listeners[name], callback)
end

function Window:keyHeld(name)
    local vk = self.Flags[name]
    if not vk or vk == 0 or self.Listening then return false end
    return isrbxactive() and iskeypressed(vk)
end

function Window:tab(name)
    local tab = setmetatable({Name = name, Window = self, Sections = {}, Current = 1}, Tab)
    table.insert(self.Tabs, tab)
    self.CurrentTab = self.CurrentTab or tab
    return tab
end

function Tab:section(name)
    local section = setmetatable({Name = name, Tab = self, Window = self.Window, Controls = {}}, Section)
    table.insert(self.Sections, section)
    return section
end

local function AddControl(section, kind, options, default)
    local control = {Type = kind, Name = options.Name or "", Options = options, Show = options.Show, Flag = options.Flag}
    if control.Flag then
        section.Window:Register(control.Flag, if options.Default ~= nil then options.Default else default, options.Save)
        section.Window:Listen(control.Flag, options.Callback)
    elseif kind ~= "button" and kind ~= "label" then
        control.Flag = "__" .. kind .. "_" .. tostring(#section.Controls) .. "_" .. section.Name .. "_" .. control.Name
        section.Window:Register(control.Flag, if options.Default ~= nil then options.Default else default, false)
        section.Window:Listen(control.Flag, options.Callback)
    end
    table.insert(section.Controls, control)
    return section
end

function Section:toggle(options)
    return AddControl(self, "toggle", options, false)
end

function Section:slider(options)
    options.Min, options.Max = options.Min or 0, options.Max or 100
    return AddControl(self, "slider", options, options.Min)
end

function Section:dropdown(options)
    options.Values = options.Values or {}
    return AddControl(self, "dropdown", options, options.Values[1])
end

function Section:color(options)
    return AddControl(self, "color", options, Color3.new(1, 1, 1))
end

function Section:keybind(options)
    return AddControl(self, "keybind", options, 0)
end

function Section:button(options)
    return AddControl(self, "button", options)
end

function Section:label(options)
    if type(options) == "string" then options = {Text = options} end
    return AddControl(self, "label", options)
end

local deadEntry = {Object = {}, Cache = {}}

function Window:Draw(kind)
    if not self.Alive then return deadEntry end
    local used = self.Used[kind] + 1
    self.Used[kind] = used
    local pool = self.Pools[kind]
    local entry = pool[used]
    if not entry then
        entry = {Object = Drawing.new(kind), Cache = {}}
        pool[used] = entry
    end
    return entry
end

local function Set(entry, key, value)
    local old = entry.Cache[key]
    if old ~= value and typeof(value) == "Color3" and typeof(old) == "Color3" and old.R == value.R and old.G == value.G and old.B == value.B then return end
    if old ~= value then
        entry.Cache[key] = value
        entry.Object[key] = value
    end
end

local function SetPosition(entry, x, y)
    local cache = entry.Cache
    if cache.PX ~= x or cache.PY ~= y then
        cache.PX, cache.PY = x, y
        entry.Object.Position = Vector2.new(x, y)
    end
end

local function SetSize(entry, w, h)
    local cache = entry.Cache
    if cache.SW ~= w or cache.SH ~= h then
        cache.SW, cache.SH = w, h
        entry.Object.Size = Vector2.new(w, h)
    end
end

function Window:Transform(x, y)
    local row = self.RowScale
    if row then
        x = self.RowX + (x - self.RowX) * row
        y = self.RowY + (y - self.RowY) * row
    end
    local scale = self.Scale
    if scale == 1 then return x, y end
    local ox, oy = self.X + self.Width / 2, self.Y + self.Height / 2
    return ox + (x - ox) * scale, oy + (y - oy) * scale
end

function Window:Rect(x, y, w, h, color, corner, z, filled, alpha)
    local entry = self:Draw("Square")
    local scale = self.Scale * (self.RowScale or 1)
    x, y = self:Transform(x, y)
    w, h = w * scale, h * scale
    if corner then corner *= scale end
    SetPosition(entry, Round(x), Round(y))
    SetSize(entry, Round(math.max(w, 0)), Round(math.max(h, 0)))
    Set(entry, "Color", color)
    Set(entry, "Filled", filled ~= false)
    Set(entry, "Corner", corner or 0)
    Set(entry, "Thickness", 1)
    Set(entry, "Transparency", (alpha or 1) * self.DrawAlpha)
    Set(entry, "ZIndex", z or 100)
    Set(entry, "Visible", true)
end

function Window:Text(text, x, y, size, color, z)
    local entry = self:Draw("Text")
    x, y = self:Transform(x, y)
    Set(entry, "Text", text)
    Set(entry, "Size", Round(size * self.Scale * (self.RowScale or 1)))
    Set(entry, "Font", self.Font)
    Set(entry, "Color", color)
    Set(entry, "Outline", false)
    Set(entry, "Center", false)
    Set(entry, "Transparency", self.DrawAlpha)
    Set(entry, "ZIndex", z or 105)
    SetPosition(entry, Round(x), Round(y))
    Set(entry, "Visible", true)
end

function Window:Hover(x, y, w, h)
    local m = self.Mouse
    return m.X >= x and m.X < x + w and m.Y >= y and m.Y < y + h
end

function Window:Clicked(x, y, w, h)
    return self.Mouse.Clicked and not self.Blocked and self:Hover(x, y, w, h)
end

local function Fit(text, width, size)
    local limit = math.max(1, math.floor(width / (size * .55)))
    if #text <= limit then return text end
    return string.sub(text, 1, math.max(1, limit - 2)) .. ".."
end

local function Run(callback, ...)
    if not callback then return end
    local ok, err = pcall(callback, ...)
    if not ok then print("[MatchaUI] callback failed: " .. tostring(err)) end
end

local controlHeights = {toggle = 28, slider = 40, dropdown = 28, color = 28, keybind = 28, button = 30, label = 22}

local drawers = {}

drawers.toggle = function(self, c, x, y, w)
    local on = self.Flags[c.Flag] == true
    local hovered = self:Hover(x - 6, y, w + 12, 28) and not self.Blocked
    c.HoverAnim = Approach(c.HoverAnim or 0, if hovered then 1 else 0, self.Dt, 20)
    if c.HoverAnim > 0 then self:Rect(x - 6, y, w + 12, 28, theme.Hover, 6, 102, true, c.HoverAnim) end
    self:Text(Fit(c.Name, w - 50, 13), x, y + 7, 13, theme.Text)
    c.Anim = Approach(c.Anim, if on then 1 else 0, self.Dt, 18)
    local a = EaseOut(c.Anim)
    local sx = x + w - 34
    self:Rect(sx, y + 6, 34, 16, LerpColor(theme.Off, theme.Accent, a), 8, 103)
    self:Rect(sx + 2 + 18 * a, y + 8, 12, 12, LerpColor(theme.Text, theme.Main, a), 6, 104)
    if self:Clicked(x - 6, y, w + 12, 28) then self:set(c.Flag, not on) end
end

drawers.slider = function(self, c, x, y, w)
    local o = c.Options
    local value = tonumber(self.Flags[c.Flag]) or o.Min
    local text = string.format(o.Format or (if o.Float then "%.2f" else "%d"), value)
    self:Text(Fit(c.Name, w - 60, 13), x, y + 3, 13, theme.Text)
    self:Text(text, x + w - TextWidth(text, 12), y + 4, 12, theme.Sub)
    local frac = Approach(c.Anim, math.clamp((value - o.Min) / math.max(o.Max - o.Min, 1e-6), 0, 1), self.Dt, 22)
    c.Anim = frac
    self:Rect(x, y + 26, w, 4, theme.Off, 2, 103)
    self:Rect(x, y + 26, w * frac, 4, theme.Accent, 2, 104)
    self:Rect(x + w * frac - 6, y + 22, 12, 12, theme.AccentBright, 6, 105)
    if self:Clicked(x - 4, y + 16, w + 8, 22) then self.Drag = {Kind = "slider", Control = c, X = x, W = w} end
end

drawers.dropdown = function(self, c, x, y, w)
    local values = c.Options.Values
    if type(values) == "function" then values = values(self) end
    local boxWidth = math.min(170, w * .5)
    local bx = x + w - boxWidth
    self:Text(Fit(c.Name, w - boxWidth - 10, 13), x, y + 7, 13, theme.Text)
    local open = self.Open and self.Open.Control == c
    self:Rect(bx, y + 3, boxWidth, 22, if open or self:Hover(bx, y + 3, boxWidth, 22) then theme.Hover else theme.Main, 6, 103)
    self:Rect(bx, y + 3, boxWidth, 22, theme.Off, 6, 104, false)
    self:Text(Fit(tostring(self.Flags[c.Flag] or ""), boxWidth - 26, 12), bx + 8, y + 7, 12, theme.Text)
    self:Text(if open then "^" else "v", bx + boxWidth - 15, y + 6, 12, theme.Sub)
    if self:Clicked(bx, y + 3, boxWidth, 22) then
        if open then
            self.Open = nil
        else
            self.Open = {Kind = "dropdown", Control = c, Values = values, X = bx, Y = y + 27, W = boxWidth, H = #values * 22 + 4}
        end
    end
end

drawers.color = function(self, c, x, y, w)
    local value = self.Flags[c.Flag]
    self:Text(Fit(c.Name, w - 50, 13), x, y + 7, 13, theme.Text)
    local sx = x + w - 36
    self:Rect(sx, y + 6, 36, 16, value, 5, 103)
    self:Rect(sx, y + 6, 36, 16, theme.Off, 5, 104, false)
    if self:Clicked(sx - 4, y, 44, 28) then
        if self.Open and self.Open.Control == c then
            self.Open = nil
        else
            self.Open = {Kind = "color", Control = c, X = x + w - 230, Y = y + 28, W = 230, H = 118}
        end
    end
end

drawers.keybind = function(self, c, x, y, w)
    local listening = self.Listening and self.Listening.Control == c
    local text = if listening then "..." else Library.KeyName(self.Flags[c.Flag])
    local chipWidth = TextWidth(text, 11) + 18
    local cx = x + w - chipWidth
    self:Text(Fit(c.Name, w - chipWidth - 10, 13), x, y + 7, 13, theme.Text)
    self:Rect(cx, y + 5, chipWidth, 18, if listening then theme.Accent else theme.Main, 6, 103)
    self:Rect(cx, y + 5, chipWidth, 18, theme.Off, 6, 104, false)
    self:Text(text, cx + 9, y + 8, 11, if listening then theme.Main else theme.Sub)
    if self:Clicked(cx - 4, y, chipWidth + 8, 28) and not listening then
        local ignore = {}
        for vk = 1, 254 do
            if iskeypressed(vk) then ignore[vk] = true end
        end
        self.Listening = {Control = c, Ignore = ignore, Since = os.clock()}
    end
end

drawers.button = function(self, c, x, y, w)
    local hovered = self:Hover(x, y + 2, w, 26) and not self.Blocked
    c.HoverAnim = Approach(c.HoverAnim or 0, if hovered then 1 else 0, self.Dt, 20)
    c.Flash = Approach(c.Flash or 0, 0, self.Dt, 8)
    local fill = LerpColor(LerpColor(theme.Main, theme.Hover, c.HoverAnim), theme.Accent, c.Flash)
    self:Rect(x, y + 2, w, 26, fill, 7, 103)
    self:Rect(x, y + 2, w, 26, LerpColor(theme.Off, theme.Accent, c.HoverAnim), 7, 104, false)
    local text = Fit(c.Name, w - 16, 13)
    self:Text(text, x + (w - TextWidth(text, 13)) / 2, y + 8, 13, LerpColor(theme.Text, theme.Main, c.Flash))
    if self:Clicked(x, y + 2, w, 26) then
        c.Flash = 1
        Run(c.Options.Callback, self)
    end
end

drawers.label = function(self, c, x, y, w)
    local o = c.Options
    local text = if o.Label then tostring(o.Label(self)) else tostring(o.Text or c.Name)
    local size = o.Size or 12
    text = Fit(text, w, size)
    local tx = if o.Center then x + (w - TextWidth(text, size)) / 2 else x
    self:Text(text, tx, y + 4, size, if o.Accent then theme.Accent else theme.Sub)
end

function Window:DrawPopup(open, interactive)
    open.Anim = Approach(open.Anim or 0, if interactive then 1 else 0, self.Dt, 16)
    local e = EaseOut(open.Anim)
    self.DrawAlpha = self.Alpha * e
    local c = open.Control
    if open.Kind == "dropdown" then
        local height = math.max(open.H * e, 6)
        self:Rect(open.X, open.Y, open.W, height, theme.Main, 8, 110)
        self:Rect(open.X, open.Y, open.W, height, theme.Off, 8, 111, false)
        local current = self.Flags[c.Flag]
        for i, value in open.Values do
            local iy = open.Y + 2 + (i - 1) * 22
            if iy + 20 > open.Y + height then break end
            local hovered = interactive and self:Hover(open.X + 2, iy, open.W - 4, 20)
            if hovered or value == current then
                self:Rect(open.X + 2, iy, open.W - 4, 20, if value == current then theme.Panel else theme.Hover, 6, 112)
            end
            self:Text(Fit(tostring(value), open.W - 16, 13), open.X + 8, iy + 3, 13, if value == current then theme.AccentBright else theme.Text, 113)
            if self.Mouse.Clicked and hovered then
                self.Open = nil
                self:set(c.Flag, value)
            end
        end
    elseif open.Kind == "color" then
        local value = self.Flags[c.Flag]
        local channels = {value.R, value.G, value.B}
        open = {X = open.X, Y = open.Y - 8 * (1 - e), W = open.W, H = open.H}
        local names = {"R", "G", "B"}
        local tints = {theme.Red, theme.Green, theme.Blue}
        self:Rect(open.X, open.Y, open.W, open.H, theme.Main, 8, 110)
        self:Rect(open.X, open.Y, open.W, open.H, theme.Off, 8, 111, false)
        for i = 1, 3 do
            local ry = open.Y + 10 + (i - 1) * 24
            local tx, tw = open.X + 28, 150
            c.ChannelAnim = c.ChannelAnim or {}
            channels[i] = Approach(c.ChannelAnim[i], channels[i], self.Dt, 22)
            c.ChannelAnim[i] = channels[i]
            self:Text(names[i], open.X + 12, ry, 12, theme.Sub, 113)
            self:Rect(tx, ry + 6, tw, 4, theme.Off, 2, 112)
            self:Rect(tx, ry + 6, tw * channels[i], 4, tints[i], 2, 113)
            self:Rect(tx + tw * channels[i] - 5, ry + 3, 10, 10, theme.Text, 5, 114)
            self:Text(tostring(Round(channels[i] * 255)), tx + tw + 10, ry, 12, theme.Text, 113)
            if interactive and self.Mouse.Clicked and self:Hover(tx - 4, ry, tw + 8, 16) then
                self.Drag = {Kind = "channel", Control = c, Channel = i, X = tx, W = tw}
            end
        end
        local hex = string.format("#%02X%02X%02X", Round(value.R * 255), Round(value.G * 255), Round(value.B * 255))
        self:Text(hex, open.X + 12, open.Y + 88, 12, theme.Sub, 113)
        self:Rect(open.X + open.W - 76, open.Y + 85, 64, 20, value, 6, 112)
        self:Rect(open.X + open.W - 76, open.Y + 85, 64, 20, theme.Off, 6, 113, false)
    end
    self.DrawAlpha = self.Alpha
    return open.Anim
end

function Window:DrawOpen()
    if self.LastOpen and self.LastOpen ~= self.Open then self.Closing = self.LastOpen end
    self.LastOpen = self.Open
    if self.Closing and self:DrawPopup(self.Closing, false) <= 0 then self.Closing = nil end
    if self.Open then self:DrawPopup(self.Open, true) end
end

function Window:UpdateDrag()
    local drag = self.Drag
    if not drag then return end
    local m = self.Mouse
    if not m.Down then
        if drag.Kind == "window" or drag.Kind == "resize" then self.Dirty = os.clock() end
        self.Drag = nil
        return
    end
    if drag.Kind == "window" then
        self.X, self.Y = m.X - drag.OX, m.Y - drag.OY
    elseif drag.Kind == "resize" then
        self.Width = math.max(520, m.X - self.X + drag.OX)
        self.Height = math.max(340, m.Y - self.Y + drag.OY)
    elseif drag.Kind == "slider" then
        local o = drag.Control.Options
        local frac = math.clamp((m.X - drag.X) / drag.W, 0, 1)
        local value = o.Min + frac * (o.Max - o.Min)
        local step = o.Step or (if o.Float then .01 else 1)
        value = math.clamp(math.floor(value / step + .5) * step, o.Min, o.Max)
        self:set(drag.Control.Flag, value)
    elseif drag.Kind == "channel" then
        local value = self.Flags[drag.Control.Flag]
        local channels = {value.R, value.G, value.B}
        channels[drag.Channel] = math.clamp((m.X - drag.X) / drag.W, 0, 1)
        self:set(drag.Control.Flag, Color3.new(channels[1], channels[2], channels[3]))
    end
end

function Window:UpdateListening()
    local listen = self.Listening
    if not listen then return end
    if self.Mouse.Clicked and os.clock() - listen.Since > .05 then
        self.Listening = nil
        return
    end
    for vk = 2, 254 do
        if not genericModifiers[vk] then
            local held = iskeypressed(vk)
            if held and not listen.Ignore[vk] then
                self.Listening = nil
                self:set(listen.Control.Flag, if vk == 0x1B then 0 else vk)
                return
            elseif not held then
                listen.Ignore[vk] = nil
            end
        end
    end
end

function Window:DrawWindow()
    local x, y, w, h = self.X, self.Y, self.Width, self.Height
    local m = self.Mouse

    self.Blocked = not self.Visible
    local open = self.Open
    if open and m.Clicked and not self:Hover(open.X, open.Y, open.W, open.H) then
        self.Open = nil
        self.Blocked = true
    elseif open and self:Hover(open.X, open.Y, open.W, open.H) then
        self.Blocked = true
    end
    if self.Drag then self.Blocked = true end

    if self:Clicked(x + w - 14, y + h - 14, 14, 14) then
        self.Drag = {Kind = "resize", OX = x + w - m.X, OY = y + h - m.Y}
        self.Blocked = true
    elseif self:Clicked(x, y, sidebarWidth, 62) or self:Clicked(x + sidebarWidth, y, w - sidebarWidth - 46, 44) then
        self.Drag = {Kind = "window", OX = m.X - x, OY = m.Y - y}
        self.Blocked = true
    end

    self:Rect(x - 1, y - 1, w + 2, h + 2, theme.Off, 12, 99, false, .8)
    self:Rect(x, y, w, h, theme.Main, 12, 100)
    self:Rect(x + sidebarWidth, y + 12, 1, h - 24, theme.Off, 0, 101)

    self:Text(self.Title, x + 16, y + 16, 17, theme.Text)
    if self.Subtitle ~= "" then self:Text(self.Subtitle, x + 16, y + 38, 11, theme.Accent) end
    self:Rect(x + 14, y + 60, sidebarWidth - 28, 1, theme.Off, 0, 101)

    local ty = y + 72
    for i, tab in self.Tabs do
        local selected = tab == self.CurrentTab
        local hovered = self:Hover(x + 8, ty, sidebarWidth - 16, 28) and not self.Blocked
        if selected then
            self.TabAnim = Approach(self.TabAnim, i, self.Dt, 18)
        elseif hovered then
            self:Rect(x + 8, ty, sidebarWidth - 16, 28, theme.Hover, 8, 102)
        end
        self:Text(Fit(tab.Name, sidebarWidth - 40, 13), x + 22, ty + 7, 13, if selected then theme.Text else theme.Sub)
        if self:Clicked(x + 8, ty, sidebarWidth - 16, 28) and not selected then
            self.CurrentTab = tab
            self.Open = nil
            self.SwitchAt = os.clock()
        end
        ty += 31
    end
    if self.TabAnim then
        local sy = y + 72 + (self.TabAnim - 1) * 31
        self:Rect(x + 8, sy, sidebarWidth - 16, 28, theme.Panel, 8, 102)
        self:Rect(x + 8, sy + 7, 3, 14, theme.Accent, 1, 103)
    end

    local version = "V" .. tostring(self.Version)
    local versionWidth = TextWidth(version, 11) + 16
    self:Rect(x + 12, y + h - 34, versionWidth, 22, theme.Off, 8, 101, false)
    self:Text(version, x + 20, y + h - 29, 11, theme.Sub)

    local cx, cw = x + sidebarWidth + 12, w - sidebarWidth - 24
    local tab = self.CurrentTab
    local unloadX = x + w - 34
    local unloadHovered = self:Hover(unloadX, y + 12, 22, 22) and not self.Blocked
    self:Rect(unloadX, y + 12, 22, 22, if unloadHovered then theme.Red else theme.Panel, 8, 102)
    self:Text("U", unloadX + 7, y + 16, 12, if unloadHovered then theme.Main else theme.Sub)
    if self:Clicked(unloadX, y + 12, 22, 22) then
        self:destroy()
        return
    end

    if not tab then return end
    self:Text(tab.Name, cx + 2, y + 14, 18, theme.Text)

    local chipX = cx
    for i, section in tab.Sections do
        local label = string.upper(section.Name)
        local chipWidth = TextWidth(label, 11) + 26
        local selected = i == tab.Current
        local hovered = self:Hover(chipX, y + 46, chipWidth, 22) and not self.Blocked
        self:Rect(chipX, y + 46, chipWidth, 22, if hovered and not selected then theme.Hover else theme.Panel, 11, 102)
        self:Text(label, chipX + 13, y + 51, 11, if selected then theme.Main else theme.Sub, 105)
        if selected then
            tab.ChipX = Approach(tab.ChipX, chipX - cx, self.Dt, 18)
            tab.ChipW = Approach(tab.ChipW, chipWidth, self.Dt, 18)
        end
        if self:Clicked(chipX, y + 46, chipWidth, 22) and not selected then
            tab.Current = i
            self.Open = nil
            self.SwitchAt = os.clock()
        end
        chipX += chipWidth + 6
    end
    if tab.ChipX then self:Rect(cx + tab.ChipX, y + 46, tab.ChipW, 22, theme.Accent, 11, 103) end

    local py, ph = y + headerHeight, h - headerHeight - footerHeight
    self:Rect(cx, py, cw, ph, theme.Panel, 10, 101)
    self:Rect(cx, py, cw, ph, theme.Off, 10, 102, false, .6)

    local section = tab.Sections[tab.Current]
    local count = 0
    if section then
        local switch = EaseOut((os.clock() - self.SwitchAt) / .2)
        self.DrawAlpha = self.Alpha * switch
        local rx, rw, ry, bottom = cx + 12, cw - 24, py + 8 + (1 - switch) * 10, py + ph - 6
        local blocked = self.Blocked
        for _, c in section.Controls do
            local shown = not c.Show or c.Show(self)
            if shown then count += 1 end
            if c.SeenFrame ~= self.Frame - 1 then c.Appear = nil end
            c.SeenFrame = self.Frame
            c.Appear = Approach(c.Appear, if shown then 1 else 0, self.Dt, 16)
            if c.Appear > 0 then
                local e = EaseOut(c.Appear)
                local height = controlHeights[c.Type] or 28
                if c.Type == "label" and c.Options.Height then height = c.Options.Height end
                if ry + height <= bottom then
                    local centreY = ry + height / 2
                    self.DrawAlpha = self.Alpha * switch * e
                    if e < 1 then self.RowScale, self.RowX, self.RowY = .7 + .3 * e, rx + rw / 2, centreY end
                    self.Blocked = blocked or not shown or e < 1
                    drawers[c.Type](self, c, rx, ry, rw)
                    self.RowScale = nil
                end
                ry += (height + 4) * e
            end
        end
        self.Blocked = blocked
        self.DrawAlpha = self.Alpha
    end

    if self.Footer ~= "" then self:Text(self.Footer, cx + 2, y + h - 21, 11, theme.Sub) end
    local options = count .. " options"
    self:Text(options, cx + cw - TextWidth(options, 11) - 2, y + h - 21, 11, theme.Sub)
    self:Rect(x + w - 9, y + h - 9, 3, 3, theme.Off, 1, 101)
    self:Rect(x + w - 14, y + h - 9, 3, 3, theme.Off, 1, 101)
    self:Rect(x + w - 9, y + h - 14, 3, 3, theme.Off, 1, 101)

    self:DrawOpen()
end

function Window:Step()
    local m = self.Mouse
    self.Frame = (self.Frame or 0) + 1
    local now = os.clock()
    self.Dt = math.min(now - (self.LastStep or now), .1)
    self.LastStep = now
    if not self.MouseObject then
        local player = Players.LocalPlayer
        self.MouseObject = player and player:GetMouse()
    end
    local mouse = self.MouseObject
    local held = ismouse1pressed() and isrbxactive()
    m.Clicked = held and not m.Down
    m.Down = held
    if mouse then m.X, m.Y = mouse.X, mouse.Y end

    local menuKey = self.Flags.__menukey or self.MenuKey
    local keyDown = menuKey ~= 0 and isrbxactive() and iskeypressed(menuKey)
    if keyDown and not self.MenuKeyDown and not self.Listening then
        self.Visible = not self.Visible
        self.Open, self.Drag = nil, nil
    end
    self.MenuKeyDown = keyDown

    self.Fade = math.clamp(self.Fade + (if self.Visible then 1 else -1) * self.Dt / .18, 0, 1)
    self.Alpha = EaseOut(self.Fade)
    self.Scale = .9 + .1 * self.Alpha
    self.DrawAlpha = self.Alpha

    self.Used.Square, self.Used.Text = 0, 0
    if self.Visible then
        self:UpdateListening()
        self:UpdateDrag()
    end
    if self.Fade > 0 then self:DrawWindow() end
    if not self.Alive then return end
    for kind, pool in self.Pools do
        for i = self.Used[kind] + 1, #pool do Set(pool[i], "Visible", false) end
    end

    if self.BlockInput then
        local block = self.Visible and (self.Drag ~= nil or self.Open ~= nil or self:Hover(self.X, self.Y, self.Width, self.Height))
        if block ~= self.InputBlocked then
            self.InputBlocked = block
            setrobloxinput(not block)
        end
    end

    if self.Dirty and os.clock() - self.Dirty > 1 then self:SaveConfig() end
end

function Window:start()
    local settings = self:tab("Settings"):section("Menu")
    settings:keybind({Name = "Menu key", Flag = "__menukey", Default = self.MenuKey})
    settings:button({Name = "Save config", Callback = function(window) window:SaveConfig() end})
    settings:button({Name = "Unload", Callback = function(window) window:destroy() end})

    for name, callbacks in self.Listeners do
        for _, callback in callbacks do Run(callback, self.Flags[name]) end
    end

    task.spawn(function()
        while self.Alive do
            self:Step()
            task.wait(1 / 60)
        end
    end)
    return self
end

function Window:destroy()
    if not self.Alive then return end
    self.Alive = false
    if self.Dirty then self:SaveConfig() end
    for _, pool in self.Pools do
        for _, entry in pool do entry.Object:Remove() end
    end
    self.Pools = {Square = {}, Text = {}}
    if self.InputBlocked then setrobloxinput(true) end
    if _G.MatchaUIWindows and _G.MatchaUIWindows[self.Folder] == self then _G.MatchaUIWindows[self.Folder] = nil end
    Run(self.OnUnload)
end

_G.MatchaUILib = Library
return Library

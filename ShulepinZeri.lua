if Player.CharName ~= "Zeri" then return end

local Zeri = {}
local Script = {
    Name = "Shulepin" .. Player.CharName,
    Version = "1.0.4",
    LastUpdated = "22/01/2022",
    Changelog = {
        [1] = "[22/01/2022 - Version 1.0.0]: Initial release",
    }
}

module(Script.Name, package.seeall, log.setup)
clean.module(Script.Name, clean.seeall, log.setup)
CoreEx.AutoUpdate("https://robur.site/shulepin/robur/raw/branch/master/" .. Script.Name .. ".lua", Script.Version)

--[[
     █████  ██████  ██ 
    ██   ██ ██   ██ ██ 
    ███████ ██████  ██ 
    ██   ██ ██      ██ 
    ██   ██ ██      ██                                  
]]

local SDK = _G.CoreEx
local Player = _G.Player

local DamageLib, CollisionLib, DashLib, HealthPred, ImmobileLib, Menu, Orbwalker, Prediction, Profiler, Spell, TargetSelector =
_G.Libs.DamageLib, _G.Libs.CollisionLib, _G.Libs.DashLib, _G.Libs.HealthPred, _G.Libs.ImmobileLib, _G.Libs.NewMenu,
_G.Libs.Orbwalker, _G.Libs.Prediction, _G.Libs.Profiler, _G.Libs.Spell, _G.Libs.TargetSelector()

local AutoUpdate, Enums, EvadeAPI, EventManager, Game, Geometry, Input, Nav, ObjectManager, Renderer =
SDK.AutoUpdate, SDK.Enums, SDK.EvadeAPI, SDK.EventManager, SDK.Game, SDK.Geometry, SDK.Input, SDK.Nav, SDK.ObjectManager, SDK.Renderer

local AbilityResourceTypes, BuffType, DamageTypes, Events, GameMaps, GameObjectOrders, HitChance, ItemSlots, 
ObjectTypeFlags, PerkIDs, QueueTypes, SpellSlots, SpellStates, Teams = 
Enums.AbilityResourceTypes, Enums.BuffTypes, Enums.DamageTypes, Enums.Events, Enums.GameMaps, Enums.GameObjectOrders,
Enums.HitChance, Enums.ItemSlots, Enums.ObjectTypeFlags, Enums.PerkIDs, Enums.QueueTypes, Enums.SpellSlots, Enums.SpellStates,
Enums.Teams

local Vector, BestCoveringCircle, BestCoveringCone, BestCoveringRectangle, Circle, CircleCircleIntersection,
Cone, LineCircleIntersection, Path, Polygon, Rectangle, Ring =
Geometry.Vector, Geometry.BestCoveringCircle, Geometry.BestCoveringCone, Geometry.BestCoveringRectangle, Geometry.Circle,
Geometry.CircleCircleIntersection, Geometry.Cone, Geometry.LineCircleIntersection, Geometry.Path, Geometry.Polygon,
Geometry.Rectangle, Geometry.Ring

local abs, acos, asin, atan, ceil, cos, deg, exp, floor, fmod, huge, log, max, min, modf, pi, rad, random, randomseed, sin,
sqrt, tan, type, ult = 
_G.math.abs, _G.math.acos, _G.math.asin, _G.math.atan, _G.math.ceil, _G.math.cos, _G.math.deg, _G.math.exp,
_G.math.floor, _G.math.fmod, _G.math.huge, _G.math.log, _G.math.max, _G.math.min, _G.math.modf, _G.math.pi, _G.math.rad,
_G.math.random, _G.math.randomseed, _G.math.sin, _G.math.sqrt, _G.math.tan, _G.math.type, _G.math.ult

local byte, char, dump, ends_with, find, format, gmatch, gsub, len, lower, match, pack, packsize, rep, reverse,
starts_with, sub, unpack, upper = 
_G.string.byte, _G.string.char, _G.string.dump, _G.string.ends_with, _G.string.find, _G.string.format,
_G.string.gmatch, _G.string.gsub, _G.string.len, _G.string.lower, _G.string.match, _G.string.pack, _G.string.packsize,
_G.string.rep, _G.string.reverse, _G.string.starts_with, _G.string.sub, _G.string.unpack, _G.string.upper

local clock, date, difftime, execute, exit, getenv, remove, rename, setlocale, time, tmpname = 
_G.os.clock, _G.os.date, _G.os.difftime, _G.os.execute, _G.os.exit, _G.os.getenv, _G.os.remove, _G.os.rename, _G.os.setlocale,
_G.os.time, _G.os.tmpname

local Resolution = Renderer.GetResolution()

--[[
    ██    ██ ████████ ██ ██      ██ ████████ ██    ██ 
    ██    ██    ██    ██ ██      ██    ██     ██  ██  
    ██    ██    ██    ██ ██      ██    ██      ████   
    ██    ██    ██    ██ ██      ██    ██       ██    
     ██████     ██    ██ ███████ ██    ██       ██  
]]

local LMBPressed = false
local MMBPressed = false
local HitChanceList = { "Collision", "OutOfRange", "VeryLow", "Low", "Medium", "High", "VeryHigh", "Dashing", "Immobile" }
local KeyCodes = {[0] = "MouseButtonUp",[1] = "LMB",[2] = "RMB",[3] = "Cancel",[4] = "MMB",[5] = "MB4",[6] = "MB4",[8] = "Back",[9] = "Tab",[10] = "LineFeed",[12] = "Clear",[13] = "Return",[16] = "Shift",[17] = "ControlKey",[18] = "Alt",[19] = "Pause",[20] = "Capital",[21] = "KanaMode",[23] = "JunjaMode",[24] = "FinalMode",[25] = "HanjaMode",[27] = "Escape",[28] = "IMEConvert",[29] = "IMENonconvert",[30] = "IMEAceept",[31] = "IMEModeChange",[32] = "Space",[33] = "PageUp",[34] = "PageDown",[35] = "End",[36] = "Home",[37] = "Left",[38] = "Up",[39] = "Right",[40] = "Down",[41] = "Select",[42] = "Print",[43] = "Execute",[44] = "PrintScreen",[45] = "Insert",[46] = "Delete",[47] = "Help",[48] = "D0",[49] = "D1",[50] = "D2",[51] = "D3",[52] = "D4",[53] = "D5",[54] = "D6",[55] = "D7",[56] = "D8",[57] = "D9",[65] = "A",[66] = "B",[67] = "C",[68] = "D",[69] = "E",[70] = "F",[71] = "G",[72] = "H",[73] = "I",[74] = "J",[75] = "K",[76] = "L",[77] = "M",[78] = "N",[79] = "O",[80] = "P",[81] = "Q",[82] = "R",[83] = "S",[84] = "T",[85] = "U",[86] = "V",[87] = "W",[88] = "X",[89] = "Y",[90] = "Z",[91] = "LWin",[92] = "RWin",[93] = "Apps",[95] = "Sleep",[96] = "NumPad0",[97] = "NumPad1",[98] = "NumPad2",[99] = "NumPad3",[100] = "NumPad4",[101] = "NumPad5",[102] = "NumPad6",[103] = "NumPad7",[104] = "NumPad8",[105] = "NumPad9",[106] = "Multiply",[107] = "Add",[108] = "Separator",[109] = "Subtract",[110] = "Decimal",[111] = "Divide",[112] = "F1",[113] = "F2",[114] = "F3",[115] = "F4",[116] = "F5",[117] = "F6",[118] = "F7",[119] = "F8",[120] = "F9",[121] = "F10",[122] = "F11",[123] = "F12",[124] = "F13",[125] = "F14",[126] = "F15",[127] = "F16",[128] = "F17",[129] = "F18",[130] = "F19",[131] = "F20",[132] = "F21",[133] = "F22",[134] = "F23",[135] = "F24",[144] = "NumLock",[145] = "Scroll",[160] = "LShiftKey",[161] = "RShiftKey",[162] = "LControlKey",[163] = "RControlKey",[164] = "LMenu",[165] = "RMenu",[166] = "BrowserBack",[167] = "BrowserForward",[168] = "BrowserRefresh",[169] = "BrowserStop",[170] = "BrowserSearch",[171] = "BrowserFavorites",[172] = "BrowserHome",[173] = "VolumeMute",[174] = "VolumeDown",[175] = "VolumeUp",[176] = "MediaNextTrack",[177] = "MediaPreviousTrack",[178] = "MediaStop",[179] = "MediaPlayPause",[180] = "LaunchMail",[181] = "SelectMedia",[182] = "LaunchApplication1",[183] = "LaunchApplication2",[186] = "Ü",[187] = "Plus",[188] = "Comma",[189] = "Minus",[190] = "Dot",[191] = "Number",[192] = "Ö",[220] = "^",[222] = "Ä",[226] = "<>",[233833342] = "RButton"}

local SlotToString = {
    [-1] = "Passive",
    [SpellSlots.Q] = "Q",
    [SpellSlots.W] = "W",
    [SpellSlots.E] = "E",
    [SpellSlots.R] = "R",
}

local AddWhiteListMenu = function(id, name)
    local name = name or "White List"
    Menu.NewTree(id, name, function()
        for k, hero in pairs(ObjectManager.Get("enemy", "heroes")) do
            local heroAI = hero.AsAI
            Menu.Checkbox(id .. heroAI.CharName, heroAI.CharName, true)
        end
    end)
end

local CursorIsUnder = function(x, y, sizeX, sizeY)
    local mousePos = Renderer.GetCursorPos()
    if not mousePos then
        return false
    end
    local posX, posY = mousePos.x, mousePos.y
    if sizeY == nil then
        sizeY = sizeX
    end
    if sizeX < 0 then
        x = x + sizeX
        sizeX = -sizeX
    end
    if sizeY < 0 then
        y = y + sizeY
        sizeY = -sizeY
    end
    return posX >= x and posX <= x + sizeX and posY >= y and posY <= y + sizeY
end

--[[
    ██████   █████  ███    ██ ███████ ██      
    ██   ██ ██   ██ ████   ██ ██      ██      
    ██████  ███████ ██ ██  ██ █████   ██      
    ██      ██   ██ ██  ██ ██ ██      ██      
    ██      ██   ██ ██   ████ ███████ ███████ 
]]

local InfoPanel = {
    X = 100,
    Y = 100,
    Size = Vector(200, 22),
    Color = 0x000000AA,
    Font = Renderer.CreateFont("Bahnschrift.ttf", 20),
    Options = {
        [1] = {
            Text = "Spell Farm",
            Type = 0,
        }
    },
    LastOptionT = 0,
    SpellFarmStatus = Menu.Get("ShulepinScript.InfoPanel.SpellFarmStatus", true),
    SpellFarmStatusT = 0,
    MoveOffset = {},
    MenuCreated = false,
}

function InfoPanel.CreateMenu()
    Menu.NewTree("ShulepinScript.InfoPanel", "Information Panel", function()
        Menu.Checkbox("ShulepinScript.InfoPanel.SpellFarmStatus", "Spell Farm Status", true)
        Menu.Text("X - "); Menu.SameLine(); Menu.Slider("ShulepinScript.InfoPanel.X", "", 100, 0, Resolution.x, 1)
        Menu.Text("Y - "); Menu.SameLine(); Menu.Slider("ShulepinScript.InfoPanel.Y", "", 100, 0, Resolution.y, 1)
    end)
    InfoPanel.MenuCreated = true
end

function InfoPanel.AddOption(option)
    InfoPanel.Options[#InfoPanel.Options + 1] = option
end

EventManager.RegisterCallback(Events.OnDraw, function()
    if not InfoPanel.MenuCreated then return end

    InfoPanel.X = Menu.Get("ShulepinScript.InfoPanel.X")
    InfoPanel.Y = Menu.Get("ShulepinScript.InfoPanel.Y")
    local font = InfoPanel.Font

    InfoPanel.Size.y = 22 + (#InfoPanel.Options * 20)

    Renderer.DrawFilledRect(Vector(InfoPanel.X, InfoPanel.Y), InfoPanel.Size, 0, InfoPanel.Color)

    local text = "Shulepin Zeri"
    local textExtent = font:CalcTextSize(tostring(text))
    local textPosition = Vector(InfoPanel.X + ((InfoPanel.Size.x / 2) - (textExtent.x / 2)), InfoPanel.Y)
    font:DrawText(textPosition, text, 0xFFFFFFFF)

    for k, v in ipairs(InfoPanel.Options) do
        local text = v.Text
        local textPosition = Vector(InfoPanel.X + 5, InfoPanel.Y + (k * 20))
        
        if v.Type == 0 then
            local menuValue = Menu.Get("ShulepinScript.InfoPanel.SpellFarmStatus", true)
            local status = menuValue and "Enabled" or "Disabled"
            local color = menuValue and 0x28cf4cFF or 0xdf2626FF
            local textExtent = font:CalcTextSize(tostring(text))
            font:DrawText(textPosition, text, color)
            font:DrawText(Vector(textPosition.x + textExtent.x , textPosition.y), " [Scroll Down]", 0xa9a7a7FF  )
        elseif v.Type == 1 then
            local menuValue = Menu.Get(v.Value)
            if v.Key == 0 then
                if MMBPressed and InfoPanel.LastOptionT + 0.25 < Game.GetTime() then
                    Menu.Set(v.Value, not menuValue)
                    InfoPanel.LastOptionT = Game.GetTime()
                end
            end
            local color = menuValue and 0x28cf4cFF or 0xdf2626FF
            local textExtent = font:CalcTextSize(tostring(text))
            font:DrawText(textPosition, text, color)
            if v.Key == 0 then
                font:DrawText(Vector(textPosition.x + textExtent.x , textPosition.y), " [MMB]", 0xa9a7a7FF  )
            end
        elseif v.Type == 2 then
            local menuValue = Menu.Get(v.Value)
            local menuKey = Menu.GetKey(v.Value)
            local keyString = KeyCodes[menuKey] or "Unknown"
            local color = menuValue and 0x28cf4cFF or 0xdf2626FF
            local textExtent = font:CalcTextSize(tostring(text))
            font:DrawText(textPosition, text, color)
            font:DrawText(Vector(textPosition.x + textExtent.x , textPosition.y), " [" .. keyString .. "]", 0xa9a7a7FF  )
        end
    end

    do
        local cursorPos = Renderer.GetCursorPos()
        local rect = {x = InfoPanel.X - 5, y = InfoPanel.Y - 5, z = InfoPanel.Size.x, w = InfoPanel.Size.y}
        if not InfoPanel.MoveOffset and rect and CursorIsUnder(rect.x, rect.y, rect.z, rect.w) and LMBPressed then
            InfoPanel.MoveOffset = {
                x = rect.x - cursorPos.x + 5,
                y = rect.y - cursorPos.y + 5
            }
        elseif InfoPanel.MoveOffset and not LMBPressed then
            InfoPanel.MoveOffset = nil
        end

        if InfoPanel.MoveOffset and rect and rect.x and rect.y then
            rect.x = InfoPanel.MoveOffset.x + cursorPos.x
            rect.x = rect.x > 0 and rect.x or 0
            rect.x = rect.x < Resolution.x - rect.z and rect.x or Resolution.x - rect.z
    
            rect.y = InfoPanel.MoveOffset.y + cursorPos.y
            rect.y = rect.y > 0 and rect.y or 0
            rect.y = rect.y < (Resolution.y - rect.w + 6) and rect.y or (Resolution.y - rect.w + 6)
    
            if LMBPressed then
                InfoPanel.X = rect.x
                InfoPanel.Y = rect.y
                Menu.Set("ShulepinScript.InfoPanel.X", rect.x)
                Menu.Set("ShulepinScript.InfoPanel.Y", rect.y)
            end
        end
    end
end)

EventManager.RegisterCallback(Events.OnMouseEvent, function(e, message, wparam, lparam)
    LMBPressed = e == 513
    MMBPressed = e == 519
    if e == 522 and InfoPanel.SpellFarmStatusT + 0.25 < Game.GetTime() then
        InfoPanel.SpellFarmStatus = not InfoPanel.SpellFarmStatus
        Menu.Set("ShulepinScript.InfoPanel.SpellFarmStatus", InfoPanel.SpellFarmStatus)
        InfoPanel.SpellFarmStatusT = Game.GetTime()
    end
end)

--[[
     ██████ ██   ██  █████  ███    ███ ██████  ██  ██████  ███    ██ 
    ██      ██   ██ ██   ██ ████  ████ ██   ██ ██ ██    ██ ████   ██ 
    ██      ███████ ███████ ██ ████ ██ ██████  ██ ██    ██ ██ ██  ██ 
    ██      ██   ██ ██   ██ ██  ██  ██ ██      ██ ██    ██ ██  ██ ██ 
     ██████ ██   ██ ██   ██ ██      ██ ██      ██  ██████  ██   ████ 
]]

function Zeri.Initialize()
    Zeri.CreateMenu()
    Zeri.CreateSpells()
    Zeri.CreateEvents()

    InfoPanel.AddOption({
        Text = "Use E After Q",
        Type = 2,
        Value = "SZeri.E.Combo.Use"
    })
end

function Zeri.CreateSpells()
    Zeri.Spells = {}

    Zeri.Spells["Q"] = Spell.Skillshot({
        Slot            = SpellSlots.Q,
        Range           = 825,
        Delay           = 0.21,
        Width           = 80,
        Speed           = 2600,
        Type            = "Linear",
        Collisions      = { WindWall = true, Minions = true },
    })

    Zeri.Spells["W"] = Spell.Skillshot({
        Slot            = SpellSlots.W,
        Range           = 1200,
        Delay           = 0.5,
        Width           = 80,
        Speed           = 2200,
        Type            = "Linear",
        Collisions      = { WindWall = true, Minions = true },
    })

    Zeri.Spells["E"] = Spell.Skillshot({
        Slot            = SpellSlots.E,
        Range           = 300
    })

    Zeri.Spells["R"] = Spell.Active({
        Slot            = SpellSlots.R,
        Range           = 825,
    })
end

function Zeri.CreateEvents()
    for name, id in pairs(Events) do
        if Zeri[name] then
            EventManager.RegisterCallback(id, Zeri[name])
        end
    end
end

function Zeri.CreateMenu()
    Menu.RegisterMenu("SZeri", "Shulepin | Zeri", function()
        Menu.Text("Spell Settings", true)
        Menu.Separator()

        Menu.NewTree("SZeri.Q", "[Q] Burst Fire", function()
            Menu.NewTree("SZeri.Q.Combo", "Combo Settings", function()
                Menu.Checkbox("SZeri.Q.Combo.Use", "Use [Q] Burst Fire", true)
                Menu.Text("Min. HitChance - "); Menu.SameLine(); Menu.Dropdown("SZeri.Q.Combo.HitChance", "", 3, HitChanceList)
            end)
            Menu.NewTree("SZeri.Q.Harass", "Harass Settings", function()
                Menu.Checkbox("SZeri.Q.Harass.Use", "Use [Q] Burst Fire", true)
                Menu.Text("Min. HitChance - "); Menu.SameLine(); Menu.Dropdown("SZeri.Q.Harass.HitChance", "", 3, HitChanceList)
            end)
            Menu.NewTree("SZeri.Q.Lasthit", "Last Hit Settings", function()
                Menu.Checkbox("SZeri.Q.Lasthit.Use", "Use [Q] Burst Fire", true)
            end)
            Menu.NewTree("SZeri.Q.Waveclear", "Wave Clear Settings", function()
                Menu.Checkbox("SZeri.Q.Waveclear.Use", "Use [Q] Burst Fire", true)
            end)
            Menu.NewTree("SZeri.Q.Killsteal", "Kill Steal Settings", function()
                Menu.Checkbox("SZeri.Q.Killsteal.Use", "Use [Q] Burst Fire", true)
                AddWhiteListMenu("SZeri.Q.Killsteal.WhiteList.")
            end)
            Menu.NewTree("SZeri.Q.Draw", "Draw Settings", function()
                Menu.Checkbox("SZeri.Q.Draw.Use", "Draw [Q] Burst Fire", true)
                Menu.Text("Color - "); Menu.SameLine(); Menu.ColorPicker("SZeri.Q.Draw.Color", "", 0xFFFFFFFF)
            end)
        end)

        Menu.NewTree("SZeri.W", "[W] Ultrashock Laser", function()
            Menu.NewTree("SZeri.W.Combo", "Combo Settings", function()
                Menu.Checkbox("SZeri.W.Combo.Use", "Use [W] Ultrashock Laser", true)
                Menu.Text("Min. HitChance - "); Menu.SameLine(); Menu.Dropdown("SZeri.W.Combo.HitChance", "", 4, HitChanceList)
            end)
            Menu.NewTree("SZeri.W.Harass", "Harass Settings", function()
                Menu.Checkbox("SZeri.W.Harass.Use", "Use [Q] Ultrashock Laser", true)
                Menu.Text("Min. HitChance - "); Menu.SameLine(); Menu.Dropdown("SZeri.W.Harass.HitChance", "", 3, HitChanceList)
            end)
            Menu.NewTree("SZeri.W.Killsteal", "Kill Steal Settings", function()
                Menu.Checkbox("SZeri.W.Killsteal.Use", "Use [W] Ultrashock Laser", true)
                AddWhiteListMenu("SZeri.W.Killsteal.WhiteList.")
            end)
            Menu.NewTree("SZeri.W.Draw", "Draw Settings", function()
                Menu.Checkbox("SZeri.W.Draw.Use", "Draw [W] Ultrashock Laser", true)
                Menu.Text("Color - "); Menu.SameLine(); Menu.ColorPicker("SZeri.W.Draw.Color", "", 0xFFFFFFFF)
            end)
        end)

        Menu.NewTree("SZeri.E", "[E] Spark Surge", function()
            Menu.NewTree("SZeri.E.Combo", "Combo Settings", function()
                Menu.Keybind("SZeri.E.Combo.Use", "Use [R] On CC", 6, true, false)
            end)
            Menu.NewTree("SZeri.E.Draw", "Draw Settings", function()
                Menu.Checkbox("SZeri.E.Draw.Use", "Draw [E] Spark Surge", true)
                Menu.Text("Color - "); Menu.SameLine(); Menu.ColorPicker("SZeri.E.Draw.Color", "", 0xFFFFFFFF)
            end)
        end)

        Menu.NewTree("SZeri.R", "[R] Lightning Crash", function()
            Menu.NewTree("SZeri.R.Combo", "Combo Settings", function()
                Menu.Checkbox("SZeri.R.Combo.Use", "Use [R] Lightning Crash", true)
                Menu.Text("Min. Heroes - "); Menu.SameLine(); Menu.Slider("SZeri.R.Combo.Heroes", "", 2, 0, 5, 1)
            end)
            Menu.NewTree("SZeri.R.Draw", "Draw Settings", function()
                Menu.Checkbox("SZeri.R.Draw.Use", "Draw [R] Lightning Crash", true)
                Menu.Text("Color - "); Menu.SameLine(); Menu.ColorPicker("SZeri.R.Draw.Color", "", 0xFFFFFFFF)
            end)
        end)

        Menu.Separator()
        Menu.Text("Other Settings", true)
        Menu.Separator()

        InfoPanel.CreateMenu()

        Menu.Separator()
        Menu.Text("Script Changelog", true)
        Menu.Separator()

        for k, v in ipairs(Script.Changelog) do
            Menu.ColoredText(v, 0x919191FF)
        end

        Menu.Separator()
        Menu.Text("Script Information", true)
        Menu.Separator()
        Menu.Text("Version:") Menu.SameLine()
        Menu.ColoredText(Script.Version, 0x919191FF, false)
        Menu.Text("Last Updated:") Menu.SameLine()
        Menu.ColoredText(Script.LastUpdated, 0x919191FF, false)
        Menu.Text("Author:") Menu.SameLine()
        Menu.ColoredText("Shulepin", 0x9400d3FF, false)
        Menu.Separator()
    end)
end

function Zeri.IsReady(spell, mode, checkMana)
    local fastClear = Orbwalker.IsFastClearEnabled()
    local id = "SZeri." .. spell .. "." .. mode
    return 
        Menu.Get(id .. ".Use") and 
        Zeri.Spells[spell]:IsReady() and
        (checkMana ~= nil and (Menu.Get(id .. ".Mana") / 100) < Player.ManaPercent or fastClear or checkMana == nil)
end

function Zeri.Combo(n)
    if n == 1 and Zeri.IsReady("R", "Combo") then
        local heroCount = 0
        local minCount = Menu.Get("SZeri.R.Combo.Heroes")
        for k, v in pairs(ObjectManager.Get("enemy", "heroes")) do
            if TargetSelector:IsValidTarget(v, Zeri.Spells.R.Range) then
                heroCount = heroCount + 1
            end
        end

        if heroCount >= minCount then
            return Zeri.Spells.R:Cast()
        end
    end
    if n == 2 and Zeri.IsReady("Q", "Combo") then
        local hitChance = Menu.Get("SZeri.Q.Combo.HitChance")
        for k, target in ipairs(Zeri.Spells.Q:GetTargets()) do
            return Zeri.Spells.Q:CastOnHitChance(target, hitChance)
        end
    end
    if n == 3 and Zeri.IsReady("W", "Combo") then
        local hitChance = Menu.Get("SZeri.W.Combo.HitChance")
        for k, target in ipairs(Zeri.Spells.W:GetTargets()) do
            return Zeri.Spells.W:CastOnHitChance(target, hitChance)
        end
    end
end

function Zeri.Harass(n)
    if n == 2 and Zeri.IsReady("Q", "Harass") then
        local hitChance = Menu.Get("SZeri.W.Harass.HitChance")
        for k, target in ipairs(Zeri.Spells.Q:GetTargets()) do
            return Zeri.Spells.Q:CastOnHitChance(target, hitChance)
        end
    end
    if n == 3 and Zeri.IsReady("W", "Harass") then
        local hitChance = Menu.Get("SZeri.W.Harass.HitChance")
        for k, target in ipairs(Zeri.Spells.W:GetTargets()) do
            return Zeri.Spells.W:CastOnHitChance(target, hitChance)
        end
    end
end

function Zeri.Lasthit(n)
    if not Menu.Get("ShulepinScript.InfoPanel.SpellFarmStatus") then return end

    if n == 1 and Zeri.IsReady("Q", "Lasthit") then
        local targs = Zeri.Spells.Q:GetFarmTargets()
        if targs[1] then
            return Zeri.Spells.Q:Cast(targs[1])
        end
    end
end

function Zeri.Waveclear(n)
    if not Menu.Get("ShulepinScript.InfoPanel.SpellFarmStatus") then return end

    local lastTarget = Orbwalker.GetLastTarget()

    if n == 1 and Zeri.IsReady("Q", "Waveclear") then
        if lastTarget and lastTarget.IsMonster and TargetSelector:IsValidTarget(lastTarget, Zeri.Spells.Q.Range) then
            return Zeri.Spells.Q:CastOnHitChance(lastTarget, HitChance.Low)
        else
            return Zeri.Spells.Q:CastIfWillHit(1, "minions")
        end
    end
end

function Zeri.KillSteal(n)
    if n == 1 and Zeri.IsReady("Q", "Killsteal") then
        for k, target in ipairs(Zeri.Spells.Q:GetTargets()) do
            local whiteListValue = Menu.Get("SZeri.Q.Killsteal.WhiteList." .. target.CharName, true)
            if whiteListValue and Zeri.Spells.Q:CanKillTarget(target) then
                return Zeri.Spells.Q:CastOnHitChance(target, HitChance.VeryLow)
            end
        end
    end
    if n == 2 and Zeri.IsReady("Q", "Killsteal") then
        for k, target in ipairs(Zeri.Spells.W:GetTargets()) do
            local whiteListValue = Menu.Get("SZeri.W.Killsteal.WhiteList." .. target.CharName, true)
            if whiteListValue and Zeri.Spells.W:CanKillTarget(target) then
                return Zeri.Spells.W:CastOnHitChance(target, HitChance.Medium)
            end
        end
    end
end

function Zeri.OnTick()
    local eBuff = Player:GetBuff("zeriespecialrounds")
    local rBuff = Player:GetBuff("ZeriR")
    Zeri.Spells.Q.Speed = rBuff and 3400 or 2600
    Zeri.Spells.Q.Collisions = (eBuff or rBuff) and {} or { WindWall = true, Minions = true }
end

function Zeri.OnNormalPriority(n)
    if not Game.CanSendInput() then return end 

    local orbMode = Zeri[Orbwalker.GetMode()]
    if orbMode then
        orbMode(n)
    end
end

function Zeri.OnExtremePriority(n)
    if not Game.CanSendInput() then return end

    Zeri.KillSteal(n)
end

function Zeri.OnPreAttack(args)
    local chargeValue = Player.SecondResource
    if chargeValue < 100 then
        if args.Target.HealthPercent < 0.35 then
            args.Process = true
        else
            args.Process = false
        end
    end

    if args.Target.IsTurret then
        if Zeri.IsReady("Q", "Waveclear") then
            return Zeri.Spells.Q:Cast(args.Target.Position)
        end
    end
end

function Zeri.OnDraw()
    for k, spell in pairs({ "Q", "W", "E", "R" }) do
        if Menu.Get("SZeri." .. spell .. ".Draw.Use") and Zeri.Spells[spell]:IsReady() then
            local color = Menu.Get("SZeri." .. spell .. ".Draw.Color")
            Renderer.DrawCircle3D(Player.Position, Zeri.Spells[spell].Range, 10, 3, color)
        end
    end
end

function Zeri.OnSpellCast(unit, spell)
    if unit.IsMe then
        if Orbwalker.GetMode() == "Combo" then
            if spell.SpellData.Name == "ZeriQ" then
                if Zeri.IsReady("E", "Combo") then
                    return Zeri.Spells.E:Cast(Renderer.GetMousePos())
                end
            end
        end
    end
end

--[[
    ██       ██████   █████  ██████  
    ██      ██    ██ ██   ██ ██   ██ 
    ██      ██    ██ ███████ ██   ██ 
    ██      ██    ██ ██   ██ ██   ██ 
    ███████  ██████  ██   ██ ██████  
]]

function OnLoad()
    Zeri.Initialize()
    return true
end
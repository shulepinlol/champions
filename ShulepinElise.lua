--[[
    ███████ ██      ██ ███████ ███████ 
    ██      ██      ██ ██      ██      
    █████   ██      ██ ███████ █████   
    ██      ██      ██      ██ ██      
    ███████ ███████ ██ ███████ ███████                                                               
]]

if Player.CharName ~= "Elise" then return end

local Elise = {}
local Script = {
    Name = "Shulepin" .. Player.CharName,
    Version = "1.0.6",
    LastUpdated = "08/08/2022",
    Changelog = {
        [1] = "[24/12/2021 - Version 1.0.0]: Initial release",
        [2] = "[03/01/2022 - Version 1.0.1]: Improved JungleClear",
    }
}

module(Script.Name, package.seeall, log.setup)
clean.module(Script.Name, clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/shulepinlol/champions/main/" .. Script.Name .. ".lua", Script.Version)

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

local GetCooldownReduction = function()
    local haste = Player.AbilityHasteMod
    return ((haste / (haste + 100)) * 100) * 0.01
end

local CalculateCD = function(value)
    local cdrValue = GetCooldownReduction()
    return value - value * cdrValue
end

local CalculateRemainingCD = function(value)
    return (value - Game.GetTime()) > 0 and value - Game.GetTime() or 0
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
        Menu.Slider("ShulepinScript.InfoPanel.X", "X -", 100, 0, Resolution.x, 1)
        Menu.Slider("ShulepinScript.InfoPanel.Y", "Y -", 100, 0, Resolution.y, 1)
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

    local text = "Shulepin Elise"
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

function Elise.Initialize()
    Elise.CreateMenu()
    Elise.CreateSpells()
    Elise.CreateEvents()

    Elise.CurrentForm = "Human"

    Elise.CD = {
        ["Human"] = { [SpellSlots.Q] = 0, [SpellSlots.W] = 0, [SpellSlots.E] = 0 },
        ["Spider"] = { [SpellSlots.Q] = 0, [SpellSlots.W] = 0, [SpellSlots.E] = 0 }
    }
    Elise.BaseCD = {
        ["Human"] = {
            [SpellSlots.Q] = { 6, 6, 6, 6, 6 },
            [SpellSlots.W] = { 12, 12, 12, 12, 12 },
            [SpellSlots.E] = { 12, 11.5, 11, 10.5, 10 },
        },
        ["Spider"] = {
            [SpellSlots.Q] = { 6, 6, 6, 6, 6 },
            [SpellSlots.W] = { 10, 10, 10, 10, 10 },
            [SpellSlots.E] = { 22, 21, 20, 19, 18 },
        }
    }

    Elise.Offsets = {
        [SpellSlots.Q] = 7,
        [SpellSlots.W] = 76,
        [SpellSlots.E] = 142,
        [SpellSlots.R] = 206,
    }
end

function Elise.CreateSpells()
    Elise.Spells = {}

    Elise.Spells["QH"] = Spell.Targeted({
        Slot            = SpellSlots.Q,
        Range           = 625,
        CD              = 0
    })

    Elise.Spells["WH"] = Spell.Skillshot({
        Slot            = SpellSlots.W,
        Range           = 950,
        Delay           = 0.1,
        Speed           = huge,
        Width           = 100,
        Type            = "Linear",
        Collisions      = { Wall = true, Minions = true },
        CD              = 0
    })

    Elise.Spells["EH"] = Spell.Skillshot({
        Slot            = SpellSlots.E,
        Range           = 1075,
        Delay           = 0.25,
        Speed           = 1600,
        Width           = 100,
        Type            = "Linear",
        Collisions      = { Wall = true, Heroes = true, Minions = true },
        CD              = 0
    })

    Elise.Spells["QS"] = Spell.Targeted({
        Slot            = SpellSlots.Q,
        Range           = 475,
        CD              = 0
    })

    Elise.Spells["WS"] = Spell.Active({
        Slot            = SpellSlots.W,
        Range           = 475,
        CD              = 0,
        LastCastT       = 0,
    })

    Elise.Spells["ES"] = Spell.Targeted({
        Slot            = SpellSlots.E,
        Range           = 700,
        CD              = 0
    })

    Elise.Spells["R"] = Spell.Active({
        Slot            = SpellSlots.R,
        Range           = 700,
        CD              = 0
    })
end

function Elise.CreateEvents()
    for name, id in pairs(Events) do
        if Elise[name] then
            EventManager.RegisterCallback(id, Elise[name])
        end
    end
end

function Elise.CreateMenu()
    Menu.RegisterMenu("SElise", "Shulepin | Elise", function()
        Menu.Separator("Spell Settings")

        Menu.NewTree("SElise.QH", "[Human] [Q] Neurotoxin", function()
            Menu.NewTree("SElise.QH.Combo", "Combo Settings", function()
                Menu.Checkbox("SElise.QH.Combo.Use", "Use [Human] [Q] Neurotoxin", true)
            end)
            Menu.NewTree("SElise.QH.Harass", "Harass Settings", function()
                Menu.Checkbox("SElise.QH.Harass.Use", "Use [Human] [Q] Neurotoxin", true)
                Menu.Slider("SElise.QH.Harass.Mana", "Min. Mana [%]", 35, 0, 100, 1)
                AddWhiteListMenu("SElise.QH.Harass.WhiteList.")
            end)
            Menu.NewTree("SElise.QH.Waveclear", "Wave Clear Settings", function()
                Menu.Checkbox("SElise.QH.Waveclear.Use", "Use [Human] [Q] Neurotoxin", true)
                Menu.Slider("SElise.QH.Waveclear.Mana", "Min. Mana [%]", 35, 0, 100, 1)
            end)
            Menu.NewTree("SElise.QH.Killsteal", "Kill Steal Settings", function()
                Menu.Checkbox("SElise.QH.Killsteal.Use", "Use [Human] [Q] Neurotoxin", true)
                AddWhiteListMenu("SElise.QH.Killsteal.WhiteList.")
            end)
            Menu.NewTree("SElise.QH.Draw", "Draw Settings", function()
                Menu.Checkbox("SElise.QH.Draw.Damage", "Draw [Human] [Q] Neurotoxin Damage", true)
                Menu.Checkbox("SElise.QH.Draw.Use", "Draw [Human] [Q] Neurotoxin Range", true)
                Menu.ColorPicker("SElise.QH.Draw.Color", "Color", 0x9400D3)
            end)
        end)

        Menu.NewTree("SElise.WH", "[Human] [W] Volatile Spiderling", function()
            Menu.NewTree("SElise.WH.Combo", "Combo Settings", function()
                Menu.Checkbox("SElise.WH.Combo.Use", "Use [Human] [W] Volatile Spiderling", true)
            end)
            Menu.NewTree("SElise.WH.Harass", "Harass Settings", function()
                Menu.Checkbox("SElise.WH.Harass.Use", "Use [Human] [W] Volatile Spiderling", true)
                Menu.Slider("SElise.WH.Harass.Mana", "Min. Mana [%]", 35, 0, 100, 1)
                AddWhiteListMenu("SElise.WH.Harass.WhiteList.")
            end)
            Menu.NewTree("SElise.WH.Waveclear", "Wave Clear Settings", function()
                Menu.Checkbox("SElise.WH.Waveclear.Use", "Use [Human] [W] Volatile Spiderling", true)
                Menu.Slider("SElise.WH.Waveclear.Mana", "Min. Mana [%]", 35, 0, 100, 1)
            end)
            Menu.NewTree("SElise.WH.Killsteal", "Kill Steal Settings", function()
                Menu.Checkbox("SElise.WH.Killsteal.Use", "Use [Human] [W] Volatile Spiderling", true)
                AddWhiteListMenu("SElise.WH.Killsteal.WhiteList.")
            end)
            Menu.NewTree("SElise.WH.Draw", "Draw Settings", function()
                Menu.Checkbox("SElise.WH.Draw.Damage", "Draw [Human] [W] Volatile Spiderling Damage", true)
                Menu.Checkbox("SElise.WH.Draw.Use", "Draw [Human] [W] Volatile Spiderling Range", true)
                Menu.ColorPicker("SElise.WH.Draw.Color", "Color", 0x9370DB)
            end)
        end)

        Menu.NewTree("SElise.EH", "[Human] [E] Cocoon", function()
            Menu.NewTree("SElise.EH.Combo", "Combo Settings", function()
                Menu.Checkbox("SElise.EH.Combo.Use", "Use [Human] [E] Cocoon", true)
                Menu.Dropdown("SElise.EH.Combo.HitChance", "Min. HitChance", 2, HitChanceList)
            end)
            Menu.NewTree("SElise.EH.Harass", "Harass Settings", function()
                Menu.Checkbox("SElise.EH.Harass.Use", "Use [Human] [E] Cocoon", true)
                Menu.Slider("SElise.EH.Harass.Mana", "Min. Mana [%]", 35, 0, 100, 1)
                Menu.Dropdown("SElise.EH.Harass.HitChance", "Min. HitChance", 2, HitChanceList)
                AddWhiteListMenu("SElise.EH.Harass.WhiteList.")
            end)
            Menu.NewTree("SElise.EH.Waveclear", "Wave Clear Settings", function()
                Menu.Checkbox("SElise.EH.Waveclear.Use", "Use [Human] [E] Cocoon", true)
                Menu.SameLine(); Menu.Slider("SElise.EH.Waveclear.Mana", "Min. Mana [%]", 35, 0, 100, 1)
            end)
            Menu.NewTree("SElise.EH.GapClose", "GapClose Settings", function()
                Menu.Checkbox("SElise.EH.GapClose.Use", "Use [Human] [E] Cocoon", true)
                AddWhiteListMenu("SElise.EH.GapClose.WhiteList.")
            end)
            Menu.NewTree("SElise.EH.Interrupt", "Interrupt Settings", function()
                Menu.Checkbox("SElise.EH.Interrupt.Use", "Use [Human] [E] Cocoon", true)
                AddWhiteListMenu("SElise.EH.Interrupt.WhiteList.")
            end)
            Menu.NewTree("SElise.EH.Draw", "Draw Settings", function()
                Menu.Checkbox("SElise.EH.Draw.Damage", "Draw [Human] [E] Cocoon Damage", true)
                Menu.Checkbox("SElise.EH.Draw.Use", "Draw [Human] [E] Cocoon Range", true)
                Menu.ColorPicker("SElise.EH.Draw.Color", "Color", 0x9370DB)
            end)
        end)

        Menu.NewTree("SElise.QS", "[Spider] [Q] Venomous Bite", function()
            Menu.NewTree("SElise.QS.Combo", "Combo Settings", function()
                Menu.Checkbox("SElise.QS.Combo.Use", "Use [Spider] [Q] Venomous Bite", true)
            end)
            Menu.NewTree("SElise.QS.Waveclear", "Wave Clear Settings", function()
                Menu.Checkbox("SElise.QS.Waveclear.Use", "Use [Spider] [Q] Venomous Bite", true)
            end)
            Menu.NewTree("SElise.QS.Killsteal", "Kill Steal Settings", function()
                Menu.Checkbox("SElise.QS.Killsteal.Use", "Use [Spider] [Q] Venomous Bite", true)
                AddWhiteListMenu("SElise.QS.Killsteal.WhiteList.")
            end)
            Menu.NewTree("SElise.QS.Draw", "Draw Settings", function()
                Menu.Checkbox("SElise.QS.Draw.Damage", "Draw [Spider] [Q] Venomous Bite Damage", true)
                Menu.Checkbox("SElise.QS.Draw.Use", "Draw [Spider] [Q] Venomous Bite Range", true)
                Menu.ColorPicker("SElise.QS.Draw.Color", "Color", 0x9370DB)
            end)
        end)

        Menu.NewTree("SElise.WS", "[Spider] [W] Skittering Frenzy", function()
            Menu.NewTree("SElise.WS.Combo", "Combo Settings", function()
                Menu.Checkbox("SElise.WS.Combo.Use", "Use [Spider] [W] Skittering Frenzy", true)
            end)
            Menu.NewTree("SElise.WS.Waveclear", "Wave Clear Settings", function()
                Menu.Checkbox("SElise.WS.Waveclear.Use", "Use [Spider] [W] Skittering Frenzy", true)
            end)
        end)

        Menu.NewTree("SElise.R", "[R] Spider Form / Human Form", function()
            Menu.NewTree("SElise.R.Combo", "Combo Settings", function()
                Menu.Checkbox("SElise.R.Combo.Use", "[R] Spider Form / Human Form", true)
            end)
            Menu.NewTree("SElise.R.Waveclear", "Wave Clear Settings", function()
                Menu.Checkbox("SElise.R.Waveclear.Use", "[R] Spider Form / Human Form", true)
            end)
        end)

        Menu.Separator("Other Settings")
        InfoPanel.CreateMenu()
        Menu.Separator("Author: Shulepin")
    end)
end

function Elise.IsReady(spell, mode, checkMana)
    local fastClear = Orbwalker.IsFastClearEnabled()
    local id = "SElise." .. spell .. "." .. mode
    return 
        Menu.Get(id .. ".Use") and 
        Elise.Spells[spell]:IsReady() and
        (checkMana ~= nil and (Menu.Get(id .. ".Mana") / 100) < Player.ManaPercent or fastClear or checkMana == nil)
end

function Elise.HumanSwitchConditions(target, mode)
    if mode ~= nil and mode == "Waveclear" then
        return (not Elise.Spells.QH:IsReady() and not Elise.Spells.WH:IsReady() and not Elise.Spells.EH:IsReady())
    else
        return 
        (Elise.Spells.QH.CD > 0 and Elise.Spells.WH.CD > 0 and Elise.Spells.EH.CD > 1) and Player:Distance(target) < Elise.Spells.ES.Range
    end
end

function Elise.SpiderSwitchConditions(target, mode)
    if mode ~= nil and mode == "Waveclear" then
        return 
        Elise.Spells.WS.LastCastT + 1 < Game.GetTime() and
        Player:GetBuff("EliseSpiderW") == nil and
        Elise.Spells.WS.CD > 2 and 
        Elise.Spells.QS.CD > 1
    else
        return 
        Elise.Spells.QH.CD <= 0.1 and Elise.Spells.QH:CanKillTarget(target, "Default", DamageLib.GetAutoAttackDamage(Player, target, true)) or
        Elise.Spells.EH.CD <= 0.5
    end
end

function Elise.Combo(n)
    if Elise.CurrentForm == "Human" then
        if n == 1 and Elise.IsReady("EH", "Combo") then
            local hitChance = Menu.Get("SElise.EH.Combo.HitChance")
            for k, target in ipairs(Elise.Spells.EH:GetTargets()) do
                return Elise.Spells.EH:CastOnHitChance(target, hitChance)
            end
        end
        if n == 2 and Elise.IsReady("WH", "Combo") then
            for k, target in ipairs(Elise.Spells.WH:GetTargets()) do
                return Elise.Spells.WH:CastOnHitChance(target, HitChance.Low)
            end
        end
        if n == 3 and Elise.IsReady("QH", "Combo") then
            for k, target in ipairs(Elise.Spells.QH:GetTargets()) do
                return Elise.Spells.QH:Cast(target)
            end
        end
        if n == 4 and Elise.IsReady("R", "Combo") then
            for k, target in ipairs(Elise.Spells.EH:GetTargets()) do
                if Elise.HumanSwitchConditions(target) then
                    return Elise.Spells.R:Cast()
                end
            end
        end
    else
        if n == 1 and Elise.IsReady("QS", "Combo") then
            for k, target in ipairs(Elise.Spells.QS:GetTargets()) do
                return Elise.Spells.QS:Cast(target)
            end
        end
        if n == 2 and Elise.IsReady("R", "Combo") then
            for k, target in ipairs(Elise.Spells.EH:GetTargets()) do
                if Elise.SpiderSwitchConditions(target) then
                    return Elise.Spells.R:Cast()
                end
            end
        end
    end
end

function Elise.Harass(n)
    if Elise.CurrentForm == "Human" then
        if n == 1 and Elise.IsReady("EH", "Harass", true) then
            local hitChance = Menu.Get("SElise.EH.Harass.HitChance")
            for k, target in ipairs(Elise.Spells.EH:GetTargets()) do
                return Elise.Spells.EH:CastOnHitChance(target, hitChance)
            end
        end
        if n == 2 and Elise.IsReady("WH", "Harass", true) then
            for k, target in ipairs(Elise.Spells.WH:GetTargets()) do
                return Elise.Spells.WH:CastOnHitChance(target, HitChance.Low)
            end
        end
        if n == 3 and Elise.IsReady("QH", "Harass", true) then
            for k, target in ipairs(Elise.Spells.QH:GetTargets()) do
                return Elise.Spells.QH:Cast(target)
            end
        end
    end
end

function Elise.Waveclear(n)
    if not Menu.Get("ShulepinScript.InfoPanel.SpellFarmStatus") then return end

    local lastTarget = Orbwalker.GetLastTarget()

    if lastTarget and lastTarget.IsMonster and TargetSelector:IsValidTarget(lastTarget, Elise.Spells.QH.Range) then
        if Elise.CurrentForm == "Human" then
            if n == 1 and Elise.IsReady("QH", "Waveclear", true) then
                return Elise.Spells.QH:Cast(lastTarget)
            end
            if n == 2 and Elise.IsReady("EH", "Waveclear", true) then
                return Elise.Spells.EH:CastOnHitChance(lastTarget, HitChance.Low)
            end
            if n == 3 and Elise.IsReady("WH", "Waveclear", true) then
                return Elise.Spells.WH:CastOnHitChance(lastTarget, HitChance.Low)
            end
            if n == 4 and Elise.IsReady("R", "Waveclear") then
                if Elise.HumanSwitchConditions(lastTarget, "Waveclear") then
                    return Elise.Spells.R:Cast()
                end
            end
        else
            if n == 1 and Elise.IsReady("QS", "Waveclear") then
                return Elise.Spells.QS:Cast(lastTarget)
            end
            if n == 2 and Elise.IsReady("R", "Waveclear") then
                if Elise.SpiderSwitchConditions(lastTarget, "Waveclear") then
                    return Elise.Spells.R:Cast()
                end
            end
        end
    else
        if Elise.CurrentForm == "Human" then
            if n == 1 and Elise.IsReady("QH", "Waveclear", true) then
                local minions = {}
                for k, v in pairs(ObjectManager.Get("enemy", "minions")) do
                    if TargetSelector:IsValidTarget(v, Elise.Spells.QH.Range) then
                        minions[#minions + 1] = v
                    end
                end
                table.sort(minions, function(a, b) return a.Health > b.Health end)
                if minions[1] then
                    return Elise.Spells.QH:Cast(minions[1])
                end
            end
            if n == 2 and Elise.IsReady("WH", "Waveclear", true) then
                return Elise.Spells.WH:CastIfWillHit(2, "minions")
            end
        else
            if n == 1 and Elise.IsReady("QS", "Waveclear") then
                local targs = Elise.Spells.QS:GetFarmTargets()
                if targs[1] then
                    return Elise.Spells.QS:Cast(targs[1])
                end
            end
        end
    end
end

function Elise.KillSteal(n)
    if Elise.CurrentForm == "Human" then
        if n == 1 and Elise.IsReady("QH", "Killsteal") then
            for k, target in ipairs(Elise.Spells.QH:GetTargets()) do
                local whiteListValue = Menu.Get("SElise.QH.Killsteal.WhiteList." .. target.CharName, true)
                if whiteListValue and Elise.Spells.QH:CanKillTarget(target) then
                    return Elise.Spells.QH:Cast(target)
                end
            end
        end
        if n == 2 and Elise.IsReady("WH", "Killsteal") then
            for k, target in ipairs(Elise.Spells.WH:GetTargets()) do
                local whiteListValue = Menu.Get("SElise.WH.Killsteal.WhiteList." .. target.CharName, true)
                if whiteListValue and Elise.Spells.WH:CanKillTarget(target) then
                    return Elise.Spells.WH:CastOnHitChance(target, HitChance.Low)
                end
            end
        end
    else
        if n == 1 and Elise.IsReady("QS", "Killsteal") then
            for k, target in ipairs(Elise.Spells.QS:GetTargets()) do
                local whiteListValue = Menu.Get("SElise.QS.Killsteal.WhiteList." .. target.CharName, true)
                if whiteListValue and Elise.Spells.QS:CanKillTarget(target) then
                    return Elise.Spells.QS:Cast(target)
                end
            end
        end
    end
end

function Elise.OnNormalPriority(n)
    if not Game.CanSendInput() then return end 
    if not Orbwalker.CanCast() then return end

    local orbMode = Elise[Orbwalker.GetMode()]
    if orbMode then
        orbMode(n)
    end

end

function Elise.OnExtremePriority(n)
    if not Game.CanSendInput() then return end

    Elise.KillSteal(n)
end

function Elise.OnTick()
    Elise.CurrentForm = Player:GetSpell(SpellSlots.Q).Name == "EliseHumanQ" and "Human" or "Spider"
    Elise.Spells.QH.CD = CalculateRemainingCD(Elise.CD["Human"][SpellSlots.Q])
    Elise.Spells.WH.CD = CalculateRemainingCD(Elise.CD["Human"][SpellSlots.W])
    Elise.Spells.EH.CD = CalculateRemainingCD(Elise.CD["Human"][SpellSlots.E])
    Elise.Spells.QS.CD = CalculateRemainingCD(Elise.CD["Spider"][SpellSlots.Q])
    Elise.Spells.WS.CD = CalculateRemainingCD(Elise.CD["Spider"][SpellSlots.W])
    Elise.Spells.ES.CD = CalculateRemainingCD(Elise.CD["Spider"][SpellSlots.E])
end

function Elise.OnDraw()
    for k, spell in pairs({ "QH", "WH", "EH", "QS" }) do
        if Menu.Get("SElise." .. spell .. ".Draw.Use") and Elise.Spells[spell]:IsReady() then
            local color = Menu.Get("SElise." .. spell .. ".Draw.Color")
            Renderer.DrawCircle3D(Player.Position, Elise.Spells[spell].Range, 10, 3, color)
        end
    end
end

function Elise.OnDrawDamage(target, dmgList)
    local totalDamage = 0

    if Elise.Spells.QH.CD == 0 and Menu.Get("SElise.QH.Draw.Damage") then
        totalDamage = totalDamage + Elise.Spells.QH:GetDamage(target)
    end

    if Elise.Spells.WH.CD == 0 and Menu.Get("SElise.WH.Draw.Damage") then
        totalDamage = totalDamage + Elise.Spells.WH:GetDamage(target)
    end

    if Elise.Spells.QS.CD == 0 and Menu.Get("SElise.QS.Draw.Damage") then
        totalDamage = totalDamage + Elise.Spells.QS:GetDamage(target, "SpiderForm")
    end

    table.insert(dmgList, totalDamage)
end

function Elise.OnProcessSpell(unit, spell)
    if unit.IsMe and spell and spell.SpellData then
        local level = spell.SpellData.Level
        local slot = spell.Slot
        local delay = spell.CastDelay
        if slot >= 0 and slot < 3 then
            Elise.CD[Elise.CurrentForm][slot] = Game.GetTime() + delay + CalculateCD(Elise.BaseCD[Elise.CurrentForm][slot][level])
        end
        if Elise.CurrentForm == "Spider" and slot == SpellSlots.W then
            Elise.Spells.WS.LastCastT = Game.GetTime()
        end
    end
end

function Elise.OnPostAttack(target)
    if target.IsHero then
        if Elise.IsReady("WS", "Combo") then
            return Elise.Spells.WS:Cast()
        end
    elseif target.IsMonster or target.IsLaneMinion then
        if not Menu.Get("ShulepinScript.InfoPanel.SpellFarmStatus") then return end
        if Elise.IsReady("WS", "Waveclear") then
            return Elise.Spells.WS:Cast()
        end
    end
end

function Elise.OnGapclose(unit, dashData)
    if unit.IsAlly then return end
    if unit.CharName == "MasterYi" then return end
    if dashData.Invulnerable then return end
    if Elise.IsReady("EH", "GapClose") and Elise.Spells.EH:IsInRange(unit) then
        local whiteListValue = Menu.Get("SElise.EH.GapClose.WhiteList." .. unit.CharName, true)
        if whiteListValue and dashData.Slot > -1 then
            return Elise.Spells.EH:CastOnHitChance(unit, HitChance.Low)
        end
    end
end

function Elise.OnInterruptibleSpell(unit, spellCast, danger, endTime, canMoveDuringChannel)
    if unit.IsAlly then return end
    if Elise.IsReady("EH", "Interrupt") and Elise.Spells.EH:IsInRange(unit) then
        local whiteListValue = Menu.Get("SElise.EH.Interrupt.WhiteList." .. unit.CharName, true)
        if whiteListValue and danger >= 3 then
            return Elise.Spells.EH:CastOnHitChance(unit, HitChance.Low)
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
    Elise.Initialize()
    return true
end

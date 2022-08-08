--[[
    ██████   ██████  ██████  ██████  ██    ██ 
    ██   ██ ██    ██ ██   ██ ██   ██  ██  ██  
    ██████  ██    ██ ██████  ██████    ████   
    ██      ██    ██ ██      ██         ██    
    ██       ██████  ██      ██         ██                                       
]]

if Player.CharName ~= "Poppy" then return end

local Poppy = {}
local Script = {
    Name = "Shulepin" .. Player.CharName,
    Version = "1.0.5",
    LastUpdated = "08/08/2022",
    Changelog = {
        [1] = "[21/12/2021 - Version 1.0.0]: Initial release",
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

local AbilityResourceTypes, BuffTypes, DamageTypes, Events, GameMaps, GameObjectOrders, HitChance, ItemSlots, 
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

    local text = "Shulepin Poppy"
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

function Poppy.Initialize()
    Poppy.CreateMenu()
    Poppy.CreateSpells()
    Poppy.CreateEvents()
end

function Poppy.CreateSpells()
    Poppy.Spells = {}

    Poppy.Spells["Q"] = Spell.Skillshot({
        Slot            = SpellSlots.Q,
        Range           = 400,
        Width           = 160,
        Delay           = 0.25,
        Speed           = huge,
        Type            = "Linear"
    })

    Poppy.Spells["W"] = Spell.Active({
        Slot            = SpellSlots.W,
        Range           = 400,
    })

    Poppy.Spells["E"] = Spell.Targeted({
        Slot            = SpellSlots.E,
        Range           = 475,
        Delay           = 0,
        Speed           = huge,
    })

    Poppy.Spells["E_Wall"] = Spell.Skillshot({
        Slot            = SpellSlots.E,
        Range           = 380,
        Delay           = 0,
        Speed           = 1800,
        Type            = "Linear",
    })
end

function Poppy.CreateEvents()
    for name, id in pairs(Events) do
        if Poppy[name] then
            EventManager.RegisterCallback(id, Poppy[name])
        end
    end
end

function Poppy.CreateMenu()
    Menu.RegisterMenu("SPoppy", "Shulepin | Poppy", function()
        Menu.Separator("Spell Settings")

        Menu.NewTree("SPoppy.Q", "[Q] Hammer Shock", function()
            Menu.NewTree("SPoppy.Q.Combo", "Combo Settings", function()
                Menu.Checkbox("SPoppy.Q.Combo.Use", "Use [Q] Hammer Shock", true)
                Menu.Dropdown("SPoppy.Q.Combo.HitChance", "Min. HitChance", 2, HitChanceList)
            end)
            Menu.NewTree("SPoppy.Q.Harass", "Harass Settings", function()
                Menu.Checkbox("SPoppy.Q.Harass.Use", "Use [Q] Hammer Shock", true)
                Menu.Slider("SPoppy.Q.Harass.Mana", "Min. Mana [%]", 35, 0, 100, 1)
                Menu.Dropdown("SPoppy.Q.Harass.HitChance", "Min. HitChance", 2, HitChanceList)
                AddWhiteListMenu("SPoppy.Q.Harass.WhiteList.")
            end)
            Menu.NewTree("SPoppy.Q.Lasthit", "Last Hit Settings", function()
                Menu.Checkbox("SPoppy.Q.Lasthit.Use", "Use [Q] Hammer Shock", true)
                Menu.Slider("SPoppy.Q.Lasthit.Mana", "Min. Mana [%]", 35, 0, 100, 1)
            end)
            Menu.NewTree("SPoppy.Q.Waveclear", "Wave Clear Settings", function()
                Menu.Checkbox("SPoppy.Q.Waveclear.Use", "Use [Q] Hammer Shock", true)
                Menu.Slider("SPoppy.Q.Waveclear.Mana", "Min. Mana [%]", 35, 0, 100, 1)
                Menu.Slider("SPoppy.Q.Waveclear.Minions", "Min. Minion Hits", 2, 0, 6, 1)
            end)
            Menu.NewTree("SPoppy.Q.Killsteal", "Kill Steal Settings", function()
                Menu.Checkbox("SPoppy.Q.Killsteal.Use", "Use [Q] Hammer Shock", true)
                AddWhiteListMenu("SPoppy.Q.Killsteal.WhiteList.")
            end)
            Menu.NewTree("SPoppy.Q.Draw", "Draw Settings", function()
                Menu.Checkbox("SPoppy.Q.Draw.Damage", "Draw [Q] Hammer Shock", true)
                Menu.Checkbox("SPoppy.Q.Draw.Use", "Draw [Q] Hammer Shock", true)
                Menu.ColorPicker("SPoppy.Q.Draw.Color", "Color", 0xf3e8f3)
            end)
        end)

        Menu.NewTree("SPoppy.W", "[W] Steadfast Presence", function()
            Menu.NewTree("SPoppy.W.Combo", "Anti Dash Settings", function()
                Menu.Checkbox("SPoppy.W.Combo.Use", "Use [W] Steadfast Presence", true)
                AddWhiteListMenu("SPoppy.W.Combo.WhiteList.")
            end)
        end)

        Menu.NewTree("SPoppy.E", "[E] Heroic Charge", function()
            Menu.NewTree("SPoppy.E.Combo", "Combo Settings", function()
                Menu.Checkbox("SPoppy.E.Combo.Use", "Use [E] Heroic Charge", true)
            end)
            Menu.NewTree("SPoppy.E.Waveclear", "Jungle Clear Settings", function()
                Menu.Checkbox("SPoppy.E.Waveclear.Use", "Use [E] Heroic Charge", true)
                Menu.Slider("SPoppy.Q.Waveclear.Mana", "Min. Mana [%]", 35, 0, 100, 1)
            end)
            Menu.NewTree("SPoppy.E.Killsteal", "Kill Steal Settings", function()
                Menu.Checkbox("SPoppy.E.Killsteal.Use", "Use [E] Heroic Charge", true)
                AddWhiteListMenu("SPoppy.E.Killsteal.WhiteList.")
            end)
            Menu.NewTree("SPoppy.E.Draw", "Draw Settings", function()
                Menu.Checkbox("SPoppy.E.Draw.Damage", "Draw [E] Heroic Charge", true)
                Menu.Checkbox("SPoppy.E.Draw.Use", "Draw [E] Heroic Charge", true)
                Menu.ColorPicker("SPoppy.E.Draw.Color", "Color", 0x918b91)
            end)
        end)

        Menu.Separator("Other Settings")
        InfoPanel.CreateMenu()
        Menu.Separator("Author: Shulepin")
    end)
end

function Poppy.IsReady(spell, mode, checkMana)
    local fastClear = Orbwalker.IsFastClearEnabled()
    local id = "SPoppy." .. spell .. "." .. mode
    return 
        Menu.Get(id .. ".Use") and 
        Poppy.Spells[spell]:IsReady() and
        (checkMana ~= nil and (Menu.Get(id .. ".Mana") / 100) < Player.ManaPercent or fastClear or checkMana == nil)
end

function Poppy.Combo(n)
    if n == 1 and Poppy.IsReady("E", "Combo") then
        for k, target in ipairs(Poppy.Spells.E:GetTargets()) do
            local shouldCast = false
            Poppy.Spells.E_Wall.Delay = Player:Distance(target) / Poppy.Spells.E_Wall.Speed
            local predPos = Poppy.Spells.E_Wall:GetPrediction(target)
            local bestPos = nil
            if predPos then
                for i = 0, (Poppy.Spells.E_Wall.Range - target.BoundingRadius), 10 do
                    local position = Player.Position:Extended(predPos.TargetPosition, Player:Distance(predPos.TargetPosition) + i)
                    if Nav.IsWall(position) then
                        bestPos = position
                        shouldCast = true
                        break
                    end
                end
            end
            if shouldCast then
                return Poppy.Spells.E:Cast(target)
            end
        end
    end
    if n == 2 and Poppy.IsReady("Q", "Combo") then
        local hitChance = Menu.Get("SPoppy.Q.Combo.HitChance")
        for k, target in ipairs(Poppy.Spells.Q:GetTargets()) do
            return Poppy.Spells.Q:CastOnHitChance(target, hitChance)
        end
    end
end

function Poppy.Harass(n)
    if n == 1 and Poppy.IsReady("Q", "Harass") then
        local hitChance = Menu.Get("SPoppy.Q.Harass.HitChance")
        for k, target in ipairs(Poppy.Spells.Q:GetTargets()) do
            return Poppy.Spells.Q:CastOnHitChance(target, hitChance)
        end
    end
end

function Poppy.Lasthit(n)
    if not Menu.Get("ShulepinScript.InfoPanel.SpellFarmStatus") then return end

    local lastTarget = Orbwalker.GetLastTarget()

    if n == 1 and Poppy.IsReady("Q", "Waveclear", true) then
        if lastTarget and lastTarget.IsMonster and TargetSelector:IsValidTarget(Poppy.Spells.Q.Range) then
            return Poppy.Spells.Q:Cast(lastTarget.Position)
        else
            local minHits = Menu.Get("SPoppy.Q.Waveclear.Minions")
            return Poppy.Spells.Q:CastIfWillHit(minHits, "minions")
        end
    end
end

function Poppy.Waveclear(n)
    if not Menu.Get("ShulepinScript.InfoPanel.SpellFarmStatus") then return end

    local lastTarget = Orbwalker.GetLastTarget()

    if n == 1 and Poppy.IsReady("Q", "Waveclear") then
        if lastTarget and lastTarget.IsMonster and TargetSelector:IsValidTarget(lastTarget, Poppy.Spells.Q.Range) then
            return Poppy.Spells.Q:CastOnHitChance(lastTarget, HitChance.Low)
        else
            local targs = Poppy.Spells.Q:GetFarmTargets()
            if targs[1] then
                return Poppy.Spells.Q:Cast(targs[1])
            end
        end
    end
    if n == 2 and Poppy.IsReady("E", "Waveclear") then
        if lastTarget and lastTarget.IsMonster and TargetSelector:IsValidTarget(lastTarget, Poppy.Spells.E.Range) then
            return Poppy.Spells.E:Cast(lastTarget)
        end
    end
end

function Poppy.KillSteal(n)
    if n == 1 and Poppy.IsReady("Q", "Killsteal") then
        for k, target in ipairs(Poppy.Spells.Q:GetTargets()) do
            local whiteListValue = Menu.Get("SPoppy.Q.Killsteal.WhiteList." .. target.CharName, true)
            if whiteListValue and Poppy.Spells.Q:CanKillTarget(target) then
                return Poppy.Spells.Q:CastOnHitChance(target, HitChance.Low)
            end
        end
    end
    if n == 2 and Poppy.IsReady("E", "Killsteal") then
        for k, target in ipairs(Poppy.Spells.E:GetTargets()) do
            local whiteListValue = Menu.Get("SPoppy.Q.Killsteal.WhiteList." .. target.CharName, true)
            if whiteListValue and Poppy.Spells.E:CanKillTarget(target) then
                return Poppy.Spells.E:Cast(target)
            end
        end
    end
end

function Poppy.OnNormalPriority(n)
    if not Game.CanSendInput() then return end 
    if not Orbwalker.CanCast() then return end

    local orbMode = Poppy[Orbwalker.GetMode()]
    if orbMode then
        orbMode(n)
    end
end

function Poppy.OnExtremePriority(n)
    if not Game.CanSendInput() then return end

    Poppy.KillSteal(n)
end

function Poppy.OnDraw()
    for k, spell in pairs({ "Q", "E" }) do
        if Menu.Get("SPoppy." .. spell .. ".Draw.Use") and Poppy.Spells[spell]:IsReady() then
            local color = Menu.Get("SPoppy." .. spell .. ".Draw.Color")
            Renderer.DrawCircle3D(Player.Position, Poppy.Spells[spell].Range, 10, 3, color)
        end
    end
end

function Poppy.OnDrawDamage(target, dmgList)
    local totalDamage = 0

    if Poppy.Spells.Q:IsReady() and Menu.Get("SPoppy.Q.Draw.Damage") then
        totalDamage = totalDamage + Poppy.Spells.Q:GetDamage(target)
    end

    if Poppy.Spells.E:IsReady() and Menu.Get("SPoppy.E.Draw.Damage") then
        totalDamage = totalDamage + Poppy.Spells.E:GetDamage(target)
    end

    table.insert(dmgList, totalDamage)
end

function Poppy.OnGapclose(unit, dashData)
    if unit.IsAlly then return end
    if unit.CharName == "MasterYi" then return end
    if dashData.Invulnerable then return end
    
    if Poppy.IsReady("W", "Combo") then
        local shouldCast = false
        local whiteListValue = Menu.Get("SPoppy.W.Combo.WhiteList." .. unit.CharName, true)
        if whiteListValue and dashData.Slot > -1 then
            if Player.Position:Distance(dashData.StartPos) < Poppy.Spells.W.Range then
                shouldCast = true
            elseif Player.Position:Distance(dashData:GetPosition()) < Poppy.Spells.W.Range then
                shouldCast = true
            end
            if shouldCast then
                return Poppy.Spells.W:Cast()
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
    Poppy.Initialize()
    return true
end

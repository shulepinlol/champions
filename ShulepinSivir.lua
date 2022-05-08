--[[
    ███████ ██ ██    ██ ██ ██████  
    ██      ██ ██    ██ ██ ██   ██ 
    ███████ ██ ██    ██ ██ ██████  
         ██ ██  ██  ██  ██ ██   ██ 
    ███████ ██   ████   ██ ██   ██
]]

if Player.CharName ~= "Sivir" then return end

local Sivir = {}
local Script = {
    Name = "Shulepin" .. Player.CharName,
    Version = "1.0.3",
    LastUpdated = "14/12/2021",
    Changelog = {
        [1] = "[14/12/2021 - Version 1.0.0]: Initial release",
    }
}

module(Script.Name, package.seeall, log.setup)
clean.module(Script.Name, clean.seeall, log.setup)
CoreEx.AutoUpdate("https://github.com/shulepinlol/champions/raw/main/" .. Script.Name .. ".lua", Script.Version)

--[[
     █████  ██████  ██ 
    ██   ██ ██   ██ ██ 
    ███████ ██████  ██ 
    ██   ██ ██      ██ 
    ██   ██ ██      ██                                  
]]

local SDK = _G.CoreEx
local Player = _G.Player
local DreamEvade = _G.DreamEvade

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

    local text = "Shulepin Sivir"
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
            font:DrawText(textPosition, text, 0xFFFFFFFF)
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

function Sivir.Initialize()
    Sivir.CreateMenu()
    Sivir.CreateSpells()
    Sivir.CreateEvents()
end

function Sivir.CreateSpells()
    Sivir.Spells = {}

    Sivir.Spells["Q"] = Spell.Skillshot({
        Slot            = SpellSlots.Q,
        Range           = 1250,
        Width           = 180,
        Delay           = 0.25,
        Speed           = 1350,
        Type            = "Linear",
        Collisions      = { WindWall = true },
    })

    Sivir.Spells["W"] = Spell.Active({
        Slot            = SpellSlots.W
    })

    Sivir.Spells["E"] = Spell.Active({
        Slot            = SpellSlots.E
    })
end

function Sivir.CreateEvents()
    for name, id in pairs(Events) do
        if Sivir[name] then
            EventManager.RegisterCallback(id, Sivir[name])
        end
    end
end

function Sivir.CreateMenu()
    Menu.RegisterMenu("ShulepinSivir", "Shulepin | Sivir", function()
        Menu.Text("Spell Settings", true)
        Menu.Separator()
        Menu.NewTree("ShulepinSivir.Q", "[Q] Boomerang Blade", function()
            Menu.NewTree("ShulepinSivir.Q.Combo", "Combo Settings", function()
                Menu.Checkbox("ShulepinSivir.Q.Combo.Use", "Use [Q] Boomerang Blade", true)
                Menu.Text("Min. HitChance - "); Menu.SameLine(); Menu.Dropdown("ShulepinSivir.Q.Combo.HitChance", "", 4, HitChanceList)
            end)
            Menu.NewTree("ShulepinSivir.Q.Harass", "Harass Settings", function()
                Menu.Checkbox("ShulepinSivir.Q.Harass.Use", "Use [Q] Boomerang Blade", true)
                Menu.Text("Min. Mana [%%]  - "); Menu.SameLine(); Menu.Slider("ShulepinSivir.Q.Harass.Mana", "", 35, 0, 100, 1)
                Menu.Text("Min. HitChance - "); Menu.SameLine(); Menu.Dropdown("ShulepinSivir.Q.Harass.HitChance", "", 4, HitChanceList)
                AddWhiteListMenu("ShulepinSivir.Q.Harass.WhiteList.")
            end)
            Menu.NewTree("ShulepinSivir.Q.Waveclear", "Wave Clear Settings", function()
                Menu.Checkbox("ShulepinSivir.Q.Waveclear.Use", "Use [Q] Boomerang Blade", true)
                Menu.Text("Min. Mana [%%]    - "); Menu.SameLine(); Menu.Slider("ShulepinSivir.Q.Waveclear.Mana", "", 35, 0, 100, 1)
                Menu.Text("Min. Minion Hits - "); Menu.SameLine(); Menu.Slider("ShulepinSivir.Q.Waveclear.Minions", "", 3, 0, 6, 1)

            end)
            Menu.NewTree("ShulepinSivir.Q.Killsteal", "Kill Steal Settings", function()
                Menu.Checkbox("ShulepinSivir.Q.Killsteal.Use", "Use [Q] Boomerang Blade", true)
                AddWhiteListMenu("ShulepinSivir.Q.Killsteal.WhiteList.")
            end)
            Menu.NewTree("ShulepinSivir.Q.Immobile", "Immobile Settings", function()
                Menu.Checkbox("ShulepinSivir.Q.Immobile.Use", "Auto Use [Q] Boomerang Blade On Immobile Enemy", true)
                AddWhiteListMenu("ShulepinSivir.Q.Immobile.WhiteList.")
            end)
            Menu.NewTree("ShulepinSivir.Q.Draw", "Draw Settings", function()
                Menu.Checkbox("ShulepinSivir.Q.Draw.Damage", "Draw [Q] Boomerang Blade Damage", true)
                Menu.Checkbox("ShulepinSivir.Q.Draw.Use", "Draw [Q] Boomerang Blade Range", true)
                Menu.Text("Color - "); Menu.SameLine(); Menu.ColorPicker("ShulepinSivir.Q.Draw.Color", "", 0xFFFFFFFF)
            end)
        end)

        Menu.NewTree("W", "[W] Ricochet", function()
            Menu.NewTree("ShulepinSivir.W.Combo", "Combo Settings", function()
                Menu.Checkbox("ShulepinSivir.W.Combo.Use", "Use [W] Ricochet", true)
            end)
            Menu.NewTree("ShulepinSivir.W.Harass", "Harass Settings", function()
                Menu.Checkbox("ShulepinSivir.W.Harass.Use", "Use [W] Ricochet", true)
            end)
            Menu.NewTree("ShulepinSivir.W.Waveclear", "Wave Clear Settings", function()
                Menu.Checkbox("ShulepinSivir.W.Waveclear.Use", "Use [W] Ricochet", true)
            end)
        end)

        Menu.NewTree("E", "[E] Spell Shield", function()
            if DreamEvade then
                Menu.Checkbox("ShulepinSivir.E.Combo.Use", "Block Spells With [E] Spell Shield", true)
                Menu.Text("Min. Danger Level - "); Menu.SameLine(); Menu.Slider("ShulepinSivir.E.Combo.Danger", "", 3, 1, 5, 1)
            else
                Menu.Text("Enable DreamEvade")
            end
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

function Sivir.IsReady(spell, mode, checkMana)
    local fastClear = Orbwalker.IsFastClearEnabled()
    local id = "ShulepinSivir." .. spell .. "." .. mode
    return 
        Menu.Get(id .. ".Use") and 
        Sivir.Spells[spell]:IsReady() and
        (checkMana ~= nil and (Menu.Get(id .. ".Mana") / 100) < Player.ManaPercent or fastClear or checkMana == nil)
end

function Sivir.Combo(n)
    if n == 1 and Sivir.IsReady("Q", "Combo") then
        local hitChance = Menu.Get("ShulepinSivir.Q.Combo.HitChance")
        for k, target in ipairs(Sivir.Spells.Q:GetTargets()) do
            return Sivir.Spells.Q:CastOnHitChance(target, hitChance)
        end
    end
end

function Sivir.Harass(n)
    if n == 1 and Sivir.IsReady("Q", "Harass", true) then
        local hitChance = Menu.Get("ShulepinSivir.Q.Harass.HitChance")
        for k, target in ipairs(Sivir.Spells.Q:GetTargets()) do
            local whiteListValue = Menu.Get("ShulepinSivir.Q.Harass.WhiteList." .. target.CharName, true)
            if whiteListValue then
                return Sivir.Spells.Q:CastOnHitChance(target, hitChance)
            end
        end
    end
end

function Sivir.Waveclear(n)
    if not Menu.Get("ShulepinScript.InfoPanel.SpellFarmStatus") then return end

    local lastTarget = Orbwalker.GetLastTarget()

    if n == 1 and Sivir.IsReady("Q", "Waveclear", true) then
        if lastTarget and lastTarget.IsMonster and TargetSelector:IsValidAutoRange(lastTarget) then
            return Sivir.Spells.Q:Cast(lastTarget.Position)
        else
            local minHits = Menu.Get("ShulepinSivir.Q.Waveclear.Minions")
            return Sivir.Spells.Q:CastIfWillHit(minHits, "minions")
        end
    end
end

function Sivir.KillSteal(n)
    if n == 1 and Sivir.IsReady("Q", "Killsteal") then
        for k, target in ipairs(Sivir.Spells.Q:GetTargets()) do
            local whiteListValue = Menu.Get("ShulepinSivir.Q.Killsteal.WhiteList." .. target.CharName, true)
            if whiteListValue and Sivir.Spells.Q:CanKillTarget(target) then
                return Sivir.Spells.Q:CastOnHitChance(target, HitChance.Medium)
            end
        end
    end
end

function Sivir.OnNormalPriority(n)
    if not Game.CanSendInput() then return end 
    if not Orbwalker.CanCast() then return end

    local orbMode = Sivir[Orbwalker.GetMode()]
    if orbMode then
        orbMode(n)
    end

    Sivir.KillSteal(n)
end

function Sivir.OnExtremePriority(n)
    if not DreamEvade then return end

    if Sivir.IsReady("E", "Combo") then
        for k, spell in pairs(DreamEvade.DangerousSpells) do
            if spell:IsOhShit() then
                local dangerLevel = Menu.Get("ShulepinSivir.E.Combo.Danger")
                if spell:GetDangerLevel() >= dangerLevel then
                    return Sivir.Spells.E:Cast()
                end
            end
        end
    end
end

function Sivir.OnHeroImmobilized(unit, endTime, isStasis)
    if unit.IsAlly then return end

    if Sivir.IsReady("Q", "Immobile") then
        local leftTime = endTime - Game.GetTime()
        local travelTime = Sivir.Spells.Q.Delay + Player:Distance(unit) / Sivir.Spells.Q.Speed
        local whiteListValue = Menu.Get("ShulepinSivir.Q.Immobile.WhiteList." .. unit.CharName, true)
        if travelTime < leftTime and whiteListValue then
            return Sivir.Spells.Q:Cast(unit.Position)
        end
    end
end

function Sivir.OnPostAttack(target)
    if target.IsHero then
        if Sivir.IsReady("W", "Combo") then
            return Sivir.Spells.W:Cast()
        end

        if Sivir.IsReady("W", "Harass") then
            return Sivir.Spells.W:Cast()
        end
    elseif target.IsMinion then
        if not Menu.Get("ShulepinScript.InfoPanel.SpellFarmStatus") then return end
        if Sivir.IsReady("W", "Waveclear") then
            return Sivir.Spells.W:Cast()
        end
    end
end

function Sivir.OnDraw()
    if Menu.Get("ShulepinSivir.Q.Draw.Use") and Sivir.Spells.Q:IsReady() then
        local color = Menu.Get("ShulepinSivir.Q.Draw.Color")
        Renderer.DrawCircle3D(Player.Position, Sivir.Spells.Q.Range, 10, 3, color)
    end
end

function Sivir.OnDrawDamage(target, dmgList)
    local totalDamage = 0

    if Sivir.Spells.Q:IsReady() and Menu.Get("ShulepinSivir.Q.Draw.Damage") then
        totalDamage = totalDamage + (Sivir.Spells.Q:GetDamage(target) * 2)
    end

    table.insert(dmgList, totalDamage)
end

--[[
    ██       ██████   █████  ██████  
    ██      ██    ██ ██   ██ ██   ██ 
    ██      ██    ██ ███████ ██   ██ 
    ██      ██    ██ ██   ██ ██   ██ 
    ███████  ██████  ██   ██ ██████  
]]

function OnLoad()
    Sivir.Initialize()
    return true
end

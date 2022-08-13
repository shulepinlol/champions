--[[
    ███████ ██    ██ ███████ ██      ██    ██ ███    ██ ███    ██ 
    ██      ██    ██ ██      ██       ██  ██  ████   ██ ████   ██ 
    █████   ██    ██ █████   ██        ████   ██ ██  ██ ██ ██  ██ 
    ██       ██  ██  ██      ██         ██    ██  ██ ██ ██  ██ ██ 
    ███████   ████   ███████ ███████    ██    ██   ████ ██   ████                                                                                                                      
]]

if Player.CharName ~= "Evelynn" then return end

local Evelynn = {}
local Script = {
    Name = "Shulepin" .. Player.CharName,
    Version = "1.0.6",
    LastUpdated = "12/08/2022",
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

    local text = "Shulepin Evelynn"
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

function Evelynn.Initialize()
    Evelynn.CreateMenu()
    Evelynn.CreateSpells()
    Evelynn.CreateEvents()

    InfoPanel.AddOption({
        Text = "R Execute",
        Type = 1,
        Key = 0,
        Value = "SEvelynn.R.Killsteal.Use"
    })
end

function Evelynn.CreateSpells()
    Evelynn.Spells = {}

    Evelynn.Spells["Q"] = Spell.Skillshot({
        Slot            = SpellSlots.Q,
        Range           = 800,
        Radius          = 60,
        Delay           = 0.25,
        Speed           = 2400,
        Type            = "Linear",
        Collisions      = { WindWall = true, Heroes = true, Minions = true },
    })

    Evelynn.Spells["E"] = Spell.Targeted({
        Slot            = SpellSlots.E,
        Range           = 300,
        Delay           = 0.25
    })

    Evelynn.Spells["R"] = Spell.Skillshot({
        Slot            = SpellSlots.R,
        Range           = 450,
        ConeAngleRad    = 90 * pi / 180,
        Delay           = 0.35,
        Speed           = huge,
        Type            = "Cone"
    })
end

function Evelynn.CreateEvents()
    for name, id in pairs(Events) do
        if Evelynn[name] then
            EventManager.RegisterCallback(id, Evelynn[name])
        end
    end
end

function Evelynn.CreateMenu()
    Menu.RegisterMenu("SEvelynn", "Shulepin | Evelynn", function()
        Menu.Separator("Spell Settings")

        Menu.NewTree("SEvelynn.Q", "[Q] Hate Spike", function()
            Menu.NewTree("SEvelynn.Q.Combo", "Combo Settings", function()
                Menu.Checkbox("SEvelynn.Q.Combo.Use", "Use [Q] Hate Spike", true)
                Menu.Dropdown("SEvelynn.Q.Combo.HitChance", "Min. HitChance", 2, HitChanceList)
            end)
            Menu.NewTree("SEvelynn.Q.Waveclear", "Wave Clear Settings", function()
                Menu.Checkbox("SEvelynn.Q.Waveclear.Use", "Use [Q] Hate Spike", true)
                Menu.Slider("SEvelynn.Q.Waveclear.Mana", "Min. Mana [%]", 35, 0, 100, 1)
            end)
            Menu.NewTree("SEvelynn.Q.Killsteal", "Killsteal Settings", function()
                Menu.Checkbox("SEvelynn.Q.Killsteal.Use", "Use [Q] Hate Spike", true)
                AddWhiteListMenu("SEvelynn.Q.Killsteal.WhiteList.")
            end)
            Menu.NewTree("SEvelynn.Q.Draw", "Draw Settings", function()
                Menu.Checkbox("SEvelynn.Q.Draw.Damage", "Draw [Q] Hate Spike Damage", true)
                Menu.Checkbox("SEvelynn.Q.Draw.Use", "Draw [Q] Hate Spike Range", true)
                Menu.ColorPicker("SEvelynn.Q.Draw.Color", "Color", 0xf231f2)
            end)
        end)

        Menu.NewTree("SEvelynn.E", "[E] Whiplash", function()
            Menu.NewTree("SEvelynn.E.Combo", "Combo Settings", function()
                Menu.Checkbox("SEvelynn.E.Combo.Use", "Use [E] Whiplash", true)
            end)
            Menu.NewTree("SEvelynn.E.Waveclear", "Wave Clear Settings", function()
                Menu.Checkbox("SEvelynn.E.Waveclear.Use", "Use [E] Whiplash", true)
                Menu.Slider("SEvelynn.E.Waveclear.Mana", "Min. Mana [%]", 35, 0, 100, 1)
            end)
            Menu.NewTree("SEvelynn.E.Killsteal", "Killsteal Settings", function()
                Menu.Checkbox("SEvelynn.E.Killsteal.Use", "Use [E] Whiplash", true)
                AddWhiteListMenu("SEvelynn.E.Killsteal.WhiteList.")
            end)
            Menu.NewTree("SEvelynn.E.Draw", "Draw Settings", function()
                Menu.Checkbox("SEvelynn.E.Draw.Damage", "Draw [E] Whiplash Damage", true)
                Menu.Checkbox("SEvelynn.E.Draw.Use", "Draw [E] Whiplash Range", true)
                Menu.ColorPicker("SEvelynn.E.Draw.Color", "Color", 0x871b87)
            end)
        end)

        Menu.NewTree("SEvelynn.R", "[R] Last Caress", function()
            Menu.NewTree("SEvelynn.R.Killsteal", "Execute Settings", function()
                Menu.Checkbox("SEvelynn.R.Killsteal.Use", "Use [R] Last Caress", true)
                AddWhiteListMenu("SEvelynn.R.Killsteal.WhiteList.")
            end)
            Menu.NewTree("SEvelynn.R.Draw", "Draw Settings", function()
                Menu.Checkbox("SEvelynn.R.Draw.Damage", "Draw [R] Last Caress Damage", true)
                Menu.Checkbox("SEvelynn.R.Draw.Use", "Draw [R] Last Caress Range", true)
                Menu.ColorPicker("SEvelynn.R.Draw.Color", "Color", 0x871b87)
            end)
        end)

        Menu.Separator("Other Settings")
        InfoPanel.CreateMenu()
        Menu.Separator("Author: Shulepin")
    end)
end

function Evelynn.IsReady(spell, mode, checkMana)
    local fastClear = Orbwalker.IsFastClearEnabled()
    local id = "SEvelynn." .. spell .. "." .. mode
    return 
        Menu.Get(id .. ".Use") and 
        Evelynn.Spells[spell]:IsReady() and
        (checkMana ~= nil and (Menu.Get(id .. ".Mana") / 100) < Player.ManaPercent or fastClear or checkMana == nil)
end

function Evelynn.Combo(n)
    if n == 2 and Evelynn.IsReady("E", "Combo") then
        for k, target in ipairs(Evelynn.Spells.E:GetTargets()) do
            return Evelynn.Spells.E:Cast(target)
        end
    end
    if n == 3 and Evelynn.IsReady("Q", "Combo") then
        local shouldCast = false
        local spellName = Evelynn.Spells.Q:GetName()
        local hitChance = Menu.Get("SEvelynn.Q.Combo.HitChance")
        for k, target in ipairs(Evelynn.Spells.Q:GetTargets()) do
            local buff = target:GetBuff("EvelynnW")
            if buff then
                local endTime = buff.StartTime + 2.5
                local travelTime = spellName == "EvelynnQ" and Evelynn.Spells.Q.Delay + Player:Distance(target) / Evelynn.Spells.Q.Speed or 0
                if endTime - Game.GetTime() < travelTime then
                    shouldCast = true
                end
            else
                shouldCast = true
            end
            if shouldCast then
                if spellName == "EvelynnQ" then
                    return Evelynn.Spells.Q:CastOnHitChance(target, hitChance)
                else
                    return Input.Cast(SpellSlots.Q)
                end
            end
        end
    end
end

function Evelynn.Waveclear(n)
    if not Menu.Get("ShulepinScript.InfoPanel.SpellFarmStatus") then return end

    local spellName = Evelynn.Spells.Q:GetName()
    local lastTarget = Orbwalker.GetLastTarget()

    if n == 1 and Evelynn.IsReady("Q", "Waveclear", true) then
        if lastTarget and lastTarget.IsMonster and TargetSelector:IsValidTarget(lastTarget, Evelynn.Spells.Q.Range) then
            return Evelynn.Spells.Q:Cast(lastTarget.Position)
        else
            local minionC = 0
            for k, v in ipairs(ObjectManager.GetNearby("enemy", "minions")) do
                if v.IsTargetable then
                    minionC = minionC + 1
                end
            end
            if spellName == "EvelynnQ" then
                if minionC >= 2 then
                    return Evelynn.Spells.Q:CastIfWillHit(1, "minions")
                end
            else
                return Input.Cast(SpellSlots.Q)
            end
        end
    end
    if n == 2 and Evelynn.IsReady("E", "Waveclear", true) and (lastTarget and lastTarget.IsMinion and TargetSelector:IsValidTarget(lastTarget, Evelynn.Spells.Q.Range)) then
        return Evelynn.Spells.E:Cast(lastTarget)
    end
end

function Evelynn.KillSteal(n)
    if n == 1 and Evelynn.IsReady("R", "Killsteal") then
        for k, target in ipairs(Evelynn.Spells.R:GetTargets()) do
            local whiteListValue = Menu.Get("SEvelynn.R.Killsteal.WhiteList." .. target.CharName, true)
            if whiteListValue and Evelynn.Spells.R:CanKillTarget(target) then
                return Evelynn.Spells.R:CastOnHitChance(target, HitChance.Low)
            end
        end
    end
    if n == 2 and Evelynn.IsReady("Q", "Killsteal") then
        for k, target in ipairs(Evelynn.Spells.Q:GetTargets()) do
            local whiteListValue = Menu.Get("SEvelynn.Q.Killsteal.WhiteList." .. target.CharName, true)
            if whiteListValue and Evelynn.Spells.Q:CanKillTarget(target) then
                return Evelynn.Spells.Q:CastOnHitChance(target, HitChance.Low)
            end
        end
    end
    if n == 3 and Evelynn.IsReady("E", "Killsteal") then
        for k, target in ipairs(Evelynn.Spells.E:GetTargets()) do
            local whiteListValue = Menu.Get("SEvelynn.E.Killsteal.WhiteList." .. target.CharName, true)
            if whiteListValue and Evelynn.Spells.E:CanKillTarget(target) then
                return Evelynn.Spells.E:Cast(target)
            end
        end
    end
end

function Evelynn.OnNormalPriority(n)
    if not Game.CanSendInput() then return end 
    if not Orbwalker.CanCast() then return end

    local orbMode = Evelynn[Orbwalker.GetMode()]
    if orbMode then
        orbMode(n)
    end
end

function Evelynn.OnExtremePriority(n)
    if not Game.CanSendInput() then return end

    Evelynn.KillSteal(n)
end

function Evelynn.OnDraw()
    for k, spell in pairs({ "Q", "E", "R" }) do
        if Menu.Get("SEvelynn." .. spell .. ".Draw.Use") and Evelynn.Spells[spell]:IsReady() then
            local color = Menu.Get("SEvelynn." .. spell .. ".Draw.Color")
            Renderer.DrawCircle3D(Player.Position, Evelynn.Spells[spell].Range, 10, 3, color)
        end
    end
end

function Evelynn.OnDrawDamage(target, dmgList)
    local totalDamage = 0

    if Evelynn.Spells.Q:IsReady() and Menu.Get("SEvelynn.Q.Draw.Damage") then
        totalDamage = totalDamage + (Evelynn.Spells.Q:GetDamage(target) + Evelynn.Spells.Q:GetDamage(target, "SecondCast") * 3)
    end

    if Evelynn.Spells.E:IsReady() and Menu.Get("SEvelynn.E.Draw.Damage") then
        totalDamage = totalDamage + Evelynn.Spells.E:GetDamage(target)
    end

    if Evelynn.Spells.R:IsReady() and Menu.Get("SEvelynn.R.Draw.Damage") then
        totalDamage = totalDamage + Evelynn.Spells.R:GetDamage(target)
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
    Evelynn.Initialize()
    return true
end

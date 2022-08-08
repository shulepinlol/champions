if Player.CharName ~= "Irelia" then return end

----------------------------------------------------------------------------------------------

local SCRIPT_NAME, VERSION, LAST_UPDATE = "ShulepinIrelia", "1.0.6", "08/08/2022"
_G.CoreEx.AutoUpdate("https://raw.githubusercontent.com/shulepinlol/champions/main/" .. SCRIPT_NAME .. ".lua", VERSION)
module(SCRIPT_NAME, package.seeall, log.setup)
clean.module(SCRIPT_NAME, clean.seeall, log.setup)

----------------------------------------------------------------------------------------------

local SDK               = _G.CoreEx

local DamageLib         = _G.Libs.DamageLib
local CollisionLib      = _G.Libs.CollisionLib
local Menu              = _G.Libs.NewMenu
local Prediction        = _G.Libs.Prediction
local TargetSelector    = _G.Libs.TargetSelector
local Orbwalker         = _G.Libs.Orbwalker
local Spell             = _G.Libs.Spell
local TS                = _G.Libs.TargetSelector()

local ObjectManager     = SDK.ObjectManager
local EventManager      = SDK.EventManager
local Input             = SDK.Input
local Game              = SDK.Game
local Geometry          = SDK.Geometry
local Renderer          = SDK.Renderer
local Enums             = SDK.Enums

local Events            = Enums.Events
local SpellSlots        = Enums.SpellSlots
local SpellStates       = Enums.SpellStates
local HitChance         = Enums.HitChance
local DamageTypes       = Enums.DamageTypes
local Vector            = Geometry.Vector

local pairs             = _G.pairs
local type              = _G.type
local tonumber          = _G.tonumber
local math_abs          = _G.math.abs
local math_huge         = _G.math.huge
local math_min          = _G.math.min
local math_deg          = _G.math.deg
local math_sin          = _G.math.sin
local math_cos          = _G.math.cos
local math_acos         = _G.math.acos
local math_pi           = _G.math.pi
local math_pi2          = 0.01745329251
local os_clock          = _G.os.clock
local string_format     = _G.string.format
local table_remove      = _G.table.remove

local _Q                = SpellSlots.Q
local _W                = SpellSlots.W
local _E                = SpellSlots.E
local _R                = SpellSlots.R

local ItemID            = require("lol/Modules/Common/ItemID")

----------------------------------------------------------------------------------------------

local Q = Spell.Targeted({
    ["Slot"] = _Q,
    ["SlotString"] = "Q",
    ["Range"] = 600,
})

local W = Spell.Skillshot({
    ["Slot"] = _W,
    ["SlotString"] = "W",
    ["Range"] = 775,
    ["Delay"] = 0.25,
    ["Radius"] = 120,
    ["Speed"] = math_huge,
    ["Type"] = "Linear",
})

local E = Spell.Skillshot({
    ["Slot"] = _E,
    ["SlotString"] = "E",
    ["Range"] = 775,
    ["Delay"] = 0.25,
    ["Radius"] = 70,
    ["Speed"] = 2000,
    ["Type"] = "Linear",
})

local R = Spell.Skillshot({
    ["Slot"] = _R,
    ["SlotString"] = "R",
    ["Range"] = 1000,
    ["Delay"] = 0.4,
    ["Radius"] = 105,
    ["Speed"] = 2000,
    ["Type"] = "Linear",
})

----------------------------------------------------------------------------------------------

local LastCastT = {
    [_Q] = 0,
    [_W] = 0,
    [_E] = 0,
    [_R] = 0,
}

local DrawSpellTable = { Q, W, E, R }

local Item = {
    Sheen = false,
    TrinityForce = false,
    WitsEnd = false,
    RecurveBow = false,
    BladeOftheRuinedKing = false,
    TitanicHydra = false
}

local LastItemUpdateT = 0
local LastSheenT = os_clock()
local TickCount = 0

local BladePosition = nil

---@type fun(a: number, r: number, g: number, b: number):number
local ARGB = function(a, r, g, b)
    return tonumber(string_format("0x%02x%02x%02x%02x", r, g, b, a))
end

---@type fun():boolean
local GameIsAvailable = function()
    return not Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling
end

---@type fun(object: GameObject, range: number, from: Vector):boolean
local IsValidTarget = function(object, range, from)
    local from = from or Player.Position
    return TS:IsValidTarget(object, range, from)
end

---@type fun(obj: GameObject):boolean
local IsValidObject = function(obj)
    return obj and obj.IsValid and not obj.IsDead
end

---@type fun(spell: SpellBase, condition: function):boolean
local IsReady = function(spell, condition)
    local isReady = spell:IsReady()
    if condition ~= nil then
        return isReady and (type(condition) == "function" and condition() or type(condition) == "boolean" and condition)
    end
    return isReady
end

---@type fun(value: number):boolean
local IsEnoughMana = function(value)
    local manaPct = Player.AsAttackableUnit.ManaPercent
    return manaPct > value * 0.01
end

---@type fun(slot: number, position: Vector|GameObject, condition: function|boolean):void
local CastSpell = function(slot, position, condition)
    local tick = os_clock()
    if LastCastT[slot] + 0.050 < tick then
        if Input.Cast(slot, position) then
            LastCastT[slot] = tick
            if condition ~= nil then
                return true and (type(condition) == "function" and condition() or type(condition) == "boolean" and condition)
            end
            return true
        end
    end
    return false
end

---@type fun(id: string):void
local AddWhiteListMenu = function(name, id)
    Menu.NewTree(id .. "WhiteList", name, function()
        local heroes = ObjectManager.Get("enemy", "heroes")
        for k, hero in pairs(heroes) do
            local heroAI = hero.AsAI
            Menu.Checkbox(id .. "WhiteList" .. heroAI.CharName, heroAI.CharName, true)
        end
    end)
end

---@type fun(id: string):boolean|number
local GetMenuValue = function(id)
    local menuValue = Menu.Get(id, true)
    if menuValue then
        return menuValue
    end
    return false
end

---@type fun(id: string):boolean|number
local GetKeyMenuValue = function(id)
    local menuValue = Menu.GetKey(id, true)
    if menuValue then
        return menuValue
    end
    return false
end

---@type fun(slot: string, mode: string, heroName: string):boolean
local GetWhiteListValue = function(slot, mode, heroName)
    return GetMenuValue(mode .. slot .. "WhiteList" .. heroName)
end

---@type fun():void
local ItemLoop = function()
    local tick = os_clock()
    if tick > LastItemUpdateT then
        Item.Sheen = false
        Item.TrinityForce = false
        Item.WitsEnd = false
        Item.RecurveBow = false
        Item.BladeOftheRuinedKing = false
        Item.TitanicHydra = false

        for slot, item in pairs(Player.Items) do
            local id = item.ItemId
            if id == ItemID.Sheen then
                Item.Sheen = true
            end
            if id == ItemID.TrinityForce then
                Item.TrinityForce = true
            end
            if id == ItemID.WitsEnd then
                Item.WitsEnd = true
            end
            if id == ItemID.RecurveBow then
                Item.RecurveBow = true
            end
            if id == ItemID.BladeOftheRuinedKing then
                Item.BladeOftheRuinedKing = true
            end
            if id == ItemID.TitanicHydra then
                Item.TitanicHydra = true
            end
        end
        LastItemUpdateT = tick + 5
    end
end

----------------------------------------------------------------------------------------------

---@type fun(spell: table, target: GameObject):number
local GetDamage = function(spell, target)
    local tick = os_clock()
    local slot = spell.Slot
    local myLevel = Player.Level
    local level = Player.AsHero:GetSpell(slot).Level
    if slot == _Q then
        local damage = 0
        local pDamage = 0
        local mDamage = 0
        local maxStacks = Player:GetBuff("ireliapassivestacksmax")
        local baseAD = Player.BaseAttackDamage
        local flatAD = Player.FlatPhysicalDamageMod
        local totalAD = Player.TotalAD
        if Item.BladeOftheRuinedKing then
            local activeBuff = target:GetBuff("item3153botrkstacks")
            local botrkDamage = target.Health * 0.1
            local rawActiveBotrkDamage = ({ 40, 44.71, 49.41, 54.12, 58.82, 63.53, 68.24, 72.94, 77.65, 82.35, 87.06, 91.76, 96.47, 101.18, 105.88, 110.59, 115.29, 120 })[myLevel]
            if target.IsMinion or target.IsMonster then
                botrkDamage = math.min(botrkDamage, 60)
            end
            if activeBuff and activeBuff.Count == 2 then
                mDamage = mDamage + rawActiveBotrkDamage
            end
            pDamage = pDamage + botrkDamage
        end
        if Item.WitsEnd then
            local witsEndDamage = ({15, 18.82, 22.65, 26.47, 30.29, 34.12, 37.94, 41.76, 45.59, 49.41, 53.24, 57.06, 60.88, 64.71, 68.53, 72.35, 76.18, 80})[myLevel]
            mDamage = mDamage + witsEndDamage
        end
        if Item.TrinityForce then 
            local tfBuff = Player:GetBuff("3078trinityforce")
            if (tick >= LastSheenT or tfBuff) then 
                pDamage = pDamage + (baseAD * 2)
            end
        end
        if Item.Sheen and not Item.TrinityForce then
            local sheenBuff = Player:GetBuff("sheen")
            if (tick >= LastSheenT or sheenBuff) then
                pDamage = pDamage + baseAD
            end
        end
        if Item.RecurveBow then
            pDamage = pDamage + 15
        end
        if Item.TitanicHydra then
            pDamage = pDamage + 5 + (Player.MaxHealth * 0.015)
        end
        if maxStacks then
            mDamage = mDamage + (12 + 3 * myLevel) + flatAD * 0.25
        end
        local qDamage = -15 + 20 * level + totalAD * 0.6
        local qMinionDamage = 20 + 40 * level + totalAD * 0.6
        if target.IsMonster or target.IsHero then
            damage = DamageLib.CalculatePhysicalDamage(Player, target, qDamage + pDamage) + DamageLib.CalculateMagicalDamage(Player, target, mDamage)
        elseif target.IsMinion then
            damage = DamageLib.CalculatePhysicalDamage(Player, target, qMinionDamage + pDamage) + DamageLib.CalculateMagicalDamage(Player, target, mDamage)
        end
        return damage
    end
    return 0
end

---@type fun(unit: GameObject):void
local CanKillWithQ = function(unit)
    local damage = (GetDamage(Q, unit) - 10)
    if unit.IsMinion then
        return damage > unit.Health
    else
        local totalHealth = unit.Health + unit.ShieldAll
        return damage > totalHealth
    end
end

----------------------------------------------------------------------------------------------

local HitChanceList = { "Collision", "OutOfRange", "VeryLow", "Low", "Medium", "High", "VeryHigh", "Dashing", "Immobile" }

Menu.RegisterMenu("SIrelia", "Shulepin Irelia", function()
    Menu.Checkbox("ScriptEnabled", "Script Enabled", true)

    Menu.Separator("Spell Settings", true)

    Menu.NewTree("Q", "[Q] Bladesurge", function()
        Menu.NewTree("ComboQ", "Combo Options", function()
            Menu.Checkbox("ComboUseQ", "Enabled", true)
        end)
        Menu.NewTree("LastHitQ", "Last Hit Options", function()
            Menu.Checkbox("LastHitUseQ", "Enabled", true)
            Menu.Slider("LastHitManaQ", "Min. Mana [%]", 0, 0, 100, 1)
        end)
        Menu.NewTree("WaveClearQ", "Wave Clear Options", function()
            Menu.Checkbox("WaveClearUseQ", "Enabled", true)
            Menu.Slider("WaveClearManaQ", "Min. Mana [%]", 0, 0, 100, 1)
        end)
        Menu.NewTree("JungleClearQ", "Jungle Clear Options", function()
            Menu.Checkbox("JungleClearUseQ", "Enabled", true)
            Menu.Slider("JungleClearManaQ", "Min. Mana [%]", 0, 0, 100, 1)
        end)
        Menu.NewTree("DrawingsQ", "Drawings", function()
            Menu.Checkbox("DrawQ", "Draw Range", true)
            Menu.ColorPicker("DrawColorQ", "Color", ARGB(255, 255, 150, 255))
        end)
    end)

    Menu.NewTree("W", "[W] Defiant Dance", function()
        Menu.NewTree("ComboW", "Combo Options", function()
            Menu.Checkbox("ComboUseW", "Enabled", true)
        end)
        Menu.NewTree("DrawingsW", "Drawings", function()
            Menu.Checkbox("DrawW", "Draw Range", false)
            Menu.ColorPicker("DrawColorW", "Color", ARGB(255, 255, 0, 255))
        end)
    end)

    Menu.NewTree("E", "[E] Flawless Duet", function()
        Menu.NewTree("ComboE", "Combo Options", function()
            Menu.Checkbox("ComboUseE", "Enabled", true)
        end)
        Menu.NewTree("DrawingsE", "Drawings", function()
            Menu.Checkbox("DrawE", "Draw Range", true)
            Menu.ColorPicker("DrawColorE", "Color", ARGB(255, 255, 0, 255))
        end)
    end)

    Menu.NewTree("R", "[R] Vanguard's Edge", function()
        Menu.NewTree("ComboR", "Combo Options", function()
            Menu.Checkbox("ComboUseR", "Enabled", true)
            Menu.Slider("ComboMinHitR", "Min. Heroes Hits", 2, 1, 5, 1)
        end)
        Menu.NewTree("PredictionR", "Prediction Options", function()
            Menu.Slider("PredictionRRange", "Max. Range", R.Range, 0, R.Range, 1)
        end)
        Menu.NewTree("DrawingsR", "Drawings", function()
            Menu.Checkbox("DrawR", "Draw Range", true)
            Menu.ColorPicker("DrawColorR", "Color", ARGB(255, 255, 0, 255))
        end)
    end)
    Menu.Separator("Author: Shulepin")
end)

----------------------------------------------------------------------------------------------

---@type fun():void
local Combo = function()
    if IsReady(R, function()
        local menuValue = GetMenuValue("ComboUseR")
        return menuValue
    end) then
        local points = {}
        local range = GetMenuValue("PredictionRRange")
        local heroCount = GetMenuValue("ComboMinHitR")
        local closestHero, closestHeroDist = nil, math_huge
        local heroes = ObjectManager.Get("enemy", "heroes")
        for i, hero in pairs(heroes) do
            local hero = hero.AsAI
            if hero and IsValidTarget(hero, R.Range) then
                local dist = Player.Position:Distance(hero.Position)
                local predResult = Prediction.GetPredictedPosition(hero, R, Player.Position)
                if predResult and predResult.CastPosition and predResult.HitChance > 0 then
                    points[#points + 1] = predResult.CastPosition
                end
                if dist < closestHeroDist then
                    closestHeroDist = dist
                    closestHero = hero
                end
            end
        end

        if closestHero and Player.Position:Distance(closestHero.Position) < range then
            local bestPos, hitCount = Geometry.BestCoveringRectangle(points, Player.Position, R.Radius)
            if bestPos and hitCount >= heroCount then
                return CastSpell(_R, bestPos)
            end
        end
    end

    local eTarget = TS:GetTarget(E.Range)
    if eTarget and IsReady(E, function()
        local menuValue = GetMenuValue("ComboUseE")
        local canCast = IsValidTarget(eTarget, E.Range)
        return menuValue and canCast
    end) then
        local eName = E:GetName()
        local mark = eTarget:GetBuff("ireliamark")
        if not mark or (mark and not IsReady(Q)) then
            if eName == "IreliaE" then
                if eTarget then
                    local predResult = Prediction.GetPredictedPosition(eTarget, E, Player.Position)
                    if predResult and predResult.HitChance >= 0.25 then
                        local dist = Player.Position:Distance(eTarget.Position)
                        local castPosRange = dist > E.Range / 1.5 and -E.Range or 100
                        local castPosition = Player.Position:Extended(predResult.CastPosition, castPosRange)
                        BladePosition = castPosition
                        return CastSpell(_E, castPosition)
                    end
                end
            elseif eName == "IreliaE2" and BladePosition then
                local predResult = Prediction.GetPredictedPosition(eTarget, E, Player.Position)
                if predResult and predResult.HitChance >= 0.25 then 
                    local castPosition = BladePosition:Extended(predResult.CastPosition, BladePosition:Distance(predResult.CastPosition) + 200)
                    if CastSpell(_E, castPosition) then
                        BladePosition = nil 
                        return true
                    end
                end
            end
        end
    end

    local wTarget = TS:GetTarget(W.Range)
    if wTarget and IsReady(W, function()
        local menuValue = GetMenuValue("ComboUseW")
        local canCast = IsValidTarget(wTarget, W.Range)
        return menuValue and canCast
    end) then
        local predResult = Prediction.GetPredictedPosition(wTarget, W, Player.Position)
        if predResult and predResult.HitChance >= 0.25 then
            if CastSpell(_W, predResult.CastPosition) then
                return Input.Release(_W, predResult.CastPosition)
            end
        end
    end

    if IsReady(Q, function()
        local menuValue = GetMenuValue("ComboUseQ")
        return menuValue
    end) then
        local maxPassiveStacks = Player:GetBuff("ireliapassivestacksmax")
        local passiveStacks = Player:GetBuff("ireliapassivestacks")
        local mousePos = Renderer.GetMousePos()
        local origDist = Player.Position:Distance(mousePos)
        local closestDist = Player.Position:Distance(mousePos)
        local closestObj = nil
        local closestObjDist = nil
        local qTarget = TS:GetTarget(1500)
        local heroes = ObjectManager.Get("enemy", "heroes")
        for k, hero in pairs(heroes) do
            local hero = hero.AsAI
            if hero and IsValidTarget(hero) then
                local mark = hero:GetBuff("ireliamark")
                if mark and (maxPassiveStacks or not closestObjDist) or CanKillWithQ(hero) then
                    closestObj = hero
                end
            end
        end
        local minions = ObjectManager.Get("enemy", "minions")
        for i, minion in pairs(minions) do
            local minion = minion.AsAI
            if minion and IsValidTarget(minion, Q.Range) then
                local minionDist = minion.Position:Distance(mousePos)
                if not maxPassiveStacks or (qTarget and qTarget.Position:Distance(Player.Position) > Orbwalker.GetTrueAutoAttackRange(Player) + 100) then
                    if CanKillWithQ(minion) or minion:GetBuff("ireliamark") then
                        if minionDist < closestDist then
                            closestDist = minionDist
                            closestObjDist = minion
                            closestObj = minion
                        end
                    end
                end
            end
        end
        if closestObj then
            return CastSpell(_Q, closestObj)
        end
    end
end

---@type fun():void
local LastHit = function()
    if IsReady(Q, function()
        local menuValue = GetMenuValue("LastHitUseQ")
        local manaMenuValue = GetMenuValue("LastHitManaQ")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        return menuValue and isEnoughMana
    end) then
        local minions = ObjectManager.Get("all", "minions")
        for i, minion in pairs(minions) do
            local minion = minion.AsAI
            if minion and (minion.IsEnemy or minion.IsMonster) and IsValidTarget(minion, Q.Range) then
                if CanKillWithQ(minion) or minion:GetBuff("ireliamark") then
                    return CastSpell(_Q, minion)
                end
            end
        end
    end
end

---@type fun():void
local AutoMode = function()
    if IsReady(Q, function()
        local menuValue = GetMenuValue("ComboUseQ")
        return menuValue
    end) then
        local heroes = ObjectManager.Get("enemy", "heroes")
        for k, hero in pairs(heroes) do
            local hero = hero.AsAI
            if hero and IsValidTarget(hero, Q.Range) and CanKillWithQ(hero) then
                return CastSpell(_Q, hero)
            end
        end
    end
end

----------------------------------------------------------------------------------------------

---@type fun():void
local OnTick = function()
    if not GetMenuValue("ScriptEnabled") then return end

    if GameIsAvailable() then
        AutoMode()

        local activeMode = Orbwalker.GetMode()
        if activeMode == "Combo" then
            Combo()
        elseif activeMode == "Lasthit" then
            LastHit()
        elseif activeMode == "Waveclear" then
            if LastHit() then
                return
            end
        end
    end

    local tick = os_clock()
    if TickCount < tick then
        TickCount = tick + 0.5

        ItemLoop()
    end
end

---@type fun():void
local OnDraw = function()
    if not GetMenuValue("ScriptEnabled") then return end

    --[[
    local minions = ObjectManager.Get("enemy", "minions")
    for i, minion in pairs(minions) do
        local minion = minion.AsAI
        if minion and minion.IsOnScreen and IsValidTarget(minion, 3000) then
            local damage, ad, ap = GetDamage(Q, minion)
            local pos = Renderer.WorldToScreen(minion.Position) + Vector(60, -20)
            Renderer.DrawText(pos, Vector(100, 100), "TOTAL: " .. math.floor(damage), ARGB(255, 255, 255, 255))
            Renderer.DrawText(pos - Vector(0, 40), Vector(100, 100), "AD: " .. math.floor(ad), ARGB(255, 255, 255, 255))
            Renderer.DrawText(pos - Vector(0, 60), Vector(100, 100), "AP: " .. math.floor(ap), ARGB(255, 255, 255, 255))
        end
    end]]

    local myHeroPos = Player.Position
    if Player.IsVisible and Player.IsOnScreen and not Player.IsDead then
        for i = 1, #DrawSpellTable do
            local spell = DrawSpellTable[i]
            if spell then
                local menuValue = GetMenuValue("Draw" .. spell.SlotString)
                if menuValue then
                    local colorValue = GetMenuValue("DrawColor" .. spell.SlotString)
                    if colorValue then
                        Renderer.DrawCircle3D(myHeroPos, spell.Range, 30, 2, colorValue)
                    end
                end
            end
        end
    end
end

---@type fun(obj: GameObject):void
local OnCreateObject = function(obj)
    if obj and obj.Name == "Blade" then
        local objAI = obj.AsAI
        if obj.TeamId == Player.TeamId then
            BladePosition = obj.Position
        end
    end
end

---@type fun(unit: GameObject, buff: BuffInst):void
local OnBuffLost = function(unit, buff)
    if unit.IsMe then
        if buff.Name == "sheen" or buff.Name == "3078trinityforce" then
            LastSheenT = os_clock() + 2
        end
    end
end

----------------------------------------------------------------------------------------------

---@type fun():void
function OnLoad()
    EventManager.RegisterCallback(Events.OnTick, OnTick)
    EventManager.RegisterCallback(Events.OnDraw, OnDraw)
    EventManager.RegisterCallback(Events.OnCreateObject, OnCreateObject)
    EventManager.RegisterCallback(Events.OnBuffLost, OnBuffLost)

    return true
end

----------------------------------------------------------------------------------------------

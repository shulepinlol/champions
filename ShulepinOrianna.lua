if Player.CharName ~= "Orianna" then return end

----------------------------------------------------------------------------------------------

local SCRIPT_NAME, VERSION, LAST_UPDATE = "ShulepinOrianna", "1.0.2", "14/09/2021"
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

local Q = Spell.Skillshot({
    ["Slot"] = _Q,
    ["SlotString"] = "Q",
    ["Range"] = 825,
    ["Speed"] = 1200,
    ["Delay"] = 0,
    ["Radius"] = 170,
    ["Type"] = "Circular"
})

local W = Spell.Active({
    ["Slot"] = _W,
    ["SlotString"] = "W",
    ["Range"] = 250,
})

local E = Spell.Targeted({
    ["Slot"] = _E,
    ["SlotString"] = "E",
    ["Range"] = 1095,
})

local R = Spell.Active({
    ["Slot"] = _R,
    ["SlotString"] = "R",
    ["Range"] = 400,
    ["Delay"] = 0.5,
})

----------------------------------------------------------------------------------------------

local LastCastT = {
    [_Q] = 0,
    [_W] = 0,
    [_E] = 0,
    [_R] = 0,
}

local BallObject = Player
local DrawSpellTable = { Q, E }
local TickCount = 0

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
    if LastCastT[slot] + 0.1 < tick then
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

---@type fun(spell: table, target: GameObject):number
local GetDamage = function(spell, target)
    local tick = os_clock()
    local slot = spell.Slot
    local myLevel = Player.Level
    local level = Player.AsHero:GetSpell(slot).Level
    local totalAP = Player.TotalAP
    if slot == _Q then
        local rawDamage = 30 + 30 * level + 0.5 * totalAP
        return DamageLib.CalculateMagicalDamage(Player, target, rawDamage)
    end
    if slot == _W then
        local rawDamage = 15 + 45 * level + 0.7 * totalAP
        return DamageLib.CalculateMagicalDamage(Player, target, rawDamage)
    end
    if slot == _E then
        local rawDamage = 30 + 30 * level + 0.3 * totalAP 
        return DamageLib.CalculateMagicalDamage(Player, target, rawDamage)
    end
    return 0
end

local GetEnemiesInRange = function(range, from)
    local result = {}
    local heroes = ObjectManager.Get("enemy", "heroes")
    for i, hero in pairs(heroes) do
        local hero = hero.AsAI
        if hero and IsValidTarget(hero, range, from) then
            result[#result + 1] = hero
        end
    end
    return result
end

local GetEnemyMinionsInRange = function(range, from, killable)
    local result = {}
    local minions = ObjectManager.Get("enemy", "minions")
    for i, minion in pairs(minions) do
        local minion = minion.AsAI
        if minion and IsValidTarget(minion, range, from) then
            if killable then
                local damage = GetDamage(W, minion)
                if damage > minion.Health then
                    result[#result + 1] = minion
                end
            else
                result[#result + 1] = minion
            end
        end
    end
    return result
end

local GetEnemiesOnLine = function(range)
    local result = {}
    local heroes = ObjectManager.Get("enemy", "heroes")
    for i, hero in pairs(heroes) do
        local hero = hero.AsAI
        if hero and IsValidTarget(hero, range) and IsValidObject(BallObject) then
            local isOnSegment, pointSegment, pointLine = hero.Position:ProjectOn(BallObject.Position, Player.Position)
            if isOnSegment and pointSegment:Distance(hero.Position) < 90 + hero.BoundingRadius / 2 then
                result[#result + 1] = hero
            end
        end
    end
    return result
end

local GetEnemyMinionsOnLine = function(range, killable)
    local result = {}
    local minions = ObjectManager.Get("enemy", "minions")
    for i, minion in pairs(minions) do
        local minion = minion.AsAI
        if minion and IsValidTarget(minion, range) and IsValidObject(BallObject) then
            local isOnSegment, pointSegment, pointLine = minion.Position:ProjectOn(BallObject.Position, Player.Position)
            if isOnSegment and pointSegment:Distance(minion.Position) < 90 + minion.BoundingRadius / 2 then
                if killable then
                    local damage = GetDamage(E, minion)
                    if damage > minion.Health then
                        result[#result + 1] = minion
                    end
                else
                    result[#result + 1] = minion
                end
            end
        end
    end
    return result
end

----------------------------------------------------------------------------------------------

local HitChanceList = { "Collision", "OutOfRange", "VeryLow", "Low", "Medium", "High", "VeryHigh", "Dashing", "Immobile" }

Menu.RegisterMenu("SOrianna", "Shulepin Orianna", function()
    Menu.Checkbox("ScriptEnabled", "Script Enabled", true)

    Menu.Separator()

    Menu.ColoredText("Spell Settings", ARGB(255, 255, 255, 255), true)

    Menu.Separator()

    Menu.NewTree("Q", "[Q] Command: Attack", function()
        Menu.NewTree("ComboQ", "Combo Options", function()
            Menu.Checkbox("ComboUseQ", "Enabled", true)
        end)
        Menu.NewTree("HarassQ", "Harass Options", function()
            Menu.Checkbox("HarassUseQ", "Enabled", true)
            Menu.Slider("HarassManaQ", "Min. Mana [%]", 35, 0, 100, 1)
            AddWhiteListMenu("White List", "HarassQ")
        end)
        Menu.NewTree("LastHitQ", "Last Hit Options", function()
            Menu.Checkbox("LastHitUseQ", "Enabled", true)
            Menu.Slider("LastHitManaQ", "Min. Mana [%]", 35, 0, 100, 1)
            Menu.Slider("LastHitMinHitQ", "Min. Minion Hits", 2, 0, 6, 1)
        end)
        Menu.NewTree("WaveClearQ", "Wave Clear Options", function()
            Menu.Checkbox("WaveClearUseQ", "Enabled", true)
            Menu.Slider("WaveClearManaQ", "Min. Mana [%]", 35, 0, 100, 1)
            Menu.Slider("WaveClearMinHitQ", "Min. Minion Hits", 3, 0, 6, 1)
        end)
        Menu.NewTree("JungleClearQ", "Jungle Clear Options", function()
            Menu.Checkbox("JungleClearUseQ", "Enabled", true)
            Menu.Slider("JungleClearManaQ", "Min. Mana [%]", 35, 0, 100, 1)
        end)
        Menu.NewTree("DrawingsQ", "Drawings", function()
            Menu.Checkbox("DrawQ", "Draw Range", true)
            Menu.ColorPicker("DrawColorQ", "Color", ARGB(255, 255, 255, 255))
        end)
    end)

    Menu.NewTree("W", "[W] Command: Dissonance", function()
        Menu.NewTree("ComboW", "Combo Options", function()
            Menu.Checkbox("ComboUseW", "Enabled", true)
        end)
        Menu.NewTree("HarassW", "Harass Options", function()
            Menu.Checkbox("HarassUseW", "Enabled", true)
            Menu.Slider("HarassManaW", "Min. Mana [%]", 35, 0, 100, 1)
            AddWhiteListMenu("White List", "HarassW")
        end)
        Menu.NewTree("LastHitW", "Last Hit Options", function()
            Menu.Checkbox("LastHitUseW", "Enabled", true)
            Menu.Slider("LastHitManaW", "Min. Mana [%]", 35, 0, 100, 1)
            Menu.Slider("LastHitMinHitW", "Min. Minion Hits", 2, 0, 6, 1)
        end)
        Menu.NewTree("WaveClearW", "Wave Clear Options", function()
            Menu.Checkbox("WaveClearUseW", "Enabled", true)
            Menu.Slider("WaveClearManaW", "Min. Mana [%]", 35, 0, 100, 1)
            Menu.Slider("WaveClearMinHitW", "Min. Minion Hits", 3, 0, 6, 1)
        end)
        Menu.NewTree("JungleClearW", "Jungle Clear Options", function()
            Menu.Checkbox("JungleClearUseW", "Enabled", true)
            Menu.Slider("JungleClearManaW", "Min. Mana [%]", 35, 0, 100, 1)
        end)
        Menu.NewTree("DrawingsW", "Drawings", function()
            Menu.Checkbox("DrawW", "Draw Range", true)
            Menu.ColorPicker("DrawColorW", "Color", ARGB(255, 255, 255, 255))
        end)
    end)

    Menu.NewTree("E", "[E] Command: Protect", function()
        Menu.NewTree("ComboE", "Combo Options", function()
            Menu.Checkbox("ComboUseE", "Enabled", true)
        end)
        Menu.NewTree("LastHitE", "Last Hit Options", function()
            Menu.Checkbox("LastHitUseE", "Enabled", true)
            Menu.Slider("LastHitManaE", "Min. Mana [%]", 35, 0, 100, 1)
            Menu.Slider("LastHitMinHitE", "Min. Minion Hits", 2, 0, 6, 1)
        end)
        Menu.NewTree("WaveClearE", "Wave Clear Options", function()
            Menu.Checkbox("WaveClearUseE", "Enabled", true)
            Menu.Slider("WaveClearManaE", "Min. Mana [%]", 35, 0, 100, 1)
            Menu.Slider("WaveClearMinHitE", "Min. Minion Hits", 3, 0, 6, 1)
        end)
        Menu.NewTree("JungleClearE", "Jungle Clear Options", function()
            Menu.Checkbox("JungleClearUseE", "Enabled", true)
            Menu.Slider("JungleClearManaE", "Min. Mana [%]", 35, 0, 100, 1)
        end)
        Menu.NewTree("DrawingsE", "Drawings", function()
            Menu.Checkbox("DrawE", "Draw Range", true)
            Menu.ColorPicker("DrawColorE", "Color", ARGB(255, 255, 255, 255))
        end)
    end)

    Menu.NewTree("R", "[R] Command: Shockwave", function()
        Menu.NewTree("ComboR", "Combo Options", function()
            Menu.Checkbox("ComboUseR", "Enabled", true)
            Menu.Slider("ComboMinHitR", "Min. Heroes Hits", 2, 0, 5, 1)
        end)
        Menu.NewTree("AutoR", "Auto Options", function()
            Menu.Checkbox("AutoUseR", "Enabled", true)
            Menu.Slider("AutoMinHitR", "Min. Heroes Hits", 3, 0, 5, 1)
        end)
        Menu.NewTree("MiscR", "Miscellaneous", function()
            Menu.Checkbox("BlockR", "Block R If No Hits", false)
        end)
        Menu.NewTree("DrawingsR", "Drawings", function()
            Menu.Checkbox("DrawR", "Draw Range", true)
            Menu.ColorPicker("DrawColorR", "Color", ARGB(255, 255, 255, 255))
        end)
    end)

    Menu.Separator()

    Menu.ColoredText("Script Information", ARGB(255, 255, 255, 255), true)

    Menu.Separator()

    Menu.ColoredText("Version: " .. VERSION, ARGB(255, 255, 255, 255))
    Menu.ColoredText("Last Update: " .. LAST_UPDATE, ARGB(255, 255, 255, 255))

    Menu.Separator()
end)

Menu.RegisterPermashow("SOrianna_PermaShow", "Shulepin Orianna: Auto Harass", function()
    Menu.Keybind("AutoHarass", "Enabled", string.byte("G"), true, false)
    Menu.Checkbox("AutoHarassUseQ", "Use Q", true)
    Menu.Checkbox("AutoHarassUseW", "Use W", true)
    Menu.Slider("AutoHarassMana", "Mana", 35, 0, 100, 1)
end, function() 
    return true
end)

----------------------------------------------------------------------------------------------

---@type fun():void
local Combo = function()
    local qTarget = TS:GetTarget(1100)
    if qTarget and IsReady(Q, function()
        local menuValue = GetMenuValue("ComboUseQ")
        local canCast = IsValidTarget(qTarget, Q.Range)
        return menuValue and canCast
    end) then
        if IsValidObject(BallObject) then
            if IsReady(R) then
                local points = {}
                local heroes = ObjectManager.Get("enemy", "heroes")
                for i, hero in pairs(heroes) do
                    local hero = hero.AsAI
                    if hero and IsValidTarget(hero, 1100) then
                        local predPos = hero:FastPrediction(R.Delay)
                        local dist = predPos:Distance(Player.Position)
                        if dist < Q.Range then
                            points[#points + 1] = predPos
                        end
                    end
                end
                local bestPos, hitCount = Geometry.BestCoveringCircle(points, 375)
                if bestPos and hitCount >= 3 then
                    return CastSpell(_Q, bestPos)
                end
            end
            if IsReady(E) then
                local ballDist = BallObject.Position:Distance(qTarget.Position)
                local heroDist = Player.Position:Distance(qTarget.Position)
                if ballDist > heroDist then
                    return E:Cast(Player)
                end
            end
            local predResult = Prediction.GetPredictedPosition(qTarget, Q, BallObject.Position)
            if predResult and predResult.HitChance >= 0.25 then
                return Q:Cast(predResult.CastPosition)
            end
        end
    end

    if IsReady(W, function()
        local menuValue = GetMenuValue("ComboUseW")
        local count = IsValidObject(BallObject) and #GetEnemiesInRange(W.Range, BallObject.Position) or 0
        return menuValue and count > 0
    end) then
        return W:Cast()
    end

    if qTarget and IsReady(E, function()
        local menuValue = GetMenuValue("ComboUseE")
        local isValid = IsValidObject(BallObject)
        local range = isValid and BallObject.Position:Distance(Player.Position) or 1100
        local count = #GetEnemiesOnLine(range)
        local canCast = IsValidTarget(qTarget, range)
        return menuValue and canCast and count > 0 and not IsReady(R)
    end) then
        return E:Cast(Player)
    end

    if IsReady(R, function()
        local menuValue = GetMenuValue("ComboUseR")
        return menuValue
    end) then
        local count = 0
        local minHit = GetMenuValue("ComboMinHitR")
        local heroes = ObjectManager.Get("enemy", "heroes")
        for i, hero in pairs(heroes) do
            local hero = hero.AsAI
            if hero and IsValidObject(BallObject) and IsValidTarget(hero, R.Range, BallObject.Position) then
                local predResult = hero:FastPrediction(R.Delay)
                if predResult:Distance(BallObject.Position) <= R.Range - (hero.BoundingRadius / 2) - 10 then
                    count = count + 1
                end
            end
        end
        if count >= minHit then
            return R:Cast()
        end
    end
end

---@type fun():void
local Harass = function()
    local qTarget = TS:GetTarget(Q.Range)
    if qTarget and IsReady(Q, function()
        local menuValue = GetMenuValue("HarassUseQ")
        local manaMenuValue = GetMenuValue("HarassManaQ")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        local whiteListValue = GetWhiteListValue("Q", "Harass", qTarget.AsAI.CharName)
        local canCast = IsValidTarget(qTarget, Q.Range)
        local isValid = IsValidObject(BallObject)
        return menuValue and isEnoughMana and whiteListValue and canCast and isValid
    end) then
        local predResult = Prediction.GetPredictedPosition(qTarget, Q, BallObject.Position)
        if predResult and predResult.HitChance >= 0.25 then
            return Q:Cast(predResult.CastPosition)
        end
    end

    if IsReady(W, function()
        local menuValue = GetMenuValue("HarassUseW")
        local manaMenuValue = GetMenuValue("HarassManaQ")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        local count = IsValidObject(BallObject) and #GetEnemiesInRange(W.Range, BallObject.Position) or 0
        return menuValue and isEnoughMana and count > 0
    end) then
        return W:Cast()
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
        local points = {}
        local siegeMinion = nil
        local minionCount = GetMenuValue("LastHitMinHitQ")
        local minions = ObjectManager.Get("enemy", "minions")
        for i, minion in pairs(minions) do
            local minion = minion.AsAI
            if minion and minion.IsTargetable then
                local predPos = minion:FastPrediction(Q.Delay)
                local dist = predPos:Distance(Player.Position)
                local damage = GetDamage(Q, minion)
                local hpPred = Q:GetHealthPred(minion)
                if dist < Q.Range and damage > hpPred then
                    points[#points + 1] = predPos
                    if minion.AsMinion.IsSiegeMinion then
                        siegeMinion = minion
                    end
                end
            end
        end

        if siegeMinion then
            return CastSpell(_Q, siegeMinion:FastPrediction(Q.Delay))
        end

        local bestPos, hitCount = Geometry.BestCoveringCircle(points, Q.Radius)
        if bestPos and hitCount >= minionCount then
            return CastSpell(_Q, bestPos)
        end
    end

    if IsReady(W, function()
        local menuValue = GetMenuValue("LastHitUseW")
        local manaMenuValue = GetMenuValue("LastHitManaW")
        local minionCount = GetMenuValue("LastHitMinHitW")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        local count = IsValidObject(BallObject) and #GetEnemyMinionsInRange(W.Range, BallObject.Position, true) or 0
        return menuValue and isEnoughMana and count >= minionCount
    end) then
        return W:Cast()
    end

    if IsReady(E, function()
        local menuValue = GetMenuValue("LastHitUseE")
        local manaMenuValue = GetMenuValue("LastHitManaE")
        local minionCount = GetMenuValue("LastHitMinHitE")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        local count = IsValidObject(BallObject) and #GetEnemyMinionsOnLine(E.Range, true) or 0
        return menuValue and isEnoughMana and count >= minionCount
    end) then
        return E:Cast(Player)
    end
end

---@type fun():void
local WaveClear = function()
    if IsReady(Q, function()
        local menuValue = GetMenuValue("WaveClearUseQ")
        local manaMenuValue = GetMenuValue("WaveClearManaQ")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        return menuValue and isEnoughMana
    end) then
        local points = {}
        local minionCount = GetMenuValue("WaveClearMinHitQ")
        local minions = ObjectManager.Get("enemy", "minions")
        for i, minion in pairs(minions) do
            local minion = minion.AsAI
            if minion and minion.IsTargetable then
                local predPos = minion:FastPrediction(Q.Delay)
                local dist = predPos:Distance(Player.Position)
                if dist < Q.Range then
                    points[#points + 1] = predPos
                end
            end
        end

        local bestPos, hitCount = Geometry.BestCoveringCircle(points, Q.Radius)
        if bestPos and hitCount >= minionCount then
            return Q:Cast(bestPos)
        end
    end

    if IsReady(W, function()
        local menuValue = GetMenuValue("WaveClearUseW")
        local manaMenuValue = GetMenuValue("WaveClearManaW")
        local minionCount = GetMenuValue("WaveClearMinHitW")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        local count = IsValidObject(BallObject) and #GetEnemyMinionsInRange(W.Range, BallObject.Position) or 0
        return menuValue and isEnoughMana and count >= minionCount
    end) then
        return W:Cast()
    end

    if IsReady(E, function()
        local menuValue = GetMenuValue("WaveClearUseE")
        local manaMenuValue = GetMenuValue("WaveClearManaE")
        local minionCount = GetMenuValue("WaveClearMinHitE")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        local count = IsValidObject(BallObject) and #GetEnemyMinionsOnLine(E.Range) or 0
        return menuValue and isEnoughMana and count >= minionCount
    end) then
        return E:Cast(Player)
    end
end

local JungleClear = function()
    local myHeroPos = Player.Position
    local mousePos = Renderer.GetMousePos()
    local bestMinion = nil
    local bestMinionHealth = 0
    local minions = ObjectManager.Get("neutral", "minions")
    for i, minion in pairs(minions) do
        local minion = minion.AsAI
        if minion and minion.IsTargetable and minion.MaxHealth > 5 then
            if minion:Distance(myHeroPos) < Q.Range then
                if minion.MaxHealth > bestMinionHealth then
                    bestMinion = minion
                    bestMinionHealth = minion.MaxHealth
                end
            end
        end
    end

    if not bestMinion then return end

    if IsReady(Q, function()
        local menuValue = GetMenuValue("JungleClearUseQ")
        local manaMenuValue = GetMenuValue("JungleClearManaQ")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        return menuValue and isEnoughMana
    end) then
        local predPos = bestMinion:FastPrediction(Q.Delay)
        if predPos then
            return Q:Cast(predPos)
        end
    end

    if IsReady(W, function()
        local menuValue = GetMenuValue("JungleClearUseW")
        local manaMenuValue = GetMenuValue("JungleClearManaW")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        local dist = IsValidObject(BallObject) and BallObject.Position:Distance(bestMinion.Position) or 0
        return menuValue and isEnoughMana and dist <= W.Range
    end) then
        return W:Cast()
    end

    if IsReady(E, function()
        local menuValue = GetMenuValue("JungleClearUseE")
        local manaMenuValue = GetMenuValue("JungleClearManaE")
        local minionCount = GetMenuValue("JungleClearMinHitE")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        return menuValue and isEnoughMana and (not IsReady(Q) and not IsReady(W))
    end) then
        return E:Cast(Player)
    end
end

local AutoMode = function()
    if GetMenuValue("AutoHarass") then
        if not IsEnoughMana(GetMenuValue("AutoHarassMana")) then return end

        local qTarget = TS:GetTarget(1100)
        if qTarget and IsReady(Q, function()
            local menuValue = GetMenuValue("AutoHarassUseQ")
            local isValid = IsValidObject(BallObject)
            local canCast = IsValidTarget(qTarget, Q.Range)
            return menuValue and canCast and isValid
        end) then
            local predResult = Prediction.GetPredictedPosition(qTarget, Q, BallObject.Position)
            if predResult and predResult.HitChance >= 0.25 then
                return Q:Cast(predResult.CastPosition)
            end
        end

        if IsReady(W, function()
            local menuValue = GetMenuValue("AutoHarassUseW")
            local count = IsValidObject(BallObject) and #GetEnemiesInRange(W.Range, BallObject.Position) or 0
            return menuValue and count > 0
        end) then
            return W:Cast()
        end
    end

    if IsReady(R, function()
        local menuValue = GetMenuValue("AutoUseR")
        return menuValue
    end) then
        local count = 0
        local minHit = GetMenuValue("AutoMinHitR")
        local heroes = ObjectManager.Get("enemy", "heroes")
        for i, hero in pairs(heroes) do
            local hero = hero.AsAI
            if hero and IsValidObject(BallObject) and IsValidTarget(hero, R.Range, BallObject.Position) then
                local predResult = hero:FastPrediction(R.Delay)
                if predResult:Distance(BallObject.Position) <= R.Range - (hero.BoundingRadius / 2) - 10 then
                    count = count + 1
                end
            end
        end
        if count >= minHit then
            return R:Cast()
        end
    end
end

----------------------------------------------------------------------------------------------

---@type fun():void
local OnTick = function()
    if not GetMenuValue("ScriptEnabled") then return end

    local tick = os_clock()
    if TickCount < tick then
        TickCount = tick + 0.1

        if not IsValidObject(BallObject) then
            BallObject = Player
        end

        if GameIsAvailable() then
            AutoMode()

            local activeMode = Orbwalker.GetMode()
            if activeMode == "Combo" then
                return Combo()
            elseif activeMode == "Harass" then
                return Harass()
            elseif activeMode == "Lasthit" then
                return LastHit()
            elseif activeMode == "Waveclear" then
                if WaveClear() or LastHit() or JungleClear() then
                    return
                end
            end
        end
    end
end

---@type fun():void
local OnDraw = function()
    if not GetMenuValue("ScriptEnabled") then return end

    if BallObject and BallObject.IsValid and BallObject.Position then
        Renderer.DrawCircle3D(Vector(BallObject.Position.x, Player.Position.y, BallObject.Position.z), 75, 30, 5, ARGB(255, 255, 255, 255))
        Renderer.DrawCircle3D(Vector(BallObject.Position.x, Player.Position.y, BallObject.Position.z), R.Range, 30, 5, ARGB(120, 255, 255, 255))
    end

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
    local name = obj.Name:lower()
    if name == "orianaizuna" then
        BallObject = obj
    elseif name == "orianaredact" then
        BallObject = obj
    elseif name:find("z_ball_glow_green") then
        BallObject = obj
    elseif name:find("e_protectshield") then
        BallObject = obj
    end
end

local OnBuffGain = function(unit, buff)
    if unit.IsMe then
        if buff.Name == "orianaghostself" then
            BallObject = Player
        end
    end
end

local OnCastSpell = function(args)
    if not GetMenuValue("ScriptEnabled") then return end

    if GetMenuValue("BlockR") then
        if args.Slot == SpellSlots.R then
            local count = 0
            local heroes = ObjectManager.Get("enemy", "heroes")
            for k, hero in pairs(heroes) do
                if IsValidObject(BallObject) and IsValidTarget(hero, R.Range, BallObject) then
                    count = count + 1
                end
            end
            if count == 0 then
                args.Process = false
            end
        end
    end
end

----------------------------------------------------------------------------------------------

---@type fun():void
function OnLoad()
    EventManager.RegisterCallback(Events.OnTick, OnTick)
    EventManager.RegisterCallback(Events.OnDraw, OnDraw)
    EventManager.RegisterCallback(Events.OnCreateObject, OnCreateObject)
    EventManager.RegisterCallback(Events.OnBuffGain, OnBuffGain)
    EventManager.RegisterCallback(Events.OnCastSpell, OnCastSpell)

    return true
end

----------------------------------------------------------------------------------------------
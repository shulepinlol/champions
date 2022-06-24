if Player.CharName ~= "Cassiopeia" then return end

----------------------------------------------------------------------------------------------

local SCRIPT_NAME, VERSION, LAST_UPDATE = "ShulepinCassiopeia", "1.0.4", "19/06/2021"
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

----------------------------------------------------------------------------------------------

local Q = Spell.Skillshot({
    ["Slot"] = _Q,
    ["SlotString"] = "Q",
    ["Speed"] = math_huge,
    ["Range"] = 850,
    ["Delay"] = 0.75,
    ["Radius"] = 150,
    ["Type"] = "Circular",
})

local W = Spell.Skillshot({
    ["Slot"] = _W,
    ["SlotString"] = "W",
    ["Speed"] = 2500,
    ["Range"] = 920,
    ["Delay"] = 0.75,
    ["Radius"] = 160,
    ["Angle"] = 100,
    ["Type"] = "Linear",
})

local E = Spell.Targeted({
    ["Slot"] = _E,
    ["SlotString"] = "E",
    ["Speed"] = 1600,
    ["Range"] = 700,
    ["Delay"] = 0.2,
})

local R = Spell.Skillshot({
    ["Slot"] = _R,
    ["SlotString"] = "R",
    ["Speed"] = math_huge,
    ["Range"] = 825,
    ["Delay"] = 0.5,
    ["Radius"] = 80,
    ["Angle"] = 80,
    ["Type"] = "Circular",
})

----------------------------------------------------------------------------------------------

local LastCastT = {
    [_Q] = 0,
    [_W] = 0,
    [_E] = 0,
    [_R] = 0,
}

local TickCount = 0
local DrawSpellTable = { Q, W, E, R }

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

---@type fun(v: Vector, angle: number):Vector
local RotateAngle = function(v, angle)
    local c, s = math_cos(angle), math_sin(angle)
    return Vector(v.x * c - v.z * s, v.y, v.z * c + v.x * s)
end

---@type fun(v1: Vector, v2: Vector, angle: number):Vector
local RotateAroundPoint = function(v1, v2, angle)
    local cos, sin = math_cos(angle), math_sin(angle)
    local x = ((v1.x - v2.x) * cos) - ((v1.z - v2.z) * sin) + v2.x
    local z = ((v1.z - v2.z) * cos) + ((v1.x - v2.x) * sin) + v2.z
    return Vector(x, v1.y, z)
end

---@type fun(v1: Vector, v2: Vector):number
local GetAngle = function(v1, v2)
    return math_deg(math_acos(v1 * v2 / (v1:Len() * v2:Len())))
end

---@type fun(p1: Vector, p2: Vector):number
local CrossProduct = function(p1, p2)
    return p2.z * p1.x - p2.x * p1.z
end

---@type fun(p1: GameObject, p2: GameObject):boolean
local IsFacing = function(p1, p2)
    local v = p1.Position - p2.Position
    local dir = p1.AsAI.Direction
    local angle = 180 - GetAngle(v, dir)
    if math_abs(angle) < 80 then
        return true
    end
    return false
end

---@type fun(position: Vector, centerCone: Vector, centerConeEnd: Vector, angle: number, range: number):boolean
local IsInTheCone = function(position, centerCone, centerConeEnd, angle, range)
    local range = range or math_huge
    local angle = angle * math_pi2
    local dir = centerConeEnd - centerCone
    local p = position - centerCone
    local p1 = RotateAngle(dir, -angle * 0.5) 
    local p2 = RotateAngle(p1, angle)
    return p:Distance(Vector(0, 0, 0)) < range and CrossProduct(p1, p) > 0 and CrossProduct(p, p2) > 0
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

---@type fun(unit: GameObject):void
local GetRealHealth = function(unit)
    local hp = unit.AsAI.Health
    local shieldAP = unit.AsAttackableUnit.ShieldAP
    return hp + shieldAP
end

---@type fun(unit: GameObject, remainingTime: number):boolean
local IsPoisoned = function(unit, remainingTime)
    local remainingTime = remainingTime + (Game.GetLatency() / 2000) or 0
    local unit = unit.IsAI and unit or unit.AsAI
    local buffs = unit.Buffs
    for buffName, buff in pairs(buffs) do
        if buff and buff.BuffType == Enums.BuffTypes.Poison and buff.DurationLeft > remainingTime then
            return true
        end
    end
    return false
end

---@type fun(spell: table, target: GameObject):number
local GetDamage = function(spell, target, travelTime)
    local slot = spell.Slot
    local level = Player.AsHero:GetSpell(slot).Level
    local totalAP = Player.TotalAP
    if slot == _E then
        local baseDamage = 48 + 4 * level + 0.1 * totalAP
        local bonusDamage = IsPoisoned(target, travelTime) and -10 + 20 * level + 0.6 * totalAP or 0
        return DamageLib.CalculateMagicalDamage(Player, target, baseDamage + bonusDamage)
    end
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

---@type fun():Vector|number
local GetBestUltimatePosition = function()
    local enemies = {}
    local count = 0 
    local bestPosition = Vector()
    local heroes = ObjectManager.Get("enemy", "heroes")
    for k, hero in pairs(heroes) do
        if IsValidTarget(hero, R.Range) and IsFacing(hero, Player) then
            local predResult = Prediction.GetPredictedPosition(hero, R, Player.Position)
            if predResult then
                enemies[#enemies + 1] = hero
                bestPosition = bestPosition + predResult.CastPosition
                count = count + 1
            end
        end
    end
    bestPosition = bestPosition / count
    if bestPosition ~= Vector() then
        local stunCount = 0
        for i = 1, #enemies do
            local hero = enemies[i]
            local endCone = Player.Position:Extended(bestPosition, R.Range)
            if hero and IsInTheCone(hero.Position, Player.Position, endCone, R.Angle) then
                local maxRangeValue = GetMenuValue("PredictionRRange")
                if Player.Position:Distance(hero.Position) <= maxRangeValue then
                    stunCount = stunCount + 1
                end
            end
        end
        return bestPosition, stunCount
    end
    return nil, 0
end

----------------------------------------------------------------------------------------------

local HitChanceList = { "Collision", "OutOfRange", "VeryLow", "Low", "Medium", "High", "VeryHigh", "Dashing", "Immobile" }

Menu.RegisterMenu("SCassiopeia", "Shulepin Cassiopeia", function()
    Menu.Checkbox("ScriptEnabled", "Script Enabled", true)

    Menu.Separator()

    Menu.ColoredText("Spell Settings", ARGB(255, 255, 255, 255), true)

    Menu.Separator()

    Menu.NewTree("Q", "[Q] Noxious Blast", function()
        Menu.NewTree("ComboQ", "Combo Options", function()
            Menu.Checkbox("ComboUseQ", "Enabled", true)
            Menu.Checkbox("ComboQPoisoned", "Only if target isn't poisoned", true)
            Menu.Dropdown("ComboHitChanceQ", "Hit Chance", 4, HitChanceList)
        end)
        Menu.NewTree("HarassQ", "Harass Options", function()
            Menu.Checkbox("HarassUseQ", "Enabled", true)
            Menu.Dropdown("HarassHitChanceQ", "Hit Chance", 4, HitChanceList)
            Menu.Slider("HarassManaQ", "Min. Mana [%]", 35, 0, 100, 1)
            AddWhiteListMenu("White List", "HarassQ")
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

    Menu.NewTree("W", "[W] Miasma", function()
        Menu.NewTree("ComboW", "Combo Options", function()
            Menu.Checkbox("ComboUseW", "Enabled", true)
            Menu.Dropdown("ComboHitChanceW", "Hit Chance", 4, HitChanceList)
        end)
        Menu.NewTree("HarassW", "Harass Options", function()
            Menu.Checkbox("HarassUseW", "Enabled", true)
            Menu.Dropdown("HarassHitChanceW", "Hit Chance", 4, HitChanceList)
            Menu.Slider("HarassManaW", "Min. Mana [%]", 35, 0, 100, 1)
            AddWhiteListMenu("White List", "HarassW")
        end)
        --Menu.NewTree("WaveClearW", "Wave Clear Options", function()
        --    Menu.Checkbox("WaveClearUseW", "Enabled", true)
        --    Menu.Slider("WaveClearManaW", "Min. Mana [%]", 35, 0, 100, 1)
        --    Menu.Slider("WaveClearMinHitW", "Min. Minion Hits", 3, 0, 6, 1)
        --end)
        Menu.NewTree("JungleClearW", "Jungle Clear Options", function()
            Menu.Checkbox("JungleClearUseW", "Enabled", true)
            Menu.Slider("JungleClearManaW", "Min. Mana [%]", 35, 0, 100, 1)
        end)
        Menu.NewTree("DrawingsW", "Drawings", function()
            Menu.Checkbox("DrawW", "Draw Range", true)
            Menu.ColorPicker("DrawColorW", "Color", ARGB(255, 255, 255, 255))
        end)
    end)

    Menu.NewTree("E", "[E] Twin Fang", function()
        Menu.NewTree("ComboE", "Combo Options", function()
            Menu.Checkbox("ComboUseE", "Enabled", true)
            Menu.Checkbox("ComboEPoisoned", "Only if target is poisoned", true)
        end)
        Menu.NewTree("HarassE", "Harass Options", function()
            Menu.Checkbox("HarassUseE", "Enabled", true)
            Menu.Checkbox("HarassEPoisoned", "Only if target is poisoned", true)
            Menu.Slider("HarassManaE", "Min. Mana [%]", 35, 0, 100, 1)
            AddWhiteListMenu("White List", "HarassE")
        end)
        Menu.NewTree("LastHitE", "Last Hit Options", function()
            Menu.Checkbox("LastHitUseE", "Enabled", true)
            Menu.Checkbox("LastHitAttackE", "Attack minion if can kill AA + E", true)
            Menu.Slider("LastHitManaE", "Min. Mana [%]", 35, 0, 100, 1)
        end)
        Menu.NewTree("WaveClearE", "Wave Clear Options", function()
            Menu.Checkbox("WaveClearUseE", "Enabled", true)
            Menu.Slider("WaveClearManaE", "Min. Mana [%]", 35, 0, 100, 1)
        end)
        Menu.NewTree("JungleClearE", "Jungle Clear Options", function()
            Menu.Checkbox("JungleClearUseE", "Enabled", true)
            Menu.Checkbox("JungleClearEPoisoned", "Only if target is poisoned", true)
            Menu.Slider("JungleClearManaE", "Min. Mana [%]", 35, 0, 100, 1)
        end)
        Menu.NewTree("DrawingsE", "Drawings", function()
            Menu.Checkbox("DrawE", "Draw Range", true)
            Menu.ColorPicker("DrawColorE", "Color", ARGB(255, 255, 255, 255))
        end)
    end)

    Menu.NewTree("R", "[R] Petrifying Gaze", function()
        Menu.NewTree("ComboR", "Combo Options", function()
            Menu.Checkbox("ComboUseR", "Enabled", true)
            Menu.Slider("ComboMinHitR", "Min. Heroes Hits", 2, 0, 5, 1)
        end)
        Menu.NewTree("AutoR", "Auto Options", function()
            Menu.Checkbox("AutoUseR", "Enabled", true)
            Menu.Slider("AutoMinHitR", "Min. Heroes Hits", 3, 0, 5, 1)
        end)
        Menu.NewTree("PredictionR", "Prediction Options", function()
            Menu.Slider("PredictionRRange", "Max. Range", 750, 0, R.Range, 1)
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

    Menu.ColoredText("Other Settings", ARGB(255, 255, 255, 255), true)

    Menu.Separator()

    Menu.NewTree("BlockAA", "Block Auto Attacks", function()
        Menu.Checkbox("BlockAAEnabled", "Block AA on Combo", true)
        Menu.Slider("BlockAALevel", "At Level", 9, 1, 18, 1)
        Menu.Separator()
        Menu.Checkbox("BlockAALastHit", "Block AA on Last Hit", true)
        Menu.Slider("BlockAALastHitLevel", "At Level", 3, 1, 18, 1)
        Menu.Separator()
        Menu.Checkbox("BlockAAWaveClear", "Block AA on Wave Clear", true)
        Menu.Slider("BlockAAWaveClearLevel", "At Level", 9, 1, 18, 1)
        Menu.Separator()
        Menu.Checkbox("BlockAAJungleClear", "Block AA on Jungle Clear", true)
        Menu.Slider("BlockAAJungleClearLevel", "At Level", 9, 1, 18, 1)
        Menu.Separator()
    end)

    Menu.Separator()

    Menu.ColoredText("Script Information", ARGB(255, 255, 255, 255), true)

    Menu.Separator()

    Menu.ColoredText("Version: " .. VERSION, ARGB(255, 255, 255, 255))
    Menu.ColoredText("Last Update: " .. LAST_UPDATE, ARGB(255, 255, 255, 255))

    Menu.Separator()
end)

----------------------------------------------------------------------------------------------

---@type fun():void
local Combo = function()
    local eTarget = TS:GetTarget(E.Range)
    if eTarget and IsReady(E, function()
        local menuValue = GetMenuValue("ComboUseE")
        local poisonMenuValue = GetMenuValue("ComboEPoisoned")
        local canCast = IsValidTarget(eTarget, E.Range)
        local travelTime = E.Delay + (Player:EdgeDistance(eTarget) / E.Speed)
        local isPoisoned = IsPoisoned(eTarget, travelTime)
        local isPoisonedCheck = poisonMenuValue and isPoisoned or not poisonMenuValue
        return menuValue and canCast and isPoisonedCheck
    end) then
        return CastSpell(_E, eTarget)
    end

    local wTarget = TS:GetTarget(W.Range)
    if wTarget and IsReady(W, function()
        local menuValue = GetMenuValue("ComboUseW")
        local canCast = IsValidTarget(wTarget, W.Range)
        return menuValue and canCast
    end) then
        local hitChanceValue = GetMenuValue("ComboHitChanceW")
        return W:CastOnHitChance(wTarget, hitChanceValue)
    end

    local qTarget = TS:GetTarget(Q.Range)
    if qTarget and IsReady(Q, function()
        local menuValue = GetMenuValue("ComboUseQ")
        local poisonMenuValue = GetMenuValue("ComboQPoisoned")
        local canCast = IsValidTarget(qTarget, Q.Range)
        local isPoisoned = IsPoisoned(qTarget, Q.Delay)
        local isPoisonedCheck = poisonMenuValue and not isPoisoned or not poisonMenuValue
        return menuValue and canCast and isPoisonedCheck
    end) then
        local hitChanceValue = GetMenuValue("ComboHitChanceQ")
        return Q:CastOnHitChance(qTarget, hitChanceValue)
    end

    if IsReady(R, function()
        local menuValue = GetMenuValue("ComboUseR")
        return menuValue
    end) then
        local minHit = GetMenuValue("ComboMinHitR")
        local bestPosition, stunCount = GetBestUltimatePosition()
        if bestPosition and stunCount >= minHit then
            return CastSpell(_R, bestPosition)
        end
    end
end

---@type fun():void
local Harass = function()
    local wTarget = TS:GetTarget(W.Range)
    if wTarget and IsReady(W, function()
        local menuValue = GetMenuValue("HarassUseW")
        local manaMenuValue = GetMenuValue("HarassManaW")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        local whiteListValue = GetWhiteListValue("W", "Harass", wTarget.AsAI.CharName)
        local canCast = IsValidTarget(wTarget, W.Range)
        return menuValue and isEnoughMana and whiteListValue and canCast
    end) then
        local hitChanceValue = GetMenuValue("HarassHitChanceW")
        return W:CastOnHitChance(wTarget, hitChanceValue)
    end

    local eTarget = TS:GetTarget(E.Range)
    if eTarget and IsReady(E, function()
        local menuValue = GetMenuValue("HarassUseE")
        local poisonMenuValue = GetMenuValue("HarassEPoisoned")
        local manaMenuValue = GetMenuValue("HarassManaE")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        local whiteListValue = GetWhiteListValue("E", "Harass", eTarget.AsAI.CharName)
        local canCast = IsValidTarget(eTarget, E.Range)
        local travelTime = E.Delay + (Player:EdgeDistance(eTarget) / E.Speed)
        local isPoisoned = IsPoisoned(eTarget, travelTime)
        local isPoisonedCheck = poisonMenuValue and isPoisoned or not poisonMenuValue
        return menuValue and isEnoughMana and whiteListValue and canCast and isPoisonedCheck
    end) then
        return CastSpell(_E, eTarget)
    end

    local qTarget = TS:GetTarget(Q.Range)
    if qTarget and IsReady(Q, function()
        local menuValue = GetMenuValue("HarassUseQ")
        local poisonMenuValue = GetMenuValue("HarassQPoisoned")
        local manaMenuValue = GetMenuValue("HarassManaQ")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        local whiteListValue = GetWhiteListValue("Q", "Harass", qTarget.AsAI.CharName)
        local canCast = IsValidTarget(qTarget, Q.Range)
        local isPoisoned = IsPoisoned(qTarget, Q.Delay)
        local isPoisonedCheck = poisonMenuValue and not isPoisoned or not poisonMenuValue
        return menuValue and isEnoughMana and whiteListValue and canCast and isPoisonedCheck
    end) then
        local hitChanceValue = GetMenuValue("HarassHitChanceQ")
        return Q:CastOnHitChance(qTarget, hitChanceValue)
    end
end

---@type fun():void
local LastHit = function()
    if IsReady(E, function()
        local menuValue = GetMenuValue("LastHitUseE")
        local manaMenuValue = GetMenuValue("LastHitManaE")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        return menuValue and isEnoughMana
    end) then
        local minions = ObjectManager.Get("enemy", "minions")
        for i, minion in pairs(minions) do
            local minion = minion.AsAI
            if minion and IsValidTarget(minion, E.Range) then
                local hpPred = E:GetHealthPred(minion)
                local travelTime = E.Delay + (Player.Position:Distance(minion.Position) / E.Speed)
                local aaDamage = Orbwalker.GetAutoAttackDamage(minion)
                local damage = GetDamage(E, minion, travelTime)
                local attackMenuValue = GetMenuValue("LastHitAttackE")
                if attackMenuValue and (hpPred > damage and hpPred < damage + aaDamage) then
                    if Orbwalker.CanAttack() then
                        Orbwalker.Orbwalk(Renderer.GetMousePos(), minion.AsAttackableUnit)
                    end
                end
                if damage >= hpPred then
                    return CastSpell(_E, minion)
                end
            end
        end
    end
end

---@type fun():void
local WaveClear = function()
    if Orbwalker.IsWindingUp() then return end
        
    if IsReady(E, function()
        local menuValue = GetMenuValue("WaveClearUseE")
        local manaMenuValue = GetMenuValue("WaveClearManaE")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        return menuValue and isEnoughMana
    end) then
        local bestMinion, lowestHealth = nil, math_huge
        local minions = ObjectManager.Get("enemy", "minions")
        for i, minion in pairs(minions) do
            local minion = minion.AsAI
            if minion and IsValidTarget(minion, E.Range) then
                local travelTime = E.Delay + (Player:EdgeDistance(minion) / E.Speed)
                local isPoisoned = IsPoisoned(minion, travelTime)
                local minionHealth = minion.Health
                if isPoisoned and minionHealth < lowestHealth then
                    lowestHealth = minionHealth
                    bestMinion = minion
                end
            end
        end

        if bestMinion then
            return CastSpell(_E, bestMinion)
        end
    end

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
            return CastSpell(_Q, bestPos)
        end
    end
end

---@type fun():void
local JungleClear = function()
    if Orbwalker.IsWindingUp() then return end

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
        local predResult = bestMinion:FastPrediction(Q.Delay)
        if predResult then
            return CastSpell(_Q, predResult)
        end
    end

    if IsReady(W, function()
        local menuValue = GetMenuValue("JungleClearUseW")
        local manaMenuValue = GetMenuValue("JungleClearManaW")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        return menuValue and isEnoughMana
    end) then
        local predResult = bestMinion:FastPrediction(W.Delay)
        if predResult then
            return CastSpell(_W, predResult)
        end
    end

    if IsReady(E, function()
        local menuValue = GetMenuValue("JungleClearUseE")
        local manaMenuValue = GetMenuValue("JungleClearManaE")
        local isEnoughMana = IsEnoughMana(manaMenuValue)
        local poisonMenuValue = GetMenuValue("JungleClearEPoisoned")
        local travelTime = E.Delay + (Player:EdgeDistance(bestMinion) / E.Speed)
        local isPoisoned = IsPoisoned(bestMinion, travelTime)
        local isPoisonedCheck = poisonMenuValue and isPoisoned or not poisonMenuValue
        return menuValue and isEnoughMana and isPoisonedCheck
    end) then
        return CastSpell(_E, bestMinion)
    end
end

---@type fun():void
local AutoMode = function()
    if IsReady(R, function()
        local menuValue = GetMenuValue("AutoUseR")
        return menuValue
    end) then
        local minHit = GetMenuValue("AutoMinHitR")
        local bestPosition, stunCount = GetBestUltimatePosition()
        if bestPosition and stunCount >= minHit then
            return CastSpell(_R, bestPosition)
        end
    end
end

----------------------------------------------------------------------------------------------

---@type fun():void
local OnUpdate = function()
    if not GetMenuValue("ScriptEnabled") then return end
    if not GameIsAvailable() then return end

    local activeMode = Orbwalker.GetMode()
    if activeMode == "Combo" then
        Combo()
    elseif activeMode == "Harass" then
        Harass()
    end
end

---@type fun():void
local OnTick = function()
    if not GetMenuValue("ScriptEnabled") then return end

    local tick = os_clock()
    if TickCount < tick then
        TickCount = tick + 0.1

        local level = Player.Level
        local activeMode = Orbwalker.GetMode()
        local blockAttackCond = false
        if activeMode == "Combo" and GetMenuValue("BlockAAEnabled") and level >= GetMenuValue("BlockAALevel") then
            blockAttackCond = true
        elseif activeMode == "Lasthit" and GetMenuValue("BlockAALastHit") and level >= GetMenuValue("BlockAALastHitLevel") then
            blockAttackCond = true
        elseif activeMode == "Waveclear" and GetMenuValue("BlockAAWaveClear") and level >= GetMenuValue("BlockAAWaveClearLevel") then
            blockAttackCond = true
        elseif activeMode == "Waveclear" and GetMenuValue("BlockAAJungleClear") and level >= GetMenuValue("BlockAAJungleClearLevel") then
            blockAttackCond = true
        end
        Orbwalker.BlockAttack(blockAttackCond)

        if GameIsAvailable() then
            AutoMode()

            if activeMode == "Lasthit" then
                LastHit()
            elseif activeMode == "Waveclear" then
                if LastHit() or WaveClear() or JungleClear() then
                    return
                end
            end
        end
    end
end

---@type fun():void
local OnDraw = function()
    if not GetMenuValue("ScriptEnabled") then return end

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

---@type fun(args: table):void
local OnCastSpell = function(args)
    if not GetMenuValue("ScriptEnabled") then return end

    if GetMenuValue("BlockR") then
        if args.Slot == SpellSlots.R then
            local count = 0
            local heroes = ObjectManager.Get("enemy", "heroes")
            local endCone = Player.Position:Extended(args.TargetEndPosition, R.Range)
            for k, hero in pairs(heroes) do
                if IsValidTarget(hero, R.Range) and IsFacing(hero, Player) and IsInTheCone(hero.Position, Player.Position, endCone, R.Angle) then
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
    EventManager.RegisterCallback(Events.OnUpdate, OnUpdate)
    EventManager.RegisterCallback(Events.OnTick, OnTick)
    EventManager.RegisterCallback(Events.OnDraw, OnDraw)
    EventManager.RegisterCallback(Events.OnCastSpell, OnCastSpell)

    return true
end

----------------------------------------------------------------------------------------------

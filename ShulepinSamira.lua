if Player.CharName ~= "Samira" then
    return
end

----------------------------------------------------------------------------------------------

local SCRIPT_NAME, VERSION, LAST_UPDATE = "ShulepinSamira", "1.0.0", "19/06/2021"
_G.CoreEx.AutoUpdate("https://robur.site/shulepin/robur/raw/branch/master/" .. SCRIPT_NAME .. ".lua", VERSION)
module(SCRIPT_NAME, package.seeall, log.setup)
clean.module(SCRIPT_NAME, clean.seeall, log.setup)

----------------------------------------------------------------------------------------------

local SDK = _G.CoreEx

local DamageLib = _G.Libs.DamageLib
local CollisionLib = _G.Libs.CollisionLib
local Menu = _G.Libs.NewMenu
local Prediction = _G.Libs.Prediction
local TargetSelector = _G.Libs.TargetSelector
local Orbwalker = _G.Libs.Orbwalker
local Spell = _G.Libs.Spell
local TS = _G.Libs.TargetSelector()

local ObjectManager = SDK.ObjectManager
local EventManager = SDK.EventManager
local Input = SDK.Input
local Game = SDK.Game
local Geometry = SDK.Geometry
local Renderer = SDK.Renderer
local Enums = SDK.Enums

local Events = Enums.Events
local SpellSlots = Enums.SpellSlots
local SpellStates = Enums.SpellStates
local HitChance = Enums.HitChance
local Vector = Geometry.Vector

local pairs = _G.pairs
local type = _G.type
local tonumber = _G.tonumber
local math_abs = _G.math.abs
local math_huge = _G.math.huge
local math_min = _G.math.min
local math_deg = _G.math.deg
local math_sin = _G.math.sin
local math_cos = _G.math.cos
local math_acos = _G.math.acos
local math_pi = _G.math.pi
local math_pi2 = 0.01745329251
local os_clock = _G.os.clock
local string_format = _G.string.format
local table_remove = _G.table.remove

local _Q = SpellSlots.Q
local _W = SpellSlots.W
local _E = SpellSlots.E
local _R = SpellSlots.R

----------------------------------------------------------------------------------------------

local Q =
    Spell.Skillshot(
    {
        ["Slot"] = _Q,
        ["SlotString"] = "Q",
        ["Speed"] = 2600,
        ["Range"] = 880,
        ["Delay"] = 0.25,
        ["Radius"] = 60,
        ["Type"] = "Linear",
        ["Collisions"] = {
            ["WindWall"] = true,
            ["Heroes"] = true,
            ["Minions"] = true
        }
    }
)

local Q2 =
    Spell.Skillshot(
    {
        ["Slot"] = _Q,
        ["SlotString"] = "Q",
        ["Speed"] = 2600,
        ["Range"] = 300,
        ["Delay"] = 0.25,
        ["Radius"] = 100,
        ["Type"] = "Linear"
    }
)

local W =
    Spell.Active(
    {
        ["Slot"] = _W,
        ["SlotString"] = "W",
        ["Range"] = 325
    }
)

local E =
    Spell.Targeted(
    {
        ["Slot"] = _E,
        ["SlotString"] = "E",
        ["Range"] = 600
    }
)

local R =
    Spell.Active(
    {
        ["Slot"] = _R,
        ["SlotString"] = "R",
        ["Range"] = 600
    }
)

----------------------------------------------------------------------------------------------

local LastCastT = {
    [_Q] = 0,
    [_W] = 0,
    [_E] = 0,
    [_R] = 0
}

local DrawSpellTable = {Q, W, E, R}

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
    if LastCastT[slot] + 0.05 < tick then
        if Input.Cast(slot, position) then
            LastCastT[slot] = tick
            if condition ~= nil then
                return true and
                    (type(condition) == "function" and condition() or type(condition) == "boolean" and condition)
            end
            return true
        end
    end
    return false
end

---@type fun(id: string):void
local AddWhiteListMenu = function(name, id)
    Menu.NewTree(
        id .. "WhiteList",
        name,
        function()
            local heroes = ObjectManager.Get("enemy", "heroes")
            for k, hero in pairs(heroes) do
                local heroAI = hero.AsAI
                Menu.Checkbox(id .. "WhiteList" .. heroAI.CharName, heroAI.CharName, true)
            end
        end
    )
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
    local flatAD = Player.FlatPhysicalDamageMod
    if slot == _E then
        local rawDamage = 40 + 10 * level + flatAD * 0.2
        return DamageLib.CalculateMagicalDamage(Player, target, rawDamage)
    end
    return 0
end

----------------------------------------------------------------------------------------------

local HitChanceList = {"Collision", "OutOfRange", "VeryLow", "Low", "Medium", "High", "VeryHigh", "Dashing", "Immobile"}

Menu.RegisterMenu(
    "SSamira",
    "Shulepin Samira",
    function()
        Menu.Checkbox("ScriptEnabled", "Script Enabled", true)

        Menu.Separator()

        Menu.ColoredText("Spell Settings", ARGB(255, 255, 255, 255), true)

        Menu.Separator()

        Menu.NewTree(
            "Q",
            "[Q] Flair",
            function()
                Menu.NewTree(
                    "ComboQ",
                    "Combo Options",
                    function()
                        Menu.Checkbox("ComboUseQ", "Enabled", true)
                        Menu.Dropdown("ComboHitChanceQ", "Hit Chance", 4, HitChanceList)
                    end
                )
                Menu.NewTree(
                    "HarassQ",
                    "Harass Options",
                    function()
                        Menu.Checkbox("HarassUseQ", "Enabled", true)
                        Menu.Dropdown("HarassHitChanceQ", "Hit Chance", 4, HitChanceList)
                        Menu.Slider("HarassManaQ", "Min. Mana [%]", 35, 0, 100, 1)
                        AddWhiteListMenu("White List", "HarassQ")
                    end
                )
                Menu.NewTree(
                    "WaveClearQ",
                    "Wave Clear Options",
                    function()
                        Menu.Checkbox("WaveClearUseQ", "Enabled", true)
                        Menu.Slider("WaveClearManaQ", "Min. Mana [%]", 35, 0, 100, 1)
                        Menu.Slider("WaveClearMinHitQ", "Min. Minion Hits", 3, 0, 6, 1)
                    end
                )
                Menu.NewTree(
                    "JungleClearQ",
                    "Jungle Clear Options",
                    function()
                        Menu.Checkbox("JungleClearUseQ", "Enabled", true)
                        Menu.Slider("JungleClearManaQ", "Min. Mana [%]", 35, 0, 100, 1)
                    end
                )
                Menu.NewTree(
                    "DrawingsQ",
                    "Drawings",
                    function()
                        Menu.Checkbox("DrawQ", "Draw Range", true)
                        Menu.ColorPicker("DrawColorQ", "Color", ARGB(255, 255, 255, 255))
                    end
                )
            end
        )

        Menu.NewTree(
            "W",
            "[W] Blade Whirl",
            function()
                Menu.NewTree(
                    "ComboW",
                    "Combo Options",
                    function()
                        Menu.Checkbox("ComboUseW", "Enabled", true)
                        Menu.Dropdown("ComboWCastMode", "Cast Mode", 0, {"Smart", "Always"})
                    end
                )
                Menu.NewTree(
                    "WaveClearW",
                    "Wave Clear Options",
                    function()
                        Menu.Checkbox("WaveClearUseW", "Enabled", true)
                        Menu.Slider("WaveClearManaW", "Min. Mana [%]", 35, 0, 100, 1)
                        Menu.Slider("WaveClearMinHitW", "Min. Minion Hits", 4, 0, 6, 1)
                    end
                )
                Menu.NewTree(
                    "JungleClearW",
                    "Jungle Clear Options",
                    function()
                        Menu.Checkbox("JungleClearUseW", "Enabled", true)
                        Menu.Slider("JungleClearManaW", "Min. Mana [%]", 35, 0, 100, 1)
                    end
                )
                Menu.NewTree(
                    "DrawingsW",
                    "Drawings",
                    function()
                        Menu.Checkbox("DrawW", "Draw Range", true)
                        Menu.ColorPicker("DrawColorW", "Color", ARGB(255, 255, 255, 255))
                    end
                )
            end
        )

        Menu.NewTree(
            "E",
            "[E] Wild Rush",
            function()
                Menu.NewTree(
                    "ComboE",
                    "Combo Options",
                    function()
                        Menu.Checkbox("ComboUseE", "Enabled", true)
                    end
                )
                Menu.NewTree(
                    "JungleClearE",
                    "Jungle Clear Options",
                    function()
                        Menu.Checkbox("JungleClearUseE", "Enabled", true)
                        Menu.Slider("JungleClearManaE", "Min. Mana [%]", 35, 0, 100, 1)
                    end
                )
                Menu.NewTree(
                    "DrawingsE",
                    "Drawings",
                    function()
                        Menu.Checkbox("DrawE", "Draw Range", true)
                        Menu.ColorPicker("DrawColorE", "Color", ARGB(255, 255, 255, 255))
                    end
                )
            end
        )

        Menu.NewTree(
            "R",
            "[R] Inferno Trigger",
            function()
                Menu.NewTree(
                    "ComboR",
                    "Combo Options",
                    function()
                        Menu.Checkbox("ComboUseR", "Enabled", true)
                    end
                )
                Menu.NewTree(
                    "DrawingsR",
                    "Drawings",
                    function()
                        Menu.Checkbox("DrawR", "Draw Range", true)
                        Menu.ColorPicker("DrawColorR", "Color", ARGB(255, 255, 255, 255))
                    end
                )
            end
        )

        Menu.Separator()

        Menu.ColoredText("Script Information", ARGB(255, 255, 255, 255), true)

        Menu.Separator()

        Menu.ColoredText("Version: " .. VERSION, ARGB(255, 255, 255, 255))
        Menu.ColoredText("Last Update: " .. LAST_UPDATE, ARGB(255, 255, 255, 255))

        Menu.Separator()
    end
)

----------------------------------------------------------------------------------------------

---@type fun():void
local Combo = function()
    if Orbwalker.IsWindingUp() then
        return
    end

    local passiveCount = Player.SecondResource
    local rTarget = TS:GetTarget(R.Range)
    if
        rTarget and
            IsReady(
                R,
                function()
                    local menuValue = GetMenuValue("ComboUseR")
                    local canCast = IsValidTarget(rTarget, R.Range)
                    return menuValue and canCast
                end
            )
     then
        return R:Cast()
    end

    if
        rTarget and
            IsReady(
                E,
                function()
                    local menuValue = GetMenuValue("ComboUseE")
                    local canCast = IsValidTarget(rTarget, R.Range)
                    local dist = Player.Position:Distance(rTarget.Position)
                    return menuValue and canCast and
                        ((passiveCount >= 4 and IsReady(W)) or passiveCount >= 5 or dist > 300 and IsReady(R))
                end
            )
     then
        return E:Cast(rTarget)
    end

    local qTarget = TS:GetTarget(Q.Range)
    if
        qTarget and
            IsReady(
                Q,
                function()
                    local menuValue = GetMenuValue("ComboUseQ")
                    local canCast = IsValidTarget(qTarget, Q.Range)
                    return menuValue and canCast
                end
            )
     then
        local hitChanceValue = GetMenuValue("ComboHitChanceQ")
        if Player.Position:Distance(qTarget) < Q2.Range then
            return Q2:CastOnHitChance(qTarget, 0.1)
        end
        return Q:CastOnHitChance(qTarget, hitChanceValue)
    end

    local wTarget = TS:GetTarget(W.Range)
    if
        wTarget and
            IsReady(
                W,
                function()
                    local menuValue = GetMenuValue("ComboUseW")
                    local castMode = GetMenuValue("ComboWCastMode")
                    local canCast = IsValidTarget(wTarget, W.Range)
                    return menuValue and canCast and
                        (castMode == 0 and Player.Level >= 6 and passiveCount == 5 or castMode == 1)
                end
            )
     then
        return W:Cast()
    end
end

---@type fun():void
local Harass = function()
    local qTarget = TS:GetTarget(Q.Range)
    if
        qTarget and
            IsReady(
                Q,
                function()
                    local menuValue = GetMenuValue("HarassUseQ")
                    local manaMenuValue = GetMenuValue("HarassManaQ")
                    local isEnoughMana = IsEnoughMana(manaMenuValue)
                    local whiteListValue = GetWhiteListValue("Q", "Harass", qTarget.AsAI.CharName)
                    local canCast = IsValidTarget(qTarget, Q.Range)
                    return menuValue and isEnoughMana and whiteListValue and canCast
                end
            )
     then
        local hitChanceValue = GetMenuValue("HarassHitChanceQ")
        if Player.Position:Distance(qTarget) < Q2.Range then
            return Q2:CastOnHitChance(qTarget, hitChanceValue)
        end
        return Q:CastOnHitChance(qTarget, hitChanceValue)
    end
end

--@type fun():void
local WaveClear = function()
    if Orbwalker.IsWindingUp() then
        return
    end

    if
        IsReady(
            Q,
            function()
                local menuValue = GetMenuValue("WaveClearUseQ")
                local manaMenuValue = GetMenuValue("WaveClearManaQ")
                local isEnoughMana = IsEnoughMana(manaMenuValue)
                return menuValue and isEnoughMana
            end
        )
     then
        local points = {}
        local minionCount = GetMenuValue("WaveClearMinHitQ")
        local closestMinion, closestMinionDist = nil, math_huge
        local minions = ObjectManager.Get("enemy", "minions")
        for i, minion in pairs(minions) do
            local minion = minion.AsAI
            if minion and minion.IsTargetable then
                local predPos = minion:FastPrediction(Q2.Delay)
                local dist = predPos:Distance(Player.Position)
                local dist2 = Player.Position:Distance(minion.Position)
                if dist < Q2.Range then
                    points[#points + 1] = predPos
                end
                if dist2 < closestMinionDist then
                    closestMinionDist = dist2
                    closestMinion = minion
                end
            end
        end

        local bestPos, hitCount = Geometry.BestCoveringCircle(points, 200)
        if bestPos and hitCount >= minionCount and closestMinion then
            local startPos = Player.Position
            local endPos = bestPos
            local isOnSegment, pointSegment, pointLine = closestMinion.Position:ProjectOn(startPos, endPos)
            if isOnSegment and pointSegment:Distance(closestMinion.Position) <= Q.Radius then
                return Q:Cast(bestPos)
            else
                return Q:Cast(closestMinion.Position)
            end
        end
    end

    if
        IsReady(
            W,
            function()
                local menuValue = GetMenuValue("WaveClearUseW")
                local manaMenuValue = GetMenuValue("WaveClearManaW")
                local isEnoughMana = IsEnoughMana(manaMenuValue)
                return menuValue and isEnoughMana
            end
        )
     then
        local count = 0
        local minionCount = GetMenuValue("WaveClearMinHitW")
        local minions = ObjectManager.Get("enemy", "minions")
        for i, minion in pairs(minions) do
            local minion = minion.AsAI
            if minion and minion.IsTargetable then
                local dist = minion.Position:Distance(Player.Position)
                if dist < W.Range then
                    count = count + 1
                end
            end
        end

        if count >= minionCount then
            return W:Cast()
        end
    end
end

---@type fun():void
local JungleClear = function()
    if Orbwalker.IsWindingUp() then
        return
    end

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

    if not bestMinion then
        return
    end

    if
        IsReady(
            Q,
            function()
                local menuValue = GetMenuValue("JungleClearUseQ")
                local manaMenuValue = GetMenuValue("JungleClearManaQ")
                local isEnoughMana = IsEnoughMana(manaMenuValue)
                return menuValue and isEnoughMana
            end
        )
     then
        local predResult = bestMinion:FastPrediction(Q.Delay)
        if predResult then
            if Player.Position:Distance(bestMinion) < Q2.Range then
                return Q2:Cast(predResult)
            end
            return Q:Cast(predResult)
        end
    end

    if
        IsReady(
            E,
            function()
                local menuValue = GetMenuValue("JungleClearUseE")
                local manaMenuValue = GetMenuValue("JungleClearManaE")
                local isEnoughMana = IsEnoughMana(manaMenuValue)
                return menuValue and isEnoughMana
            end
        )
     then
        return E:Cast(bestMinion)
    end

    if
        IsReady(
            W,
            function()
                local menuValue = GetMenuValue("JungleClearUseW")
                local manaMenuValue = GetMenuValue("JungleClearManaW")
                local isEnoughMana = IsEnoughMana(manaMenuValue)
                return menuValue and isEnoughMana
            end
        )
     then
        local dist = Player.Position:Distance(bestMinion)
        if dist <= W.Range then
            return W:Cast()
        end
    end
end

---@type fun():void
local AutoMode = function()
    if
        IsReady(
            E,
            function()
                local menuValue = GetMenuValue("ComboUseE")
                return menuValue
            end
        )
     then
        local heroes = ObjectManager.Get("enemy", "heroes")
        for k, hero in pairs(heroes) do
            local hero = hero.AsAI
            local damage = GetDamage(E, hero)
            local aaDamage = DamageLib.GetAutoAttackDamage(Player, hero, true)
            local health = hero.Health + hero.ShieldAll
            if hero and IsValidTarget(hero, E.Range) and damage + aaDamage >= health then
                return E:Cast(hero)
            end
        end
    end
end

----------------------------------------------------------------------------------------------

---@type fun():void
local OnUpdate = function()
    if not GetMenuValue("ScriptEnabled") then
        return
    end
    if not GameIsAvailable() then
        return
    end

    local activeMode = Orbwalker.GetMode()
    if activeMode == "Combo" then
        Combo()
    elseif activeMode == "Harass" then
        Harass()
    end
end

---@type fun():void
local OnTick = function()
    if not GetMenuValue("ScriptEnabled") then
        return
    end

    local tick = os_clock()
    if TickCount < tick then
        TickCount = tick + 0.3

        AutoMode()

        if GameIsAvailable() then
            local activeMode = Orbwalker.GetMode()
            if activeMode == "Waveclear" then
                if WaveClear() or JungleClear() then
                    return
                end
            end
        end
    end
end

---@type fun():void
local OnDraw = function()
    if not GetMenuValue("ScriptEnabled") then
        return
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

----------------------------------------------------------------------------------------------

---@type fun():void
function OnLoad()
    EventManager.RegisterCallback(Events.OnUpdate, OnUpdate)
    EventManager.RegisterCallback(Events.OnTick, OnTick)
    EventManager.RegisterCallback(Events.OnDraw, OnDraw)

    return true
end

----------------------------------------------------------------------------------------------

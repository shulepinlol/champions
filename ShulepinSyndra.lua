if Player.CharName ~= "Syndra" then return end

----------------------------------------------------------------------------------------------

local SCRIPT_NAME, VERSION, LAST_UPDATE = "ShulepinSyndra", "1.0.9", "12/08/2022"
_G.CoreEx.AutoUpdate("https://raw.githubusercontent.com/shulepinlol/champions/main/" .. SCRIPT_NAME .. ".lua", VERSION)
module("ShulepinSyndra", package.seeall, log.setup)
clean.module("ShulepinSyndra", clean.seeall, log.setup)

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
local Vector            = Geometry.Vector

local pairs             = _G.pairs
local type              = _G.type
local tonumber          = _G.tonumber
local math_abs          = _G.math.abs
local math_huge         = _G.math.huge
local math_min          = _G.math.min
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
    ["Range"] = 800,
    ["Delay"] = 0.65,
    ["Radius"] = 180,
    ["Type"] = "Circular",
})

local W = Spell.Skillshot({
    ["Slot"] = _W,
    ["SlotString"] = "W",
    ["Speed"] = math_huge,
    ["Range"] = 950,
    ["Delay"] = 0.75,
    ["Radius"] = 225,
    ["Type"] = "Circular",

    ["GrabbedObjects"] = nil,
    ["ObjectList"] = {
        ["SRU_ChaosMinionSuper"]    = true,
        ["SRU_OrderMinionSuper"]    = true,
        ["HA_ChaosMinionSuper"]     = true,
        ["HA_OrderMinionSuper"]     = true,
        ["SRU_ChaosMinionRanged"]   = true,
        ["SRU_OrderMinionRanged"]   = true,
        ["HA_ChaosMinionRanged"]    = true,
        ["HA_OrderMinionRanged"]    = true,
        ["SRU_ChaosMinionMelee"]    = true,
        ["SRU_OrderMinionMelee"]    = true,
        ["HA_ChaosMinionMelee"]     = true,
        ["HA_OrderMinionMelee"]     = true,
        ["SRU_ChaosMinionSiege"]    = true,
        ["SRU_OrderMinionSiege"]    = true,
        ["HA_ChaosMinionSiege"]     = true,
        ["HA_OrderMinionSiege"]     = true,
        ["SRU_Krug"]                = true,
        ["SRU_KrugMini"]            = true,
        ["TestCubeRender"]          = true,
        ["SRU_RazorbeakMini"]       = true,
        ["SRU_Razorbeak"]           = true,
        ["SRU_MurkwolfMini"]        = true,
        ["SRU_Murkwolf"]            = true,
        ["SRU_Gromp"]               = true,
        ["Sru_Crab"]                = true,
        ["SRU_Red"]                 = true,
        ["SRU_Blue"]                = true,
        ["EliseSpiderling"]         = true,
        ["HeimerTYellow"]           = true,
        ["HeimerTBlue"]             = true,
        ["MalzaharVoidling"]        = true,
        ["ShacoBox"]                = true,
        ["YorickGhoulMelee"]        = true,
        ["YorickBigGhoul"]          = true
    }
})

local E = Spell.Skillshot({
    ["Slot"] = _E,
    ["SlotString"] = "E",
    ["Speed"] = 2500,
    ["Range"] = 700,
    ["Delay"] = 0.25,
    ["Radius"] = 100,
    ["Type"] = "Linear",
})

local EQ = Spell.Skillshot({
    ["Slot"] = _E,
    ["SlotString"] = "E",
    ["Speed"] = 2000,
    ["Range"] = 1250,
    ["Delay"] = 0.3,
    ["Radius"] = 100,
    ["Type"] = "Linear",
})

local EQ2 = Spell.Skillshot({
    ["Slot"] = _E,
    ["SlotString"] = "E",
    ["Speed"] = 2000,
    ["Range"] = 1250,
    ["Delay"] = 0.3,
    ["Radius"] = 100,
    ["Type"] = "Linear",
})

local R = Spell.Targeted({
    ["Slot"] = _R,
    ["SlotString"] = "R",
    ["Speed"] = 2000,
    ["Range"] = 750,
    ["Delay"] = 0,
})

----------------------------------------------------------------------------------------------

local OrbData = {}

local LastOrbGrabT = 0
local LastActionT = 0
local LastCastT = {
    [_Q] = 0,
    [_W] = 0,
    [_E] = 0,
    [_R] = 0,
}

local DrawSpellTable = { Q, W, E, R, EQ }

local TickCount = 0
local CastingEQ = false
local AntiGapEQ = false

---@type fun(a: number, r: number, g: number, b: number):number
local ARGB = function(a, r, g, b)
    return tonumber(string_format("0x%02x%02x%02x%02x", r, g, b, a))
end

----------------------------------------------------------------------------------------------

Menu.RegisterMenu("SSyndra", "Shulepin Syndra", function()
    Menu.ColumnLayout("c4", "c4", 1, true, function()
    Menu.NewTree("Drawings", "Drawings", function()
        Menu.Checkbox("DrawQ", "Draw Q", true)
        Menu.ColorPicker("DrawColorQ", "Q Color", ARGB(255, 255, 150, 255))
        Menu.Checkbox("DrawW", "Draw W", false)
        Menu.ColorPicker("DrawColorW", "W Color", ARGB(255, 255, 0, 255))
        Menu.Checkbox("DrawE", "Draw E", true)
        Menu.ColorPicker("DrawColorE", "E Color", ARGB(255, 255, 0, 255))
        Menu.Checkbox("DrawR", "Draw R", false)
        Menu.ColorPicker("DrawColorR", "R Color", ARGB(255, 255, 0, 255))
        Menu.Checkbox("DrawOrbs", "Draw Orbs", true)
        Menu.ColorPicker("DrawColorOrbs", "Orbs Color", ARGB(255, 255, 150, 255))
        Menu.Checkbox("DrawDamage", "Draw Ultimate Damage", true)
        Menu.ColorPicker("DrawColorDamage", "Damage Color", ARGB(255, 250, 170, 30))
    end)
    end)

        Menu.NewTree("Combo Options", "Combo Options", function()
        Menu.Separator("Combo Options", true)
        Menu.Checkbox("ComboUseQ", "Use Q", true)
        Menu.Checkbox("ComboUseW", "Use W", true)
        Menu.Checkbox("ComboUseE", "Use E", true)
        Menu.Checkbox("ComboUseQE", "Use Q + E Long", true)
        Menu.Checkbox("ComboUseWE", "Use W + E Long", false)
        Menu.Checkbox("ComboUseR", "Use R", true)

        Menu.NewTree("WhiteList", "R Cast White List", function()
            local heroes = ObjectManager.Get("enemy", "heroes")
            for k, hero in pairs(heroes) do
                local heroAI = hero.AsAI
                Menu.Checkbox("WhiteList" .. heroAI.CharName, heroAI.CharName, true)
            end
        end)

        Menu.NewTree("Conditions", "R Cast Conditions", function()
            Menu.Checkbox("ConditionsQ", "Don't Cast If Can Kill With Q", true)
        end)
        end)

        Menu.NewTree("Harass Options", "Harass Options", function()
        Menu.Separator("Harass Options", true)
        Menu.Checkbox("HarassUseQ", "Use Q", true)
        Menu.Checkbox("HarassUseW", "Use W", true)
        Menu.Checkbox("HarassUseE", "Use E", true)
        Menu.Checkbox("HarassUseQE", "Use Q + E Long", true)
        Menu.Checkbox("HarassUseWE", "Use W + E Long", true)
        Menu.Slider("HarassMana", "Mana", 30, 0, 100, 1)
    end)

    Menu.ColumnLayout("c2", "c2", 3, true, function()
        Menu.NewTree("Last Hit Options", "Last Hit Options", function()
        Menu.Separator("Last Hit Options", true)
        Menu.Checkbox("LastHitUseQ", "Use Q", true)
        Menu.Slider("LastHitMinionCountQ", "Hits", 2, 0, 6, 1)
        Menu.Slider("LastHitMana", "Mana", 30, 0, 100, 1)
    end)

        Menu.NextColumn()

    Menu.NewTree("Wave Clear Options", "Wave Clear Options", function()
        Menu.Separator("Wave Clear Options", true)
        Menu.Checkbox("WaveClearUseQ", "Use Q", true)
        Menu.Slider("WaveClearMinionCountQ", "Q Hits", 2, 0, 6, 1)
        Menu.Checkbox("WaveClearUseW", "Use W", true)
        Menu.Slider("WaveClearMinionCountW", "W Hits", 3, 0, 6, 1)
        Menu.Slider("WaveClearMana", "Mana", 30, 0, 100, 1)
    end)

        Menu.NextColumn()

    Menu.NewTree("Jungle Clear Options", "Jungle Clear Options", function()
        Menu.Separator("Jungle Clear Options", true)
        Menu.Checkbox("JungleClearUseQ", "Use Q", true)
        Menu.Checkbox("JungleClearUseW", "Use W", true)
        Menu.Checkbox("JungleClearUseE", "Use E", true)
        Menu.Slider("JungleClearMana", "Mana", 30, 0, 100, 1)
    end)
    end)

    Menu.ColumnLayout("c3", "c3", 2, true, function()
    Menu.NewTree("Prediction Options", "Prediction Options", function()
        Menu.Separator("Prediction Options", true)
        Menu.Slider("HitChanceQ", "Q HitChance", 0.15, 0, 1, 0.01)
        Menu.Slider("HitChanceW", "W HitChance", 0.15, 0, 1, 0.01)
        Menu.Slider("HitChanceQE", "QE HitChance", 0.35, 0, 1, 0.01)
    end)

        Menu.NextColumn()

    Menu.NewTree("Miscellaneous", "Miscellaneous", function()
        Menu.Separator("Miscellaneous", true)
        Menu.Checkbox("MiscAntiGap", "Use QE Gapclose", false)
        Menu.Checkbox("MiscInterrupt", "Use QE Interrupt", false)
    end)
    end)

    Menu.Separator("Author: Shulepin")
end)

----------------------------------------------------------------------------------------------

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
    if LastCastT[slot] + 0.25 < tick then
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

---@type fun(unit: GameObject):void
local GetRealHealth = function(unit)
    local hp = unit.AsAI.Health
    local shieldAP = unit.AsAttackableUnit.ShieldAP
    return hp + shieldAP
end

---@type fun():table
local GetBestOrbs = function()
    local tick = os_clock()
    local bestOrbs = {}
    for i = 1, #OrbData do
        local orb = OrbData[i]
        if orb then
            local isValid = IsValidObject(orb.Object)
            local position = nil
            if isValid then position = orb.Object.Position else position = orb.Position end
            if position then
                local dist = position:Distance(Player.Position)
                if dist <= E.Range then
                    local travelTime = E.Delay + (dist / E.Speed)
                    local hitTime = tick + travelTime
                    if orb.IsCreated and hitTime + 0.1 < orb.EndTime or hitTime > orb.EndTime then
                        if not W.GrabbedObjects or (W.GrabbedObjects and orb.Object and isValid and W.GrabbedObjects.Object and IsValidObject(W.GrabbedObjects.Object) and W.GrabbedObjects.Object.Ptr ~= orb.Object.Ptr) then
                            bestOrbs[#bestOrbs + 1] = orb
                        end
                    end
                end
            end
        end
    end
    return bestOrbs
end

---@type fun():GameObject
local GetBestGrabObject = function(onlyOrb)
    local bestOrb, lowestOrbT = nil, math_huge
    for i = 1, #OrbData do
        local orb = OrbData[i]
        if orb and orb.IsCreated and IsValidObject(orb.Object) then
            local dist = Player.Position:Distance(orb.Object.Position)
            if orb.EndTime < lowestOrbT and dist < 925 then
                lowestOrbT = orb.EndTime
                bestOrb = orb.Object
            end
        end
    end

    if bestOrb then return bestOrb, 1 end
    if onlyOrb then return end

    local minions = ObjectManager.Get("all", "minions")
    local bestMinion, lowestMinionHealth = nil, math_huge
    for i, minion in pairs(minions) do
        local minionAI = minion.AsAI
        if minionAI and minion.TeamId ~= Player.TeamId and W.ObjectList[minionAI.CharName] and IsValidTarget(minionAI, 925) then
            local minionHealth = minionAI.Health
            if minionHealth < lowestMinionHealth then
                lowestMinionHealth = minionHealth
                bestMinion = minionAI
            end
        end
    end

    if bestMinion then return bestMinion, 0 end
end

---@type fun():void
local UpdateGrabbedObjects = function()
    local buff = Player:GetBuff("syndrawtooltip")
    if not W.GrabbedObjects and buff then
        local minions = ObjectManager.Get("enemy", "minions")
        for i, minion in pairs(minions) do
            local minion = minion.AsAI
            if minion then
                local buff = minion:GetBuff("syndrawbuff")
                if buff and buff.DurationLeft > 0 then
                    W.GrabbedObjects = {
                        Object = minion,
                        Type = 0,
                    }
                    return
                end
            end
        end
    end
    
end

---@type fun():void
local ClearOrbData = function()
    local tick = os_clock()
    for i = 1, #OrbData do
        local orb = OrbData[i]
        if orb then
            if tick >= orb.EndTime then
                table_remove(OrbData, i)
            end
        end
    end
end

----------------------------------------------------------------------------------------------

---@type fun():void
local Combo = function(mode)
    if mode == "Harass" and not IsEnoughMana(GetMenuValue("HarassMana")) then return end
    local tick = os_clock()
    local bestOrbs = GetBestOrbs()
    local eqTarget = TS:GetTarget(EQ.Range)

    if eqTarget and IsReady(E, function()
        local menuValue = GetMenuValue(mode .. "UseE")
        local canCast = IsValidTarget(eqTarget, EQ.Range)
        return menuValue and canCast
    end) then
        if IsReady(Q) and GetMenuValue(mode .. "UseQE") and Player.Position:Distance(eqTarget) > Q.Range then
            EQ2.Delay = E.Delay + Q.Range / E.Speed
            local predResult = Prediction.GetPredictedPosition(eqTarget, EQ2, Player.Position:Extended(eqTarget.Position, Q.Range))
            if predResult and predResult.HitChance >= GetMenuValue("HitChanceQE") then
                if CastSpell(_Q, Player.Position:Extended(predResult.CastPosition, Q.Range)) then
                    CastingEQ = true
                    LastActionT = tick + 0.75
                    return true
                end
            end
        elseif IsReady(W) and GetMenuValue(mode .. "UseWE") and Player.Position:Distance(eqTarget) > Q.Range and W.GrabbedObjects then
            local wName = W:GetName()
            if wName ~= "SyndraW" and W.GrabbedObjects.Type == 1 then
                EQ2.Delay = E.Delay + W.Range / E.Speed
                local predResult = Prediction.GetPredictedPosition(eqTarget, EQ2, Player.Position:Extended(eqTarget.Position, E.Range))
                if predResult and predResult.HitChance >= GetMenuValue("HitChanceQE") then
                    if CastSpell(_W, Player.Position:Extended(predResult.CastPosition, E.Range)) then
                        CastingEQ = true
                        LastActionT = tick + 0.75
                        return true
                    end
                end
            end
        else
            for i = 1, #bestOrbs do
                local orb = bestOrbs[i]
                if orb then 
                    --local position = orb.Position or orb.Object.Position
                    local isValid = IsValidObject(orb.Object)
                    local position = nil
                    if isValid then position = orb.Object.Position else position = orb.Position end
                    if position then
                        local startPos = Player.Position
                        local endPos = Player.Position:Extended(position, Player.Position:Distance(position) > 200 and 1300 or 1000)
                        EQ.Delay = E.Delay + Player.Position:Distance(position) / E.Speed
                        local predResult = Prediction.GetPredictedPosition(eqTarget, EQ, position)
                        if predResult and predResult.HitChance >= GetMenuValue("HitChanceQE") then
                            local point = predResult.TargetPosition
                            local isOnSegment, pointSegment, pointLine = point:ProjectOn(startPos, endPos)
                            if isOnSegment and pointSegment:Distance(point) < EQ.Radius + eqTarget.BoundingRadius then
                                if CastSpell(_E, position) then
                                    LastActionT = tick + 0.75
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if tick < LastActionT then return end

    local wTarget = TS:GetTarget(W.Range)
    if wTarget and IsReady(W, function()
        local menuValue = GetMenuValue(mode .. "UseW")
        local canCast = IsValidTarget(wTarget, W.Range)
        return menuValue and canCast
    end) then
        local wName = W:GetName()
        if wName == "SyndraW" and not W.GrabbedObjects then
            local target = GetBestGrabObject()
            if target then
                return CastSpell(_W, target.Position)
            end
        else
            local predResult = Prediction.GetPredictedPosition(wTarget, W, Player.Position)
            if predResult and predResult.HitChance >= GetMenuValue("HitChanceW") then
                return CastSpell(_W, predResult.CastPosition)
            end
        end
    end

    local qTarget = TS:GetTarget(Q.Range)
    if qTarget and IsReady(Q, function()
        local menuValue = GetMenuValue(mode .. "UseQ")
        local canCast = IsValidTarget(qTarget, Q.Range)
        return menuValue and canCast
    end) then
        local predResult = Prediction.GetPredictedPosition(qTarget, Q, Player.Position)
        if predResult and predResult.HitChance >= GetMenuValue("HitChanceQ") then
            return CastSpell(_Q, predResult.CastPosition, function()
                OrbData[#OrbData + 1] = {
                    Object = nil,
                    Position = predResult.CastPosition,
                    IsCreated = false,
                    EndTime = tick + Q.Delay,
                }
                LastActionT = tick + Q.Delay
                return true
            end)
        end
    end
end

local LastHit = function()
    if not IsEnoughMana(GetMenuValue("LastHitMana")) then return end

    if IsReady(Q, function()
        local menuValue = GetMenuValue("LastHitUseQ")
        return menuValue
    end) then
        local points = {}
        local minionCount = GetMenuValue("LastHitMinionCountQ")
        local minions = ObjectManager.Get("enemy", "minions")

        for i, minion in pairs(minions) do
            local minion = minion.AsAI
            if minion and minion.IsTargetable then
                local predPos = minion:FastPrediction(Q.Delay)
                local dist = predPos:Distance(Player.Position)
                if dist < Q.Range and Q:CanKillTarget(minion) then
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
local WaveClear = function()
    if not IsEnoughMana(GetMenuValue("WaveClearMana")) then return end

    if IsReady(Q, function()
        local menuValue = GetMenuValue("WaveClearUseQ")
        return menuValue
    end) then
        local points = {}
        local minionCount = GetMenuValue("WaveClearMinionCountQ")
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

    if IsReady(W, function()
        local menuValue = GetMenuValue("WaveClearUseW")
        return menuValue
    end) then
        local points = {}
        local minionCount = GetMenuValue("WaveClearMinionCountW")
        local minions = ObjectManager.Get("enemy", "minions")

        for i, minion in pairs(minions) do
            local minion = minion.AsAI
            if minion and minion.IsTargetable then
                local predPos = minion:FastPrediction(W.Delay)
                local dist = predPos:Distance(Player.Position)
                if dist < W.Range then
                    points[#points + 1] = predPos
                end
            end
        end

        local bestPos, hitCount = Geometry.BestCoveringCircle(points, W.Radius)
        if bestPos and hitCount >= (minionCount - 1) then
            return CastSpell(_W, bestPos)
        end
    end
end

---@type fun():void
local JungleClear = function()
    if not IsEnoughMana(GetMenuValue("JungleClearMana")) then return end

    local tick = os_clock()
    local myHeroPos = Player.Position
    local mousePos = Renderer.GetMousePos()
    local bestMinion = nil
    local bestMinionHealth = 0
    local minions = ObjectManager.Get("neutral", "minions")
    for i, minion in pairs(minions) do
        local minion = minion.AsAI
        if minion and minion.IsTargetable and minion.MaxHealth > 5 then
            if minion:Distance(myHeroPos) < Q.Range and minion:Distance(mousePos) < 600 then
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
        return menuValue
    end) then
        local predResult = bestMinion:FastPrediction(Q.Delay)
        if predResult then
            return CastSpell(_Q, predResult)
        end
    end

    if IsReady(W, function()
        local menuValue = GetMenuValue("JungleClearUseW")
        return menuValue
    end) then
        local wName = W:GetName()
        if wName == "SyndraW" and not W.GrabbedObjects then
            local target = GetBestGrabObject(true)
            if target then
                return CastSpell(_W, target.Position)
            end
        else
            local predResult = bestMinion:FastPrediction(W.Delay)
            if predResult then
                return CastSpell(_W, predResult)
            end
        end
    end

    local bestOrbs = GetBestOrbs()
    if IsReady(E, function()
        local menuValue = GetMenuValue("JungleClearUseE")
        local menuValueW = GetMenuValue("JungleClearUseW")
        return menuValue and (not IsReady(W) and menuValueW or not menuValueW)
    end) then
        for i = 1, #bestOrbs do
            local orb = bestOrbs[i]
            if orb then 
                local isValid = IsValidObject(orb.Object)
                local position = nil
                if isValid then position = orb.Object.Position else position = orb.Position end
                if position then
                    local startPos = Player.Position
                    local endPos = Player.Position:Extended(position, Player.Position:Distance(position) > 200 and 1300 or 1000)
                    EQ.Delay = E.Delay + Player.Position:Distance(position) / E.Speed
                    local predResult = bestMinion:FastPrediction(EQ.Delay)
                    if predResult then
                        local point = predResult
                        local isOnSegment, pointSegment, pointLine = point:ProjectOn(startPos, endPos)
                        if isOnSegment and pointSegment:Distance(point) < EQ.Radius + bestMinion.BoundingRadius then
                            if CastSpell(_E, position) then
                                LastActionT = tick + 0.75
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
end

---@type fun(target: GameObject):void
local GetUltimateConditions = function(target)
    local condition = true
    if GetMenuValue("ConditionsQ") then
        if IsReady(Q, function()
            local damage = Q:GetDamage(target)
            local health = GetRealHealth(target)
            local healthCondition = health - damage <= 0
            local timeCondition = os_clock() > LastActionT
            local distCondition = Player.Position:Distance(target.Position) < Q.Range
            return healthCondition and timeCondition and distCondition
        end) then
            condition = false
        end
    end
    return condition
end

---@type fun():void
local ExecuteUltimate = function()
    if IsReady(R, function()
        local menuValue = GetMenuValue("ComboUseR")
        return menuValue
    end) then
        local heroes = ObjectManager.Get("enemy", "heroes")
        for k, hero in pairs(heroes) do
            if IsValidTarget(hero, R.Range) then
                local damage = R:GetDamage(hero)
                local health = GetRealHealth(hero)
                local whiteList = GetMenuValue("WhiteList" .. hero.AsAI.CharName)
                local conditions = GetUltimateConditions(hero)
                if damage > health and conditions and whiteList then
                    return CastSpell(_R, hero)
                end
            end
        end
    end
end

----------------------------------------------------------------------------------------------

---@type fun():void
local OnUpdate = function()
    if not GameIsAvailable() then return end

    local activeMode = Orbwalker.GetMode()
    if activeMode == "Combo" or activeMode == "Harass" then
        Combo(activeMode)
    end
end

---@type fun():void
local OnTick = function()
    local tick = os_clock()
    if TickCount < tick then
        TickCount = tick + 0.2

        ClearOrbData()
        ExecuteUltimate()
        UpdateGrabbedObjects()

        if GameIsAvailable() then
            local activeMode = Orbwalker.GetMode()
            if activeMode == "Lasthit" then
                LastHit()
            elseif activeMode == "Waveclear" then
                if LastHit() or 
                   WaveClear() or 
                   JungleClear() then
                    return 
                end
            end
        end
    end
end

---@type fun():void
local OnDraw = function()
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
        if GetMenuValue("DrawOrbs") then
            for i = 1, #OrbData do
                local orb = OrbData[i]
                if orb then
                    local obj = orb.Object
                    if obj and IsValidObject(obj) then
                        Renderer.DrawCircle3D(obj.Position, 65, 30, 2, GetMenuValue("DrawColorOrbs"))
                    end
                end
            end
        end
    end
    if GetMenuValue("DrawDamage") then
        local heroes = ObjectManager.Get("enemy", "heroes")
        for k, hero in pairs(heroes) do
            local heroAI = hero.AsAI
            if hero.IsVisible and hero.IsOnScreen and not hero.IsDead then
                local damage = R:GetDamage(hero)
                local hpBarPos = heroAI.HealthBarScreenPos
                local x = 106 / (heroAI.MaxHealth + heroAI.ShieldAll)
                local position = (heroAI.Health + heroAI.ShieldAll) * x
                local value = math_min(position, damage * x)
                position = position - value
                Renderer.DrawFilledRect(Vector(hpBarPos.x + position - 45, hpBarPos.y - 23), Vector(value, 11), 1, GetMenuValue("DrawColorDamage"))
            end
        end
    end
end

---@type fun(obj: GameObject):void
local OnCreateObject = function(obj)
    if obj and obj.Name == "Seed" then
        local objAI = obj.AsAI
        if obj.TeamId == Player.TeamId and objAI.CharName == "SyndraSphere" then 
            OrbData[#OrbData + 1] = {
                Object = obj,
                Position = nil,
                IsCreated = true,
                EndTime = os_clock() + 6.25,
            }
        end
    end
end

---@type fun(obj: GameObject):void
local OnDeleteObject = function(obj)
    if obj and obj.Name == "Seed" then
        local objAI = obj.AsAI
        if obj.TeamId == Player.TeamId and objAI.CharName == "SyndraSphere" then 
            for i = 1, #OrbData do
                local orb = OrbData[i]
                if orb then
                    if orb.Object and orb.Object.Ptr == obj.Ptr then
                        table_remove(OrbData, i)
                    end
                end
            end
        end
    end
end

---@type fun(unit: GameObject, spell: BuffInst):void
local OnBuffLost = function(unit, buff)
    if unit.IsMe then
        if buff.Name == "syndrawtooltip" then
            W.GrabbedObjects = nil
        end
    end
end

---@type fun(unit: GameObject, spell: SpellCast):void
local OnProcessSpell = function(unit, spell)
    if unit.IsMe then
        if spell and spell.SpellData then
            local sData = spell.SpellData
            local name = sData.Name
            local endPos = spell.EndPos

            if name == "SyndraQ" then
                local activeMode = Orbwalker.GetMode()
                if AntiGapEQ then
                    if CastingEQ then
                        CastSpell(_E, endPos)
                    end
                elseif activeMode == "Combo" or activeMode == "Harass" then
                    local menuValue = GetMenuValue(activeMode .. "UseE")
                    if CastingEQ and menuValue then
                        CastSpell(_E, endPos)
                    end
                end

                OrbData[#OrbData + 1] = {
                    Object = nil,
                    Position = endPos,
                    IsCreated = false,
                    EndTime = os_clock() + Q.Delay,
                }   
            end

            if name == "SyndraE" then
                CastingEQ = false
                AntiGapEQ = false
            end

            if name == "SyndraWCast" and LastOrbGrabT + 5 > os_clock() then
                OrbData[#OrbData + 1] = {
                    Object = nil,
                    Position = Player.Position:Extended(endPos, E.Range - 50),
                    IsCreated = false,
                    EndTime = os_clock() + Q.Delay,
                }
            end
        end
    end
end

---@type fun(args: table):void
local OnCastSpell = function(args)
    if args.Slot == SpellSlots.W then
        if not W.GrabbedObjects then
            local tick = os_clock()
            local orbDist = math_huge
            local minionDist = math_huge
            local castPosition = args.TargetPosition
            local distToCastPos = Player.Position:Distance(castPosition)
            if distToCastPos <= 925 then
                for i = 1, #OrbData do
                    local orb = OrbData[i]
                    if orb and orb.IsCreated and IsValidObject(orb.Object) then
                        local distToOrb = Player.Position:Distance(orb.Object)
                        local dist = castPosition:Distance(orb.Object.Position)
                        if dist <= orbDist and distToOrb <= 925 then
                            orbDist = dist
                            W.GrabbedObjects = {
                                Object = orb.Object,
                                Type = 1,
                            }
                            orb.EndTime = tick + 6.25
                            LastOrbGrabT = tick
                        end
                    end
                end
            end
        end
    end
end

---@type fun(unit: AIBaseClient, dash: DashInstance):void
local OnGapclose = function(unit, dash)
    if not unit.IsEnemy then return end

    if IsReady(Q, function()
        local menuValue = GetMenuValue("MiscAntiGap")
        local canCast = IsValidTarget(unit, Q.Range)
        return menuValue and canCast
    end) then
        local predResult = nil
        local dashEndPos = dash:GetPosition(Q.Delay)
        if dashEndPos:Distance(Player.Position) < 200 then
            predResult = Player.Position:Extended(unit.Position, 250)
        else
            predResult = dashEndPos
        end
        if predResult then
            return CastSpell(_Q, predResult, function()
                OrbData[#OrbData + 1] = {
                    Object = nil,
                    Position = predResult,
                    IsCreated = false,
                    EndTime = os_clock() + Q.Delay,
                }
                CastingEQ = true
                AntiGapEQ = true
                LastActionT = os_clock() + Q.Delay
                return true
            end)
        end
    end
end

---@type fun(unit: AIBaseClient, spell: SpellCast):void
local OnInterruptibleSpell = function(unit, spell)
    if not unit.IsEnemy then return end

    local tick = os_clock()
    if IsReady(Q, function()
        local menuValue = GetMenuValue("MiscInterrupt")
        local canCast = IsValidTarget(unit, Q.Range)
        return menuValue and canCast
    end) then
        if IsReady(Q) and Player.Position:Distance(unit) > Q.Range then
            EQ2.Delay = E.Delay + Q.Range / E.Speed
            local predResult = Prediction.GetPredictedPosition(unit, EQ2, Player.Position:Extended(unit.Position, Q.Range))
            if predResult and predResult.HitChance > 0 then
                if CastSpell(_Q, Player.Position:Extended(predResult.CastPosition, Q.Range)) then
                    CastingEQ = true
                    LastActionT = tick + 0.75
                    return true
                end
            end
        elseif IsReady(W) and Player.Position:Distance(unit) > Q.Range and W.GrabbedObjects then
            local wName = W:GetName()
            if wName ~= "SyndraW" and W.GrabbedObjects.Type == 1 then
                EQ2.Delay = E.Delay + W.Range / E.Speed
                local predResult = Prediction.GetPredictedPosition(unit, EQ2, Player.Position:Extended(unit.Position, E.Range))
                if predResult and predResult.HitChance > 0 then
                    if CastSpell(_W, Player.Position:Extended(predResult.CastPosition, E.Range)) then
                        CastingEQ = true
                        LastActionT = tick + 0.75
                        return true
                    end
                end
            end
        else
            local bestOrbs = GetBestOrbs()
            for i = 1, #bestOrbs do
                local orb = bestOrbs[i]
                if orb then 
                    local isValid = IsValidObject(orb.Object)
                    local position = nil
                    if isValid then position = orb.Object.Position else position = orb.Position end
                    if position then
                        local startPos = Player.Position
                        local endPos = Player.Position:Extended(position, Player.Position:Distance(position) > 200 and 1300 or 1000)
                        EQ.Delay = E.Delay + Player.Position:Distance(position) / E.Speed
                        local predResult = Prediction.GetPredictedPosition(unit, EQ, position)
                        if predResult and predResult.HitChance > 0 then
                            local point = predResult.TargetPosition
                            local isOnSegment, pointSegment, pointLine = point:ProjectOn(startPos, endPos)
                            if isOnSegment and pointSegment:Distance(point) < EQ.Radius + unit.BoundingRadius then
                                if CastSpell(_E, position) then
                                    LastActionT = tick + 0.75
                                    return true
                                end
                            end
                        end
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
    EventManager.RegisterCallback(Events.OnBuffLost, OnBuffLost)
    EventManager.RegisterCallback(Events.OnCreateObject, OnCreateObject)
    EventManager.RegisterCallback(Events.OnDeleteObject, OnDeleteObject)
    EventManager.RegisterCallback(Events.OnProcessSpell, OnProcessSpell)
    EventManager.RegisterCallback(Events.OnCastSpell, OnCastSpell)
    EventManager.RegisterCallback(Events.OnGapclose, OnGapclose)
    EventManager.RegisterCallback(Events.OnInterruptibleSpell, OnInterruptibleSpell)

    return true
end

----------------------------------------------------------------------------------------------

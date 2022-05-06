if Player.CharName ~= "Jayce" then return end

----------------------------------------------------------------------------------------------

local SCRIPT_NAME, VERSION, LAST_UPDATE = "ShulepinJayce", "1.0.0", "19/06/2021"
_G.CoreEx.AutoUpdate("https://robur.site/shulepin/robur/raw/branch/master/" .. SCRIPT_NAME .. ".lua", VERSION)
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

local QR = Spell.Skillshot({
    ["Slot"] = _Q,
    ["SlotString"] = "Q",
    ["Speed"] = 1450,
    ["Range"] = 1050,
    ["Delay"] = 0.25,
    ["Radius"] = 65,
    ["Type"] = "Linear",

    ["CD"] = 0,
    ["Form"] = "Range",

    ["Collisions"] = {
        ["Heroes"] = true,
        ["Minions"] = true,
        ["WindWall"] = true
    },

    ["UseHitbox"] = true,
})

local QR2 = Spell.Skillshot({
    ["Slot"] = _Q,
    ["SlotString"] = "Q",
    ["Speed"] = 2350,
    ["Range"] = 1470,
    ["Delay"] = 0.25,
    ["Radius"] = 65,
    ["Type"] = "Linear",

    ["CD"] = 0,
    ["Form"] = "Range",

    ["Collisions"] = {
        ["Heroes"] = true,
        ["Minions"] = true,
        ["WindWall"] = true
    },

    ["UseHitbox"] = true,
    ["Enhanced"] = true,
})

local WR = Spell.Active({
    ["Slot"] = _W,
    ["SlotString"] = "W",
    ["Range"] = 650,
    ["CD"] = 0,
    ["Form"] = "Range",
})

local ER = Spell.Skillshot({
    ["Slot"] = _E,
    ["SlotString"] = "E",
    ["Range"] = 650,
    ["CD"] = 0,
    ["Form"] = "Range",
})

local QM = Spell.Targeted({
    ["Slot"] = _Q,
    ["SlotString"] = "Q",
    ["Range"] = 600,
    ["CD"] = 0,
    ["Form"] = "Melee",
})

local WM = Spell.Active({
    ["Slot"] = _W,
    ["SlotString"] = "W",
    ["Range"] = 300,
    ["CD"] = 0,
    ["Form"] = "Melee",
})

local EM = Spell.Targeted({
    ["Slot"] = _E,
    ["SlotString"] = "E",
    ["Range"] = 270,
    ["CD"] = 0,
    ["Form"] = "Melee",
})

local R = Spell.Active({
    ["Slot"] = _R,
    ["SlotString"] = "R",
    ["Range"] = 650,
    ["CD"] = 0
})

local SpellTable = { QR, WR, ER, QM, WM, EM }
local DrawSpellTable = { QR, QR2, QM, WM, EM }

local CD = {
    ["Range"] = {
        [_Q] = 0,
        [_W] = 0,
        [_E] = 0
    },
    ["Melee"] = {
        [_Q] = 0,
        [_W] = 0,
        [_E] = 0
    }
}

local BaseCD = {
    ["Range"] = {
        [_Q] = { 8, 8, 8, 8, 8, 8 },
        [_W] = { 13, 11.4, 9.8, 8.2, 6.6, 5 },
        [_E] = { 16, 16, 16, 16, 16, 16 },
    },
    ["Melee"] = {
        [_Q] = { 16, 14, 12, 10, 8, 6 },
        [_W] = { 10, 10, 10, 10, 10, 10 },
        [_E] = { 20, 18, 16, 14, 12, 10 },
    }
}

local LastCastT = {
    [_Q] = 0,
    [_W] = 0,
    [_E] = 0,
    [_R] = 0,
}

local TickCount = 0
local CurrentTarget = nil
local GatePosition = nil
local GateLastCastT = 0
local CastingQE = false
local CurrentForm = Player.AsHero:GetSpell(_Q).Name == "JayceShockBlast" and "Range" or "Melee"

---@type fun(a: number, r: number, g: number, b: number):number
local ARGB = function(a, r, g, b)
    return tonumber(string_format("0x%02x%02x%02x%02x", r, g, b, a))
end

----------------------------------------------------------------------------------------------

Menu.RegisterMenu("SJayce", "Shulepin Jayce", function()
    Menu.ColumnLayout("c1", "c1", 2, true, function()
        Menu.ColoredText("Combo Options", 0xFFD700FF, true)
        Menu.ColoredText("> Range Spells", ARGB(255, 255, 255, 255))
        Menu.Checkbox("ComboUseRangeQ", "Use Q", true)
        Menu.Checkbox("ComboUseRangeW", "Use W", true)
        Menu.Checkbox("ComboUseRangeE", "Use E", true)
        Menu.ColoredText("> Melee Spells", ARGB(255, 255, 255, 255))
        Menu.Checkbox("ComboUseMeleeQ", "Use Q", true)
        Menu.Checkbox("ComboUseMeleeW", "Use W", true)
        Menu.Checkbox("ComboUseMeleeE", "Use E", true)
        Menu.ColoredText("", ARGB(255, 255, 255, 255))
        Menu.Checkbox("ComboUseR", "Use R", true)

        Menu.NextColumn()

        Menu.ColoredText("Harass Options", 0xFFD700FF, true)
        Menu.Checkbox("HarassUseRangeQ", "Use Range Q", true)
        Menu.Checkbox("HarassUseRangeQE", "Use Range QE", true)
        Menu.Checkbox("HarassUseRangeW", "Use Range W After Attack", true)
        Menu.Slider("HarassMana", "Mana", 50, 0, 100, 1)
    end)

    Menu.Separator()

    Menu.ColumnLayout("c2", "c2", 2, true, function()
        Menu.ColoredText("WaveClear Options", 0xFFD700FF, true)
        Menu.Checkbox("WaveClearUseRangeQ", "Use Range Q", true)
        Menu.Slider("WaveClearMinionCountQ", "Q Hits", 3, 0, 6, 1)
        Menu.Slider("WaveClearMana", "Mana", 50, 0, 100, 1)

        Menu.NextColumn()

        Menu.ColoredText("JungleClear Options", 0xFFD700FF, true)
        Menu.ColoredText("> Range Spells", ARGB(255, 255, 255, 255))
        Menu.Checkbox("JungleClearUseRangeQ", "Use Q", true)
        Menu.Checkbox("JungleClearUseRangeW", "Use W", true)
        Menu.Checkbox("JungleClearUseRangeE", "Use E", true)
        Menu.ColoredText("> Melee Spells", ARGB(255, 255, 255, 255))
        Menu.Checkbox("JungleClearUseMeleeQ", "Use Q", true)
        Menu.Checkbox("JungleClearUseMeleeW", "Use W", true)
        Menu.Checkbox("JungleClearUseMeleeE", "Use E", true)
        Menu.ColoredText("", ARGB(255, 255, 255, 255))
        Menu.Checkbox("JungleClearUseR", "Use R", true)
        Menu.Slider("JungleClearMana", "Mana", 50, 0, 100, 1)
    end)

    Menu.Separator()

    Menu.ColumnLayout("c3", "c3", 2, true, function()
        Menu.ColoredText("Prediction Options", 0xFFD700FF, true)
        Menu.Slider("HitChanceQ", "Q HitChance", 0.25, 0, 1, 0.01)
        Menu.Slider("HitChanceQE", "QE HitChance", 0.25, 0, 1, 0.01)

        Menu.NextColumn()

        Menu.ColoredText("Miscellaneous", 0xFFD700FF, true)
        Menu.Checkbox("MiscAntiGap", "Use E Gapclose", false)
        Menu.Checkbox("MiscInterrupt", "Use E Interrupt", false)
        Menu.Checkbox("MiscAnimCancel", "Cancel Melee Q Animation", true)

        Menu.NewTree("ManualQE", "Manual Q + E", function()
            Menu.Keybind("MiscManualQE", "Manual Q + E", string.byte("T"), false)
        end)
    end)

    Menu.Separator()

    Menu.ColumnLayout("c4", "c4", 1, true, function()
        Menu.Checkbox("DrawRangeQ", "Draw Range Q", true)
        Menu.ColorPicker("DrawColorRangeQ", "Range Q Color", ARGB(255, 255, 255, 255))
        Menu.Checkbox("DrawMeleeQ", "Draw Melee Q", true)
        Menu.ColorPicker("DrawColorMeleeQ", "Melee Q Color", ARGB(255, 255, 255, 255)) 
        Menu.Checkbox("DrawMeleeW", "Draw Melee W", true)
        Menu.ColorPicker("DrawColorMeleeW", "Melee W Color", ARGB(255, 255, 255, 255))
        Menu.Checkbox("DrawMeleeE", "Draw Melee E", true)
        Menu.ColorPicker("DrawColorMeleeE", "Melee E Color", ARGB(255, 255, 255, 255)) 
    end)

    Menu.Separator()

    Menu.ColoredText("Script Information", ARGB(255, 255, 255, 255), true)

    Menu.Separator()

    Menu.ColoredText("Version: " .. VERSION, ARGB(255, 255, 255, 255))
    Menu.ColoredText("Last Update: " .. LAST_UPDATE, ARGB(255, 255, 255, 255))

    Menu.Separator()
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

---@type fun(spell: SpellBase, condition: function):boolean
local IsReady = function(spell, condition)
    local isReady = spell:IsReady()
    if condition ~= nil then
        return isReady and (type(condition) == "function" and condition() or type(condition) == "boolean" and condition)
    end
    return isReady
end

---@type fun(slot: number):void
local CastSpell = function(slot, ...)
    local tick = os_clock()
    if LastCastT[slot] + 0.25 < tick then
        if Input.Cast(slot, ...) then
            LastCastT[slot] = tick
            return true
        end
    end
    return false
end

---@type fun(value: number):boolean
local IsEnoughMana = function(value)
    local manaPct = Player.AsAttackableUnit.ManaPercent
    return manaPct > value * 0.01
end

---@type fun(value: number):number
local CalculateCD = function(value)
    local cdPct = Player.AsAI.PercentCooldownMod
    local cdrValue = math_abs(cdPct)
    return value - value * cdrValue
end

---@type fun(value: number):number
local CalculateRemainingCD = function(value)
    local time = os_clock()
    return (value - time) > 0 and value - time or 0
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

---@type fun(slot: number):number
local GetManaCost = function(slot)
    local spellSlot = Player.AsHero:GetSpell(slot)
    return spellSlot.ManaCost
end

---@type fun(spell: table, target: GameObject):number
local GetDamage = function(spell, target)
    local slot = spell.Slot
    local level = Player.AsHero:GetSpell(slot).Level
    local flatAD = Player.AsHero.FlatPhysicalDamageMod
    if spell.Form == "Melee" then
        if slot == _Q then
            local rawDamage = ({55, 95, 135, 175, 215, 255})[level > 0 and level or 1] + 1.2 * flatAD
            return DamageLib.CalculatePhysicalDamage(Player, target, rawDamage)
        end
        if slot == _E then
            local maxHp = target.AsHero.MaxHealth
            local rawDamage = (({8, 10.4, 12.8, 15.2, 17.6, 20})[level > 0 and level or 1] * 0.01) * maxHp + flatAD
            return DamageLib.CalculatePhysicalDamage(Player, target, rawDamage)
        end
    else
        if slot == _Q then
            if spell.Enhanced then
                local rawDamage = ({55, 110, 165, 220, 275, 330})[level > 0 and level or 1] + 1.2 * flatAD
                return DamageLib.CalculatePhysicalDamage(Player, target, (rawDamage + (rawDamage * 0.4)))
            else
                local rawDamage = ({55, 110, 165, 220, 275, 330})[level > 0 and level or 1] + 1.2 * flatAD
                return DamageLib.CalculatePhysicalDamage(Player, target, rawDamage)
            end
        end
    end
end

---@type fun():void
local UpdateSpellCD = function()
    for i = 1, #SpellTable do
        local spell = SpellTable[i]
        if spell then
            spell.CD = CalculateRemainingCD(CD[spell.Form][spell.Slot])
        end
    end
end

----------------------------------------------------------------------------------------------

---@type fun():void
local Combo = function()
    if Orbwalker.IsWindingUp() then return end

    if CurrentForm == "Range" then
        local qTarget = TS:GetTarget(QR.Range)
        local wTarget = TS:GetTarget(WR.Range)
        local qeTarget = TS:GetTarget(QR2.Range)

        if qeTarget and IsReady(QR, function()
            local menuValueQ = GetMenuValue("ComboUseRangeQ")
            local menuValueE = GetMenuValue("ComboUseRangeE")
            local eIsReady = IsReady(ER)
            local targetIsValid = IsValidTarget(qeTarget, QR2.Range)
            local isEnoughMana = GetManaCost(_Q) + GetManaCost(_E)
            return menuValueQ and menuValueE and eIsReady and targetIsValid and isEnoughMana
        end) then
            CastingQE = true
            local hitChance = GetMenuValue("HitChanceQE")
            local predResult = Prediction.GetPredictedPosition(qeTarget, QR2, Player.Position)
            if predResult and predResult.HitChance >= hitChance then
                return CastSpell(_Q, predResult.CastPosition)
            end
        elseif qTarget and IsReady(QR, function()
            local menuValue = GetMenuValue("ComboUseRangeQ")
            local targetIsValid = IsValidTarget(qTarget, QR2.Range)
            local condition = Player.AsHero:GetSpell(_E).Level > 0 and ER.CD > 0 and ER.CD < 3
            return menuValue and targetIsValid and not condition
        end) then
            local hitChance = GetMenuValue("HitChanceQ")
            local predResult = Prediction.GetPredictedPosition(qTarget, QR, Player.Position)
            if predResult and predResult.HitChance > hitChance then
                return CastSpell(_Q, predResult.CastPosition)
            end
        end
        
        if wTarget and IsReady(WR, function()
            local menuValue = GetMenuValue("ComboUseRangeW")
            local canCast = IsValidTarget(qTarget, WR.Range)
            return menuValue and canCast
        end) then
            return CastSpell(_W)
        end

        if GetMenuValue("ComboUseR") then
            if qTarget and IsReady(R) and not IsReady(QR) and not IsReady(WR) and not IsReady(ER) then
                if IsValidTarget(qTarget, QM.Range) and QM.CD < 0.25 and QR.CD > 2 then
                    return CastSpell(_R)
                end
            end
        end
    else
        local qTarget = TS:GetTarget(QM.Range)
        local wTarget = TS:GetTarget(WM.Range)
        local eTarget = TS:GetTarget(EM.Range)

        if qTarget and IsReady(QM, function()
            local menuValue = GetMenuValue("ComboUseMeleeQ")
            local canCast = IsValidTarget(qTarget, QM.Range)
            return menuValue and canCast
        end) then
            return CastSpell(_Q, qTarget)
        end

        if wTarget and IsReady(WM, function()
            local menuValue = GetMenuValue("ComboUseMeleeW")
            local canCast = IsValidTarget(wTarget, WM.Range)
            return menuValue and canCast
        end) then
            return CastSpell(_W)
        end

        if eTarget and IsReady(EM, function()
            local menuValue = GetMenuValue("ComboUseMeleeE")
            local canCast = IsValidTarget(eTarget, EM.Range)
            local isKillable = GetDamage(EM, eTarget) > (eTarget.Health + eTarget.AsAttackableUnit.ShieldAD)
            return menuValue and canCast and Player:GetBuff("jaycehypercharge") == nil or isKillable
        end) then
            return CastSpell(_E, eTarget)
        end

        if GetMenuValue("ComboUseR") then
            if qTarget and IsReady(R) and not IsReady(QM) then
                if Player:EdgeDistance(qTarget) > 300 or QR.CD < 0.25 then
                    return CastSpell(_R)
                end
            end
        end
    end
end

---@type fun():void
local Harass = function()
    if Orbwalker.IsWindingUp() then return end
    if not IsEnoughMana(GetMenuValue("HarassMana")) then return end

    if CurrentForm == "Range" then
        local qTarget = TS:GetTarget(QR.Range)
        local qeTarget = TS:GetTarget(QR2.Range)

        if qeTarget and IsReady(QR, function()
            local menuValue = GetMenuValue("HarassUseRangeQE")
            local eIsReady = IsReady(ER)
            local targetIsValid = IsValidTarget(qeTarget, QR2.Range)
            local isEnoughMana = GetManaCost(_Q) + GetManaCost(_E)
            return menuValue and eIsReady and targetIsValid and isEnoughMana
        end) then
            CastingQE = true
            local hitChance = GetMenuValue("HitChanceQE")
            local predResult = Prediction.GetPredictedPosition(qeTarget, QR2, Player.Position)
            if predResult and predResult.HitChance >= hitChance then
                return CastSpell(_Q, predResult.CastPosition)
            end
        elseif qTarget and IsReady(QR, function()
            local menuValue = GetMenuValue("HarassUseRangeQ")
            local targetIsValid = IsValidTarget(qTarget, QR2.Range)
            local condition = Player.AsHero:GetSpell(_E).Level > 0 and ER.CD > 0 and ER.CD < 3
            return menuValue and targetIsValid and not condition
        end) then
            local hitChance = GetMenuValue("HitChanceQ")
            local predResult = Prediction.GetPredictedPosition(qTarget, QR, Player.Position)
            if predResult and predResult.HitChance > hitChance then
                return CastSpell(_Q, predResult.CastPosition)
            end
        end
    end
end

---@type fun():void
local WaveClear = function()
    if Orbwalker.IsWindingUp() then return end
    if not IsEnoughMana(GetMenuValue("WaveClearMana")) then return end

    if CurrentForm == "Range" then
        if IsReady(QR, function()
            local menuValue = GetMenuValue("WaveClearUseRangeQ")
            return menuValue
        end) then
            local points = {}
            local minionCount = GetMenuValue("WaveClearMinionCountQ")
            local minions = ObjectManager.Get("enemy", "minions")

            for i, minion in pairs(minions) do
                local minion = minion.AsAI
                if minion then
                    local predPos = minion:FastPrediction(QR.Delay)
                    local dist = predPos:Distance(Player.Position)
                    if dist < QR.Range then
                        points[#points + 1] = predPos
                    end
                end
            end

            local bestPos, hitCount = Geometry.BestCoveringCircle(points, 85)
            if bestPos and hitCount >= minionCount then
                return CastSpell(_Q, bestPos)
            end
        end
    end
end

---@type fun():void
local JungleClear = function()
    if Orbwalker.IsWindingUp() then return end
    if not IsEnoughMana(GetMenuValue("JungleClearMana")) then return end

    local myHeroPos = Player.Position
    local mousePos = Renderer.GetMousePos()
    local bestMinion = nil
    local bestMinionHealth = 0
    local minions = ObjectManager.Get("neutral", "minions")
    for i, minion in pairs(minions) do
        local minion = minion.AsAI
        if minion and minion.IsTargetable and minion.MaxHealth > 5 then
            if minion:Distance(myHeroPos) < QM.Range and minion:Distance(mousePos) < 600 then
                if minion.MaxHealth > bestMinionHealth then
                    bestMinion = minion
                    bestMinionHealth = minion.MaxHealth
                end
            end
        end
    end

    if not bestMinion then return end

    if CurrentForm == "Range" then
        if IsReady(QR2, function()
            local menuValueQ = GetMenuValue("JungleClearUseRangeQ")
            local menuValueE = GetMenuValue("JungleClearUseRangeE")
            local targetIsValid = IsValidTarget(bestMinion, QR2.Range)
            local eIsReady = IsReady(ER)
            local isEnoughMana = GetManaCost(_Q) + GetManaCost(_E)
            return menuValueQ and menuValueE and eIsReady and targetIsValid and isEnoughMana
        end) then
            CastingQE = true
            local predResult = bestMinion:FastPrediction(QR2.Delay)
            if predResult then
                return CastSpell(_Q, predResult)
            end
        elseif IsReady(QR, function()
            local menuValue = GetMenuValue("JungleClearUseRangeQ")
            local targetIsValid = IsValidTarget(bestMinion, QR.Range)
            local condition = Player.AsHero:GetSpell(_E).Level > 0 and ER.CD > 0 and ER.CD < 3
            return menuValue and targetIsValid and not condition
        end) then
            local predResult = bestMinion:FastPrediction(QR.Delay)
            if predResult then
                return CastSpell(_Q, predResult)
            end
        end
        
        if IsReady(WR, function()
            local menuValue = GetMenuValue("JungleClearUseRangeW")
            local canCast = IsValidTarget(bestMinion, WR.Range)
            return menuValue and canCast
        end) then
            return CastSpell(_W)
        end

        if GetMenuValue("JungleClearUseR") then
            if IsReady(R) and not IsReady(QR) and not IsReady(WR) and not IsReady(ER) then
                if IsValidTarget(bestMinion, QM.Range) and QM.CD < 0.25 and QR.CD > 2 then
                    return CastSpell(_R)
                end
            end
        end
    else
        if IsReady(QM, function()
            local menuValue = GetMenuValue("JungleClearUseMeleeQ")
            local canCast = IsValidTarget(bestMinion, QM.Range)
            return menuValue and canCast
        end) then
            return CastSpell(_Q, bestMinion)
        end

        if IsReady(WM, function()
            local menuValue = GetMenuValue("JungleClearUseMeleeW")
            local canCast = IsValidTarget(bestMinion, WM.Range)
            return menuValue and canCast
        end) then
            return CastSpell(_W)
        end

        if IsReady(EM, function()
            local menuValue = GetMenuValue("JungleClearUseMeleeE")
            local canCast = IsValidTarget(bestMinion, EM.Range)
            return menuValue and canCast
        end) then
            return CastSpell(_E, bestMinion)
        end

        if GetMenuValue("JungleClearUseR") then
            if IsReady(R) and not IsReady(QM) then
                if Player:EdgeDistance(bestMinion) > 300 or QR.CD < 0.25 then
                    return CastSpell(_R)
                end
            end
        end
    end
end

---@type fun():void
local GateLogic = function()
    local tick = os_clock()
    if CastingQE and CurrentForm == "Range" then
        if IsReady(ER) and GatePosition and GateLastCastT + 0.25 > tick then
            CastSpell(_E, GatePosition)
        end
    end
end

---@type fun(mode: string):boolean
local BlockAttackLogic = function(mode)
    return Orbwalker.BlockAttack(CurrentForm == "Range" and mode == "Combo" and IsReady(R) and QM.CD < 0.25)
end

---@type fun():void
local ManualQE = function()
    if IsReady(QR, function()
        local menuValue = GetMenuValue("MiscManualQE")
        local eIsReady = IsReady(ER)
        local isEnoughMana = GetManaCost(_Q) + GetManaCost(_E)
        return menuValue and eIsReady and isEnoughMana
    end) then
        CastingQE = true
        local mousePos = Renderer.GetMousePos()
        return CastSpell(_Q, mousePos)
    end
end

local CastE = function(target)
    if not target or EM.CD ~= 0 or EM:GetLevel() == 0 then return end
    if CurrentForm == "Range" and IsReady(R) then
        return CastSpell(_R)
    elseif CurrentForm == "Melee" and IsReady(EM) and IsValidTarget(target, EM.Range) then
        return CastSpell(_E, target)
    end
end

----------------------------------------------------------------------------------------------

---@type fun():void
local OnUpdate = function()
    if not GameIsAvailable() then return end

    local activeMode = Orbwalker.GetMode()
    if activeMode == "Combo" then
        Combo()
    elseif activeMode == "Harass" then
        Harass()
    end

    GateLogic()
    ManualQE()
    --BlockAttackLogic(activeMode)
end

---@type fun():void
local OnTick = function()
    local tick = os_clock()
    if TickCount < tick then
        TickCount = tick + 0.1

        UpdateSpellCD()

        local activeMode = Orbwalker.GetMode()
        if activeMode == "Waveclear" then
            WaveClear()
            JungleClear()
        end
    end
end

---@type fun():void
local OnDraw = function()
    local myHeroPos = Player.Position
    if Player.IsVisible and Player.IsOnScreen and not Player.IsDead then
        for i = 1, #DrawSpellTable do
            local spell = DrawSpellTable[i]
            if spell and spell.Form == CurrentForm then
                local menuValue = GetMenuValue("Draw" .. CurrentForm .. spell.SlotString)
                if menuValue then
                    local color = GetMenuValue("DrawColor" .. CurrentForm .. spell.SlotString)
                    if color then
                        Renderer.DrawCircle3D(myHeroPos, spell.Range, 30, 2, color)
                    end
                end
            end
        end
    end
end

---@type fun(unit: GameObject, spell: SpellCast):void
local OnProcessSpell = function(unit, spell)
    if unit.IsMe then
        if spell and spell.SpellData then
            local level = spell.SpellData.Level
            local slot = spell.Slot
            local name = spell.SpellData.Name
            local delay = (CurrentForm == "Range" and slot == _Q and 0.25) or (CurrentForm == "Melee" and slot == _E and 0.25) or 0
            
            if slot >= 0 and slot < 3 then
                CD[CurrentForm][slot] = os_clock() + delay + CalculateCD(BaseCD[CurrentForm][slot][level])
            end

            if name == "JayceShockBlast" then
                local source = spell.StartPos
                local endPos = spell.EndPos
                local blastPosition = Player.Position:Extended(endPos, 500)
                GatePosition = source + (blastPosition - source):Perpendicular2():Normalized() * 60
                GateLastCastT = os_clock()
            end

            if name == "JayceAccelerationGate" then
                GatePosition = nil
                CastingQE = false
            end

            if GetMenuValue("MiscAnimCancel") and name == "JayceToTheSkies" then
                Game.SendChat("/l")
            end

            if name == "JayceStanceGtH" then
                CurrentForm = "Melee"
            elseif name == "JayceStanceHtG" then
                CurrentForm = "Range"
            end
        end
    end
end

---@type fun(target: GameObject):void
local OnPostAttack = function(target)
    if not target.IsHero then return end

    local activeMode = Orbwalker.GetMode()
    if activeMode == "Combo" or activeMode == "Harass" then
        if IsReady(WR, function()
            local menuValue = GetMenuValue(activeMode .. "UseRangeW")
            local canCast = IsValidTarget(target, WR.Range)
            return menuValue and canCast
        end) then
            return CastSpell(_W)
        end
    end
end

---@type fun(unit: AIBaseClient, dash: DashInstance):void
local OnGapclose = function(unit, dash)
    if not unit.IsEnemy or not IsReady(EM) or not IsValidTarget(unit, EM.Range + 100) then return end

    if GetMenuValue("MiscAntiGap") then
        return CastE(unit)
    end
end

---@type fun(unit: AIBaseClient, spell: SpellCast):void
local OnInterruptibleSpell = function(unit, spell)
    if not unit.IsEnemy or not IsReady(EM) or not IsValidTarget(unit, EM.Range + 100) then return end

    if GetMenuValue("MiscInterrupt") then
        return CastE(unit)
    end
end

----------------------------------------------------------------------------------------------

---@type fun():void
function OnLoad()
    EventManager.RegisterCallback(Events.OnUpdate, OnUpdate)
    EventManager.RegisterCallback(Events.OnTick, OnTick)
    EventManager.RegisterCallback(Events.OnDraw, OnDraw)
    EventManager.RegisterCallback(Events.OnProcessSpell, OnProcessSpell)
    EventManager.RegisterCallback(Events.OnPostAttack, OnPostAttack)
    EventManager.RegisterCallback(Events.OnGapclose, OnGapclose)
    EventManager.RegisterCallback(Events.OnInterruptibleSpell, OnInterruptibleSpell)

    return true
end

----------------------------------------------------------------------------------------------
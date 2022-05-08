--[[
     █████  ██      ██ ███████ ████████  █████  ██████  
    ██   ██ ██      ██ ██         ██    ██   ██ ██   ██ 
    ███████ ██      ██ ███████    ██    ███████ ██████  
    ██   ██ ██      ██      ██    ██    ██   ██ ██   ██ 
    ██   ██ ███████ ██ ███████    ██    ██   ██ ██   ██ 
]]

if Player.CharName ~= "Alistar" then return end

local Alistar = {}
local Script = {
    Name = "Shulepin" .. Player.CharName,
    Version = "1.0.1",
    LastUpdated = "22/12/2021",
    Changelog = {
        [1] = "[22/12/2021 - Version 1.0.0]: Initial release",
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

local DebuffData = {
    Ahri =          {{ Name = 'ahriseducedoom',         Type = BuffType.Charm,  Slot = SpellSlots.E }},
    Alistar =       {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Amumu =         {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.Q }, { Name = 'CurseoftheSadMummy',Type = BuffType.Snare,Slot = SpellSlots.R }},
    Anivia =        {{ Name = 'aniviaiced',             Type = BuffType.Stun,   Slot = SpellSlots.Q }},
    Annie =         {{ Name = 'anniepassivestun',       Type = BuffType.Stun,   Slot = -1 }},
    Ashe =          {{ Name = 'AsheR',                  Type = BuffType.Stun,   Slot = SpellSlots.R }},
    AurelionSol =   {{ Name = 'aurelionsolqstun',       Type = BuffType.Stun,   Slot = SpellSlots.Q }},
    Bard =          {{ Name = 'BardQSchacleDebuff',     Type = BuffType.Stun,   Slot = SpellSlots.Q }},
    Blitzcrank =    {{ Name = 'Silence',                Type = BuffType.Silence,Slot = SpellSlots.R }},
    Brand =         {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.Q }},
    Braum =         {{ Name = 'braumstundebuff',        Type = BuffType.Stun,   Slot = -1 }},
    Caitlyn =       {{ Name = 'caitlynyordletrapdebuff',Type = BuffType.Snare,  Slot = SpellSlots.W }},
    Camille =       {{ Name = 'camilleestun',           Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Cassiopeia =    {{ Name = 'CassiopeiaRStun',        Type = BuffType.Stun,   Slot = SpellSlots.R }},
    Chogath =       {{ Name = 'Silence',                Type = BuffType.Silence,Slot = SpellSlots.W }},
    Ekko =          {{ Name = 'ekkowstun',              Type = BuffType.Stun,   Slot = SpellSlots.W }},
    Elise =         {{ Name = 'EliseHumanE',            Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Evelynn =       {{ Name = 'Charm',                  Type = BuffType.Charm,  Slot = SpellSlots.W }},
    FiddleSticks =  {{ Name = 'Flee',                   Type = BuffType.Flee,   Slot = SpellSlots.Q }, { Name = 'DarkWind',Type = BuffType.Silence,Slot = SpellSlots.E }},
    Fiora =         {{ Name = 'fiorawstun',             Type = BuffType.Stun,   Slot = SpellSlots.W }},
    Galio =         {{ Name = 'Taunt',                  Type = BuffType.Taunt,  Slot = SpellSlots.W }},
    Garen =         {{ Name = 'Silence',                Type = BuffType.Silence,Slot = SpellSlots.Q }},
    Gnar =          {{ Name = 'gnarstun',               Type = BuffType.Stun,   Slot = SpellSlots.W }, { Name = 'gnarknockbackcc',Type = BuffType.Stun, Slot = SpellSlots.R }},
    Hecarim =       {{ Name = 'HecarimUltMissileGrab',  Type = BuffType.Flee,   Slot = SpellSlots.R }},
    Heimerdinger =  {{ Name = 'HeimerdingerESpell',     Type = BuffType.Stun,   Slot = SpellSlots.E }, { Name = 'HeimerdingerESpell_ult', Type = BuffType.Stun, Slot = SpellSlots.E, Display = 'Enchanted E' }},
    Irelia =        {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Ivern =         {{ Name = 'IvernQ',                 Type = BuffType.Snare,  Slot = SpellSlots.Q }},
    Jax =           {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Jhin =          {{ Name = 'JhinW',                  Type = BuffType.Snare,  Slot = SpellSlots.W }},
    Jinx =          {{ Name = 'JinxEMineSnare',         Type = BuffType.Snare,  Slot = SpellSlots.E }},
    Karma =         {{ Name = 'karmaspiritbindroot',    Type = BuffType.Snare,  Slot = SpellSlots.W }},
    Kennen =        {{ Name = 'KennenMoSDiminish',      Type = BuffType.Stun,   Slot = -1 }},
    Leblanc =       {{ Name = 'leblanceroot',           Type = BuffType.Snare,  Slot = SpellSlots.E }, { Name = 'leblancreroot', Type = BuffType.Snare, Slot = SpellSlots.E, Display = 'Enchanted E' }},
    Leona =         {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.Q }},
    Lissandra =     {{ Name = 'LissandraWFrozen',       Type = BuffType.Snare,  Slot = SpellSlots.W }, { Name = 'LissandraREnemy2', Type = BuffType.Stun, Slot = SpellSlots.R }},
    Lulu =          {{ Name = 'LuluWTwo',               Type = BuffType.Polymorph, Slot = SpellSlots.W }},
    Lux =           {{ Name = 'LuxLightBindingMis',     Type = BuffType.Snare,  Slot = SpellSlots.Q }},
    Malzahar =      {{ Name = 'MalzaharQMissile',       Type = BuffType.Silence,Slot = SpellSlots.Q }, { Name = 'MalzaharR', Type = BuffType.Suppression, Slot = SpellSlots.R }},
    Maokai =        {{ Name = 'maokaiwroot',            Type = BuffType.Snare,  Slot = SpellSlots.W }, { Name = 'maokairroot', Type = BuffType.Snare, Slot = SpellSlots.R }},
    Mordekaiser =   {{ Name = 'MordekaiserR',           Type = BuffType.CombatDehancer, Slot = SpellSlots.R }},
    Morgana =       {{ Name = 'MorganaQ',               Type = BuffType.Snare,  Slot = SpellSlots.Q }, { Name = 'morganarstun', Type = BuffType.Stun, Slot = SpellSlots.R }},
    Nami =          {{ Name = 'NamiQDebuff',            Type = BuffType.Stun,   Slot = SpellSlots.Q }},
    Nasus =         {{ Name = 'NasusW',                 Type = BuffType.Slow,   Slot = SpellSlots.W }},
    Nautilus =      {{ Name = 'nautiluspassiveroot',    Type = BuffType.Stun,   Slot = -1 }, { Name = 'nautilusanchordragroot', Type = BuffType.Snare, Slot = SpellSlots.R }},
    Neeko =         {{ Name = 'neekoeroot',             Type = BuffType.Snare,  Slot = SpellSlots.E }, { Name = 'neekorstun', Type = BuffType.Stun, Slot = SpellSlots.R }},
    Nocture =       {{ Name = 'Flee',                   Type = BuffType.Flee,   Slot = SpellSlots.E }},
    Nunu =          {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.W }},
    Pantheon =      {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.W }},
    Alistar =         {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Pyke =          {{ Name = 'PykeEMissile',           Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Qiyana =        {{ Name = 'qiyanarstun',            Type = BuffType.Stun,   Slot = SpellSlots.R }, { Name = 'qiyanaqroot', Type = BuffType.Snare, Slot = SpellSlots.Q }},
    Rakan =         {{ Name = 'rakanrdebuff',           Type = BuffType.Charm,  Slot = SpellSlots.R }},
    Rammus =        {{ Name = 'Taunt',                  Type = BuffType.Taunt,  Slot = SpellSlots.E }},
    Renekton =      {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.W }},
    Rengar =        {{ Name = 'RengarEEmp',             Type = BuffType.Snare,  Slot = SpellSlots.E }},
    Riven =         {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.W }},
    Ryze =          {{ Name = 'RyzeW',                  Type = BuffType.Snare,  Slot = SpellSlots.W }},
    Sejuani =       {{ Name = 'sejuanistun',            Type = BuffType.Stun,   Slot = SpellSlots.R }},
    Shaco =         {{ Name = 'shacoboxsnare',          Type = BuffType.Snare,  Slot = SpellSlots.W }},
    Shen =          {{ Name = 'Taunt',                  Type = BuffType.Taunt,  Slot = SpellSlots.E }},
    Skarner =       {{ Name = 'skarnerpassivestun',     Type = BuffType.Stun,   Slot = -1 }, { Name = 'suppression', Type = BuffType.Stun, Slot = SpellSlots.R }},
    Sona =          {{ Name = 'SonaR',                  Type = BuffType.Stun,   Slot = SpellSlots.R }},
    Soraka =        {{ Name = 'sorakaesnare',           Type = BuffType.Snare,  Slot = SpellSlots.E }},
    Sylas =         {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Swain =         {{ Name = 'swaineroot',             Type = BuffType.Snare,  Slot = SpellSlots.E }},
    Syndra =        {{ Name = 'syndraebump',            Type = BuffType.Stun,   Slot = SpellSlots.E }},
    TahmKench =     {{ Name = 'tahmkenchqstun',         Type = BuffType.Stun,   Slot = SpellSlots.Q }, { Name = 'tahmkenchwdevoured', Type = BuffType.Suppression, Slot = SpellSlots.W }},
    Taric =         {{ Name = 'taricestun',             Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Teemo =         {{ Name = 'BlindingDart',           Type = BuffType.Stun,   Slot = SpellSlots.Q }},
    Thresh =        {{ Name = 'threshqfakeknockup',     Type = BuffType.Knockup,Slot = SpellSlots.Q }, { Name = 'threshrslow', Type = BuffType.Slow, Slot = SpellSlots.R }},
    Tryndamere =    {{ Name = 'tryndamerewslow',        Type = BuffType.Slow,   Slot = SpellSlots.W }},
    TwistedFate =   {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Udyr =          {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Urgot =         {{ Name = 'urgotrfear',             Type = BuffType.Fear,   Slot = SpellSlots.R }},
    Varus =         {{ Name = 'varusrroot',             Type = BuffType.Snare,  Slot = SpellSlots.R }},
    Vayne =         {{ Name = 'VayneCondemnMissile',    Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Veigar =        {{ Name = 'veigareventhorizonstun', Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Viktor =        {{ Name = 'viktorgravitonfieldstun',Type = BuffType.Stun,   Slot = SpellSlots.W }, { Name = 'viktorwaugstun', Type = BuffType.Stun, Slot = SpellSlots.W }},
    Warwick =       {{ Name = 'Flee',                   Type = BuffType.Flee,   Slot = SpellSlots.E }, { Name = 'suppression', Type = BuffType.Suppression, Slot = SpellSlots.R }},
    Xayah =         {{ Name = 'XayahE',                 Type = BuffType.Snare,  Slot = SpellSlots.E }},
    Xerath =        {{ Name = 'Stun',                   Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Yuumi =         {{ Name = 'yuumircc',               Type = BuffType.Snare,  Slot = SpellSlots.R }},
    Yasuo =         {{ Name = 'yasuorknockup',          Type = BuffType.Knockup,Slot = SpellSlots.R }},
    Zac =           {{ Name = 'zacqyankroot',           Type = BuffType.Snare,  Slot = SpellSlots.Q }, { Name = 'zachitstun', Type = BuffType.Stun, Slot = SpellSlots.E }},
    Zilean =        {{ Name = 'ZileanStunAnim',         Type = BuffType.Stun,   Slot = SpellSlots.Q }, { Name = 'timewarpslow', Type = BuffType.Slow, Slot = SpellSlots.E }},
    Zoe =           {{ Name = 'zoeesleepstun',          Type = BuffType.Stun,   Slot = SpellSlots.E }},
    Zyra =          {{ Name = 'zyraehold',              Type = BuffType.Snare,  Slot = SpellSlots.E }},
    Senna =         {{ Name = 'sennawroot',             Type = BuffType.Snare,  Slot = SpellSlots.W }},
    Lillia =        {{ Name = 'LilliaRSleep',           Type = BuffType.Drowsy, Slot = SpellSlots.R }},
    Sett =          {{ Name = 'Stun',                   Type = BuffType.Stun, Slot = SpellSlots.E }},
    Yone =          {{ Name = 'yonerstun',              Type = BuffType.Stun, Slot = SpellSlots.R }},
    Viego =         {{ Name = 'ViegoWMis',              Type = BuffType.Stun, Slot = SpellSlots.W }},
    Sylas =         {{ Name = 'Stun',                   Type = BuffType.Stun, Slot = SpellSlots.E }},
    Seraphine =     {{ Name = 'SeraphineERoot',         Type = BuffType.Snare, Slot = SpellSlots.E }, { Name = 'seraphineestun', Type = BuffType.Stun, Slot = SpellSlots.E }},
    Rell =          {{ Name = 'rellestun',              Type = BuffType.Stun, Slot = SpellSlots.E }, { Name = 'Stun', Type = BuffType.Stun, Slot = SpellSlots.W }},
    Aphelios =      {{ Name = 'ApheliosGravitumRoot',   Type = BuffType.Snare, Slot = SpellSlots.Q }},
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
    Options = {},
    LastOptionT = 0,
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

    local text = "Shulepin Alistar"
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

function Alistar.Initialize()
    Alistar.CreateMenu()
    Alistar.CreateSpells()
    Alistar.CreateEvents()

    InfoPanel.AddOption({
        Text = "Use R On CC",
        Type = 2,
        Value = "SAlistar.R.ToggleKey"
    })

    InfoPanel.AddOption({
        Text = "Flash E+Q",
        Type = 2,
        Value = "SAlistar.FlashWQ.Key"
    })
end

function Alistar.CreateSpells()
    Alistar.Spells = {}

    Alistar.Spells["Q"] = Spell.Active({
        Slot            = SpellSlots.Q,
        Range           = 375,
        Delay           = 0.25,
    })

    Alistar.Spells["W"] = Spell.Targeted({
        Slot            = SpellSlots.W,
        Range           = 650,
    })

    Alistar.Spells["E"] = Spell.Active({
        Slot            = SpellSlots.E,
        Range           = 350,
    })

    Alistar.Spells["R"] = Spell.Active({
        Slot            = SpellSlots.R,
    })

    local flashSlot = 0
    for _, slot in ipairs({ SpellSlots.Summoner1, SpellSlots.Summoner2 }) do
        if Player:GetSpell(slot).Name == "SummonerFlash" then
            flashSlot = slot
        end
    end
    if flashSlot > 0 then
        Alistar.Spells["Flash"] = Spell.Skillshot({
            Slot            = flashSlot,
            Range           = 400
        })
    end
end

function Alistar.CreateEvents()
    for name, id in pairs(Events) do
        if Alistar[name] then
            EventManager.RegisterCallback(id, Alistar[name])
        end
    end
end

function Alistar.CreateMenu()
    Menu.RegisterMenu("SAlistar", "Shulepin | Alistar", function()
        Menu.Text("Spell Settings", true)
        Menu.Separator()

        Menu.NewTree("SAlistar.Q", "[Q] Pulverize", function()
            Menu.NewTree("SAlistar.Q.Combo", "Combo Settings", function()
                Menu.Checkbox("SAlistar.Q.Combo.Use", "Use [Q] Pulverize", true)
            end)
            Menu.NewTree("SAlistar.Q.GapClose", "GapClose Settings", function()
                Menu.Checkbox("SAlistar.Q.GapClose.Use", "Use [Q] Pulverize", true)
                AddWhiteListMenu("SAlistar.Q.GapClose.WhiteList.")
            end)
            Menu.NewTree("SAlistar.Q.Interrupt", "Interrupt Settings", function()
                Menu.Checkbox("SAlistar.Q.Interrupt.Use", "Use [Q] Pulverize", true)
                AddWhiteListMenu("SAlistar.Q.Interrupt.WhiteList.")
            end)
            Menu.NewTree("SAlistar.Q.Killsteal", "Kill Steal Settings", function()
                Menu.Checkbox("SAlistar.Q.Killsteal.Use", "Use [Q] Pulverize", true)
                AddWhiteListMenu("SAlistar.Q.Killsteal.WhiteList.")
            end)
            Menu.NewTree("SAlistar.Q.Draw", "Draw Settings", function()
                Menu.Checkbox("SAlistar.Q.Draw.Damage", "Draw [Q] Pulverize Damage", true)
                Menu.Checkbox("SAlistar.Q.Draw.Use", "Draw [Q] Pulverize Range", true)
                Menu.Text("Color - "); Menu.SameLine(); Menu.ColorPicker("SAlistar.Q.Draw.Color", "", 0xFFFFFFFF)
            end)
        end)

        Menu.NewTree("SAlistar.W", "[W] Headbutt", function()
            Menu.NewTree("SAlistar.W.Combo", "Combo Settings", function()
                Menu.Checkbox("SAlistar.W.Combo.Use", "Use [W] Headbutt", true)
            end)
            Menu.NewTree("SAlistar.W.Killsteal", "Kill Steal Settings", function()
                Menu.Checkbox("SAlistar.W.Killsteal.Use", "Use [W] Headbutt", true)
                AddWhiteListMenu("SAlistar.W.Killsteal.WhiteList.")
            end)
            Menu.NewTree("SAlistar.W.Draw", "Draw Settings", function()
                Menu.Checkbox("SAlistar.W.Draw.Damage", "Draw [W] Headbutt Damage", true)
                Menu.Checkbox("SAlistar.W.Draw.Use", "Draw [W] Headbutt Range", true)
                Menu.Text("Color - "); Menu.SameLine(); Menu.ColorPicker("SAlistar.W.Draw.Color", "", 0xFFFFFFFF)
            end)
        end)

        Menu.NewTree("SAlistar.E", "[E] Trample", function()
            Menu.NewTree("SAlistar.E.Combo", "Combo Settings", function()
                Menu.Checkbox("SAlistar.E.Combo.Use", "Use [E] Trample", true)
                Menu.Checkbox("SAlistar.E.Combo.BlockAttack", "Block Attack While [E] Trample", true)
            end)
        end)

        Menu.NewTree("SAlistar.R", "[R] Unbreakable Will", function()
            Menu.Keybind("SAlistar.R.ToggleKey", "Use [R] On CC", string.byte("T"), true, false)
            Menu.NewTree("SAlistar.R.CC", "CC List", function()
                for handle, hero in pairs(ObjectManager.Get("enemy", "heroes")) do
                    local charName = hero.CharName
                    if DebuffData[charName] then
                        for k, buffData in pairs(DebuffData[charName]) do
                            local id = "SAlistar.R.CC." .. charName .. "." ..  buffData.Name
                            local name = charName .. " | " .. SlotToString[buffData.Slot] .. " | " .. buffData.Name
                            Menu.Checkbox(id, name, true)
                        end
                    end
                end
            end)
        end)

        Menu.Separator()
        Menu.Text("Other Settings", true)
        Menu.Separator()

        Menu.NewTree("SAlistar.FlashWQ", "Flash [E] + [Q]", function()
            Menu.Checkbox("SAlistar.FlashWQ.Use", "Enabled", true)
            Menu.Keybind("SAlistar.FlashWQ.Key", "Flash [E] + [Q] Key", string.byte("G"), false, false)
        end)

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

function Alistar.IsReady(spell, mode, checkMana)
    local fastClear = Orbwalker.IsFastClearEnabled()
    local id = "SAlistar." .. spell .. "." .. mode
    return 
        Menu.Get(id .. ".Use") and 
        Alistar.Spells[spell]:IsReady() and
        (checkMana ~= nil and (Menu.Get(id .. ".Mana") / 100) < Player.ManaPercent or fastClear or checkMana == nil)
end

function Alistar.Combo(n)
    if n == 1 and Alistar.IsReady("W", "Combo") and Alistar.IsReady("Q", "Combo") then
        for k, target in ipairs(Alistar.Spells.W:GetTargets()) do
            if target:Distance(Player) > Alistar.Spells.Q.Range then
                return Alistar.Spells.W:Cast(target)
            end
        end
    end
    if n == 2 and Alistar.IsReady("Q", "Combo") then
        for k, target in ipairs(Alistar.Spells.Q:GetTargets()) do
            local predPos = target:FastPrediction(Alistar.Spells.Q.Delay)
            if Alistar.Spells.Q:IsInRange(predPos) then
                return Alistar.Spells.Q:Cast()
            end
        end
    end
    if n == 3 and Alistar.IsReady("E", "Combo") then
        for k, target in ipairs(Alistar.Spells.E:GetTargets()) do
            return Alistar.Spells.E:Cast()
        end
    end
end

function Alistar.KillSteal(n)
    if n == 3 and Alistar.IsReady("Q", "Killsteal") then
        for k, target in ipairs(Alistar.Spells.Q:GetTargets()) do
            local whiteListValue = Menu.Get("SAlistar.Q.Killsteal.WhiteList." .. target.CharName, true)
            if whiteListValue and Alistar.Spells.Q:CanKillTarget(target) then
                return Alistar.Spells.Q:Cast()
            end
        end
    end
    if n == 4 and Alistar.IsReady("W", "Killsteal") then
        for k, target in ipairs(Alistar.Spells.W:GetTargets()) do
            local extraDmg = (Alistar.Spells.Q:IsReady() and Player:Distance(target) > Alistar.Spells.Q.Range) and Alistar.Spells.Q:GetDamage(target) or 0
            local whiteListValue = Menu.Get("SAlistar.W.Killsteal.WhiteList." .. target.CharName, true)
            if whiteListValue and Alistar.Spells.W:CanKillTarget(target, nil, extraDmg) then
                return Alistar.Spells.W:Cast(target)
            end
        end
    end
end

function Alistar.UltimateLogic(n)
    if #ObjectManager.GetNearby("enemy", "heroes") < 1 then return end
    if n == 1 and Alistar.Spells.R:IsReady() and Menu.Get("SAlistar.R.ToggleKey") then
        for k, buff in pairs(Player.Buffs) do
            if buff and buff.Source then
                if Menu.Get("SAlistar.R.CC." .. buff.Source.CharName .. "." ..  buff.Name, true) then
                    return Alistar.Spells.R:Cast()
                end
            end
        end
    end
end

function Alistar.FlashW(n)
    if n == 2 and Alistar.Spells.Flash and Menu.Get("SAlistar.FlashWQ.Use") and Menu.Get("SAlistar.FlashWQ.Key") then
        Orbwalker.Orbwalk(Renderer.GetMousePos())
        if Alistar.Spells.Flash:IsReady() and Alistar.Spells.W:IsReady() and Alistar.Spells.Q:IsReady() then
            local flashRange = Alistar.Spells.W.Range - 35 + Alistar.Spells.Flash.Range
            local target = TargetSelector:GetTarget(flashRange)
            if target and not Alistar.Spells.W:IsInRange(target) then
                local position = Player.ServerPos:Extended(target.ServerPos, Alistar.Spells.Flash.Range)
                if Alistar.Spells.Flash:Cast(position) then
                    return Alistar.Spells.W:Cast(target)
                end 
            end
        end
    end
end

function Alistar.OnNormalPriority(n)
    if not Game.CanSendInput() then return end 
    if not Orbwalker.CanCast() then return end

    local orbMode = Alistar[Orbwalker.GetMode()]
    if orbMode then
        orbMode(n)
    end

end

function Alistar.OnExtremePriority(n)
    if not Game.CanSendInput() then return end

    Alistar.UltimateLogic(n)
    Alistar.FlashW(n)
    Alistar.KillSteal(n)
end

local buffCount = 0
local buffCountT = 0
function Alistar.OnPreAttack(args)
    if Menu.Get("SAlistar.E.Combo.BlockAttack") then
        local orbMode = Orbwalker.GetMode()
        if orbMode == "Combo" then
            local enemyAround = false
            for k, enemy in pairs(ObjectManager.GetNearby("enemy", "heroes")) do
                if Player:Distance(enemy) < Alistar.Spells.E.Range then
                    enemyAround = true
                    break
                end
            end
            if enemyAround then
                local buff = Player:GetBuff("AlistarE")
                if buff then
                    local time = Game.GetTime()
                    local latency = Game.GetLatency()
                    local attackCastDelay = Player.AttackCastDelay + (latency / 1000)
                    if buffCount ~= buff.Count and buffCountT + 0.5 < time then
                        buffCountT = time
                        buffCount = buff.Count
                    end

                    local timeSinceLastStack = time - buffCountT
                    if buffCount >= 4 and attackCastDelay > timeSinceLastStack then
                        --
                    else
                        args.Process = false
                    end
                end
            end
        end
    end
end

function Alistar.OnDraw()
    for k, spell in pairs({ "Q", "W" }) do
        if Menu.Get("SAlistar." .. spell .. ".Draw.Use") and Alistar.Spells[spell]:IsReady() then
            local color = Menu.Get("SAlistar." .. spell .. ".Draw.Color")
            Renderer.DrawCircle3D(Player.Position, Alistar.Spells[spell].Range, 10, 3, color)
        end
    end

    if Menu.Get("SAlistar.FlashWQ.Key") then
        local Q = Alistar.Spells.Q
        local W = Alistar.Spells.W
        local flash = Alistar.Spells.Flash
        if not flash then return end
        if W:IsReady() and Q:IsReady() and flash:IsReady() then
            return Renderer.DrawCircle3D(Player.Position, flash.Range + W.Range, 10, 3, 0xFF0000FF)
        end
    end
end

function Alistar.OnDrawDamage(target, dmgList)
    local totalDamage = 0

    if Alistar.Spells.Q:IsReady() and Menu.Get("SAlistar.Q.Draw.Damage") then
        totalDamage = totalDamage + Alistar.Spells.Q:GetDamage(target)
    end

    if Alistar.Spells.W:IsReady() and Menu.Get("SAlistar.W.Draw.Damage") then
        totalDamage = totalDamage + Alistar.Spells.W:GetDamage(target)
    end

    table.insert(dmgList, totalDamage)
end

function Alistar.OnGapclose(unit, dashData)
    if unit.IsAlly then return end
    if unit.CharName == "MasterYi" then return end
    if dashData.Invulnerable then return end
    if Alistar.IsReady("Q", "GapClose") then
        local shouldCast = false
        local whiteListValue = Menu.Get("SAlistar.Q.GapClose.WhiteList." .. unit.CharName, true)
        if whiteListValue and dashData.Slot > -1 then
            if Player.Position:Distance(dashData:GetPosition(Alistar.Spells.Q.Delay)) < Alistar.Spells.Q.Range then
                shouldCast = true
            end
            if shouldCast then
                return Alistar.Spells.Q:Cast()
            end
        end
    end
end

function Alistar.OnInterruptibleSpell(unit, spell, danger, endTime, canMoveDuringChannel)
    if unit.IsAlly then return end
    if Alistar.IsReady("Q", "Interrupt") then
        local whiteListValue = Menu.Get("SAlistar.Q.Interrupt.WhiteList." .. unit.CharName, true)
        if whiteListValue and danger > 4 and Alistar.Spells.Q:IsInRange(unit) then
            return Alistar.Spells.Q:Cast()
        end
    end
end

function Alistar.OnProcessSpell(unit, spell)
    if unit.IsMe and spell.SpellData and spell.SpellData.Name == "Headbutt" and spell.Target and spell.Target.IsHero then
        local extraDmg = (Alistar.Spells.Q:IsReady() and Player:Distance(spell.Target) > Alistar.Spells.Q.Range) and Alistar.Spells.Q:GetDamage(spell.Target) or 0
        local canKill = Alistar.Spells.W:CanKillTarget(spell.Target, nil, extraDmg)
        if Orbwalker.GetMode() == "Combo" or Menu.Get("SAlistar.FlashWQ.Key") or canKill then
            return delay(spell.CastDelay, function() return Alistar.Spells.Q:Cast() end)
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
    Alistar.Initialize()
    return true
end

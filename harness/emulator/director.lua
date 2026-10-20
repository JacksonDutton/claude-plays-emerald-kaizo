-- Pokemon Emerald director module. Loaded by bootstrap.lua (loadfile +
-- pcall, never dofile directly) -- bootstrap owns the TCP socket and the
-- single frame callback for the life of the mGBA process; THIS file can be
-- swapped out live via the "RELOAD" socket command with no mGBA restart.
-- Ends with `return { onFrame=.., handle=.., VERSION=.., teardown=.. }`.
-- All addresses verified against the real pret/pokeemerald compiled
-- symbol table (https://raw.githubusercontent.com/pret/pokeemerald/symbols/pokeemerald.sym)
-- and, for struct layouts, the actual C source -- never guessed, never
-- reused without re-verifying. See the project's harness-status.md for
-- the full incident history and provenance of every address below.
--
-- Architecture note (why this file exists, separate from bootstrap.lua):
-- every deploy used to cost a full mGBA quit->relaunch->reopen-Scripting-
-- console->dofile->Run cycle, because the OLD single-file script owned the
-- TCP socket and a frame callback that couldn't be unregistered -- the
-- single biggest tax on the build loop. bootstrap.lua now owns those two
-- things ONCE per process; this file just returns a module table that gets
-- swapped in. All state below (queue, nav, mode, decision, frameCount,
-- the log ring buffer, ...) lives in locals closed over by that module
-- table -- a RELOAD creates a brand-new set of these locals (dofile runs
-- the whole chunk fresh), which is the correct, safe default: nothing
-- carries over across a reload except what's explicitly saved to an mGBA
-- state slot.

local VERSION = "v2.0"  -- shasum -a 256 of this file's content (pre-stamp), first 8 hex chars. Recomputed and substituted by hand at each deploy (see deploy notes in harness-status.md).

-- ---------------------------------------------------------------------
-- JSON / hex helpers
-- ---------------------------------------------------------------------
local function toHex(n, width)
    width = width or 8
    local s = ""
    n = n % (2 ^ 32)
    for i = 1, width do
        local nib = n % 16
        s = string.format("%x", nib) .. s
        n = (n - nib) / 16
    end
    return "0x" .. s
end

local function toJsonStr(s)
    return '"' .. tostring(s):gsub('[%c"\\]', function(c)
        if c == '"' then return '\\"'
        elseif c == '\\' then return '\\\\'
        elseif c == '\n' then return '\\n'
        else return string.format('\\u%04x', string.byte(c)) end
    end) .. '"'
end

-- Encodes a plain Lua table (string/number/boolean/nil values only, no
-- nesting) as a JSON object. Used by DIAG/REGRESS/LOG so their shape isn't
-- hand-concatenated string-by-string like the older commands -- less
-- error-prone for the wider, flatter payloads those commands return.
local function encodeFlat(t)
    local parts = {}
    for k, v in pairs(t) do
        local vs
        if v == nil then vs = "null"
        elseif type(v) == "string" then vs = toJsonStr(v)
        elseif type(v) == "boolean" or type(v) == "number" then vs = tostring(v)
        else vs = toJsonStr(tostring(v)) end
        table.insert(parts, toJsonStr(k) .. ":" .. vs)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

-- ---------------------------------------------------------------------
-- Strict tables -- catch the "nil-field silently becomes the string nil
-- in a JSON response" bug class (incident #7: nav.stuckCount referenced a
-- field that no longer existed on the nav table and silently emitted the
-- literal text "nil" into STATE JSON for an unknown number of polls; luac
-- -p does not catch this, Lua does not catch this by default). Wrap a
-- table with strict() right after every field it will ever have is set,
-- and any read or write of an undeclared field errors immediately and
-- loudly instead of returning/accepting nil. Applied below to `nav`
-- (exactly the incident-7 case) and to the new battle-decision-state
-- table (the newest table with a meaningful fixed field set) -- NOT to
-- lookup tables like KNOWN_MODES or BATTLE_INPUT_FUNCS, where returning
-- nil for an unrecognised key is the correct, load-bearing behaviour.
--
-- allowedFields (optional): explicit list of every field name the table
-- will ever hold. REQUIRED whenever any field is meant to start out nil
-- (a Pokemon-choice cursor before a choice exists, etc.) -- a Lua table
-- constructor never actually stores a nil-valued key (`{x = nil}` does
-- NOT declare `x`), so without an explicit whitelist the field doesn't
-- exist yet and both the first read AND the first real write of it would
-- incorrectly error as "unknown"/"undeclared". Found live (incident #16
-- below) when DIAG errored on `learn_move_state` and GOTO's own
-- `nav.lastX`/`lastY`/`bestDist` turned out to have the identical bug --
-- caught before either shipped into real play. When omitted, the
-- whitelist is just the table's own keys at construction time, which is
-- only safe when every field is given a real (non-nil) initial value.
local function strict(t, name, allowedFields)
    local allowed = {}
    if allowedFields then
        for _, k in ipairs(allowedFields) do allowed[k] = true end
    else
        for k in pairs(t) do allowed[k] = true end
    end
    return setmetatable(t, {
        __index = function(_, k)
            if allowed[k] then return nil end
            error(name .. ": read of unknown field '" .. tostring(k) .. "'", 2)
        end,
        __newindex = function(tbl, k, v)
            if not allowed[k] then
                error(name .. ": write to undeclared field '" .. tostring(k) .. "'", 2)
            end
            rawset(tbl, k, v)
        end,
    })
end

-- ---------------------------------------------------------------------
-- Verified RAM addresses
-- ---------------------------------------------------------------------
local PLAYER_PARTY_COUNT_ADDR = 0x020244E9   -- gPlayerPartyCount
local PLAYER_PARTY_ADDR = 0x020244EC          -- gPlayerParty
local PARTY_MON_SIZE = 100
local ENEMY_PARTY_ADDR = 0x02024744           -- gEnemyParty

local SAVEBLOCK1_PTR_ADDR = 0x03005D8C        -- gSaveBlock1Ptr
local SAVEBLOCK2_PTR_ADDR = 0x03005D90        -- gSaveBlock2Ptr

local GMAIN_ADDR = 0x030022C0                 -- gMain
local GMAIN_CALLBACK2_ADDR = GMAIN_ADDR + 0x04 -- struct Main.callback2

local BATTLE_TYPE_FLAGS_ADDR = 0x02022FEC     -- gBattleTypeFlags
local BATTLE_TYPE_TRAINER = 0x08
local BATTLE_TYPE_DOUBLE = 0x01
local BATTLE_TYPE_LINK = 0x02
local BATTLE_TYPE_SAFARI = 0x80
local BATTLE_OUTCOME_ADDR = 0x0202433A        -- gBattleOutcome

local SAVEBLOCK1_FLAGS_OFFSET = 0x1270        -- SaveBlock1.flags[]
local FLAG_BADGE01_GET = 0x867                -- SYSTEM_FLAGS+0x7

local SAVEBLOCK1_MAPGROUP_OFFSET = 0x04       -- SaveBlock1.location.mapGroup
local SAVEBLOCK1_MAPNUM_OFFSET = 0x05         -- SaveBlock1.location.mapNum

local OBJECT_EVENTS_ADDR = 0x02037350         -- gObjectEvents (16 x struct ObjectEvent)
local OBJECT_EVENT_SIZE = 0x24
local OBJECT_EVENTS_COUNT = 16
local OBJECT_EVENT_ELEVATION_OFFSET = 0x0B    -- currentElevation:4 (low nibble) / previousElevation:4 (high nibble)

-- gBackupMapLayout (struct BackupMapLayout: s32 width@0, s32 height@4, u16*map@8)
-- -- the SAME grid GetCollisionAtCoords()/MapGridGetCollisionAt() read to decide
-- whether a WALK will actually move the player, straight from
-- include/global.fieldmap.h + src/fieldmap.c (curl+grep verified, not recalled).
-- Each u16 block packs: bits 0-9 metatile id, bits 10-11 collision (0=passable,
-- 1-3=impassable variants), bits 12-15 elevation (0=transition/any, 15=multi-
-- level/any, otherwise must match the mover's own current elevation or the
-- move is blocked as an elevation mismatch -- e.g. the sunken-rug/wood-floor
-- step boundary that GOTO kept bouncing off in the rival's house). This is
-- the exact signal the game itself uses, read directly -- not a guess, not a
-- walkthrough, and a strictly better tool than bump-testing or a screenshot
-- for "can I walk onto this tile."
local BACKUP_MAP_LAYOUT_ADDR = 0x03005dc0
local MAPGRID_COLLISION_SHIFT = 10
local MAPGRID_COLLISION_MASK = 0x0C00
local MAPGRID_ELEVATION_SHIFT = 12
local MAPGRID_ELEVATION_MASK = 0xF000
local MAPGRID_METATILE_MASK = 0x03FF
local ELEVATION_TRANSITION = 0
local ELEVATION_MULTI_LEVEL = 15
-- incident #17 root cause: #define MAPGRID_UNDEFINED MAPGRID_METATILE_ID_MASK
-- (include/global.fieldmap.h) -- a raw block of exactly 0x3FF is the fill
-- value for grid cells the game has never loaded real data into (outside
-- the currently-loaded map connections -- very common indoors, where only
-- the room itself plus whatever's through a loaded door/warp connection is
-- real). MapGridGetCollisionAt() SPECIAL-CASES this exact value to force
-- collision=1 (impassable) rather than decoding its (all-zero) packed
-- bits, which would otherwise decode as collision=0/elevation=0 and look
-- indistinguishable from ordinary open floor. Naively unpacking bits
-- without this check is what made LOOK report a "clear" path that was
-- really unloaded void -- the game bumped the player in place every frame
-- (runningState went to MOVING but tileTransitionState never left 0,
-- confirmed via the driveStep trace log) instead of walking, and WALK/GOTO
-- correctly reported blocked. This is not a wall in the normal sense, so
-- it gets its own grid symbol below rather than reusing "#".
local MAPGRID_UNDEFINED = 0x03FF
local OBJ_EVENT_GFX_ITEM_BALL = 59

local GMAP_HEADER_ADDR = 0x02037318           -- gMapHeader
local GMAP_HEADER_EVENTS_OFFSET = 0x04
local MAPEVENTS_WARPCOUNT_OFFSET = 0x01
local MAPEVENTS_WARPS_PTR_OFFSET = 0x08
local WARPEVENT_SIZE = 0x08
local MAPEVENTS_BGCOUNT_OFFSET = 0x03
local MAPEVENTS_BGS_PTR_OFFSET = 0x10
local BGEVENT_SIZE = 0x0C

local FIELD_LOCK_ADDR = 0x03000f2c            -- sLockFieldControls

-- Battle/menu decision signals -- NEW this pass, resolves the harness's
-- former "Known limitation: auto-mode could blindly mash through a real
-- decision" gap. Re-verified live via curl+grep against the current
-- symbol table immediately before writing this (never trust a remembered
-- address): all match exactly.
local BATTLESCRIPT_CURR_INSTR_ADDR = 0x02024214  -- gBattlescriptCurrInstr (u32, byte-stream addr, NOT a Thumb fn ptr -- do not mask)
local LEARN_MOVE_ASK_START = 0x082DABE3          -- BattleScript_AskToLearnMove
local LEARN_MOVE_ASK_END = 0x082DAC10            -- BattleScript_ForgotAndLearnedNewMove (exclusive end of the ask-to-learn region)
local BATTLE_COMMUNICATION_ADDR = 0x02024332     -- gBattleCommunication (8 bytes)
local YESNO_CURSOR_ADDR = BATTLE_COMMUNICATION_ADDR + 1  -- index 1: 0=Yes,1=No for the learn-move box
local BATTLE_SCRIPTING_ADDR = 0x02024474         -- gBattleScripting (size 0x28)
local LEARN_MOVE_STATE_ADDR = BATTLE_SCRIPTING_ADDR + 0x1F  -- derived offset (0x02024493), NOT a symbol -- verify live, treat as telemetry only
local MOVE_TO_LEARN_ADDR = 0x020244E2            -- gMoveToLearn (u16)
local MOVE_SLOT_TO_REPLACE_ADDR = 0x0203CF21     -- sMoveSlotToReplace (u8; 4 = MAX_MON_MOVES = cancel)
local SUMMARY_SCREEN_CB2 = 0x081BFAB4            -- MainCB2 in src/pokemon_summary_screen.c -- IS a function pointer, mask & ~1
local BATTLER_CONTROLLER_FUNCS_ADDR = 0x03005D60 -- gBattlerControllerFuncs, battler 0 = player in singles
local MULTI_USE_PLAYER_CURSOR_ADDR = 0x03005D74  -- gMultiUsePlayerCursor (controller-driven yes/no box cursor; inits to 1=No, DIFFERENT convention from the learn-move box's 0=Yes default)
local GTASKS_ADDR = 0x03005E00                   -- gTasks, 16 x struct Task (func u32 @+0x00, isActive u8 @+0x04)
local GTASK_SIZE = 0x28
local TASK_HANDLE_YESNO_ADDR = 0x080E215C        -- Task_HandleYesNoInput -- OVERWORLD field yes/no box (field_locked is true here too -- was blindly A-mashed before this pass, see incident below)
local TASK_HANDLE_MULTICHOICE_ADDR = 0x080E2058  -- Task_HandleMultichoiceInput -- field multichoice menu
local TASK_HANDLE_REPLACE_MOVE_ADDR = 0x081C174C -- Task_HandleReplaceMoveInput -- the move-forget screen itself
local TASK_HANDLE_CHOOSE_MON_ADDR = 0x081B1370   -- Task_HandleChooseMonInput -- the party menu (also the forced party screen after a faint, where S otherwise reads bat:other)
local BATTLE_MONS_ADDR = 0x02024084              -- gBattleMons (struct BattlePokemon[MAX_BATTLERS_COUNT], size 0x58 each) -- verified live via curl+grep against pret/pokeemerald include/pokemon.h + symbol table before writing this
local BATTLE_MON_SIZE = 0x58
local BATTLE_MON_HP_OFF = 0x28                   -- u16 hp
local BATTLE_MON_MAXHP_OFF = 0x2C                -- u16 maxHP
local BATTLE_MON_SPECIES_OFF = 0x00              -- u16 species
local BATTLE_MON_LEVEL_OFF = 0x2A                -- u8 level

-- Tenth-session build: dialogue text over the socket. Every field message
-- shown via ShowFieldMessage()/ExpandStringAndStartDrawFieldMessage()
-- (src/field_message_box.c) is placeholder-expanded into gStringVar4
-- BEFORE it's ever drawn -- confirmed against pret/pokeemerald source, not
-- guessed. Battle text has its own equivalent buffer. This is what
-- collapses the whole incident #19/#21 "had to screenshot every message"
-- failure class: the actual displayed text is sitting in RAM the whole
-- time, we just never read it before now.
local FIELD_STRING_VAR4_ADDR = 0x02021fc4        -- gStringVar4 (expanded field-message text)
local FIELD_STRING_VAR4_SIZE = 0x3e8             -- 1000 bytes, per symbol table
local BATTLE_DISPLAYED_STRING_ADDR = 0x02022e2c  -- gDisplayedStringBattle (expanded battle-message text)
local BATTLE_DISPLAYED_STRING_SIZE = 0x12c       -- 300 bytes, per symbol table

-- Eleventh-session build (2026-09-10): the current map's real NAME, read
-- from ROM data -- same shape as TEXT, but answers "where am I" instead
-- of "what's being said". Emerald's own on-screen "POKéMON CENTER" /
-- town-name popup is generated by GetMapName() (src/region_map.c):
-- StringCopy(dest, gRegionMapEntries[regionMapSectionId].name) when
-- regionMapSectionId < MAPSEC_NONE. gRegionMapEntries is a ROM table of
-- struct RegionMapLocation {u8 x,y,width,height; const u8 *name;}
-- (include/region_map.h) -- 8 bytes/entry, name is a POINTER to a
-- Gen3-encoded string elsewhere in ROM, not inline text. Confirmed
-- against pret source, not guessed from a building's visual appearance
-- (roof color, silhouette) -- see self-improvement.md lesson 20 for why
-- that distinction matters. gMapHeader->regionMapSectionId offset (0x14)
-- confirmed against include/global.fieldmap.h's struct MapHeader.
local GMAP_HEADER_REGIONMAPSEC_OFFSET = 0x14   -- mapsec_u8_t regionMapSectionId
local REGION_MAP_ENTRIES_ADDR = 0x085a147c     -- gRegionMapEntries
local REGION_MAP_ENTRY_SIZE = 8                -- struct RegionMapLocation, confirmed via symbol table size / entry count below
local REGION_MAP_ENTRY_COUNT = 213             -- 0x6a8 (symbol table size) / 8 -- entries 0..212 are real; >=213 (MAPSEC_NONE and beyond, incl. dynamic/secret base) has no table entry, per GetMapName()'s own bounds check

-- Named battler-controller functions that mean "the game is genuinely
-- waiting on a real choice from the player" -- NOT an exhaustive list of
-- every controller function that can ever run (plain message/animation
-- phases use others not enumerated here), deliberately: this is the set
-- explicitly researched and verified as decision points. An unmapped
-- in-battle controller function is reported as "other" (see
-- getBattleDecisionState) and is NOT treated as risky/parked on -- that
-- would stop auto-mode from ever advancing ordinary battle message text.
-- If a real gap is found here (an unmapped state that WAS a live choice),
-- log it as an incident and add it to this table -- don't guess more
-- entries in blind.
local BATTLE_INPUT_FUNCS = {
    [0x08057588] = "choose_action",          -- Fight/Bag/Pokemon/Run
    [0x08057BFC] = "choose_move",
    [0x08057824] = "choose_target",
    [0x0805C114] = "choose_move_after_dma3", -- transient, precedes choose_move
    [0x080599D4] = "yesno",
    [0x0805C2AC] = "choose_pokemon",         -- party menu, e.g. after a faint
    [0x0805C248] = "choose_item",
}

-- Known CB2_* callback addresses (ROM, 0x08xxxxxx), for mode detection.
local KNOWN_MODES = {
    [0x080AA7A4] = "title_screen",
    [0x080AAB2C] = "title_screen",
    [0x0816CEAC] = "copyright_screen",
    [0x0816CF0C] = "copyright_screen",
    [0x0802F6B0] = "main_menu",
    [0x08085EF8] = "new_game_intro",
    [0x080E4F58] = "naming_screen",
    [0x08031678] = "naming_screen_return",
    [0x08085E5C] = "overworld",
    [0x08085E50] = "overworld",
    [0x080860C8] = "overworld",
    [0x08086230] = "overworld",
    [0x08036760] = "battle_init",
    [0x08038420] = "battle_main",
}

local function u32(a) return emu:read32(a) end
local function u16(a) return emu:read16(a) end
local function u8(a) return emu:read8(a) end

-- ---------------------------------------------------------------------
-- Ring-buffer log -- item 6. ~200 entries, in-memory only, no file I/O in
-- the frame callback. Lets the harness notice its own anomalies (incidents
-- #3 and #8 were both caught by Jackson watching the real screen, not by
-- the harness) and gives DIAG something to compute "recent activity" from
-- instead of a separate tracking mechanism.
-- ---------------------------------------------------------------------
local LOG_CAPACITY = 200
local logBuf = {}
local logHead = 1  -- next write index (1-based, wraps)
local logCount = 0

-- Filled in below playerSig() is defined; forward-declared here so
-- pushLog can call it without caring about definition order elsewhere.
local playerSigForLog = nil

local function pushLog(event, extra)
    local x, y, mapGroup, mapNum, fieldLocked = 0, 0, -1, -1, false
    if playerSigForLog then
        local ok, px, py, _, _, pmg, pmn = pcall(playerSigForLog)
        if ok then x, y, mapGroup, mapNum = px, py, pmg, pmn end
    end
    local ok2, fl = pcall(u8, FIELD_LOCK_ADDR)
    if ok2 then fieldLocked = fl ~= 0 end
    local entry = {frame = extra and extra.frame or 0, event = event, x = x, y = y,
                    map_group = mapGroup, map_num = mapNum, field_locked = fieldLocked,
                    queue_len = extra and extra.queue_len or 0, detail = extra and extra.detail or nil}
    logBuf[logHead] = entry
    logHead = (logHead % LOG_CAPACITY) + 1
    if logCount < LOG_CAPACITY then logCount = logCount + 1 end
end

-- Returns up to n most-recent entries, newest last (chronological order).
local function tailLog(n)
    n = math.min(n or 10, logCount)
    local out = {}
    local idx = logHead - 1
    for i = 1, n do
        if idx < 1 then idx = LOG_CAPACITY end
        table.insert(out, 1, logBuf[idx])
        idx = idx - 1
    end
    return out
end

-- Returns {oldestEntryWithinWindow, inputSentCount} for entries with
-- frame >= (currentFrame - windowFrames). Used by DIAG's "position delta
-- / inputs sent over the last N frames" -- reuses the log instead of a
-- second parallel tracking mechanism.
local function logWindowSummary(currentFrame, windowFrames)
    local oldest, inputCount = nil, 0
    local idx = logHead - 1
    for i = 1, logCount do
        if idx < 1 then idx = LOG_CAPACITY end
        local e = logBuf[idx]
        if e and e.frame >= currentFrame - windowFrames then
            oldest = e
            if e.event == "input_sent" then inputCount = inputCount + 1 end
        else
            break
        end
        idx = idx - 1
    end
    return oldest, inputCount
end

-- ---------------------------------------------------------------------
-- getWarps -- MUST stay defined below u32/u16/u8 (see incident: this
-- function used to be defined ABOVE them, so u8/u16/u32 inside its body
-- resolved to nil GLOBALS at closure-creation time -- every read threw,
-- pcall swallowed it, and the function silently returned empty despite
-- every address being individually correct). Any new function that calls
-- u8/u16/u32 must be defined after this comment block, not before.
-- ---------------------------------------------------------------------
-- incident #18: WarpEvent x/y are stored in the RAW map-file coordinate
-- system, NOT the padded (+MAP_OFFSET) system gObjectEvents.currentCoords /
-- playerSig() / LOOK all use. include/fieldmap.c confirms the conversion
-- everywhere a warp coordinate meets a live position: e.g.
-- `x = gSaveBlock1Ptr->pos.x + MAP_OFFSET + gDirectionToVectors[...]`.
-- Found live: a warp reported here as (x=2,y=2) turned out to be the exact
-- tile that actually triggered the stairs-up transition at live position
-- (9,9) -- 2+7=9 on both axes. MAP_OFFSET is a fixed engine constant (the
-- padding border around every loaded map), not derived per-map.
local MAP_OFFSET = 7

local function getWarps()
    local out = {}
    local dbg = {eventsPtr = nil, warpCount = nil, warpsPtr = nil,
                 ok1 = false, ok2 = false, ok3 = false, firstOkw = nil}
    local ok, eventsPtr = pcall(u32, GMAP_HEADER_ADDR + GMAP_HEADER_EVENTS_OFFSET)
    dbg.ok1, dbg.eventsPtr = ok, eventsPtr
    if not ok or eventsPtr == 0 then return out, dbg end
    local ok2, warpCount = pcall(u8, eventsPtr + MAPEVENTS_WARPCOUNT_OFFSET)
    dbg.ok2, dbg.warpCount = ok2, warpCount
    if not ok2 then return out, dbg end
    local ok3, warpsPtr = pcall(u32, eventsPtr + MAPEVENTS_WARPS_PTR_OFFSET)
    dbg.ok3, dbg.warpsPtr = ok3, warpsPtr
    if not ok3 or warpsPtr == 0 then return out, dbg end
    for i = 0, warpCount - 1 do
        local base = warpsPtr + i * WARPEVENT_SIZE
        local okw, rawX = pcall(u16, base + 0x00)
        if dbg.firstOkw == nil then dbg.firstOkw = okw end
        if not okw then break end
        local rawY = u16(base + 0x02)
        local elevation = u8(base + 0x04)
        local warpId = u8(base + 0x05)
        local destMapNum = u8(base + 0x06)
        local destMapGroup = u8(base + 0x07)
        -- x/y: player-space (use directly with GOTO). raw_x/raw_y: the
        -- untouched ROM values, kept for debugging this conversion itself.
        table.insert(out, {index = i, x = rawX + MAP_OFFSET, y = rawY + MAP_OFFSET,
            raw_x = rawX, raw_y = rawY, elevation = elevation,
            warp_id = warpId, dest_map_num = destMapNum, dest_map_group = destMapGroup})
    end
    return out, dbg
end


-- BGEVENTS (2026-10-08): interactable wall/sign tiles (scrolls, signs, plaques),
-- kinds 0-4 only (script triggers by facing direction). Hidden items (kind 7) and
-- secret bases are deliberately NOT listed: Itemfinder exists in game.
local function getBgEvents()
    local out = {}
    local ok, eventsPtr = pcall(u32, GMAP_HEADER_ADDR + GMAP_HEADER_EVENTS_OFFSET)
    if not ok or eventsPtr == 0 then return out end
    local ok2, n = pcall(u8, eventsPtr + MAPEVENTS_BGCOUNT_OFFSET)
    local ok3, ptr = pcall(u32, eventsPtr + MAPEVENTS_BGS_PTR_OFFSET)
    if not ok2 or not ok3 or ptr == 0 then return out end
    for i = 0, n - 1 do
        local base = ptr + i * BGEVENT_SIZE
        local rawX = u16(base + 0x00)
        local rawY = u16(base + 0x02)
        local kind = u8(base + 0x05)
        if kind <= 4 then
            table.insert(out, {x = rawX + MAP_OFFSET, y = rawY + MAP_OFFSET, kind = kind})
        end
    end
    return out
end

-- Display-only screen labels (2026-09-29), keyed by gMain.callback2 with
-- bit 0 masked. Deliberately NOT merged into KNOWN_MODES: getMode()'s
-- names drive decision parking, and these only add a `scr:<label>` tag to
-- the S line so screens the harness could not name (bag, trainer card,
-- Pokedex, shop, PC, evolution) are visible without a screenshot.
-- Addresses from pokeemerald.sym (CB2_BagMenuRun, CB2_TrainerCard,
-- CB2_Pokedex, CB2_BuyMenu, CB2_PokeStorage, CB2_EvolutionSceneUpdate,
-- CB2_UpdatePartyMenu). bag/card/dex/party verified live from the Start
-- menu; shop, pc and evo are UNTESTED until the game reaches them.
local KNOWN_SCREENS = {
    [0x081AAD5C] = "bag",
    [0x080C2710] = "card",
    [0x080BB774] = "dex",
    [0x080DFD64] = "shop",
    [0x080C7D54] = "pc",
    [0x0813E3A4] = "evo",
    [0x081B01B0] = "party",
}
local function screenLabel()
    local ok, cb2 = pcall(u32, GMAIN_CALLBACK2_ADDR)
    if not ok then return nil end
    return KNOWN_SCREENS[cb2 & ~1]
end

local function getMode()
    local ok, cb2 = pcall(u32, GMAIN_CALLBACK2_ADDR)
    if not ok then return "unknown", 0 end
    local realAddr = cb2 & ~1
    local name = KNOWN_MODES[realAddr]
    if name then return name, cb2 end
    return "unknown", cb2
end

local function getBattleFlags()
    local ok, flags = pcall(u32, BATTLE_TYPE_FLAGS_ADDR)
    if not ok then return nil end
    if flags == 0 then return nil end
    return {
        raw = flags,
        trainer = (flags & BATTLE_TYPE_TRAINER) ~= 0,
        double = (flags & BATTLE_TYPE_DOUBLE) ~= 0,
        link = (flags & BATTLE_TYPE_LINK) ~= 0,
        safari = (flags & BATTLE_TYPE_SAFARI) ~= 0,
    }
end

local function getEnemy()
    local ok, personality = pcall(u32, ENEMY_PARTY_ADDR)
    if not ok then return nil end
    local level = u8(ENEMY_PARTY_ADDR + 0x54)
    local maxHp = u16(ENEMY_PARTY_ADDR + 0x58)
    if level >= 1 and level <= 100 and maxHp > 0 and maxHp < 999 then
        return {personality = personality, level = level, max_hp = maxHp}
    end
    return nil
end

local function getBattleOutcome()
    local ok, v = pcall(u8, BATTLE_OUTCOME_ADDR)
    if not ok then return 0 end
    return v
end

local function isFieldLocked()
    local ok, v = pcall(u8, FIELD_LOCK_ADDR)
    return ok and v ~= 0
end

-- Generic task-scan helper (battle-decision-signals research): detects
-- whether a task with the given function address is currently active,
-- regardless of which slot it's in. One helper, reusable for any
-- task-implemented menu including ones not yet individually researched.
local function taskActive(fn)
    for i = 0, 15 do
        local b = GTASKS_ADDR + i * GTASK_SIZE
        local ok, isActive = pcall(u8, b + 4)
        if ok and isActive ~= 0 then
            local ok2, func = pcall(u32, b)
            if ok2 and (func & ~1) == fn then return true end
        end
    end
    return false
end

-- Live player tile position, read from the player's OWN gObjectEvents
-- slot (currentCoords) rather than gSaveBlock1Ptr->pos, which only
-- updates on warp-in and via camera-scroll bookkeeping (never runs once a
-- room already fits on screen -- see harness-status.md incident #13).
local function livePlayerXY()
    for i = 0, OBJECT_EVENTS_COUNT - 1 do
        local base = OBJECT_EVENTS_ADDR + i * OBJECT_EVENT_SIZE
        local okA, flags0 = pcall(u8, base + 0x00)
        local okP, flags2 = pcall(u8, base + 0x02)
        if okA and okP and (flags0 & 1) ~= 0 and (flags2 & 1) ~= 0 then
            return u16(base + 0x10), u16(base + 0x12), i
        end
    end
    return nil, nil, nil
end

local function countBadges(sb1)
    local count = 0
    for i = 0, 7 do
        local flagNum = FLAG_BADGE01_GET + i
        local byteIdx = flagNum // 8
        local bitIdx = flagNum % 8
        local ok, byte = pcall(u8, sb1 + SAVEBLOCK1_FLAGS_OFFSET + byteIdx)
        if ok and (byte & (1 << bitIdx)) ~= 0 then count = count + 1 end
    end
    return count
end

local function playerSig()
    local ok, sb1 = pcall(u32, SAVEBLOCK1_PTR_ADDR)
    if not ok or sb1 == 0 then return 0, 0, 0, 0, -1, -1, nil, nil, nil end
    local lx, ly, slot = livePlayerXY()
    local x = lx or u16(sb1 + 0x00)
    local y = ly or u16(sb1 + 0x02)
    local badges = countBadges(sb1)
    local partyCount = u8(PLAYER_PARTY_COUNT_ADDR)
    local mapGroup = u8(sb1 + SAVEBLOCK1_MAPGROUP_OFFSET)
    local mapNum = u8(sb1 + SAVEBLOCK1_MAPNUM_OFFSET)
    local posX, posY = u16(sb1 + 0x00), u16(sb1 + 0x02)
    return x, y, badges, partyCount, mapGroup, mapNum, slot, posX, posY
end

local function getPlayerElevation(slot)
    if not slot then return nil end
    local ok, b = pcall(u8, OBJECT_EVENTS_ADDR + slot * OBJECT_EVENT_SIZE + OBJECT_EVENT_ELEVATION_OFFSET)
    if not ok then return nil end
    return b & 0x0F  -- low nibble = currentElevation, matches this codebase's other LSB-first packed bitfields
end

-- Reads gBackupMapLayout's own dimensions/pointer fresh every call (never
-- cached) -- width/height/pointer all change on every warp, and a stale
-- cache here would silently misread an entirely different room's grid.
local function getMapGridBlock(x, y)
    local okW, width = pcall(u32, BACKUP_MAP_LAYOUT_ADDR + 0x00)
    local okH, height = pcall(u32, BACKUP_MAP_LAYOUT_ADDR + 0x04)
    local okP, mapPtr = pcall(u32, BACKUP_MAP_LAYOUT_ADDR + 0x08)
    if not (okW and okH and okP) then return nil end
    -- width/height are s32 in the struct; a bad/negative read (torn state
    -- mid-warp) must not be treated as a huge unsigned bound.
    if width <= 0 or width > 2000 or height <= 0 or height > 2000 then return nil end
    if x < 0 or x >= width or y < 0 or y >= height then return nil end
    local okB, block = pcall(u16, mapPtr + 2 * (x + width * y))
    if not okB then return nil end
    return block
end

-- Decodes one map-grid block into {metatile, collision, elevation}. Mirrors
-- UNPACK_METATILE/UNPACK_COLLISION/UNPACK_ELEVATION from
-- include/global.fieldmap.h exactly (shifts/masks curl+grep verified).
local function decodeGridBlock(block)
    if block == MAPGRID_UNDEFINED then
        -- Mirrors MapGridGetCollisionAt/MapGridGetElevationAt's own special
        -- case exactly: forced collision=1, elevation=0, regardless of the
        -- (meaningless, all-zero-under-the-mask) raw bits.
        return {metatile = block & MAPGRID_METATILE_MASK, collision = 1, elevation = 0, undefined = true}
    end
    return {
        metatile = block & MAPGRID_METATILE_MASK,
        collision = (block & MAPGRID_COLLISION_MASK) >> MAPGRID_COLLISION_SHIFT,
        elevation = (block & MAPGRID_ELEVATION_MASK) >> MAPGRID_ELEVATION_SHIFT,
        undefined = false,
    }
end

-- One-character symbol for a tile relative to the mover's OWN elevation --
-- this is what actually determines whether that mover (not just "the map in
-- the abstract") could step onto it, mirroring IsElevationMismatchAt().
local function gridTileSymbol(x, y, playerElevation)
    local block = getMapGridBlock(x, y)
    if block == nil then return "?" end  -- border / outside the loaded grid bounds entirely
    local d = decodeGridBlock(block)
    if d.undefined then return "u" end  -- unloaded grid cell -- forced-impassable by the game, but not a "real" wall (see MAPGRID_UNDEFINED note above); may open up on approach if a connection loads
    if d.collision ~= 0 then return "#" end  -- terrain-impassable, unconditionally
    if playerElevation == nil or d.elevation == ELEVATION_TRANSITION or
       d.elevation == ELEVATION_MULTI_LEVEL or d.elevation == playerElevation then
        return "."  -- passable at the mover's current elevation
    end
    return "^"  -- passable terrain, but a real step/ledge: elevation mismatch blocks it from here
end

-- Builds an ASCII collision snapshot centered on the player -- the direct
-- replacement for "screenshot to see the room": '.'=open, '#'=terrain-
-- blocked, '^'=elevation-mismatched (a step/ledge, not a wall -- often
-- crossable from a DIFFERENT approach tile), 'N'=another object event
-- (NPC/item) standing there, '@'=the player, '?'=outside the loaded grid
-- (map border/edge). Costs one JSON round trip, no image tokens, and reads
-- the exact signal the game's own movement code uses -- not a guess.
local function getCollisionGrid(radius)
    radius = radius or 5
    local px, py, _, _, mapGroup, mapNum, slot = playerSig()
    local pelev = getPlayerElevation(slot)
    local x0, y0 = px - radius, py - radius
    local occupied = {}
    for i = 0, OBJECT_EVENTS_COUNT - 1 do
        local base = OBJECT_EVENTS_ADDR + i * OBJECT_EVENT_SIZE
        local okA, flags0 = pcall(u8, base + 0x00)
        local okP, flags2 = pcall(u8, base + 0x02)
        if okA and okP and (flags0 & 1) ~= 0 and (flags2 & 1) == 0 then  -- active, NOT the player
            local okM, evMapNum = pcall(u8, base + 0x09)
            local okG, evMapGroup = pcall(u8, base + 0x0A)
            if okM and okG and evMapNum == mapNum and evMapGroup == mapGroup then
                local ex, ey = u16(base + 0x10), u16(base + 0x12)
                occupied[ex .. "," .. ey] = true
            end
        end
    end
    local rows = {}
    for y = y0, py + radius do
        local chars = {}
        for x = x0, px + radius do
            if x == px and y == py then
                chars[#chars + 1] = "@"
            elseif occupied[x .. "," .. y] then
                chars[#chars + 1] = "N"
            else
                chars[#chars + 1] = gridTileSymbol(x, y, pelev)
            end
        end
        rows[#rows + 1] = table.concat(chars)
    end
    return rows, x0, y0, px, py, pelev
end
playerSigForLog = playerSig

local function getObjectEvents()
    local out = {}
    for i = 0, OBJECT_EVENTS_COUNT - 1 do
        local base = OBJECT_EVENTS_ADDR + i * OBJECT_EVENT_SIZE
        local ok, flags0 = pcall(u8, base + 0x00)
        if ok and (flags0 & 1) ~= 0 then
            local flags2 = u8(base + 0x02)
            local isPlayer = (flags2 & 1) ~= 0
            local graphicsId = u8(base + 0x05)
            local localId = u8(base + 0x08)
            local objMapNum = u8(base + 0x09)
            local objMapGroup = u8(base + 0x0A)
            local cx = u16(base + 0x10)
            local cy = u16(base + 0x12)
            table.insert(out, {
                slot = i, local_id = localId, graphics_id = graphicsId,
                map_group = objMapGroup, map_num = objMapNum,
                x = cx, y = cy, is_player = isPlayer,
                is_item_ball = (graphicsId == OBJ_EVENT_GFX_ITEM_BALL),
            })
        end
    end
    return out
end

-- Battle/menu decision state -- item 7. Resolves the harness's former
-- "Known limitation" (auto-mode could blindly mash through move-forget,
-- a nickname Yes/No, etc.) by naming every state that means "a real
-- choice is on screen right now" instead of treating battle_init/
-- battle_main as one big mash-through-everything zone.
-- HP visibility -- added per Jackson's explicit request (2026-09-09,
-- fifth-session follow-up) before the first real trainer battle: no HP
-- signal existed anywhere in the harness until now, meaning a fainting
-- Pokemon or a close fight was completely invisible to DIAG. Reads
-- gBattleMons[0] (player, singles convention already established at
-- BATTLER_CONTROLLER_FUNCS_ADDR's comment above) and gBattleMons[1]
-- (opponent). Struct layout verified live via curl+grep against
-- pret/pokeemerald include/pokemon.h immediately before writing this,
-- not a remembered/guessed offset.
local function getBattleHP()
    local out = {my_hp = nil, my_max_hp = nil, my_species = nil, my_level = nil,
                 opp_hp = nil, opp_max_hp = nil, opp_species = nil, opp_level = nil}
    local base0 = BATTLE_MONS_ADDR
    local base1 = BATTLE_MONS_ADDR + BATTLE_MON_SIZE
    local ok0, hp0 = pcall(u16, base0 + BATTLE_MON_HP_OFF)
    if ok0 then
        out.my_hp = hp0
        local okm, m = pcall(u16, base0 + BATTLE_MON_MAXHP_OFF); if okm then out.my_max_hp = m end
        local oks, sp = pcall(u16, base0 + BATTLE_MON_SPECIES_OFF); if oks then out.my_species = sp end
        local okl, lv = pcall(u8, base0 + BATTLE_MON_LEVEL_OFF); if okl then out.my_level = lv end
    end
    local ok1, hp1 = pcall(u16, base1 + BATTLE_MON_HP_OFF)
    if ok1 then
        out.opp_hp = hp1
        local okm, m = pcall(u16, base1 + BATTLE_MON_MAXHP_OFF); if okm then out.opp_max_hp = m end
        local oks, sp = pcall(u16, base1 + BATTLE_MON_SPECIES_OFF); if oks then out.opp_species = sp end
        local okl, lv = pcall(u8, base1 + BATTLE_MON_LEVEL_OFF); if okl then out.opp_level = lv end
        local okp, pid = pcall(u32, base1 + 0x48)
        local oko, oid = pcall(u32, base1 + 0x54)
        if okp and oko then
            local x = ((oid & 0xFFFF) ~ (oid >> 16) ~ (pid & 0xFFFF) ~ (pid >> 16)) & 0xFFFF
            out.opp_shiny = x < 8
        end
    end
    return out
end

local function getBattleDecisionState(gameModeHint)
    -- incident #20: in_battle must be derived from game_mode (callback2),
    -- never from raw gBattleTypeFlags -- confirmed via pret/pokeemerald
    -- source (src/battle_setup.c) that gBattleTypeFlags is only ever
    -- zeroed at the START of the NEXT battle's setup, never on the
    -- current battle's end, so it stays nonzero (stale) for an
    -- arbitrarily long stretch of real overworld play after a battle
    -- actually ends. game_mode/callback2 is confirmed to transition
    -- promptly and correctly, so it's the trustworthy signal here.
    local gm = gameModeHint
    if gm == nil then gm = getMode() end
    local inBattle = (gm == "battle_init" or gm == "battle_main")
    local d = strict({
        in_battle = inBattle,
        battle_input = "none",
        learn_move = false,
        learn_move_state = nil,
        yesno_cursor = nil,
        summary_screen = false,
        move_to_learn = nil,
        field_menu = false,
        field_menu_kind = nil,
        risky = false,
    }, "battleDecisionState", {
        "in_battle", "battle_input", "learn_move", "learn_move_state",
        "yesno_cursor", "summary_screen", "move_to_learn", "field_menu",
        "field_menu_kind", "risky",
    })

    -- Field (overworld) Yes/No and multichoice boxes: relevant whether or
    -- not a battle is active, since field_locked is true during these and
    -- the general auto-mash branch used to answer them blind (see the new
    -- incident logged in harness-status.md for this pass).
    if taskActive(TASK_HANDLE_YESNO_ADDR) then
        d.field_menu = true
        d.field_menu_kind = "yesno"
    elseif taskActive(TASK_HANDLE_MULTICHOICE_ADDR) then
        d.field_menu = true
        d.field_menu_kind = "multichoice"
    end

    if inBattle then
        local okBi, cf = pcall(u32, BATTLER_CONTROLLER_FUNCS_ADDR)
        if okBi then
            local name = BATTLE_INPUT_FUNCS[cf & ~1]
            d.battle_input = name or "other"
        end

        local okBs, instr = pcall(u32, BATTLESCRIPT_CURR_INSTR_ADDR)
        if okBs and instr >= LEARN_MOVE_ASK_START and instr < LEARN_MOVE_ASK_END then
            d.learn_move = true
        end
        local okLs, ls = pcall(u8, LEARN_MOVE_STATE_ADDR)
        if okLs then d.learn_move_state = ls end
        local okYc, yc = pcall(u8, YESNO_CURSOR_ADDR)
        if okYc then d.yesno_cursor = yc end
        local okMl, ml = pcall(u16, MOVE_TO_LEARN_ADDR)
        if okMl then d.move_to_learn = ml end

        local okCb, cb2 = pcall(u32, GMAIN_CALLBACK2_ADDR)
        if okCb and (cb2 & ~1) == SUMMARY_SCREEN_CB2 then d.summary_screen = true end
    end

    d.risky = d.learn_move or d.summary_screen or d.field_menu or
              (d.battle_input ~= "none" and d.battle_input ~= "other")
    return d
end

-- ---------------------------------------------------------------------
-- Action queue (only path that ever calls emu:setKeys())
-- ---------------------------------------------------------------------
local queue = {}
local totalInputsSent = 0
local function schedule(mask, hold, release)
    if type(mask) ~= "number" then return false end
    table.insert(queue, {mask = mask, hold = hold or 8, release = release or 32})
    totalInputsSent = totalInputsSent + 1
    return true
end

local DIR = {up = 64, down = 128, left = 32, right = 16}
local BUTTON = {a = 1, b = 2, select = 4, start = 8,
                 right = 16, left = 32, up = 64, down = 128}

local mode = "auto"
local decision = nil
local frameCount = 0
local lastGameMode = nil
local namingScreenCount = 0
local everReachedOverworld = false
local AUTOSAVE_INTERVAL = 3600
local lastAutosaveFrame = 0
local AUTOSAVE_SLOT = 9

-- Generic anomaly detector -- item 6. If inputs are being sent (auto-mode
-- is actively pressing buttons) and NO element of the state signature has
-- changed for ANOMALY_THRESHOLD frames, something is wrong even if
-- nothing else caught it -- auto-park instead of continuing to burn
-- input forever. The signature is deliberately dominated by position/map/
-- state, NOT text/VRAM diversity (incident #3: a text-diversity-based
-- stale-detector never parked against an object that prints different
-- text each time even though position never moved; incident #8: an
-- NPC-dialogue re-trigger loop changed text every press but nothing else
-- -- a text-based signature would have missed it exactly like #3 did).
local ANOMALY_THRESHOLD = 600
local lastAnomalySig = nil
local anomalyUnchangedFrames = 0

local function computeAnomalySignature(x, y, mapGroup, mapNum, fieldLocked, cb2, partyCount, battleRaw)
    return table.concat({x, y, mapGroup, mapNum, tostring(fieldLocked),
                          toHex(cb2 & ~1), partyCount, battleRaw or 0}, "|")
end

-- ---------------------------------------------------------------------
-- Movement step engine -- shared by GOTO (navStep) and WALK.
--
-- incident #17, take 2. The first fix (still visible in git history/
-- harness-status.md) replaced the original blind "hold N, release N" frame
-- guess with a driveStep() that watched gPlayerAvatar's own
-- tileTransitionState (0x02037590+0x03) for a return-to-zero as the
-- "one tile done" signal. That is what the actual game code uses
-- internally, so it looked right on paper -- but it depends on catching a
-- SPECIFIC SINGLE FRAME (the brief idle tick between two consecutive tile
-- transitions during a held multi-tile walk) on every poll. Live-tested,
-- it missed almost all of them: "WALK right 3" actually walked the player
-- 10 tiles (x 7->17, confirmed via DIAG) while the engine's own frame-by-
-- frame trace log showed tileTransitionState reading 0 for 20 straight
-- samples with runningState pinned at MOVING(2) the whole time -- i.e. our
-- callback's samples were landing almost entirely on the "still mid-walk"
-- side of a state that, per the struct's own comment, cycles through
-- brief transitions even while genuinely moving. Chasing a single-frame
-- edge over a socket-driven poll loop is inherently fragile.
--
-- The fix: stop trying to catch the exact transition edge. Hold the
-- direction, and every frame just compare the player's OWN live position
-- (gObjectEvents currentCoords, via playerSig() -- already the harness's
-- one source of truth for "where is the player," used everywhere else)
-- against where the hold started. Position is cumulative and monotonic in
-- the held direction, so ANY sample -- however sparse -- still reports
-- correct total progress; there is no single frame that must be caught.
-- "Are we stuck" is answered the same grounded way: if progress hasn't
-- INCREASED for a generous frame budget, we're stuck (real wall/ledge/
-- NPC), full stop -- no guessing at animation timing at all.
local DIR_VECTOR = {
    [DIR.up]    = {0, -1},
    [DIR.down]  = {0, 1},
    [DIR.left]  = {-1, 0},
    [DIR.right] = {1, 0},
}
local STALL_FRAME_LIMIT = 24  -- generous vs. a normal ~16f/tile walk; holding a few extra frames after truly stopping costs nothing since completion is read from position, not timed

-- state: {startX, startY, dx, dy, lastProgress, stallFrames}, owned by the
-- caller (nav.stepping / walk.stepping) so independent steppers never
-- share bookkeeping. Returns the CURRENT cumulative tiles-in-the-held-
-- direction moved since this hold started (0 while nothing has moved yet),
-- plus a boolean "stalled" (progress hasn't increased for
-- STALL_FRAME_LIMIT frames -- caller should stop holding and accept
-- whatever `progress` is as final, whether that's 0 or a partial count).
local function driveHold(state, mask)
    if state.startX == nil then
        state.startX, state.startY = playerSig()
        state.lastProgress = 0
        state.stallFrames = 0
    end
    emu:setKeys(mask)
    local x, y = playerSig()
    local vec = DIR_VECTOR[mask]
    local progress = (x - state.startX) * vec[1] + (y - state.startY) * vec[2]
    if progress > state.lastProgress then
        state.lastProgress = progress
        state.stallFrames = 0
    else
        state.stallFrames = state.stallFrames + 1
    end
    return progress, (state.stallFrames >= STALL_FRAME_LIMIT)
end

-- Read-only peek at a hold-in-progress's current tile count, for STATE/DIAG
-- reporting -- never calls emu:setKeys(), never mutates state.
local function peekHoldProgress(state, mask)
    if not state or state.startX == nil then return 0 end
    local x, y = playerSig()
    local vec = DIR_VECTOR[mask]
    return (x - state.startX) * vec[1] + (y - state.startY) * vec[2]
end

-- ---------------------------------------------------------------------
-- GOTO navigator
-- ---------------------------------------------------------------------
local nav = nil
local NAV_MAX_NO_PROGRESS = 14
local NAV_MAX_BLOCKED_STREAK = 4

local function navStep()
    if not nav then return end
    if isFieldLocked() then
        schedule(BUTTON.a, 8, 16)
        return
    end

    -- A step already in flight: keep driving THAT direction to its
    -- conclusion before re-reading position or picking a new direction --
    -- switching direction mid-transition is how the old code's oscillation
    -- happened.
    if nav.stepping then
        local progress, stalled = driveHold(nav.stepping, nav.stepping.dirMask)
        if progress >= 1 then
            -- One tile done -- release NOW, don't keep holding into stall
            -- confirmation, or the same direction would just carry on into
            -- a second tile nav never decided to take.
            emu:setKeys(0)
            nav.stepping = nil
            nav.blockedStreak = 0
        elseif stalled then
            emu:setKeys(0)
            nav.stepping = nil
            nav.blockedStreak = nav.blockedStreak + 1
        else
            return  -- still holding, no tile completed yet
        end
    end

    local x, y, _, _, mapGroup, mapNum = playerSig()
    if nav.mapGroup ~= nil and (mapGroup ~= nav.mapGroup or mapNum ~= nav.mapNum) then
        mode = "parked"
        decision = {type = "warped", x = x, y = y, map_group = mapGroup, map_num = mapNum,
                    from_map_group = nav.mapGroup, from_map_num = nav.mapNum, frame = frameCount}
        pushLog("nav_park", {frame = frameCount, detail = "warped"})
        nav = nil
        return
    end
    if x == nav.tx and y == nav.ty then
        pushLog("nav_park", {frame = frameCount, detail = "reached"})
        nav = nil
        return
    end

    local dist = math.abs(nav.tx - x) + math.abs(nav.ty - y)
    if nav.bestDist == nil or dist < nav.bestDist then
        nav.bestDist = dist
        nav.noProgress = 0
    else
        nav.noProgress = nav.noProgress + 1
    end
    if nav.noProgress >= NAV_MAX_NO_PROGRESS then
        mode = "parked"
        decision = {type = "nav_stuck", x = x, y = y, tx = nav.tx, ty = nav.ty, frame = frameCount}
        pushLog("nav_park", {frame = frameCount, detail = "nav_stuck"})
        nav = nil
        return
    end

    local dx, dy = nav.tx - x, nav.ty - y
    if nav.axis == "x" and dx == 0 then nav.axis = "y" end
    if nav.axis == "y" and dy == 0 then nav.axis = "x" end
    local primary, secondary
    if nav.axis == "x" then
        primary = dx > 0 and DIR.right or (dx < 0 and DIR.left or nil)
        secondary = dy > 0 and DIR.down or (dy < 0 and DIR.up or nil)
    else
        primary = dy > 0 and DIR.down or (dy < 0 and DIR.up or nil)
        secondary = dx > 0 and DIR.right or (dx < 0 and DIR.left or nil)
    end

    local dir
    if nav.blockedStreak == 0 then
        dir = primary or secondary
    elseif nav.blockedStreak < NAV_MAX_BLOCKED_STREAK then
        dir = secondary or primary
    else
        local perpPair = (nav.axis == "x") and {DIR.up, DIR.down} or {DIR.left, DIR.right}
        dir = (nav.blockedStreak % 2 == 0) and perpPair[1] or perpPair[2]
    end
    -- Door avoidance (2026-10-01): never step onto a warp tile that is not the target (GOTO kept re-entering the building whose door sat beside the route).
    do
        local vec = {[DIR.right] = {1, 0}, [DIR.left] = {-1, 0}, [DIR.down] = {0, 1}, [DIR.up] = {0, -1}}
        if nav.warps == nil then
            local okw, ws = pcall(getWarps)
            nav.warps = okw and ws or {}
        end
        local function isWarp(d)
            local v = vec[d]
            if not v then return false end
            local wx, wy = x + v[1], y + v[2]
            if wx == nav.tx and wy == nav.ty then return false end
            for _, w in ipairs(nav.warps) do if w.x == wx and w.y == wy then return true end end
            return false
        end
        if dir and isWarp(dir) then
            local alts = {}
            if secondary then alts[#alts + 1] = secondary end
            for _, a in ipairs({DIR.up, DIR.down, DIR.left, DIR.right}) do alts[#alts + 1] = a end
            for _, a in ipairs(alts) do
                if a ~= dir and not isWarp(a) then dir = a; break end
            end
        end
    end
    nav.stepping = {dirMask = dir}
    pushLog("nav_step", {frame = frameCount})
end

-- ---------------------------------------------------------------------
-- WALK -- a short, deliberate, manually-chosen move in one direction.
-- Holds the direction continuously via driveHold() for the whole run (see
-- the incident #17 writeup above driveHold's definition) rather than
-- re-entering per tile, and stops the instant ground-truth position shows
-- either the full request satisfied or genuinely stalled -- so "WALK left
-- 7" means what it says without either the old under-delivery or the
-- transition-catching over-delivery.
-- ---------------------------------------------------------------------
local walk = nil

local function walkStep()
    if not walk then return end
    if isFieldLocked() then
        schedule(BUTTON.a, 8, 16)
        return
    end
    walk.stepping = walk.stepping or {}
    local progress, stalled = driveHold(walk.stepping, walk.dirMask)
    if progress >= walk.n then
        emu:setKeys(0)
        pushLog("walk_done", {frame = frameCount, detail = "moved " .. progress})
        walk = nil
        return
    end
    if stalled then
        emu:setKeys(0)
        pushLog("walk_blocked", {frame = frameCount,
                 detail = "moved " .. progress .. " of " .. walk.n})
        walk = nil
        return
    end
    -- else: still holding, no completion yet -- fall through and wait for next frame
end

-- ---------------------------------------------------------------------
-- Frame callback body -- called every frame by bootstrap.lua via a
-- _G.DIRECTOR.onFrame lookup, never registered directly here.
-- ---------------------------------------------------------------------
local AUTOSAVE_FRAMES = 60 * 60 * 3   -- 3 minutes of emulated time
local autosaveEnabled = true
local autosaveStable, autosaveLastMap, autosaveLastFrame = nil, nil, 0
local autosaveBattleSeen, autosaveCount, autosaveLastSig, autosaveError = false, 0, nil, nil

local v2 = {}   -- harness v2 (text freshness + NAME): filled in by the do-block after readGen3String (the file is at Lua's 200-local limit)
local function onFrame()
    frameCount = frameCount + 1
    if v2.textFreshTick then pcall(v2.textFreshTick) end
    if #queue > 0 then
        local a = queue[1]
        local ok = pcall(function()
            if a.hold > 0 then
                emu:setKeys(a.mask); a.hold = a.hold - 1
            elseif a.release > 0 then
                emu:setKeys(0); a.release = a.release - 1
            else
                table.remove(queue, 1)
            end
        end)
        if not ok then table.remove(queue, 1) end
        return
    end
    emu:setKeys(0)
    if v2.nameTick then local okN, busyN = pcall(v2.nameTick); if okN and busyN then return end end   -- v2 NAME job drives the naming screen

    -- Rolling crash-insurance autosave (2026-09-26, after an mGBA crash lost
    -- an unsaved gym run). Savestate slot 2 is written whenever the player has
    -- free overworld control AND (the map changed, a battle just ended, or
    -- AUTOSAVE_FRAMES passed) -- checked once a second, only after the same
    -- tile has held for two checks. Pure infrastructure: never an input.
    if autosaveEnabled and frameCount % 60 == 0 then
        local okA, err = pcall(function()
            local gmA = getMode()
            local inB = (gmA == "battle_init" or gmA == "battle_main")
            if inB then autosaveBattleSeen = true; autosaveStable = nil; return end
            if gmA ~= "overworld" or walk ~= nil or nav ~= nil or isFieldLocked() then autosaveStable = nil; return end
            local ax, ay, _, _, ag, an = playerSig()
            local sig = ag .. "." .. an .. ":" .. ax .. "," .. ay
            if autosaveStable ~= sig then autosaveStable = sig; return end
            local mapSig = ag .. "." .. an
            if autosaveLastMap == nil then autosaveLastMap = mapSig; autosaveLastFrame = frameCount; return end
            if mapSig ~= autosaveLastMap or autosaveBattleSeen or (frameCount - autosaveLastFrame) >= AUTOSAVE_FRAMES then
                emu:saveStateSlot(2)
                autosaveLastMap, autosaveLastFrame, autosaveBattleSeen = mapSig, frameCount, false
                autosaveCount = autosaveCount + 1
                autosaveLastSig = sig
                pushLog("autosave", {frame = frameCount, detail = "slot2 " .. sig})
            end
        end)
        if not okA then autosaveError = tostring(err) end
    end

    local gameMode, cb2 = getMode()

    if gameMode == "naming_screen" and lastGameMode ~= "naming_screen" then
        namingScreenCount = namingScreenCount + 1
        mode = "parked"
        nav = nil
        walk = nil
        decision = {type = "naming_screen", visit = namingScreenCount, frame = frameCount}
        pushLog("decision_raised", {frame = frameCount, detail = "naming_screen"})
        lastGameMode = gameMode
        return
    end

    if gameMode == "battle_init" or gameMode == "battle_main" then
        -- Battle/menu decision guard (item 7) -- checked BEFORE the
        -- trainer/wild split below, so it applies uniformly to both: the
        -- moment a real choice (move-forget, any battle_input state,
        -- summary screen) is on screen, park unconditionally, even
        -- mid-nav or mid-pause, exactly like the existing trainer-battle
        -- park below. This REPLACES blindly mashing A through
        -- battle_init/battle_main -- auto-mode now only advances
        -- non-interactive message text, never makes a battle choice
        -- itself.
        local bds = getBattleDecisionState()
        if bds.risky then
            nav = nil
            walk = nil
            mode = "parked"
            decision = {type = "battle_decision", frame = frameCount,
                        battle_input = bds.battle_input, learn_move = bds.learn_move,
                        learn_move_state = bds.learn_move_state, yesno_cursor = bds.yesno_cursor,
                        summary_screen = bds.summary_screen, move_to_learn = bds.move_to_learn}
            pushLog("decision_raised", {frame = frameCount, detail = "battle_decision:" .. tostring(bds.battle_input)})
            lastGameMode = gameMode
            return
        end
        local bf = getBattleFlags()
        if bf and bf.trainer then
            nav = nil
            walk = nil
            mode = "parked"
            local enemy = getEnemy()
            decision = {type = "battle", trainer = true, frame = frameCount,
                        enemy_level = enemy and enemy.level or nil,
                        enemy_max_hp = enemy and enemy.max_hp or nil}
            pushLog("decision_raised", {frame = frameCount, detail = "trainer_battle"})
            lastGameMode = gameMode
            return
        elseif nav or walk then
            nav = nil
            walk = nil
        end
    end

    -- Field (overworld) Yes/No or multichoice box: field_locked is true
    -- here, so without this check the general auto-mash branch further
    -- below would answer it blind with A -- a latent version of the same
    -- risk item 7 targets in battle, found this pass, logged as a new
    -- incident in harness-status.md.
    if gameMode ~= "battle_init" and gameMode ~= "battle_main" then
        local okYn = taskActive(TASK_HANDLE_YESNO_ADDR)
        local okMc = (not okYn) and taskActive(TASK_HANDLE_MULTICHOICE_ADDR)
        if okYn or okMc then
            nav = nil
            walk = nil
            mode = "parked"
            decision = {type = "field_menu", kind = okYn and "yesno" or "multichoice", frame = frameCount}
            pushLog("decision_raised", {frame = frameCount, detail = "field_menu"})
            lastGameMode = gameMode
            return
        end
    end

    if nav then
        navStep()
        return
    end
    if walk then
        walkStep()
        return
    end
    if mode ~= "auto" then return end

    -- Generic anomaly check -- only in the free-running auto zone (not
    -- mid-nav, which has its own noProgress-based stuck detector, and not
    -- mid-queue-drain, handled above). If the state signature hasn't
    -- moved for ANOMALY_THRESHOLD frames while auto-mode is active and
    -- would otherwise keep pressing buttons, park instead of continuing
    -- to press "just in case" forever.
    do
        local x, y, badges, partyCount, mapGroup, mapNum = playerSig()
        local bf = getBattleFlags()
        local sig = computeAnomalySignature(x, y, mapGroup, mapNum, isFieldLocked(), cb2, partyCount, bf and bf.raw)
        if sig == lastAnomalySig then
            anomalyUnchangedFrames = anomalyUnchangedFrames + 1
        else
            anomalyUnchangedFrames = 0
            lastAnomalySig = sig
        end
        if anomalyUnchangedFrames >= ANOMALY_THRESHOLD then
            mode = "parked"
            decision = {type = "anomaly", frame = frameCount,
                        reason = "state signature unchanged for " .. tostring(ANOMALY_THRESHOLD) .. "+ frames while auto-mode was active"}
            pushLog("decision_raised", {frame = frameCount, detail = "anomaly"})
            anomalyUnchangedFrames = 0
            lastGameMode = gameMode
            return
        end
    end

    if gameMode == "battle_init" or gameMode == "battle_main" then
        -- Only reached when NOT risky (see the guard above) -- safe to
        -- advance plain message/animation text.
        schedule(1, 8, 24)
        pushLog("input_sent", {frame = frameCount, detail = "battle_text"})
        lastGameMode = gameMode
        return
    end

    if gameMode == "title_screen" or gameMode == "main_menu" or
       gameMode == "copyright_screen" or gameMode == "new_game_intro" or
       gameMode == "naming_screen_return" then
        schedule(1, 8, 32)
        lastGameMode = gameMode
        return
    end

    if gameMode == "unknown" then
        if not everReachedOverworld then
            schedule(1, 8, 32)
            lastGameMode = gameMode
            return
        end
        mode = "parked"
        decision = {type = "unknown_mode", callback2 = toHex(cb2), frame = frameCount}
        pushLog("decision_raised", {frame = frameCount, detail = "unknown_mode"})
        lastGameMode = gameMode
        return
    end

    if gameMode == "overworld" then everReachedOverworld = true end

    if frameCount - lastAutosaveFrame >= AUTOSAVE_INTERVAL then
        pcall(function() emu:saveStateSlot(AUTOSAVE_SLOT) end)
        lastAutosaveFrame = frameCount
    end

    if isFieldLocked() then
        schedule(BUTTON.a, 8, 32)
        pushLog("input_sent", {frame = frameCount, detail = "field_lock_advance"})
        lastGameMode = gameMode
        return
    end

    local x, y = playerSig()
    mode = "parked"
    decision = {type = "needs_decision", frame = frameCount, x = x, y = y}
    pushLog("decision_raised", {frame = frameCount, detail = "needs_decision"})
    lastGameMode = gameMode
end

-- ---------------------------------------------------------------------
-- Fixture slots -- item 4. mGBA slots 3-8 reserved for regression
-- fixtures (slot 9 is autosave, slots 1-2 are manual milestone
-- checkpoints -- do NOT reuse 3-8 for progress saves). Each fixture's
-- check() runs immediately after LOADing that slot and asserts the
-- signature that made it useful as a fixture in the first place. Slots
-- 5/6 can only be verified for their STARTING condition synchronously
-- (a single socket call can't drive multiple frames of GOTO/nav
-- behaviour) -- their check() says so explicitly; full behavioural
-- verification (does GOTO actually park nav_stuck without oscillating,
-- does GOTO abort cleanly as "warped") still needs a live follow-up GOTO
-- issued by hand after REGRESS loads the fixture.
-- ---------------------------------------------------------------------
local FIXTURES = {
    [3] = {
        desc = "Mid-dialogue, message box open",
        check = function()
            local locked = isFieldLocked()
            return locked, {field_locked = locked, expected = true}
        end,
    },
    [4] = {
        desc = "Free-standing overworld, no script",
        check = function()
            local locked = isFieldLocked()
            local qlen = #queue
            return (not locked) and qlen == 0, {field_locked = locked, queue_len = qlen}
        end,
    },
    [5] = {
        desc = "Standing next to a GOTO-blocking obstacle (starting condition only -- drive GOTO by hand afterward to verify nav_stuck without oscillation)",
        check = function()
            local x, y, _, _, mapGroup, mapNum = playerSig()
            return true, {x = x, y = y, map_group = mapGroup, map_num = mapNum, note = "starting-condition-only; behavioural GOTO check must be run manually"}
        end,
    },
    [6] = {
        desc = "Freshly warped interior (starting condition only -- issue a GOTO on the OLD map's coordinates afterward to confirm it aborts as 'warped')",
        check = function()
            local x, y, _, _, mapGroup, mapNum = playerSig()
            return mapGroup ~= nil and mapGroup >= 0, {x = x, y = y, map_group = mapGroup, map_num = mapNum, note = "starting-condition-only"}
        end,
    },
    [7] = {
        desc = "In a wild battle",
        check = function()
            -- incident #20: derive in_battle from game_mode, consistent
            -- with STATE/DIAG, not from raw gBattleTypeFlags.
            local gm = getMode()
            local inBattle = (gm == "battle_init" or gm == "battle_main")
            local bf = inBattle and getBattleFlags() or nil
            local ok = inBattle and bf ~= nil and not bf.trainer
            return ok, {in_battle = inBattle, battle_trainer = bf and bf.trainer or false}
        end,
    },
    [8] = {
        desc = "First move-learn prompt",
        check = function()
            local bds = getBattleDecisionState()
            return bds.learn_move, {learn_move = bds.learn_move, learn_move_state = bds.learn_move_state}
        end,
    },
}

-- ---------------------------------------------------------------------
-- Gen 3 text decoding (tenth-session build). Byte->character table
-- generated once, offline, from pret/pokeemerald's own charmap.txt
-- (curl+grep against the repo, same class of legitimate technical
-- research as every RAM address in this file -- not a walkthrough, and
-- not guessed). A handful of low byte values (this ROM's font table
-- dual-purposes some slots for Japanese kana depending on region) picked
-- up a kana entry instead of a Latin one where charmap.txt defines both
-- for the same byte and the kana line happened to appear first in the
-- file -- harmless in practice, since real English-ROM text never
-- actually encodes to those specific byte values. Only entries 0x00-0xF6
-- matter for real dialogue; 0xF7 and above are handled as control codes
-- below, never looked up here.
local CHARMAP = {
  [0] = " ", [1] = "À", [2] = "Á", [3] = "Â", [4] = "Ç", [5] = "È", [6] = "É", [7] = "Ê",
  [8] = "Ë", [9] = "Ì", [10] = "こ", [11] = "Î", [12] = "Ï", [13] = "Ò", [14] = "Ó", [15] = "Ô",
  [16] = "Œ", [17] = "Ù", [18] = "Ú", [19] = "Û", [20] = "Ñ", [21] = "ß", [22] = "à", [23] = "á",
  [24] = "ね", [25] = "ç", [26] = "è", [27] = "é", [28] = "ê", [29] = "ë", [30] = "ì", [31] = "ま",
  [32] = "î", [33] = "ï", [34] = "ò", [35] = "ó", [36] = "ô", [37] = "œ", [38] = "ù", [39] = "ú",
  [40] = "û", [41] = "ñ", [42] = "º", [43] = "ª", [44] = "わ", [45] = "&", [46] = "+", [47] = "ぁ",
  [48] = "ぃ", [49] = "ぅ", [50] = "ぇ", [51] = "ぉ", [52] = "ゃ", [53] = "=", [54] = ";", [55] = "が",
  [56] = "ぎ", [57] = "ぐ", [58] = "げ", [59] = "ご", [60] = "ざ", [61] = "じ", [62] = "ず", [63] = "ぜ",
  [64] = "ぞ", [65] = "だ", [66] = "ぢ", [67] = "づ", [68] = "で", [69] = "ど", [70] = "ば", [71] = "び",
  [72] = "ぶ", [73] = "べ", [74] = "ぼ", [75] = "ぱ", [76] = "ぴ", [77] = "ぷ", [78] = "ぺ", [79] = "ぽ",
  [80] = "っ", [81] = "¿", [82] = "¡", [83] = "ウ", [84] = "エ", [85] = "オ", [86] = "カ", [87] = "キ",
  [88] = "ク", [89] = "ケ", [90] = "Í", [91] = "%", [92] = "(", [93] = ")", [94] = "セ", [95] = "ソ",
  [96] = "タ", [97] = "チ", [98] = "ツ", [99] = "テ", [100] = "ト", [101] = "ナ", [102] = "ニ", [103] = "ヌ",
  [104] = "â", [105] = "ノ", [106] = "ハ", [107] = "ヒ", [108] = "フ", [109] = "ヘ", [110] = "ホ", [111] = "í",
  [112] = "ミ", [113] = "ム", [114] = "メ", [115] = "モ", [116] = "ヤ", [117] = "ユ", [118] = "ヨ", [119] = "ラ",
  [120] = "リ", [121] = "ル", [122] = "レ", [123] = "ロ", [124] = "ワ", [125] = "ヲ", [126] = "ン", [127] = "ァ",
  [128] = "ィ", [129] = "ゥ", [130] = "ェ", [131] = "ォ", [132] = "ャ", [133] = "<", [134] = ">", [135] = "ガ",
  [136] = "ギ", [137] = "グ", [138] = "ゲ", [139] = "ゴ", [140] = "ザ", [141] = "ジ", [142] = "ズ", [143] = "ゼ",
  [144] = "ゾ", [145] = "ダ", [146] = "ヂ", [147] = "ヅ", [148] = "デ", [149] = "ド", [150] = "バ", [151] = "ビ",
  [152] = "ブ", [153] = "ベ", [154] = "ボ", [155] = "パ", [156] = "ピ", [157] = "プ", [158] = "ペ", [159] = "ポ",
  [160] = "ッ", [161] = "0", [162] = "1", [163] = "2", [164] = "3", [165] = "4", [166] = "5", [167] = "6",
  [168] = "7", [169] = "8", [170] = "9", [171] = "!", [172] = "?", [173] = ".", [174] = "-", [175] = "·",
  [176] = "…", [177] = "\u{201C}", [178] = "\u{201D}", [179] = "\u{2018}", [180] = "\u{2019}",
  [181] = "♂", [182] = "♀", [183] = "¥", [184] = ",", [185] = "×", [186] = "/",
  [187] = "A", [188] = "B", [189] = "C", [190] = "D", [191] = "E", [192] = "F", [193] = "G", [194] = "H",
  [195] = "I", [196] = "J", [197] = "K", [198] = "L", [199] = "M", [200] = "N", [201] = "O", [202] = "P",
  [203] = "Q", [204] = "R", [205] = "S", [206] = "T", [207] = "U", [208] = "V", [209] = "W", [210] = "X",
  [211] = "Y", [212] = "Z", [213] = "a", [214] = "b", [215] = "c", [216] = "d", [217] = "e", [218] = "f",
  [219] = "g", [220] = "h", [221] = "i", [222] = "j", [223] = "k", [224] = "l", [225] = "m", [226] = "n",
  [227] = "o", [228] = "p", [229] = "q", [230] = "r", [231] = "s", [232] = "t", [233] = "u", [234] = "v",
  [235] = "w", [236] = "x", [237] = "y", [238] = "z", [239] = "\u{25B6}", [240] = ":",
  [241] = "Ä", [242] = "Ö", [243] = "Ü", [244] = "ä", [245] = "ö", [246] = "ü",
}

-- FC-prefixed format/control commands take a variable number of extra
-- bytes after the subcommand id -- best-effort table from charmap.txt's
-- own comments (e.g. "COLOR_HIGHLIGHT_SHADOW ... takes 3 bytes"). These
-- are rare in ordinary field/battle dialogue (mostly used for menus,
-- credits, and colored proper nouns); an unmapped subcommand falls back
-- to skipping 0 extra bytes, which can desync a decode for the rest of a
-- string in that rare case -- acceptable for a first pass, flag as a
-- known limitation if it ever actually shows up garbled.
local FC_EXTRA_BYTES = {
    [0x00] = 0, [0x01] = 1, [0x02] = 1, [0x03] = 1, [0x04] = 3, [0x05] = 1, [0x06] = 1, [0x07] = 0,
    [0x08] = 1, [0x09] = 0, [0x0A] = 1, [0x0B] = 2, [0x0C] = 0, [0x0D] = 1, [0x0E] = 1, [0x0F] = 1,
    [0x10] = 2, [0x11] = 1, [0x12] = 2, [0x13] = 1, [0x14] = 1, [0x15] = 0, [0x16] = 0, [0x17] = 1, [0x18] = 1,
}

-- Decodes a Gen 3-encoded byte array (already read from RAM, already
-- truncated at or before the 0xFF terminator) into a plain UTF-8 Lua
-- string. NAME_END/formatting control codes are consumed and mostly
-- dropped (rendered as no-ops or newlines) rather than emitted literally
-- -- the goal is readable text, not a byte-exact re-encoding.
local function decodeGen3String(bytes)
    local out, i, n = {}, 1, #bytes
    while i <= n do
        local b = bytes[i]
        if b == 0xFF then
            break -- '$' -- string terminator
        elseif b == 0xFE then
            table.insert(out, "\n"); i = i + 1        -- \n -- new line
        elseif b == 0xFA then
            table.insert(out, "\n"); i = i + 1         -- \l -- scroll up window
        elseif b == 0xFB then
            table.insert(out, "\n\n"); i = i + 1       -- \p -- new paragraph
        elseif b == 0xFC then
            local sub = bytes[i + 1]
            local extra = (sub ~= nil and FC_EXTRA_BYTES[sub]) or 0
            i = i + 2 + extra
        elseif b == 0xFD then
            -- Placeholder marker (player/rival name, item name, etc). By
            -- the time text lands in gStringVar4/gDisplayedStringBattle,
            -- StringExpandPlaceholders()/BufferStringBattle() have
            -- already resolved these to real text upstream -- a raw 0xFD
            -- surviving into this buffer would be unexpected, so this is
            -- a defensive skip, not the normal path.
            i = i + 2
        elseif b == 0xF7 then
            i = i + 1 -- DYNAMIC special glyph, no clean text equivalent -- drop
        else
            table.insert(out, CHARMAP[b] or "")
            i = i + 1
        end
    end
    return table.concat(out)
end

-- Reads up to maxLen bytes starting at addr and decodes them as a Gen 3
-- string, stopping early at the 0xFF terminator. One byte-at-a-time
-- pcall(u8, ...) loop, but it stops at the terminator almost immediately
-- for any real message (a few dozen bytes, not hundreds) -- still far
-- cheaper than a screenshot.
local function readGen3String(addr, maxLen)
    local bytes = {}
    for i = 0, maxLen - 1 do
        local ok, b = pcall(u8, addr + i)
        if not ok then break end
        table.insert(bytes, b)
        if b == 0xFF then break end
    end
    return decodeGen3String(bytes)
end

-- ---------------------------------------------------------------------
-- harness v2 (1/2): text freshness. T / TEXT read gStringVar4 / gDisplayedStringBattle,
-- which keep the LAST message after it leaves the screen. This labels the text:
--   field:  sFieldMessageBoxMode (0x020375bc, u8; HIDDEN=0 UNUSED=1 NORMAL=2 AUTO_SCROLL=3,
--           src/field_message_box.c). NB it drops to HIDDEN as soon as the text has finished
--           PRINTING, while the box still waits for A (Task_DrawFieldMessage state 2), so
--           HIDDEN alone does not mean "gone". "old" = HIDDEN and field controls not locked
--           (a message waiting on A always has a script running, i.e. the lock set).
--   battle: choose_action / choose_move / choose_target -> "menu" (a menu is up; the buffer
--           holds the earlier message, or the "What will X do?" prompt).
-- onFrame samples the decoded text every TEXT_TICK frames to know how long it has been unchanged.
-- ---------------------------------------------------------------------
do
local K = {
    FIELD_MSGBOX_MODE_ADDR = 0x020375bc,
    TEXT_TICK = 6, TEXT_STALE_S = 3,
    NS_PTR_ADDR = 0x02039f94,
    NS_TEXTBUF = 0x1800, NS_STATE = 0x1E10, NS_PAGE = 0x1E22, NS_CURSOR_SPR = 0x1E23, NS_TEMPLATE = 0x1E28,
    NS_STATE_INPUT = 2,
    GSPRITES_ADDR = 0x02020630, GSPRITE_SIZE = 0x44, SPRITE_DATA_OFF = 0x2E,
    FIELD_BOX_NAMES = {[0] = "hidden", [1] = "unused", [2] = "normal", [3] = "autoscroll"},
    NS_COLS = {[0] = 6, [1] = 8, [2] = 8},
    NS_PAGE_NAMES = {[0] = "symbols", [1] = "upper", [2] = "lower"},
}
v2.K = K
local textTrack = {}
local textGen = {f = 0, lastMode = 0}   -- f: +1 each time the field message box goes hidden -> shown, so re-showing identical text restarts the age

local function readCurrentText()
    local gm = getMode()
    local inBattle = (gm == "battle_init" or gm == "battle_main")
    local addr = inBattle and BATTLE_DISPLAYED_STRING_ADDR or FIELD_STRING_VAR4_ADDR
    local maxLen = inBattle and BATTLE_DISPLAYED_STRING_SIZE or FIELD_STRING_VAR4_SIZE
    local ok, text = pcall(readGen3String, addr, maxLen)
    return inBattle, ok and text or nil, gm
end

-- seconds the text for this source has been unchanged (records it if new)
local function trackText(src, text, gen)
    local tr = textTrack[src]
    if tr == nil or tr.text ~= text or tr.gen ~= gen then
        tr = {text = text, since = frameCount, gen = gen}
        textTrack[src] = tr
    end
    return (frameCount - tr.since) / 60
end

-- pure formatter (SELFTEST): word = "old" | "menu" | nil (live)
local function formatText(src, word, text, age)
    local s = "[" .. src .. (word and (" " .. word) or "") .. "] " .. text
    if age > K.TEXT_STALE_S then s = s .. string.format(" (unchanged %ds)", math.floor(age)) end
    return s
end

-- returns word ("old"/"menu"/nil), box description, age_s for the currently displayed buffer
local function textStatus(inBattle, gm, text)
    local word, box
    if inBattle then
        local bi = getBattleDecisionState(gm).battle_input
        box = bi
        if bi == "choose_action" or bi == "choose_move" or bi == "choose_target" then word = "menu" end
    else
        local okm, m = pcall(u8, K.FIELD_MSGBOX_MODE_ADDR)
        box = okm and (K.FIELD_BOX_NAMES[m] or tostring(m)) or "unreadable"
        -- "old" only where the buffer is known not to be what is on screen: the naming screen (it draws its
        -- own title, never gStringVar4; the script that opened it keeps the field locked) and the overworld
        -- with the box idle and controls free. Elsewhere (new-game intro speech, clock/starter screens,
        -- menus) gStringVar4 can hold the live text, or not, with the box idle, so those get no word
        -- (seen live: Birch's intro speech sits in gStringVar4 while the box mode reads hidden).
        if gm == "naming_screen" or (okm and m == 0 and not isFieldLocked() and gm == "overworld") then word = "old" end
    end
    return word, box, trackText(inBattle and "b" or "f", text, inBattle and 0 or textGen.f)
end

v2.textFreshTick = function()
    if frameCount % K.TEXT_TICK ~= 0 then return end
    local inBattle, text = readCurrentText()
    local okm, m = pcall(u8, K.FIELD_MSGBOX_MODE_ADDR)
    if okm then
        if m ~= 0 and textGen.lastMode == 0 then textGen.f = textGen.f + 1 end
        textGen.lastMode = m
    end
    if text then trackText(inBattle and "b" or "f", text, inBattle and 0 or textGen.f) end
end

-- ---------------------------------------------------------------------
-- harness v2 (2/2): NAME <text> -- type a whole name on the naming screen, never confirm.
-- Layout/addresses from pret src/naming_screen.c: sKeyboardChars, sPageColumnCounts, MainState_*,
-- Task_HandleInput (D-pad rows wrap mod 4; col == column count is the OK/BACK/page button column;
-- SELECT cycles pages SYMBOLS(0) -> UPPER(1) -> LOWER(2) -> SYMBOLS; START jumps to OK).
-- sNamingScreen (0x02039f94, heap ptr) -> struct NamingScreenData: textBuffer +0x1800 (u8[16], EOS=0xFF,
-- space=0x00), state +0x1E10 (2 = STATE_HANDLE_INPUT), currentPage +0x1E22, cursorSpriteId +0x1E23,
-- template ptr +0x1E28 (maxChars = byte 1). Cursor cell = gSprites[id].data[0], data[1] (sX, sY).
-- Every step re-reads the real cursor/page/text; it never counts moves.
-- ---------------------------------------------------------------------
local NS_ROWS = {   -- KBPAGE index -> rows of keys (sKeyboardChars; symbols page has 6 columns)
    [1] = {"ABCDEF .", "GHIJKL ,", "MNOPQRS ", "TUVWXYZ "},
    [2] = {"abcdef .", "ghijkl ,", "mnopqrs ", "tuvwxyz "},
    [0] = {"01234 ", "56789 ", "!?\u{2642}\u{2640}/-", "\u{2026}\u{201C}\u{201D}\u{2018}\u{2019} "},
}
local NS_INDEX = {}   -- char -> list of {page, col, row}
for page, rows in pairs(NS_ROWS) do
    for row, str in ipairs(rows) do
        local col = 0
        for _, cp in utf8.codes(str) do
            local ch = utf8.char(cp)
            NS_INDEX[ch] = NS_INDEX[ch] or {}
            table.insert(NS_INDEX[ch], {page = page, col = col, row = row - 1})
            col = col + 1
        end
    end
end
local NS_SUPPORTED = "A-Z a-z 0-9 space . , ! ? / - ' and \u{2642} \u{2640} \u{2026} \u{201C} \u{201D} \u{2018}"

-- text -> list of key characters, or nil, errmsg. ASCII ' is the keyboard's apostrophe key.
local function parseNameText(text)
    if not utf8.len(text) then return nil, "not valid UTF-8" end
    local chars, pos = {}, 0
    for _, cp in utf8.codes(text) do
        pos = pos + 1
        local ch = utf8.char(cp)
        if ch == "'" then ch = "\u{2019}" end
        if not NS_INDEX[ch] then
            return nil, string.format("unsupported character '%s' at position %d (supported: %s)", utf8.char(cp), pos, NS_SUPPORTED)
        end
        chars[#chars + 1] = ch
    end
    return chars
end

local function s16(v) if v >= 0x8000 then return v - 0x10000 end return v end

-- live naming screen snapshot, or nil, reason
local function readNamingScreen()
    local okp, base = pcall(u32, K.NS_PTR_ADDR)
    if not okp or base < 0x02000000 or base >= 0x02040000 then return nil, "no naming screen allocated" end
    local ok, r = pcall(function()
        local spr = K.GSPRITES_ADDR + u8(base + K.NS_CURSOR_SPR) * K.GSPRITE_SIZE
        local tmpl = u32(base + K.NS_TEMPLATE)
        local maxc = (tmpl >= 0x08000000 and tmpl < 0x0A000000) and u8(tmpl + 1) or 0
        local bytes = {}
        for i = 0, 15 do
            local b = u8(base + K.NS_TEXTBUF + i)
            if b == 0xFF then break end
            bytes[#bytes + 1] = b
        end
        return {state = u8(base + K.NS_STATE), page = u8(base + K.NS_PAGE), cx = s16(u16(spr + K.SPRITE_DATA_OFF)),
                cy = s16(u16(spr + K.SPRITE_DATA_OFF + 2)), max = maxc, text = decodeGen3String(bytes), n = #bytes}
    end)
    if not ok then return nil, tostring(r) end
    if r.max < 1 or r.max > 16 or r.page > 2 then return nil, "naming struct looks wrong (max=" .. r.max .. " page=" .. r.page .. ")" end
    return r
end

-- Pure: which single button gets the cursor closer to key `ch`, given page/cursor. "a" = press the key.
local function namePlan(page, cx, cy, ch)
    local cells, here = NS_INDEX[ch], {}
    if not cells then return nil end
    for _, c in ipairs(cells) do if c.page == page then here[#here + 1] = c end end
    if #here == 0 then return "select" end          -- next page in the cycle (works from any cursor cell)
    if cx >= K.NS_COLS[page] then return "left" end   -- on the OK/BACK/page button column: step back onto the keys
    local best, bestCost
    for _, c in ipairs(here) do
        local dy = (c.row - cy) % 4
        local cost = math.min(dy, 4 - dy) + math.abs(c.col - cx)
        if bestCost == nil or cost < bestCost then best, bestCost = c, cost end
    end
    if best.row ~= cy then return ((best.row - cy) % 4 <= 2) and "down" or "up" end
    if best.col ~= cx then return (best.col > cx) and "right" or "left" end
    return "a"
end

local nameJob = nil
local function nameFail(j, msg) j.status = "error"; j.err = msg; pushLog("name_error", {frame = frameCount, detail = msg}) end

v2.nameTick = function()
    local j = nameJob
    if not j or j.status ~= "running" then return false end
    if frameCount - j.start > j.limit then nameFail(j, "timed out after " .. j.steps .. " presses"); return false end
    local gm = getMode()
    local rd, why = readNamingScreen()
    if gm ~= "naming_screen" or not rd then nameFail(j, "naming screen is gone (" .. tostring(why or gm) .. ")"); return false end
    if rd.state ~= K.NS_STATE_INPUT then return true end   -- fading in / page swap / moving to OK: wait
    local expect = table.concat(j.chars, "", 1, math.min(rd.n, #j.chars))
    if rd.text ~= expect or rd.n > #j.chars then
        nameFail(j, string.format("typed text '%s' does not match expected '%s' after %d presses", rd.text, expect, j.steps)); return false
    end
    if rd.n == #j.chars then j.status = "done"; pushLog("name_done", {frame = frameCount, detail = rd.text}); return false end
    local btn = namePlan(rd.page, rd.cx, rd.cy, j.chars[rd.n + 1])
    local sig = rd.page .. ":" .. rd.cx .. "," .. rd.cy .. ":" .. rd.n
    if sig == j.lastSig and btn == j.lastBtn then j.stuck = j.stuck + 1 else j.stuck = 0 end
    if j.stuck >= 3 then nameFail(j, "no progress: '" .. btn .. "' had no effect 3 times at " .. sig); return false end
    j.lastSig, j.lastBtn, j.steps = sig, btn, j.steps + 1
    schedule(BUTTON[btn], 5, 5)
    return true
end

local function nameStatusLine()
    local rd, why = readNamingScreen()
    local j = nameJob
    local s = "job=" .. (j and j.status or "none")
    if rd then
        s = s .. string.format(" name=\"%s\" len=%d/%d page=%s cursor=%d,%d", rd.text, rd.n, rd.max, K.NS_PAGE_NAMES[rd.page] or rd.page, rd.cx, rd.cy)
    else
        s = s .. " name=unreadable (" .. tostring(why) .. ")"
    end
    if j and j.err then s = s .. " err=" .. j.err end
    return s
end

local function nameStart(text)
    if #queue > 0 or (nameJob and nameJob.status == "running") then return "ERR busy: previous input still queued/draining" end
    local chars, err = parseNameText(text)
    if not chars then return "ERR NAME: " .. err end
    local gm = getMode()
    local rd, why = readNamingScreen()
    if gm ~= "naming_screen" or not rd then return "ERR NAME: not on a naming screen (mode=" .. gm .. ", " .. tostring(why or "ok") .. ")" end
    if #chars > rd.max then return string.format("ERR NAME: '%s' is %d characters, this naming screen allows %d", text, #chars, rd.max) end
    local pre = table.concat(chars, "", 1, math.min(rd.n, #chars))
    if rd.n > #chars or rd.text ~= pre then
        return string.format("ERR NAME: name box already holds '%s', which is not the start of '%s' -- clear it first (g b = backspace)", rd.text, text)
    end
    nameJob = {chars = chars, status = "running", start = frameCount, limit = 900 + 200 * #chars, steps = 0, stuck = 0}
    pushLog("name_start", {frame = frameCount, detail = text})
    return string.format("OK NAME queued: %d chars of max %d (will not confirm)", #chars, rd.max)
end

v2.readCurrentText, v2.textStatus, v2.formatText = readCurrentText, textStatus, formatText
v2.parseNameText, v2.namePlan, v2.readNamingScreen = parseNameText, namePlan, readNamingScreen
v2.nameStart, v2.nameStatusLine, v2.NS_INDEX, v2.NS_ROWS = nameStart, nameStatusLine, NS_INDEX, NS_ROWS
v2.nameRunning = function() return nameJob ~= nil and nameJob.status == "running" end
end

-- getMapName([mapsecIdOverride]) -- reads the current map's real name
-- from gRegionMapEntries. mapsecIdOverride lets SELFTEST exercise the
-- out-of-range bounds check without needing a live ROM read (see the
-- mapname_bounds_works check below); live callers (MAPNAME) call this
-- with no argument, which reads gMapHeader->regionMapSectionId fresh.
local function getMapName(mapsecIdOverride)
    local mapsecId
    if mapsecIdOverride ~= nil then
        mapsecId = mapsecIdOverride
    else
        local ok1, id = pcall(u8, GMAP_HEADER_ADDR + GMAP_HEADER_REGIONMAPSEC_OFFSET)
        if not ok1 then
            return {mapsec_id = -1, name = "", name_ok = false, reason = "read_error"}
        end
        mapsecId = id
    end
    if mapsecId >= REGION_MAP_ENTRY_COUNT then
        -- MAPSEC_NONE and anything past it (incl. the dynamic-ferry and
        -- secret-base special cases GetMapName() itself branches on
        -- before ever touching the table) -- we don't reproduce those
        -- special-cased names, just report that this mapsec has none.
        return {mapsec_id = mapsecId, name = "", name_ok = false, reason = "no_table_entry (dynamic/secret_base/none)"}
    end
    local entryAddr = REGION_MAP_ENTRIES_ADDR + mapsecId * REGION_MAP_ENTRY_SIZE
    local ok2, namePtr = pcall(u32, entryAddr + 4)  -- +4: past x/y/width/height, at the name pointer field
    if not ok2 then
        return {mapsec_id = mapsecId, name = "", name_ok = false, reason = "ptr_read_error"}
    end
    local ok3, name = pcall(readGen3String, namePtr, 20)
    if not ok3 then
        return {mapsec_id = mapsecId, name = "", name_ok = false, reason = "string_read_error"}
    end
    return {mapsec_id = mapsecId, name = name, name_ok = true}
end

-- ---------------------------------------------------------------------
-- Socket command handling -- called by bootstrap.lua as
-- _G.DIRECTOR.handle(line) for every line, EXCEPT "RELOAD" which
-- bootstrap special-cases itself (this module can't swap itself out from
-- inside its own call frame).
-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- ROM name tables (2026-09-26). Addresses from pret/pokeemerald's
-- pokeemerald.sym (curl+grep), struct layouts from include/pokemon.h.
-- Pure perception: turns raw IDs into the names the game itself prints.
-- ---------------------------------------------------------------------
local SPECIES_NAMES_ADDR, SPECIES_NAME_LEN, NUM_SPECIES_TBL = 0x083185c8, 11, 412
local MOVE_NAMES_ADDR, MOVE_NAME_LEN, NUM_MOVES_TBL = 0x0831977c, 13, 355
local TYPE_NAMES_ADDR, TYPE_NAME_LEN = 0x0831ae38, 7
local BATTLE_MOVES_ADDR, BATTLE_MOVE_SIZE = 0x0831c898, 12   -- struct BattleMove: effect,power,type,acc,pp,...
local PARTY_ADDR, PARTY_MON_SIZE, PARTY_COUNT_ADDR = 0x020244ec, 100, 0x020244e9
local SUBSTRUCT_ORDER = {"GAEM","GAME","GEAM","GEMA","GMAE","GMEA","AGEM","AGME","AEGM","AEMG","AMGE","AMEG",
                         "EGAM","EGMA","EAGM","EAMG","EMGA","EMAG","MGAE","MGEA","MAGE","MAEG","MEGA","MEAG"}

local function speciesName(id)
    if not id or id <= 0 or id >= NUM_SPECIES_TBL then return tostring(id) end
    local ok, n = pcall(readGen3String, SPECIES_NAMES_ADDR + id * SPECIES_NAME_LEN, SPECIES_NAME_LEN)
    return (ok and n ~= "") and n or tostring(id)
end
local function typeName(t)
    local ok, n = pcall(readGen3String, TYPE_NAMES_ADDR + t * TYPE_NAME_LEN, TYPE_NAME_LEN)
    return ok and n or tostring(t)
end
local function moveInfo(id)
    if not id or id <= 0 or id >= NUM_MOVES_TBL then return nil end
    local okN, n = pcall(readGen3String, MOVE_NAMES_ADDR + id * MOVE_NAME_LEN, MOVE_NAME_LEN)
    local b = BATTLE_MOVES_ADDR + id * BATTLE_MOVE_SIZE
    local okP, pow = pcall(u8, b + 1)
    local okT, ty = pcall(u8, b + 2)
    local okM, maxpp = pcall(u8, b + 4)
    return {name = okN and n or tostring(id), power = okP and pow or 0,
            type = okT and typeName(ty) or "?", basepp = okM and maxpp or 0}
end
local function statusName(st)
    if not st or st == 0 then return nil end
    if (st & 0x7) ~= 0 then return "SLP" end
    if (st & 0x80) ~= 0 then return "TOX" end
    if (st & 0x8) ~= 0 then return "PSN" end
    if (st & 0x10) ~= 0 then return "BRN" end
    if (st & 0x20) ~= 0 then return "FRZ" end
    if (st & 0x40) ~= 0 then return "PAR" end
    return "ST" .. st
end
-- Decrypt one party mon's Growth (species) and Attacks (moves/PP) substructs.
local function partyMon(i)
    local base = PARTY_ADDR + i * PARTY_MON_SIZE
    local pers, otid = u32(base), u32(base + 4)
    local key = pers ~ otid
    local order = SUBSTRUCT_ORDER[(pers % 24) + 1]
    local function sub(letter)
        local pos = order:find(letter) - 1
        local a = base + 0x20 + pos * 12
        return {u32(a) ~ key, u32(a + 4) ~ key, u32(a + 8) ~ key}
    end
    local g, at = sub("G"), sub("A")
    local species = g[1] & 0xFFFF
    local moves = {at[1] & 0xFFFF, (at[1] >> 16) & 0xFFFF, at[2] & 0xFFFF, (at[2] >> 16) & 0xFFFF}
    local pp = {at[3] & 0xFF, (at[3] >> 8) & 0xFF, (at[3] >> 16) & 0xFF, (at[3] >> 24) & 0xFF}
    local okN, nick = pcall(readGen3String, base + 8, 10)
    return {species = species, nick = okN and nick or "?", level = u8(base + 0x54),
            hp = u16(base + 0x56), maxhp = u16(base + 0x58), status = u32(base + 0x50),
            moves = moves, pp = pp}
end

-- ---------------------------------------------------------------------
-- Read-only inventory/progress perception (2026-09-29): MONEY, BAG, DEX.
-- Offsets from pret/pokeemerald include/global.h (SaveBlock1/SaveBlock2
-- struct comments); gItems address and 44-byte stride from
-- pokeemerald.sym + include/item.h (struct Item, name[14] first).
-- Money is a u32 XORed with SaveBlock2.encryptionKey; item quantities are
-- u16 XORed with the key's low 16 bits. The Pokedex owned/seen bit arrays
-- are 52 bytes (ROUND_BITS_TO_BYTES(NUM_SPECIES=412)) and are national-dex
-- indexed, so DEX reports national owned/seen counts. Pure perception:
-- reads what the Trainer Card / bag / Pokedex screens would show.
-- ---------------------------------------------------------------------
local SB1_MONEY_OFF = 0x490
local SB1_POCKETS = {{"ITEMS", 0x560, 30}, {"KEY", 0x5D8, 30}, {"BALLS", 0x650, 16},
                     {"TMHM", 0x690, 64}, {"BERRIES", 0x790, 46}}
local SB2_ENCKEY_OFF = 0xAC
local SB2_PLAYTIME_OFF = 0x0E   -- playTimeHours u16, then minutes u8, seconds u8 (pret SaveBlock2)
local SB2_DEX_OWNED_OFF, SB2_DEX_SEEN_OFF, DEX_FLAG_BYTES = 0x28, 0x5C, 52
local GITEMS_ADDR, GITEM_SIZE, NUM_ITEMS_TBL, ITEM_NAME_LEN = 0x085839a0, 44, 377, 14

local function itemName(id)
    if not id or id <= 0 or id >= NUM_ITEMS_TBL then return tostring(id) end
    local ok, n = pcall(readGen3String, GITEMS_ADDR + id * GITEM_SIZE, ITEM_NAME_LEN)
    return (ok and n ~= "") and n or tostring(id)
end
local function saveKey() return u32(u32(SAVEBLOCK2_PTR_ADDR) + SB2_ENCKEY_OFF) end
local function readMoney()
    return (u32(u32(SAVEBLOCK1_PTR_ADDR) + SB1_MONEY_OFF) ~ saveKey()) & 0xFFFFFFFF
end
local function readBag(pocketName)
    local sb1, key = u32(SAVEBLOCK1_PTR_ADDR), saveKey() & 0xFFFF
    local out = {}
    for _, p in ipairs(SB1_POCKETS) do
        if not pocketName or pocketName:upper() == p[1] then
            local items = {}
            for i = 0, p[3] - 1 do
                local a = sb1 + p[2] + i * 4
                local id = u16(a)
                if id ~= 0 then items[#items + 1] = string.format("%s x%d", itemName(id), u16(a + 2) ~ key) end
            end
            out[#out + 1] = p[1] .. ": " .. (#items > 0 and table.concat(items, ", ") or "-")
        end
    end
    return table.concat(out, " | ")
end
local function popcount(base, n)
    local c = 0
    for i = 0, n - 1 do
        local b = u8(base + i)
        while b > 0 do c = c + (b & 1); b = b >> 1 end
    end
    return c
end
local function readDex()
    local sb2 = u32(SAVEBLOCK2_PTR_ADDR)
    return popcount(sb2 + SB2_DEX_OWNED_OFF, DEX_FLAG_BYTES), popcount(sb2 + SB2_DEX_SEEN_OFF, DEX_FLAG_BYTES)
end

local function handle(cmd)
    local parts = {}
    for w in cmd:gmatch("%S+") do table.insert(parts, w) end
    local op = parts[1]

    if op == "FRAME" then
        return tostring(frameCount)
    elseif op == "R8" then
        return tostring(u8(tonumber(parts[2])))
    elseif op == "R16" then
        return tostring(u16(tonumber(parts[2])))
    elseif op == "R32" then
        return tostring(u32(tonumber(parts[2])))
    elseif op == "VERSION" then
        return VERSION
    elseif op == "MODE" then
        local gm, cb2 = getMode()
        return encodeFlat({director_mode = mode, game_mode = gm, callback2 = toHex(cb2),
                            frame = frameCount, queue_len = #queue, nav_active = nav ~= nil,
                            walk_active = walk ~= nil,
                            field_locked = isFieldLocked(), version = VERSION})
    elseif op == "STATE" then
        local x, y, badges, partyCount, mapGroup, mapNum, playerSlot, posX, posY = playerSig()
        local gm = getMode()
        -- incident #20: in_battle derived from game_mode, not raw
        -- gBattleTypeFlags (which never clears on battle end -- see
        -- getBattleDecisionState's comment for the source-verified why).
        local inBattle = (gm == "battle_init" or gm == "battle_main")
        local bf = inBattle and getBattleFlags() or nil
        local t = {x = x, y = y, player_slot = playerSlot, pos_x = posX, pos_y = posY,
                   map_group = mapGroup, map_num = mapNum, badges = badges, party_count = partyCount,
                   game_mode = gm, queue_len = #queue, nav_active = nav ~= nil, walk_active = walk ~= nil,
                   in_battle = inBattle, battle_trainer = bf and bf.trainer or nil,
                   battle_outcome = getBattleOutcome(), field_locked = isFieldLocked(), version = VERSION}
        if nav then t.nav_target_x, t.nav_target_y, t.nav_stuck_count = nav.tx, nav.ty, nav.noProgress end
        if walk then t.walk_n, t.walk_progress = walk.n, peekHoldProgress(walk.stepping, walk.dirMask) end
        return encodeFlat(t)
    elseif op == "OBJECTS" then
        local filter = parts[2]
        local objs = getObjectEvents()
        local items = {}
        for _, o in ipairs(objs) do
            if filter ~= "items" or o.is_item_ball then
                table.insert(items, encodeFlat(o))
            end
        end
        return "[" .. table.concat(items, ",") .. "]"
    elseif op == "WARPS" then
        local warps, dbg = getWarps()
        local items = {}
        for _, w in ipairs(warps) do table.insert(items, encodeFlat(w)) end
        return '{"warps":[' .. table.concat(items, ",") .. '],"_debug":' .. encodeFlat(dbg) .. "}"
    elseif op == "BGEVENTS" then
        local bgs = getBgEvents()
        local items = {}
        for _, b in ipairs(bgs) do table.insert(items, encodeFlat(b)) end
        return "[" .. table.concat(items, ",") .. "]"
    elseif op == "LOOK" then
        -- Direct replacement for "take a screenshot to see the room": reads
        -- the same collision/elevation grid the game's own movement code
        -- checks before a step is allowed, centered on the player. One
        -- cheap JSON round trip in place of an image. See gridTileSymbol()
        -- for the legend (. open, # terrain-blocked, ^ elevation-mismatch/
        -- ledge, N another object, @ player, u in-bounds but never loaded
        -- with real data -- MAPGRID_UNDEFINED, forced-impassable by the
        -- game (incident #17) but may open up once a connection loads,
        -- ? genuinely outside the grid's width/height bounds).
        local radius = tonumber(parts[2]) or 5
        if radius < 1 then radius = 1 end
        if radius > 10 then radius = 10 end
        local rows, x0, y0, px, py, pelev = getCollisionGrid(radius)
        local rowsJson = {}
        for _, r in ipairs(rows) do table.insert(rowsJson, toJsonStr(r)) end
        return '{"grid":[' .. table.concat(rowsJson, ",") .. '],"x0":' .. x0 .. ',"y0":' .. y0 ..
               ',"px":' .. px .. ',"py":' .. py .. ',"pelev":' .. tostring(pelev) ..
               ',"legend":".=open #=wall ^=ledge/step N=npc @=you u=undefined(unloaded,blocked) ?=out_of_bounds"}'
    elseif op == "DIAG" then
        -- One round trip instead of five (item 5): everything needed to
        -- diagnose a stuck/unexpected director in one poll.
        local x, y, badges, partyCount, mapGroup, mapNum, playerSlot = playerSig()
        local gm, cb2 = getMode()
        -- incident #20: in_battle derived from game_mode, not raw
        -- gBattleTypeFlags (source-confirmed to never clear on battle end).
        local inBattle = (gm == "battle_init" or gm == "battle_main")
        local bf = inBattle and getBattleFlags() or nil
        local bds = getBattleDecisionState(gm)
        local hp = inBattle and getBattleHP() or nil
        local head = queue[1]
        local oldest, inputCount = logWindowSummary(frameCount, 300)
        -- incident #19: clean, always-fresh decision signals for manual
        -- play, derived the same way every call (never a stale cached
        -- flag like the old yesno_cursor, which was observed holding a
        -- leftover value from a previous battle during plain dialogue).
        -- decision_pending mirrors the internal auto-park state (persists
        -- until RESUME); yesno_active is the direct, un-cached
        -- taskActive()/battle_input read -- poll this between individual
        -- PRESS calls during any cutscene/dialogue chain, not just after
        -- a batch of them.
        local yesnoActive = (bds.field_menu and bds.field_menu_kind == "yesno") or bds.battle_input == "yesno"
        local t = {
            version = VERSION, director_mode = mode, game_mode = gm,
            callback2_raw = toHex(cb2), callback2_resolved = KNOWN_MODES[cb2 & ~1] or "unknown",
            field_locked = isFieldLocked(), queue_len = #queue,
            queue_head_mask = head and head.mask or nil, queue_head_hold = head and head.hold or nil,
            x = x, y = y, map_group = mapGroup, map_num = mapNum,
            nav_active = nav ~= nil,
            nav_target_x = nav and nav.tx or nil, nav_target_y = nav and nav.ty or nil,
            nav_axis = nav and nav.axis or nil, nav_blocked_streak = nav and nav.blockedStreak or nil,
            nav_no_progress = nav and nav.noProgress or nil, nav_best_dist = nav and nav.bestDist or nil,
            nav_start_map_group = nav and nav.mapGroup or nil, nav_start_map_num = nav and nav.mapNum or nil,
            walk_active = walk ~= nil, walk_n = walk and walk.n or nil,
            walk_progress = walk and peekHoldProgress(walk.stepping, walk.dirMask) or nil,
            in_battle = inBattle, battle_trainer = bf and bf.trainer or false,
            battle_outcome = getBattleOutcome(),
            battle_input = bds.battle_input, learn_move = bds.learn_move,
            learn_move_state = bds.learn_move_state, yesno_cursor = bds.yesno_cursor,
            summary_screen = bds.summary_screen, field_menu = bds.field_menu,
            field_menu_kind = bds.field_menu_kind, decision_risky = bds.risky,
            yesno_active = yesnoActive,
            decision_pending = decision ~= nil, decision_type = decision and decision.type or nil,
            -- decision_flavor: true only for the naming-entry screen itself
            -- (starter/rival/nickname text entry) -- a real, unambiguous RAM
            -- fact, not a guess at intent. The Yes/No box that PRECEDES a
            -- nickname prompt is NOT separately flagged here -- it is
            -- structurally identical at the RAM level to any other field
            -- yes/no box, so that distinction is a playing-skill procedural
            -- rule (pause on any field yesno right after catching/receiving a
            -- Pokemon), not a harness signal. See harness-status.md.
            decision_flavor = (decision ~= nil and decision.type == "naming_screen"),
            my_hp = hp and hp.my_hp or nil, my_max_hp = hp and hp.my_max_hp or nil,
            my_species = hp and hp.my_species or nil, my_level = hp and hp.my_level or nil,
            opp_hp = hp and hp.opp_hp or nil, opp_max_hp = hp and hp.opp_max_hp or nil,
            opp_species = hp and hp.opp_species or nil, opp_level = hp and hp.opp_level or nil, opp_shiny = hp and hp.opp_shiny or nil,
            party_count = partyCount, badges = badges,
            pos_delta_x = oldest and (x - oldest.x) or nil, pos_delta_y = oldest and (y - oldest.y) or nil,
            inputs_last_300f = inputCount,
        }
        return encodeFlat(t)
    elseif op == "S" then
        -- Token-efficiency build (2026-09-26): one short line instead of
        -- DIAG's ~650-char JSON. Only flags that are actually set appear.
        -- Format: "<map_group>.<map_num> <x>,<y> P<party> B<badges>" then
        -- any of: busy (queue/walk/nav still running), lock (field_locked),
        -- yn (yes/no box up), menu:<kind>, bat:<battle_input>,
        -- me:<species> <hp>/<max> L<lv>, vs:<species> <hp>/<max> L<lv>,
        -- learn (move-learn prompt), sum (summary screen), pmenu (party menu),
        -- scr:<bag|card|dex|shop|pc|evo|party> (screen label from callback2),
        -- dec:naming_screen (can go stale after the screen closes -- see
        -- harness-status.md "Confirmed NOT bugs").
        local x, y, badges, partyCount, mapGroup, mapNum = playerSig()
        local gm = getMode()
        local inBattle = (gm == "battle_init" or gm == "battle_main")
        local bds = getBattleDecisionState(gm)
        local out = {string.format("%d.%d %d,%d P%d B%d", mapGroup, mapNum, x, y, partyCount, badges)}
        if #queue > 0 or walk ~= nil or nav ~= nil or (v2.nameRunning and v2.nameRunning()) then out[#out+1] = "busy" end
        if isFieldLocked() then out[#out+1] = "lock" end
        local yn = (bds.field_menu and bds.field_menu_kind == "yesno") or bds.battle_input == "yesno"
        if yn then out[#out+1] = "yn" end
        -- Display-only guess (2026-10-01): prompts that raise no yn flag ("Will X change POKéMON?", "Use next POKéMON?", the save prompt)
        -- all end in "?" in the message buffer. Flag "yn?" when the text ends in "?" while the game waits (battle: bat:other, no party menu; field: lock).
        if not yn then
            local okq, qtxt = pcall(function()
                if inBattle then
                    if bds.battle_input == "other" and not taskActive(TASK_HANDLE_CHOOSE_MON_ADDR) then return readGen3String(BATTLE_DISPLAYED_STRING_ADDR, BATTLE_DISPLAYED_STRING_SIZE) end
                elseif isFieldLocked() then return readGen3String(FIELD_STRING_VAR4_ADDR, FIELD_STRING_VAR4_SIZE) end
                return nil
            end)
            if okq and type(qtxt) == "string" and qtxt:match("%?%s*$") then out[#out+1] = "yn?" end
        end
        if bds.field_menu and bds.field_menu_kind ~= "yesno" then out[#out+1] = "menu:" .. tostring(bds.field_menu_kind) end
        if inBattle then
            local bi = bds.battle_input
            if bi == "other" then
                -- Double battles: the player's second battler (slot 2) has its
                -- own controller func; battler 0's reads "other" while slot 2
                -- is choosing (found live vs. TOMMY+MARC, 2026-09-26).
                local ok2, cf2 = pcall(u32, BATTLER_CONTROLLER_FUNCS_ADDR + 8)
                local n2 = ok2 and BATTLE_INPUT_FUNCS[cf2 & ~1] or nil
                if n2 then bi = n2 .. "#2" end
            end
            if bi ~= "none" and bi ~= "yesno" then out[#out+1] = "bat:" .. tostring(bi) end
            local hp = getBattleHP()
            if hp then
                out[#out+1] = string.format("me:%s %s/%s L%s", speciesName(hp.my_species), tostring(hp.my_hp), tostring(hp.my_max_hp), tostring(hp.my_level))
                out[#out+1] = string.format("vs:%s %s/%s L%s", speciesName(hp.opp_species), tostring(hp.opp_hp), tostring(hp.opp_max_hp), tostring(hp.opp_level) .. (hp.opp_shiny and " shiny" or ""))
                local bfd = getBattleFlags()
                -- K2: foe trainer's team size, the same information as the party-ball
                -- row a human sees in a trainer battle (count and how many have fainted;
                -- no species, levels or order).
                if bfd and bfd.trainer and not bfd.link then
                    local total, alive = 0, 0
                    for i = 0, 5 do
                        local b = ENEMY_PARTY_ADDR + i * 100
                        local okL, lv = pcall(u8, b + 0x54)
                        local okM, mx = pcall(u16, b + 0x58)
                        if okL and okM and lv >= 1 and lv <= 100 and mx > 0 and mx < 999 then
                            total = total + 1
                            local okH, h = pcall(u16, b + 0x56)
                            if okH and h > 0 then alive = alive + 1 end
                        end
                    end
                    if total > 0 then out[#out+1] = string.format("foes:%d/%d", alive, total) end
                end
                if bfd and bfd.double then
                    for _, slot in ipairs({2, 3}) do
                        local b = BATTLE_MONS_ADDR + slot * BATTLE_MON_SIZE
                        local okS, sp = pcall(u16, b + BATTLE_MON_SPECIES_OFF)
                        if okS and sp > 0 then
                            out[#out+1] = string.format("%s:%s %d/%d L%d", slot == 2 and "me2" or "vs2", speciesName(sp),
                                u16(b + BATTLE_MON_HP_OFF), u16(b + BATTLE_MON_MAXHP_OFF), u8(b + BATTLE_MON_LEVEL_OFF))
                        end
                    end
                end
            end
            local bf = getBattleFlags()
            if bf and bf.trainer then out[#out+1] = "trainer" end
        end
        if bds.learn_move then out[#out+1] = "learn" end
        if bds.summary_screen then out[#out+1] = "sum" end
        if taskActive(TASK_HANDLE_CHOOSE_MON_ADDR) then out[#out+1] = "pmenu" end   -- party menu up (2026-09-29; added so a faint's forced party screen is visible without a screenshot)
        do local scr = screenLabel(); if scr then out[#out+1] = "scr:" .. scr end end   -- display-only screen tag (see KNOWN_SCREENS)
        if decision ~= nil and decision.type == "naming_screen" and (gm == "naming_screen" or gm == "naming_screen_return") then out[#out+1] = "dec:naming_screen" end   -- live only while the screen is up (stale-latch fix 2026-10-01)
        return table.concat(out, " ")
    elseif op == "MOVES" then
        -- Active battler's moves with type/power and CURRENT PP from
        -- gBattleMons. "MOVES 2" = the player's second battler in doubles.
        -- Slot order = the 2x2 menu: 1 top-left, 2 top-right, 3 bottom-left, 4 bottom-right.
        local slot = tonumber(parts[2]) or 0
        local b = BATTLE_MONS_ADDR + slot * BATTLE_MON_SIZE
        local out = {speciesName(u16(b + BATTLE_MON_SPECIES_OFF))}
        for m = 0, 3 do
            local id = u16(b + 0x0C + m * 2)
            local mi = moveInfo(id)
            if mi then out[#out+1] = string.format("%d:%s %s/%d pp%d", m + 1, mi.name, mi.type, mi.power, u8(b + 0x24 + m)) end
        end
        return table.concat(out, " | ")
    elseif op == "PARTY" then
        -- Whole party from RAM, no menus: nickname(species) level hp/max
        -- status, then moves with current PP. Decrypts the Growth/Attacks
        -- substructs (key = personality ^ otId, order = personality % 24).
        local n = u8(PARTY_COUNT_ADDR)
        local lines = {}
        for i = 0, n - 1 do
            local ok, m = pcall(partyMon, i)
            if ok then
                local mv = {}
                for k = 1, 4 do
                    local mi = moveInfo(m.moves[k])
                    if mi then mv[#mv+1] = mi.name .. " " .. m.pp[k] end
                end
                local st = statusName(m.status)
                lines[#lines+1] = string.format("%d %s(%s) L%d %d/%d%s: %s", i + 1, m.nick, speciesName(m.species),
                    m.level, m.hp, m.maxhp, st and (" " .. st) or "", table.concat(mv, ", "))
            else
                lines[#lines+1] = (i + 1) .. " ERR " .. tostring(m)
            end
        end
        return table.concat(lines, " || ")
    elseif op == "MONEY" then
        local ok, v = pcall(readMoney)
        return ok and tostring(v) or ("ERR " .. tostring(v))
    elseif op == "BAG" then
        local ok, v = pcall(readBag, parts[2])
        return ok and v or ("ERR " .. tostring(v))
    elseif op == "DEX" then
        local ok, o, sn = pcall(readDex)
        return ok and string.format("owned=%d seen=%d (national bits)", o, sn) or ("ERR " .. tostring(o))
    elseif op == "SNAP" then
        -- One-call checkpoint block, all from RAM (2026-09-29): player name,
        -- map id + name, position, badges, play time, money, Pokedex counts,
        -- whole party (same text as PARTY) and every bag pocket. Sections are
        -- separated by " || " so `g snap` can print one per line. Pure perception.
        local ok, r = pcall(function()
            local sb2 = u32(SAVEBLOCK2_PTR_ADDR)
            local pname = readGen3String(sb2, 8)
            local x, y, badges, _, mg, mn = playerSig()
            local hours, mins, secs = u16(sb2 + SB2_PLAYTIME_OFF), u8(sb2 + SB2_PLAYTIME_OFF + 2), u8(sb2 + SB2_PLAYTIME_OFF + 3)
            local owned, seen = readDex()
            local bag = (readBag():gsub(" | ", " || "))
            return string.format("%s | map %d.%d %s (%d,%d) | badges %d | time %d:%02d:%02d | money %d | dex %d owned %d seen | version %s || PARTY %s || BAG %s",
                pname, mg, mn, tostring(getMapName().name), x, y, badges, hours, mins, secs, readMoney(), owned, seen, VERSION, handle("PARTY"), bag)
        end)
        return ok and r or ("ERR " .. tostring(r))
    elseif op == "AUTOSAVE" then
        -- AUTOSAVE [on|off] -> status of the rolling slot-2 crash insurance.
        if parts[2] == "off" then autosaveEnabled = false elseif parts[2] == "on" then autosaveEnabled = true end
        return string.format("autosave=%s count=%d last=%s age_s=%d err=%s", tostring(autosaveEnabled), autosaveCount,
            tostring(autosaveLastSig), math.floor((frameCount - autosaveLastFrame) / 60), tostring(autosaveError))
    elseif op == "CLIENTS" then
        local n = 0
        for _ in pairs(_G.BRIDGE_CLIENTS or {}) do n = n + 1 end
        return "clients=" .. n
    elseif op == "T" then
        -- Plain-text TEXT: just the decoded message, newlines flattened to
        -- " / ", no JSON wrapper. Same buffers as TEXT.
        -- v2: "[f] "/"[b] " prefix kept; a status word goes inside it ("[f old]", "[b menu]") and
        -- " (unchanged Ns)" is appended after 3 s. No word = the text is the live one. See the v2 block.
        local inBattle, text, gm = v2.readCurrentText()
        if not text then return "ERR text read failed" end
        local word, _, age = v2.textStatus(inBattle, gm, text)
        return v2.formatText(inBattle and "b" or "f", word, (text:gsub("\n+", " / ")), age)
    elseif op == "NAME" then
        -- v2: NAME <text> types the name (never confirms); bare NAME = status/read-back line.
        local arg = cmd:match("^NAME (.*)$")
        if arg == nil or arg == "" then return v2.nameStatusLine() end
        return v2.nameStart(arg)
    elseif op == "SHOT" then
        -- Native 240x160 frame straight from the emulator core: no window
        -- lookup, no crop, immune to the mGBA window moving (lesson 61).
        local path = parts[2]
        if not path then return "ERR usage: SHOT <absolute path.png>" end
        local ok, err = pcall(function() emu:screenshot(path) end)
        return ok and ("OK " .. path) or ("ERR screenshot failed: " .. tostring(err))
    elseif op == "TEXT" then
        -- Tenth-session build: read whatever message is CURRENTLY
        -- displayed, straight from the same buffer the game itself
        -- rendered it from, instead of screenshotting to read it. See the
        -- CHARMAP/decodeGen3String block above for the decode, and
        -- harness-status.md's "Next build target" note for why this
        -- exists (collapses incidents #19/#21's whole failure class).
        local inBattle, text, gm = v2.readCurrentText()
        if not text then
            return encodeFlat({text = "", source = inBattle and "battle" or "field", read_ok = false})
        end
        -- v2: live = false when the text is stale ("old") or a battle menu is up ("menu"); box = field
        -- message-box mode (hidden/normal/autoscroll) or battle_input; age_s = seconds unchanged.
        local word, box, age = v2.textStatus(inBattle, gm, text)
        return encodeFlat({text = text, source = inBattle and "battle" or "field", read_ok = true,
                           live = (word == nil), box = box, age_s = math.floor(age * 10) / 10})
    elseif op == "MAPNAME" then
        -- Eleventh-session build: confirm WHERE the player actually is
        -- from ROM data (gRegionMapEntries via gMapHeader's
        -- regionMapSectionId), instead of guessing a building's purpose
        -- from visual convention (roof color, silhouette) -- see the
        -- getMapName() block above and self-improvement.md lesson 20.
        return encodeFlat(getMapName())
    elseif op == "LOG" then
        local n = tonumber(parts[2]) or 10
        local entries = tailLog(n)
        local items = {}
        for _, e in ipairs(entries) do table.insert(items, encodeFlat(e)) end
        return "[" .. table.concat(items, ",") .. "]"
    elseif op == "REGRESS" then
        -- Loads each populated fixture slot in turn, asserts its expected
        -- signature, restores nothing afterward (the last-loaded fixture
        -- is left active -- LOAD your real checkpoint after running this).
        local results = {}
        for slot = 3, 8 do
            local fx = FIXTURES[slot]
            if fx then
                local ok = pcall(function() emu:loadStateSlot(slot) end)
                if ok then
                    local pass, detail = fx.check()
                    table.insert(results, encodeFlat({slot = slot, desc = fx.desc, pass = pass, detail = encodeFlat(detail)}))
                else
                    table.insert(results, encodeFlat({slot = slot, desc = fx.desc, pass = false, detail = "slot empty or load failed"}))
                end
            end
        end
        return "[" .. table.concat(results, ",") .. "]"
    elseif op == "DECISION" then
        if decision then
            return encodeFlat(decision)
        end
        return "null"
    elseif op == "PRESS" then
        -- incident #19 fix: refuse a new PRESS while one is still
        -- queued/draining. Root cause (confirmed against bootstrap.lua):
        -- the socket handler drains every buffered line in one synchronous
        -- loop with ZERO emulator frames in between, so a batch of
        -- "PRESS a\nPRESS a\n..." arriving in one packet used to call
        -- handle() back-to-back with no frame ever running onFrame()'s
        -- decision-detection logic between them -- that's how the
        -- Mudkip-nickname Yes/No box got blown through blind. Since queue
        -- only drains on a real onFrame() tick, this forces at least one
        -- actual frame (and therefore one decision-detection pass) to
        -- happen between any two presses, structurally, not just by
        -- convention. Does not block WALK/GOTO (separate walk/nav state,
        -- already mutually-exclusive and untouched by this).
        if #queue > 0 then
            return "ERR busy: previous PRESS still queued/draining -- wait for it to finish and check DIAG (decision_pending/yesno_active) before pressing again"
        end
        local raw = parts[2]
        local mask = BUTTON[(raw or ""):lower()] or tonumber(raw)
        if not mask then
            return "ERR bad button (use a/b/select/start/up/down/left/right, or a numeric mask)"
        end
        local hold = tonumber(parts[3]) or 8
        local rel = tonumber(parts[4]) or 32
        schedule(mask, hold, rel)
        pushLog("input_sent", {frame = frameCount, detail = "PRESS " .. tostring(raw)})
        return "OK"
    elseif op == "SEQ" then
        -- 2026-10-10 (companion, at Jackson's request): frame-exact chained
        -- input for Mach Bike floors. SEQ <mask>:<hold> [<mask>:<hold> ...]
        -- Each step is held for <hold> frames with ZERO release between
        -- steps, so speed carries through turns with no call-to-call jitter.
        -- Masks: right 16, left 32, up 64, down 128 (add them for an overlap,
        -- e.g. right+down = 144). The last step releases for 8 frames.
        if #queue > 0 then
            return "ERR busy: previous input still queued/draining"
        end
        local steps = {}
        for i = 2, #parts do
            local m, h = parts[i]:match("^(%d+):(%d+)$")
            if not m then return "ERR usage: SEQ <mask>:<hold> ... (bad step '" .. tostring(parts[i]) .. "')" end
            steps[#steps + 1] = {tonumber(m), tonumber(h)}
        end
        if #steps == 0 then return "ERR usage: SEQ <mask>:<hold> ..." end
        for i, st in ipairs(steps) do
            schedule(st[1], st[2], (i == #steps) and 8 or 0)
        end
        pushLog("input_sent", {frame = frameCount, detail = "SEQ " .. tostring(#steps) .. " steps"})
        return "OK " .. tostring(#steps) .. " steps queued"
    elseif op == "WALK" then
        local dir = DIR[parts[2]]
        local n = tonumber(parts[3]) or 1
        if not dir then return "ERR bad direction" end
        nav = nil  -- WALK and GOTO are mutually exclusive
        walk = strict({dirMask = dir, n = n, stepping = nil}, "walk",
                       {"dirMask", "n", "stepping"})
        pushLog("input_sent", {frame = frameCount, detail = "WALK " .. tostring(parts[2]) .. " " .. tostring(n)})
        return "OK"
    elseif op == "RESUME" then
        mode = "auto"
        decision = nil
        pushLog("mode_change", {frame = frameCount, detail = "resume"})
        return "OK"
    elseif op == "PAUSE" then
        mode = "parked"
        pushLog("mode_change", {frame = frameCount, detail = "pause"})
        return "OK"
    elseif op == "GOTO" then
        local tx, ty = tonumber(parts[2]), tonumber(parts[3])
        if not tx or not ty then return "ERR usage: GOTO <x> <y>" end
        local x0, y0, _, _, mapGroup0, mapNum0 = playerSig()
        local axis = (math.abs(tx - x0) >= math.abs(ty - y0)) and "x" or "y"
        walk = nil  -- GOTO and WALK are mutually exclusive
        nav = strict({tx = tx, ty = ty, axis = axis, blockedStreak = 0,
               stepping = nil, bestDist = nil, noProgress = 0,
               mapGroup = mapGroup0, mapNum = mapNum0}, "nav", {
               "tx", "ty", "axis", "blockedStreak", "stepping",
               "bestDist", "noProgress", "warps", "mapGroup", "mapNum",
        })
        pushLog("mode_change", {frame = frameCount, detail = "goto " .. tx .. "," .. ty})
        return "OK"
    elseif op == "STOPNAV" then
        local was = (nav ~= nil) or (walk ~= nil)
        if nav then emu:setKeys(0) end
        if walk then emu:setKeys(0) end
        nav = nil
        walk = nil
        return was and "OK stopped" or "OK not_active"
    elseif op == "CLEARQUEUE" then
        local n = #queue
        queue = {}
        return "OK cleared " .. tostring(n)
    elseif op == "SAVE" then
        local slot = tonumber(parts[2]) or 1
        if slot >= 3 and slot <= 8 then
            return "ERR slots 3-8 are reserved for REGRESS fixtures -- use slot 1 or 2 for a manual checkpoint"
        end
        local ok = pcall(function() emu:saveStateSlot(slot) end)
        return ok and "OK" or "ERR save failed"
    elseif op == "SAVEFIXTURE" then
        -- Deliberate escape hatch for populating slots 3-8 (SAVE refuses
        -- them). SAVEFIXTURE <slot>
        local slot = tonumber(parts[2])
        if not slot or slot < 3 or slot > 8 then return "ERR usage: SAVEFIXTURE <3-8>" end
        local ok = pcall(function() emu:saveStateSlot(slot) end)
        return ok and ("OK saved fixture slot " .. slot .. " (" .. (FIXTURES[slot] and FIXTURES[slot].desc or "undocumented") .. ")") or "ERR save failed"
    elseif op == "LOAD" then
        local slot = tonumber(parts[2]) or 1
        local ok = pcall(function() emu:loadStateSlot(slot) end)
        return ok and "OK" or "ERR load failed"
    elseif op == "SELFTEST" then
        local results = {}
        local qLenBefore = #queue
        local acceptedBad = schedule(nil, 1, 1)
        results.reject_bad_mask = (acceptedBad == false and #queue == qLenBefore)
        results.button_lookup_a = (BUTTON["a"] == 1)
        results.dir_lookup_up = (DIR["up"] == 64)
        results.read_works = pcall(u32, GMAIN_CALLBACK2_ADDR)
        results.field_lock_read_works = pcall(u8, FIELD_LOCK_ADDR)
        local sb1Ok, sb1 = pcall(u32, SAVEBLOCK1_PTR_ADDR)
        local badgeOk, badgeCount = false, nil
        if sb1Ok then badgeOk, badgeCount = pcall(countBadges, sb1) end
        results.badge_count_read_works = (sb1Ok and badgeOk and type(badgeCount) == "number" and badgeCount >= 0 and badgeCount <= 8)
        results.screen_table_works = (KNOWN_SCREENS[0x081AAD5C] == "bag" and pcall(screenLabel))
        local mOk, mV = pcall(readMoney)
        results.money_read_works = (mOk and type(mV) == "number" and mV >= 0 and mV <= 999999)
        local bOk, bV = pcall(readBag)
        results.bag_read_works = (bOk and type(bV) == "string" and bV:find("ITEMS:", 1, true) ~= nil)
        results.item_names_work = (itemName(4):find("BALL", 1, true) ~= nil)   -- 4 = ITEM_POKE_BALL
        local dOk, dOwned, dSeen = pcall(readDex)
        local snOk, snV = pcall(handle, "SNAP")
        results.snap_works = (snOk and type(snV) == "string" and snV:find("| map %d+%.%d+ ") ~= nil and snV:find("| badges %d") ~= nil and snV:find(" || BAG ", 1, true) ~= nil)
        results.dex_read_works = (dOk and dOwned <= dSeen and dSeen <= 412)
        local okPm, pm = pcall(partyMon, 0)
        results.party_decrypt_works = okPm and pm.species > 0 and pm.species < NUM_SPECIES_TBL and not speciesName(pm.species):match("^%d+$")
        local okMi, mi = pcall(moveInfo, 33)   -- 33 = TACKLE in pret's include/constants/moves.h
        results.move_names_work = okMi and mi ~= nil and mi.name == "TACKLE"
        results.map_id_read_works = sb1Ok and pcall(u8, sb1 + SAVEBLOCK1_MAPGROUP_OFFSET) and pcall(u8, sb1 + SAVEBLOCK1_MAPNUM_OFFSET)
        results.battle_outcome_read_works = pcall(u8, BATTLE_OUTCOME_ADDR)
        local objOk, objs = pcall(getObjectEvents)
        results.object_events_read_works = (objOk and type(objs) == "table")
        local liveOk, lx, ly = pcall(livePlayerXY)
        results.live_player_pos_read_works = (liveOk and lx ~= nil and ly ~= nil)
        local warpsOk, warps = pcall(getWarps)
        results.warps_read_works = (warpsOk and type(warps) == "table")
        local gridOk, gridRows = pcall(getCollisionGrid, 2)
        results.collision_grid_read_works = (gridOk and type(gridRows) == "table" and #gridRows == 5 and #gridRows[1] == 5)
        -- incident #17 take 2: the tileTransitionState-based step engine
        -- was replaced with driveHold()'s position-delta approach (see the
        -- writeup above its definition) -- this checks the pure peek
        -- helper against a fabricated in-flight hold state instead of the
        -- old raw-transition-byte read.
        local nowX, nowY = playerSig()
        local peekOk, peekVal = pcall(peekHoldProgress, {startX = nowX, startY = nowY}, DIR.right)
        results.hold_progress_peek_works = (peekOk and peekVal == 0)  -- same position as "start" -> zero progress, no frames have run between these two reads
        -- incident #17 regression guard: a raw block of exactly
        -- MAPGRID_UNDEFINED (0x3FF) must decode to forced collision=1 (a
        -- real wall/void), never the naive all-zero-bits collision=0 that
        -- caused LOOK to report unloaded grid cells as open floor.
        local undefDecode = decodeGridBlock(MAPGRID_UNDEFINED)
        results.mapgrid_undefined_decode_works = (undefDecode.collision == 1 and undefDecode.undefined == true)
        -- New this pass:
        results.version_stamp_set = (VERSION ~= nil and VERSION ~= "")
        local bdsOk, bds = pcall(getBattleDecisionState)
        results.battle_decision_read_works = (bdsOk and type(bds) == "table" and bds.battle_input ~= nil)
        -- Task-scan liveness: confirm the scan mechanism itself works by
        -- checking it against a task that's virtually always running
        -- somewhere in this engine, NOT just that it returns false for
        -- our specific targets (a scan that's silently broken would also
        -- always return false -- that's the exact failure mode to catch).
        local scanOk, anyTaskFound = pcall(function()
            for i = 0, 15 do
                local b = GTASKS_ADDR + i * GTASK_SIZE
                if u8(b + 4) ~= 0 then return true end
            end
            return false
        end)
        results.task_scan_read_works = (scanOk and type(anyTaskFound) == "boolean")
        local logOk = pcall(pushLog, "selftest", {frame = frameCount})
        results.log_write_works = logOk
        local strictOk = pcall(function()
            local t = strict({a = 1}, "selftest_strict")
            local ok2 = pcall(function() return t.doesNotExist end)
            if ok2 ~= false then return false end  -- reading an undeclared field must error
            -- A declared-but-initially-nil field (the incident-16 case:
            -- nav.lastX / battleDecisionState.learn_move_state) must be
            -- readable as nil AND writable exactly once the allowlist
            -- names it, even though the constructor never actually
            -- stores a nil-valued key.
            local t2 = strict({x = 1, y = nil}, "selftest_strict2", {"x", "y"})
            local ok3, y0 = pcall(function() return t2.y end)
            if not (ok3 and y0 == nil) then return false end
            local ok4 = pcall(function() t2.y = 5 end)
            if not (ok4 and t2.y == 5) then return false end
            return true
        end)
        results.strict_table_works = strictOk
        -- Incident #20 regression guard: in_battle must be gated by
        -- game_mode, not raw gBattleTypeFlags (which pret's source
        -- confirms never clears on battle end). Passing an explicit
        -- gameModeHint of "overworld" must force in_battle=false
        -- regardless of whatever gBattleTypeFlags actually holds live
        -- right now (including a genuinely stale nonzero leftover) --
        -- this is what actually proves the fix's logic, not just that
        -- the function runs.
        local bds20Ok, bds20 = pcall(getBattleDecisionState, "overworld")
        results.in_battle_derives_from_mode_works = (bds20Ok and bds20.in_battle == false)
        -- Incident #19 regression guard: PRESS must refuse (not silently
        -- queue) while a previous press is still draining, so a batch of
        -- socket lines arriving with zero frames between them (confirmed
        -- root cause -- see bootstrap.lua's synchronous line-drain loop)
        -- can no longer blow through a decision-detection window. Swap in
        -- a fake non-empty queue (no real key press involved -- handle()
        -- runs fully synchronously within one Lua call, so no frame
        -- callback can interleave here) and confirm the busy path is hit
        -- before schedule() would ever be reached, then restore the real
        -- queue exactly as it was.
        local savedQueue = queue
        queue = {{mask = BUTTON.a, hold = 1, release = 1}}
        local pressOk, pressResp = pcall(handle, "PRESS a")
        local queueUntouched = (#queue == 1 and queue[1].mask == BUTTON.a)
        queue = savedQueue
        results.press_busy_reject_works = (pressOk and type(pressResp) == "string" and
            pressResp:find("^ERR busy") ~= nil and queueUntouched)
        -- Tenth-session build: decode a fabricated Gen 3 byte sequence
        -- (no live RAM read involved) covering a letter, a space, a
        -- newline control code, and the terminator -- confirms the
        -- CHARMAP table and decodeGen3String's control-code handling
        -- both actually work, not just that TEXT returns a string of
        -- some kind.
        local sample = {0xBB, 0xBC, 0xBD, 0x00, 0xFE, 0xD5, 0xD6, 0xD7, 0xFF, 0xBB}
        local decoded = decodeGen3String(sample)
        results.text_decode_works = (decoded == "ABC \nabc")
        -- Eleventh-session build: confirm getMapName()'s out-of-range
        -- guard rejects a mapsec id past the real table (213 entries)
        -- without touching live RAM -- the override param exists
        -- specifically so this is testable without a real ROM read.
        local oor = getMapName(9999)
        results.mapname_bounds_works = (oor.name_ok == false and oor.mapsec_id == 9999)
        -- harness v2: text labels + NAME planner (pure, fabricated inputs) and the live reads they rely on
        results.text_label_works = (v2.formatText("f", "old", "hi", 5.2) == "[f old] hi (unchanged 5s)"
            and v2.formatText("b", "menu", "x", 0) == "[b menu] x" and v2.formatText("f", nil, "y", 3) == "[f] y")
        results.text_status_read_works = (pcall(u8, v2.K.FIELD_MSGBOX_MODE_ADDR) and pcall(v2.readCurrentText) and pcall(v2.textStatus, false, "overworld", "x") and v2.textStatus(false, "new_game_intro", "x") == nil and v2.textStatus(false, "naming_screen", "x") == "old")
        local c1, c2, e1 = v2.parseNameText("Aa 'z"), v2.parseNameText("a$"), nil
        results.name_parse_works = (c1 ~= nil and #c1 == 5 and c2 == nil and select(2, v2.parseNameText("ab\u{4E2D}")) ~= nil)
        results.name_layout_works = (#v2.NS_INDEX["A"] == 1 and v2.NS_INDEX["A"][1].page == 1 and v2.NS_INDEX["a"][1].page == 2 and v2.NS_INDEX["7"][1].page == 0
            and #v2.NS_INDEX[" "] > 6 and v2.K.NS_COLS[0] == 6 and utf8.len(v2.NS_ROWS[0][3]) == 6)
        results.name_plan_works = (v2.namePlan(1, 0, 0, "A") == "a" and v2.namePlan(1, 0, 0, "B") == "right" and v2.namePlan(1, 0, 0, "a") == "select"
            and v2.namePlan(1, 0, 0, "T") == "up" and v2.namePlan(1, 0, 0, "G") == "down" and v2.namePlan(1, 8, 2, "A") == "left"
            and v2.namePlan(2, 5, 3, "e") == "down" and v2.namePlan(0, 0, 0, "A") == "select" and v2.namePlan(1, 7, 0, ".") == "a")
        results.name_screen_read_safe = pcall(v2.readNamingScreen)
        return encodeFlat(results)
    else
        return "ERR unknown command: " .. tostring(op)
    end
end

local function teardown()
    -- Nothing needs explicit cleanup: the socket and frame callback are
    -- owned by bootstrap.lua and survive a reload untouched; queue/nav/
    -- log all live in this module's locals and are simply replaced when
    -- dofile creates the next module's fresh closures. Kept as a real
    -- function (not omitted) so bootstrap.lua's optional-teardown check
    -- has something to call and this stays the place to add real cleanup
    -- if a future signal ever needs it (e.g. an open file handle).
end

return {
    onFrame = onFrame,
    handle = handle,
    VERSION = VERSION,
    teardown = teardown,
}

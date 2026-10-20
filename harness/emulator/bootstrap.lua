-- Pokemon Emerald harness bootstrap. Loaded ONCE per mGBA process via
-- Tools -> Scripting -> dofile("bootstrap.lua") -> Run. Owns the TCP
-- socket and the single frame callback for the life of the process.
-- Everything game-related lives in director.lua, which this file loads
-- via loadDirector() and can SWAP OUT on a live "RELOAD" socket command
-- without ever touching the socket or the frame callback again -- that's
-- the whole point: director.lua changes no longer need a full mGBA
-- quit/relaunch, only bootstrap.lua changes do (rare).
--
-- Design constraint that makes this safe: the frame callback and the
-- socket dispatcher both do a _G.DIRECTOR lookup EVERY time, never a
-- closure capture of the module table -- so swapping _G.DIRECTOR is
-- immediately live for both, and a RELOAD that fails leaves the OLD
-- director (old closure, old state) fully intact and answering.

-- Double-load guard (2026-09-26): a second dofile() in the same mGBA
-- process used to crash on re-binding port 8888 (lesson 28) and would also
-- register a second frame callback (director ticking twice per frame).
-- Now it is a harmless no-op that says so.
if _G.BOOTSTRAP_LOADED then
    console:log("bootstrap.lua already loaded in this mGBA process -- ignoring second dofile")
    return
end

local DIRECTOR_PATH = "__DIRECTOR_PATH__"
local PORT = 8888

local function loadDirector()
    local chunk, loadErr = loadfile(DIRECTOR_PATH)
    if not chunk then return nil, "load error: " .. tostring(loadErr) end
    local ok, result = pcall(chunk)
    if not ok then return nil, "runtime error: " .. tostring(result) end
    if type(result) ~= "table" or type(result.onFrame) ~= "function" or type(result.handle) ~= "function" then
        return nil, "director.lua did not return a valid module table (needs onFrame + handle)"
    end
    return result, nil
end

local initial, loadErr = loadDirector()
_G.DIRECTOR = initial
_G.DIRECTOR_LOAD_ERROR = loadErr
_G.DIRECTOR_FRAME_ERROR = nil

-- The ONE frame callback bootstrap.lua will ever register for this
-- process. Everything it does is a fresh _G.DIRECTOR lookup, so a RELOAD
-- takes effect on the very next frame with zero extra wiring.
callbacks:add("frame", function()
    if _G.DIRECTOR and _G.DIRECTOR.onFrame then
        local ok, err = pcall(_G.DIRECTOR.onFrame)
        if not ok then _G.DIRECTOR_FRAME_ERROR = tostring(err) end
    end
end)

local server = socket.bind(nil, PORT)
if not server then
    console:error("bootstrap.lua: could not bind port " .. PORT .. " (already in use?)")
    return
end
server:listen(1)
_G.BOOTSTRAP_LOADED = true

-- Crash fix (2026-09-26): accepted client sockets used to be referenced only
-- by their own callback closure. Once a client disconnected, Lua could
-- garbage-collect a socket mGBA still had callbacks registered on -> SIGBUS
-- inside the frame callback (crash log mGBA-2026-09-26-131215). Keep a strong
-- reference to every live client, and close + drop it explicitly on
-- disconnect so its callbacks are torn down by mGBA, not by the GC.
_G.BRIDGE_CLIENTS = _G.BRIDGE_CLIENTS or {}
local function dropClient(c)
    pcall(function() c:close() end)
    _G.BRIDGE_CLIENTS[c] = nil
end

server:add("received", function()
    local c = server:accept()
    if c then
        -- Disconnects don't reliably fire an event, so clients piled up
        -- (8 live after a relaunch + a few g calls). Our tools use one
        -- connection at a time: close every older client on each new accept.
        for old in pairs(_G.BRIDGE_CLIENTS) do dropClient(old) end
        _G.BRIDGE_CLIENTS[c] = true
        local buffer = ""
        c:add("error", function() dropClient(c) end)
        c:add("received", function()
            local data, err = c:receive(4096)
            if not data or data == "" then
                local again = socket.ERRORS and socket.ERRORS.AGAIN
                if again == nil or err ~= again then dropClient(c) end
                return
            end
            if data then
                buffer = buffer .. data
                while true do
                    local nl = buffer:find("\n")
                    if not nl then break end
                    local line = buffer:sub(1, nl - 1)
                    buffer = buffer:sub(nl + 1)
                    local resp

                    if line == "RELOAD" then
                        -- Special-cased HERE, not delegated to
                        -- DIRECTOR.handle, because it needs to replace
                        -- _G.DIRECTOR itself -- a module can't swap
                        -- itself out from inside its own call frame.
                        local newDirector, err = loadDirector()
                        if newDirector then
                            local old = _G.DIRECTOR
                            if old and type(old.teardown) == "function" then
                                pcall(old.teardown)
                            end
                            local oldVersion = old and old.VERSION or "none"
                            _G.DIRECTOR = newDirector
                            _G.DIRECTOR_LOAD_ERROR = nil
                            _G.DIRECTOR_FRAME_ERROR = nil
                            -- Reset is the safe default: fresh queue/nav/
                            -- mode/state on every swap, never carried over.
                            resp = "OK reloaded " .. tostring(oldVersion) .. " -> " .. tostring(newDirector.VERSION)
                        else
                            -- Syntax/runtime error in the new file must
                            -- NEVER leave the process with no director --
                            -- the old one (old closure, old state) keeps
                            -- answering exactly as before.
                            resp = "ERR reload failed, keeping current director: " .. tostring(err)
                        end
                    elseif line == "BOOTVERSION" then
                        resp = (_G.DIRECTOR and tostring(_G.DIRECTOR.VERSION) or "none") ..
                               " load_error=" .. tostring(_G.DIRECTOR_LOAD_ERROR) ..
                               " frame_error=" .. tostring(_G.DIRECTOR_FRAME_ERROR)
                    elseif _G.DIRECTOR and _G.DIRECTOR.handle then
                        local ok2, r = pcall(_G.DIRECTOR.handle, line)
                        resp = ok2 and r or ("ERR " .. tostring(r))
                    else
                        resp = "ERR no director loaded: " .. tostring(_G.DIRECTOR_LOAD_ERROR)
                    end

                    c:send(resp .. "\n")
                end
            end
        end)
    end
end)

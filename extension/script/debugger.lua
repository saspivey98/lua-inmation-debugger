local platform, root, luaapi = ...

local arch = (function()
    if string.packsize then
        local size = string.packsize "T"
        if size == 8 then
            return 64
        end
        if size == 4 then
            return 32
        end
    else
        local size = #tostring(io.stderr)
        if size == 23 then
            return 64
        end
        if size == 15 then
            return 32
        end
    end
    assert(false, "unknown arch")
end)()

local rt = "/runtime"
if platform == "windows" then
    if arch == 64 then
        rt = rt .. "/win64"
    else
        rt = rt .. "/win32"
    end
else
    assert(arch == 64)
    rt = rt .. "/" .. platform
end
if _VERSION == "Lua 5.4" then
    rt = rt .. "/lua54"
elseif _VERSION == "Lua 5.3" then
    rt = rt .. "/lua53"
elseif _VERSION == "Lua 5.2" then
    rt = rt .. "/lua52"
else
    error(_VERSION .. " is not supported.")
end

local ext = platform == "windows" and "dll" or "so"
local remotedebug = root..rt..'/remotedebug.'..ext
if luaapi then
    assert(package.loadlib(remotedebug,'init'))(luaapi)
end
local rdebug = assert(package.loadlib(remotedebug,'luaopen_remotedebug'))()

local dbg = {}

function dbg:start(addr, client)
    local address = ("%q, %s"):format(addr, client == true and "true" or "false")
    rdebug.start(([=[
        package.path = %q
        package.cpath = %q
        debug.setCstacklimit(1000)
        local log = require 'common.log'
        log.file = %q
        local m = require 'backend.master'
        m(%q, %q)
        local w = require 'backend.worker'
        w.openupdate()
    ]=]):format(
          root..'/script/?.lua'
        , root..rt..'/?.'..ext
        , root..'/worker.log'
        , root..'/error.log'
        , address
    ))
end

function dbg:wait()
    rdebug.probe 'wait'
end

function dbg:event(name, ...)
    return rdebug.event('event_'..name, ...)
end

debug.getregistry()["lua-debug"] = dbg
return dbg

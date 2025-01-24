-- esi-variables

local lib = {}

local JSON = require'dkjson'
local O = require 'esi-objects'

--@md
function lib.INFO(_)
    return {
    version = {
        major = 1,
        minor = 0,
        revision = 2
    },
    contacts = {
        {
        name = "Florian Seidl",
        email = "florian.seidl@cts-gmbh.de"
        },
        {
        name = "Sebastian Gau",
        email = "sebastian.gau@basf.com"
        },
        {
        name = "Timo Klingenmeier",
        email = "timo.klingenmeier@inmation.com"
        }
    },
    library = {
        modulename = "esi-variables",
    },
    dependencies = {
        {
        modulename = 'dkjson',
        version = {
            major = 2,
            minor = 5,
            revision = 0
        }
        },
        {
        modulename = 'esi-objects',
        version = {
            major = 0,
            minor = 1,
            revision = 1
        }
        }
    }
    }
end

--@md
function lib:SETVARIABLE(...)
    local v,q,t,variablepath,obj,hist = self:_loadsetvariableparameters(...)
    if type(variablepath) == "nil" then
        return false
    end
    local path = self:_ensurevariablepath(variablepath,obj,hist)
    if type(path) ~= "string" then
        return false
    end
    inmation.setvalue(path, v, q, t)
    return true
end
--@md
function lib.SET(_,...) return lib:SETVARIABLE(...) end

-- added by TimoKl to support the no history option
function lib._iif(_,cond,r1,r2)
    if cond then return r1 else return r2 end
end

-- reads the arguments and returns v,q,t, the path of the variable and the objects
-- TimoKl added the nohist option
function lib:_loadsetvariableparameters(...)
    local J = JSON
    local obj = inmation.getself()
    local args = table.pack(...)
    if #args > 1 then
    local v
    local variablepath = args[1]
    if type(args[2]) == "table" then
        v = J.encode(args[2], {indent = false})
    else
        v = args[2]
    end
    local q = args[3]  or 0
    local t = args[4] or inmation.currenttime()
    local h=self:_iif("boolean"==type(args[5]),args[5],true)
    return v,q,t,variablepath,obj,h
    elseif #args == 1 then
    local v
    local variablepath = args[1].path
    if type(args[1].v) == "table" then
        local jsonprop = args[1].json or {indent = false}
        v = J.encode(args[1].v, jsonprop)
    else
        v = args[1].v
    end
    local q = args[1].q or 0
    local t = args[1].t or inmation.currenttime()
    obj = args[1].object or obj
    local h=self:_iif("boolean"==type(args[1].hist),args[1].hist,true)
    return v,q,t,variablepath,obj,h
    end
    return nil,nil,nil,nil,nil
end

-- ensure variable path
function lib:_ensurevariablepath(variablepath,obj,hist)
    local ObjectParent,ObjectName = inmation.splitpath(variablepath)
    if ObjectName == nil then
        ObjectName = variablepath
        ObjectParent = ""
    end
    local path = obj:path()
    if #ObjectParent > 0 then
        for _,vgroup in ipairs(inmation.split(ObjectParent, "/")) do
        if O:EXISTS{["parentpath"] = path, ["objectname"] = vgroup} == false then
            local variablegrpprop = {
            ["path"] = path,
            ["class"] = "MODEL_CLASS_VARIABLEGROUP",
            ["properties"] = {
                [".ObjectName"] = vgroup,
                [".AuxStateManagement.AuxStateChangeStrategy"]=inmation.model.codes.AuxStateChangeStrategy.INHIBIT
            }
            }
            O:UPSERTOBJECT(variablegrpprop)
        end
        path = path .. "/" .. vgroup
        end
    end
    if O:EXISTS{["parentpath"] = path, ["objectname"] = ObjectName} == false then
        local variableprop = {
        ["path"] = path,
        ["class"] = "MODEL_CLASS_VARIABLE",
        ["properties"] = {
            [".ObjectName"] = ObjectName,
            [".ArchiveOptions.StorageStrategy"] = self:_iif(hist,
            inmation.model.flags.ItemValueStorageStrategy.STORE_RAW_HISTORY,0),
            [".ArchiveOptions.ArchiveSelector"] = self:_iif(hist,inmation.model.codes.ArchiveTarget.ARC_PRODUCTION,
            inmation.model.codes.ArchiveTarget.ARC_TEST),
            [".ArchiveOptions.PersistencyMode"] = inmation.model.codes.PersistencyMode.PERSIST_PERIODICALLY,
            }
        }
        local o = O:UPSERTOBJECT(variableprop)
        if o then
        return o:path()
        else
        return nil
        end
    else
        return path .. "/" .. ObjectName
    end
end
--@md
function lib:GETVARIABLE(arg)
    local J = JSON
    local path = self:_getvariablepath(arg)
    if type(path) == "nil" then
        return nil,nil,nil
    end
    if O:EXISTS{["path"] = path} == false then
        return nil,nil,nil
    else
        local v,q,t = inmation.getvalue(path)
        if type(v) == "string" then
        if v:sub(1,1) .. v:sub(-1,-1) == "{}" or v:sub(1,1) .. v:sub(-1,-1) == "[]" then
            local vj = J.decode(v) or v
            return vj,q,t
        end
        end
        return v,q,t
    end
end
--@md
function lib.GET(_,arg) return lib:GETVARIABLE(arg) end

-- returns the path for the GETVARIABLE function
function lib._getvariablepath(_,arg)
    local obj = inmation.getself()
    if type(arg) == "table" then
        local variablepath = arg.path
        obj = arg.object or obj
        local path = obj:path() .. "/" .. variablepath
        return path
    elseif type(arg) == "string" then
        local path = obj:path() .. "/" .. arg
        return path
    end
    return nil
end

return lib
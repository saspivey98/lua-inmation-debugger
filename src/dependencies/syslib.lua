local https = require("esi-lcurl-http-client")
local MONGO = require('mongo')
local JSON = require('rapidjson')
local config = require('syslib.config') --read config file

local syslib = {}

--model codes
syslib.model = require('syslib.model')

--checks if last char of config.url is '/'; append if DNE
syslib.url = config.url:byte(config.url:len()) == 47
    and config.url.."api/v2/execfunction" or config.url.."/api/v2/execfunction"

--self path for specific functions
syslib.selfpath = config.selfpath or ""

--a table to store function name mappings for pcall and scopedcall
local function_names = {}

syslib.headers = {
    accept = "application/json",
    username = config.headers.username,
    password = config.headers.password,
    ContentType = "application/json"
}

local body = {
    data = {
        lib = "esi-syslib",
        func = "main",
        farg = {}
    }
}

function syslib.INFO(_)
    return {
        version = {
            major=1,
            minor=5,
            revision=7
        },
        contacts = {
            {
                name="Simon Spivey",
                company="adatafy",
                email="sspivey@adatafy.com"
            }
        },
        library = {
            modulename="syslib",
            filename="syslib.lua",
            description=[[--
			links indepenent lua environment to inmation
            --]]
        },
        dependencies = {
            "syslib.config.lua",
            "syslib.model.lua",
            "esi-syslib.lua",
            "esi-lcurl-http-client.lua",
            "lua-mongo",
            "rapidjson"
        }
    }
end

local function headerSetter(...)
    local args = ...

    local temp = {}
    local arg
    for i = 1, #args do
        arg = "arg" .. (i // 10) .. (i % 10)
        temp[arg] = args[i]
    end

    body.data.farg = temp
end

------------------------------------------------------
----------- Begin Object Library Functions -----------
------------------------------------------------------

local object = {} --object.location is the object path
--calling properties

--arg = path or id
function syslib.getobject(path)
    --check if true
    headerSetter({'GETOBJECT', path, "DEFAULT"})
    if syslib:main('GETOBJECT') then
        --default to this function when access object properties
        object.__index = function(o, k, v)
            --if key has value then return
            if v then
                return v
            --if key is for function then call
            elseif object[k] then
                return object[k]
            else
                headerSetter({'GETOBJECT', o.location, 'PROPERTY', k})
                return syslib:main('GETOBJECT')
            end
        end

        local obj = {}
        setmetatable(obj, object)
        obj.location = path
        return obj
    end
end

--args = parent, class, [obj_type]
function syslib.createobject(parent, class, obj_type)
    headerSetter({'CREATEOBJECT', parent, class, obj_type})
    syslib:main('CREATEOBJECT')
    object.location = parent
    object.class = class
    object.obj_type = obj_type
    object.create = true --flag to distinguish between create object and get object
    return object
end

function syslib.new(parent, class, obj_type)
    return syslib.createobject(parent, class, obj_type)
end

function object:commit()
    local properties = {}
    for k,v in pairs(self) do
        if type(v) ~= "function" then
            properties[k] = v
        end
    end
    headerSetter({'GETOBJECT', properties, 'COMMIT'})
    return syslib:main('COMMIT')
end

function object:cfgversion()
    headerSetter({'GETOBJECT', self.location, "CFGVERSION"})
    return syslib:main('GETOBJECT')
end

--returns a specified child object
function object:child(child)
    return syslib.getobject(self.location.."/"..child)
end

--returns a list of children as objects
function object:children()
    headerSetter({'GETOBJECT', self.location, "CHILDREN"})
    local children = {}
    for _,child in ipairs(syslib:main('GETOBJECT')) do
        table.insert(children, syslib.getobject(child))
    end
    return children
end

function object:classversion()
    headerSetter({'GETOBJECT', self.location, "CLASSVERSION"})
    return syslib:main('GETOBJECT')
end

function object:comm_empty()
    headerSetter({'GETOBJECT', self.location, "COMM_EMPTY"})
    return syslib:main('GETOBJECT')
end

function object:comm_error()
    headerSetter({'GETOBJECT', self.location, "COMM_ERROR"})
    return syslib:main('GETOBJECT')
end

function object:comm_good()
    headerSetter({'GETOBJECT', self.location, "COMM_GOOD"})
    return syslib:main('GETOBJECT')
end

function object:comm_neutral()
    headerSetter({'GETOBJECT', self.location, "COMM_NEUTRAL"})
    return syslib:main('GETOBJECT')
end

function object:comm_warning()
    headerSetter({'GETOBJECT', self.location, "COMM_WARNING"})
    return syslib:main('GETOBJECT')
end

function object:classmismatch()
    headerSetter({'GETOBJECT', self.location, "CLASS_MISMATCH"})
    return syslib:main('GETOBJECT')
end

function object:created()
    headerSetter({'GETOBJECT', self.location, "CREATED"})
    return syslib:main('GETOBJECT')
end

function object:deleted()
    headerSetter({'GETOBJECT', self.location, "DELETED"})
    return syslib:main('GETOBJECT')
end

function object:dynamic()
    headerSetter({'GETOBJECT', self.location, "DYNAMIC"})
    return syslib:main('GETOBJECT')
end

function object:empty()
    headerSetter({'GETOBJECT', self.location, "EMPTY"})
    return syslib:main('GETOBJECT')
end

function object:enabled()
    headerSetter({'GETOBJECT', self.location, "ENABLED"})
    return syslib:main('GETOBJECT')
end

function object:error()
    headerSetter({'GETOBJECT', self.location, "ERROR"})
    return syslib:main('GETOBJECT')
end

function object:exploring()
    headerSetter({'GETOBJECT', self.location, "EXPLORING"})
    return syslib:main('GETOBJECT')
end

function object:good()
    headerSetter({'GETOBJECT', self.location, "GOOD"})
    return syslib:main('GETOBJECT')
end

function object:has_objref()
    headerSetter({'GETOBJECT', self.location, "HAS_OBJREF"})
    return syslib:main('GETOBJECT')
end

function object:has_secref()
    headerSetter({'GETOBJECT', self.location, "HAS_SECREF"})
    return syslib:main('GETOBJECT')
end

function object:model()
    headerSetter({'GETOBJECT', self.location, "MODEL"})
    return syslib:main('GETOBJECT')
end

function object:modified()
    headerSetter({'GETOBJECT', self.location, "MODIFIED"})
    return syslib:main('GETOBJECT')
end

function object:neutral()
    headerSetter({'GETOBJECT', self.location, "NEUTRAL"})
    return syslib:main('GETOBJECT')
end

function object:numid()
    headerSetter({'GETOBJECT', self.location, "NUMID"})
    return syslib:main('GETOBJECT')
end

--returns parent object
function object:parent()
    local index = self.location:match'^.*()/'
    if index > 1 then
        return syslib.getobject(self.location:sub(0,index-1))
    end
end

function object:path()
    headerSetter({'GETOBJECT', self.location, "PATH"})
    return syslib:main('GETOBJECT')
end

function object:registering()
    headerSetter({'GETOBJECT', self.location, "REGISTERING"})
    return syslib:main('GETOBJECT')
end

function object:sysname()
    headerSetter({'GETOBJECT', self.location, "SYSNAME"})
    return syslib:main('GETOBJECT')
end

function object:state()
    headerSetter({'GETOBJECT', self.location, "STATE"})
    return syslib:main('GETOBJECT')
end

function object:textid()
    headerSetter({'GETOBJECT', self.location, "TEXTID"})
    return syslib:main('GETOBJECT')
end

function object:type()
    headerSetter({'GETOBJECT', self.location, "TYPE"})
    return syslib:main('GETOBJECT')
end

function object:unconfirmed()
    headerSetter({'GETOBJECT', self.location, "UNCONFIRMED"})
    return syslib:main('GETOBJECT')
end

function object:userstate()
    headerSetter({'GETOBJECT', self.location, "USERSTATE"})
    return syslib:main('GETOBJECT')
end

function object:warning()
    headerSetter({'GETOBJECT', self.location, "WARNING"})
    return syslib:main('GETOBJECT')
end

----------------------------------------------------------------
----------------- END OBJECT LIBRARY FUNCTIONS -----------------
----------------------------------------------------------------

------------------------------------------------------------------
----------------- Begin syslib library functions -----------------
------------------------------------------------------------------

--if need to change paramaters, use create
function syslib:create(url, username, password)
    if type(url) ~= "string" or type(username) ~= "string" or type(password) ~= "string" then return "error" end
    self.url = url
    self.headers.username = username
    self.headers.password = password
end

--arg is store name
function syslib.getmongoconnectionstring(arg)
    headerSetter({'GETMONGOCONNECTIONSTRING', arg})
    return syslib:main('GETMONGOCONNECTIONSTRING')
end

--arg is item path
function syslib.get(arg)
    headerSetter({'GET', arg})
    return syslib:main('GET')
end

function syslib.getvalue(arg1, arg2)
    return syslib.get(arg1, arg2)
end

function syslib.set(arg1, arg2)
    headerSetter({'SET', arg1, arg2})
    return syslib:main('SET')
end

function syslib.setvalue(arg1, arg2)
    return syslib.set(arg1, arg2)
end

--arg = time
function syslib.gettime(arg)
    headerSetter({'GETTIME', arg})
    return syslib:main('GETTIME')
end

function syslib.getcorepath(path)
    headerSetter({'GETCOREPATH'}, path or syslib.selfpath)
    return syslib:main('GETCOREPATH')
end

function syslib.getsystempath()
    headerSetter({'GETSYSTEMPATH'})
    return syslib:main('GETSYSTEMPATH')
end

--arg = time
function syslib.gettimepartstable(t)
    headerSetter({'GETTIMEPARTSTABLE', t})
    return syslib:main('GETTIMEPARTSTABLE')
end

function syslib.findobjects(str, model, dyonly, fullpath)
    headerSetter({'FINDOBJECTS', str, model, dyonly, fullpath})
    local objects = {}
    for _,obj in ipairs(syslib:main('FINDOBJECTS')) do
        table.insert(objects, syslib.getobject(obj[1]))
    end
    return objects
end

function syslib.gethistory(paths, starttime, endtime, intervals_no, agg_type)
    headerSetter({'GETHISTORY', paths, starttime, endtime, intervals_no, agg_type})
    return syslib:main('GETHISTORY')
end

--arg = path
function syslib.splitpath(p)
    headerSetter({'SPLITPATH', p})
    return syslib:main('SPLITPATH')
end

function syslib.getpropertyid(path, property)
    headerSetter({'PROPID', path, property or ""})
    return syslib:main('PROPID')
end

function syslib.propid(path, property)
    return syslib.getpropertyid(path, property)
end

function syslib.sethistory(ID, v, q, t)
    headerSetter({'SETHIST', ID, v, q, t})
    return syslib:main('SETHIST')
end

function syslib.sethist(ID, v, q, t) return syslib.sethistory(ID, v, q, t) end

--args = path, lua code
function syslib.execute(p, code)
    headerSetter({'EXECUTE', p, code})
    return syslib:main('EXECUTE')
end

--args = string to be converted, [the country encoding]
function syslib.asciitoutf8(string, code_page)
    headerSetter({'ASCIItoUTF8', string, code_page})
    return syslib:main('ASCIItoUTF8')
end

--args = objspec, name, [repeater]
function syslib.attach(objspec, name, repeater)
    headerSetter({'ATTACH', objspec, name, repeater})
    return syslib:main('ATTACH')
end

--args = objspec, name, [input], [duration], [size])
function syslib.buffer(objspec, name, input, duration, size)
    headerSetter({'BUFFER', objspec.location or objspec, name, input, duration, size})
    return syslib:main('BUFFER')
end

--args = model_flags, [profiles]
--! need more information about objspec or profiles.
function syslib.checkmodelaccess(model_flags, objspec)
    headerSetter({'CHECKMODELACCESS', model_flags, objspec.location})
    return syslib:main('CHECKMODELACCESS')
end

--args = pathspec, sec_attr, [profiles]
function syslib.checkpermission(pathspec, sec_attr, objspec)
    headerSetter({'CHECKPERMISSION', pathspec, sec_attr, objspec.location})
    return syslib:main('CHECKPERMISSION')
end

------------------------------------------------
--------- Begin syslib Control Library ---------
------------------------------------------------

syslib.control = {
    ["getself"] = function ()
        headerSetter({'CONTROLGETSELF', syslib.selfpath})
        return syslib:main('CONTROLGETSELF')
    end,

    --args = id
    ["dedicate"] = function (id)
        headerSetter({'CONTROLDEDICATE', id})
        return syslib:main('CONTROLDEDICATE')
    end,

    ["list"] = function ()
        headerSetter({'CONTROLLIST'})
        return syslib:main('CONTROLLIST')
    end,

    --args = id
    ["terminate"] = function (id)
        headerSetter({'CONTROLTERMINATE', id})
        return syslib:main('CONTROLTERMINATE')
    end
}

----------------------------------------------------
------------ End syslib control library ------------
----------------------------------------------------

----------------------------------------------------
------------- End syslib model library -------------
----------------------------------------------------

--args = standard_attrs, [custom_attrs]
function syslib.createevent(standard_attrs, custom_attrs)
    headerSetter({'CREATEEVENT', standard_attrs, custom_attrs})
    return syslib:main('CREATEEVENT')
end

--args = header, payload, algo_params
function syslib.createjwt(header, payload, algo_params)
    headerSetter({'CREATEJWT', header, payload, algo_params})
    return syslib:main('CREATEJWT')
end


--args = [epoch]
function syslib.currenttime(epoch)
    headerSetter({'CURRENTTIME', epoch})
    return syslib:main('CURRENTTIME')
end

function syslib.now(epoch)
    return syslib.currenttime(epoch)
end

function syslib.currenttimezone()
    headerSetter({'CURRENTTIMEZONE'})
    return syslib:main('CURRENTTIMEZONE')
end

--args = str
function syslib.debase64(str)
    headerSetter({'DEBASE64', str})
    return syslib:main('DEBASE64')
end

--args = default_params
function syslib.def(default_params)
    return syslib.defaults(default_params)
end

--args = default_params
function syslib.defaults(default_params)
    headerSetter({'DEFAULTS', default_params})
    return syslib:main('DEFAULTS')
end

--args = pathspec, [name]
function syslib.deletefile(pathspec, name)
    headerSetter({'DELETEFILE', pathspec, name})
    return syslib:main('DELETEFILE')
end

--args = objspec
function syslib.del(objspec)
    return syslib.deleteobject(objspec)
end

--args = objspec
function syslib.deleteobject(objspec)
    headerSetter({'DELETEOBJECT', objspec})
    return syslib:main('DELETEOBJECT')
end

--pathspec, time_start, time_end, [datastore]
function syslib.deleterawhistory(pathspec, time_start, time_end, datastore)
    headerSetter({'DELETERAWHISTORY', pathspec, time_start, time_end, datastore})
    return syslib:main('DELETERAWHISTORY')
end

--args = text
function syslib.digest(text)
    headerSetter({'DIGEST', text})
    return syslib:main('DIGEST')
end

--args = digest, text
function syslib.digestupdate(digest, text)
    headerSetter({'DIGESTUPDATE', digest, text})
    return syslib:main('DIGESTUPDATE')
end

--args = lib_name
function syslib.digestlib(lib_name)
    headerSetter({'DIGESTLIB', lib_name})
    return syslib:main('DIGESTLIB')
end

--args = objspec
function syslib.disableobject(objspec)
    headerSetter({'DISABLEOBJECT', objspec})
    return syslib:main('DISABLEOBJECT')
end

--args = objspec
function syslib.dis(objspec)
    return syslib.disableobject(objspec)
end

--args = path
function syslib.dumpimage(path)
    headerSetter({'DUMPIMAGE', path})
    return syslib:main('DUMPIMAGE')
end

--args = objspec
function syslib.enableobject(objspec)
    headerSetter({'ENABLEOBJECT', objspec})
    return syslib:main('ENABLEOBJECT')
end

--args = objspec
function syslib.ena(objspec)
    return syslib.enableobject(objspec)
end

--args = bytes
function syslib.enbase64(bytes)
    headerSetter({'ENBASE64', bytes})
    return syslib:main('ENBASE64')
end

--args = exl_time
function syslib.excel2posix(exl_time)
    headerSetter({'EXCEL2POSIX', exl_time})
    return syslib:main('EXCEL2POSIX')
end

--args = string
function syslib.foldcase(string)
    headerSetter({'FOLDCASE', string})
    return syslib:main('FOLDCASE')
end

--args = datasource, item_ids, [attribute_ids], [skip_values]
function syslib.getattributesex(datasource, item_ids, attribute_ids, skip_values)
    headerSetter({'GETATTRIBUTESEX', syslib.selfpath, datasource, JSON.encode(item_ids), JSON.encode(attribute_ids), skip_values})
    return syslib:main('GETATTRIBUTESEX')
end

--args = objspec(s), options
function syslib.getaudittrail(objspec, options)
    headerSetter({'GETAUDITTRAIL', objspec, options})
    return syslib:main('GETAUDITTRAIL')
end

--args = objspec
function syslib.getbackreferences(objspec)
    headerSetter({'GETBACKREFERENCES', objspec})
    return syslib:main('GETBACKREFERENCES')
end

--args = objspec
function syslib.getconnectorpath(path)
    headerSetter({'GETCONNECTORPATH', path or syslib.selfpath})
    return syslib:main('GETCONNECTORPATH')
end

function syslib.getdefaults()
    headerSetter({'GETDEFAULTS'})
    return syslib:main('GETDEFAULTS')
end

--args = pathspec, [allow_remote]
function syslib.getdefaultstore(pathspec, allow_remote)
    headerSetter({'GETDEFAULTSTORE', pathspec, allow_remote})
    return syslib:main('GETDEFAULTSTORE')
end

--args = paths, start, finish, [options]
function syslib.geteventhistory(paths, start, finish, options)
    headerSetter({'GETEVENTHISTORY', paths, start, finish, options or {}})
    return syslib:main('GETEVENTHISTORY')
end

--args = spathspec, [filter]
function syslib.getfile(pathspec, filter)
    headerSetter({'GETFILE', pathspec, filter})
    return syslib:main('GETFILE')
end

--args = pathspec, [filter]
function syslib.getfilemetadata(pathspec, filter)
    headerSetter({'GETFILEMETADATA', pathspec, filter})
    return syslib:main('GETFILEMETADATA')
end


--args = datasource, ids, [start], [finish], [max_values], [bound_required], [modified_info]
function syslib.gethistoryex(datasource, ids, ...)
    --headerSetter({'GETHISTORYEX', syslib.selfpath, datasource, ids, start, finish, max_values, bound_required, modified_info})
    headerSetter({'GETHISTORYEX', syslib.selfpath, datasource, ids, ...})
    return syslib:main('GETHISTORYEX')
end

--args = pathspec, [datastore]
function syslib.gethistoryframe(pathspec,datastore)
    headerSetter({'GETHISTORYFRAME', pathspec,datastore})
    return syslib:main('GETHISTORYFRAME')
end

-- start_time, end_time, [objects], [maxlogs]
function syslib.getlogs(start_time, end_time, objects, maxlogs)
    headerSetter({'GETLOGS', start_time, end_time, objects, maxlogs})
    return syslib:main('GETLOGS')
end

function syslib.getmicrosecondcounter()
    headerSetter({'GETMICROSECONDCOUNTER'})
    return syslib:main('GETMICROSECONDCOUNTER')
end

-- [store], [testarchive]
function syslib.getmongoconnection(store, testarchive)
    local str = syslib.getmongoconnectionstring(store, testarchive)
    return MONGO.Client(str)
end

function syslib.getopcuaquality(opcclassicquality)
    headerSetter({'GETOPCUAQUALITY', opcclassicquality})
    return syslib:main('GETOPCUAQUALITY')
end

function syslib.getparentpath(objspec)
    headerSetter({'GETPARENTPATH', objspec})
    return syslib:main('GETPARENTPATH')
end

function syslib.parent(objspec)
    return syslib.getparentpath(objspec)
end

function syslib.getproductkey()
    headerSetter({'GETPRODKEY'})
    return syslib:main('GETPRODKEY')
end

function syslib.getpropertyname(propid)
    headerSetter({'GETPROPNAME', propid})
    return syslib:main('GETPROPNAME')
end

function syslib.getrawhistory(pathspec, bounds, time_start, time_end, max_limit, datastore, modified_data_mode)
    headerSetter({'GETRAWHIST', pathspec, bounds, time_start, time_end, max_limit, datastore, modified_data_mode})
    return syslib:main('GETRAWHIST')
end

function syslib.getreferences(objspec)
    headerSetter({'GETREFS', objspec or syslib.selfpath})
    return syslib:main('GETREFS')
end

function syslib.getsafconfirmedseqnr(category)
    headerSetter({'GETSAFCONFIRMSEQNR', category})
    return syslib:main('GETSAFCONFIRMSEQNR')
end

function syslib.getsafforwardedseqnr(category)
    headerSetter({'GETSAFFORWARDSEQNR', category})
    return syslib:main('GETSAFFORWARDSEQNR')
end

function syslib.getsafseqnr(category)
    headerSetter({'GETSAFSEQNR', category})
    return syslib:main('GETSAFSEQNR')
end

function syslib.getscopeparameters()
    headerSetter({'GETSCOPEPARAMS'})
    return syslib:main('GETSCOPEPARAMS')
end

function syslib.getrelaypaths(objspec)
    headerSetter({'GETRELAYPATHS', objspec})
    return syslib:main('GETRELAYPATHS')
end

function syslib.getselectorentries(pathspec, options)
    headerSetter({'GETSELECTORENTRIES', pathspec, options})
    return syslib:main('GETSELECTORENTRIES')
end

function syslib.getself()
    if syslib.selfpath == "" then
        return "'selfpath' key value of syslib.config.lua is not a valid object."
    else
        return syslib.getobject(syslib.selfpath)
    end
end

function syslib.getselfpath()
    return syslib.selfpath
end

function syslib.getstoreid(store)
    headerSetter({'GETSTOREID', store})
    return syslib:main('GETSTOREID')
end

local sysDB = {}
function syslib.getsystemdb()

    sysDB.__index = sysDB
    local obj = {}
    setmetatable(obj, sysDB)
    function obj:query(sqlcmd)
        headerSetter({'GETSYSTEMDB', sqlcmd})
        local data, errmsg = syslib:main('GETSYSTEMDB')

        local cursor = {}
        function cursor:fetch(tb, modestring)
            if tb == nil or type(tb) ~= "table" then tb = {} end
            if modestring == nil or type(modestring) ~= "string" then modestring = "n" end
            local row = data[1]
            table.remove(data, 1)
            return row
        end
        return cursor
    end
    return obj
end

function syslib.gettcpconnections(version)
    headerSetter({'GETTCPCONNECTIONS', version})
    return syslib:main('GETTCPCONNECTIONS')
end

--arg = time
function syslib.gettimeparts(t)
    headerSetter({'GETTIMEPARTS', t})
    return syslib:main('GETTIMEPARTS')
end

function syslib.hdagetitemattributes(datasource)
    headerSetter({'HDAGETITEM', syslib.selfpath, datasource})
    return syslib:main('HDAGETITEM')
end

function syslib.hdareadattributes(datasource, item_tag, attribute_tags, start_time, end_time)
    headerSetter({'HDAREAD', syslib.selfpath, datasource, item_tag, attribute_tags, start_time, end_time})
    return syslib:main('HDAREAD')
end

function syslib.isbadstatus(quality)
    headerSetter({'ISBADSTATUS', quality})
    return syslib:main('ISBADSTATUS')
end

function syslib.isgoodstatus(quality)
    headerSetter({'ISGOODSTATUS', quality})
    return syslib:main('ISGOODSTATUS')
end

function syslib.isuncertainstatus(quality)
    headerSetter({'ISUNCERTAINSTATUS', quality})
    return syslib:main('ISUNCERTAINSTATUS')
end

function syslib.ip21browse(datasource, tags, options)
    headerSetter({'IP21BROWSE', syslib.selfpath, datasource, tags, options})
    return syslib:main('IP21BROWSE')
end

function syslib.ip21getitemid(tag, field)
    headerSetter({'IP21GETITEMID', syslib.selfpath, tag, field})
    return syslib:main('IP21GETITEMID')
end

function syslib.ip21parseitemid(itemid)
    headerSetter({'IP21PARSEITEMID', syslib.selfpath, itemid})
    return syslib:main('IP21PARSEITEMID')
end

function syslib.last(objspec, name)
    headerSetter({'LAST', objspec.location or objspec, name})
    return syslib:main('LAST')
end

function syslib.listbuffer(objspec)
    headerSetter({'LISTBUFFER', objspec})
    return syslib:main('LISTBUFFER')
end

function syslib.listproperties(objspec, resultspec, ...)
    --stuff vararg into table and push
    headerSetter({'LISTPROPS', objspec, resultspec, ...})
    return syslib:main('LISTPROPS')
end

function syslib.linkprocessvalue(objspec, ref)
    headerSetter({'LINKPV', objspec, ref})
    return syslib:main('LINKPV')
end

function syslib.log(log_code, log_message, log_details)
    headerSetter({'LOG', log_code, log_message, log_details or ""})
    return syslib:main('LOG')
end

function syslib.luamemory(objspec, limit)
    headerSetter({'LUAMEM', objspec, limit})
    return syslib:main('LUAMEM')
end

function syslib.luacpuusage(objspec, limit)
    headerSetter({'LUACPU', objspec, limit})
    return syslib:main('LUACPU')
end

function syslib.mass(entries, batch_flags)
    headerSetter({'MASS', entries, batch_flags})
    return syslib:main('MASS')
end

function syslib.moveobject(objspec, parent, rename)
    headerSetter({'MOVEOBJ', objspec.location or objspec, parent.location or parent, rename})
    return syslib:main('MOVEOBJ')
end

--!  returns userdata, but we can just return argument parameters and pass them to other msg
function syslib.msgqueue(objspec, slot)
    return {objspec=objspec,slot=slot}
    --headerSetter({'MSGQUEUE', objspec, slot})
    --return syslib:main('MSGQUEUE')
end

function syslib.msgpush(queue, msg)
    headerSetter({'MSGPUSH', queue.objspec, queue.slot, msg})
    return syslib:main('MSGPUSH')
end

function syslib.msgpop(queue, msgid)
    headerSetter({'MSGPOP', queue.objspec, queue.slot, msgid})
    return syslib:main('MSGPOP')
end

function syslib.msgnext(queue, msgid)
    headerSetter({'MSGNEXT', queue.objspec, queue.slot, msgid})
    return syslib:main('MSGNEXT')
end

function syslib.msgclear(queue)
    headerSetter({'MSGCLEAR', queue.objspec, queue.slot})
    return syslib:main('MSGCLEAR')
end

function syslib.msgstats(queue)
    headerSetter({'MSGSTATS', queue.objspec, queue.slot})
    return syslib:main('MSGSTATS')
end

function syslib.opcdabrowse(datasource)
    headerSetter({'OPCDABROWSE'}, datasource)
    return syslib:main('OPCDABROWSE')
end

function syslib.pcall(func, param)
    headerSetter({'PCALL', function_names[func], param})
    return syslib:main('PCALL')
end

function syslib.peek(objspec, name)
    headerSetter({'PEEK', objspec.location or objspec, name})
    return syslib:main('PEEK')
end

function syslib.posix2excel(key)
    headerSetter({'POSIX2EXCEL', key})
    return syslib:main('POSIX2EXCEL')
end

function syslib.queryenvironment(key)
    headerSetter({'QUERYENVIRONMENT', key})
    return syslib:main('QUERYENVIRONMENT')
end

function syslib.queryservertimestamp(pathspec, time, datastore)
    headerSetter({'QUERYSERVERTIME', pathspec, time, datastore})
    return syslib:main('QUERYSERVERTIME')
end

function syslib.regex(string, expression)
    headerSetter({'REGEX', string, expression})
    return syslib:main('REGEX')
end

function syslib.scopedcall(settings, callback_func, ...)
    headerSetter({'SCOPEDCALL', settings, function_names[callback_func], ...})
    return syslib:main('SCOPEDCALL')
end

function syslib.setdefaults(default_params)
    headerSetter({'SETDEFAULT', default_params})
    return syslib:main('SETDEFAULT')
end

function syslib.setevent(data)
    headerSetter({'SETEVENT', data})
    return syslib:main('SETEVENT')
end

function syslib.setfile(pathspec, data, nameormetadata, mode)
    headerSetter({'SETFILE', pathspec, data, nameormetadata, mode})
    return syslib:main('SETFILE')
end

function syslib.setfilemetadata(pathspec, name, metadata, mode)
    headerSetter({'SETFILEMETA', pathspec, name, metadata, mode})
    return syslib:main('SETFILEMETA')
end

function syslib.sethistoryex(datasource, tags, values, qualities, timestamps, mode)
    headerSetter({'SETHISTEX', syslib.selfpath, datasource, tags, values, qualities, timestamps, mode})
    return syslib:main('SETHISTEX')
end

function syslib.setproductkey(product_key)
    headerSetter({'SETPRODUCTKEY', product_key})
    return syslib:main('SETPRODUCTKEY')
end

function syslib.setreferences(objspec, refs)
    headerSetter({'SETREFERENCES', objspec.location or objspec, refs})
    return syslib:main('SETREFERENCES')
end

function syslib.setscopeparameters(settings)
    headerSetter({'SETSCOPEPARAMS', settings})
    return syslib:main('SETSCOPEPARAMS')
end

function syslib.sleep(milliseconds)
    headerSetter({'SLEEP', milliseconds})
    return syslib:main('SLEEP')
end

function syslib.tear(objspec, name)
    headerSetter({'TEAR', objspec.location or objspec, name})
    return syslib:main('TEAR')
end

function syslib.uabrowse(datasource, nodes_to_browse, defaults)
    headerSetter({'UABROWSE', syslib.selfpath, datasource, JSON.encode(nodes_to_browse), JSON.encode(defaults)})
    return syslib:main('UABROWSE')
end

function syslib.uabrowsenext(datasource, checkpoints)
    headerSetter({'UABROWSENEXT', datasource, checkpoints})
    return syslib:main('UABROWSENEXT')
end

function syslib.uaextradata(quality, ignore_info_type)
    headerSetter({'UAEXTRADATA', quality, ignore_info_type})
    return syslib:main('UAEXTRADATA')
end

function syslib.uamethodcall(datasource, methods_to_call)
    headerSetter({'UAMETHODCALL', datasource, methods_to_call})
    return syslib:main('UAMETHODCALL')
end

function syslib.uaread(datasource, nodes_to_read, max_age, return_ts)
    headerSetter({'UAREAD', syslib.selfpath, datasource, JSON.encode(nodes_to_read), max_age, return_ts})
    return syslib:main('UAREAD')
end

function syslib.utf16to8(string, big_endian)
    headerSetter({'UTF16to8', string, big_endian})
    return syslib:main('UTF16to8')
end

function syslib.utf8to16(string, big_endian)
    headerSetter({'UTF8to16', string, big_endian})
    return syslib:main('UTF8to16')
end

function syslib.utf8toascii(string, code_page)
    headerSetter({'UTF8toASCII', string, code_page})
    return syslib:main('UTF8toASCII')
end

function syslib.uuid(count, options)
    headerSetter({'UUID', count, options})
    return syslib:main('UUID')
end

function syslib:main(farg)
    local client = https.NEW({})
    local res = client:POST(self.url, self.headers, body)
    if res.code == 200 or res.ok then
        local data = res.data.data[1].v
        if farg == "GET" then
            return data.v, data.q, data.t
        elseif farg == "CURRENTTIMEZONE" then
            return data.offset, data.name, data.dst
        elseif farg == "GETHISTORYFRAME" then
            return data.starttime, data.endtime
        elseif farg == "GETSYSTEMDB" then
            return data.cursor, data.err
        elseif farg == "LISTPROPS" or farg == "GETFILE" then
            return JSON.decode(data)
        elseif farg == "MSGNEXT" then
            return data.msgid, data.msg
        elseif farg == "PCALL" then
            return data.ok, data.err_or_msg, data.err_table
        elseif farg == "PEEK" or farg == "TEAR" then
            return data.values, data.qualities, data.timestamps, data.count
        elseif farg == "SPLITPATH" then
            return data.parent, data.child
        else
            return data
        end
    else
        return false
    end
end

for name,value in pairs(syslib) do
    if type(value) == "function" then
        --function_names[value] = "syslib."..name
        function_names[value] = name
    end
end

return syslib